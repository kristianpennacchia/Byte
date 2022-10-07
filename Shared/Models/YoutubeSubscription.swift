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

extension YoutubeSubscription: Channelable {
    var displayName: String { snippet.title }
    var profileImageUrl: String { snippet.thumbnails.default.url }
}
