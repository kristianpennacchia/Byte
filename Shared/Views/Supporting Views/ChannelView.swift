//
//  ChannelView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ChannelView: View {
    let channel: any Channelable

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Avatar(channel: channel)
            VStack(alignment: .center) {
                Text(channel.displayName)
            }
        }
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView(channel: channelPreview)
    }
}
