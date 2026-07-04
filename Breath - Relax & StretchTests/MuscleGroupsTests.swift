import Testing
@testable import BreathRelaxStretch

struct MuscleGroupsTests {
    /// Every legacy region name used by seed v3 / saved marks must map somewhere.
    static let legacyNames = [
        "Chest", "Core", "Glutes", "Head", "Hips", "Left Arm", "Left Calf",
        "Left Elbow", "Left Foot", "Left Forearm", "Left Hamstring", "Left Hand",
        "Left Knee", "Left Leg", "Left Shin", "Left Shoulder", "Lower Back",
        "Neck", "Right Arm", "Right Calf", "Right Elbow", "Right Foot",
        "Right Forearm", "Right Hamstring", "Right Hand", "Right Knee",
        "Right Leg", "Right Shin", "Right Shoulder", "Upper Back"
    ]

    @Test func everyLegacyNameMigrates() {
        for old in Self.legacyNames {
            let mapped = MuscleGroup.migrate([old])
            #expect(!mapped.isEmpty, "\(old) has no migration target")
            for name in mapped {
                #expect(MuscleGroup(rawValue: name) != nil, "\(name) is not a valid group")
            }
        }
    }

    @Test func migrationPassesUnknownNamesThrough() {
        #expect(MuscleGroup.migrate(["My Custom Area"]) == ["My Custom Area"])
    }

    @Test func migrationDeduplicates() {
        // "Left Leg" and "Left Knee" both include Left Quadriceps — no dupes.
        let out = MuscleGroup.migrate(["Left Leg", "Left Knee"])
        #expect(Set(out).count == out.count)
    }

    @Test func groupCountIsAround40() {
        #expect((38...52).contains(MuscleGroup.allCases.count))
    }
}
