//
//  TopViewControllerKey.swift
//  Byte
//
//  Created by Kristian Pennacchia on 21/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct PresenterViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        var top = UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController
        while let controller = top?.presentedViewController {
            top = controller
        }
        return ViewControllerHolder(controller: top)
    }
}

extension EnvironmentValues {
    var presenter: ViewControllerHolder {
        get { return self[PresenterViewControllerKey.self] }
        set { self[PresenterViewControllerKey.self] = newValue }
    }
}
