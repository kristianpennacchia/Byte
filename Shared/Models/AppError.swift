//
//  AppError.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct AppError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
