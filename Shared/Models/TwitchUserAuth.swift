//
//  TwitchUserAuth.swift
//  Byte
//
//  Created by Kristian Pennacchia on 8/9/2025.
//  Copyright © 2025 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct TwitchUserAuth: Decodable {
	let accessToken: String
	let expiresIn: UInt
	let scope: [String]
	let tokenType: String
	let refreshToken: String?
}
