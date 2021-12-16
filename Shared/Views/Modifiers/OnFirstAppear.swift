//
//  OnFirstAppear.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct OnFirstAppear: ViewModifier {
    @State private var hasAppeared = false

    let perform: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            guard self.hasAppeared == false else { return }
            self.hasAppeared = true

            self.perform()
        }
    }
}

extension View {
    func onFirstAppear(perform: @escaping () -> Void) -> some View {
        modifier(OnFirstAppear(perform: perform))
    }
}
