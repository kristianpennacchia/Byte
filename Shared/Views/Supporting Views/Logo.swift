//
//  Logo.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import UIKit

struct Logo: View {
    enum Style {
        case purple, white, black

        var image: UIImage {
            switch self {
            case .purple:
                return #imageLiteral(resourceName: "LogoPurple")
            case .white:
                return #imageLiteral(resourceName: "LogoWhite")
            case .black:
                return #imageLiteral(resourceName: "LogoBlack")
            }
        }
    }

    let style: Style

    var body: some View {
        Image(uiImage: style.image)
            .resizable()
            .scaledToFit()
            .frame(height: LogoSize.medium.height)
    }
}

struct Logo_Previews: PreviewProvider {
    static var previews: some View {
        Logo(style: .purple)
    }
}
