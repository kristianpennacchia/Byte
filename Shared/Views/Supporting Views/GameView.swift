//
//  GameView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct GameView: View {
    @State private var isFocused = false

    let game: Game
    let hasFocusEffect: Bool

    var body: some View {
        VStack(alignment: .center) {
            CoverArt(game: game, artSize: CovertArtSize.medium)
                .cornerRadius(hasFocusEffect ? 0 : 8)
                .thirdDimensionEffect(isExtended: hasFocusEffect ? isFocused : false)
            Spacer()
                .frame(height: 16)
            Text(game.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(0)
                .multilineTextAlignment(.center)
        }
        .focusable(true) { self.isFocused = $0 }
        .padding(.top, 6)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(game: .preview, hasFocusEffect: true)
    }
}
