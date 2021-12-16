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
        VStack {
            ScrollView {
                if store.items.isEmpty == false {
                    Refresh(isAnimating: $isRefreshing, action: refresh)
                }

                let columns = Array(repeating: GridItem(.flexible()), count: 4)
                LazyVGrid(columns: columns) {
                    ForEach(store.items) { stream in
                        StreamView(stream: stream, isSelected: selectedStreams.contains(stream))
                            .navigationBarTitle(self.store.fetchType.navBarTitle)
                            .onSelect {
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
                    }
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
