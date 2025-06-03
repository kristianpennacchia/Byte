//
//  SignInView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    @Binding var isSigningIn: Bool

    var body: some View {
        VStack {
            if isSigningIn {
                HeartbeatActivityIndicator()
					.frame(alignment: .center)
            } else {
                Button(action: signIn) {
                    Text("Sign-In")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 50, leading: 100, bottom: 50, trailing: 100))
                }
                .background(Color.brand.primary)
            }
        }
    }

    private func signIn() {
        isSigningIn = true
        sessionStore.signInTwitch()
    }
}

//struct SignInView_Previews: PreviewProvider {
//    @State private var isSigningIn = false
//
//    static var previews: some View {
//        return SignInView(isSigningIn: $isSigningIn)
//    }
//}
