//
//  YoutubeSubscription.swift
//  Byte
//
//  Created by Kristian Pennacchia on 1/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

// https://developers.google.com/youtube/v3/docs/subscriptions#resource-representation
struct YoutubeSubscription: Decodable {
    struct Snippet: Hashable, Decodable {
        struct ResourceID: Hashable, Decodable {
            let kind: String
            let channelId: String
        }

        struct Thumbnails: Hashable, Decodable {
            struct URL: Hashable, Decodable {
                let url: String
            }

            let `default`: URL
            let medium: URL
            let high: URL
        }

        let publishedAt: Date
        let title: String
        let description: String
        let resourceId: ResourceID
        let channelId: String
        let thumbnails: Thumbnails
    }

    struct ContentDetail: Hashable, Decodable {
        let totalItemCount: Int
        let newItemCount: Int
        let activityType: String
    }

    static let platform = StreamablePlatform.youtube
    static let part = "snippet,contentDetails"

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetail

    @CodableIgnored var live: YoutubeAPI.LiveResult?
}

extension YoutubeSubscription: Streamable {
    var userId: String { snippet.resourceId.channelId }
    var userName: String { snippet.title }
    var title: String { "" }
    var viewerCount: Int? { nil }
    var startedAt: Date? { nil }
    var duration: String? { nil }

    func thumbnail(width: Int, height: Int) -> String {
        if let live {
            return "https://i1.ytimg.com/vi/\(live.videoID)/mqdefault.jpg"
        }
        return snippet.thumbnails.high.url
    }
}
