//
//  TwitchOAuth.swift
//  Byte
//
//  Created by Kristian Pennacchia on 8/9/2025.
//  Copyright © 2025 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct TwitchOAuth: OAuthable {
	let requestedAt = Date()
	let deviceCode: String
	let userCode: String
	var verificationUrl: String { verificationUri }
	let verificationUri: String
	let expiresIn: UInt
	let interval: UInt
}
