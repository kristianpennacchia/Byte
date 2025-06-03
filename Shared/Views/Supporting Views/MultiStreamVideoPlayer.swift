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

    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var showMenu = false
    @State private var showStreamPicker = false

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
					StreamVideoPlayer(
						videoMode: .live(stream),
						muteNotFocused: shouldMuteWhenNotInFocus(stream: stream),
						isAudioOnly: audioOnlyStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) }),
						isFlipped: flippedStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) })
					)
					.onPlayToEndTime {
						remove(stream: stream)
					}
					.onPlayerFocused { player in
						focusedPlayer = player
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
						streamViewModel.selectedStream = stream
						showMenu = true
					}
				}
			}
        }
        .ignoresSafeArea()
		.background(Color.black)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onExitCommand {
            isPresented = false
        }
        .actionSheet(isPresented: $showMenu) {
            let stream = streamViewModel.selectedStream!
            let isAudioOnly = audioOnlyStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) })
            let isFlipped = flippedStreams.contains(where: { equalsStreamable(lhs: $0, rhs: stream) })

			let title: String
			if let quality = streamViewModel.streamQuality[stream.id] {
				title = "\(stream.displayName)\n\(stream.duration)\n\(quality)"
			} else {
				title = "\(stream.displayName)\n\(stream.duration)"
			}

            return ActionSheet(title: Text(title), message: Text(stream.title), buttons: [
                .default(Text("Add New Stream")) {
                    showStreamPicker = true
                },
                .default(Text(isAudioOnly ? "Show Video" : "Hide Video")) {
                    toggleShowingVideo(for: stream)
                },
                .default(Text(isFlipped ? "Unflip" : "Flip")) {
                    toggleFlippingVideo(for: stream)
                },
                .destructive(Text("Remove Stream")) {
                    remove(stream: stream)
                },
                .cancel()
            ])
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
    func remove(stream: any Streamable) {
        guard let index = streams.firstIndex(where: {equalsStreamable(lhs: $0, rhs: stream) }) else { return }

        streams.remove(at: index)

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
        if showMenu || showStreamPicker {
            return streamViewModel.selectedStream != nil && equalsStreamable(lhs: streamViewModel.selectedStream!, rhs: stream) == false
        } else {
            return streams.count > 1
        }
    }
}
