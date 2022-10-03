//
//  Streamable.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

enum StreamablePlatform {
    case twitch, youtube

    var displayPriority: Int {
        switch self {
        case .twitch:
            return 1
        case .youtube:
            return 0
        }
    }
}

protocol Streamable: Comparable {
    static var platform: StreamablePlatform { get }

    var id: String { get }
    var userId: String { get }
    var userName: String { get }
    var title: String { get }
    var viewerCount: Int? { get }
    var startedAt: Date? { get }
    var duration: String? { get }
}

extension Streamable where Self: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        if type(of: lhs).platform == type(of: rhs).platform {
            return (lhs.viewerCount ?? 0) == (rhs.viewerCount ?? 0) ? lhs.userName < rhs.userName : (lhs.viewerCount ?? 0) < (rhs.viewerCount ?? 0)
        } else {
            return type(of: lhs).platform.displayPriority < type(of: rhs).platform.displayPriority
        }
    }
}
