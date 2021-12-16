//
//  CoverArt.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import KingfisherSwiftUI

struct CoverArt: View {
    let game: Game
    let artSize: CGSize

    var body: some View {
        KFImage(URL(string: game.boxArt(width: Int(artSize.width), height: Int(artSize.height))))
            .placeholder {
                Placeholder(artSize: artSize)
            }
            .background(Color.brand.purple)
            .frame(width: artSize.width, height: artSize.height)
    }
}

extension CoverArt {
    struct Placeholder: View {
        let artSize: CGSize

        var body: some View {
            Rectangle()
                .fill(Color.brand.purple)
                .frame(width: artSize.width, height: artSize.height)
        }
    }
}

struct CoverArt_Previews: PreviewProvider {
    static var previews: some View {
        CoverArt(game: .preview, artSize: CovertArtSize.medium)
    }
}
