//
//  OAuthable.swift
//  Byte
//
//  Created by Kristian Pennacchia on 8/9/2025.
//  Copyright © 2025 Kristian Pennacchia. All rights reserved.
//

import Foundation

protocol OAuthable : Decodable {
	var requestedAt: Date { get }
	var deviceCode: String { get }
	var userCode: String { get }
	var verificationUrl: String { get }
	var expiresIn: UInt { get }
	var interval: UInt { get }
}

extension OAuthable {
	var isExpired: Bool {
		return Date() > requestedAt.addingTimeInterval(TimeInterval(expiresIn))
	}
}
