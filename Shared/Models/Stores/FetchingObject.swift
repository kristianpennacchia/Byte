//
//  FetchingObject.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

protocol FetchingKey {}

protocol FetchingObject: ObservableObject {
    associatedtype Item
    associatedtype Key: FetchingKey

    var api: API { get }
    var originalItems: [Item] { get }
    var items: [Item] { get }
    var fetchType: Key { get }
    var filter: String { get set }
    var lastFetched: Date? { get }
    var isStale: Bool { get }
    var staleTimeoutMinutes: Int { get }

    init(api: API, fetch: Key)

    func fetch(completion: @escaping () -> Void)
}

extension FetchingObject {
    var isStale: Bool {
        let timeout = Calendar.current.date(byAdding: .minute, value: -staleTimeoutMinutes, to: Date())!
        return lastFetched == nil || lastFetched! < timeout
    }
    var staleTimeoutMinutes: Int { 5 }

    func fetch() {
        fetch {}
    }
}
