//
//  TwitchError.swift
//  Byte
//
//  Created by Kristian Pennacchia on 24/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct TwitchError: Decodable {
    let error: String
    let status: Int
    let message: String?
}
