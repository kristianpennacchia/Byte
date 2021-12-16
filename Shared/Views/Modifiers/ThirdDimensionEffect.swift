//
//  ThirdDimensionEffect.swift
//  Byte
//
//  Created by Kristian Pennacchia on 2/10/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import SwiftUI

struct ThirdDimensionEffectView<Content: View>: View {
    let isExtended: Bool
    let restingDepth: CGFloat
    let extendedDepth: CGFloat
    let foregroundColor: Color
    let edgeColor: Color
    let content: Content

    init(isExtended: Bool, restingDepth: CGFloat, extendedDepth: CGFloat, foregroundColor: Color, edgeColor: Color, @ViewBuilder builder: () -> Content) {
        self.isExtended = isExtended
        self.restingDepth = restingDepth
        self.extendedDepth = extendedDepth
        self.foregroundColor = foregroundColor
        self.edgeColor = edgeColor
        self.content = builder()
    }

    var body: some View {
        let facePoint = isExtended ? CGPoint(x: extendedDepth, y: -extendedDepth)
                                   : CGPoint(x: restingDepth, y: -restingDepth)
        return content
            .hidden()
            .overlay(
                GeometryReader { geometry in
                    // Fill the space between the base of the view and the 3D moving 'face'
                    Path { path in
                        path.addLines([
                            facePoint,
                            CGPoint(x: facePoint.x, y: geometry.size.height + facePoint.y),
                            CGPoint(x: geometry.size.width + facePoint.x, y: geometry.size.height + facePoint.y),
                            CGPoint(x: geometry.size.width, y: geometry.size.height),
                            CGPoint(x: 0, y: geometry.size.height),
                            .zero
                        ])
                    }
                    .fill(edgeColor)

                    // Draw the 'face' that will move when toggling 3D
                    Path { path in
                        path.addRect(CGRect(origin: facePoint, size: geometry.size))
                    }
                    .fill(self.foregroundColor)

                    self.content.transformEffect(CGAffineTransform(translationX: facePoint.x, y: facePoint.y))
                }
            )
    }
}

extension View {
    func thirdDimensionEffect(isExtended: Bool, restingDepth: CGFloat = 0, extendedDepth: CGFloat = 6, foregroundColor: Color = .clear, edgeColor: Color? = nil) -> some View {
        let edgeColor = edgeColor ?? [
            Color.red,
            Color.blue,
            Color.purple,
            Color.green,
            Color.orange,
        ].randomElement()!

        return ThirdDimensionEffectView(isExtended: isExtended, restingDepth: restingDepth, extendedDepth: extendedDepth, foregroundColor: foregroundColor, edgeColor: edgeColor) {
            self
        }
    }
}
