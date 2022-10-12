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

        var isRefreshing = false
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject private var gameViewModel = GameViewModel()

    @StateObject var store: GameStore
    @State private var items = [Game]()
    @State private var showSpoilerMenu = false
    @State private var showGame = false
    @Binding var shouldRefresh: Bool

    var body: some View {
        ZStack {
            Color.brand.brandDarkDark.ignoresSafeArea()
            if items.isEmpty {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible()), count: 4)
                    LazyVGrid(columns: columns) {
                        ForEach(items) { game in
                            GameView(game: game)
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
                .padding([.leading, .trailing], 14)
                .edgesIgnoringSafeArea([.leading, .trailing])
            }
        }
        .onReceive(sessionStore) { _ in
            refresh()
        }
        .onReceive(store.$items) { items in
            self.items = items
        }
        .onReceive(AppState()) { state in
            if store.isStale, state == .willEnterForeground {
                refresh()
            }
        }
        .onChange(of: shouldRefresh) { newValue in
            if newValue {
                shouldRefresh = false
                refresh()
            }
        }
        .onAppear {
            if store.isStale {
                refresh()
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
                StreamList(store: StreamStore(twitchAPI: self.api, fetch: .game(gameViewModel.game!)), shouldRefresh: .constant(false))
                    .environmentObject(self.api)
            }
        )
    }
}

private extension GameList {
    func refresh() {
        guard gameViewModel.isRefreshing == false else { return }

        Task {
            gameViewModel.isRefreshing = true
            try? await store.fetch()
            gameViewModel.isRefreshing = false
        }
    }
}

struct GameList_Previews: PreviewProvider {
    static var previews: some View {
        GameList(store: GameStore(twitchAPI: .shared, fetch: .top), shouldRefresh: .constant(false))
    }
}
