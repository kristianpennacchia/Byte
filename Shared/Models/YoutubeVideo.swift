//
//  YoutubeVideo.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

/// https://developers.google.com/youtube/v3/docs/videos#resource-representation
struct YoutubeVideo: Decodable {
    struct Snippet: Decodable {
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
        let tags: [String]?
        let categoryId: String
        let liveBroadcastContent: String
    }

    struct ContentDetails: Decodable {
        let duration: String
        let dimension: String
        let definition: String
        let caption: String
        let licensedContent: Bool
        let projection: String
    }

    struct Statistics: Decodable {
        let viewCount: String
        let likeCount: String?
        let commentCount: String?
    }

    struct Player: Decodable {
        let embedHtml: String
        let embedHeight: UInt?
        let embedWidth: UInt?
    }

    struct LiveStreamingDetails: Decodable {
        let actualStartTime: String?
        let actualEndTime: String?
        let scheduledStartTime: String?
        let scheduledEndTime: String?
        let concurrentViewers: UInt?
        let activeLiveChatId: String?
    }

    static let part = "snippet,contentDetails,statistics,player,recordingDetails,liveStreamingDetails"

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    let statistics: Statistics
    let player: Player
    let liveStreamingDetails: LiveStreamingDetails?

    var isCurrentlyLive: Bool { liveStreamingDetails?.actualStartTime != nil && liveStreamingDetails?.actualEndTime == nil }
}
