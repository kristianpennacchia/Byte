//
//  ChannelStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

final class ChannelStore: FetchingObject {
    enum Fetch: FetchingKey {
        case top, followed(userID: String)
    }

    private(set) var lastFetched: Date?

    let twitchAPI: TwitchAPI
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }
    var staleTimeoutMinutes: Int { 15 }

    @Published private(set) var originalItems = [Channel]() {
        didSet {
            applyFilter()
        }
    }
    @Published private(set) var items = [Channel]()

    init(twitchAPI: TwitchAPI, fetch: Fetch) {
        self.twitchAPI = twitchAPI
        self.fetchType = fetch
    }

    func fetch(completion: @escaping () -> Void) {
        let continueFetch = { [weak self] (result: Result<TwitchDataItem<[Channel]>, Error>) in
            guard let self = self else { return }

            self.lastFetched = Date()

            switch result {
            case .success(let data):
                self.originalItems = data.data.sorted(by: <)
            case .failure(let error):
                print("Fetching '\(self.fetchType)' channels failed. \(error.localizedDescription)")
            }

            completion()
        }

        switch fetchType {
        case .followed(let userID):
            let query: [String: Any] = [
                "first": 100,
                "from_id": userID,
            ]

            twitchAPI.executeFetchAll(endpoint: "users/follows", query: query, decoding: [Channel.Stub].self) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let followedUserData):
                    // Now get the channel data for each followed user
                    let group = DispatchGroup()
                    var followedChannels = [Channel]()
                    followedUserData.data
                        .chunked(into: 100)
                        .forEach { stubs in
                            group.enter()

                            let query: [String: Any] = [
                                "first": stubs.count,
                                "id": stubs.map { $0.toId },
                            ]

                            self.twitchAPI.executeFetchAll(endpoint: "users", query: query, decoding: [Channel].self) { result in
                                switch result {
                                case .success(let data):
                                    followedChannels += data.data
                                case .failure(let error):
                                    print("Fetching stream data for all followed users failed. \(error.localizedDescription)")
                                }

                                group.leave()
                            }
                        }
                    group.notify(queue: .main) {
                        continueFetch(.success(TwitchDataItem<[Channel]>(data: followedChannels, pagination: nil)))
                    }
                case .failure(let error):
                    print("Fetching all user follows failed. \(error.localizedDescription)")
                }
            }
        case .top:
            /// - Todo: Fetch top channels
            break
        }
    }
}

private extension ChannelStore {
    func applyFilter() {
        if filter.isEmpty {
            items = originalItems
        } else {
            items = originalItems.filter { $0.displayName.contains(filter) }
        }
    }
}
