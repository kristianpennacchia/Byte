//
//  OnSelect.swift
//  Byte
//
//  Created by Kristian Pennacchia on 25/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

extension View {
    func onSelect(perform: @escaping () -> Void) -> some View {
        modifier(OnSelect(perform: perform))
    }
}
