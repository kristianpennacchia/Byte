//
//  GameList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct GameList: View {
    @EnvironmentObject private var api: API

    @ObservedObject var store: GameStore

    @State private var isRefreshing = false

    var body: some View {
        VStack {
            ScrollView {
                if store.items.isEmpty == false {
                    Refresh(isAnimating: $isRefreshing, action: refresh)
                }

                let columns = Array(repeating: GridItem(.flexible()), count: 6)
                LazyVGrid(columns: columns) {
                    ForEach(store.items) { game in
                        GameView(game: game)
                            .push {
                                StreamList(store: StreamStore(api: self.api, fetch: .game(game)))
                                    .environmentObject(self.api)
                            }
                    }
                }
            }
            .onAppear {
                if self.store.isStale {
                    self.refresh()
                }
            }
            .onReceive(AppState()) { state in
                if self.store.isStale, state == .willEnterForeground {
                    self.refresh()
                }
            }
        }
    }
}

private extension GameList {
    func refresh() {
        isRefreshing = true
        store.fetch {
            self.isRefreshing = false
        }
    }
}

struct GameList_Previews: PreviewProvider {
    static var previews: some View {
        GameList(store: GameStore(api: .shared, fetch: .top))
    }
}
