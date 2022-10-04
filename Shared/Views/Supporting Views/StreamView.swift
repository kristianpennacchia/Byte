//
//  StreamView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct StreamView: View {
    private static let viewCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @State private var isFocused = false
    @State private var game: Game?

    let stream: any Streamable
    let isSelected: Bool
    let hasFocusEffect: Bool

    var body: some View {
        if let stream = stream as? Stream, game?.id != stream.gameId {
            stream.game(api: api) { result in
                switch result {
                case .success(let data):
                    self.game = data
                case .failure(let error):
                    print("Fetching game (id = \(stream.gameId) failed. \(error.localizedDescription))")
                }
            }
        }

        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                ZStack(alignment: .bottomTrailing) {
                    Thumbnail(videoStream: .stream(stream))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .cornerRadius(hasFocusEffect ? 0 : 8)
                    if stream is Stream {
                        Group {
                            if self.game != nil {
                                CoverArt(game: self.game!, artSize: CovertArtSize.small)
                            } else {
                                CoverArt.Placeholder(artSize: CovertArtSize.small)
                            }
                        }
                        .border(Color.black)
                    }
                }

                if isSelected {
                    ZStack {
                        Circle()
                            .foregroundColor(Color.brand.brand)
                            .padding(4)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44, alignment: .center)
                    .position(x: 24, y: 24)
                }
            }
            .thirdDimensionEffect(isExtended: hasFocusEffect ? isFocused : false)

            HStack(alignment: .top) {
                if isFocused, hasFocusEffect {
                    Spacer()
                        .frame(width: 10)
                }
                VStack(alignment: .center) {
                    HStack(alignment: .top) {
                        Text(stream.userName)
                            .font(.caption)
                            .bold()
                            .foregroundColor(isFocused ? .brand.brand : .white)
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
                    Text(stream.title)
                        .font(.caption)
                        .foregroundColor(isFocused ? .brand.brand : .white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 70, alignment: .top)
                }
                if isFocused, hasFocusEffect {
                    Spacer()
                        .frame(width: 10)
                }
            }
            .background(
                Group {
                    if hasFocusEffect {
                        if isFocused {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .foregroundColor(.clear)
                        }
                    } else {
                        EmptyView()
                    }
                }
            )
        }
        .focusable(true) {
            self.isFocused = $0
        }
        .ignoresSafeArea()
        .padding(.top, hasFocusEffect ? 6 : 0)
        .padding(.trailing, hasFocusEffect ? 6 : 0)
    }
}

struct StreamView_Previews: PreviewProvider {
    static var previews: some View {
        StreamView(stream: streamablePreview, isSelected: false, hasFocusEffect: true)
    }
}
