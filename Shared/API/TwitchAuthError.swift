//
//  TwitchAuthError.swift
//  Byte
//
//  Created by Kristian Pennacchia on 8/9/2025.
//  Copyright © 2025 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct TwitchAuthError: LocalizedError, Decodable {
	enum Reason {
		case unknown
		case authorizationPending
		case invalidDeviceCode
		case invalidRefreshToken
	}

    let status: Int
    let message: String

	var reason: Reason {
		switch message.lowercased() {
		case "authorization_pending":
			return .authorizationPending
		case "invalid device code":
			return .invalidDeviceCode
		case "invalid refresh token":
			return .invalidRefreshToken
		default:
			return .unknown
		}
	}
}
