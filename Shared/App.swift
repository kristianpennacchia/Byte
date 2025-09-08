//
//  App.swift
//  Byte
//
//  Created by Kristian Pennacchia on 5/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import KeychainAccess
import SwiftUI

enum App {
    private struct ServiceSecrets: Decodable {
        let twitch: TwitchSecrets?
        let youtube: YoutubeSecrets?
    }

    @AppStorage("launchCount") private static var launchCount = 0

    private(set) static var previewUsername: String!

	@MainActor static func setup() {
        let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: "Secrets", withExtension: "json")!)
        let decoder = JSONDecoder()
        let serviceSecrets = try! decoder.decode(ServiceSecrets.self, from: jsonData)

        previewUsername = serviceSecrets.twitch?.previewUsername ?? "testuser123"

        let twitchKeychain = Keychain(service: "twitch")
        let youtubeKeychain = Keychain(service: "youtube")

        if launchCount == 0 {
            try? twitchKeychain.removeAll()
            try? youtubeKeychain.removeAll()
        }
        launchCount += 1

		if let twitchSecrets = serviceSecrets.twitch {
			TwitchAPI.setup(
				authentication: .init(
					clientID: twitchSecrets.clientID.byte,
					privateClientID: twitchSecrets.clientID.twitch,
					secret: twitchSecrets.secret.byte
				),
				webAccessToken: twitchSecrets.oAuthToken?.webUserAccessToken ?? twitchKeychain[KeychainKey.webAccessToken],
				accessToken: twitchSecrets.oAuthToken?.byteUserAccessToken ?? twitchKeychain[KeychainKey.accessToken],
				refreshToken: twitchSecrets.oAuthToken?.byteUserRefreshToken ?? twitchKeychain[KeychainKey.refreshToken]
			)
		}

        if let youtubeSecrets = serviceSecrets.youtube {
            YoutubeAPI.setup(authentication: .init(
                clientID: youtubeSecrets.clientID.byte,
                secret: youtubeSecrets.secret.byte
            ))
        }
    }
}
