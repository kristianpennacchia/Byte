//
//  Channel.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Channel: Decodable, Channelable {
    static var platform = VideoPlatform.twitch

    let id: String
    let login: String
    let displayName: String
    let profileImageUrl: String

    var channelId: String { id }
}

extension Channel {
    struct Stub: Decodable {
        let broadcasterId: String
        let broadcasterName: String
    }
}

extension Channel: Comparable {
    static func < (lhs: Channel, rhs: Channel) -> Bool {
        lhs.displayName.caseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }
}
