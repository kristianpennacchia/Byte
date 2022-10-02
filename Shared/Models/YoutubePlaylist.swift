//
//  YoutubePlaylist.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

/// https://developers.google.com/youtube/v3/docs/playlistItems#resource
struct YoutubePlaylist: Decodable {
    struct Snippet: Decodable {
        struct ResourceID: Decodable {
            let kind: String
            let videoId: String
        }

        struct Thumbnails: Decodable {
            struct URL: Decodable {
                let url: String
            }

            let `default`: URL
            let medium: URL
            let high: URL
        }

        let publishedAt: String
        let channelId: String
        let title: String
        let description: String
        let thumbnails: Thumbnails
        let channelTitle: String
        let videoOwnerChannelTitle: String
        let videoOwnerChannelId: String
        let playlistId: String
        let position: UInt
        let resourceId: ResourceID
    }

    struct ContentDetails: Decodable {
        let videoId: String
        let videoPublishedAt: String
    }

    static let part = "snippet,id,contentDetails,status"

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
}
