import Foundation

/// One phase of a breathing pattern — e.g. {"Inhale", 4} — authored per
/// exercise on `Exercise.breathPattern`. See BreathPhaseCycle for how a
/// sequence of these is resolved against elapsed time during a live session.
struct BreathPhaseStep: Codable, Equatable {
    let label: String
    let seconds: Int
}
