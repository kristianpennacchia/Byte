//
//  YoutubeSearchResult.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeSearchResult: Decodable {
    struct ID: Decodable {
        let kind: String
        let videoId: String
        let channelId: String
        let playlistId: String
    }

    struct Snippet: Decodable {
        struct Thumbnail: Decodable {
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
        let thumbnails: [Thumbnail]
        let channelTitle: String
        let liveBroadcastContent: String
    }

    let kind: String
    let etag: String
    let id: ID
    let snippet: Snippet
}
