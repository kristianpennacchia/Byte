//
//  Channelable.swift
//  Byte
//
//  Created by Kristian Pennacchia on 7/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

func equalsChannelable(lhs: any Channelable, rhs: any Channelable) -> Bool {
    return lhs.channelId == rhs.channelId
}

func compareChannelable(lhs: any Channelable, rhs: any Channelable) -> Bool {
    return lhs.displayName < rhs.displayName
}

let channelPreview = Channel(
    id: App.previewUsername,
    login: App.previewUsername,
    displayName: App.previewUsername,
    profileImageUrl: ""
)

protocol Channelable: Identifiable, Equatable, Hashable, Comparable {
    static var platform: VideoPlatform { get }

    var channelId: String { get }
    var displayName: String { get }
    var profileImageUrl: String { get }
}

extension Channelable where Self: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        equalsChannelable(lhs: lhs, rhs: rhs)
    }
}

extension Channelable where Self: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        compareChannelable(lhs: lhs, rhs: rhs)
    }
}
