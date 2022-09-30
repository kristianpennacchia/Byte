//
//  OAuthView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 28/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct OAuthView: View {
    private class ViewModel: ObservableObject {
        @Published var isRetrievingOAuth = false
        @Published var authError: Error?
    }

    @EnvironmentObject private var sessionStore: SessionStore

    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel = ViewModel()

    @State private var oAuth: YoutubeOAuth?
    @State private var showAuthError = false
    @State private var heartbeatChanged = false

    private let heartbeatTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        if oAuth == nil, viewModel.isRetrievingOAuth == false {
            viewModel.isRetrievingOAuth = true
            sessionStore.signInYoutube { result in
                switch result {
                case .success(let data):
                    oAuth = data
                    viewModel.isRetrievingOAuth = false
                case .failure(_):
                    dismiss()
                }
            } completion: { error in
                if let error = error {
                    showAuthError = true
                    viewModel.authError = error
                } else {
                    dismiss()
                }
            }
        }

        return ZStack {
            Color.black.ignoresSafeArea()
            if let oAuth {
                HStack(alignment: .top) {
                    Spacer()
                    VStack {
                        QRCode(value: oAuth.verificationUrl)
                            .frame(width: 400, height: 400)
                        Text("Can't scan the QRCode? Go to")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                        Text(oAuth.verificationUrl)
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
                        Text("Sign in to Youtube by scanning the QRCode with your phones camera.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .frame(width: 500)
                            .padding(.top)
                        Text(oAuth.userCode)
                            .font(.system(size: 100))
                            .monospacedDigit()
                            .padding(.top)
                    }
                    Spacer()
                }
            } else {
                ZStack {
                    Circle()
                        .frame(width: 200, height: 200)
                        .foregroundColor(heartbeatChanged ? .white.opacity(0.8) : .brand.youtube)
                        .animation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3))
                    Image(systemName: "heart.fill")
                        .foregroundColor(heartbeatChanged ? .brand.youtube : .white)
                        .font(.system(size: 100))
                        .scaleEffect(heartbeatChanged ? 1.0 : 0.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3))
                }
                .animation(.default)
                .onReceive(heartbeatTimer) { _ in
                    heartbeatChanged.toggle()
                }
            }
        }
        .alert(isPresented: $showAuthError) {
            Alert(title: Text("Unable To Sign In"), message: Text(viewModel.authError?.localizedDescription ?? ""))
        }
    }
}

struct OAuthView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthView()
    }
}
