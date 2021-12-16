//
//  PlayerViewController.swift
//  Byte
//
//  Created by Kristian Pennacchia on 19/9/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import AVKit
import SwiftUI

class PlayerViewController: AVPlayerViewController {
    @AppStorage("lastSelectedQuality") private var lastSelectedQuality: String?
    @AppStorage("lastSelectedBandwidth") private var lastSelectedBandwidth: Int?

    private var currentMeta: M3U8.Meta?

    var playlist: M3U8? {
        didSet {
            // Default to the stream quality with the closest matching bandwidth to the last used
            guard let playlist = playlist, playlist.meta.isEmpty == false else {
                removeStream()
                return
            }

            let meta: M3U8.Meta
            let rememberQualityChoice: Bool
            if let lastSelectedQuality = lastSelectedQuality, let match = playlist.meta.first(where: { $0.name == lastSelectedQuality }) {
                meta = match
                rememberQualityChoice = true
                // Let's not fallback to bandwidth since the user never explictly chooses
                // bandwidth, only resolution/framerate. Better to just fallback to Source quality
//            } else if let lastSelectedBandwidth = lastSelectedBandwidth {
//                meta = playlist.meta.closest(lastSelectedBandwidth, keyPath: \.bandwidth)!
//                rememberQualityChoice = false
            } else {
                meta = playlist.meta.sorted(by: >).first!
                rememberQualityChoice = false
            }

            play(meta: meta, rememberQualityChoice: rememberQualityChoice)
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        player = AVPlayer()
        player?.automaticallyWaitsToMinimizeStalling = true
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
        requiresLinearPlayback = true

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(singleTap)))
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPress)))
    }

    deinit {
        removeStream()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: true, completion: completion)

        if isBeingDismissed {
            removeStream()
        }
    }
}

private extension PlayerViewController {
    func play(meta: M3U8.Meta, rememberQualityChoice: Bool) {
        guard let url = URL(string: meta.url) else {
            removeStream()
            return
        }

        currentMeta = meta

        if rememberQualityChoice {
            lastSelectedQuality = meta.name
            lastSelectedBandwidth = meta.bandwidth
        }

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 0.5
        item.automaticallyPreservesTimeOffsetFromLive = true
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = false
//        item.preferredPeakBitRate = 15000000    // 15Mbps

        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: item)

        player?.replaceCurrentItem(with: item)
        player?.playImmediately(atRate: 1.0)
    }

    func removeStream() {
        NotificationCenter.default.removeObserver(self)
        currentMeta = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }

    @objc func playbackDidEnd() {
        removeStream()
        dismiss(animated: true, completion: nil)
    }

    @objc func singleTap(_ gesture: UILongPressGestureRecognizer) {
        guard let playlist = playlist else { return }

        let alert = UIAlertController(title: "Video Quality", message: nil, preferredStyle: .actionSheet)
        playlist.meta.map { meta in
            let current = "\(currentMeta == meta ? "★" : "")"
            return UIAlertAction(title: "\(meta.name ?? "Unknown") \(current)", style: .default) { [weak self] _ in
                self?.play(meta: meta, rememberQualityChoice: true)
            }
        }.forEach(alert.addAction)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        guard let meta = currentMeta ?? playlist?.meta.sorted(by: >).first else { return }

        play(meta: meta, rememberQualityChoice: false)
    }
}
