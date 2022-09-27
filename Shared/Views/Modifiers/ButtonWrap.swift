//
//  SwiftUIView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/12/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

private struct PassthroughButtonStyle<Content: View>: ButtonStyle {
    let content: Content

    func makeBody(configuration: Self.Configuration) -> some View {
        content
    }
}

private struct ButtonWrap<Content: View>: View {
    let action: () -> Void
    let longPress: (() -> Void)?
    let content: Content

    init(action: @escaping () -> Void, longPress: (() -> Void)? = nil, @ViewBuilder builder: () -> Content) {
        self.action = action
        self.longPress = longPress
        self.content = builder()
    }

    var body: some View {
        Button(action: {}) {
            content
                .ignoresSafeArea()
        }
        .simultaneousGesture(TapGesture().onEnded(action))
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            longPress?()
        })
    }
}

extension View {
    func buttonWrap(action: @escaping () -> Void, longPress: (() -> Void)? = nil) -> some View {
        ButtonWrap(action: action, longPress: longPress) {
            self
        }
    }
}
