//
//  VisualEffectView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 18/7/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct VisualEffectView_Previews: PreviewProvider {
    static var previews: some View {
        VisualEffectView(effect: UIBlurEffect(style: .regular))
    }
}
