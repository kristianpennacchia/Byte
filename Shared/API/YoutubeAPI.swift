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
import SwiftSoup

final class YoutubeAPI: ObservableObject {
    struct Authentication {
        let clientID: String
        let secret: String
    }

    typealias Completion<T> = (_ result: Result<T, Error>) -> Void where T: Decodable
    typealias CompletionRaw = (_ result: Result<Data, Error>) -> Void

    static var isAvailable: Bool { shared != nil }
    static private(set) var shared: YoutubeAPI!

    private let didChange = PassthroughSubject<Output, Failure>()
    private let keychain = Keychain(service: "youtube")

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
        decoder.dateDecodingStrategy = .iso8601
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

    func refreshAccessToken() async throws -> Void {
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
}

extension YoutubeAPI {
    func execute<T>(method: Method, base: Base, endpoint: String, query: [String: Any?] = [:], page: Pagination? = nil, decoding: T.Type) async throws -> T where T: Decodable {
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
                } catch {
                    do {
                        throw try decoder.decode(YoutubeError2.self, from: data)
                    } catch {
                        throw error
                    }
                }
            } else {
                return try decoder.decode(T.self, from: data)
            }
        } catch let error as YoutubeError {
            if error.errorCode == "UNAUTHENTICATED" {
                // Authentication failure. The access token has become invalid, try to refresh it.
                try await refreshAccessToken()

                // Access token refreshed, retry this method.
                return try await execute(method: method, base: base, endpoint: endpoint, query: query, page: page, decoding: decoding)
            } else {
                throw error
            }
        } catch let error as YoutubeError2 {
            if error.error.status == "UNAUTHENTICATED" {
                // Authentication failure. The access token has become invalid, try to refresh it.
                try await refreshAccessToken()

                // Access token refreshed, retry this method.
                return try await execute(method: method, base: base, endpoint: endpoint, query: query, page: page, decoding: decoding)
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

    #warning("TODO: Implement fetching all pages for a request that supports pagination.")
//    func executeFetchAll<T>(method: Method = .get, base: Base, endpoint: String, query: [String: Any?] = [:], decoding: [T].Type, completion: @escaping Completion<[T]>) where T: Decodable {
//        var allItems = [T]()
//
//        func fetch(page: Pagination?) {
//            var query = query
//            query["after"] = page?.cursor
//
//            execute(method: method, base: base, endpoint: endpoint, query: query, page: page, decoding: decoding) { result in
//                switch result {
//                case .success(let data):
//                    allItems += data.data
//
//                    if data.pagination == nil || data.pagination!.isValid == false || data.data.isEmpty {
//                        // All data has been downloaded
//                        completion(.success(DataItem<[T]>(data: allItems, pagination: data.pagination)))
//                    } else {
//                        fetch(page: data.pagination)
//                    }
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
//
//        fetch(page: nil)
//    }

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

