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
        @Published var streams = Set<Stream>()
    }

    @EnvironmentObject private var api: API
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @ObservedObject var store: StreamStore

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var isRefreshing = false
    @State private var selectedStreams = Set<Stream>()
    @State private var showVideoPlayer = false

    var body: some View {
        ZStack {
            Color.brand.purpleDarkDark.ignoresSafeArea()
            ScrollView {
                if store.uniquedItems.isEmpty == false {
                    Refresh(isAnimating: $isRefreshing, action: refresh)
                        .padding(.bottom, 8)
                }

                let columns = Array(repeating: GridItem(.flexible()), count: 4)
                LazyVGrid(columns: columns) {
                    ForEach(store.uniquedItems) { uniqueItem in
                        let stream = uniqueItem.stream
                        StreamView(stream: stream, isSelected: selectedStreams.contains(stream), hasFocusEffect: false)
                            .navigationBarTitle(self.store.fetchType.navBarTitle)
                            .buttonWrap {
                                if selectedStreams.contains(stream) == false {
                                    selectedStreams.insert(stream)
                                }

                                streamViewModel.streams = selectedStreams
                                showVideoPlayer = true
                            }
                            .onPlayPauseCommand {
                                // Multi-select streams.
                                if selectedStreams.contains(stream) {
                                    // Remove
                                    selectedStreams.remove(stream)
                                } else {
                                    // Add
                                    selectedStreams.insert(stream)
                                }
                            }
                            .contextMenu {
                                Button(spoilerFilter.isSpoiler(gameID: stream.gameId) ? "Remove Game From Spoiler Filter" : "Add Game To Spoiler Filter") {
                                    spoilerFilter.toggle(gameID: stream.gameId)
                                }
                                Button("Cancel") {}
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
            .onReceive(AppState()) { state in
                if store.isStale, state == .willEnterForeground {
                    refresh()
                }
            }
            .padding([.leading, .trailing], 14)
            .edgesIgnoringSafeArea([.leading, .trailing])
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
        StreamList(store: StreamStore(api: .shared, fetch: .followed(userID: App.previewUsername)))
    }
}
