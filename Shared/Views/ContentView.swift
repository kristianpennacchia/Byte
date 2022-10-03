//
//  ContentView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 29/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var twitchAPI: TwitchAPI
    @EnvironmentObject private var youtubeAPI: YoutubeAPI

    // When this value changes, the entire view is reloaded
    @State private var user: Channel?
    @State private var isSigningIn = false

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
                TabView {
                    StreamList(store: StreamStore(twitchAPI: twitchAPI, youtubeAPI: youtubeAPI, fetch: .followed(userID: user!.id)))
                        .tabItem {
                            Text("Followed Streams")
                        }
                    StreamList(store: StreamStore(twitchAPI: twitchAPI, fetch: .top))
                        .tabItem {
                            Text("Streams")
                        }
                    GameList(store: GameStore(twitchAPI: twitchAPI, fetch: .top))
                        .tabItem {
                            Text("Games")
                        }
                    ChannelList(store: ChannelStore(twitchAPI: twitchAPI, fetch: .followed(userID: user!.id)))
                        .tabItem {
                            Text("Followed Channels")
                        }
                }
                .padding(.bottom, 50)
            }
        }
        .accentColor(Color.brand.purple)
        .onFirstAppear {
            isSigningIn = true
            sessionStore.signInTwitch()
            sessionStore.signInYoutube()

        }
        .onReceive(sessionStore) { store in
            user = store.twitchUser
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppFactory.makeContent()
    }
}
