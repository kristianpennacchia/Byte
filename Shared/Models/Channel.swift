//
//  Channel.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Channel: Identifiable, Hashable, Decodable {
    let id: String
    let login: String
    let displayName: String
    let profileImageUrl: String
}

extension Channel {
    struct Stub: Decodable {
        let fromId: String
        let fromName: String
        let toId: String
        let toName: String
    }
}

extension Channel: Comparable {
    static func < (lhs: Channel, rhs: Channel) -> Bool {
        lhs.displayName.caseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }
}

extension Channel {
    static let preview = Channel(
        id: App.previewUsername,
        login: App.previewUsername,
        displayName: App.previewUsername,
        profileImageUrl: ""
    )
}
