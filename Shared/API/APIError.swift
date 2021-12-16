//
//  APIError.swift
//  Byte
//
//  Created by Kristian Pennacchia on 6/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

enum APIError: LocalizedError {
    case unknown
    case invalidData(Any.Type)

    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown API error occured."
        case .invalidData(let type):
            return "Invalid data retrived for '\(type)'."
        }
    }
}
