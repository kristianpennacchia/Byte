//
//  AppState.swift
//  Byte
//
//  Created by Kristian Pennacchia on 28/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    enum State {
        case didBecomeActive, willResignActive, willEnterForeground, didEnterBackground
    }

	private let didChange = PassthroughSubject<Output, Failure>()

    private var didBecomeActiveToken: NSObjectProtocol?
    private var willResignActiveToken: NSObjectProtocol?
    private var willEnterForegroundToken: NSObjectProtocol?
    private var didEnterBackgroundToken: NSObjectProtocol?

    init() {
        didBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
			DispatchQueue.main.async { [weak self] in
				self?.didBecomeActive()
			}
        }
        willResignActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
			DispatchQueue.main.async { [weak self] in
				self?.willResignActive()
			}
        }
        willEnterForegroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
			DispatchQueue.main.async { [weak self] in
				self?.willEnterForeground()
			}
        }
        didEnterBackgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
			DispatchQueue.main.async { [weak self] in
				self?.didEnterBackground()
			}
        }
    }
}

private extension AppState {
	func didBecomeActive() {
        didChange.send(.didBecomeActive)
    }

    func willResignActive() {
        didChange.send(.willResignActive)
    }

    func willEnterForeground() {
        didChange.send(.willEnterForeground)
    }

    func didEnterBackground() {
        didChange.send(.didEnterBackground)
    }
}

extension AppState: @preconcurrency Publisher {
    typealias Output = State
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        didChange.receive(subscriber: subscriber)
    }
}
