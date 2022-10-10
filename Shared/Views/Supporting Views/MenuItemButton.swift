//
//  MenuItemButton.swift
//  Byte
//
//  Created by Kristian Pennacchia on 4/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct MenuItemButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: icon)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50)
                Text(title)
                    .padding(.leading, 16)
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "arrow.clockwise" : "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            }
        }
    }
}

struct MenuItemButton_Previews: PreviewProvider {
    static var previews: some View {
        MenuItemButton(title: "Test", icon: "person.2", isSelected: true) {}
    }
}
