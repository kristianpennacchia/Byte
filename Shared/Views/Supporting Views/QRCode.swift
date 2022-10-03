//
//  QRCode.swift
//  Byte
//
//  Created by Kristian Pennacchia on 28/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCode: View {
    let value: String
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Image(uiImage: generateQRCode(from: value))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
}

private extension QRCode {
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

struct QRCode_Previews: PreviewProvider {
    static var previews: some View {
        QRCode(value: "www.apple.com")
    }
}
