import Testing
@testable import BreathRelaxStretch

struct ExerciseCategoryTests {
    @Test func everyMuscleGroupMapsToExactlyOneCategory() {
        for group in MuscleGroup.allCases {
            let categories = ExerciseCategory.categories(for: [group.rawValue])
            #expect(categories.count == 1, "MuscleGroup \(group.rawValue) should map to exactly one category")
        }
    }

    @Test func singlePartMapsToExpectedCategory() {
        #expect(ExerciseCategory.categories(for: ["Left Quadriceps"]) == [.legs])
        #expect(ExerciseCategory.categories(for: ["Left Abs"]) == [.core])
        #expect(ExerciseCategory.categories(for: ["Head"]) == [.neck])
    }

    @Test func exerciseSpanningCategoriesMapsToBoth() {
        let categories = ExerciseCategory.categories(for: ["Left Chest", "Left Shoulder"])
        #expect(categories == [.chest, .shoulders])
    }

    @Test func unknownPartNameIsIgnored() {
        #expect(ExerciseCategory.categories(for: ["Not A Real Part"]).isEmpty)
    }

    @Test func allCategoriesHaveEightCases() {
        #expect(ExerciseCategory.allCases.count == 8)
    }
}
