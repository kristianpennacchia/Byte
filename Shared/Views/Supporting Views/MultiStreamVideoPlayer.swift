//
//  StreamPicker.swift
//  Byte
//
//  Created by Kristian Pennacchia on 6/7/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import AVKit

struct MultiStreamVideoPlayer: View {
	@MainActor
	private class StreamViewModel: ObservableObject {
		@Published var selectedStream: (any Streamable)?
		@Published var selectedStreamQuality = [String: StreamQuality]()
		@Published var streamQuality = [String: [StreamQuality]]()
	}

	@EnvironmentObject private var spoilerFilter: SpoilerFilter
	@Environment(\.resetFocus) private var resetFocus

	@StateObject private var streamViewModel = StreamViewModel()

	@State private var showControlsOverlay = false
	@State private var showStreamPicker = false
	@State private var didDismissControlsOverlayWithExit = false
	@State private var restoringSelectedStreamID: String?

	@ObservedObject var store: StreamStore
	@State var streams: [any Streamable]
	@State var audioOnlyStreams = [any Streamable]()
	@State var flippedStreams = [any Streamable]()
	@State var focusedPlayer: AVPlayer?
	@Binding var isPresented: Bool
	@Namespace private var streamFocusNamespace

	var body: some View {
		ZStack {
			PlayerLayer(player: focusedPlayer, videoGravity: .resizeAspectFill)
			VisualEffectView(effect: UIBlurEffect(style: .dark))

			let columnCount = Int(ceil(sqrt(Double(streams.count))))
			let columns = Array(
				repeating: GridItem(.flexible(), spacing: 0),
				count: columnCount
			)

			LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
				ForEach(streams, id: \.id) { stream in
					ZStack {
						let isAudioOnly = audioOnlyStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) })
						let isFlipped = flippedStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) })
						let isRestoreTarget = restoringSelectedStreamID == stream.id

						StreamVideoPlayer(
							videoMode: .live(stream),
							muteNotFocused: shouldMuteWhenNotInFocus(stream: stream),
							hasSelectedAudioStream: streamViewModel.selectedStream != nil,
							isSelectedForAudio: isSelected(stream),
							isAudioOnly: isAudioOnly,
							isFlipped: isFlipped,
							streamQuality: streamViewModel.selectedStreamQuality[stream.id]
						)
						.onPlayToEndTime {
							remove(stream: stream)
						}
						.onPlayerFocused { player in
							focusedPlayer = player
							if showControlsOverlay == false {
								if let restoringSelectedStreamID {
									if restoringSelectedStreamID == stream.id {
										streamViewModel.selectedStream = stream
										self.restoringSelectedStreamID = nil
									}
									return
								}

								streamViewModel.selectedStream = stream
							}
						}
						.onStreamError { _ in
							remove(stream: stream)
						}
						.onReceiveVideoQuality { videoMode, qualities in
							if case .live(let streamable) = videoMode {
								if streamViewModel.streamQuality[streamable.id] != qualities {
									streamViewModel.streamQuality[streamable.id] = qualities
								}

								// Set default selected quality if current quality does not exist in the qualities array.
								if (qualities.contains(where: { $0.id == streamViewModel.selectedStreamQuality[stream.id]?.id }) == false) {
									streamViewModel.selectedStreamQuality[stream.id] = qualities.first
								}
							}
						}
						.equatable()
						.aspectRatio(contentMode: .fit)
						.prefersDefaultFocus(isRestoreTarget || isSelected(stream), in: streamFocusNamespace)
						.onTapGesture {
							showControls(for: stream)
						}

						if showControlsOverlay, isSelected(stream) {
							StreamControlsOverlay(
								stream: stream,
								selectedQuality: streamViewModel.selectedStreamQuality[stream.id],
								streamQualities: streamViewModel.streamQuality[stream.id] ?? [],
								isAudioOnly: isAudioOnly,
								isFlipped: isFlipped,
								addStream: {
									hideControlsOverlay()
									showStreamPicker = true
								},
								toggleVideo: {
									toggleShowingVideo(for: stream)
								},
								toggleFlip: {
									toggleFlippingVideo(for: stream)
								},
								removeStream: {
									hideControlsOverlay()
									remove(stream: stream)
								},
								changeQuality: { newQuality in
									streamViewModel.selectedStreamQuality[stream.id] = newQuality
								},
								dismiss: hideControlsOverlayFromExit
							)
							.transition(.opacity.combined(with: .scale(scale: 0.98)))
						}
					}
				}
			}
			.focusScope(streamFocusNamespace)

			ExitCommandInterceptor(
				isActive: showControlsOverlay,
				onExit: hideControlsOverlayFromExit
			)
			.frame(width: 1, height: 1)
		}
		.ignoresSafeArea()
		.interactiveDismissDisabled(true)
		.background(Color.black)
		.onAppear {
			UIApplication.shared.isIdleTimerDisabled = true
		}
		.onDisappear {
			UIApplication.shared.isIdleTimerDisabled = false
		}
		.onExitCommand {
			if showControlsOverlay {
				hideControlsOverlay()
			} else if didDismissControlsOverlayWithExit {
				didDismissControlsOverlayWithExit = false
			} else {
				isPresented = false
			}
		}
		.fullScreenCover(
			isPresented: $showStreamPicker,
			onDismiss: {
			},
			content: {
				StreamPicker(store: store) { stream in
					showStreamPicker = false
					streams.append(stream)
				}
			}
		)
	}
}
private extension MultiStreamVideoPlayer {
	func showControls(for stream: any Streamable) {
		restoringSelectedStreamID = nil
		streamViewModel.selectedStream = stream
		showControlsOverlay = true
	}

