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

    @ObservedObject var store: VideoStore

    @StateObject private var videoViewModel = VideoViewModel()

    @State private var isRefreshing = false
    @State private var showVideoPlayer = false

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
                            .padding(.bottom, 8)
                    }

                    let columns = Array(repeating: GridItem(.flexible()), count: 4)
                    LazyVGrid(columns: columns) {
                        ForEach(store.items, id: \.videoId) { video in
                            VideoView(video: video)
                                .buttonWrap {
                                    videoViewModel.video = video
                                    showVideoPlayer = true
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
        isRefreshing = true
        store.fetch {
            self.isRefreshing = false
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
