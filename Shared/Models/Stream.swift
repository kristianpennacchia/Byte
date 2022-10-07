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

    @discardableResult
    func game(api: TwitchAPI, completion: @escaping (Result<Game, Error>) -> Void) -> URLSessionTask? {
        api.execute(endpoint: "games", query: ["id": gameId], decoding: [Game].self) { result in
            switch result {
            case .success(let data):
                if let game = data.data.first {
                    completion(.success(game))
                } else {
                    completion(.failure(APIError.invalidData(Game.self)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
