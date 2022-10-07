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
        @Published var channel: (any Channelable)?
    }

    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var youtubeAPI: YoutubeAPI

    @ObservedObject var store: ChannelStore

    @StateObject private var channelViewModel = ChannelViewModel()

    @State private var isRefreshing = false
    @State private var showChannel = false

    var body: some View {
        ZStack {
            Color.brand.brandDarkDark.ignoresSafeArea()
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
                        ForEach(store.items, id: \.channelId) { channel in
                            ChannelView(channel: channel)
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
                switch type(of: channelViewModel.channel!).platform {
                case .twitch:
                    VideoList(store: VideoStore(twitchAPI: twitchAPI, fetch: .user(userID: channelViewModel.channel!.channelId)))
                        .environmentObject(twitchAPI)
                case .youtube:
                    VideoList(store: VideoStore(youtubeAPI: youtubeAPI, fetch: .user(userID: channelViewModel.channel!.channelId)))
                        .environmentObject(youtubeAPI)
                }
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
        ChannelList(store: ChannelStore(twitchAPI: .shared, fetch: .followed(twitchUserID: "1")))
    }
}
