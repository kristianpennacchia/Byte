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
            if streams.count > 1 {
                PlayerLayer(player: focusedPlayer, videoGravity: .resizeAspectFill)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
				VisualEffectView(effect: UIBlurEffect(style: .dark))
					.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
					.equatable()
					.aspectRatio(contentMode: .fit)
					.onTapGesture {
						streamViewModel.selectedStream = stream
						showMenu = true
					}
				}
			}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
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

            return ActionSheet(title: Text("\(stream.displayName)\n\(stream.duration)"), message: Text(stream.title), buttons: [
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
    func makeColumns(streamCount: Int, reader: GeometryProxy) -> [GridItem] {
        switch streamCount {
        case 1:
            return [
                GridItem(.fixed(reader.size.width), spacing: 0, alignment: .center),
            ]
        case 2:
            return [
                GridItem(.fixed(reader.size.width / 2), spacing: 0, alignment: .center),
            ]
        default:
            return [
                GridItem(.adaptive(minimum: reader.size.width / 2, maximum: reader.size.width), spacing: 0, alignment: .center),
            ]
        }
    }

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
