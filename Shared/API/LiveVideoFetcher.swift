//
//  LiveVideoFetcher.swift
//  Byte
//
//  Created by Kristian Pennacchia on 12/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import OSLog

class LiveVideoFetcher: NSObject {
    private struct YtdlpResponse: Decodable {
        let formats: [YtdlpFormat]?
        let url: URL?
    }

    fileprivate struct SigToken: Decodable {
        struct Data: Decodable {
            struct Token: Decodable {
                let value: String
                let signature: String
            }

            let streamPlaybackAccessToken: Token?
            let videoPlaybackAccessToken: Token?
            var playbackAccessToken: Token {
                streamPlaybackAccessToken ?? videoPlaybackAccessToken!
            }
        }

        let data: Data
        var signature: String { data.playbackAccessToken.signature }
        var token: String { data.playbackAccessToken.value }
    }

    fileprivate enum VideoStream {
        case live(channel: String), vod(vodID: String)

        var isLive: Bool {
            if case .live = self {
                return true
            } else {
                return false
            }
        }
        var channel: String? {
            switch self {
            case .live(channel: let channel):
                return channel
            case .vod(vodID: _):
                return nil
            }
        }
        var vodID: String? {
            switch self {
            case .live(channel: _):
                return nil
            case .vod(vodID: let vodID):
                return vodID
            }
        }
    }

    enum VideoMode: Equatable {
        static func == (lhs: LiveVideoFetcher.VideoMode, rhs: LiveVideoFetcher.VideoMode) -> Bool {
            switch (lhs, rhs) {
            case (.live(_), .vod(_)):
                return false
            case (.vod(_), .live(_)):
                return false
            case (.live(let a), .live(let b)):
                return a.id == b.id
            case (.vod(let a), .vod(let b)):
                return a.videoId == b.videoId
            }
        }

        case live(any Streamable), vod(any Videoable)
    }

    enum VideoDataResponse {
        case playlist(M3U8)
        case formats([YoutubePlayerResponse.StreamingData.Format])
        case ytdlpFormats([YtdlpFormat])
        case urls([URL])
    }

    private(set) lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()

    let twitchAPI: TwitchAPI
    let clientID: String
    let videoMode: VideoMode

    init(twitchAPI: TwitchAPI, videoMode: VideoMode) {
        self.twitchAPI = twitchAPI
        self.clientID = twitchAPI.authentication.privateClientID
        self.videoMode = videoMode
    }
}

