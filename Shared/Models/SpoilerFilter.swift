//
//  SpoilerFilter.swift
//  Byte
//
//  Created by Kristian Pennacchia on 9/11/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import Combine

final class SpoilerFilter: ObservableObject {
    private let didChange = PassthroughSubject<Output, Failure>()

    private var gameIDs = [String]() {
        didSet {
            didChange.send(self)
        }
    }

    init(gameIDs: [String]) {
        self.gameIDs = gameIDs
    }
}

extension SpoilerFilter {
    func isSpoiler(gameID: String) -> Bool {
        gameIDs.contains(gameID)
    }
}

extension SpoilerFilter: Publisher {
    typealias Output = SpoilerFilter
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
