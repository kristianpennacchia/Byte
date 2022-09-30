//
//  SessionStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import Combine

final class SessionStore: ObservableObject {
    private let didChange = PassthroughSubject<Output, Failure>()

    private var twitchAPISinkCancellable: AnyCancellable?

    let twitchAPI: TwitchAPI
    let youtubeAPI: YoutubeAPI?

    init(twitchAPI: TwitchAPI, youtubeAPI: YoutubeAPI?) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = youtubeAPI

        // Listen for auth user changes.
        twitchAPISinkCancellable = self.twitchAPI.sink { user in
            self.twitchUser = user
        }
    }

    var twitchUser: Channel? {
        didSet {
            didChange.send(self)
        }
    }
    var youtubeUser: Data? {
        didSet {
            didChange.send(self)
        }
    }

    func signInTwitch() {
        twitchAPI.authenticate { [weak self] result in
            switch result {
            case .success(let data):
                self?.twitchUser = data.data.first
            case .failure(let error):
                Swift.print("Failed sign-in. \(error)")
            }
        }
    }

    func signInYoutube(oAuthHandler: @escaping (Result<YoutubeOAuth, Error>) -> Void, completion: @escaping (_ error: Error?) -> Void) {
        youtubeAPI?.authenticate(oAuthHandler: { result in
            if case .failure(let error) = result {
                Swift.print("Failed to begin Youtube OAuth flow. \(error.localizedDescription)")
            }

            oAuthHandler(result)
        }, completion: { result in
            switch result {
            case .success(let data):
                // The user is signed-in.
                self.youtubeUser = data
                completion(nil)
            case .failure(let error):
                Swift.print("Failed to complete Youtube sign-in. \(error.localizedDescription)")
                completion(error)
            }
        })
    }

    func signOut() {
        twitchUser = nil
    }
}

extension SessionStore: Publisher {
    typealias Output = SessionStore
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
