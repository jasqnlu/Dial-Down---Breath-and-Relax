import Testing
@testable import BreathRelaxStretch

struct GoalMetaTests {

    @Test func wakeUpAndUnwindPoolsExist() {
        #expect(GoalMeta.all.contains { $0.id == "wake_up" })
        #expect(GoalMeta.all.contains { $0.id == "unwind" })
    }

    @Test func wakeUpAndUnwindExerciseNamesExistInSeedData() throws {
        let seedNames = Set(try SeedDataTests.loadExercises().compactMap { $0["name"] as? String })
        let wakeUp = try #require(GoalMeta.all.first { $0.id == "wake_up" })
        let unwind = try #require(GoalMeta.all.first { $0.id == "unwind" })
        for name in wakeUp.exerciseNames + unwind.exerciseNames {
            #expect(seedNames.contains(name), "\(name) not found in SeedData.json")
        }
    }
}
