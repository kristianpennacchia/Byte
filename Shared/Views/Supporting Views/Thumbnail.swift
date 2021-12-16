//
//  Thumbnail.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.KingfisherOptionsInfo

struct Thumbnail: View {
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    enum VideoStream {
        case stream(Stream), vod(Video)
    }

    let videoStream: VideoStream
    
    var body: some View {
        let options: KingfisherOptionsInfo = [.cacheMemoryOnly, .memoryCacheExpiration(.seconds(300))]
        let url: URL?
        let duration: String
        switch videoStream {
        case .stream(let stream):
            url = URL(string: stream.thumbnail(width: 300, height: 200))
            duration = stream.duration
        case .vod(let video):
            url = URL(string: video.thumbnail(size: 300))
            duration = video.duration
        }

        return ZStack(alignment: .bottomLeading) {
            switch videoStream {
            case .stream(let stream):
                KFImage(spoilerFilter.isSpoiler(gameID: stream.gameId) ? nil : url, options: options)
                    .placeholder {
                        Placeholder()
                    }
                    .resizable()
                    .aspectRatio(1.5, contentMode: .fill)
            case .vod(_):
                // We don't care about spoilers for VODs.
                KFImage(url, options: options)
                    .placeholder {
                        Placeholder()
                    }
                    .resizable()
                    .aspectRatio(1.5, contentMode: .fill)
            }
            Text("  \(duration)  ")
                .font(.caption)
                .bold()
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(8)
                .padding([.leading, .bottom])

        }
    }
}

extension Thumbnail {
    struct Placeholder: View {
        var body: some View {
            let view = Rectangle()
                .fill(Color.black)
                .aspectRatio(1.5, contentMode: .fill)

            #if os(tvOS)
            return view
            #else
            return view.scaledToFill()
            #endif
        }
    }
}

struct Thumbnail_Previews: PreviewProvider {
    static var previews: some View {
        Thumbnail(videoStream: .stream(.preview))
    }
}
