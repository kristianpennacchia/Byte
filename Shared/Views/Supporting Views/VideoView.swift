//
//  VideoView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/8/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct VideoView: View {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    @EnvironmentObject private var api: API
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @State private var isFocused = false

    let video: Video

    var body: some View {
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Thumbnail(videoStream: .vod(video))
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .thirdDimensionEffect(isExtended: isFocused)

            HStack(alignment: .top) {
                if isFocused {
                    Spacer()
                        .frame(width: 10)
                }
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.caption)
                        .bold()
                        .foregroundColor(isFocused ? .brand.purple : .white)
                    HStack(alignment: .center, spacing: 4) {
                        Text(Self.dateFormatter.string(from: video.createdAt))
                            .font(.caption)
                            .bold()
                            .foregroundColor(.brand.live)
                        Image(systemName: "calendar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 18)
                            .foregroundColor(.brand.live)
                    }
                    Text(video.description)
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

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(video: .preview)
    }
}
