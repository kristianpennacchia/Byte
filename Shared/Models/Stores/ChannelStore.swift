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
        case top, followed(twitchUserID: String?)
    }

    private(set) var lastFetched: Date?

    let twitchAPI: TwitchAPI?
    let youtubeAPI: YoutubeAPI?
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }
    var staleTimeoutMinutes: Int { 15 }

    private(set) var originalItems = [any Channelable]() {
        didSet {
            applyFilter()
        }
    }

    @Published private(set) var items = [any Channelable]()

    init(twitchAPI: TwitchAPI, fetch: Fetch) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = nil
        self.fetchType = fetch
    }

    init(youtubeAPI: YoutubeAPI, fetch: Fetch) {
        self.twitchAPI = nil
        self.youtubeAPI = youtubeAPI
        self.fetchType = fetch
    }

    init(twitchAPI: TwitchAPI, youtubeAPI: YoutubeAPI, fetch: Fetch) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = youtubeAPI
        self.fetchType = fetch
    }

    func fetch(completion: @escaping () -> Void) {
        let continueFetch = { [weak self] (result: Result<TwitchDataItem<[Channel]>, Error>) in
            guard let self = self else { return }

            Task {
                // We got all the Twitch results, now get the Youtube results (if applicable for the fetch type).
                var youtubeChannels = [YoutubeSubscription]()

                if let youtubeAPI = self.youtubeAPI, case .followed(twitchUserID: _) = self.fetchType {
                    print("Getting subscribed Youtube channels...")

                    do {
                        // https://developers.google.com/youtube/v3/docs/subscriptions/list
                        youtubeChannels = try await youtubeAPI.executeFetchAll(
                            method: .get,
                            base: .youtube,
                            endpoint: "subscriptions",
                            query: [
                                "part": YoutubeSubscription.part,
                                "maxResults": 50,
                                "mine": true,
                            ],
                            decoding: YoutubeDataItem<YoutubeSubscription>.self
                        )
                    } catch {
                        print("Failed to fetch subscribed Youtube channels. \(error.localizedDescription)")
                    }
                }

                self.lastFetched = Date()

                let stableYoutubeChannels = youtubeChannels

                await MainActor.run {
                    switch result {
                    case .success(let data):
                        var channels = [any Channelable]()
                        channels.append(contentsOf: data.data)
                        channels.append(contentsOf: stableYoutubeChannels)
                        self.originalItems = channels.sorted(by: compareChannelable)
                    case .failure(let error):
                        print("Fetching '\(self.fetchType)' channels failed. \(error.localizedDescription)")
                    }

                    completion()
                }
            }
        }

        guard let twitchAPI else {
            continueFetch(.success(TwitchDataItem<[Channel]>(data: [], pagination: nil)))
            return
        }

        switch fetchType {
        case .followed(let twitchUserID):
            let query: [String: Any] = [
                "first": 100,
                "from_id": twitchUserID!,
            ]

            twitchAPI.executeFetchAll(endpoint: "users/follows", query: query, decoding: [Channel.Stub].self) { [weak self] result in
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

                            twitchAPI.executeFetchAll(endpoint: "users", query: query, decoding: [Channel].self) { result in
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
