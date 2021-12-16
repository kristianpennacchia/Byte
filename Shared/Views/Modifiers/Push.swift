//
//  Push.swift
//  Byte
//
//  Created by Kristian Pennacchia on 25/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

extension View {
    func push<Destination: View>(_ destination: Destination) -> some View {
        modifier(Push(destination: destination))
    }

    func push<Destination: View>(_ destination: () -> Destination) -> some View {
        modifier(Push(destination: destination()))
    }
}
