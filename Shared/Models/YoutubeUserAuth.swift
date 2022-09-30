//
//  YoutubeUserAuth.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeUserAuth: Decodable {
    let accessToken: String
    let expiresIn: UInt
    let scope: String
    let tokenType: String
    let refreshToken: String
}
