//
//  StreamStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI

final class StreamStore: FetchingObject {
    enum Fetch: FetchingKey {
        case top, followed(userID: String), game(Game)
    }

    private(set) var lastFetched: Date?

    let api: API
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }

    @Published private(set) var originalItems = [Stream]() {
        didSet {
            applyFilter()
        }
    }
    @Published private(set) var items = [Stream]()

    init(api: API, fetch: Fetch) {
        self.api = api
        self.fetchType = fetch
    }

    func fetch(completion: @escaping () -> Void) {
        let continueFetch = { [weak self] (result: Result<DataItem<[Stream]>, Error>) in
            guard let self = self else { return }

            self.lastFetched = Date()

            switch result {
            case .success(let data):
                self.originalItems = Set(data.data).sorted(by: >)
            case .failure(let error):
                print("Fetching '\(self.fetchType)' streams failed. \(error.localizedDescription)")
            }

            completion()
        }

        switch fetchType {
        case .followed(let userID):
            let query: [String: Any] = [
                "first": 100,
                "from_id": userID,
            ]

            api.executeFetchAll(endpoint: "users/follows", query: query, decoding: [Channel.Stub].self) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let followedUserData):
                    // Now get the stream data for each followed channel
                    let group = DispatchGroup()
                    var liveStreams = [Stream]()
                    followedUserData.data
                        .chunked(into: 100)
                        .forEach { stubs in
                            group.enter()

                            let query: [String: Any] = [
                                "first": stubs.count,
                                "user_id": stubs.map { $0.toId },
                            ]

                            self.api.executeFetchAll(endpoint: "streams", query: query, decoding: [Stream].self) { result in
                                switch result {
                                case .success(let data):
                                    liveStreams += data.data
                                case .failure(let error):
                                    print("Fetching stream data for all followed users failed. \(error.localizedDescription)")
                                }

                                group.leave()
                            }
                    }
                    group.notify(queue: .main) {
                        continueFetch(.success(DataItem<[Stream]>(data: liveStreams, pagination: nil)))
                    }
                case .failure(let error):
                    print("Fetching all user follows failed. \(error.localizedDescription)")
                }
            }
        case .top:
            let query: [String: Any] = [
                "first": 100,
            ]

            api.execute(endpoint: "streams", query: query, decoding: [Stream].self, completion: continueFetch)
        case .game(let game):
            let query: [String: Any] = [
                "first": 100,
                "game_id": game.id,
            ]

            api.execute(endpoint: "streams", query: query, decoding: [Stream].self, completion: continueFetch)
        }
    }
}

private extension StreamStore {
    func applyFilter() {
        if filter.isEmpty {
            items = originalItems
        } else {
            items = originalItems.filter { $0.title.contains(filter) }
        }
    }
}
