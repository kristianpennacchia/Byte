//
//  CodableIgnored.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

@propertyWrapper
struct CodableIgnored<T>: Codable, Hashable where T: Hashable {
    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        self.wrappedValue = nil
    }

    func encode(to encoder: Encoder) throws {
        // Do nothing
    }
}

extension KeyedDecodingContainer {
    func decode<T>(_ type: CodableIgnored<T>.Type, forKey key: Self.Key) throws -> CodableIgnored<T> {
        return CodableIgnored(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    mutating func encode<T>(_ value: CodableIgnored<T>, forKey key: KeyedEncodingContainer<K>.Key) throws {
        // Do nothing
    }
}
