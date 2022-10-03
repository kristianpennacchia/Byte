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

    struct UniqueStream: Identifiable, Hashable {
        static func == (lhs: StreamStore.UniqueStream, rhs: StreamStore.UniqueStream) -> Bool {
            return lhs.id == rhs.id
        }

        let stream: any Streamable

        // Force this instance to never be the same, so that the stream view can be updated to show
        // changes in static data.
        // E.g. Duration is determined by the unchanging `startedAt` property.
        // E.g. Thumbnail URL never changes, but the image itself does.
        // Because of this, the views displaying the stream will be showing outdated data even if none
        // of the properties on the Stream model have changed.
        let id = UUID()

        func hash(into hasher: inout Hasher) {
            hasher.combine(stream)
            hasher.combine(id)
        }
    }

    private(set) var lastFetched: Date?

    let twitchAPI: TwitchAPI
    let youtubeAPI: YoutubeAPI?
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }

    @Published private(set) var originalItems = [any Streamable]() {
        didSet {
            applyFilter()
        }
    }
    @Published private(set) var items = [any Streamable]()
    @Published private(set) var uniquedItems = [UniqueStream]()

    init(twitchAPI: TwitchAPI, fetch: Fetch) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = nil
        self.fetchType = fetch
    }

    init(twitchAPI: TwitchAPI, youtubeAPI: YoutubeAPI, fetch: Fetch) {
        self.twitchAPI = twitchAPI
        self.youtubeAPI = youtubeAPI
        self.fetchType = fetch
    }

    func fetch(completion: @escaping () -> Void) {
        let continueFetch = { [weak self] (result: Result<TwitchDataItem<[Stream]>, Error>) in
            guard let self = self else { return }

            Task {
                // We got all the Twitch results, now get the Youtube results (if applicable for the fetch type).
                var liveYoutubeChannels = [YoutubeSubscription]()

                if let youtubeAPI = self.youtubeAPI, case .followed(userID: _) = self.fetchType {
                    print("Getting Youtube live streams...")

                    do {
                        // https://developers.google.com/youtube/v3/docs/subscriptions/list
                        let subscriptions = try await youtubeAPI.executeFetchAll(
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

                        do {
                            // Running in parallel, check which channels are live.
                            try await withThrowingTaskGroup(of: (subscription: YoutubeSubscription, isLive: Bool).self) { group in
                                for subscription in subscriptions {
                                    group.addTask {
                                        let isLive = try await youtubeAPI.getIsLive(channelID: subscription.snippet.resourceId.channelId)
                                        return (subscription, isLive)
                                    }
                                }

                                for try await result in group where result.isLive {
                                    liveYoutubeChannels.append(result.subscription)
                                }
                            }
                        } catch {
                            print("Failed to check if channels are live. \(error.localizedDescription)")
                        }
                    } catch {
                        print("Failed to fetch Youtube live streams. \(error.localizedDescription)")
                    }
                }

                self.lastFetched = Date()

                switch result {
                case .success(let data):
                    var streams = [any Streamable]()
                    streams.append(contentsOf: data.data)
                    streams.append(contentsOf: liveYoutubeChannels)
                    self.originalItems = streams.sorted(by: compareStreamable)
                case .failure(let error):
                    print("Fetching '\(self.fetchType)' streams failed. \(error.localizedDescription)")
                }

                completion()
            }
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

                            self.twitchAPI.executeFetchAll(endpoint: "streams", query: query, decoding: [Stream].self) { result in
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
                        continueFetch(.success(TwitchDataItem<[Stream]>(data: liveStreams, pagination: nil)))
                    }
                case .failure(let error):
                    print("Fetching all user follows failed. \(error.localizedDescription)")
                }
            }
        case .top:
            let query: [String: Any] = [
                "first": 100,
            ]

            twitchAPI.execute(endpoint: "streams", query: query, decoding: [Stream].self, completion: continueFetch)
        case .game(let game):
            let query: [String: Any] = [
                "first": 100,
                "game_id": game.id,
            ]

            twitchAPI.execute(endpoint: "streams", query: query, decoding: [Stream].self, completion: continueFetch)
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

        uniquedItems = items.map(UniqueStream.init)
    }
}
