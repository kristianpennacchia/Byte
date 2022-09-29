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

    private var apiSinkCancellable: AnyCancellable?

    let twitchAPI: TwitchAPI
    let youtubeAPI: YoutubeAPI?

    init(twitchAPI: TwitchAPI, youtubeAPI: YoutubeAPI?) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = youtubeAPI

        // Listen for auth user changes.
        apiSinkCancellable = self.twitchAPI.sink { user in
            self.twitchUser = user
        }
    }

    var twitchUser: Channel? {
        didSet {
            didChange.send(self)
        }
    }
    var youtubeUser: Void?

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

    func signInYoutube(oAuthHandler: @escaping (YoutubeOAuth) -> Void) {
        youtubeAPI?.authenticate(oAuthHandler: { result in
            switch result {
            case .success(let data):
                oAuthHandler(data)
            case .failure(let error):
                Swift.print("Failed to begin Youtube sign-in. \(error.localizedDescription)")
            }
        }, completion: { result in
            switch result {
            case .success(let data):
                #warning("TODO: The user is signed-in... Now what?")
            case .failure(let error):
                Swift.print("Failed to complete Youtube sign-in. \(error.localizedDescription)")
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
