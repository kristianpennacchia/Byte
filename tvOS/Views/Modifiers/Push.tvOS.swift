//
//  Push.tvOS.swift
//  Byte
//
//  Created by Kristian Pennacchia on 21/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct Push<Destination: View>: ViewModifier {
    @State private var shouldPresent = false

    let destination: Destination

    func body(content: Content) -> some View {
        content
            .onSelect {
                self.shouldPresent.toggle()
            }
        .sheet(isPresented: $shouldPresent) {
            self.destination
        }
    }
}
