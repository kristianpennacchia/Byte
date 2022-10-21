//
//  StreamPicker.swift
//  Byte
//
//  Created by Kristian Pennacchia on 6/7/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import AVKit
import SwimplyPlayIndicator

struct StreamVideoPlayer: View {
    private class PlayerViewModel: ObservableObject {
        @Published var player = AVPlayer()

        var isConfigured: Bool { player.currentItem != nil }
    }

    fileprivate enum PlayingItem {
        case url(URL)
        case asset(AVAsset)
    }

    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @FocusState private var isFocused: Bool

    @State private var showErrorAlert = false
    @State private var error: Error?
    @State private var currentPlayingItem: PlayingItem?
    @State private var indicatorState: SwimplyPlayIndicator.AudioState = .stop

    @StateObject private var playerViewModel = PlayerViewModel()

    private var onPlayToEndTime: (() -> Void)?
    private var onPlayerFocused: ((AVPlayer) -> Void)?

    let videoMode: LiveVideoFetcher.VideoMode
    let muteNotFocused: Bool
    let isAudioOnly: Bool
    let isFlipped: Bool

    @Binding var isPresented: Bool

    init(videoMode: LiveVideoFetcher.VideoMode, muteNotFocused: Bool, isAudioOnly: Bool, isFlipped: Bool, isPresented: Binding<Bool>) {
        self.videoMode = videoMode
        self.muteNotFocused = muteNotFocused
        self.isAudioOnly = isAudioOnly
        self.isFlipped = isFlipped
        self._isPresented = isPresented
    }

