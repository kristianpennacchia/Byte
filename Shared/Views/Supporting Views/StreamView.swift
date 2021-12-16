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

    @EnvironmentObject private var api: API
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @State private var isFocused = false
    @State private var game: Game?

    let stream: Stream
    let isSelected: Bool

    var body: some View {
        if game?.id != stream.gameId {
            stream.game(api: api) { result in
                switch result {
                case .success(let data):
                    self.game = data
                case .failure(let error):
                    print("Fetching game (id = \(self.stream.gameId) failed. \(error.localizedDescription))")
                }
            }
        }

        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Thumbnail(videoStream: .stream(stream))
                    .frame(minWidth: 0, maxWidth: .infinity)
                Group {
                    if self.game != nil {
                        CoverArt(game: self.game!, artSize: CovertArtSize.small)
                    } else {
                        CoverArt.Placeholder(artSize: CovertArtSize.small)
                    }
                }
                .border(Color.black)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .colorMultiply(.brand.purple)
                        .position(x: 20, y: 20)
                }
            }
            .thirdDimensionEffect(isExtended: isFocused)

            HStack(alignment: .top) {
                if isFocused {
                    Spacer()
                        .frame(width: 10)
                }
                VStack(alignment: .leading) {
                    HStack(alignment: .center, spacing: 4) {
                        Text(stream.userName)
                            .font(.caption)
                            .bold()
                            .foregroundColor(isFocused ? .brand.purple : .white)
                        Spacer()
                        Text(Self.viewCountFormatter.string(from: NSNumber(integerLiteral: stream.viewerCount)) ?? "")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.brand.live)
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 18)
                            .foregroundColor(.brand.live)
                    }
                    Text(stream.title)
                        .font(.caption)
                        .foregroundColor(isFocused ? .brand.purple : .white)
                        .lineLimit(2)
                        .frame(height: 70, alignment: .top)
                }
                if isFocused {
                    Spacer()
                        .frame(width: 10)
                }
            }
            .background(
                Group {
                    if isFocused {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                    } else {
                        RoundedRectangle(cornerRadius: 0)
                            .foregroundColor(.clear)
                    }
                }
            )
        }
        .focusable(true) {
            self.isFocused = $0
        }
        .padding(.top, 6)
        .padding(.trailing, 6)
    }
}

struct StreamView_Previews: PreviewProvider {
    static var previews: some View {
        StreamView(stream: .preview, isSelected: false)
    }
}
