import Testing
@testable import BreathRelaxStretch

/// Anatomical sub-head vocabulary: heads map to a valid parent muscle group,
/// non-heads don't, and the head names stay in lock-step with the Blender
/// export (Tools/blender/classify_head_hitboxes.py).
struct MuscleHeadTests {

    @Test func everyHeadMapsToAValidParentGroup() {
        #expect(!MuscleGroup.muscleHeads.isEmpty)
        for (head, parent) in MuscleGroup.muscleHeads {
            #expect(MuscleGroup(rawValue: parent) != nil,
                    "\(head) → \(parent) is not a valid MuscleGroup")
            // A head is distinct from its parent and from any group case.
            #expect(head != parent)
            #expect(MuscleGroup(rawValue: head) == nil,
                    "\(head) should be a head, not a group case")
        }
    }

    @Test func headsComeInLeftRightPairs() {
        for head in MuscleGroup.muscleHeads.keys where head.hasPrefix("Left ") {
            let right = "Right " + head.dropFirst("Left ".count)
            #expect(MuscleGroup.muscleHeads[right] != nil, "\(head) has no Right pair")
        }
    }

    @Test func parentOfHeadIdentifiesHeadsOnly() {
        #expect(MuscleGroup.parentOfHead("Left Triceps Long Head") == "Left Triceps")
        #expect(MuscleGroup.parentOfHead("Right Rectus Femoris") == "Right Quadriceps")
        #expect(MuscleGroup.parentOfHead("Left Soleus") == "Left Calves")
        // Plain group / coarse names are not heads.
        #expect(MuscleGroup.parentOfHead("Left Triceps") == nil)
        #expect(MuscleGroup.parentOfHead("Abs") == nil)
        #expect(MuscleGroup.parentOfHead("Nonsense") == nil)
    }

    @Test func faceZonesResolveToHeadParent() {
        for zone in ["Left Eye", "Right Eye", "Left Temple", "Right Temple",
                     "Left Jaw", "Right Jaw", "Forehead"] {
            #expect(MuscleGroup.parentOfHead(zone) == "Head",
                    "\(zone) should parent to Head")
        }
    }

    @Test func foreheadIsMidlineWithNoSide() {
        #expect(MuscleGroup.muscleHeads["Forehead"] == "Head")
        #expect(MuscleGroup.muscleHeads["Left Forehead"] == nil)
        #expect(MuscleGroup.muscleHeads["Right Forehead"] == nil)
    }

    @Test func bilateralFaceZonesComeInPairs() {
        for base in ["Eye", "Temple", "Jaw"] {
            #expect(MuscleGroup.muscleHeads["Left \(base)"] == "Head")
            #expect(MuscleGroup.muscleHeads["Right \(base)"] == "Head")
        }
    }

    /// The triceps example from the feature request: three heads, one parent.
    @Test func tricepsHasThreeHeadsPerSide() {
        for side in ["Left", "Right"] {
            let heads = MuscleGroup.muscleHeads
                .filter { $0.value == "\(side) Triceps" }
                .map(\.key)
                .sorted()
            #expect(heads == [
                "\(side) Triceps Lateral Head",
                "\(side) Triceps Long Head",
                "\(side) Triceps Medial Head",
            ])
        }
    }
}
