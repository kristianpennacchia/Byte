//
//  YoutubeAPI.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import KeychainAccess

final class YoutubeAPI: ObservableObject {
    struct Authentication {
        let clientID: String
        let secret: String
    }

    typealias Completion<T> = (_ result: Result<T, Error>) -> Void where T: Decodable

    static var isAvailable: Bool { shared != nil }
    static private(set) var shared: YoutubeAPI!

    private let didChange = PassthroughSubject<Output, Failure>()
    private let keychain = Keychain(service: "youtube")
    private let dateFormatter = ISO8601DateFormatter()
    private let dateMillisFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        return df
    }()

    let session: URLSession
    let authentication: Authentication
    let decoder = JSONDecoder()

    var accessToken: String? {
        get {
            keychain[KeychainKey.accessToken]
        }
        set {
            keychain[KeychainKey.accessToken] = newValue
        }
    }
    var refreshToken: String? {
        get {
            keychain[KeychainKey.refreshToken]
        }
        set {
            keychain[KeychainKey.refreshToken] = newValue
        }
    }

    static func setup(authentication: Authentication) {
        shared = YoutubeAPI(authentication: authentication)
    }

    private init(authentication: Authentication) {
        self.authentication = authentication

        session = URLSession(configuration: .default)

        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { [unowned self] decoder in
            let valueContainer = try decoder.singleValueContainer()
            let dateString = try valueContainer.decode(String.self)

            if let date = self.dateFormatter.date(from: dateString) ?? self.dateMillisFormatter.date(from: dateString) {
                return date
            } else {
                throw AppError(message: "Failed parsing date = \(dateString)")
            }
        }
    }
}

extension YoutubeAPI {
    enum Method: String {
        case get, post, put, patch, delete
    }

    enum Base: String {
        case auth = "https://oauth2.googleapis.com/"
        case youtube = "https://youtube.googleapis.com/youtube/v3/"
        case people = "https://people.googleapis.com/v1/"

        var url: URL {
            return URL(string: rawValue)!
        }

        func authorizationHeader(accessToken: String) -> String {
            let prefix: String
            switch self {
            case .auth: prefix = "Bearer"
            case .youtube: prefix = "Bearer"
            case .people: prefix = "Bearer"
            }

            return "\(prefix) \(accessToken)"
        }
    }
}

extension YoutubeAPI {

    // - MARK: Authentication

