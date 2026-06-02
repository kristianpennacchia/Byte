//
//  StreamControlsOverlay.swift
//  Byte
//
//  Created by Kristian Pennacchia on 21/5/2026.
//  Copyright © 2026 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct StreamControlsOverlay: View {
	private enum Control: Hashable {
		case addStream
		case toggleVideo
		case toggleFlip
		case removeStream
		case changeQuality
	}

	let stream: any Streamable
	let selectedQuality: StreamQuality?
	let streamQualities: [StreamQuality]
	let isAudioOnly: Bool
	let isFlipped: Bool
	let addStream: () -> Void
	let toggleVideo: () -> Void
	let toggleFlip: () -> Void
	let removeStream: () -> Void
	let changeQuality: (_ newQuality: StreamQuality) -> Void
	let dismiss: () -> Void

	@Environment(\.resetFocus) private var resetFocus
	@FocusState private var focusedControl: Control?
	@Namespace private var controlsFocusNamespace

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .bottom, spacing: 28) {
				VStack(alignment: .leading, spacing: 8) {
					Text(stream.displayName)
						.font(.system(size: 34, weight: .bold))
						.lineLimit(1)

					Text(stream.title)
						.font(.system(size: 21, weight: .semibold))
						.lineLimit(1)
				}

				Spacer(minLength: 24)

				HStack(spacing: 18) {
					iconButton(
						systemImage: isAudioOnly ? "eye" : "eye.slash",
						control: .toggleVideo,
						action: toggleVideo
					)
					iconButton(
						systemImage: isFlipped ? "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right.fill" : "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right",
						control: .toggleFlip,
						action: toggleFlip
					)
					iconButton(
						systemImage: "stop",
						control: .removeStream,
						action: removeStream
					)
				}
			}

			Capsule()
				.fill(.white.opacity(0.32))
				.frame(height: 6)

			HStack(alignment: .center, spacing: 16) {
				metadataLabel(stream.duration, systemImage: "dot.radiowaves.left.and.right")
				if streamQualities.isEmpty == false {
					let quality = selectedQuality ?? streamQualities.first!
					contextButton(quality.label, systemImage: "display", control: .changeQuality) {
						ForEach(streamQualities, id: \.id) { quality in
							Button(quality.label) {
								changeQuality(quality)
							}
						}
					}
				}

				Spacer(minLength: 24)

				pillButton(
					title: "Add Stream",
					control: .addStream,
					action: addStream
				)
			}
		}
		.padding(.horizontal, 58)
		.padding(.top, 112)
		.padding(.bottom, 48)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
		.foregroundStyle(.white)
		.background(alignment: .bottom) {
			LinearGradient(
				stops: [
					.init(color: .clear, location: 0),
					.init(color: .black.opacity(0.16), location: 0.32),
					.init(color: .black.opacity(0.62), location: 0.68),
					.init(color: .black.opacity(0.84), location: 1)
				],
				startPoint: .top,
				endPoint: .bottom
			)
		}
		.focusScope(controlsFocusNamespace)
		.focusSection()
		.onMoveCommand(perform: moveFocus)
		.onExitCommand(perform: dismiss)
		.onAppear {
			DispatchQueue.main.async {
				focusedControl = .addStream
				resetFocus(in: controlsFocusNamespace)
			}
		}
	}

	private func metadataLabel(_ title: String, systemImage: String) -> some View {
		Label(title, systemImage: systemImage)
			.font(.system(size: 18, weight: .semibold))
			.foregroundStyle(.white.opacity(0.74))
	}

	private func contextButton<MenuItems>(_ title: String, systemImage: String, control: Control, @ViewBuilder menuItems: () -> MenuItems) -> some View where MenuItems : View {
		Menu {
			menuItems()
		} label: {
			Label(title, systemImage: systemImage)
				.font(.system(size: 18, weight: .semibold))
				.foregroundStyle(focusedControl == control ? .black : .white)
		}
		.focused($focusedControl, equals: control)
		.prefersDefaultFocus(control == .addStream, in: controlsFocusNamespace)
	}

	private func pillButton(title: String, control: Control, action: @escaping () -> Void) -> some View {
		Text(title)
			.font(.system(size: 18, weight: .semibold))
			.lineLimit(1)
			.padding(.horizontal, 24)
			.frame(height: 48)
			.contentShape(Capsule())
			.focusEffectDisabled()
			.focusable(true, interactions: .activate)
			.focused($focusedControl, equals: control)
			.prefersDefaultFocus(control == .addStream, in: controlsFocusNamespace)
			.foregroundStyle(focusedControl == control ? .black : .white)
			.background {
				Capsule()
					.fill(focusedControl == control ? .white : .white.opacity(0.14))
			}
			.scaleEffect(focusedControl == control ? 1.06 : 1)
			.shadow(color: .black.opacity(focusedControl == control ? 0.34 : 0), radius: 18, y: 8)
			.animation(.easeInOut(duration: 0.14), value: focusedControl)
			.overlayControlAction(action)
			.onExitCommand(perform: dismiss)
	}

	private func iconButton(systemImage: String, control: Control, action: @escaping () -> Void) -> some View {
		Image(systemName: systemImage)
			.font(.system(size: 25, weight: .semibold))
			.frame(width: 62, height: 62)
			.contentShape(Circle())
			.focusEffectDisabled()
			.focusable(true, interactions: .activate)
			.focused($focusedControl, equals: control)
			.prefersDefaultFocus(control == .addStream, in: controlsFocusNamespace)
			.foregroundStyle(iconForeground(for: control))
			.background {
				Circle()
					.fill(iconBackground(for: control))
			}
			.scaleEffect(focusedControl == control ? 1.12 : 1)
			.shadow(color: .black.opacity(focusedControl == control ? 0.4 : 0.22), radius: focusedControl == control ? 18 : 8, y: 8)
			.animation(.easeInOut(duration: 0.14), value: focusedControl)
			.overlayControlAction(action)
			.onExitCommand(perform: dismiss)
	}

	private func iconBackground(for control: Control) -> Color {
		if focusedControl == control {
			return control == .removeStream ? .red.opacity(0.92) : .white.opacity(0.96)
		}
		return .white.opacity(0.18)
	}

	private func iconForeground(for control: Control) -> Color {
		if focusedControl == control {
			return control == .removeStream ? .white : .black
		}
		return .white
	}

	private func moveFocus(_ direction: MoveCommandDirection) {
		let target: Control?

		switch direction {
		case .up:
			if focusedControl == .addStream {
				target = .toggleVideo
			} else {
				target = nil
			}
		case .down:
			if focusedControl != .addStream {
				target = .addStream
			} else {
				target = nil
			}
		case .left, .right:
			target = nil
		@unknown default:
			target = nil
		}

		if let target {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
				focusedControl = target
			}
		}
	}
}

private extension View {
	func overlayControlAction(_ action: @escaping () -> Void) -> some View {
		simultaneousGesture(TapGesture().onEnded(action))
			.accessibilityAction {
				action()
			}
			.accessibilityAddTraits(.isButton)
	}
}
