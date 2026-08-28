import Testing
@testable import BreathRelaxStretch

@Suite struct CustomizeRoutineExerciseMergeTests {
    private func makeExercise(name: String) -> Exercise {
        Exercise(
            name: name, type: .stretch,
            targetBodyParts: ["Lower Back"], durationSeconds: 60,
            difficulty: 1, instructions: [], cueStyle: .hold
        )
    }

    @Test func appendsNewExercisesToBase() {
        let boxBreathing = makeExercise(name: "Box Breathing")
        let neckRoll = makeExercise(name: "Neck Roll")

        let merged = CustomizeRoutineExerciseMerge.appending([neckRoll], to: [boxBreathing])

        #expect(merged.map(\.uuid) == [boxBreathing.uuid, neckRoll.uuid])
    }

    @Test func skipsDuplicatesAlreadyInBaseByUUID() {
        let boxBreathing = makeExercise(name: "Box Breathing")

        let merged = CustomizeRoutineExerciseMerge.appending([boxBreathing], to: [boxBreathing])

        #expect(merged.map(\.uuid) == [boxBreathing.uuid])
    }

    @Test func preservesBaseOrderThenAppendsInPickedOrder() {
        let boxBreathing = makeExercise(name: "Box Breathing")
        let catCow = makeExercise(name: "Cat-Cow Flow")
        let neckRoll = makeExercise(name: "Neck Roll")
        let shoulderShrug = makeExercise(name: "Shoulder Shrug")

        let merged = CustomizeRoutineExerciseMerge.appending([shoulderShrug, neckRoll], to: [boxBreathing, catCow])

        #expect(merged.map(\.uuid) == [boxBreathing.uuid, catCow.uuid, shoulderShrug.uuid, neckRoll.uuid])
    }
}
