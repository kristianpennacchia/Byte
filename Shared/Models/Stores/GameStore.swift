//
//  GameStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

final class GameStore: FetchingObject {
    enum Fetch: FetchingKey {
        case top, followed
    }

    private(set) var lastFetched: Date?

    let twitchAPI: TwitchAPI
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

    func fetch(completion: @escaping () -> Void) {
        let query: [String: Any] = [
            "first": 100,
        ]

        switch fetchType {
        case .top:
            twitchAPI.execute(endpoint: "games/top", query: query, decoding: [Game].self) { [weak self] result in
                guard let self = self else { return }

                self.lastFetched = Date()

                switch result {
                case .success(let data):
                    self.originalItems = data.data
                case .failure(let error):
                    print("Fetching '\(self.fetchType)' games failed. \(error.localizedDescription)")
                }

                completion()
            }
        case .followed:
            break
        }
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
