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
		@Published var streamQuality = [String: String]()
    }

    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var showControlsOverlay = false
    @State private var showStreamPicker = false
	@State private var didDismissControlsOverlayWithExit = false

    @ObservedObject var store: StreamStore
    @State var streams: [any Streamable]
    @State var audioOnlyStreams = [any Streamable]()
    @State var flippedStreams = [any Streamable]()
    @State var focusedPlayer: AVPlayer?
    @Binding var isPresented: Bool

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

						StreamVideoPlayer(
							videoMode: .live(stream),
							muteNotFocused: shouldMuteWhenNotInFocus(stream: stream),
							isAudioOnly: isAudioOnly,
							isFlipped: isFlipped
						)
						.onPlayToEndTime {
							remove(stream: stream)
						}
						.onPlayerFocused { player in
							focusedPlayer = player
							if showControlsOverlay == false {
								streamViewModel.selectedStream = stream
							}
						}
						.onStreamError { _ in
							remove(stream: stream)
						}
						.onReceiveVideoQuality { videoMode, quality in
							if case .live(let streamable) = videoMode {
								streamViewModel.streamQuality[streamable.id] = quality
							}
						}
						.equatable()
						.aspectRatio(contentMode: .fit)
						.onTapGesture {
							showControls(for: stream)
						}

						if showControlsOverlay, isSelected(stream) {
							StreamControlsOverlay(
								stream: stream,
								quality: streamViewModel.streamQuality[stream.id],
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
								dismiss: hideControlsOverlayFromExit
							)
							.transition(.opacity.combined(with: .scale(scale: 0.98)))
						}
					}
				}
			}

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
		streamViewModel.selectedStream = stream
		showControlsOverlay = true
	}

	func hideControlsOverlay() {
		showControlsOverlay = false
	}

	func hideControlsOverlayFromExit() {
		showControlsOverlay = false
		didDismissControlsOverlayWithExit = true

		DispatchQueue.main.async {
			didDismissControlsOverlayWithExit = false
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
        if showControlsOverlay || showStreamPicker {
            return streamViewModel.selectedStream != nil && equalsStreamable(lhs: streamViewModel.selectedStream!, rhs: stream) == false
        } else {
            return streams.count > 1
        }
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
