//
//  YoutubeBroadcast.swift
//  Byte
//
//  Created by Kristian Pennacchia on 1/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeBroadcast: Decodable {
    struct Snippet: Decodable {
        struct Thumbnail: Decodable {
            struct URL: Decodable {
                let url: String
                let width: Int
                let height: Int
            }

            let `default`: URL
            let medium: URL
            let high: URL
        }

        let publishedAt: String
        let title: String
        let description: String
        let channelId: String
        let thumbnails: [Thumbnail]
        let scheduledStartTime: String
        let scheduledEndTime: String
        let actualStartTime: String
        let actualEndTime: String
        let isDefaultBroadcast: Bool
        let liveChatId: String
    }

    struct Status: Decodable {
        let lifeCycleStatus: String
        let privacyStatus: String
        let recordingStatus: String
        let madeForKids: String
        let selfDeclaredMadeForKids: String
    }

    struct ContentDetail: Decodable {
        struct MonitorStream: Decodable {
            let enableMonitorStream: Bool
            let broadcastStreamDelayMs: Int
            let embedHtml: String
        }

        let boundStreamId: String
        let boundStreamLastUpdateTimeMs: String
        let monitorStream: MonitorStream
        let enableEmbed: Bool
        let enableDvr: Bool
        let recordFromStart: Bool
        let enableClosedCaptions: Bool
        let closedCaptionsType: String
        let projection: String
        let enableLowLatency: Bool
        let latencyPreference: Bool
        let enableAutoStart: Bool
        let enableAutoStop: Bool
    }

    struct Statistics: Decodable {
        let totalChatCount: UInt
    }

    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
    let status: Status
    let contentDetails: ContentDetail
    let statistics: Statistics
}
