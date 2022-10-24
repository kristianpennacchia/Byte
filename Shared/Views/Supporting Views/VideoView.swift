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

    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @State private var isFocused = false

    let video: any Videoable

    var body: some View {
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Thumbnail(videoStream: .vod(video))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .cornerRadius(8)
            }

            HStack(alignment: .top) {
                VStack(alignment: .center) {
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
                    Text(video.title)
                        .font(.caption)
                        .foregroundColor(isFocused ? .brand.primary : .white)
                        .lineLimit(2)
                        .frame(height: 70, alignment: .top)
                }
            }
        }
        .focusable(true) {
            self.isFocused = $0
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(video: videoPreview)
    }
}
