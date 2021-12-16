//
//  M3U8.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct M3U8 {
    enum Error: String, LocalizedError {
        case decodeFailure = "Failed to decode data into a valid string."
        case urlParseFailure = "Failed to parse m3u8 URLs from decoded string."

        var errorDescription: String? { return rawValue }
    }

    private static let videoMetadataRegex = ##"#EXT-X-MEDIA:TYPE=(\w+).*GROUP-ID=("\w+").*NAME=("[\w].+").*"##
    private static let videoAdvancedMetadataRegex = ##"#EXT-X-STREAM-INF:.*BANDWIDTH=(\d+).*(?:RESOLUTION=([\dx]+))?.*"##
    private static let urlRegex = #"https:\/\/.*\.m3u8"#

    let rawText: String
    let meta: [Meta]

    init(data: Data) throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw Error.decodeFailure
        }

        rawText = text

        let basicMetadata = text.substrings(matching: Self.videoMetadataRegex)
        let advancedMetadata = text.substrings(matching: Self.videoAdvancedMetadataRegex)
        let urls = text.substrings(matching: Self.urlRegex)

        guard urls.isEmpty == false else {
            throw Error.urlParseFailure
        }

        meta = zip(urls, zip(basicMetadata, advancedMetadata)).map { url, metadata in
            let (basic, advanced) = metadata
            return Meta(url: String(url), metadata: String(basic), advancedMetadata: String(advanced))
        }
    }
}

extension M3U8: CustomStringConvertible {
    var description: String {
        return meta.map { $0.description }.joined(separator: "\n")
    }
}