extension LiveVideoFetcher {
    func fetch() async throws -> VideoDataResponse {
        switch videoMode {
        case .live(let stream):
            switch type(of: stream).platform {
            case .twitch:
                let data = try await twitchAPI.execute(method: .get, endpoint: "users", query: ["id": stream.userId], decoding: [Channel].self)
                if let channel = data.data.first {
                    return try await getVideo(.live(channel: channel.login))
                } else {
                    throw AppError(message: "Decoding channel data for user ID '\(stream.userId)' failed.")
                }
            case .youtube:
                // First try scraping the Youtube website ourselves.
                do {
                    var request = URLRequest(url: URL(string: "https://www.youtube.com/watch?v=\(stream.id)")!)
                    request.httpMethod = "GET"
                    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let htmlPageData = try await session.data(for: request).0
                    let htmlPageString = String(data: htmlPageData, encoding: .utf8)!
                    let playerResponseJSON = try /var\s+ytInitialPlayerResponse\s*=\s*({.*?});/.firstMatch(in: htmlPageString)?.output.1

                    guard let playerResponseJSONData = playerResponseJSON?.data(using: .utf8) else {
                        throw AppError(message: "Could not get player response JSON data.")
                    }

                    let playerResponse = try JSONDecoder().decode(YoutubePlayerResponse.self, from: playerResponseJSONData)

                    let m3u8Data = try await session.data(from: URL(string: playerResponse.streamingData.hlsManifestUrl!)!).0
                    let m3u8 = try M3U8(data: m3u8Data)
                    return .playlist(m3u8)
                } catch let error as DecodingError {
					Logger.streaming.error("Fetching video page for video ID '\(stream.id)' failed. \(LocalizedDecodingError(decodingError: error).localizedDescription)")
                } catch {
					Logger.streaming.error("Fetching video page for video ID '\(stream.id)' failed. \(error.localizedDescription)")
                }

				Logger.streaming.debug("Falling back to yt-dlp.")

                // Fallback to getting the direct video URLs via yt-dlp.
                do {
                    var request = URLRequest(url: URL(string: "https://youtube-dl-web.vercel.app/api/info?q=https://www.youtube.com/watch?v=\(stream.id)&f=bestvideo+bestaudio/best")!)

                    // Long timeout interval due to OnRender servers taking a long time to start up.
                    request.timeoutInterval = 120

                    let data = try await session.data(for: request).0
                    let ytdlpResponse = try JSONDecoder().decode(YtdlpResponse.self, from: data)

					if let url = ytdlpResponse.url {
						return .urls([url])
					} else if let formats = ytdlpResponse.formats {
						return .ytdlpFormats(formats)
					} else {
						throw AppError(message: "Could not get 'best' URL or format from yt-dlp response.")
					}
                } catch let error as DecodingError {
                    throw AppError(message: "Fetching direct Youtube video URLs for video ID '\(stream.id)' failed. \(LocalizedDecodingError(decodingError: error).localizedDescription)")
                } catch {
                    // Failed getting direct URLs. Fallback to getting them ourselves.
                    throw AppError(message: "Fetching direct Youtube video URLs for video ID '\(stream.id)' failed. \(error.localizedDescription)")
                }
            }
        case .vod(let video):
            switch type(of: video).platform {
            case .twitch:
                return try await getVideo(.vod(vodID: video.videoId))
            case .youtube:
                // First try getting the direct video URLs via yt-dlp.
                do {
                    var request = URLRequest(url: URL(string: "https://youtube-dl-web.vercel.app/api/info?q=https://www.youtube.com/watch?v=\(video.videoId)&f=bestvideo+bestaudio/best")!)

                    // Long timeout interval due to OnRender servers taking a long time to start up.
                    request.timeoutInterval = 120

                    let data = try await session.data(for: request).0
                    let ytdlpResponse = try JSONDecoder().decode(YtdlpResponse.self, from: data)

					if let url = ytdlpResponse.url {
						return .urls([url])
					} else if let formats = ytdlpResponse.formats {
						return .ytdlpFormats(formats)
					} else {
						throw AppError(message: "Could not get 'best' URL or format from yt-dlp response.")
					}
                } catch let error as DecodingError {
					Logger.streaming.error("Fetching direct Youtube video URLs for video ID '\(video.videoId)' failed. \(LocalizedDecodingError(decodingError: error).localizedDescription)")
                } catch {
                    // Failed getting direct URLs. Fallback to getting them ourselves.
					Logger.streaming.error("Fetching direct Youtube video URLs for video ID '\(video.videoId)' failed. \(error.localizedDescription)")
                }

				Logger.streaming.debug("Falling back to website parsing.")

                // Fallback to scraping the Youtube website ourselves.
                do {
                    var request = URLRequest(url: URL(string: "https://www.youtube.com/watch?v=\(video.videoId)")!)
                    request.httpMethod = "GET"
                    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let htmlPageData = try await session.data(for: request).0
                    let htmlPageString = String(data: htmlPageData, encoding: .utf8)!
                    let playerResponseJSON = try /var\s+ytInitialPlayerResponse\s*=\s*({.*?});\s*var\s+\w+\s*=/.firstMatch(in: htmlPageString)?.output.1

                    guard let playerResponseJSONData = playerResponseJSON?.data(using: .utf8) else {
                        throw AppError(message: "Could not get player response JSON data.")
                    }

                    let playerResponse = try JSONDecoder().decode(YoutubePlayerResponse.self, from: playerResponseJSONData)
                    return .formats(playerResponse.streamingData.formats ?? [])
                } catch let error as DecodingError {
                    throw AppError(message: "Fetching channel for video ID '\(video.videoId)' failed. \(LocalizedDecodingError(decodingError: error).localizedDescription)")
                } catch {
                    throw AppError(message: "Fetching channel for video ID '\(video.videoId)' failed. \(error.localizedDescription)")
                }
            }
        }
    }
}

