//
//  OAuthView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 28/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct OAuthView: View {
	@MainActor
    private class ViewModel: ObservableObject {
        @Published var authError: Error?
    }

	enum Service {
		case twitch, youtube

		var title: String {
			switch self {
			case .twitch:
				return "Twitch"
			case .youtube:
				return "YouTube"
			}
		}

		var instructions: String {
			switch self {
			case .twitch:
				return "Sign in to Twitch by scanning the QRCode with your phones camera."
			case .youtube:
				return "Sign in to Youtube by scanning the QRCode with your phones camera."
			}
		}
	}

    @EnvironmentObject private var sessionStore: SessionStore

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ViewModel()

    @State private var oAuth: OAuthable?
    @State private var showAuthError = false

	let service: Service

    var body: some View {
        ZStack {
			switch service {
			case .twitch:
				Color.brand.twitch.ignoresSafeArea()
			case .youtube:
				Color.brand.youtube.ignoresSafeArea()
			}
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
						Text(service.title)
                            .font(.largeTitle)
                            .padding(.top, 32)
						Text(service.instructions)
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
                HeartbeatActivityIndicator()
            }
        }
        .onAppear {
			switch service {
			case .twitch:
				sessionStore.startTwitchOAuth { result in
					switch result {
					case .success(let data):
						oAuth = data
					case .failure(let error):
						viewModel.authError = error
						showAuthError = true
					}
				} completion: { result in
					switch result {
					case .success(_):
						dismiss()
					case .failure(let error):
						viewModel.authError = error
						showAuthError = true
					}
				}
			case .youtube:
				sessionStore.startYoutubeOAuth { result in
					switch result {
					case .success(let data):
						oAuth = data
					case .failure(let error):
						viewModel.authError = error
						showAuthError = true
					}
				} completion: { result in
					switch result {
					case .success(_):
						dismiss()
					case .failure(let error):
						viewModel.authError = error
						showAuthError = true
					}
				}
			}
        }
        .alert("Unable To Sign In", isPresented: $showAuthError) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(viewModel.authError?.localizedDescription ?? "")
        }
    }
}

struct OAuthView_Previews: PreviewProvider {
    static var previews: some View {
		OAuthView(service: .twitch)
    }
}
