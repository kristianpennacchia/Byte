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
    let hasFocusEffect: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Avatar(channel: channel)
                .thirdDimensionEffect(isExtended: hasFocusEffect ? isFocused : false)
            VStack(alignment: .center) {
                Text(channel.displayName)
            }
        }
        .focusable(true) { self.isFocused = $0 }
        .padding(.top, hasFocusEffect ? 6 : 0)
        .padding(.trailing, hasFocusEffect ? 6 : 0)
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView(channel: .preview, hasFocusEffect: true)
    }
}
