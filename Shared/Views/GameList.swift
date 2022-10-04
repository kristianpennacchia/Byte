//
//  GameList.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct GameList: View {
    private class GameViewModel: ObservableObject {
        @Published var game: Game?
    }

    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @ObservedObject var store: GameStore

    @StateObject private var gameViewModel = GameViewModel()

    @State private var isRefreshing = false
    @State private var showSpoilerMenu = false
    @State private var showGame = false

    var body: some View {
        ZStack {
            Color.brand.purpleDarkDark.ignoresSafeArea()
            if isRefreshing, store.items.isEmpty {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                    if store.items.isEmpty == false {
                        Refresh(isAnimating: $isRefreshing, action: refresh)
                            .padding(.bottom, 8)
                    }

                    let columns = Array(repeating: GridItem(.flexible()), count: 6)
                    LazyVGrid(columns: columns) {
                        ForEach(store.items) { game in
                            GameView(game: game, hasFocusEffect: false)
                                .buttonWrap {
                                    gameViewModel.game = game
                                    showGame = true
                                } longPress: {
                                    gameViewModel.game = game
                                    showSpoilerMenu = true
                                }
                        }
                    }
                    .padding([.leading, .trailing], 14)
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
                .padding([.leading, .trailing], 14)
                .edgesIgnoringSafeArea([.leading, .trailing])
            }
        }
        .actionSheet(isPresented: $showSpoilerMenu) {
            return ActionSheet(title: Text("Spoiler Filter"), message: nil, buttons: [
                .default(Text(spoilerFilter.isSpoiler(gameID: gameViewModel.game!.id) ? "Show Game Thumbnail" : "Hide Game Thumbnail")) {
                    spoilerFilter.toggle(gameID: gameViewModel.game!.id)
                },
                .cancel()
            ])
        }
        .fullScreenCover(
            isPresented: $showGame,
            onDismiss: {
                gameViewModel.game = nil

                if store.isStale {
                    refresh()
                }
            },
            content: {
                StreamList(store: StreamStore(twitchAPI: self.api, fetch: .game(gameViewModel.game!)))
                    .environmentObject(self.api)
            }
        )
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
        GameList(store: GameStore(twitchAPI: .shared, fetch: .top))
    }
}
