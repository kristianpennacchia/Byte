//
//  Dictionary+Extensions.swift
//  Byte
//
//  Created by Kristian Pennacchia on 9/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any? {
    /// Converts Dictionary into query parameters, while filtering out nil values.
    /// E.g. `["one": 1, "two": nil]` becomes `"one=1"`.
    func queryParameters() -> String {
        return filter { $0.value != nil }
            .map { key, value in
                if let array = value as? [Any] {
                    return array.map { "\(key)=\($0)" }.joined(separator: "&")
                } else {
                    return "\(key)=\(value!)"
                }
        }
        .joined(separator: "&")
    }
}
