//
//  StreamPicker.swift
//  Byte
//
//  Created by Kristian Pennacchia on 8/7/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct StreamPicker: View {
	@EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var spoilerFilter: SpoilerFilter

    @StateObject var store: StreamStore

    @State private var streams = [StreamStore.UniqueStream]()
    @State private var isRefreshing = false

    let onSelectedStream: (any Streamable) -> Void

    var body: some View {
        ZStack {
            ZStack {
                ScrollView {
                    if streams.isEmpty == false {
                        Refresh(isAnimating: $isRefreshing, action: refresh)
                    }

                    let columns = Array(repeating: GridItem(.flexible()), count: 4)
                    LazyVGrid(columns: columns) {
                        ForEach(streams) { uniqueItem in
                            let stream = uniqueItem.stream
                            StreamView(stream: stream, multiSelectIndex: nil)
                                .buttonWrap {
                                    onSelectedStream(stream)
                                }
                        }
                        .padding(14)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(25)
            .background(
                ZStack {
                    Color.brand.primary
                    Color.black.opacity(0.7)
                }
            )
        }
        .onReceive(store.$uniquedItems) { items in
            streams = items
        }
        .onReceive(AppState()) { state in
            if store.isStale, state == .willEnterForeground {
                refresh()
            }
        }
        .onAppear {
            if store.isStale {
                refresh()
            }
        }
        .padding([.leading, .trailing], 50)
        .padding([.top, .bottom], 50)
        .background(VisualEffectView(effect: UIBlurEffect(style: .dark)))
        .edgesIgnoringSafeArea(.all)
    }
}

private extension StreamPicker {
    func refresh() {
        guard isRefreshing == false else { return }

        Task {
            isRefreshing = true
            try? await store.fetch()
            isRefreshing = false
        }
    }
}

//struct StreamPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        var selectedStream: Binding<Stream>
//        StreamPicker(store: StreamStore(twitchAPI: .shared, fetch: .followed(userID: app.previewUsername)), selectedStream: Binding<Stream>())
//    }
//}
