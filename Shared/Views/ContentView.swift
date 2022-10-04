//
//  ContentView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    private enum AllMenuItem: Int, Identifiable, CaseIterable {
        case followedStreams

        var id: Int { rawValue }
        var title: String {
            switch self {
            case .followedStreams:
                return "Followed Streams"
            }
        }
    }

    private enum TwitchMenuItem: Int, Identifiable, CaseIterable {
        case followedStreams
        case topStreams
        case topGames
        case followedChannels

        var id: Int { rawValue }
        var title: String {
            switch self {
            case .followedStreams:
                return "Followed Streams"
            case .topStreams:
                return "Top Streams"
            case .topGames:
                return "Top Games"
            case .followedChannels:
                return "Followed Channels"
            }
        }
    }

    private enum YoutubeMenuItem: Int, Identifiable, CaseIterable {
        case followedStreams

        var id: Int { rawValue }
        var title: String {
            switch self {
            case .followedStreams:
                return "Followed Streams"
            }
        }
    }

    private enum SelectionMenuItem {
        case all(AllMenuItem)
        case twitch(TwitchMenuItem)
        case youtube(YoutubeMenuItem)
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var youtubeAPI: YoutubeAPI

    @State private var twitchUser: Channel?
    @State private var youtubeUser: YoutubePerson?
    @State private var showYoutubeAuthScreen = false
    @State private var selectedMenuItem = SelectionMenuItem.all(.followedStreams)

    init() {
        #if !os(tvOS)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "Brand")!]
        #endif
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(named: "Brand")!]
    }

    var body: some View {
        ZStack {
            Color.brand.purpleDarkDark.ignoresSafeArea()
            if twitchUser == nil {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .center, spacing: 16) {
                        List {
                            ForEach(AllMenuItem.allCases) { menuItem in
                                MenuItemButton(title: menuItem.title) {
                                    selectedMenuItem = .all(menuItem)
                                }
                            }
                            Spacer(minLength: 24)
                            Section("Twitch") {
                                ForEach(TwitchMenuItem.allCases) { menuItem in
                                    MenuItemButton(title: menuItem.title) {
                                        selectedMenuItem = .twitch(menuItem)
                                    }
                                }
                            }
                            if YoutubeAPI.isAvailable {
                                Spacer(minLength: 24)
                                Section("Youtube") {
                                    if youtubeUser == nil {
                                        Button("Sign In") {
                                            showYoutubeAuthScreen = true
                                        }
                                    } else {
                                        ForEach(YoutubeMenuItem.allCases) { menuItem in
                                            MenuItemButton(title: menuItem.title) {
                                                selectedMenuItem = .youtube(menuItem)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.leading, .trailing], 30)
                        .padding([.top, .bottom], 50)
                    }
                    .background(Color.brand.purpleDark)
                    .frame(width: 400)
                    .edgesIgnoringSafeArea(.all)
                    Group {
                        switch selectedMenuItem {
                        case .all(let menuItem):
                            switch menuItem {
                            case .followedStreams:
                                StreamList(store: StreamStore(twitchAPI: twitchAPI, youtubeAPI: youtubeAPI, fetch: .followed(userID: twitchUser!.id)))
                            }
                        case .twitch(let menuItem):
                            switch menuItem {
                            case .followedStreams:
                                StreamList(store: StreamStore(twitchAPI: twitchAPI, fetch: .followed(userID: twitchUser!.id)))
                            case .topStreams:
                                StreamList(store: StreamStore(twitchAPI: twitchAPI, fetch: .top))
                            case .topGames:
                                GameList(store: GameStore(twitchAPI: twitchAPI, fetch: .top))
                            case .followedChannels:
                                ChannelList(store: ChannelStore(twitchAPI: twitchAPI, fetch: .followed(userID: twitchUser!.id)))
                            }
                        case .youtube(let menuItem):
                            switch menuItem {
                            case .followedStreams:
                                StreamList(store: StreamStore(youtubeAPI: youtubeAPI, fetch: .followed(userID: twitchUser!.id)))
                            }
                        }
                    }
                    .padding([.top, .bottom], 50)
                    .frame(maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .accentColor(Color.brand.purple)
        .edgesIgnoringSafeArea(.bottom)
        .onFirstAppear {
            sessionStore.signInTwitch()
            sessionStore.signInYoutube()
        }
        .onReceive(sessionStore) { store in
            twitchUser = store.twitchUser
            youtubeUser = store.youtubeUser
        }
        .fullScreenCover(
            isPresented: $showYoutubeAuthScreen,
            onDismiss: {},
            content: {
                OAuthView()
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppFactory.makeContent()
    }
}
