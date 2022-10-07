//
//  Videoable.swift
//  Byte
//
//  Created by Kristian Pennacchia on 7/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

func equalsVideoable(lhs: any Videoable, rhs: any Videoable) -> Bool {
    return lhs.id == rhs.id
}

func compareVideoable(lhs: any Videoable, rhs: any Videoable) -> Bool {
    return lhs.createdAt > rhs.createdAt
}

let videoPreview = Video(
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

protocol Videoable: Identifiable, Hashable, Decodable {
    static var platform: VideoPlatform { get }

    var id: String { get }
    var title: String { get }
    var createdAt: Date { get }
    var duration: String? { get }

    func thumbnail(size: Int) -> String
}

extension Videoable where Self: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        equalsVideoable(lhs: lhs, rhs: rhs)
    }
}

extension Videoable where Self: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        compareVideoable(lhs: lhs, rhs: rhs)
    }
}
