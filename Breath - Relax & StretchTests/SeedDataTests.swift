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
                let isGroup = MuscleGroup(rawValue: part) != nil
                let isHead = MuscleGroup.parentOfHead(part) != nil
                let isJoint = JointRegion.isJoint(part)
                #expect(isGroup || isHead || isJoint,
                        "\(raw["name"] ?? "?") targets unknown '\(part)'")
            }
        }
    }

    @Test func everyJointRegionHasDedicatedExercises() throws {
        let all = try Self.loadExercises()
        for joint in JointRegion.allCases {
            let hit = all.contains { raw in
                (raw["targetBodyParts"] as? [String] ?? []).contains(joint.rawValue)
            }
            #expect(hit, "No seed exercise targets the '\(joint.rawValue)' joint directly")
        }
    }

    @Test func faceZoneExercisesTargetRegisteredZones() throws {
        let zones: Set<String> = ["Left Eye", "Right Eye", "Left Temple",
                                  "Right Temple", "Left Jaw", "Right Jaw", "Forehead"]
        let all = try Self.loadExercises()
        for zone in zones {
            let hit = all.contains { raw in
                (raw["targetBodyParts"] as? [String] ?? []).contains(zone)
            }
            #expect(hit, "No seed exercise targets the '\(zone)' zone")
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

    /// Pure breathing exercises must never carry `targetBodyParts` — the Body
    /// Map resolves regions to exercises purely from that field, so a
    /// non-empty value on a `breath`-typed entry leaks it into whichever
    /// muscle/joint regions it happens to name (regression for "Progressive
    /// Relaxation Breath" appearing under Core/Legs regions).
    @Test func breathExercisesHaveNoTargetBodyParts() throws {
        for raw in try Self.loadExercises() where (raw["type"] as? String) == "breath" {
            #expect((raw["targetBodyParts"] as? [String] ?? []).isEmpty,
                    "\(raw["name"] ?? "?") is type 'breath' but has non-empty targetBodyParts")
        }
    }

    @Test func exerciseNamesAreUnique() throws {
        let names = try Self.loadExercises().compactMap { $0["name"] as? String }
        #expect(names.count == Set(names).count)
    }

    /// `seedIfNeeded()` (Breath__Relax___StretchApp.swift) parses this "id"
    /// directly as the Exercise's uuid — the identifier Session/Routine
    /// exerciseIDs and Supabase's RemoteExercise.id compare across devices —
    /// so it must be a valid, unique UUID string for every entry, or a fresh
    /// install silently falls back to the name-derived uuid for that row.
    @Test func everyExerciseHasAValidUniqueID() throws {
        let all = try Self.loadExercises()
        let ids = all.compactMap { $0["id"] as? String }
        #expect(ids.count == all.count, "Every seed exercise must have an \"id\"")
        for id in ids {
            #expect(UUID(uuidString: id) != nil, "\"\(id)\" is not a valid UUID")
        }
        #expect(ids.count == Set(ids).count, "Seed exercise ids must be unique")
    }

    @Test func everyExerciseIsComplete() throws {
        for raw in try Self.loadExercises() {
            #expect((raw["instructions"] as? [String] ?? []).count >= 3)
            #expect(((raw["durationSeconds"] as? Int) ?? 0) >= 15)
            #expect((1...3).contains((raw["difficulty"] as? Int) ?? 0))
        }
    }

    @Test func everyExerciseHasCueStyle() throws {
        for raw in try Self.loadExercises() {
            let cueStyle = raw["cueStyle"] as? String
            #expect(["hold", "repeat"].contains(cueStyle ?? ""),
                    "\(raw["name"] ?? "?") has missing/invalid cueStyle: \(cueStyle ?? "nil")")
        }
    }
}

private final class BundleToken {}