private extension LiveVideoFetcher {
    func usherAPI(video: VideoStream, sigToken: SigToken) async -> (url: URL, additionalHeaders: [String: String]) {
        var components: URLComponents
        switch video {
        case .live(let channel):
			components = URLComponents(string: "https://usher.ttvnw.net/api/channel/hls/\(channel).m3u8")!
        case .vod(let vodID):
            components = URLComponents(string: "https://usher.ttvnw.net/vod/\(vodID)")!
        }

		let queryItemsDict: [String: Any]? = [
			"player": "twitchweb",
			"allow_source": true,
			"allow_audio_only": true,
			"sig": sigToken.signature,
			"p": Int.random(in: 0 ... .max),
			"type": "any",
			"allow_spectre": false,
			"fast_bread": true,
		]

        components.queryItems = queryItemsDict?.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

        let url: URL
        let additionalheaders = [String: String]()
		let urlQueryCharacterSet = CharacterSet.alphanumerics.union(.init([".", "_"]))
		let token = sigToken.token
			.replacingOccurrences(of: "\\", with: "")
			.addingPercentEncoding(withAllowedCharacters: urlQueryCharacterSet) ?? ""
		let urlString = components.url!.absoluteString.appending("&token=\(token)")
		url = URL(string: urlString)!

		Logger.streaming.debug("Twitch URL = \(components.url!.absoluteString)")

        return (url, additionalheaders)
    }

    func tokenAPI(video: VideoStream) -> URLRequest {
        let url = URL(string: "https://gql.twitch.tv/gql")!
        let body: [String: Any] = [
            "operationName": "PlaybackAccessToken",
            "extensions": [
                "persistedQuery": [
                    "version": 1,
                    "sha256Hash": "0828119ded1c13477966434e15800ff57ddacf13ba1911c129dc2200705b0712",
                ],
            ],
            "variables": [
                "isLive": video.isLive,
                "login": video.channel ?? "",
                "isVod": video.isLive == false,
                "vodID": video.vodID ?? "",
                "playerType": "web",
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(clientID, forHTTPHeaderField: "Client-ID")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        return request
    }

    func getTokenAndSignature(video: VideoStream) async throws -> SigToken {
        let request = tokenAPI(video: video)
        let data = try await session.data(for: request).0

        do {
            return try JSONDecoder().decode(SigToken.self, from: data)
        } catch let error as DecodingError {
            let localizedError = LocalizedDecodingError(decodingError: error)
			Logger.streaming.error("Failed to decode Twitch token and signature from JSON. \(error.localizedDescription)")
            throw localizedError
        }
    }

    func getVideo(_ video: VideoStream) async throws -> VideoDataResponse {
        try await Task.retrying { [self] isLastRetry in
            let sigToken = try await getTokenAndSignature(video: video)
            let (url, additionalHeaders) = await usherAPI(video: video, sigToken: sigToken)

            var request = URLRequest(url: url)
            additionalHeaders.forEach { header in
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }

            let data = try await session.data(for: request).0

            do {
                let m3u8 = try M3U8(data: data)
                return .playlist(m3u8)
            } catch {
                if let string = String(data: data, encoding: .utf8) {
					Logger.streaming.error("Failed parsing M3U8 data. \(string)")
                }
                throw error
            }
        }.value
    }
}

extension LiveVideoFetcher: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.host {
        case "usher.twitch.tv", "usher.ttvnw.net", "api.ttv.lol":
            // Ignore all server SSL/security issues for this host
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
