//
//  SessionStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import Combine
import OSLog

@MainActor
final class SessionStore: ObservableObject {
    private let didChange = PassthroughSubject<Output, Failure>()

    private var twitchAPISinkCancellable: AnyCancellable?
    private var youtubeAPISinkCancellable: AnyCancellable?

    let twitchAPI: TwitchAPI?
    let youtubeAPI: YoutubeAPI?

    init(twitchAPI: TwitchAPI?, youtubeAPI: YoutubeAPI?) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = youtubeAPI

        // Listen for auth user changes.
        twitchAPISinkCancellable = self.twitchAPI?.sink { user in
            self.twitchUser = user
        }
        youtubeAPISinkCancellable = self.youtubeAPI?.sink { user in
            self.youtubeUser = user
        }
    }

    var twitchUser: Channel? {
        didSet {
            didChange.send(self)
        }
    }
    var youtubeUser: YoutubePerson? {
        didSet {
            didChange.send(self)
        }
    }
	var twitchAuthError: Error? {
		didSet {
			didChange.send(self)
		}
	}
	var youtubeAuthError: Error? {
		didSet {
			didChange.send(self)
		}
	}
	var hasAttemptedTwitchAuth: Bool {
		return twitchUser != nil || twitchAuthError != nil
	}
	var hasAttemptedYoutubeAuth: Bool {
		return youtubeUser != nil || youtubeAuthError != nil
	}

    func signInTwitch() {
		guard let twitchAPI else {
			twitchAuthError = APIError.noAuth
			return
		}

        Task {
            do {
                twitchUser = try await twitchAPI.getAuthenticatedPerson().data.first
            } catch {
				Logger.twitch.error("Failed Twitch sign-in. \(error)")
				twitchAuthError = error
            }
        }
    }

    func signInYoutube() {
		guard let youtubeAPI else {
			youtubeAuthError = APIError.noAuth
			return
		}

        Task {
            do {
                youtubeUser = try await youtubeAPI.getAuthenticatedPerson()
            } catch {
				Logger.youtube.error("Failed Youtube sign-in. \(error)")
				youtubeAuthError = error
            }
        }
    }

    func startTwitchOAuth(oAuthHandler: @escaping (Result<TwitchOAuth, Error>) -> Void, completion: @escaping (Result<Channel, Error>) -> Void) {
        twitchAPI?.authenticate(oAuthHandler: { result in
            if case .failure(let error) = result {
				Logger.twitch.error("Failed to begin Twitch OAuth flow. \(error.localizedDescription)")
            }

            oAuthHandler(result)
        }, completion: { result in
            switch result {
            case .success(let data):
                // The user is signed-in.
				self.twitchUser = data.data.first!
                completion(.success(self.twitchUser!))
            case .failure(let error):
				Logger.twitch.error("Failed to complete Twitch sign-in. \(error.localizedDescription)")
                completion(.failure(error))
            }
        })
    }

	func startYoutubeOAuth(oAuthHandler: @escaping (Result<YoutubeOAuth, Error>) -> Void, completion: @escaping (Result<YoutubePerson, Error>) -> Void) {
        youtubeAPI?.authenticate(oAuthHandler: { result in
            if case .failure(let error) = result {
				Logger.youtube.error("Failed to begin Youtube OAuth flow. \(error.localizedDescription)")
            }

            oAuthHandler(result)
        }, completion: { result in
            switch result {
            case .success(let data):
                // The user is signed-in.
                self.youtubeUser = data
                completion(.success(self.youtubeUser!))
            case .failure(let error):
				Logger.youtube.error("Failed to complete Youtube sign-in. \(error.localizedDescription)")
                completion(.failure(error))
            }
        })
    }

    func signOut() {
        twitchUser = nil
        youtubeUser = nil
    }
}

extension SessionStore: @preconcurrency Publisher {
    typealias Output = SessionStore
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
