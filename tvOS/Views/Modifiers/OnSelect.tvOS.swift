//
//  OnSelect.tvOS.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct OnSelect: ViewModifier {
    let perform: () -> Void

    func body(content: Content) -> some View {
        content.onLongPressGesture(minimumDuration: 0.01, pressing: nil, perform: perform)
//        Tappable(perform: perform) {
//            content
//        }
    }
}

//private final class TapView: UIViewRepresentable {
//    typealias UIViewType = UIView
//
//    let perform: () -> Void
//
//    init(perform: @escaping () -> Void) {
//        self.perform = perform
//    }
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized)))
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {
//    }
//}
//
//private extension TapView {
//    @objc func tapGestureRecognized(_ gesture: UITapGestureRecognizer) {
//        perform()
//    }
//}
//
//private struct Tappable<Content>: View where Content : View {
//    let content: () -> Content
//    let perform: () -> Void
//
//    @inlinable public init(perform: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
//        self.perform = perform
//        self.content = content
//    }
//
//    var body: some View {
//        ZStack {
//            TapView(perform: perform)
//            content()
//        }
//    }
//}
