import Testing
import Foundation
@testable import BreathRelaxStretch

// ContentPack and GoalMeta (which GuidedProgram.proFullReset/starterProgram
// are both derived from) reference exercises by display-name string matched
// against SeedData.json at render time, not by a compiler-checked reference.
// TODO.md notes this was "manually verified once" — this test keeps it true
// automatically instead of relying on that staying accurate.
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

    @Test func everyContentPackExerciseNameExistsInSeedCatalog() throws {
        let seedNames = try seedExerciseNames()
        for pack in ContentPack.all {
            for name in pack.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in \(pack.title) doesn't match any seed exercise")
            }
        }
    }

    @Test func everyGoalMetaExerciseNameExistsInSeedCatalog() throws {
        let seedNames = try seedExerciseNames()
        for goal in GoalMeta.all {
            for name in goal.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in goal \(goal.id) doesn't match any seed exercise")
            }
        }
    }

    @Test func proFullResetOnlyReferencesRealExerciseNames() throws {
        let seedNames = try seedExerciseNames()
        for day in GuidedProgram.proFullReset.days {
            for name in day.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in proFullReset day \(day.dayNumber) doesn't match any seed exercise")
            }
        }
    }

    @Test func starterProgramOnlyReferencesRealExerciseNames() throws {
        let seedNames = try seedExerciseNames()
        let allGoalIDs = Set(GoalMeta.all.map(\.id))
        for day in GuidedProgram.starterProgram(goalIDs: allGoalIDs).days {
            for name in day.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in starterProgram day \(day.dayNumber) doesn't match any seed exercise")
            }
        }
    }
}

private final class BundleToken {}
