//
//  MenuActionButton.swift
//  Byte
//
//  Created by Kristian Pennacchia on 9/9/2025.
//  Copyright © 2025 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct MenuActionButton: View {
	let title: String
	let subtitle: String?
	let icon: String
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(alignment: .center, spacing: 0) {
				Image(systemName: icon)
					.aspectRatio(contentMode: .fit)
					.frame(width: 50)
				VStack(alignment: .leading, spacing: 8) {
					Text(title)
					if let subtitle {
						Text(subtitle)
							.font(.system(size: 20, weight: .medium))
					}
				}
				.padding(.leading, 16)
			}
		}
	}
}

struct MenuActionButton_Previews: PreviewProvider {
	static var previews: some View {
		MenuActionButton(title: "Test title", subtitle: "Test subtitle", icon: "person.2") {}
	}
}
