import SwiftUI
import AVKit

/// Hero media slot: looping local video when available. Missing media renders
/// nothing so exercise detail screens do not reserve a blank placeholder.
struct ExerciseMediaCard: View {
    let exercise: Exercise
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    var body: some View {
        Group {
            if let url = exercise.localVideoURL {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        guard player == nil else { return }
                        let p = AVPlayer(url: url)
                        p.isMuted = true
                        p.actionAtItemEnd = .none
                        let token = NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: p.currentItem, queue: .main) { _ in
                                p.seek(to: .zero); p.play()
                            }
                        loopObserver = token
                        p.play()
                        player = p
                    }
                    .onDisappear {
                        player?.pause()
                        if let token = loopObserver {
                            NotificationCenter.default.removeObserver(token)
                        }
                        player = nil
                        loopObserver = nil
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel))
        .padding(.horizontal)
    }
}
