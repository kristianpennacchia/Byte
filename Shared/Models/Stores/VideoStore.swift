//
//  VideoStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/8/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI
import OSLog

final class VideoStore: FetchingObject {
    enum Fetch: FetchingKey {
        case user(userID: String)
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

    private(set) var originalItems = [any Videoable]() {
        didSet {
            applyFilter()
        }
    }

    @Published private(set) var items = [any Videoable]()

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
        var videos = [any Videoable]()

        switch fetchType {
        case .user(let userID):
            let query: [String: Any] = [
                "first": 25,
                "user_id": userID,
            ]

            do {
                let twitchVideos = try await twitchAPI?.execute(
                    method: .get,
                    endpoint: "videos",
                    query: query,
                    decoding: [Video].self
                ).data ?? []
                videos.append(contentsOf: twitchVideos)
            } catch {
				Logger.twitch.error("Failed getting Twitch videos. \(error.localizedDescription)")
            }

            do {
                // https://developers.google.com/youtube/v3/docs/playlistItems/list
                let uploadPlaylistID = "UU" + userID.dropFirst(2)

                // Only get the latest 50, otherwise we could be downloading thousands of videos.
                var youtubeVideos = try await youtubeAPI?.execute(
                    method: .get,
                    base: .youtube,
                    endpoint: "playlistItems",
                    query: [
                        "part": YoutubePlaylistItem.part,
                        "maxResults": 50,
                        "playlistId": uploadPlaylistID,
                    ],
                    decoding: YoutubeDataItem<YoutubePlaylistItem>.self
                ).items ?? []

                let youtubeVideoDetails = try await youtubeAPI?.execute(
                    method: .get,
                    base: .youtube,
                    endpoint: "videos",
                    query: [
                        "part": YoutubeVideo.part,
                        "maxResults": 50,
                        "id": youtubeVideos.map(\.videoId),
                    ],
                    decoding: YoutubeDataItem<YoutubeVideo>.self
                ).items ?? []

                youtubeVideos = youtubeVideos.map { video in
                    if let matchingDetails = youtubeVideoDetails.first(where: { $0.id == video.videoId }) {
                        var video = video
                        video.adhocDuration = matchingDetails.contentDetails.duration
                        return video
                    } else {
                        return video
                    }
                }

                videos.append(contentsOf: youtubeVideos)
            } catch {
				Logger.youtube.error("Failed getting Youtube videos. \(error.localizedDescription)")
            }
        }

        lastFetched = Date()
        originalItems = videos.sorted(by: compareVideoable)
    }
}

private extension VideoStore {
    func applyFilter() {
        if filter.isEmpty {
            items = originalItems
        } else {
            items = originalItems.filter { $0.title.contains(filter) }
        }
    }
}
