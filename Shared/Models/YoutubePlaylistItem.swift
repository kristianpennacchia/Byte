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
            let maxres: URL?
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
        $0.allowedUnits = [.day, .hour, .minute]
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

    var adhocDuration: String?
}

extension YoutubePlaylistItem: Videoable {
    var videoId: String { contentDetails.videoId }
    var title: String { snippet.title }
    var createdAt: Date { contentDetails.videoPublishedAt }
    var duration: String? {
        if let adhocDuration {
            return parse(iso8601Duration: adhocDuration)
        } else {
            return nil
        }
    }

    func thumbnail(size: Int) -> String {
        // Fallback to medium as it has a better fitting aspect ratio.
        snippet.thumbnails.maxres?.url ?? snippet.thumbnails.medium.url
    }
}

private extension YoutubePlaylistItem {
    func parse(iso8601Duration: String) -> String? {
        var duration = iso8601Duration
        if duration.hasPrefix("PT") { duration.removeFirst(2) }

        let hour, minute, second: Double

        if let index = duration.firstIndex(of: "H") {
            hour = Double(duration[..<index]) ?? 0
            duration.removeSubrange(...index)
        } else {
            hour = 0
        }

        if let index = duration.firstIndex(of: "M") {
            minute = Double(duration[..<index]) ?? 0
            duration.removeSubrange(...index)
        } else {
            minute = 0
        }

        if let index = duration.firstIndex(of: "S") {
            second = Double(duration[..<index]) ?? 0
        } else {
            second = 0
        }

        return Self.formatter
            .string(from: hour * 3600 + minute * 60 + second)?
            .replacingOccurrences(of: "min.", with: "m")
    }
}
