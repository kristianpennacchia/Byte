//
//  Stream.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Stream: Decodable, Streamable {
    enum Live: String, Decodable {
        case live
    }

    private static let formatter: DateComponentsFormatter = {
        $0.allowedUnits = [.hour, .minute]
        $0.unitsStyle = .abbreviated
        $0.zeroFormattingBehavior = .dropLeading
        return $0
    }(DateComponentsFormatter())

    static let platform = VideoPlatform.twitch

    let id: String
    let userId: String
    let userName: String
    let gameId: String
    let type: Live
    let title: String
    let viewerCount: Int?
    let startedAt: Date
    let thumbnailUrl: String
    var duration: String {
        Self.formatter
            .string(from: startedAt, to: Date())?
            .replacingOccurrences(of: "min.", with: "m")
            ?? ""
    }
}

extension Stream {
    func thumbnail(width: Int, height: Int) -> String {
        thumbnailUrl
            .replacingOccurrences(of: "{width}", with: "\(width)")
            .replacingOccurrences(of: "{height}", with: "\(height)")
    }

    func game(api: TwitchAPI) async throws -> Game {
        let data = try await api.execute(method: .get, endpoint: "games", query: ["id": gameId], decoding: [Game].self)
        if let game = data.data.first {
            return game
        } else {
            throw APIError.invalidData(Game.self)
        }
    }
}
