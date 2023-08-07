//
//  ChannelStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation
import OSLog

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

    func fetch() async throws {
        var channels = [any Channelable]()

        switch fetchType {
        case .followed(let twitchUserID):
            do {
                let query: [String: Any] = [
                    "first": 100,
                    "from_id": twitchUserID ?? "",
                ]

                let twitchFollowedChannelStubs = try await twitchAPI?.executeFetchAll(method: .get, endpoint: "users/follows", query: query, decoding: [Channel.Stub].self).data ?? []

                // Now get the channel data for each followed channel.
                for stubs in twitchFollowedChannelStubs.chunked(into: 100) {
                    let query: [String: Any] = [
                        "first": stubs.count,
                        "id": stubs.map { $0.toId },
                    ]

                    let twitchUsers = try await twitchAPI?.executeFetchAll(method: .get, endpoint: "users", query: query, decoding: [Channel].self).data ?? []
                    channels += twitchUsers
                }
            } catch {
				Logger.twitch.error("Fetching all Twitch followed channels failed. \(error.localizedDescription)")
            }

            do {
                // https://developers.google.com/youtube/v3/docs/subscriptions/list
                let youtubeChannels = try await youtubeAPI?.executeFetchAll(
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
                channels += youtubeChannels
            } catch {
				Logger.youtube.error("Fetching all Youtube subscribed channels failed. \(error.localizedDescription)")
            }
        case .top:
            /// - Todo: Fetch top channels
            break
        }

        lastFetched = Date()
        originalItems = channels.sorted(by: compareChannelable)
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
