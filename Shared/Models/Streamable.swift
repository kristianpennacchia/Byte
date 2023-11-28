//
//  Streamable.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

func equalsStreamable(lhs: any Streamable, rhs: any Streamable) -> Bool {
    return lhs.id == rhs.id
}

func compareStreamable(lhs: any Streamable, rhs: any Streamable) -> Bool {
    return (lhs.viewerCount ?? 0) == (rhs.viewerCount ?? 0) ? lhs.userName < rhs.userName : (lhs.viewerCount ?? 0) > (rhs.viewerCount ?? 0)
}

let streamablePreview = Stream(
    id: App.previewUsername,
    userId: App.previewUsername,
	userLogin: "",
    userName: App.previewUsername,
    gameId: "23124",
    type: .live,
    title: "Some stream",
    viewerCount: .random(in: .min ... .max),
    startedAt: Date(),
    thumbnailUrl: "",
	language: "en"
)

protocol Streamable: Identifiable, Equatable, Hashable, Comparable {
    static var platform: VideoPlatform { get }

    var id: String { get }
    var userId: String { get }
    var userName: String { get }
	var displayName: String { get }
    var title: String { get }
    var viewerCount: Int? { get }
    var startedAt: Date { get }
    var duration: String { get }
	var language: String { get }

    func thumbnail(width: Int, height: Int) -> String
}

extension Streamable where Self: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        equalsStreamable(lhs: lhs, rhs: rhs)
    }
}

extension Streamable where Self: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        compareStreamable(lhs: lhs, rhs: rhs)
    }
}
