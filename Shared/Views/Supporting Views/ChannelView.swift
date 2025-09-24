//
//  ChannelView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ChannelView: View {
	@State private var isFocused = false

    let channel: any Channelable

    var body: some View {
		ZStack {
			Color.brand.primaryDark.cornerRadius(22)
			VStack(alignment: .center, spacing: 8) {
				Avatar(channel: channel)

				ZStack {
					if isFocused {
						Color.brand.primaryDarkDark.cornerRadius(18)
					} else {
						Color.brand.primaryDark.cornerRadius(18)
					}
					VStack(alignment: .center) {
						Text(channel.displayName)
							.multilineTextAlignment(TextAlignment.center)
					}
					.padding()
				}
			}
			.padding()
		}
		.focusable(true) {
			self.isFocused = $0
		}
		.animation(Animation.bouncy) { contentView in
			contentView.scaleEffect(isFocused ? 1.05 : 1.0)
		}
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView(channel: channelPreview)
    }
}
