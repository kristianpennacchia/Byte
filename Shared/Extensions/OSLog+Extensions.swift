//
//  OSLog+Extensions.swift
//  Byte
//
//  Created by Kristian Pennacchia on 7/8/2023.
//  Copyright © 2023 Kristian Pennacchia. All rights reserved.
//

import OSLog

extension Logger {
	static let streaming = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Streaming")
	static let twitch = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Twitch")
	static let youtube = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Youtube")
}
