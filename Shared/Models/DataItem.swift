//
//  DataItem.swift
//  Byte
//
//  Created by Kristian Pennacchia on 6/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct DataItem<T: Decodable>: Decodable {
    let data: T
    let pagination: Pagination?
}
