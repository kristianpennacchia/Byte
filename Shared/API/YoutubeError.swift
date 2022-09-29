//
//  YoutubeError.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeError: LocalizedError, Decodable {
    let errorCode: String
}
