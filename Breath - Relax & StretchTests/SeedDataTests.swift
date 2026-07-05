import Testing
import Foundation
@testable import BreathRelaxStretch

struct SeedDataTests {
    static func loadExercises() throws -> [[String: Any]] {
        let url = try #require(Bundle(for: BundleToken.self)
            .url(forResource: "SeedData", withExtension: "json")
            ?? Bundle.main.url(forResource: "SeedData", withExtension: "json"))
        let json = try #require(try JSONSerialization.jsonObject(
            with: Data(contentsOf: url)) as? [String: Any])
        return try #require(json["exercises"] as? [[String: Any]])
    }

    @Test func allTargetsAreValidGroups() throws {
        for raw in try Self.loadExercises() {
            for part in (raw["targetBodyParts"] as? [String] ?? []) {
                #expect(MuscleGroup(rawValue: part) != nil,
                        "\(raw["name"] ?? "?") targets unknown '\(part)'")
            }
        }
    }

    @Test func everyMuscleGroupHasThreeStretches() throws {
        let fallbacks: Set<MuscleGroup> = [.head, .leftHand, .rightHand, .leftFoot, .rightFoot]
        var counts: [String: Int] = [:]
        for raw in try Self.loadExercises() where (raw["type"] as? String) != "breath" {
            for part in (raw["targetBodyParts"] as? [String] ?? []) {
                counts[part, default: 0] += 1
            }
        }
        for group in MuscleGroup.allCases where !fallbacks.contains(group) {
            #expect(counts[group.rawValue, default: 0] >= 3,
                    "\(group.rawValue) has only \(counts[group.rawValue, default: 0]) stretches")
        }
    }

    @Test func exerciseNamesAreUnique() throws {
        let names = try Self.loadExercises().compactMap { $0["name"] as? String }
        #expect(names.count == Set(names).count)
    }

    @Test func everyExerciseIsComplete() throws {
        for raw in try Self.loadExercises() {
            #expect((raw["instructions"] as? [String] ?? []).count >= 3)
            #expect(((raw["durationSeconds"] as? Int) ?? 0) >= 15)
            #expect((1...3).contains((raw["difficulty"] as? Int) ?? 0))
        }
    }
}

private final class BundleToken {}
