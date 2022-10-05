//
//  StreamPicker.swift
//  Byte
//
//  Created by Kristian Pennacchia on 8/7/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct StreamPicker: View {
    @EnvironmentObject private var api: TwitchAPI
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @ObservedObject var store: StreamStore

    @State private var isRefreshing = false

    let onSelectedStream: (any Streamable) -> Void

    var body: some View {
        ZStack {
            ZStack {
                ScrollView {
                    if store.items.isEmpty == false {
                        Refresh(isAnimating: $isRefreshing, action: refresh)
                    }

                    let columns = Array(repeating: GridItem(.flexible()), count: 4)
                    LazyVGrid(columns: columns) {
                        ForEach(store.items, id: \.id) { stream in
                            StreamView(stream: stream, isSelected: false)
                                .buttonWrap {
                                    onSelectedStream(stream)
                                }
                        }
                        .padding(14)
                    }
                }
                .onAppear {
                    if store.isStale {
                        refresh()
                    }
                }
                .onReceive(AppState()) { state in
                    if store.isStale, state == .willEnterForeground {
                        refresh()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(25)
            .background(
                ZStack {
                    Color.brand.brand
                    Color.black.opacity(0.7)
                }
            )
        }
        .padding([.leading, .trailing], 50)
        .padding([.top, .bottom], 50)
        .background(VisualEffectView(effect: UIBlurEffect(style: .dark)))
        .edgesIgnoringSafeArea(.all)
    }
}

private extension StreamPicker {
    func refresh() {
        isRefreshing = true
        store.fetch {
            self.isRefreshing = false
        }
    }
}

//struct StreamPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        var selectedStream: Binding<Stream>
//        StreamPicker(store: StreamStore(twitchAPI: .shared, fetch: .followed(userID: app.previewUsername)), selectedStream: Binding<Stream>())
//    }
//}
