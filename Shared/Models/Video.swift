//
//  Video.swift
//  Byte
//
//  Created by Kristian Pennacchia on 11/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Video: Videoable, Decodable {
    enum VideoType: String, Decodable {
        case upload, archive, highlight
    }

    enum Viewable: String, Decodable {
        case `public`, `private`
    }

    static let platform = VideoPlatform.twitch

    let id: String
    let type: VideoType
    let title: String
    let description: String
    let createdAt: Date
    let duration: String
    let thumbnailUrl: String
    let url: String
    let viewable: Viewable
    let viewCount: Int
}

extension Video {
    func thumbnail(size: Int) -> String {
        thumbnailUrl
            .replacingOccurrences(of: "{width}", with: "\(size)")
            .replacingOccurrences(of: "{height}", with: "\(size)")
    }
}

extension Video: Comparable {
    static func < (lhs: Video, rhs: Video) -> Bool {
        lhs.createdAt < rhs.createdAt
    }
}
