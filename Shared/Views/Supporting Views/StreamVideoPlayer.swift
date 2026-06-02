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
import OSLog

struct StreamVideoPlayer: View {
	@MainActor
	private class PlayerViewModel: ObservableObject {
		@Published var player = AVPlayer()

		var isConfigured: Bool { player.currentItem != nil }
	}

	fileprivate enum PlayingItem {
		case url(URL)
		case asset(AVAsset)
	}

	@EnvironmentObject private var sessionStore: SessionStore
	@EnvironmentObject private var spoilerFilter: SpoilerFilter

	@FocusState private var isFocused: Bool

	@State private var showErrorAlert = false
	@State private var error: Error?
	@State private var currentPlayingItem: PlayingItem?
	@State private var indicatorState: SwimplyPlayIndicator.AudioState = .stop

	@StateObject private var playerViewModel = PlayerViewModel()

	private var onPlayToEndTime: (() -> Void)?
	private var onPlayerFocused: ((AVPlayer) -> Void)?
	private var onStreamError: ((Error?) -> Void)?
	private var onReceiveVideoQuality: ((_ videoMode: LiveVideoFetcher.VideoMode, _ qualities: [StreamQuality]) -> Void)?

	let videoMode: LiveVideoFetcher.VideoMode
	let muteNotFocused: Bool
	let hasSelectedAudioStream: Bool
	let isSelectedForAudio: Bool
	let isAudioOnly: Bool
	let isFlipped: Bool
	let streamQuality: StreamQuality?

	init(videoMode: LiveVideoFetcher.VideoMode, muteNotFocused: Bool, hasSelectedAudioStream: Bool = false, isSelectedForAudio: Bool = false, isAudioOnly: Bool, isFlipped: Bool, streamQuality: StreamQuality?) {
		self.videoMode = videoMode
		self.muteNotFocused = muteNotFocused
		self.hasSelectedAudioStream = hasSelectedAudioStream
		self.isSelectedForAudio = isSelectedForAudio
		self.isAudioOnly = isAudioOnly
		self.isFlipped = isFlipped
		self.streamQuality = streamQuality
	}

	var body: some View {
		if playerViewModel.isConfigured == false {
			playerViewModel.player.isMuted = muteNotFocused
		}

		let fetcher = LiveVideoFetcher(twitchAPI: sessionStore.twitchAPI, videoMode: videoMode)

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
			SwimplyPlayIndicator(state: $indicatorState, color: .brand.primary.opacity(0.5), style: .legacy)
				.frame(width: 18, height: 18)
				.position(x: 30, y: 30)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.focusable(disableSeeking)
		.focused($isFocused)
		.onAppear {
			initiateStream(fetcher: fetcher, force: false)
		}
		.onDisappear {
			playerViewModel.player.pause()
			playerViewModel.player.replaceCurrentItem(with: nil)
		}
		.onLongPressGesture {
			guard let currentPlayingItem = currentPlayingItem else { return }

			playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: currentPlayingItem))
			playerViewModel.player.playImmediately(atRate: 1.0)
		}
		.onChange(of: isFocused) { _, newValue in
			updateMutedState()

			if newValue {
				onPlayerFocused?(playerViewModel.player)
			}
		}
		.onChange(of: muteNotFocused) { _, _ in
			updateMutedState()
		}
		.onChange(of: hasSelectedAudioStream) { _, _ in
			updateMutedState()
		}
		.onChange(of: isSelectedForAudio) { _, _ in
			updateMutedState()
		}
		.onChange(of: streamQuality) { _, newQuality in
			guard let newQuality else { return }

			let playingItem = PlayingItem.url(newQuality.url)
			currentPlayingItem = playingItem

			playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: playingItem))
			playerViewModel.player.playImmediately(atRate: 1.0)
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
					onStreamError?(error)
				}
			)
		}
	}
}
private extension StreamVideoPlayer {
	func updateMutedState() {
		if muteNotFocused {
			let isAudible = hasSelectedAudioStream ? isSelectedForAudio : isFocused
			playerViewModel.player.isMuted = !isAudible
			indicatorState = isAudible ? .play : .stop
		} else {
			playerViewModel.player.isMuted = false
			indicatorState = .stop
		}
	}

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

