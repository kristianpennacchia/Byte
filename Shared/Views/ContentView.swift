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
        var icon: String {
            switch self {
            case .followedStreams:
                return "person.2.wave.2"
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
        var icon: String {
            switch self {
            case .followedStreams:
                return "person.2.wave.2"
            case .topStreams:
                return "crown"
            case .topGames:
                return "gamecontroller"
            case .followedChannels:
                return "person.2"
            }
        }
    }

    private enum YoutubeMenuItem: Int, Identifiable, CaseIterable {
        case followedStreams
        case followedChannels

        var id: Int { rawValue }
        var title: String {
            switch self {
            case .followedStreams:
                return "Followed Streams"
            case .followedChannels:
                return "Followed Channels"
            }
        }
        var icon: String {
            switch self {
            case .followedStreams:
                return "person.2.wave.2"
            case .followedChannels:
                return "person.2"
            }
        }
    }

    private enum SelectionMenuItem: Equatable {
        case all(AllMenuItem)
        case twitch(TwitchMenuItem)
        case youtube(YoutubeMenuItem)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.all(let lhsItem), .all(let rhsItem)):
                return lhsItem == rhsItem
            case (.twitch(let lhsItem), .twitch(let rhsItem)):
                return lhsItem == rhsItem
            case (.youtube(let lhsItem), .youtube(let rhsItem)):
                return lhsItem == rhsItem
            default:
                return false
            }
        }
    }

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var youtubeAPI: YoutubeAPI

    @State private var twitchUser: Channel?
    @State private var youtubeUser: YoutubePerson?
    @State private var showYoutubeAuthScreen = false
    @State private var selectedMenuItem = SelectionMenuItem.all(.followedStreams) {
        didSet {
            if selectedMenuItem == oldValue {
                // The user has re-selected the currently selected menu item. Initiate refresh.
                isRefreshing = true
            }
        }
    }
    @State private var isRefreshing = false

    init() {
        #if !os(tvOS)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "Brand")!]
        #endif
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(named: "Brand")!]
    }

    var body: some View {
        ZStack {
            Color.brand.brandDarkDark.ignoresSafeArea()
            if twitchUser == nil {
                HeartbeatActivityIndicator()
                    .frame(alignment: .center)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .center, spacing: 16) {
                        List {
                            ForEach(AllMenuItem.allCases) { menuItem in
                                MenuItemButton(title: menuItem.title, icon: menuItem.icon, isSelected: .all(menuItem) == selectedMenuItem) {
                                    selectedMenuItem = .all(menuItem)
                                }
                            }
                            Spacer(minLength: 24)
                            Section("Twitch") {
                                ForEach(TwitchMenuItem.allCases) { menuItem in
                                    MenuItemButton(title: menuItem.title, icon: menuItem.icon, isSelected: .twitch(menuItem) == selectedMenuItem) {
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
                                            MenuItemButton(title: menuItem.title, icon: menuItem.icon, isSelected: .youtube(menuItem) == selectedMenuItem) {
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
                    .background(Color.brand.brandDark)
                    .frame(width: 440)
                    .edgesIgnoringSafeArea(.all)
                    Group {
                        switch selectedMenuItem {
                        case .all(let menuItem):
                            switch menuItem {
                            case .followedStreams:
                                StreamList(store: StreamStore(twitchAPI: twitchAPI, youtubeAPI: youtubeAPI, fetch: .followed(twitchUserID: twitchUser!.id)), shouldRefresh: $isRefreshing)
                            }
                        case .twitch(let menuItem):
                            switch menuItem {
                            case .followedStreams:
                                StreamList(store: StreamStore(twitchAPI: twitchAPI, fetch: .followed(twitchUserID: twitchUser!.id)), shouldRefresh: $isRefreshing)
                            case .topStreams:
                                StreamList(store: StreamStore(twitchAPI: twitchAPI, fetch: .top), shouldRefresh: $isRefreshing)
                            case .topGames:
                                GameList(store: GameStore(twitchAPI: twitchAPI, fetch: .top), shouldRefresh: $isRefreshing)
                            case .followedChannels:
                                ChannelList(store: ChannelStore(twitchAPI: twitchAPI, fetch: .followed(twitchUserID: twitchUser!.id)), shouldRefresh: $isRefreshing)
                            }
                        case .youtube(let menuItem):
                            switch menuItem {
                            case .followedStreams:
                                StreamList(store: StreamStore(youtubeAPI: youtubeAPI, fetch: .followed(twitchUserID: nil)), shouldRefresh: $isRefreshing)
                            case .followedChannels:
                                ChannelList(store: ChannelStore(youtubeAPI: youtubeAPI, fetch: .followed(twitchUserID: nil)), shouldRefresh: $isRefreshing)
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding([.top, .bottom], 50)
                    .frame(alignment: .center)
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .accentColor(Color.brand.brand)
        .edgesIgnoringSafeArea(.all)
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
