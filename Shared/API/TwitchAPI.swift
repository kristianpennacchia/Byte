//
//  TwitchAPI.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import KeychainAccess
import OSLog

@MainActor
final class TwitchAPI: ObservableObject {
    struct Authentication {
        let clientID: String
        let privateClientID: String
        let secret: String
    }

	typealias Completion<T> = (_ result: Result<T, Error>) -> Void where T: Decodable

	static var isAvailable: Bool { shared != nil }
    static private(set) var shared: TwitchAPI!

    private let didChange = PassthroughSubject<Output, Failure>()
    private let keychain = Keychain(service: "twitch")

    let session: URLSession
    let authentication: Authentication
    let decoder = JSONDecoder()

	var webAccessToken: String? {
		didSet {
			keychain[KeychainKey.webAccessToken] = webAccessToken
		}
    }
	var accessToken: String? {
        didSet {
            keychain[KeychainKey.accessToken] = accessToken
        }
    }
    var refreshToken: String? {
        didSet {
            keychain[KeychainKey.refreshToken] = refreshToken
        }
    }

	static func setup(authentication: Authentication, webAccessToken: String?, accessToken: String?, refreshToken: String? = nil) {
		shared = TwitchAPI(authentication: authentication, webAccessToken: webAccessToken, accessToken: accessToken, refreshToken: refreshToken)
    }

    private init(authentication: Authentication, webAccessToken: String?, accessToken: String?, refreshToken: String? = nil) {
        self.authentication = authentication
        self.webAccessToken = webAccessToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Client-ID": authentication.clientID
        ]

        session = URLSession(configuration: config)

        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }
}

extension TwitchAPI {
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

extension TwitchAPI {

    // - MARK: Authentication

	func authenticate(oAuthHandler: @escaping Completion<TwitchOAuth>, completion: @escaping Completion<TwitchDataItem<[Channel]>>) {
        if accessToken != nil {
			// We should be able to get the user info assuming the accessToken is still valid.
			Task {
				do {
					let person = try await getAuthenticatedPerson()

					DispatchQueue.main.async {
						completion(.success(person))
					}
				} catch {
					Logger.youtube.debug("Failed getting user info. \(error.localizedDescription)")
					DispatchQueue.main.async {
						completion(.failure(error))
					}
				}
			}
        } else {
			let query = [
				"client_id": authentication.clientID,
				"scopes": "user:read:follows",
			]

			Task {
				do {
					let data = try await executeUnwrapped(method: .post, base: .auth, endpoint: "device", query: query, decoding: TwitchOAuth.self)

					DispatchQueue.main.async {
						oAuthHandler(.success(data))
					}

					Logger.twitch.debug("Polling for user to complete OAuth.")

					// Continuously poll 'https://id.twitch.tv/oauth2/token' every `data.interval` seconds until we get a success or failure response.
					let pollQuery = [
						"client_id": authentication.clientID,
						"scopes": "user:read:follows",
						"device_code": data.deviceCode,
						"grant_type": "urn:ietf:params:oauth:grant-type:device_code",
					]

					poll: repeat {
						guard data.isExpired == false else {
							DispatchQueue.main.async {
								oAuthHandler(.failure(APIError.unknown))
							}
							break poll
						}

						try! await Task.sleep(seconds: TimeInterval(data.interval))

						do {
							let userAuth = try await executeUnwrapped(method: .post, base: .auth, endpoint: "token", query: pollQuery, decoding: TwitchUserAuth.self)

							accessToken = userAuth.accessToken
							refreshToken = userAuth.refreshToken ?? refreshToken

							// Get user data.
							let person = try await getAuthenticatedPerson()
							DispatchQueue.main.async {
								completion(.success(person))
							}

							break poll
						} catch let error as TwitchAuthError {
							if error.reason != .authorizationPending {
								Logger.twitch.error("Failed getting Twitch OAuth response. \(error.localizedDescription)")
								DispatchQueue.main.async {
									completion(.failure(error))
								}
								break poll
							}
						} catch {
							Logger.twitch.error("Failed getting Twitch OAuth response. \(error.localizedDescription)")
							DispatchQueue.main.async {
								completion(.failure(error))
							}
							break poll
						}
					} while true
				} catch {
					Logger.twitch.error("Failed getting Twitch OAuth response. \(error.localizedDescription)")
					DispatchQueue.main.async {
						oAuthHandler(.failure(error))
					}
				}
			}
        }
    }

