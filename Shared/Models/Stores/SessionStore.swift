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

    let api: API

    init(api: API) {
        self.api = api
    }

    var user: Channel? {
        didSet {
            didChange.send(self)
        }
    }

    func signIn() {
        api.authenticate { [weak self] result in
            switch result {
            case .success(let data):
                self?.user = data.data.first
            case .failure(let error):
                Swift.print("Failed sign-in. \(error)")
            }
        }
    }

    func signOut() {
        user = nil
    }
}

extension SessionStore: Publisher {
    typealias Output = SessionStore
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
