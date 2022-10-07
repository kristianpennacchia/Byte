//
//  Thumbnail.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import Kingfisher

struct Thumbnail: View {
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    enum VideoStream {
        case stream(any Streamable), vod(any Videoable)
    }

    let videoStream: VideoStream
    
    var body: some View {
        let url: URL?
        let duration: String?
        let isSpoiler: Bool
        switch videoStream {
        case .stream(let stream):
            url = URL(string: stream.thumbnail(width: 300, height: 200))
            duration = stream.duration

            if let twitchStream = stream as? Stream {
                isSpoiler = spoilerFilter.isSpoiler(gameID: twitchStream.gameId)
            } else {
                isSpoiler = false
            }
        case .vod(let video):
            url = URL(string: video.thumbnail(size: 300))
            duration = video.duration
            isSpoiler = false
        }

        return ZStack(alignment: .bottomLeading) {
            switch videoStream {
            case .stream(_):
                KFImage(isSpoiler ? nil : url)
                    .cacheMemoryOnly()
                    .memoryCacheExpiration(.seconds(300))
                    .memoryCacheAccessExtending(.none)
                    .placeholder {
                        Placeholder()
                    }
                    .resizable()
                    .aspectRatio(1.5, contentMode: .fill)
            case .vod(_):
                // We don't care about spoilers for VODs.
                KFImage(url)
                    .cacheMemoryOnly()
                    .memoryCacheExpiration(.seconds(300))
                    .memoryCacheAccessExtending(.none)
                    .placeholder {
                        Placeholder()
                    }
                    .resizable()
                    .aspectRatio(1.5, contentMode: .fill)
            }
            if let duration {
                Text("  \(duration)  ")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .padding([.leading, .bottom], 8)
            }
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
        Thumbnail(videoStream: .stream(streamablePreview))
    }
}
