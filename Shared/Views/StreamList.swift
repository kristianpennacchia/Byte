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

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var streams = [StreamStore.UniqueStream]()
    @State private var selectedStreams = [any Streamable]()
    @State private var showSpoilerMenu = false
    @State private var showVideoPlayer = false
    @State private var isRefreshing = false

    @StateObject var store: StreamStore
    @Binding var shouldRefresh: Bool

    var body: some View {
        ZStack {
            Color.brand.brandDarkDark.ignoresSafeArea()
            if streams.isEmpty || isRefreshing {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible()), count: 3)
                    LazyVGrid(columns: columns) {
                        ForEach(streams) { uniqueItem in
                            let stream = uniqueItem.stream
                            StreamView(stream: stream, isSelected: selectedStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) }))
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
                .padding([.leading, .trailing], 14)
                .edgesIgnoringSafeArea([.leading, .trailing])
            }
        }
        .onReceive(sessionStore) { _ in
            refresh()
        }
        .onReceive(store.$uniquedItems) { items in
            streams = items
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
            if store.isStale {
                refresh()
            }
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
    }
}

private extension StreamList {
    func refresh() {
        guard isRefreshing == false else { return }

        Task {
            isRefreshing = true
            try? await store.fetch()
            isRefreshing = false
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
        StreamList(store: StreamStore(twitchAPI: .shared, fetch: .followed(twitchUserID: App.previewUsername)), shouldRefresh: .constant(false))
    }
}