    func refreshAccessToken() async throws -> TwitchDataItem<[Channel]> {
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
			let userAuth = try await executeUnwrapped(method: .post, base: .auth, endpoint: "token", query: query, decoding: TwitchUserAuth.self)
			accessToken = userAuth.accessToken
			self.refreshToken = userAuth.refreshToken ?? refreshToken

            let users = try await getAuthenticatedPerson()
            if let user = users.data.first {
                didChange.send(user)
            }

            return users
        } catch {
            // Refreshing user access token failed, which likely means the refresh token is no longer valid.
			self.accessToken = nil
            self.refreshToken = nil
            throw error
        }
    }

	func getAuthenticatedPerson() async throws -> TwitchDataItem<[Channel]> {
		return try await execute(method: .get, endpoint: "users", decoding: [Channel].self)
	}
}

extension TwitchAPI {
	@discardableResult
	func executeUnwrapped<T: Decodable>(method: Method, base: Base = .helix, endpoint: String, query: [String: Any?] = [:], decoding: T.Type) async throws -> T {
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
			return try decoder.decode(T.self, from: data)
		} catch let decodingError as DecodingError {
			Logger.twitch.error("URL from decoding failure = \(request.url?.absoluteString ?? "N/A"), query = \(query)")

			if let rawData = String(data: data, encoding: .utf8) {
				Logger.twitch.error("Raw data from decoding failure = \(rawData)")
			}

			do {
				let twitchError = try self.decoder.decode(TwitchError.self, from: data)
				if twitchError.status == 401 {
					// Authentication failure. The access token has become invalid, try to refresh it.
					_ = try await refreshAccessToken()
					return try await executeUnwrapped(method: method, base: base, endpoint: endpoint, query: query, decoding: decoding)
				}
			} catch {
				throw try self.decoder.decode(TwitchAuthError.self, from: data)
			}

			throw LocalizedDecodingError(decodingError: decodingError)
		}
	}

    @discardableResult
    func execute<T>(method: Method, base: Base = .helix, endpoint: String, query: [String: Any?] = [:], decoding: T.Type) async throws -> TwitchDataItem<T> {
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
            return try decoder.decode(TwitchDataItem<T>.self, from: data)
        } catch let decodingError as DecodingError {
			Logger.twitch.error("URL from decoding failure = \(request.url?.absoluteString ?? "N/A"), query = \(query)")

            if let rawData = String(data: data, encoding: .utf8) {
				Logger.twitch.error("Raw data from decoding failure = \(rawData)")
            }

            do {
                let twitchError = try self.decoder.decode(TwitchError.self, from: data)
                if twitchError.status == 401 {
                    // Authentication failure. The access token has become invalid, try to refresh it.
                    _ = try await refreshAccessToken()
                    return try await execute(method: method, base: base, endpoint: endpoint, query: query, decoding: decoding)
                } else {
                    throw LocalizedDecodingError(decodingError: decodingError)
                }
            } catch {
                throw LocalizedDecodingError(decodingError: decodingError)
            }
        }
    }

    func executeFetchAll<T>(method: Method, base: Base = .helix, endpoint: String, query: [String: Any?] = [:], decoding: [T].Type) async throws -> TwitchDataItem<[T]> where T: Decodable {
        var allItems = [T]()
        var currentDataItem: TwitchDataItem<[T]>?

        repeat {
            var query = query
            query["after"] = currentDataItem?.pagination?.cursor

            currentDataItem = try await execute(method: method, base: base, endpoint: endpoint, query: query, decoding: decoding)
            allItems += currentDataItem!.data
        } while currentDataItem?.pagination != nil && currentDataItem!.pagination!.isValid && currentDataItem!.data.isEmpty == false

        return TwitchDataItem<[T]>(data: allItems, pagination: currentDataItem?.pagination)
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

extension TwitchAPI: @preconcurrency Publisher {
    typealias Output = Channel
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
