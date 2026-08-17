import Testing
import Foundation
@testable import BreathRelaxStretch

// GoalMeta references exercises by display-name string matched against
// SeedData.json at render time, not by a compiler-checked reference. This
// test keeps that mapping honest rather than relying on manual review.
struct CuratedContentIntegrityTests {

    private func seedExerciseNames() throws -> Set<String> {
        let url = try #require(Bundle(for: BundleToken.self)
            .url(forResource: "SeedData", withExtension: "json")
            ?? Bundle.main.url(forResource: "SeedData", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let exercises = try #require(json["exercises"] as? [[String: Any]])
        return Set(exercises.compactMap { $0["name"] as? String })
    }

    @Test func everyGoalMetaExerciseNameExistsInSeedCatalog() throws {
        let seedNames = try seedExerciseNames()
        for goal in GoalMeta.all {
            for name in goal.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in goal \(goal.id) doesn't match any seed exercise")
            }
        }
    }

    @Test func everyPremadeRoutineExerciseNameExistsInSeedCatalog() throws {
        let seedNames = try seedExerciseNames()
        for routine in PremadeRoutine.all {
            for name in routine.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in \(routine.title) doesn't match any seed exercise")
            }
        }
    }
}

private final class BundleToken {}
