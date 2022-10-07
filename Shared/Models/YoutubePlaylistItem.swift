//
//  YoutubePlaylistItem.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

/// https://developers.google.com/youtube/v3/docs/playlistItems#resource
struct YoutubePlaylistItem: Decodable {
    struct Snippet: Hashable, Decodable {
        struct ResourceID: Hashable, Decodable {
            let kind: String
            let videoId: String
        }

        struct Thumbnails: Hashable, Decodable {
            struct URL: Hashable, Decodable {
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

    struct ContentDetails: Hashable, Decodable {
        let videoId: String
        let videoPublishedAt: Date
    }

    private static let formatter: DateComponentsFormatter = {
        $0.allowedUnits = [.hour, .minute]
        $0.unitsStyle = .abbreviated
        $0.zeroFormattingBehavior = .dropLeading
        return $0
    }(DateComponentsFormatter())

    static var platform = VideoPlatform.youtube
    static let part = "snippet,id,contentDetails,status"

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
}

extension YoutubePlaylistItem: Videoable {
    var videoId: String { contentDetails.videoId }
    var title: String { snippet.title }
    var createdAt: Date { contentDetails.videoPublishedAt }
    var duration: String? { nil }

    func thumbnail(size: Int) -> String {
        snippet.thumbnails.high.url
    }
}
