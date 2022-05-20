//
//  AppFactory.swift
//  Byte
//
//  Created by Kristian Pennacchia on 3/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

enum AppFactory {
    static func makeContent() -> some View {
        return ContentView()
            .environmentObject(SessionStore(api: .shared))
            .environmentObject(API.shared)
            .environmentObject(SpoilerFilter())
    }
}
