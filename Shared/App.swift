//
//  App.swift
//  Byte
//
//  Created by Kristian Pennacchia on 5/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import KeychainAccess

enum App {
    private struct ServiceSecrets: Decodable {
        let twitch: TwitchSecrets
        let youtube: YoutubeSecrets?
    }

    private(set) static var previewUsername: String!

    static func setup() {
        let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: "Secrets", withExtension: "json")!)
        let decoder = JSONDecoder()
        let serviceSecrets = try! decoder.decode(ServiceSecrets.self, from: jsonData)

        previewUsername = serviceSecrets.twitch.previewUsername

        let keychain = Keychain(service: "twitch")

        if keychain[KeychainKey.accessToken] == nil {
            keychain[KeychainKey.accessToken] = serviceSecrets.twitch.oAuthToken.byteUserAccessToken
        }

        if keychain[KeychainKey.refreshToken] == nil {
            keychain[KeychainKey.refreshToken] = serviceSecrets.twitch.oAuthToken.byteUserRefreshToken
        }

        TwitchAPI.setup(
            authentication: Authentication(
                clientID: serviceSecrets.twitch.clientID.byte,
                privateClientID: serviceSecrets.twitch.clientID.twitch,
                secret: serviceSecrets.twitch.secret.byte
            ),
            accessToken: keychain[KeychainKey.accessToken],
            refreshToken: keychain[KeychainKey.refreshToken]
        )
    }
}