	func initiateStream(fetcher: LiveVideoFetcher, force: Bool) {
		// Continue if this stream has not already been configured, or one of the variables has changed.
		guard playerViewModel.isConfigured == false || force else { return }

		Task { @MainActor in
			do {
				let videoResponse = try await fetcher.fetch()
				let playingItem: PlayingItem
				let automaticallyWaitsToMinimizeStalling: Bool
				let streamQualities: [StreamQuality]
				var selectedStreamQuality: StreamQuality?

				switch videoResponse {
				case .playlist(let playlist, let manifestUrl):
					if playlist.meta.isEmpty, let urlString = playlist.rawURLs.last {
						playingItem = .url(URL(string: urlString)!)
						automaticallyWaitsToMinimizeStalling = true
						streamQualities = []
					} else if playlist.meta.isEmpty == false {
						streamQualities = playlist.meta.sorted(by: >).map { meta in
							return StreamQuality(label: meta.name ?? meta.resolution ?? "Unknown (\(meta.bandwidth)", url: URL(string: meta.url)!, bandwidth: meta.bandwidth)
						}
						selectedStreamQuality = streamQualities.first { $0.id == streamQuality?.id } ?? streamQualities.first!
						playingItem = .url(selectedStreamQuality!.url)
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
					selectedStreamQuality = StreamQuality(label: format.quality, url: format.url, bandwidth: format.bitrate)
					streamQualities = [selectedStreamQuality!]
				case .ytdlpFormats(let formats):
					if let avFormat = formats
						.filter({ $0.ext == "mp4" && $0.vcodec.contains("avc1.") && $0.acodec.contains("mp4a.") })
						.sorted(by: { $0.height ?? 0 > $1.height ?? 0 })
						.first
					{
						playingItem = .url(avFormat.url)
						automaticallyWaitsToMinimizeStalling = false
						selectedStreamQuality = StreamQuality(label: avFormat.resolution ?? "Unknown (\(avFormat.filesize ?? 0))", url: avFormat.url, bandwidth: Int(avFormat.filesize ?? 0))
						streamQualities = [selectedStreamQuality!]
						Logger.streaming.debug("url = \(avFormat.url)")
						break
					}

					let supportedFormats = formats.sorted(by: >).filter { $0.ext == "mp4" || $0.ext == "m4a" }
					if let audioURL = supportedFormats.first(where: \.isAudioOnly)?.url, let video = supportedFormats.first(where: \.isVideoOnly) {
						let audioAsset = AVAsset(url: audioURL)
						let videoAsset = AVAsset(url: video.url)

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
						selectedStreamQuality = StreamQuality(label: video.resolution ?? "Unknown (\(video.filesize ?? 0))", url: video.url, bandwidth: Int(video.filesize ?? 0))
						streamQualities = [selectedStreamQuality!]
					} else {
						throw AppError(message: "Unable to get valid audio and video URLs.")
					}
				case .urls(let urls):
					Logger.streaming.debug("urls = \(urls)")
					if urls.isEmpty == false {
						playingItem = .url(urls.first!)
						automaticallyWaitsToMinimizeStalling = true
						selectedStreamQuality = nil
						streamQualities = []
					} else {
						throw AppError(message: "Unable to get valid video URL.")
					}
				}

				currentPlayingItem = playingItem

				playerViewModel.player.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
				playerViewModel.player.replaceCurrentItem(with: makePlayerItem(from: playingItem))
				playerViewModel.player.playImmediately(atRate: 1.0)

				updateMutedState()

				onReceiveVideoQuality?(videoMode, streamQualities)
			} catch {
				Logger.streaming.error("Failed fetching live video data. \(error.localizedDescription)")
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

	func onStreamError(perform: @escaping (Error?) -> Void) -> Self {
		var copy = self
		copy.onStreamError = perform
		return copy
	}

	func onReceiveVideoQuality(perform: @escaping (_ videoMode: LiveVideoFetcher.VideoMode, _ qualities: [StreamQuality]) -> Void) -> Self {
		var copy = self
		copy.onReceiveVideoQuality = perform
		return copy
	}
}

extension StreamVideoPlayer: Equatable {
	static func == (lhs: StreamVideoPlayer, rhs: StreamVideoPlayer) -> Bool {
		return lhs.videoMode == rhs.videoMode
		&& lhs.muteNotFocused == rhs.muteNotFocused
		&& lhs.hasSelectedAudioStream == rhs.hasSelectedAudioStream
		&& lhs.isSelectedForAudio == rhs.isSelectedForAudio
		&& lhs.isAudioOnly == rhs.isAudioOnly
		&& lhs.isFlipped == rhs.isFlipped
		&& lhs.streamQuality == rhs.streamQuality
	}
}
