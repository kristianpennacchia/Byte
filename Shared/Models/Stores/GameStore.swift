//
//  GameStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import OSLog

final class GameStore: FetchingObject {
    enum Fetch: FetchingKey {
        case top, followed
    }

    private(set) var lastFetched: Date?

    let twitchAPI: TwitchAPI?
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }

    @Published private(set) var originalItems = [Game]() {
        didSet {
            applyFilter()
        }
    }
    @Published private(set) var items = [Game]()

    init(twitchAPI: TwitchAPI, fetch: Fetch) {
        self.twitchAPI = twitchAPI
        self.fetchType = fetch
    }

    func fetch() async throws {
        var games = [Game]()

        let query: [String: Any] = [
            "first": 100,
        ]

        switch fetchType {
        case .top:
            do {
                let twitchGames = try await twitchAPI!.execute(method: .get, endpoint: "games/top", query: query, decoding: [Game].self).data
                games.append(contentsOf: twitchGames)
            } catch {
				Logger.twitch.error("Fetching '\(String(describing: self.fetchType))' games failed. \(error.localizedDescription)")
            }
        case .followed:
            break
        }

        lastFetched = Date()
        originalItems = games
    }
}

private extension GameStore {
    func applyFilter() {
        if filter.isEmpty {
            items = originalItems
        } else {
            items = originalItems.filter { $0.name.contains(filter) }
        }
    }
}
