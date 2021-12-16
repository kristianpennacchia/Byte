//
//  LocalizedDecodingError.swift
//  Byte
//
//  Created by Kristian Pennacchia on 6/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct LocalizedDecodingError: LocalizedError {
    let decodingError: DecodingError

    var errorDescription: String? { (decodingError as NSError).userInfo[NSDebugDescriptionErrorKey] as? String }
}
