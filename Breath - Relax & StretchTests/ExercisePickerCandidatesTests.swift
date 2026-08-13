import Testing
@testable import BreathRelaxStretch

@Suite struct ExercisePickerCandidatesTests {
    private func makeExercise(name: String) -> Exercise {
        Exercise(
            name: name, type: .stretch,
            targetBodyParts: ["Lower Back"], durationSeconds: 60,
            difficulty: 1, instructions: [], cueStyle: .hold
        )
    }

    @Test func excludesAlreadyAddedExercisesByUUID() {
        let boxBreathing = makeExercise(name: "Box Breathing")
        let catCow = makeExercise(name: "Cat-Cow Flow")
        let neckRoll = makeExercise(name: "Neck Roll")
        let all = [boxBreathing, catCow, neckRoll]

        let available = ExercisePickerCandidates.available(from: all, excluding: [catCow])

        #expect(available.map(\.uuid) == [boxBreathing.uuid, neckRoll.uuid])
    }

    @Test func returnsAllWhenExcludingIsEmpty() {
        let all = [makeExercise(name: "Box Breathing"), makeExercise(name: "Cat-Cow Flow")]

        let available = ExercisePickerCandidates.available(from: all, excluding: [])

        #expect(available.map(\.uuid) == all.map(\.uuid))
    }

    @Test func returnsEmptyWhenEveryExerciseIsExcluded() {
        let boxBreathing = makeExercise(name: "Box Breathing")
        let catCow = makeExercise(name: "Cat-Cow Flow")
        let all = [boxBreathing, catCow]

        let available = ExercisePickerCandidates.available(from: all, excluding: all)

        #expect(available.isEmpty)
    }
}
