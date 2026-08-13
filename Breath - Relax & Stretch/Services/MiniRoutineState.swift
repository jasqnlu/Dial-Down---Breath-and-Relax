import Foundation
import Combine

/// Ad hoc exercise selection for Body Map's "build a mini routine" flow —
/// no name, no save step, just a running list you can Start once you're
/// happy with it. Distinct from Routine (SwiftData, named, persisted):
/// this never touches the database, it only exists for the lifetime of one
/// Body Map screen.
final class MiniRoutineState: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []

    func toggle(_ exercise: Exercise) {
        if let index = exercises.firstIndex(where: { $0.uuid == exercise.uuid }) {
            exercises.remove(at: index)
        } else {
            exercises.append(exercise)
        }
    }

    func contains(_ exercise: Exercise) -> Bool {
        exercises.contains { $0.uuid == exercise.uuid }
    }

    var totalSeconds: Int {
        exercises.reduce(0) { $0 + $1.durationSeconds }
    }
}
