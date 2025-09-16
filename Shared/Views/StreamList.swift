//
//  ChannelList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct StreamList: View {
	@MainActor
    private class StreamViewModel: ObservableObject {
        @Published var streams = [any Streamable]()
        @Published var stream: (any Streamable)?
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var streams = [StreamStore.UniqueStream]()
    @State private var selectedStreams = [any Streamable]()
    @State private var showStreamMenu = false
    @State private var showChannel = false
    @State private var showVideoPlayer = false
    @State private var isRefreshing = false

    @StateObject var store: StreamStore
    @Binding var shouldRefresh: Bool

    var body: some View {
        ZStack {
            Color.brand.primaryDarkDark.ignoresSafeArea()
			if isRefreshing {
				HeartbeatActivityIndicator()
					.frame(alignment: .center)
			} else if sessionStore.twitchUser == nil && sessionStore.youtubeUser == nil {
				// Not signed in, show nothing.
			} else if streams.isEmpty {
				Text("No Streams")
					.font(.largeTitle)
					.frame(alignment: .center)
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible()), count: 3)
                    LazyVGrid(columns: columns) {
                        ForEach(streams) { uniqueItem in
                            let stream = uniqueItem.stream
							let multiSelectIndex = selectedStreams.firstIndex(where: { equalsStreamable(lhs: $0, rhs: stream) })
                            StreamView(stream: stream, multiSelectIndex: multiSelectIndex)
                                .navigationBarTitle(store.fetchType.navBarTitle)
                                .buttonWrap {
                                    if selectedStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) }) == false {
                                        selectedStreams.append(stream)
                                    }

                                    streamViewModel.streams = selectedStreams
                                    streamViewModel.stream = stream
                                    showVideoPlayer = true
                                } longPress: {
                                    streamViewModel.stream = stream
                                    showStreamMenu = true
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
        .onChange(of: shouldRefresh) { oldValue, newValue in
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
        .actionSheet(isPresented: $showStreamMenu) {
            var buttons = [ActionSheet.Button]()

            if let stream = streamViewModel.stream as? Stream {
                buttons.append(
                    .default(Text(spoilerFilter.isSpoiler(gameID: stream.gameId) ? "Show Game Thumbnail" : "Hide Game Thumbnail")) {
                        spoilerFilter.toggle(gameID: stream.gameId)
                    }
                )
            }

            if let stream = streamViewModel.stream {
                buttons.append(
                    .default(Text("View \(stream.displayName)")) {
                        showChannel = true
                    }
                )
            }

            buttons.append(.cancel())

            return ActionSheet(title: Text(""), message: nil, buttons: buttons)
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
            isPresented: $showChannel,
            onDismiss: {
                streamViewModel.stream = nil
            },
            content: {
                switch type(of: streamViewModel.stream!).platform {
                case .twitch:
					VideoList(store: VideoStore(twitchAPI: sessionStore.twitchAPI!, fetch: .user(userID: streamViewModel.stream!.userId)))
						.environmentObject(sessionStore)
                case .youtube:
					VideoList(store: VideoStore(youtubeAPI: sessionStore.youtubeAPI!, fetch: .user(userID: streamViewModel.stream!.userId)))
						.environmentObject(sessionStore)
                }
            }
        )
    }
}

private extension StreamList {
    func refresh() {
        guard isRefreshing == false else { return }

        Task {
            isRefreshing = true

			// Handle the situation where the user may have just signed in, but the old
			// follow fetch type has a `nil` twitch user ID, resulting in the refresh not
			// showin the followed streams.
			if case .followed(let twitchUserId) = store.fetchType, twitchUserId == nil {
				store.fetchType = .followed(twitchUserID: sessionStore.twitchUser?.id)
			}

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
