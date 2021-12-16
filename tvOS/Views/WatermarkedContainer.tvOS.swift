//
//  WatermarkedContainer.tvOS.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

extension WatermarkedContainer {
    var body: some View {
        ZStack {
            content()
            Logo(style: .black)
                .position(x: 20, y: 50)
        }
    }
}
