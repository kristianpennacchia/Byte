//
//  SwiftUIView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 18/6/20.
//  Copyright © 2020 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    typealias UIView = UIActivityIndicatorView

    var isAnimating: Bool
    var configuration: (_ indicator: UIView) -> Void = { _ in }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}

extension View where Self == ActivityIndicator {
    func configure(_ configuration: @escaping (Self.UIView)->Void) -> Self {
        Self.init(isAnimating: self.isAnimating, configuration: configuration)
    }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator(isAnimating: true)
    }
}
