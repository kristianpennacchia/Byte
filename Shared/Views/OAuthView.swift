//
//  OAuthView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 28/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct OAuthView: View {
    var body: some View {
        ZStack {
            Color.brand.youtube.ignoresSafeArea()
            HStack(alignment: .top) {
                Spacer()
                VStack {
                    QRCode(value: "www.apple.com")
                        .frame(width: 400, height: 400)
                    Text("Can't scan the QRCode? Go to")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                    Text("www.apple.com")
                        .font(.body)
                        .bold()
                        .multilineTextAlignment(.center)
                    Text("on your phone.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                VStack {
                    Text("Youtube")
                        .font(.largeTitle)
                        .padding(.top, 32)
                    Text("Sign in to Youtube by scanning the QRCode with your phone.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .frame(width: 500)
                        .padding(.top)
                    Text("0A1B2C")
                        .font(.system(size: 100))
                        .monospacedDigit()
                        .padding(.top)
                }
                Spacer()
            }
        }
    }
}

struct OAuthView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthView()
    }
}
