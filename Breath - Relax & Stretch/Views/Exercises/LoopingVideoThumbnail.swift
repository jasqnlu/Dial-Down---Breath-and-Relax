import SwiftUI
import AVFoundation
import UIKit

/// Lightweight looping, muted video thumbnail for list rows — backed by a bare
/// `AVPlayerLayer` (no `VideoPlayer` transport chrome) and torn down when the
/// row scrolls off screen, so a scrolling list can show many loops cheaply.
/// Fills its frame (center-cropped). Honors Reduce Motion by holding frame one.
struct LoopingVideoThumbnail: UIViewRepresentable {
    let url: URL
    var reduceMotion: Bool

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.configure(url: url, reduceMotion: reduceMotion)
        return view
    }

    func updateUIView(_ uiView: PlayerLayerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerLayerView, coordinator: ()) {
        uiView.teardown()
    }

    final class PlayerLayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?   // gap-free loop; retained to keep looping

        func configure(url: URL, reduceMotion: Bool) {
            let item = AVPlayerItem(url: url)
            let queue = AVQueuePlayer(playerItem: item)
            queue.isMuted = true
            playerLayer.player = queue
            playerLayer.videoGravity = .resizeAspectFill
            if reduceMotion {
                queue.pause()                 // static first frame
            } else {
                looper = AVPlayerLooper(player: queue, templateItem: item)
                queue.play()
            }
            player = queue
        }

        func teardown() {
            player?.pause()
            looper = nil
            player = nil
            playerLayer.player = nil
        }
    }
}
