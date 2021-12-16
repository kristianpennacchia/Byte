//
//  WatermarkedContainer.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct WatermarkedContainer<Content>: View where Content: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
}

struct WatermarkedContainer_Previews: PreviewProvider {
    static var previews: some View {
        WatermarkedContainer {
            Text("Some text for testing")
        }
    }
}
