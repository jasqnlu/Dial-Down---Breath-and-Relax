import Testing
@testable import BreathRelaxStretch

struct MuscleGroupJointMappingTests {
    @Test func jointNamesExpandToAdjacentMuscleGroups() {
        #expect(MuscleGroup.migrate(["Left Elbow"]) == ["Left Biceps", "Left Triceps", "Left Forearm"])
        #expect(MuscleGroup.migrate(["Right Knee"]) == ["Right Quadriceps", "Right Hamstrings", "Right Calves"])
        #expect(MuscleGroup.migrate(["Left Wrist"]) == ["Left Forearm"])
        #expect(MuscleGroup.migrate(["Right Ankle"]) == ["Right Calves", "Right Tibialis", "Right Foot"])
    }

    @Test func everyJointHitboxNameIsMapped() {
        for volume in BodyHitVolumes.load(resource: "joint_hitboxes") {
            #expect(MuscleGroup.oldRegionMap[volume.name] != nil, "\(volume.name)")
        }
    }
}