	func hideControlsOverlay() {
		showControlsOverlay = false
		restoreSelectedStreamFocus()
	}

	func hideControlsOverlayFromExit() {
		showControlsOverlay = false
		didDismissControlsOverlayWithExit = true
		restoreSelectedStreamFocus()

		DispatchQueue.main.async {
			didDismissControlsOverlayWithExit = false
		}
	}

	func restoreSelectedStreamFocus() {
		restoringSelectedStreamID = streamViewModel.selectedStream?.id

		DispatchQueue.main.async {
			resetFocus(in: streamFocusNamespace)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
				resetFocus(in: streamFocusNamespace)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
					restoringSelectedStreamID = nil
				}
			}
		}
	}

	func isSelected(_ stream: any Streamable) -> Bool {
		guard let selectedStream = streamViewModel.selectedStream else { return false }
		return equalsStreamable(lhs: selectedStream, rhs: stream)
	}

	func remove(stream: any Streamable) {
		guard let index = streams.firstIndex(where: {equalsStreamable(lhs: $0, rhs: stream) }) else { return }

		streams.remove(at: index)
		if isSelected(stream) {
			streamViewModel.selectedStream = nil
		}

		if streams.isEmpty {
			// Dismiss
			isPresented = false
		}
	}

	func toggleShowingVideo(for stream: any Streamable) {
		if let index = audioOnlyStreams.firstIndex(where: { equalsStreamable(lhs: $0, rhs: stream) }) {
			audioOnlyStreams.remove(at: index)
		} else {
			audioOnlyStreams.append(stream)
		}
	}

	func toggleFlippingVideo(for stream: any Streamable) {
		if let index = flippedStreams.firstIndex(where: { equalsStreamable(lhs: $0, rhs: stream) }) {
			flippedStreams.remove(at: index)
		} else {
			flippedStreams.append(stream)
		}
	}

	func shouldMuteWhenNotInFocus(stream: any Streamable) -> Bool {
		return streams.count > 1
	}
}

private struct ExitCommandInterceptor: UIViewControllerRepresentable {
	let isActive: Bool
	let onExit: () -> Void

	func makeUIViewController(context: Context) -> ExitCommandInterceptorViewController {
		let viewController = ExitCommandInterceptorViewController()
		viewController.onExit = onExit
		return viewController
	}

	func updateUIViewController(_ viewController: ExitCommandInterceptorViewController, context: Context) {
		viewController.isActive = isActive
		viewController.onExit = onExit
		viewController.updateResponderState()
	}
}

private final class ExitCommandInterceptorViewController: UIViewController {
	var isActive = false
	var onExit: (() -> Void)?

	override var canBecomeFirstResponder: Bool {
		isActive
	}

	override var keyCommands: [UIKeyCommand]? {
		guard isActive else { return nil }

		return [
			UIKeyCommand(
				input: UIKeyCommand.inputEscape,
				modifierFlags: [],
				action: #selector(handleExitCommand)
			)
		]
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		updateResponderState()
	}

	func updateResponderState() {
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }

			if isActive {
				becomeFirstResponder()
			} else {
				resignFirstResponder()
			}
		}
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if isActive, presses.contains(where: { $0.type == .menu }) {
			onExit?()
			return
		}

		super.pressesBegan(presses, with: event)
	}

	@objc private func handleExitCommand() {
		guard isActive else { return }
		onExit?()
	}
}
