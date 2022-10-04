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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center) {
                Text(title)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            }
        }
    }
}

struct MenuItemButton_Previews: PreviewProvider {
    static var previews: some View {
        MenuItemButton(title: "Test") {}
    }
}
