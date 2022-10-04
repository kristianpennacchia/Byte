//
//  ContentView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    private enum MenuItem: Int, Identifiable, CaseIterable {
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

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var youtubeAPI: YoutubeAPI

    @State private var user: Channel?
    @State private var isSigningIn = false
    @State private var showYoutubeAuthScreen = false
    @State private var selectedMenuItem = MenuItem.followedStreams

    init() {
#if !os(tvOS)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "Brand")!]
#endif
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(named: "Brand")!]
    }

    var body: some View {
        ZStack {
            Color.brand.purpleDarkDark.ignoresSafeArea()
            if user == nil {
                VStack {
                    Spacer()
                    SignInView(isSigningIn: $isSigningIn)
                    Spacer()
                }
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .center, spacing: 16) {
                        List(MenuItem.allCases) { menuItem in
                            Button {
                                selectedMenuItem = menuItem
                            } label: {
                                HStack {
                                    Text(menuItem.title)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .padding([.leading, .trailing], 50)
                        .padding([.top, .bottom], 50)
                        Button {
                            showYoutubeAuthScreen = true
                        } label: {
                            VStack {
                                Text("Youtube")
                                    .foregroundColor(.black)
                                Text("Sign in")
                                    .foregroundColor(.black.opacity(0.8))
                                    .font(.caption)
                            }
                        }
                        .tint(.red)
                        .padding([.top, .bottom], 50)
                    }
                    .background(Color.brand.purpleDark)
                    .frame(width: 350)
                    .edgesIgnoringSafeArea(.all)
                    Group {
                        switch selectedMenuItem {
                        case .followedStreams:
                            StreamList(store: StreamStore(twitchAPI: twitchAPI, youtubeAPI: youtubeAPI, fetch: .followed(userID: user!.id)))
                        case .topStreams:
                            StreamList(store: StreamStore(twitchAPI: twitchAPI, fetch: .top))
                        case .topGames:
                            GameList(store: GameStore(twitchAPI: twitchAPI, fetch: .top))
                        case .followedChannels:
                            ChannelList(store: ChannelStore(twitchAPI: twitchAPI, fetch: .followed(userID: user!.id)))
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
            isSigningIn = true
            sessionStore.signInTwitch()
            sessionStore.signInYoutube()

        }
        .onReceive(sessionStore) { store in
            user = store.twitchUser
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
