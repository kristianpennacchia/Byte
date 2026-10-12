//
//  AppState.swift
//  Byte
//
//  Created by Kristian Pennacchia on 28/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import UIKit
import Combine

struct AppState: Publisher {
	enum State {
		case didBecomeActive, willResignActive, willEnterForeground, didEnterBackground
	}

	typealias Output = State
	typealias Failure = Never

	func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
		Publishers.MergeMany(
			publisher(for: UIApplication.didBecomeActiveNotification, sending: .didBecomeActive),
			publisher(for: UIApplication.willResignActiveNotification, sending: .willResignActive),
			publisher(for: UIApplication.willEnterForegroundNotification, sending: .willEnterForeground),
			publisher(for: UIApplication.didEnterBackgroundNotification, sending: .didEnterBackground)
		)
		.receive(on: DispatchQueue.main)
		.receive(subscriber: subscriber)
	}
}

private extension AppState {
	func publisher(for name: Notification.Name, sending state: State) -> Publishers.Map<NotificationCenter.Publisher, State> {
		NotificationCenter.default.publisher(for: name).map { _ in state }
	}
}

