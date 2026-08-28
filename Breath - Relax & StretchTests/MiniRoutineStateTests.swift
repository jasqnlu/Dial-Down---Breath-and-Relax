import Testing
@testable import BreathRelaxStretch

struct MiniRoutineStateTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name, type: .stretch, targetBodyParts: ["Lower Back"], durationSeconds: duration,
            difficulty: 1, instructions: [], cueStyle: .hold
        )
    }

    @Test func startsEmpty() {
        #expect(MiniRoutineState().exercises.isEmpty)
    }

    @Test func toggleAddsThenRemoves() {
        let state = MiniRoutineState()
        let exercise = makeExercise(name: "Shoulder Roll", duration: 30)
        state.toggle(exercise)
        #expect(state.contains(exercise) == true)
        #expect(state.exercises.count == 1)
        state.toggle(exercise)
        #expect(state.contains(exercise) == false)
        #expect(state.exercises.isEmpty)
    }

    @Test func totalSecondsSumsAddedExercises() {
        let state = MiniRoutineState()
        state.toggle(makeExercise(name: "A", duration: 30))
        state.toggle(makeExercise(name: "B", duration: 45))
        #expect(state.totalSeconds == 75)
    }

    @Test func containsIsFalseForAnUnaddedExercise() {
        let state = MiniRoutineState()
        state.toggle(makeExercise(name: "A", duration: 30))
        #expect(state.contains(makeExercise(name: "B", duration: 45)) == false)
    }
}