    func authenticate(oAuthHandler: @escaping Completion<YoutubeOAuth>, completion: @escaping Completion<YoutubePerson>) {
        if accessToken != nil {
            // We should be able to get the user info assuming the accessToken is still valid.
            Task {
                do {
                    let person = try await getAuthenticatedPerson()

                    DispatchQueue.main.async {
                        completion(.success(person))
                    }
                } catch {
                    Swift.print("Failed getting user info.", error)
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            let query = [
                "client_id": authentication.clientID,
                "scope": "https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/userinfo.profile",
            ]

            Task {
                do {
                    let data = try await execute(method: .post, base: .auth, endpoint: "device/code", query: query, decoding: YoutubeOAuth.self)

                    oAuthHandler(.success(data))

                    Swift.print("Polling for user to complete OAuth.")

                    // Continuously poll 'https://oauth2.googleapis.com/token' every `data.interval` seconds until we get a success or failure response.
                    let pollQuery = [
                        "client_id": authentication.clientID,
                        "client_secret": authentication.secret,
                        "device_code": data.deviceCode,
                        "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                        "access_type": "offline",
                        "prompt": "consent",
                    ]

                    repeat {
                        guard data.isExpired == false else {
                            oAuthHandler(.failure(APIError.unknown))
                            break
                        }

                        try! await Task.sleep(seconds: TimeInterval(data.interval))

                        do {
                            let userAuth = try await execute(method: .post, base: .auth, endpoint: "token", query: pollQuery, decoding: YoutubeUserAuth.self)
                            accessToken = userAuth.accessToken
                            refreshToken = userAuth.refreshToken ?? refreshToken

                            // Get user data.
                            let person = try await getAuthenticatedPerson()
                            completion(.success(person))
                        } catch let error as YoutubeError {
                            if error.error == "access_denied" {
                                Swift.print("Failed getting Youtube OAuth response. \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                                break
                            }
                        } catch {
                            Swift.print("Failed getting Youtube OAuth response. \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                            break
                        }
                    } while true
                } catch {
                    Swift.print("Failed getting Youtube OAuth response. \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        oAuthHandler(.failure(error))
                    }
                }
            }
        }
    }

    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw APIError.refreshToken
        }

        let query = [
            "client_id": authentication.clientID,
            "client_secret": authentication.secret,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        ]

        do {
            let userAuth = try await execute(method: .post, base: .auth, endpoint: "token", query: query, decoding: YoutubeUserAuth.self)
            accessToken = userAuth.accessToken
            self.refreshToken = userAuth.refreshToken ?? refreshToken

            // Get user data.
            let person = try await getAuthenticatedPerson()
            didChange.send(person)
        } catch {
            // Refreshing user access token failed, which likely means the refresh token is no longer valid.
            self.accessToken = nil
            self.refreshToken = nil
            throw error
        }
    }

    func getAuthenticatedPerson() async throws -> YoutubePerson {
        // https://developers.google.com/people/v1/profiles
        let query = [
            "personFields": "names",
        ]

        return try await execute(method: .get, base: .people, endpoint: "people/me", query: query, decoding: YoutubePerson.self)
    }

    func getLiveVideoIDs(channelID: String) async throws -> [String] {
        // Perform a cheap (data size) check to see if the channel is live.
        let embedChannelURL = URL(string: "https://www.youtube.com/embed/live_stream?channel=\(channelID)")!
        let embedHtmlPageData = try await session.data(from: embedChannelURL).0
        let embedHtmlPageString = String(data: embedHtmlPageData, encoding: .utf8)!

        guard embedHtmlPageString.contains(##"<link rel="canonical" href="https://www.youtube.com/watch?v="##)
           && embedHtmlPageString.contains("scheduledStartTime") == false
        else {
            return []
        }

        // Channel is live. A channel can have multiple live streams at once, so we need to get all their live video IDs.
        let liveVideoChannelURL = URL(string: "https://www.youtube.com/channel/\(channelID)/streams")!

        var request = URLRequest(url: liveVideoChannelURL)

        // We need to get the desktop webpage.
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        let liveVideoHtmlPageData = try await session.data(for: request).0
        let liveVideoHtmlPageString = String(data: liveVideoHtmlPageData, encoding: .utf8)!

        // Now use regex to get all the live video IDs.
        return liveVideoHtmlPageString.matches(of: /"watchEndpoint":{"videoId":"(.*?)"/).map(\.output.1).map(String.init)
    }
}

extension YoutubeAPI {
    func execute<T>(method: Method, base: Base, endpoint: String, query: [String: Any?] = [:], decoding: T.Type) async throws -> T where T: Decodable {
        var components = URLComponents(url: base.url.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        components.query = query.queryParameters()

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue

        if let accessToken = accessToken {
            let authorization = base.authorizationHeader(accessToken: accessToken)
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        let data = try await session.data(for: request).0

        do {
            if let rawData = String(data: data, encoding: .utf8), rawData.contains("\"error\":") {
                // It's a fucking error in a successful HTTP status code response. FUCK YOU GOOGLE!
                do {
                    throw try decoder.decode(YoutubeError.self, from: data)
                } catch is DecodingError {
                    do {
                        throw try decoder.decode(YoutubeError2.self, from: data)
                    } catch let error as DecodingError {
                        throw error
                    }
                }
            } else {
                return try decoder.decode(T.self, from: data)
            }
        } catch let error as YoutubeError {
            if error.errorCode?.uppercased() == "UNAUTHENTICATED" {
                // Authentication failure. The access token has become invalid, try to refresh it.
                try await refreshAccessToken()

                // Access token refreshed, retry this method.
                return try await execute(method: method, base: base, endpoint: endpoint, query: query, decoding: decoding)
            } else {
                throw error
            }
        } catch let error as YoutubeError2 {
            if error.error.status?.uppercased() == "UNAUTHENTICATED" {
                // Authentication failure. The access token has become invalid, try to refresh it.
                try await refreshAccessToken()

                // Access token refreshed, retry this method.
                return try await execute(method: method, base: base, endpoint: endpoint, query: query, decoding: decoding)
            } else {
                throw error
            }
        } catch let error as DecodingError {
            Swift.print("URL from decoding failure = \(request.url?.absoluteString ?? "N/A"), query = \(query)")

            if let rawData = String(data: data, encoding: .utf8) {
                Swift.print("Raw data from decoding failure = \(rawData)")
            }

            throw LocalizedDecodingError(decodingError: error)
        } catch {
            throw error
        }
    }

    func executeFetchAll<T>(method: Method = .get, base: Base, endpoint: String, query: [String: Any?] = [:], decoding: YoutubeDataItem<T>.Type) async throws -> [T] where T: Decodable {
        var allItems = [T]()
        var nextPageToken: String?

        repeat {
            var query = query
            query["pageToken"] = nextPageToken

            let data = try await execute(method: method, base: base, endpoint: endpoint, query: query, decoding: decoding)
            allItems += data.items

            nextPageToken = data.nextPageToken
            if data.items.isEmpty {
                nextPageToken = nil
            }
        } while nextPageToken != nil

        return allItems
    }

    func executeRaw(method: Method, base: Base, endpoint: String, query: [String: Any?] = [:]) async throws -> Data {
        var components = URLComponents(url: base.url.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        components.query = query.queryParameters()

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue

        if let accessToken = accessToken {
            let authorization = base.authorizationHeader(accessToken: accessToken)
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        return try await session.data(for: request).0
    }
}

extension YoutubeAPI: Publisher {
    typealias Output = YoutubePerson
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}

