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
    struct Snippet: Hashable, Decodable {
        struct Thumbnails: Hashable, Decodable {
            struct URL: Hashable, Decodable {
                let url: String
            }

            let `default`: URL
            let medium: URL
            let high: URL
            let maxres: URL?
        }

        let publishedAt: Date
        let channelId: String
        let title: String
        let description: String
        let thumbnails: Thumbnails
        let channelTitle: String
        let tags: [String]?
        let categoryId: String
        let defaultLanguage: String
        let liveBroadcastContent: String
    }

    struct ContentDetails: Hashable, Decodable {
        let duration: String
        let dimension: String
        let definition: String
        let caption: String
        let licensedContent: Bool
        let projection: String
    }

    struct Statistics: Hashable, Decodable {
        let viewCount: String
        let likeCount: String?
        let commentCount: String?
    }

    struct Player: Hashable, Decodable {
        let embedHtml: String
        let embedHeight: UInt?
        let embedWidth: UInt?
    }

    struct LiveStreamingDetails: Hashable, Decodable {
        let actualStartTime: Date?
        let actualEndTime: Date?
        let scheduledStartTime: Date?
        let scheduledEndTime: Date?
        let concurrentViewers: String?
        let activeLiveChatId: String?
    }

    private static let formatter: DateComponentsFormatter = {
        $0.allowedUnits = [.day, .hour, .minute]
        $0.unitsStyle = .abbreviated
        $0.zeroFormattingBehavior = .dropLeading
        return $0
    }(DateComponentsFormatter())

    static let part = "snippet,contentDetails,statistics,liveStreamingDetails"

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    let statistics: Statistics
    let liveStreamingDetails: LiveStreamingDetails?

    var isCurrentlyLive: Bool { liveStreamingDetails?.actualStartTime != nil && liveStreamingDetails?.actualEndTime == nil }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.snippet.publishedAt < rhs.snippet.publishedAt
    }
}

extension YoutubeVideo: Streamable {
    static let platform = VideoPlatform.youtube

    var userId: String { snippet.channelId }
    var userName: String { snippet.channelTitle }
	var displayName: String { userName }
    var title: String { snippet.title }
    var viewerCount: Int? {
        if let concurrentViewers = liveStreamingDetails?.concurrentViewers {
            return Int(concurrentViewers)
        } else {
            return nil
        }
    }
    var startedAt: Date { liveStreamingDetails?.actualStartTime ?? snippet.publishedAt }
    var duration: String {
        Self.formatter
            .string(from: startedAt, to: Date())?
            .replacingOccurrences(of: "min.", with: "m")
            ?? ""
    }
	var language: String { snippet.defaultLanguage }

    func thumbnail(width: Int, height: Int) -> String {
        // Fallback to medium as it has a better fitting aspect ratio.
        snippet.thumbnails.maxres?.url ?? snippet.thumbnails.medium.url
    }
}
