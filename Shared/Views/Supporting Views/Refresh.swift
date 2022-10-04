//
//  Refresh.swift
//  Byte
//
//  Created by Kristian Pennacchia on 25/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct Refresh: View {
    @Binding var isAnimating: Bool

    let action: () -> Void

    var body: some View {
        return Button(action: action) {
            HStack {
                Spacer()
                    .frame(width: 430)

                Image(systemName: "arrow.2.circlepath.circle")
                    .rotationEffect(Angle(degrees: .pi))
                    .animation(
                        .linear(duration: 0.25)
                            .repeatForever(),
                        value: isAnimating
                    )

                Spacer()
                    .frame(width: 430)
            }
        }
        .background(Color.brand.brand.cornerRadius(10))
    }
}

//struct Refresh_Previews: PreviewProvider {
//    static var previews: some View {
//        Refresh(isAnimating: false) {}
//    }
//}
