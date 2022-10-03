//
//  Strings+Extensions.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

extension String {
    func substrings(matching pattern: String) -> [Substring] {
        do {
            let expression = try NSRegularExpression(pattern: pattern, options: [])
            let matches = expression.matches(in: self, options: [], range: NSRange((startIndex...).relative(to: self), in: self))
            return matches
                .compactMap { result in
                    if let range = Range(result.range, in: self) {
                        return self[range]
                    } else {
                        return nil
                    }
            }
        } catch {
            return []
        }
    }
}
