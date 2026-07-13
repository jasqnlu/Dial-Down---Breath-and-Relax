import Foundation

struct BreathingRunPlan: Equatable {
    let totalRounds: Int
    let recordsCompletion: Bool

    static func session(selectedRounds: Int) -> BreathingRunPlan {
        BreathingRunPlan(totalRounds: max(1, selectedRounds), recordsCompletion: true)
    }

    static func circlePreview(selectedRounds: Int) -> BreathingRunPlan {
        BreathingRunPlan(totalRounds: 1, recordsCompletion: false)
    }
}
