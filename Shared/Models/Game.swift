//
//  Game.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct Game: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let boxArtUrl: String
}

extension Game {
    static let preview = Game(
        id: "csgo",
        name: "Counter-Strike: Global Offesnive",
        boxArtUrl: ""
    )

    func boxArt(width: Int, height: Int) -> String {
        boxArtUrl
            .replacingOccurrences(of: "{width}", with: "\(width)")
            .replacingOccurrences(of: "{height}", with: "\(height)")
    }
}
