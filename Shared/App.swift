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
        let twitch: TwitchSecrets
        let youtube: YoutubeSecrets?
    }

    @AppStorage("launchCount") private static var launchCount = 0

    private(set) static var previewUsername: String!

	@MainActor static func setup() {
        let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: "Secrets", withExtension: "json")!)
        let decoder = JSONDecoder()
        let serviceSecrets = try! decoder.decode(ServiceSecrets.self, from: jsonData)

        previewUsername = serviceSecrets.twitch.previewUsername

        let twitchKeychain = Keychain(service: "twitch")
        let youtubeKeychain = Keychain(service: "youtube")

        if launchCount == 0 {
            try? twitchKeychain.removeAll()
            try? youtubeKeychain.removeAll()
        }
        launchCount += 1

		if twitchKeychain[KeychainKey.webAccessToken] == nil {
			twitchKeychain[KeychainKey.webAccessToken] = serviceSecrets.twitch.oAuthToken.webUserAccessToken
		}

        if twitchKeychain[KeychainKey.accessToken] == nil {
            twitchKeychain[KeychainKey.accessToken] = serviceSecrets.twitch.oAuthToken.byteUserAccessToken
        }

        if twitchKeychain[KeychainKey.refreshToken] == nil {
            twitchKeychain[KeychainKey.refreshToken] = serviceSecrets.twitch.oAuthToken.byteUserRefreshToken
        }

        TwitchAPI.setup(
            authentication: .init(
                clientID: serviceSecrets.twitch.clientID.byte,
                privateClientID: serviceSecrets.twitch.clientID.twitch,
                secret: serviceSecrets.twitch.secret.byte
            ),
			webAccessToken: twitchKeychain[KeychainKey.webAccessToken]!,
            accessToken: twitchKeychain[KeychainKey.accessToken]!,
            refreshToken: twitchKeychain[KeychainKey.refreshToken]
        )

        if let youtubeSecrets = serviceSecrets.youtube {
            YoutubeAPI.setup(authentication: .init(
                clientID: youtubeSecrets.clientID.byte,
                secret: youtubeSecrets.secret.byte
            ))
        }
    }
}
