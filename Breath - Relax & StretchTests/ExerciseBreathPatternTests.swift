import Testing
import Foundation
@testable import BreathRelaxStretch

struct ExerciseBreathPatternTests {
    private func makeExercise() -> Exercise {
        Exercise(name: "X", type: .breath, targetBodyParts: [],
                 durationSeconds: 60, difficulty: 1, instructions: [])
    }

    @Test func defaultsToEmptyPattern() {
        #expect(makeExercise().breathPattern.isEmpty)
    }

    @Test func roundTripsThroughSetterAndGetter() {
        let e = makeExercise()
        let pattern = [BreathPhaseStep(label: "Inhale", seconds: 4), BreathPhaseStep(label: "Exhale", seconds: 6)]
        e.breathPattern = pattern
        #expect(e.breathPattern == pattern)
    }

    /// Mirrors `ExerciseCueStyleTests.cueStyleFallsBackToHoldForUnparseableRawStorage`:
    /// garbage raw storage (e.g. a pre-migration or corrupted row) must never
    /// crash the getter — it decodes to an empty pattern instead.
    @Test func fallsBackToEmptyForUnparseableRawStorage() {
        let e = makeExercise()
        e.breathPatternData = Data("not valid json".utf8)
        #expect(e.breathPattern.isEmpty)
    }
}
