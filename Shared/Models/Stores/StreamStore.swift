//
//  StreamStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI
import OSLog

final class StreamStore: FetchingObject {
    enum Fetch: FetchingKey {
        case top, followed(twitchUserID: String?), game(Game)
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

    let twitchAPI: TwitchAPI?
    let youtubeAPI: YoutubeAPI?
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }

    private(set) var originalItems = [any Streamable]() {
        didSet {
            applyFilter()
        }
    }
    private(set) var items = [any Streamable]()

    @Published private(set) var uniquedItems = [UniqueStream]()

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

    func fetch() async throws {
        var streams = [any Streamable]()

        switch fetchType {
        case .followed(let twitchUserID):
            do {
                let twitchFollowedChannelStubs = try await twitchAPI?.executeFetchAll(
                    method: .get,
                    endpoint: "users/follows",
                    query: [
                        "first": 100,
                        "from_id": twitchUserID ?? "",
                    ],
                    decoding: [Channel.Stub].self
                ).data ?? []

                // Now get the stream data for each followed channel.
                for stubs in twitchFollowedChannelStubs.chunked(into: 100) {
                    let twitchStreams = try await twitchAPI?.executeFetchAll(
                        method: .get,
                        endpoint: "streams",
                        query: [
                            "first": stubs.count,
                            "user_id": stubs.map { $0.toId },
                        ],
                        decoding: [Stream].self
                    ).data ?? []
                    streams += twitchStreams
                }
            } catch {
				Logger.twitch.error("Fetching all Twitch followed channels failed. \(error.localizedDescription)")
            }

            do {
                // https://developers.google.com/youtube/v3/docs/subscriptions/list
                let subscriptions = try await youtubeAPI?.executeFetchAll(
                    method: .get,
                    base: .youtube,
                    endpoint: "subscriptions",
                    query: [
                        "part": YoutubeSubscription.part,
                        "maxResults": 50,
                        "mine": true,
                    ],
                    decoding: YoutubeDataItem<YoutubeSubscription>.self
                ) ?? []

                var liveVideoIDs = [String]()

                do {
                    // Running in parallel, check which channels are live.
                    try await withThrowingTaskGroup(of: [String].self) { group in
                        for subscription in subscriptions {
                            group.addTask {
                                return try await self.youtubeAPI?.getLiveVideoIDs(channelID: subscription.snippet.resourceId.channelId) ?? []
                            }
                        }

                        for try await ids in group {
                            liveVideoIDs.append(contentsOf: ids)
                        }
                    }
                } catch {
					Logger.youtube.error("Failed to check if Youtube channels are live. \(error.localizedDescription)")
                }

                // https://developers.google.com/youtube/v3/docs/videos/list
                let liveYoutubeChannels = try await youtubeAPI?.executeFetchAll(
                    method: .get,
                    base: .youtube,
                    endpoint: "videos",
                    query: [
                        "part": YoutubeVideo.part,
                        "maxResults": 50,
                        "id": liveVideoIDs.joined(separator: ","),
                    ],
                    decoding: YoutubeDataItem<YoutubeVideo>.self
                ).filter(\.isCurrentlyLive) ?? []
                streams += liveYoutubeChannels
            } catch {
				Logger.youtube.error("Fetching all Youtube followed channels failed. \(error.localizedDescription)")
            }
        case .top:
            let query: [String: Any] = [
                "first": 100,
            ]

            let twitchStreams = try await twitchAPI?.execute(method: .get, endpoint: "streams", query: query, decoding: [Stream].self).data ?? []
            streams += twitchStreams
        case .game(let game):
            let query: [String: Any] = [
                "first": 100,
                "game_id": game.id,
            ]

            let twitchStreams = try await twitchAPI?.execute(method: .get, endpoint: "streams", query: query, decoding: [Stream].self).data ?? []
            streams += twitchStreams
        }

        lastFetched = Date()
        originalItems = streams.sorted(by: compareStreamable)
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
