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

    @Test func difficultyFilterKeepsOnlyMatchingLevels() {
        let exercises = [
            makeExercise(name: "Easy One", targetBodyParts: [], difficulty: 1),
            makeExercise(name: "Medium One", targetBodyParts: [], difficulty: 2),
            makeExercise(name: "Hard One", targetBodyParts: [], difficulty: 3)
        ]

        let results = ExerciseSearchResults(
            exercises: exercises,
            searchText: "",
            selectedType: nil,
            visibleCount: 7,
            selectedDifficulties: [1]
        )

        #expect(results.visible.map(\.name) == ["Easy One"])
    }

    @Test func emptyDifficultySelectionMeansNoFilter() {
        let exercises = [
            makeExercise(name: "Easy One", targetBodyParts: [], difficulty: 1),
            makeExercise(name: "Hard One", targetBodyParts: [], difficulty: 3)
        ]

        let results = ExerciseSearchResults(
            exercises: exercises,
            searchText: "",
            selectedType: nil,
            visibleCount: 7,
            selectedDifficulties: []
        )

        #expect(results.visible.count == 2)
    }

    @Test func durationBucketFiltersBySeconds() {
        let exercises = [
            makeExercise(name: "Short", targetBodyParts: [], durationSeconds: 45),
            makeExercise(name: "Medium", targetBodyParts: [], durationSeconds: 120),
            makeExercise(name: "Long", targetBodyParts: [], durationSeconds: 240)
        ]

        let under1 = ExerciseSearchResults(
            exercises: exercises,
            searchText: "",
            selectedType: nil,
            visibleCount: 7,
            durationBucket: .under1Min
        )
        #expect(under1.visible.map(\.name) == ["Short"])

        let oneToThree = ExerciseSearchResults(
            exercises: exercises,
            searchText: "",
            selectedType: nil,
            visibleCount: 7,
            durationBucket: .oneToThreeMin
        )
        #expect(oneToThree.visible.map(\.name) == ["Medium"])

        let threePlus = ExerciseSearchResults(
            exercises: exercises,
            searchText: "",
            selectedType: nil,
            visibleCount: 7,
            durationBucket: .threePlusMin
        )
        #expect(threePlus.visible.map(\.name) == ["Long"])
    }

    @Test func filtersCombineWithSearchAndType() {
        let exercises = [
            makeExercise(name: "Chest Opener", type: .stretch, targetBodyParts: ["Left Chest"], durationSeconds: 60, difficulty: 1),
            makeExercise(name: "Chest Press", type: .stretch, targetBodyParts: ["Left Chest"], durationSeconds: 60, difficulty: 3),
            makeExercise(name: "Chest Breather", type: .breath, targetBodyParts: ["Left Chest"], durationSeconds: 60, difficulty: 1)
        ]

        let results = ExerciseSearchResults(
            exercises: exercises,
            searchText: "chest",
            selectedType: .stretch,
            visibleCount: 7,
            selectedDifficulties: [1]
        )

        #expect(results.visible.map(\.name) == ["Chest Opener"])
    }

    private func makeExercise(
        name: String,
        type: ExerciseType = .stretch,
        targetBodyParts: [String],
        durationSeconds: Int = 60,
        difficulty: Int = 1
    ) -> Exercise {
        Exercise(
            name: name,
            type: type,
            targetBodyParts: targetBodyParts,
            durationSeconds: durationSeconds,
            difficulty: difficulty,
            instructions: []
        )
    }
}
