import SwiftUI
import AVKit

/// Hero media slot: the exercise's looping demo — a filmed clip when present,
/// otherwise the generated 3D muscle-animation loop. Missing media renders
/// nothing so exercise detail screens do not reserve a blank placeholder.
/// Honors Reduce Motion by showing a static first frame instead of looping.
struct ExerciseMediaCard: View {
    let exercise: Exercise
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    var body: some View {
        Group {
            if let url = exercise.demoVideoURL {
                VideoPlayer(player: player)
                    // The generated animation is a standing portrait; filmed
                    // hero clips are landscape.
                    .aspectRatio(exercise.demoIsAnimation ? 4.0 / 5.0 : 16.0 / 9.0,
                                 contentMode: .fit)
                    .onAppear { start(url: url) }
                    .onDisappear { stop() }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel))
        .padding(.horizontal)
    }

    private func start(url: URL) {
        guard player == nil else { return }
        let p = AVPlayer(url: url)
        p.isMuted = true
        if reduceMotion {
            // Reduce Motion: leave it paused on the first frame (a static poster).
            p.pause()
        } else {
            p.actionAtItemEnd = .none
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem, queue: .main) { _ in
                    p.seek(to: .zero); p.play()
                }
            p.play()
        }
        player = p
    }

    private func stop() {
        player?.pause()
        if let token = loopObserver {
            NotificationCenter.default.removeObserver(token)
        }
        player = nil
        loopObserver = nil
    }
}
