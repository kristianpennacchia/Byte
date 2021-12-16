//
//  API.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

final class API: ObservableObject {
    typealias Completion<T> = (_ result: Result<DataItem<T>, Error>) -> Void where T: Decodable
    typealias CompletionRaw = (_ result: Result<Data, Error>) -> Void

    static private(set) var shared: API!

    let session: URLSession
    let authentication: Authentication
    let decoder = JSONDecoder()

    var accessToken: String?

    static func setup(authentication: Authentication, accessToken: String? = nil) {
        shared = API(authentication: authentication, accessToken: accessToken)
    }

    private init(authentication: Authentication, accessToken: String? = nil) {
        self.authentication = authentication
        self.accessToken = accessToken

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Client-ID": authentication.clientID
        ]

        session = URLSession(configuration: config)

        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }
}

extension API {
    enum Method: String {
        case get, post, put, patch, delete
    }

    enum Base: String {
        case auth = "https://id.twitch.tv/oauth2/"
        case kraken = "https://api.twitch.tv/kraken/"
        case helix = "https://api.twitch.tv/helix/"

        var url: URL {
            return URL(string: rawValue)!
        }

        func authorizationHeader(accessToken: String) -> String {
            let prefix: String
            switch self {
            case .auth: prefix = "OAuth"
            case .helix: prefix = "Bearer"
            case .kraken: prefix = "OAuth"
            }

            return "\(prefix) \(accessToken)"
        }
    }
}

extension API {

    // - MARK: Authentication

    func authenticate(completion: @escaping Completion<[Channel]>) {
        if accessToken != nil {
            // We should be able to get the user info assuming the accessToken is still valid
            API.shared.execute(endpoint: "users", decoding: [Channel].self, completion: completion)
        } else {
            /// - Todo: Authenticate
//            let query = [
//                "client_id": authentication.clientID,
//                "redirect_uri": "byte://auth",
//                "response_type": "token",
//                "scope": "",
//            ].queryParameters()
//
//            executeRaw(base: .auth, endpoint: "authorize", query: query, completion: completion)
        }
    }
}

extension API {
    @discardableResult
    func execute<T>(method: Method = .get, base: Base = .helix, endpoint: String, query: [String: Any?] = [:], page: Pagination? = nil, decoding: T.Type, completion: @escaping Completion<T>) -> URLSessionTask {
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
                    let result = try self.decoder.decode(DataItem<T>.self, from: data)

                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                } catch let de as DecodingError {
                    print("URL from decoding failure = \(request.url?.absoluteString ?? "N/A"), query = \(query)")

                    if let rawData = String(data: data, encoding: .utf8) {
                        print("Raw data from decoding failure = \(rawData)")
                    }

                    DispatchQueue.main.async {
                        completion(.failure(LocalizedDecodingError(decodingError: de)))
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

    func executeFetchAll<T>(method: Method = .get, base: Base = .helix, endpoint: String, query: [String: Any?] = [:], decoding: [T].Type, completion: @escaping Completion<[T]>) where T: Decodable {
        var allItems = [T]()

        func fetch(page: Pagination?) {
            var query = query
            query["after"] = page?.cursor

            execute(method: method, base: base, endpoint: endpoint, query: query, page: page, decoding: decoding) { result in
                switch result {
                case .success(let data):
                    allItems += data.data

                    if data.pagination == nil || data.pagination!.isValid == false || data.data.isEmpty {
                        // All data has been downloaded
                        completion(.success(DataItem<[T]>(data: allItems, pagination: data.pagination)))
                    } else {
                        fetch(page: data.pagination)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        fetch(page: nil)
    }

    @discardableResult
    func executeRaw(method: Method = .get, base: Base = .helix, endpoint: String, query: [String: Any?] = [:], page: Pagination? = nil, completion: @escaping CompletionRaw) -> URLSessionTask {
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
