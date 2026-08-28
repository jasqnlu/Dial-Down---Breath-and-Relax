import Foundation

/// Pure resolution of "which phase, how many seconds remain in it" from
/// elapsed time — no SwiftUI, no Date, no timers. SessionPlayerView calls
/// `resolve` once per second (piggybacking its existing 1Hz tick) rather
/// than running a separate sleep-based task per phase; because this derives
/// from wall-clock elapsed time rather than accumulated sleep(), it self-
/// corrects for free after the app backgrounds/foregrounds or the session
/// pauses/resumes — no special-case handling needed by the caller.
enum BreathPhaseCycle {
    struct Resolved: Equatable {
        let phaseIndex: Int
        let secondsRemainingInPhase: Int
    }

    static func resolve(pattern: [BreathPhaseStep], elapsedSeconds: Int) -> Resolved? {
        guard !pattern.isEmpty else { return nil }
        let cycleLength = pattern.reduce(0) { $0 + $1.seconds }
        guard cycleLength > 0 else { return nil }

        var offset = elapsedSeconds % cycleLength
        for (index, phase) in pattern.enumerated() {
            guard phase.seconds > 0 else { continue }
            if offset < phase.seconds {
                return Resolved(phaseIndex: index, secondsRemainingInPhase: phase.seconds - offset)
            }
            offset -= phase.seconds
        }
        // Elapsed lands exactly on a cycle boundary (offset == 0 after the
        // loop exhausts every phase) — that's the start of phase 0 again.
        guard let first = pattern.first(where: { $0.seconds > 0 }),
              let firstIndex = pattern.firstIndex(where: { $0.seconds > 0 }) else { return nil }
        return Resolved(phaseIndex: firstIndex, secondsRemainingInPhase: first.seconds)
    }
}