    var body: some View {
        if playerViewModel.isConfigured == false {
            playerViewModel.player.isMuted = muteNotFocused
        }

        let fetcher = LiveVideoFetcher(twitchAPI: twitchAPI, videoMode: videoMode)

        // If this was already been configured but a variable has been changed, let us immediately re-initiate the stream so that we can apply the new variables.
        if playerViewModel.isConfigured {
            initiateStream(fetcher: fetcher)
        }

        let disableSeeking: Bool
        switch videoMode {
        case .live(_):
            disableSeeking = true
        case .vod(_):
            disableSeeking = false
        }

        return ZStack {
            VideoPlayer(player: playerViewModel.player)
                .disabled(disableSeeking)
                .scaleEffect(CGSize(width: isFlipped ? -1 : 1, height: 1))
            if isAudioOnly {
                Color.clear
                    .background(.regularMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            SwimplyPlayIndicator(state: $indicatorState, color: .brand.brand.opacity(0.5), style: .legacy)
                .frame(width: 18, height: 18)
                .position(x: 30, y: 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable(disableSeeking)
        .focused($isFocused)
        .onAppear {
            initiateStream(fetcher: fetcher)
        }
        .onDisappear {
            playerViewModel.player.pause()
            playerViewModel.player.replaceCurrentItem(with: nil)
        }
        .onExitCommand {
            isPresented = false
        }
        .onLongPressGesture {
            guard let currentPlayingItem = currentPlayingItem else { return }

            playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: currentPlayingItem))
            playerViewModel.player.playImmediately(atRate: 1.0)
        }
        .onChange(of: isFocused) { isFocused in
            if muteNotFocused {
                playerViewModel.player.isMuted = !isFocused
                indicatorState = isFocused ? .play : .stop
            } else {
                playerViewModel.player.isMuted = false
                indicatorState = .stop
            }

            if isFocused {
                onPlayerFocused?(playerViewModel.player)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { output in
            if let item = output.object as? AVPlayerItem, item == playerViewModel.player.currentItem {
                onPlayToEndTime?()
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Unable To Play Stream"),
                message: Text(error?.localizedDescription ?? "Unknown error occurred."),
                dismissButton: .default(Text("OK")) {
                    playerViewModel.player.pause()
                    playerViewModel.player.replaceCurrentItem(with: nil)
                    isPresented = false
                }
            )
        }
    }
}

private extension StreamVideoPlayer {
    func makePlayerItem(from playingItem: PlayingItem) -> AVPlayerItem {
        let item: AVPlayerItem

        switch playingItem {
        case .url(let url):
            item = AVPlayerItem(url: url)
        case .asset(let asset):
            item = AVPlayerItem(asset: asset)
        }

        item.preferredForwardBufferDuration = 0.5
        item.automaticallyPreservesTimeOffsetFromLive = true
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        return item
    }

    func initiateStream(fetcher: LiveVideoFetcher) {
        // Continue if this stream has not already been configured, or one of the variables has changed.
        guard playerViewModel.isConfigured == false else { return }

        Task {
            do {
                let videoResponse = try await fetcher.fetch()
                let playingItem: PlayingItem
                let automaticallyWaitsToMinimizeStalling: Bool

                switch videoResponse {
                case .playlist(let playlist):
                    if let urlString = playlist.meta.isEmpty ? playlist.rawURLs.last : playlist.meta.sorted(by: >).first?.url {
                        playingItem = .url(URL(string: urlString)!)
                        automaticallyWaitsToMinimizeStalling = true
                    } else {
                        throw AppError(message: "Unable to get valid video URL.")
                    }
                case .formats(let formats):
                    guard let format = formats
                        .filter({ $0.mimeType.contains("video/mp4") && $0.mimeType.contains("avc1.") && $0.mimeType.contains("mp4a.") })
                        .sorted(by: { $0.bitrate > $1.bitrate })
                        .first
                    else {
                        throw AppError(message: "Unable to get valid video URL.")
                    }

                    playingItem = .url(format.url)
                    automaticallyWaitsToMinimizeStalling = false
                case .ytdlpFormats(let formats):
                    let supportedFormats = formats.sorted(by: >).filter { $0.ext == "mp4" || $0.ext == "m4a" }
                    if let audioURL = supportedFormats.first(where: \.isAudioOnly)?.url, let videoURL = supportedFormats.first(where: \.isVideoOnly)?.url {
                        let audioAsset = AVAsset(url: audioURL)
                        let videoAsset = AVAsset(url: videoURL)

                        let videoDuration = try await videoAsset.load(.duration)
                        let audioDuration = try await audioAsset.load(.duration)
                        let duration = videoDuration > audioDuration ? videoDuration : audioDuration

                        let mixAsset = AVMutableComposition()

                        let compoAudioTrack = mixAsset.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                        let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first!
                        try compoAudioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: audioTrack, at: .zero)

                        let compoVideoTrack = mixAsset.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                        let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first!
                        try compoVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: videoTrack, at: .zero)

                        playingItem = .asset(mixAsset)
                        automaticallyWaitsToMinimizeStalling = true
                    } else {
                        throw AppError(message: "Unable to get valid audio and video URLs.")
                    }
                case .urls(let urls):
                    print(urls)
                    if urls.isEmpty == false {
                        playingItem = .url(urls.first!)
                        automaticallyWaitsToMinimizeStalling = true
                    } else {
                        throw AppError(message: "Unable to get valid video URL.")
                    }
                }

                currentPlayingItem = playingItem

                playerViewModel.player.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
                playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: playingItem))
                playerViewModel.player.playImmediately(atRate: 1.0)

                if muteNotFocused {
                    playerViewModel.player.isMuted = isFocused == false
                }
            } catch {
                print("Failed fetching live video data. \(error.localizedDescription)")
                self.error = error
                showErrorAlert = true
            }
        }
    }
}

extension StreamVideoPlayer {
    func onPlayToEndTime(perform: @escaping () -> Void) -> Self {
        var copy = self
        copy.onPlayToEndTime = perform
        return copy
    }
    
    func onPlayerFocused(perform: @escaping (AVPlayer) -> Void) -> Self {
        var copy = self
        copy.onPlayerFocused = perform
        return copy
    }
}

extension StreamVideoPlayer: Equatable {
    static func == (lhs: StreamVideoPlayer, rhs: StreamVideoPlayer) -> Bool {
        return lhs.videoMode == rhs.videoMode
            && lhs.muteNotFocused == rhs.muteNotFocused
            && lhs.isAudioOnly == rhs.isAudioOnly
            && lhs.isFlipped == rhs.isFlipped
    }
}
