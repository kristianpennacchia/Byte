//
//  YoutubeSubscription.swift
//  Byte
//
//  Created by Kristian Pennacchia on 1/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeSubscription: Decodable {
    struct Snippet: Decodable {
        struct ResourceID: Decodable {
            let kind: String
            let channelId: String
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
        let title: String
        let description: String
        let resourceId: ResourceID
        let channelId: String
        let thumbnails: Thumbnails
    }

    struct ContentDetail: Decodable {
        let totalItemCount: Int
        let newItemCount: Int
        let activityType: String
    }

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetail
}
