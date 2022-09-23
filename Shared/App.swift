//
//  App.swift
//  Byte
//
//  Created by Kristian Pennacchia on 5/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

enum App {
    private struct SecretKeys: Decodable {
        struct ClientID: Decodable {
            let twitch: String
            let byte: String
        }

        struct Secret: Decodable {
            let byte: String
        }

        struct OAuthToken: Decodable {
            let byteUserMe: String
        }

        let previewUsername: String
        let clientID: ClientID
        let secret: Secret
        let oAuthToken: OAuthToken
    }

    private(set) static var previewUsername: String!

    static func setup() {
        let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: "Secrets", withExtension: "json")!)
        let decoder = JSONDecoder()
        let secretKeys = try! decoder.decode(SecretKeys.self, from: jsonData)

        previewUsername = secretKeys.previewUsername

        API.setup(
            authentication: Authentication(
                clientID: secretKeys.clientID.byte,
                privateClientID: secretKeys.clientID.twitch,
                secret: secretKeys.secret.byte
            ),
            accessToken: secretKeys.oAuthToken.byteUserMe
        )
    }
}
