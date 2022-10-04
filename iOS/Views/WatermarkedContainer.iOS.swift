//
//  WatermarkedContainer.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

extension WatermarkedContainer {
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 0) {
                    ZStack {
                        Logo(style: .black)
                            .padding(.top, geometry.safeAreaInsets.top)
                            .padding([.top, .bottom])
                    }
                    .frame(width: geometry.size.width)
                    .background(Color.brand.brand)
                    self.content()
                }
                .edgesIgnoringSafeArea(.top)
                .frame(maxWidth: .infinity)
                .padding(0)
            }
            .navigationBarHidden(true)
        }
    }
}
