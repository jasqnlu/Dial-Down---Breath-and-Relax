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
    @State private var calloutTimeObserver: Any?
    /// Driven by `AnimationCallout.opacity(atLoopTime:)` on every periodic
    /// time-observer tick; pinned to 1 for Reduce Motion (see `start(url:)`).
    @State private var calloutOpacity: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            if let url = exercise.demoVideoURL {
                VideoPlayer(player: player)
                    // The generated animation is a standing portrait; filmed
                    // hero clips are landscape.
                    .aspectRatio(exercise.demoIsAnimation ? 4.0 / 5.0 : 16.0 / 9.0,
                                 contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel))
                    .padding(.horizontal)
                    .overlay(alignment: .topLeading) {
                        // Callouts are authored against the generated
                        // animation's timing/anchor — gated the same way as
                        // the legacy disclaimer below so one can never render
                        // over a filmed clip it wasn't positioned for.
                        if exercise.demoIsAnimation, let callout = exercise.animationCallout {
                            GeometryReader { proxy in
                                // Clamp inward from the raw anchor fraction so
                                // an anchor authored near an edge (e.g. a hand
                                // reaching off to one side) doesn't push the
                                // text pill past the frame — the arrow can sit
                                // right at the joint; the label just needs
                                // enough margin to stay legible.
                                let margin: CGFloat = 110
                                let x = min(max(callout.anchor.x * proxy.size.width, margin),
                                            max(margin, proxy.size.width - margin))
                                let y = min(max(callout.anchor.y * proxy.size.height, margin),
                                            max(margin, proxy.size.height - margin))
                                AnimationCalloutOverlay(callout: callout, opacity: calloutOpacity)
                                    .position(x: x, y: y)
                            }
                            // No extra padding here: `.overlay` already hands
                            // its content the exact frame of the view it's
                            // attached to (the video, post-padding/clipping
                            // above) — adding padding here would inset this
                            // reader further and throw off the anchor math.
                            .allowsHitTesting(false)
                        }
                    }
                    .onAppear { start(url: url) }
                    .onDisappear { stop() }

                // Resolution order: an authored callout replaces the generic
                // disclaimer entirely — no double messaging (see
                // Exercise.showsApproximateAnimationNote).
                if exercise.demoIsAnimation && exercise.showsApproximateAnimationNote {
                    AnimationAccuracyNote()
                }
            }
        }
    }

    private func start(url: URL) {
        guard player == nil else { return }
        let p = AVPlayer(url: url)
        p.isMuted = true
        if reduceMotion {
            // Reduce Motion: leave it paused on the first frame (a static poster).
            // A callout still needs to reach the user, so show it statically
            // (full opacity, no fade) rather than never appearing.
            p.pause()
            if exercise.animationCallout != nil {
                calloutOpacity = 1
            }
        } else {
            p.actionAtItemEnd = .none
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem, queue: .main) { _ in
                    p.seek(to: .zero); p.play()
                }
            if let callout = exercise.animationCallout {
                // Re-arms every loop for free: the observer above seeks the
                // player back to `.zero` on each end-of-item, so the time
                // this callback receives naturally restarts from 0 each loop.
                let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
                calloutTimeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                    calloutOpacity = callout.opacity(atLoopTime: time.seconds)
                }
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
        if let token = calloutTimeObserver {
            player?.removeTimeObserver(token)
        }
        player = nil
        loopObserver = nil
        calloutTimeObserver = nil
        calloutOpacity = 0
    }
}
