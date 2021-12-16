//
//  Video.swift
//  Byte
//
//  Created by Kristian Pennacchia on 11/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Video: Identifiable, Hashable, Decodable {
    enum VideoType: String, Decodable {
        case upload, archive, highlight
    }

    enum Viewable: String, Decodable {
        case `public`, `private`
    }

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
    static let preview = Video(
        id: App.previewUsername,
        type: .archive,
        title: "My Amazing Stream!!?!?",
        description: "Wow I'm so fucking good",
        createdAt: .init(),
        duration: "1hr 30m",
        thumbnailUrl: "",
        url: "",
        viewable: .public,
        viewCount: 696969
    )

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
