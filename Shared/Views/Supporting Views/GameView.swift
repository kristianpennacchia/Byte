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

    var body: some View {
		ZStack {
			Color.brand.primaryDark.cornerRadius(22)
			VStack(alignment: .center) {
				CoverArt(game: game, artSize: CovertArtSize.medium)
					.cornerRadius(8)
				Spacer()
					.frame(height: 16)
				ZStack {
					if isFocused {
						Color.brand.primaryDarkDark.cornerRadius(18)
					} else {
						Color.brand.primaryDark.cornerRadius(18)
					}
					Text(game.name)
						.font(.caption)
						.foregroundColor(.white)
						.lineLimit(0)
						.multilineTextAlignment(.center)
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

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(game: .preview)
    }
}
