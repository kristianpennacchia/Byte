//
//  SpoilerFilter.swift
//  Byte
//
//  Created by Kristian Pennacchia on 9/11/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class SpoilerFilter: ObservableObject {
    @AppStorage("spoilerFilterGameIDs") private var spoilerFilterGameIDs: String?

    private let didChange = PassthroughSubject<Output, Failure>()

    private var gameIDs: [String] {
        get {
            return spoilerFilterGameIDs?.components(separatedBy: ",") ?? []
        }
        set {
            spoilerFilterGameIDs = newValue.joined(separator: ",")
            didChange.send(self)
        }
    }
}

extension SpoilerFilter {
    func isSpoiler(gameID: String) -> Bool {
        gameIDs.contains(gameID)
    }

    func add(gameID: String) {
        if isSpoiler(gameID: gameID) == false {
            gameIDs.append(gameID)
        }
    }

    func remove(gameID: String) {
        guard let index = gameIDs.firstIndex(of: gameID) else { return }

        gameIDs.remove(at: index)
    }

    func toggle(gameID: String) {
        if isSpoiler(gameID: gameID) {
            remove(gameID: gameID)
        } else {
            add(gameID: gameID)
        }
    }
}

extension SpoilerFilter: Publisher {
    typealias Output = SpoilerFilter
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
