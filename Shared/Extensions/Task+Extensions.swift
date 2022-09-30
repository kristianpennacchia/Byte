//
//  Task+Extensions.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
