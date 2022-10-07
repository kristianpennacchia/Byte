//
//  VideoStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/8/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI

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

    @Published private(set) var originalItems = [any Videoable]() {
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

    func fetch(completion: @escaping () -> Void) {
        let continueFetch = { [weak self] (result: Result<(twitch: TwitchDataItem<[Video]>?, youtube: [YoutubePlaylistItem]?), Error>) in
            guard let self = self else { return }

            self.lastFetched = Date()

            switch result {
            case .success(let data):
                var videos = [any Videoable]()
                videos.append(contentsOf: data.twitch?.data ?? [])
                videos.append(contentsOf: data.youtube ?? [])
                self.originalItems = videos.sorted(by: compareVideoable)
            case .failure(let error):
                print("Fetching '\(self.fetchType)' videos failed. \(error.localizedDescription)")
            }

            completion()
        }

        switch fetchType {
        case .user(let userID):
            let query: [String: Any] = [
                "first": 25,
                "user_id": userID,
            ]

            @Sendable
            func getYoutubeVideos(userID: String) async throws -> [YoutubePlaylistItem] {
                // https://developers.google.com/youtube/v3/docs/playlistItems/list
                let uploadPlaylistID = "UU" + userID.dropFirst(2)
                return try await youtubeAPI?.executeFetchAll(
                    method: .get,
                    base: .youtube,
                    endpoint: "playlistItems",
                    query: [
                        "part": YoutubePlaylistItem.part,
                        "maxResults": 50,
                        "playlistId": uploadPlaylistID,
                    ],
                    decoding: YoutubeDataItem<YoutubePlaylistItem>.self
                ) ?? []
            }

            if let twitchAPI = twitchAPI {
                twitchAPI.execute(endpoint: "videos", query: query, decoding: [Video].self) { result in
                    switch result {
                    case .success(let twitchData):
                        Task {
                            do {
                                let videos = try await getYoutubeVideos(userID: userID)
                                continueFetch(.success((twitchData, videos)))
                            } catch {
                                continueFetch(.failure(error))
                            }
                        }
                    case .failure(let error):
                        continueFetch(.failure(error))
                    }
                }
            } else {
                Task {
                    do {
                        let videos = try await getYoutubeVideos(userID: userID)
                        continueFetch(.success((nil, videos)))
                    } catch {
                        continueFetch(.failure(error))
                    }
                }
            }
        }
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
