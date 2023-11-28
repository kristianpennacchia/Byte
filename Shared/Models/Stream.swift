//
//  Stream.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

/// https://dev.twitch.tv/docs/api/reference/#get-streams
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
	let userLogin: String
    let userName: String
	var displayName: String {
		if language == "en" || userLogin.isEmpty || userLogin.compare(userName, options: .caseInsensitive) == .orderedSame {
			return userName
		} else {
			return "\(userName) (\(userLogin))"
		}
	}
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
	let language: String
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
