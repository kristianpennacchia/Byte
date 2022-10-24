//
//  HeartbeatActivityIndicator.swift
//  Byte
//
//  Created by Kristian Pennacchia on 1/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct HeartbeatActivityIndicator: View {
    @State private var heartbeatChanged = false

    private let heartbeatTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle()
                .frame(width: 200, height: 200)
                .foregroundColor(heartbeatChanged ? .brand.tertiary.opacity(0.8) : .brand.brand)
                .animation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3))
//            Image(systemName: "heart.fill")
            Image("LogoShort")
                .foregroundColor(heartbeatChanged ? .brand.brand : .brand.tertiary)
                .font(.system(size: 100))
                .scaleEffect(heartbeatChanged ? 1.5 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3))
        }
        .animation(.default)
        .onFirstAppear {
            heartbeatChanged.toggle()
        }
        .onReceive(heartbeatTimer) { _ in
            heartbeatChanged.toggle()
        }
    }
}

struct HeartbeatActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        HeartbeatActivityIndicator()
    }
}
