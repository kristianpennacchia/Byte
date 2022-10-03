//
//  ChannelList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct StreamList: View {
    private class StreamViewModel: ObservableObject {
        @Published var streams = [any Streamable]()
        @Published var stream: (any Streamable)?
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @ObservedObject var store: StreamStore

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var isRefreshing = false
    @State private var selectedStreams = [any Streamable]()
    @State private var showYoutubeAuthScreen = false
    @State private var showSpoilerMenu = false
    @State private var showVideoPlayer = false

    var body: some View {
        ZStack {
            Color.brand.purpleDarkDark.ignoresSafeArea()
            ScrollView {
                HStack(alignment: .center, spacing: 16) {
                    if sessionStore.youtubeAPI != nil, sessionStore.youtubeUser == nil {
                        Spacer()
                        Button("Youtube") {
                            showYoutubeAuthScreen = true
                        }
                        .foregroundColor(.white)
                        .tint(.red)
                        Spacer()
                        if store.uniquedItems.isEmpty == false {
                            Refresh(isAnimating: $isRefreshing, action: refresh)
                        }
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                    } else {
                        if store.uniquedItems.isEmpty == false {
                            Refresh(isAnimating: $isRefreshing, action: refresh)
                        }
                    }
                }
                .padding(.bottom, 8)

                let columns = Array(repeating: GridItem(.flexible()), count: 4)
                LazyVGrid(columns: columns) {
                    ForEach(store.uniquedItems) { uniqueItem in
                        let stream = uniqueItem.stream
                        StreamView(stream: stream, isSelected: selectedStreams.contains(where: { $0.id == stream.id }), hasFocusEffect: false)
                            .navigationBarTitle(store.fetchType.navBarTitle)
                            .buttonWrap {
                                if selectedStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) }) == false {
                                    selectedStreams.append(stream)
                                }

                                streamViewModel.streams = selectedStreams
                                streamViewModel.stream = stream
                                showVideoPlayer = true
                            } longPress: {
                                if stream is Stream {
                                    streamViewModel.stream = stream
                                    showSpoilerMenu = true
                                }
                            }
                            .onPlayPauseCommand {
                                // Multi-select streams.
                                if let index = selectedStreams.firstIndex(where: { equalsStreamable(lhs: $0, rhs: stream) }) {
                                    // Remove
                                    selectedStreams.remove(at: index)
                                } else {
                                    // Add
                                    selectedStreams.append(stream)
                                }
                            }
                    }
                    .padding([.leading, .trailing], 14)
                }
            }
            .onAppear {
                if store.isStale {
                    refresh()
                }
            }
            .onReceive(sessionStore) { store in
                refresh()
            }
            .onReceive(AppState()) { state in
                if store.isStale, state == .willEnterForeground {
                    refresh()
                }
            }
            .padding([.leading, .trailing], 14)
            .edgesIgnoringSafeArea([.leading, .trailing])
        }
        .actionSheet(isPresented: $showSpoilerMenu) {
            if let stream = streamViewModel.stream as? Stream {
                return ActionSheet(title: Text("Spoiler Filter"), message: nil, buttons: [
                    .default(Text(spoilerFilter.isSpoiler(gameID: stream.gameId) ? "Show Game Thumbnail" : "Hide Game Thumbnail")) {
                        spoilerFilter.toggle(gameID: stream.gameId)
                    },
                    .cancel()
                ])
            } else {
                return ActionSheet(title: Text("None"), message: nil, buttons: [.cancel()])
            }
        }
        .fullScreenCover(
            isPresented: $showVideoPlayer,
            onDismiss: {
                streamViewModel.streams = []
                selectedStreams = []

                if store.isStale {
                    refresh()
                }
            },
            content: {
                MultiStreamVideoPlayer(store: store, streams: streamViewModel.streams, isPresented: $showVideoPlayer)
            }
        )
        .fullScreenCover(
            isPresented: $showYoutubeAuthScreen,
            onDismiss: {},
            content: {
                OAuthView()
            }
        )
    }
}

private extension StreamList {
    func refresh() {
        isRefreshing = true
        store.fetch {
            self.isRefreshing = false
        }
    }
}

private extension StreamStore.Fetch {
    var navBarTitle: String {
        switch self {
        case .followed(_):
            return "Followed"
        case .game(let game):
            return game.name
        case .top:
            return "Top"
        }
    }
}

struct StreamList_Previews: PreviewProvider {
    static var previews: some View {
        StreamList(store: StreamStore(twitchAPI: .shared, fetch: .followed(userID: App.previewUsername)))
    }
}
