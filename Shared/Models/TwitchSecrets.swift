//
//  TwitchSecrets.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct TwitchSecrets: Decodable {
    struct ClientID: Decodable {
        let twitch: String
        let byte: String
    }

    struct Secret: Decodable {
        let byte: String
    }

    struct OAuthToken: Decodable {
        let webUserAccessToken: String?
        let byteUserAccessToken: String
        let byteUserRefreshToken: String?
    }

    let previewUsername: String?
    let clientID: ClientID
    let secret: Secret
    let oAuthToken: OAuthToken?
}
