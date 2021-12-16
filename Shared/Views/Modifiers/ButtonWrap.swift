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
    let content: Content

    init(action: @escaping () -> Void, @ViewBuilder builder: () -> Content) {
        self.action = action
        self.content = builder()
    }

    var body: some View {
        Button("", action: action)
            .buttonStyle(PassthroughButtonStyle(content: content))
    }
}

extension View {
    func buttonWrap(action: @escaping () -> Void) -> some View {
        ButtonWrap(action: action) {
            self
        }
    }
}
