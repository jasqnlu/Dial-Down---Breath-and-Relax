import Testing
@testable import BreathRelaxStretch

struct ExerciseSearchPaginationTests {
    @Test func initialPageShowsAtMostSevenMatchingExercises() {
        let exercises = (1...12).map { index in
            makeExercise(name: "Chest Opener \(index)", targetBodyParts: ["Left Chest"])
        }

        let results = ExerciseSearchResults(
            exercises: exercises,
            searchText: "chest",
            selectedType: nil,
            visibleCount: 7
        )

        #expect(results.visible.map(\.name) == (1...7).map { "Chest Opener \($0)" })
        #expect(results.canLoadMore)
    }

    @Test func loadingNextPageAddsAnotherSevenExercises() {
        let exercises = (1...15).map { index in
            makeExercise(name: "Shoulder Reset \(index)", targetBodyParts: ["Left Shoulder"])
        }

        let results = ExerciseSearchResults(
            exercises: exercises,
            searchText: "shoulder",
            selectedType: nil,
            visibleCount: 14
        )

        #expect(results.visible.count == 14)
        #expect(results.canLoadMore)
    }

    @Test func searchMatchesBodyPartAndTypeBeforePagination() {
        let exercises = [
            makeExercise(name: "Breath A", type: .breath, targetBodyParts: ["Left Chest"]),
            makeExercise(name: "Stretch B", type: .stretch, targetBodyParts: ["Right Chest"]),
            makeExercise(name: "Stretch C", type: .stretch, targetBodyParts: ["Left Shoulder"])
        ]

        let results = ExerciseSearchResults(
            exercises: exercises,
            searchText: "chest",
            selectedType: .stretch,
            visibleCount: 7
        )

        #expect(results.visible.map(\.name) == ["Stretch B"])
        #expect(!results.canLoadMore)
    }

    private func makeExercise(
        name: String,
        type: ExerciseType = .stretch,
        targetBodyParts: [String]
    ) -> Exercise {
        Exercise(
            name: name,
            type: type,
            targetBodyParts: targetBodyParts,
            durationSeconds: 60,
            difficulty: 1,
            instructions: []
        )
    }
}
