//
//  Array+Twitch.swift
//  Byte
//
//  Created by Kristian Pennacchia on 9/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element: Numeric & Comparable {
    func closest(_ givenValue: Element) -> Element? {
        let sortedArray = sorted()

        let over = sortedArray.first { $0 >= givenValue }
        let under = sortedArray.last { $0 <= givenValue }

        if over == nil && under == nil {
            return nil
        } else if over == nil {
            return under!
        } else if under == nil {
            return over!
        }

        let diffOver = over! - givenValue
        let diffUnder = givenValue - under!

        return (diffOver < diffUnder) ? over : under
    }
}

extension Array where Element: Comparable {
    func closest<N>(_ givenValue: N, keyPath: KeyPath<Element, N>) -> Element? where N: Numeric & Comparable {
        let sortedArray = sorted()

        let over = sortedArray.first { $0[keyPath: keyPath] >= givenValue }
        let under = sortedArray.last { $0[keyPath: keyPath] <= givenValue }

        if over == nil && under == nil {
            return nil
        } else if over == nil {
            return under!
        } else if under == nil {
            return over!
        }

        let diffOver = over![keyPath: keyPath] - givenValue
        let diffUnder = givenValue - under![keyPath: keyPath]

        return (diffOver < diffUnder) ? over : under
    }
}
