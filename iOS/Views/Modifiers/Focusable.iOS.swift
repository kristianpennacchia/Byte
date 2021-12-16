//
//  Focusable.iOS.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

/// Dummy modifier to allow easy code reuse with tvOS
struct Focusable: ViewModifier {
    let isFocusable: Bool
    let onFocusChange: (Bool) -> Void

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func focusable(_ isFocusable: Bool = true, onFocusChange: @escaping (Bool) -> Void = { _ in }) -> some View {
        modifier(Focusable(isFocusable: isFocusable, onFocusChange: onFocusChange))
    }
}
