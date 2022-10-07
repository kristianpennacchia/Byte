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

    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @State private var showErrorAlert = false
    @State private var error: Error?
    @State private var currentStreamURL: URL?
    @State private var isFocused = false
    @State private var indicatorState: SwimplyPlayIndicator.AudioState = .stop
    @State private var collatedSeekCount = 0
    @State private var cancelSeekSource: TaskCancellationSource?

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
            playerViewModel.player.automaticallyWaitsToMinimizeStalling = true
            playerViewModel.player.isMuted = muteNotFocused
        }

        let fetcher = LiveVideoFetcher(twitchAPI: twitchAPI, videoMode: videoMode)

        // If this was already been configured but a variable has been changed, let us immediately re-initiate the stream so that we can apply the new variables.
        if playerViewModel.isConfigured {
            initiateStream(fetcher: fetcher)
        }

        let allowSeeking: Bool
        switch videoMode {
        case .live(_):
            allowSeeking = false
        case .vod(_):
            allowSeeking = true
        }

        return ZStack {
            VideoPlayer(player: playerViewModel.player)
                .disabled(true)
                .onAppear {
                    initiateStream(fetcher: fetcher)
                }
                .onDisappear {
                    playerViewModel.player.pause()
                    playerViewModel.player.replaceCurrentItem(with: nil)
                }
                .focusable(true) { isFocused in
                    self.isFocused = isFocused

                    if muteNotFocused {
                        playerViewModel.player.isMuted = !isFocused
                        indicatorState = isFocused ? .play : .stop
                    } else {
                        playerViewModel.player.isMuted = false
                        indicatorState = .stop
                    }
                    
                    onPlayerFocused?(playerViewModel.player)
                }
                .onPlayPauseCommand {
                    guard allowSeeking else { return }

                    if playerViewModel.player.rate == 0 {
                        playerViewModel.player.play()
                    } else {
                        playerViewModel.player.pause()
                    }
                }
                .onMoveCommand { direction in
                    guard allowSeeking else { return }

                    collatedSeekCount += 1

                    cancelSeekSource?.isCancelled = true
                    cancelSeekSource = performAfter(duration: .milliseconds(250)) {
                        let time = playerViewModel.player.currentTime()
                        let seekDurationInterval: TimeInterval = 60 * (playerViewModel.player.rate == 0 ? 10 : 2)
                        let seekDuration = CMTime(seconds: seekDurationInterval * Double(collatedSeekCount), preferredTimescale: time.timescale)

                        switch direction {
                        case .left:
                            playerViewModel.player.seek(to: time - seekDuration)
                        case .right:
                            playerViewModel.player.seek(to: time + seekDuration)
                        default:
                            break
                        }

                        // If the playback is paused, we need to play then pause immediately to force the player to update its pause frame
                        if playerViewModel.player.rate == 0 {
                            playerViewModel.player.play()
                            playerViewModel.player.pause()
                        }

                        collatedSeekCount = 0
                    }
                }
                .onExitCommand {
                    isPresented = false
                }
                .onLongPressGesture {
                    guard let currentStreamURL = currentStreamURL else { return }

                    playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: currentStreamURL))
                    playerViewModel.player.playImmediately(atRate: 1.0)
                }
                .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { output in
                    if let item = output.object as? AVPlayerItem, item == playerViewModel.player.currentItem {
                        onPlayToEndTime?()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(CGSize(width: isFlipped ? -1 : 1, height: 1))
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
            if isAudioOnly {
                Color.clear
                    .background(.regularMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            SwimplyPlayIndicator(state: $indicatorState, color: .brand.brand.opacity(0.5), style: .legacy)
                .frame(width: 18, height: 18)
                .position(x: 30, y: 30)
        }
    }
}

private extension StreamVideoPlayer {
    func makePlayerItem(from url: URL) -> AVPlayerItem {
        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 0.5
        item.automaticallyPreservesTimeOffsetFromLive = true
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        return item
    }

    func initiateStream(fetcher: LiveVideoFetcher) {
        // Continue if this stream has not already been configured, or one of the variables has changed.
        guard playerViewModel.isConfigured == false else { return }

        fetcher.fetch { result in
            switch result {
            case .success(let response):
                let url: URL?

                switch response {
                case .playlist(let playlist):
                    if let urlString = playlist.meta.isEmpty ? playlist.rawURLs.last : playlist.meta.sorted(by: >).first?.url {
                        url = URL(string: urlString)
                    } else {
                        url = nil
                    }
                case .formats(let formats):
                    let format = formats
                        .filter { $0.mimeType.contains("video/mp4") }
                        .sorted { $0.bitrate > $1.bitrate }
                        .first

                    print("playing format = \(format)")

                    url = format?.url
                }

                print("playing url = \(url)")

                DispatchQueue.main.async {
                    if url != nil {
                        currentStreamURL = url!

                        playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: url!))
                        playerViewModel.player.playImmediately(atRate: 1.0)

                        if muteNotFocused {
                            playerViewModel.player.isMuted = isFocused == false
                        }
                    } else {
                        isPresented = false
                    }
                }
            case .failure(let error):
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
