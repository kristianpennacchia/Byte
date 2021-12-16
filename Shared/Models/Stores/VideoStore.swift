//
//  VideoStore.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/8/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import Foundation
import SwiftUI

final class VideoStore: FetchingObject {
    enum Fetch: FetchingKey {
        case user(userID: String)
    }

    private(set) var lastFetched: Date?

    let api: API
    let fetchType: Fetch
    var filter = "" {
        didSet {
            applyFilter()
        }
    }

    @Published private(set) var originalItems = [Video]() {
        didSet {
            applyFilter()
        }
    }
    @Published private(set) var items = [Video]()

    init(api: API, fetch: Fetch) {
        self.api = api
        self.fetchType = fetch
    }

    func fetch(completion: @escaping () -> Void) {
        let continueFetch = { [weak self] (result: Result<DataItem<[Video]>, Error>) in
            guard let self = self else { return }

            self.lastFetched = Date()

            switch result {
            case .success(let data):
                self.originalItems = Set(data.data).sorted(by: >)
            case .failure(let error):
                print("Fetching '\(self.fetchType)' videos failed. \(error.localizedDescription)")
            }

            completion()
        }

        switch fetchType {
        case .user(let userID):
            let query: [String: Any] = [
                "first": 25,
                "user_id": userID,
            ]

            api.execute(endpoint: "videos", query: query, decoding: [Video].self, completion: continueFetch)
        }
    }
}

private extension VideoStore {
    func applyFilter() {
        if filter.isEmpty {
            items = originalItems
        } else {
            items = originalItems.filter { $0.title.contains(filter) }
        }
    }
}
