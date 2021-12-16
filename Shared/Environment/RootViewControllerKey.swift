//
//  RootViewControllerKey.swift
//  Byte
//
//  Created by Kristian Pennacchia on 21/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct RootViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        return ViewControllerHolder(controller: UIApplication.shared.windows.first?.rootViewController)
    }
}

extension EnvironmentValues {
    var root: ViewControllerHolder {
        get { return self[RootViewControllerKey.self] }
        set { self[RootViewControllerKey.self] = newValue }
    }
}
