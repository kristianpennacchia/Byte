//
//  YoutubeOAuth.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeOAuth: Decodable {
    let deviceCode: String
    let userCode: String
    let verificationUrl: String
    let expiresIn: UInt
    let interval: UInt
}
