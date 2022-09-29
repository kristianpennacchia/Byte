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

        var url: URL {
            return URL(string: rawValue)!
        }

        func authorizationHeader(accessToken: String) -> String {
            let prefix: String
            switch self {
            case .auth: prefix = "Bearer"
            }

            return "\(prefix) \(accessToken)"
        }
    }
}

extension YoutubeAPI {

    // - MARK: Authentication

    func authenticate(oAuthHandler: @escaping Completion<YoutubeOAuth>, completion: @escaping CompletionRaw) {
        if accessToken != nil {
            // We should be able to get the user info assuming the accessToken is still valid.
            #warning("TODO: Get the authenticated user data.")
//            YoutubeAPI.shared.execute(base: .auth, endpoint: "users", decoding: [Channel].self, completion: completion)
        } else {
            let query = [
                "client_id": authentication.clientID,
                "scope": "https://www.googleapis.com/auth/youtube.readonly",
            ]

            execute(method: .post, base: .auth, endpoint: "device/code", query: query, decoding: YoutubeOAuth.self) { result in
                switch result {
                case .success(let data):
                    oAuthHandler(.success(data))

                    #warning("TODO: Continuously poll 'https://oauth2.googleapis.com/token' every `data.interval` seconds until we get a success or failure response.")
                case .failure(let error):
                    Swift.print("Failed getting Youtube OAuth response. \(error.localizedDescription)")
                }
            }
        }
    }

    func refreshAccessToken(completion: @escaping Completion<[Channel]>) {
        guard let refreshToken = refreshToken else {
            completion(.failure(APIError.refreshToken))
            return
        }

        let query = [
            "client_id": authentication.clientID,
            "client_secret": authentication.secret,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        ]

        #warning("TODO: Execute request to refresh the expired access token.")
//        executeRaw(method: .post, base: .auth, endpoint: "token", query: query) { result in
//            switch result {
//            case .success(let data):
//                guard let jsonData = try? JSONSerialization.jsonObject(with: data),
//                      let json = jsonData as? [String:  Any?],
//                      let accessToken = json["access_token"] as? String,
//                      let refreshToken = json["refresh_token"] as? String
//                else {
//                    // Refreshing user access token failed, which likely means the refresh token is no longer valid.
//                    self.refreshToken = nil
//                    completion(.failure(APIError.refreshToken))
//                    return
//                }
//
//                self.accessToken = accessToken
//                self.refreshToken = refreshToken
//                self.authenticate { result in
//                    if case .success(let users) = result, let user = users.data.first {
//                        self.didChange.send(user)
//                    }
//
//                    completion(result)
//                }
//            case .failure(let error):
//                // Refreshing user access token failed, which likely means the refresh token is no longer valid.
//                self.refreshToken = nil
//
//                completion(.failure(error))
//            }
//        }
    }
}

extension YoutubeAPI {
    @discardableResult
    func execute<T>(method: Method = .get, base: Base, endpoint: String, query: [String: Any?] = [:], page: Pagination? = nil, decoding: T.Type, completion: @escaping Completion<T>) -> URLSessionTask {
        var components = URLComponents(url: base.url.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        components.query = query.queryParameters()

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue

        if let accessToken = accessToken {
            let authorization = base.authorizationHeader(accessToken: accessToken)
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let result = try self.decoder.decode(T.self, from: data)

                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                } catch let de as DecodingError {
                    Swift.print("URL from decoding failure = \(request.url?.absoluteString ?? "N/A"), query = \(query)")

                    if let rawData = String(data: data, encoding: .utf8) {
                        Swift.print("Raw data from decoding failure = \(rawData)")
                    }

                    do {
                        let error = try self.decoder.decode(YoutubeError.self, from: data)

                        if error.errorCode == "TODO: The code which tells you the access token has expired." {
                            // Authentication failure. The access token has become invalid, try to refresh it.
                            self.refreshAccessToken { result in
                                switch result {
                                case .success(_):
                                    self.execute(method: method, base: base, endpoint: endpoint, query: query, page: page, decoding: decoding, completion: completion)
                                case .failure(let error):
                                    DispatchQueue.main.async {
                                        completion(.failure(error))
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(LocalizedDecodingError(decodingError: de)))
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(LocalizedDecodingError(decodingError: de)))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(error ?? APIError.unknown))
                }
            }
        }
        task.resume()
        return task
    }

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

    @discardableResult
    func executeRaw(method: Method = .get, base: Base, endpoint: String, query: [String: Any?] = [:], completion: @escaping CompletionRaw) -> URLSessionTask {
        var components = URLComponents(url: base.url.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        components.query = query.queryParameters()

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue

        if let accessToken = accessToken {
            let authorization = base.authorizationHeader(accessToken: accessToken)
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }

        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    completion(.success(data))
                } else {
                    completion(.failure(error ?? APIError.unknown))
                }
            }
        }
        task.resume()
        return task
    }
}

extension YoutubeAPI: Publisher {
    typealias Output = Channel
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}

