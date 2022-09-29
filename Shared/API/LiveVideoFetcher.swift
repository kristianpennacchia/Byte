//
//  LiveVideoFetcher.swift
//  Byte
//
//  Created by Kristian Pennacchia on 12/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

class LiveVideoFetcher: NSObject {
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

    struct Error: LocalizedError {
        let message: String
        var errorDescription: String? { return message }
    }

    enum VideoMode: Equatable {
        case live(Stream), vod(Video)
    }

    enum VideoStream {
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

    private(set) lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()

    let api: TwitchAPI
    let clientID: String
    let videoMode: VideoMode

    init(api: TwitchAPI, videoMode: VideoMode) {
        self.api = api
        self.clientID = api.authentication.privateClientID
        self.videoMode = videoMode
    }
}

extension LiveVideoFetcher {
    func fetch(completion: @escaping (Result<M3U8, Error>) -> Void) {
        switch videoMode {
        case .live(let stream):
            api.execute(endpoint: "users", query: ["id": stream.userId], decoding: [Channel].self) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let data):
                    if let channel = data.data.first {
                        self.getVideo(.live(channel: channel.login), completion: completion)
                    } else {
                        completion(.failure(Error(message: "Decoding channel data for user ID '\(stream.userId)' failed.")))
                    }
                case .failure(let error):
                    completion(.failure(Error(message: "Fetching channel for user ID '\(stream.userId)' failed. \(error.localizedDescription)")))
                }
            }
        case .vod(let video):
            getVideo(.vod(vodID: video.id), completion: completion)

//            twitchAPI.execute(endpoint: "videos", query: ["id": video], decoding: [Video].self) { [weak self] result in
//                guard let self = self else { return }
//
//                switch result {
//                case .success(let data):
//                    if let video = data.data.first {
//                        self.getVideo(.vod(vodID: video.id), completion: completion)
//                    } else {
//                        completion(.failure(Error(message: "Decoding VOD data with ID '\(video.id)' failed.")))
//                    }
//                case .failure(let error):
//                    completion(.failure(Error(message: "Fetching VOD with ID '\(video.id)' failed. \(error.localizedDescription)")))
//                }
//            }
        }
    }
}

private extension LiveVideoFetcher {
    func usherAPI(video: VideoStream, sigToken: SigToken) -> URL {
        var components: URLComponents
        switch video {
        case .live(let channel):
            components = URLComponents(string: "https://usher.ttvnw.net/api/channel/hls/\(channel).m3u8")!
        case .vod(let vodID):
            components = URLComponents(string: "https://usher.ttvnw.net/vod/\(vodID)")!
        }

        components.queryItems = [
            "player": "twitchweb",
            "allow_source": true,
            "allow_audio_only": true,
            "sig": sigToken.signature,
            "p": Int.random(in: 0 ... .max),
            "type": "any",
            "allow_spectre": false,
            "fast_bread": true,
        ].map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

        let urlQueryCharacterSet = CharacterSet.alphanumerics.union(.init([".", "_"]))
        let token = sigToken.token
            .replacingOccurrences(of: "\\", with: "")
            .addingPercentEncoding(withAllowedCharacters: urlQueryCharacterSet)
            ?? ""
        let urlString = components.url!.absoluteString.appending("&token=\(token)")
        return URL(string: urlString)!
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
                "playerType": "embed",
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(clientID, forHTTPHeaderField: "Client-ID")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        return request
    }

    func getTokenAndSignature(video: VideoStream, completion: @escaping (Result<SigToken, Error>) -> Void) {
        let request = tokenAPI(video: video)
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let sigToken = try decoder.decode(SigToken.self, from: data)
                    completion(.success(sigToken))
                } catch let error as NSError {
                    completion(.failure(Error(message: "Failed to decode token and signature from JSON. \(error.localizedDescription)\n\n\(error.debugDescription)")))
                } catch {
                    completion(.failure(Error(message: "Failed to decode token and signature from JSON. \(error.localizedDescription)")))
                }
            } else {
                completion(.failure(Error(message: "Failed to download token and signature. \(error?.localizedDescription ?? "Unknown error.")")))
            }
        }
        task.resume()
    }

    func getVideo(_ video: VideoStream, completion: @escaping (Result<M3U8, Error>) -> Void) {
        getTokenAndSignature(video: video) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                let url = self.usherAPI(video: video, sigToken: data)
                let task = self.session.dataTask(with: url) { data, response, error in
                    if let data = data {
                        do {
                            let m3u8 = try M3U8(data: data)
                            completion(.success(m3u8))
                        } catch {
                            completion(.failure(Error(message: "Failed to decode m3u8 data. \(error.localizedDescription)")))
                        }
                    } else {
                        completion(.failure(Error(message: "Failed to download live stream m3u8 data. \(error?.localizedDescription ?? "Unknown error.")")))
                    }
                }
                task.resume()
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
