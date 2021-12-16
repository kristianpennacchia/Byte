//
//  OnSelect.iOS.swift
//  Byte
//
//  Created by Kristian Pennacchia on 15/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct OnSelect: ViewModifier {
    let perform: () -> Void

    func body(content: Content) -> some View {
        content.onTapGesture {
            self.perform()
        }
    }
}
