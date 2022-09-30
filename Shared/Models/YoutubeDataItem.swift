//
//  YoutubeDataItem.swift
//  Byte
//
//  Created by Kristian Pennacchia on 1/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubeDataItem<T: Decodable>: Decodable {
    struct PageInfo: Decodable {
        let totalResults: Int
        let resultsPerPage: Int
    }

    let kind: String
    let etag: String
    let nextPageToken: String
    let prevPageToken: String?
    let pageInfo: PageInfo
    let items: [T]
}
