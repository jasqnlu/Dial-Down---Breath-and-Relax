import Testing
@testable import BreathRelaxStretch

struct ExerciseGraphGroupingTests {
    @Test func groupsExercisesBySpecificBodyPartWithinCategory() {
        let exercises = [
            makeExercise(name: "Left quad opener", targetBodyParts: ["Left Quadriceps"], difficulty: 1),
            makeExercise(name: "Right quad opener", targetBodyParts: ["Right Quadriceps"], difficulty: 1),
            makeExercise(name: "Calf stretch", targetBodyParts: ["Left Calves"], difficulty: 2)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .legs)

        #expect(groups.map(\.title).contains("Quadriceps"))
        #expect(groups.map(\.title).contains("Calves"))
        #expect(groups.first { $0.title == "Quadriceps" }?.exercises.count == 2)
    }

    @Test func fallsBackToDifficultyWhenBodyPartDoesNotMatchCategory() {
        let exercises = [
            makeExercise(name: "Starter stretch", targetBodyParts: [], difficulty: 1),
            makeExercise(name: "Deep stretch", targetBodyParts: [], difficulty: 3)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .legs)

        #expect(groups.map(\.title).contains("Beginner"))
        #expect(groups.map(\.title).contains("Advanced"))
    }

    @Test func chestGroupsUseMajorMinorAndGeneralSubcategories() {
        let exercises = [
            makeExercise(name: "High Doorway Chest Stretch (Upper Chest)", targetBodyParts: ["Left Chest", "Right Chest"], difficulty: 2),
            makeExercise(name: "Pec Minor Corner Stretch", targetBodyParts: ["Left Chest"], difficulty: 2),
            makeExercise(name: "Deep Belly Breath", targetBodyParts: ["Left Chest", "Right Chest"], difficulty: 1)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .chest)

        #expect(groups.map(\.title).contains("Pectoralis Major"))
        #expect(groups.map(\.title).contains("Pectoralis Minor"))
        #expect(groups.map(\.title).contains("General Chest"))
    }

    private func makeExercise(name: String, targetBodyParts: [String], difficulty: Int) -> Exercise {
        Exercise(
            name: name,
            type: .stretch,
            targetBodyParts: targetBodyParts,
            durationSeconds: 60,
            difficulty: difficulty,
            instructions: []
        )
    }
}
