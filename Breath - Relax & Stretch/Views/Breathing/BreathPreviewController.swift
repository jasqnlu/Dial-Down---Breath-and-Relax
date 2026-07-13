import Foundation
import Combine

// MARK: - BreathPreviewController

/// Drives ONE silent demo cycle of a breathing pattern's phase sequence so the
/// idle breathing circle can preview the rhythm. No session record, no haptics,
/// no VoiceCueService — purely visual state that BreathingView observes.
@MainActor
final class BreathPreviewController: ObservableObject {

    enum State: Equatable {
        case idle
        case playing(BreathPhase)
    }

    @Published private(set) var state: State = .idle

    /// Speed multiplier so tests run in milliseconds (1.0 in the app).
    private let timeScale: Double
    private var playbackTask: Task<Void, Never>?

    init(timeScale: Double = 1.0) {
        self.timeScale = timeScale
    }

    /// Idle → play one cycle; playing → cancel back to idle.
    func toggle(pattern: BreathingPattern) {
        if case .playing = state {
            cancel()
        } else {
            play(pattern: pattern)
        }
    }

    func cancel() {
        playbackTask?.cancel()
        playbackTask = nil
        if state != .idle {
            state = .idle
        }
    }

    // MARK: - Private

    private func play(pattern: BreathingPattern) {
        let p = pattern.phases

        // One cycle: inhale → hold → exhale → hold2, skipping zero-length phases.
        let steps: [(phase: BreathPhase, seconds: Int)] = [
            (.inhale, p.inhale),
            (.hold,   p.hold),
            (.exhale, p.exhale),
            (.hold2,  p.hold2),
        ].filter { $0.1 > 0 }

        guard let first = steps.first else { return }

        // Publish the first phase synchronously so the tap feels instant.
        state = .playing(first.phase)

        playbackTask = Task { [weak self, timeScale] in
            for (index, step) in steps.enumerated() {
                if Task.isCancelled { return }
                if index > 0 {
                    self?.state = .playing(step.phase)
                }
                try? await Task.sleep(for: .seconds(Double(step.seconds) * timeScale))
            }
            if Task.isCancelled { return }
            self?.state = .idle
            self?.playbackTask = nil
        }
    }
}
