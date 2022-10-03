//
//  YoutubeError2.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeError2: LocalizedError, Decodable {
    struct NestedError: Decodable {
        let code: Int
        let message: String
        let status: String?
    }

    let error: NestedError

    var errorDescription: String? {
        if let status = error.status {
            return "(\(error.code)) [status: \(status)] \(error.message)"
        } else {
            return "(\(error.code)) \(error.message)"
        }
    }
}
