//
//  M3U8Meta.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

extension M3U8 {
    struct Meta: Equatable {
        let url: String
        let metadata: String
        let advancedMetadata: String
        let name: String?
        let resolution: String?
        let bandwidth: Int
        let codecs: String?
        var isAudioOnly: Bool { name?.contains("audio") ?? false }

        init(url: String, metadata: String, advancedMetadata: String) {
            self.url = url
            self.metadata = metadata
            self.advancedMetadata = advancedMetadata
            self.name = Self.getPart(from: metadata, key: "NAME=", breakAt: ",")
            self.resolution = Self.getPart(from: advancedMetadata, key: "RESOLUTION=", breakAt: ",")
            if let bandwidth = Self.getPart(from: advancedMetadata, key: "BANDWIDTH=", breakAt: ",") {
                self.bandwidth = Int(bandwidth) ?? 0
            } else {
                self.bandwidth = 0
            }
            self.codecs = Self.getPart(from: advancedMetadata, key: "CODECS=", breakAt: "\",")
        }
    }
}

extension M3U8.Meta {
    private static func getPart(from text: String, key: String, breakAt: String) -> String? {
        guard let keyRange = text.range(of: key) else { return nil }

        let rangeAfterKey = (keyRange.upperBound...).relative(to: text)
        let value: String
        if let endIndex = text.range(of: breakAt, options: .literal, range: rangeAfterKey) {
            // Use the lower bound of the end index because we do not want to include the breaking string in the value
            let adjustedEnd = text.index(before: endIndex.lowerBound)
            value = String(text[(rangeAfterKey.lowerBound...adjustedEnd).relative(to: text)])
        } else {
            // Assume the value will be from the end of the key range to the end of the text
            let adjustedKeyEnd = text.index(before: keyRange.upperBound)
            value = String(text[(adjustedKeyEnd...).relative(to: text)])
        }

        return value.replacingOccurrences(of: "\"", with: "")
    }
}

extension M3U8.Meta: Comparable {
    static func < (lhs: M3U8.Meta, rhs: M3U8.Meta) -> Bool {
        lhs.bandwidth < rhs.bandwidth
    }
}

extension M3U8.Meta: CustomStringConvertible {
    var description: String {
        return """
        url = \(url)
        name = \(String(describing: name))
        resolution = \(String(describing: resolution))
        bandwidth = \(String(describing: bandwidth))
        codecs = \(String(describing: codecs))
        """
    }
}
