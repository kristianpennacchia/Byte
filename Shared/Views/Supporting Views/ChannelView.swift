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

    let channel: Channel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Avatar(channel: channel)
                .thirdDimensionEffect(isExtended: isFocused)
            VStack(alignment: .leading) {
                Text(channel.displayName)
            }
        }
        .focusable(true) { self.isFocused = $0 }
        .padding(.top, 6)
        .padding(.trailing, 6)
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView(channel: .preview)
    }
}
