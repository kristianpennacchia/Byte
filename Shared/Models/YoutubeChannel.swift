//
//  YoutubeChannel.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

/// https://developers.google.com/youtube/v3/docs/channels#resource
struct YoutubeChannel: Decodable {
    struct Snippet: Decodable {
        struct Thumbnails: Decodable {
            struct URL: Decodable {
                let url: String
            }

            let `default`: URL
            let medium: URL
            let high: URL
        }

        let title: String
        let description: String
        let customUrl: String?
        let publishedAt: Date
        let thumbnails: Thumbnails
    }

    struct ContentDetails: Decodable {
        struct RelatedPlaylists: Decodable {
            let likes: String
            let uploads: String
        }

        let relatedPlaylists: RelatedPlaylists
    }

    struct Statistics: Decodable {
        let viewCount: String
        let subscriberCount: String
        let hiddenSubscriberCount: Bool
        let videoCount: String
    }

    static let part = "snippet,contentDetails,statistics"

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    let statistics: Statistics
}
