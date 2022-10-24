//
//  VideoList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/8/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct VideoList: View {
    private class VideoViewModel: ObservableObject {
        @Published var video: (any Videoable)?
    }

    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject var store: VideoStore

    @StateObject private var videoViewModel = VideoViewModel()

    @State private var items = [any Videoable]()
    @State private var showVideoPlayer = false
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            Color.brand.primaryDarkDark.ignoresSafeArea()
            if items.isEmpty || isRefreshing {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                    if items.isEmpty == false {
                        Refresh(isAnimating: $isRefreshing, action: refresh)
                            .padding(.bottom, 8)
                    }

                    let columns = Array(repeating: GridItem(.flexible()), count: 4)
                    LazyVGrid(columns: columns) {
                        ForEach(items, id: \.videoId) { video in
                            VideoView(video: video)
                                .buttonWrap {
                                    videoViewModel.video = video
                                    showVideoPlayer = true
                                }
                        }
                        .padding([.leading, .trailing], 14)
                    }
                }
                .padding([.leading, .trailing], 14)
                .edgesIgnoringSafeArea([.leading, .trailing])
            }
        }
        .onReceive(store.$items) { items in
            self.items = items
        }
        .onReceive(AppState()) { state in
            if store.isStale, state == .willEnterForeground {
                refresh()
            }
        }
        .onAppear {
            if store.isStale {
                refresh()
            }
        }
        .fullScreenCover(
            isPresented: $showVideoPlayer,
            onDismiss: {
                videoViewModel.video = nil

                if store.isStale {
                    refresh()
                }
            },
            content: {
                StreamVideoPlayer(videoMode: .vod(videoViewModel.video!), muteNotFocused: false, isAudioOnly: false, isFlipped: false, isPresented: $showVideoPlayer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
            }
        )
        .navigationBarTitle(self.store.fetchType.navBarTitle)
    }
}

private extension VideoList {
    func refresh() {
        guard isRefreshing == false else { return }

        Task {
            isRefreshing = true
            try? await store.fetch()
            isRefreshing = false
        }
    }
}

private extension VideoStore.Fetch {
    var navBarTitle: String {
        switch self {
        case .user(let userID):
            return userID
        }
    }
}

struct VideoList_Previews: PreviewProvider {
    static var previews: some View {
        VideoList(store: VideoStore(twitchAPI: .shared, fetch: .user(userID: App.previewUsername)))
    }
}
