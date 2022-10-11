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

        var isRefreshing = false
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var youtubeAPI: YoutubeAPI

    @StateObject private var channelViewModel = ChannelViewModel()

    @State private var items = [any Channelable]()

    @StateObject var store: ChannelStore
    @State private var showChannel = false
    @Binding var shouldRefresh: Bool

    var body: some View {
        ZStack {
            Color.brand.brandDarkDark.ignoresSafeArea()
            if items.isEmpty {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible()), count: 5)
                    LazyVGrid(columns: columns) {
                        ForEach(items, id: \.channelId) { channel in
                            ChannelView(channel: channel)
                                .buttonWrap {
                                    channelViewModel.channel = channel
                                    showChannel = true
                                }
                        }
                        .padding([.leading, .trailing], 14)
                    }
                }
            }
        }
        .onReceive(sessionStore) { _ in
            refresh()
        }
        .onReceive(store.$items) { items in
            self.items = items
        }
        .onReceive(AppState()) { state in
            if store.isStale, state == .willEnterForeground {
                refresh()
            }
        }
        .onChange(of: shouldRefresh) { newValue in
            if newValue {
                shouldRefresh = false
                refresh()
            }
        }
        .onAppear {
            if self.store.isStale {
                self.refresh()
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
        guard channelViewModel.isRefreshing == false else { return }

        channelViewModel.isRefreshing = true

        store.fetch {
            channelViewModel.isRefreshing = false
        }
    }
}

struct ChannelList_Previews: PreviewProvider {
    static var previews: some View {
        ChannelList(store: ChannelStore(twitchAPI: .shared, fetch: .followed(twitchUserID: "1")), shouldRefresh: .constant(false))
    }
}
