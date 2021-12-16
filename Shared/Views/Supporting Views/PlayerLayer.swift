//
//  AVPlayerLayerView.swift
//  Byte
//
//  Created by Kristian Pennacchia on 16/12/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import SwiftUI
import AVFoundation

struct PlayerLayer: UIViewRepresentable {
    let player: AVPlayer?
    let videoGravity: AVLayerVideoGravity

    func makeUIView(context: UIViewRepresentableContext<Self>) -> AVPlayerLayerView {
        AVPlayerLayerView()
    }

    func updateUIView(_ uiView: AVPlayerLayerView, context: UIViewRepresentableContext<Self>) {
        uiView.player = player
        uiView.playerLayer.videoGravity = videoGravity
    }
}

class AVPlayerLayerView: UIView {
    // Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    // The associated player object.
    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct PlayerLayer_Previews: PreviewProvider {
    static var previews: some View {
        PlayerLayer(player: nil, videoGravity: .resizeAspect)
    }
}




