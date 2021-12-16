//
//  ChannelList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ChannelList: View {
    @EnvironmentObject private var api: API

    @ObservedObject var store: ChannelStore

    @State private var isRefreshing = false

    var body: some View {
        VStack {
            ScrollView {
                if store.items.isEmpty == false {
                    Refresh(isAnimating: $isRefreshing, action: refresh)
                }

                let columns = Array(repeating: GridItem(.flexible()), count: 6)
                LazyVGrid(columns: columns) {
                    ForEach(store.items) { channel in
                        ChannelView(channel: channel)
                            .push {
                                VideoList(store: VideoStore(api: self.api, fetch: .user(userID: channel.id)))
                                    .environmentObject(self.api)
                            }
                    }
                }
            }
            .onAppear {
                if self.store.isStale {
                    self.refresh()
                }
            }
            .onReceive(AppState()) { state in
                if self.store.isStale, state == .willEnterForeground {
                    self.refresh()
                }
            }
        }
    }
}

private extension ChannelList {
    func refresh() {
        isRefreshing = true
        store.fetch {
            self.isRefreshing = false
        }
    }
}

struct ChannelList_Previews: PreviewProvider {
    static var previews: some View {
        ChannelList(store: ChannelStore(api: .shared, fetch: .followed(userID: "1")))
    }
}
