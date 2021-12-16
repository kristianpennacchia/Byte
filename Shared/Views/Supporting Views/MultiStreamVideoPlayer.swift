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
    private class StreamViewModel: ObservableObject {
        @Published var selectedStream: Stream?
    }

    @EnvironmentObject private var api: API
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject private var streamViewModel = StreamViewModel()

    @State private var showMenu = false
    @State private var showStreamPicker = false

    @ObservedObject var store: StreamStore
    @State var streams: Set<Stream>
    @State var audioOnlyStreams = [Stream]()
    @State var flippedStreams = [Stream]()
    @Binding var isPresented: Bool

    var body: some View {
        Group {
            GeometryReader { reader in
                LazyVGrid(columns: makeColumns(streamCount: streams.count, reader: reader), alignment: .center, spacing: 0) {
                    ForEach(Array(streams), id: \.id) { stream in
                        StreamVideoPlayer(
                            videoMode: .live(stream),
                            muteNotFocused: streams.count > 1,
                            isAudioOnly: audioOnlyStreams.contains(stream),
                            isFlipped: flippedStreams.contains(stream),
                            isPresented: $isPresented
                        )
                        .onPlayToEndTime {
                            remove(stream: stream)
                        }
                        .equatable()
                        .aspectRatio(contentMode: .fit)
                        .onSelect {
                            streamViewModel.selectedStream = stream
                            showMenu = true
                        }
                    }
                }
                .frame(maxHeight: reader.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .actionSheet(isPresented: $showMenu) {
            let stream = streamViewModel.selectedStream!
            let isAudioOnly = audioOnlyStreams.contains(stream)
            let isFlipped = flippedStreams.contains(stream)

            return ActionSheet(title: Text("\(stream.userName)\n\(stream.duration)"), message: Text(stream.title), buttons: [
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
                    self.streams.insert(stream)
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

    func remove(stream: Stream) {
        guard let index = streams.firstIndex(of: stream) else { return }

        streams.remove(at: index)

        if streams.isEmpty {
            // Dismiss
            isPresented = false
        }
    }

    func toggleShowingVideo(for stream: Stream) {
        if let index = audioOnlyStreams.firstIndex(of: stream) {
            audioOnlyStreams.remove(at: index)
        } else {
            audioOnlyStreams.append(stream)
        }
    }

    func toggleFlippingVideo(for stream: Stream) {
        if let index = flippedStreams.firstIndex(of: stream) {
            flippedStreams.remove(at: index)
        } else {
            flippedStreams.append(stream)
        }
    }
}
