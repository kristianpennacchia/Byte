//
//  YoutubePlayerResponse.swift
//  Byte
//
//  Created by Kristian Pennacchia on 4/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubePlayerResponse: Decodable {
    struct StreamingData: Decodable {
        struct Format: Decodable {
            let itag: Int
            let qualityLabel: String
            let url: String?
        }

        struct AdaptiveFormat: Decodable {
            let itag: Int
//            let mimeType: []
            let qualityLabel: String?
            let url: String?
        }

        let hlsManifestUrl: String?
        let formats: [Format]?
        let adaptiveFormats: [AdaptiveFormat]?
    }

    struct VideoDetails: Decodable {
        let videoId: String
        let author: String
        let title: String
        let isLive: Bool?
        let isLiveContent: Bool?
        let isLiveDvrEnabled: Bool?
        let isLowLatencyLiveStream: Bool?
        let isPrivate: Bool?
    }

    struct Microformat: Decodable {
        struct Renderer: Decodable {
            struct Thumbnails: Hashable, Decodable {
                struct URL: Hashable, Decodable {
                    let url: String
                    let width: Int
                    let height: Int
                }

                let thumbnails: [URL]
            }

            let thumbnail: Thumbnails
        }

        let playerMicroformatRenderer: Renderer?
        let microformatDataRenderer: Renderer?
    }

    let streamingData: StreamingData
    let videoDetails: VideoDetails
    let microformat: Microformat
}
