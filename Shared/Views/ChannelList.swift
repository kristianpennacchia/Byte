//
//  ChannelList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ChannelList: View {
    private class ChannelViewModel: ObservableObject {
        @Published var channel: Channel?
    }

    @EnvironmentObject private var api: TwitchAPI

    @ObservedObject var store: ChannelStore

    @StateObject private var channelViewModel = ChannelViewModel()

    @State private var isRefreshing = false
    @State private var showChannel = false

    var body: some View {
        ZStack {
            Color.brand.purpleDarkDark.ignoresSafeArea()
            if isRefreshing, store.items.isEmpty {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                    if store.items.isEmpty == false {
                        Refresh(isAnimating: $isRefreshing, action: refresh)
                    }
                    
                    let columns = Array(repeating: GridItem(.flexible()), count: 5)
                    LazyVGrid(columns: columns) {
                        ForEach(store.items) { channel in
                            ChannelView(channel: channel, hasFocusEffect: false)
                                .buttonWrap {
                                    channelViewModel.channel = channel
                                    showChannel = true
                                }
                        }
                        .padding([.leading, .trailing], 14)
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
        .fullScreenCover(
            isPresented: $showChannel,
            onDismiss: {
                channelViewModel.channel = nil

                if store.isStale {
                    refresh()
                }
            },
            content: {
                VideoList(store: VideoStore(twitchAPI: self.api, fetch: .user(userID: channelViewModel.channel!.id)))
                    .environmentObject(self.api)
            }
        )
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
        ChannelList(store: ChannelStore(twitchAPI: .shared, fetch: .followed(userID: "1")))
    }
}
