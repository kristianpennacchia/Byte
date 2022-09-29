//
//  YoutubeSecrets.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeSecrets: Decodable {
    struct ClientID: Decodable {
        let byte: String
    }

    struct Secret: Decodable {
        let byte: String
    }

    let clientID: ClientID
    let secret: Secret
}
