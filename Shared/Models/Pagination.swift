//
//  Pagination.swift
//  Byte
//
//  Created by Kristian Pennacchia on 6/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Pagination: Decodable {
    let cursor: String?
    var isValid: Bool { cursor != nil && cursor != "IA" }
}
