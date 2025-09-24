//
//  StreamView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import OSLog

struct StreamView: View {
    private static let viewCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

	@EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @State private var isFocused = false
    @State private var game: Game?

    let stream: any Streamable
    let multiSelectIndex: Int?

    var body: some View {
		if sessionStore.twitchAPI != nil, let stream = stream as? Stream, game?.id != stream.gameId {
            Task { @MainActor in
                do {
					game = try await stream.game(api: sessionStore.twitchAPI!)
                } catch {
					Logger.twitch.debug("Fetching game (id = \(stream.gameId) failed. \(error.localizedDescription))")
                }
            }
        }

		let isSpoiler: Bool
		if let twitchStream = stream as? Stream {
			isSpoiler = spoilerFilter.isSpoiler(gameID: twitchStream.gameId)
		} else {
			isSpoiler = false
		}

		return ZStack {
			Color.brand.primaryDark.cornerRadius(22)
			VStack(alignment: .leading, spacing: 8) {
				ZStack {
					ZStack(alignment: .bottomTrailing) {
						Thumbnail(videoStream: .stream(stream))
							.frame(minWidth: 0, maxWidth: .infinity)
							.cornerRadius(18)
						if stream is Stream {
							Group {
								if self.game != nil {
									CoverArt(game: self.game!, artSize: CovertArtSize.small)
								} else {
									CoverArt.Placeholder(artSize: CovertArtSize.small)
								}
							}
							.border(Color.black)
							.clipShape(UnevenRoundedRectangle(
								cornerRadii: .init(
									topLeading: 0,
									bottomLeading: 0,
									bottomTrailing: 18,
									topTrailing: 0
								)
							))
						}
					}

					if let multiSelectIndex {
						ZStack {
							Circle()
								.foregroundColor(Color.brand.primary)
								.padding(4)
							Text("\(multiSelectIndex + 1)")
								.font(.caption)
								.foregroundColor(.white)
						}
						.frame(width: 44, height: 44, alignment: .center)
						.position(x: 24, y: 24)
					}
				}

				ZStack {
					if isFocused {
						Color.brand.primaryDarkDark.cornerRadius(18)
					} else {
						Color.brand.primaryDark.cornerRadius(18)
					}
					HStack(alignment: .top) {
						VStack(alignment: .center) {
							HStack(alignment: .top) {
								Text(stream.displayName)
									.font(.caption)
									.bold()
									.foregroundColor(.white)
									.lineLimit(1)
								if let viewerCount = stream.viewerCount,
								   let number = Self.viewCountFormatter.string(from: NSNumber(integerLiteral: viewerCount)) {
									Spacer(minLength: 4)
									HStack(alignment: .center, spacing: 4) {
										Text(number)
											.font(.caption)
											.bold()
											.foregroundColor(.brand.live)
										Image(systemName: "person.fill")
											.resizable()
											.aspectRatio(contentMode: .fit)
											.frame(height: 18)
											.foregroundColor(.brand.live)
									}
								}
							}
							Text(isSpoiler ? "" : stream.title)
								.font(.caption)
								.foregroundColor(.white)
								.lineLimit(2)
								.multilineTextAlignment(.center)
								.frame(height: 70, alignment: .top)
						}
					}
					.padding()
				}
			}
			.padding()
		}
		.focusable(true) {
			self.isFocused = $0
		}
		.ignoresSafeArea()
		.animation(Animation.bouncy) { contentView in
			contentView.scaleEffect(isFocused ? 1.05 : 1.0)
		}
    }
}

struct StreamView_Previews: PreviewProvider {
    static var previews: some View {
        StreamView(stream: streamablePreview, multiSelectIndex: nil)
    }
}
