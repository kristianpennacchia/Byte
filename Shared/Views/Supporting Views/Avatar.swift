//
//  Avatar.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import Kingfisher

struct Avatar: View {
    let channel: any Channelable

    var body: some View {
        KFImage(URL(string: channel.profileImageUrl))
			.resizing(referenceSize: AvatarSize.large, mode: .aspectFill)
            .placeholder {
                Placeholder(channel: channel)
            }
            .background(Color.brand.primary)
			.frame(width: AvatarSize.large.width, height: AvatarSize.large.height)
            .clipShape(Circle())
    }
}

extension Avatar {
    struct Placeholder: View {
        let channel: any Channelable

        var body: some View {
            Circle()
                .fill(Color.brand.primary)
				.frame(width: AvatarSize.large.width, height: AvatarSize.large.height)
                .overlay(
                    Text(String(channel.displayName.first!.uppercased()))
                        .font(.callout)
            )
        }
    }
}

struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        Avatar(channel: Channel(
            id: "",
            login: "",
            displayName: "Kristian",
            profileImageUrl: "https://static-cdn.jtvnw.net/jtv_user_pictures/peeve-profile_image-b58e1c992ab40e64-70x70.png"
        ))
    }
}
