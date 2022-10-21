//
//  YtdlpFormat.swift
//  Byte
//
//  Created by Kristian Pennacchia on 21/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YtdlpFormat: Decodable {
    let filesize: UInt?
    let width: Int?
    let height: Int?
    let ext: String
    let acodec: String
    let vcodec: String
    let resolution: String
    let url: URL
    var hasAudio: Bool { acodec != "none" }
    var hasVideo: Bool { vcodec != "none" }
    var isMedia: Bool { hasAudio || hasVideo }
    var isAudioOnly: Bool { hasAudio && !hasVideo }
    var isVideoOnly: Bool { !hasAudio && hasVideo }
}

extension YtdlpFormat: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.filesize ?? 0) < (rhs.filesize ?? 0)
    }
}
