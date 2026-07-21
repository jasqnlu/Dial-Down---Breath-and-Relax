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

    /// The 5 joint regions added for the single-anatomy model (Plan 3) expand to
    /// their crossing muscles, so a joint tap surfaces those muscles' stretches
    /// through the existing `migrate` → `RegionExerciseResolver` path.
    @Test func newJointRegionsExpandToCrossingMuscles() {
        #expect(MuscleGroup.migrate(["Left Shoulder Joint"]) == ["Left Shoulder", "Left Chest", "Left Lats", "Left Trapezius"])
        #expect(MuscleGroup.migrate(["Right Hip"]) == ["Right Glutes", "Right Hip Flexors", "Right Adductors", "Right Hamstrings"])
        #expect(MuscleGroup.migrate(["Upper Spine"]) == ["Spinal Erectors", "Left Trapezius", "Right Trapezius"])
        #expect(MuscleGroup.migrate(["Lower Spine"]) == ["Lower Back", "Spinal Erectors"])
    }

    /// Every one of the 15 joint regions resolves to a non-empty set of muscle
    /// groups (expands rather than passing through unchanged).
    @Test func allJointRegionsResolveToMuscles() {
        for joint in JointRegion.allNames {
            let expanded = MuscleGroup.migrate([joint])
            #expect(!expanded.isEmpty, "\(joint) resolves to no muscles")
            #expect(expanded != [joint], "\(joint) did not expand to crossing muscles")
        }
    }
}
