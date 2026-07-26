import Testing
import simd
@testable import BreathRelaxStretch

struct MuscleHitResolverTests {
    private func vol(_ name: String, min: SIMD3<Float>, max: SIMD3<Float>) -> HitVolume {
        HitVolume(name: name, minBound: min, maxBound: max)
    }

    @Test func containmentResolvesToContainingBox() {
        let a = vol("A", min: [0, 0, 0], max: [1, 1, 1])
        let b = vol("B", min: [2, 0, 0], max: [3, 1, 1])
        #expect(MuscleHitResolver.regionName(at: [0.5, 0.5, 0.5], in: [a, b]) == "A")
    }

    @Test func smallestVolumeWinsWhenNested() {
        let muscle = vol("Left Forearm", min: [0, 0, 0], max: [1, 3, 1])
        let joint  = vol("Left Wrist",   min: [0.2, 1.4, 0.2], max: [0.8, 1.6, 0.8])
        #expect(MuscleHitResolver.regionName(at: [0.5, 1.5, 0.5], in: [muscle, joint]) == "Left Wrist")
    }

    @Test func nearestCenterFallbackWhenOutsideEveryBox() {
        let a = vol("A", min: [0, 0, 0], max: [1, 1, 1])       // center (0.5,0.5,0.5)
        let b = vol("B", min: [10, 0, 0], max: [11, 1, 1])     // center (10.5,…)
        #expect(MuscleHitResolver.regionName(at: [2, 0.5, 0.5], in: [a, b]) == "A")
    }

    @Test func emptyVolumesReturnsNil() {
        #expect(MuscleHitResolver.regionName(at: [0, 0, 0], in: []) == nil)
    }

    @Test func bundledMuscleVolumesLoad() {
        let volumes = BodyHitVolumes.load(resource: "musclegroup_hitboxes")
        #expect(volumes.count == 41)
        #expect(volumes.allSatisfy { $0.volume > 0 })
    }

    // MARK: - candidates(near:in:) — anatomical adjacency

    /// Boxes laid out so a chest tap sits with a forearm box nearby (the pose
    /// bleed the old radius suffered) — adjacency must still exclude the forearm.
    @Test func chestTapExcludesNonAdjacentForearm() {
        let chest = vol("Left Chest",   min: [0.05, 0.3, 0.0], max: [0.35, 0.6, 0.25])
        let abs   = vol("Left Abs",     min: [-0.1, 0.1, 0.0], max: [0.1, 0.35, 0.2])   // adjacent
        let fore  = vol("Left Forearm", min: [0.30, 0.2, 0.0], max: [0.45, 0.5, 0.2])   // near but NOT adjacent
        let tapCenter = chest.center
        let result = MuscleHitResolver.candidates(near: tapCenter, in: [chest, abs, fore], maxCandidates: 4)
        #expect(result.first == "Left Chest")
        #expect(result.contains("Left Abs"))
        #expect(!result.contains("Left Forearm"))
    }

    @Test func shoulderJointTapReturnsJointPlusCrossingMuscles() {
        // Shoulder Joint box is smallest, so it wins the primary tiebreak; its
        // adjacency (per RegionAdjacency) is shoulder/chest/trapezius.
        let shoulder  = vol("Left Shoulder",   min: [0.1, 0.3, -0.1], max: [0.3, 0.6, 0.1])
        let chest     = vol("Left Chest",      min: [0.1, 0.3, -0.1], max: [0.3, 0.6, 0.1])
        let trapezius = vol("Left Trapezius",  min: [0.1, 0.0, -0.1], max: [0.3, 0.3, 0.1])
        let shoulderJoint = vol("Left Shoulder Joint", min: [0.17, 0.28, -0.03], max: [0.23, 0.34, 0.03])
        let result = MuscleHitResolver.candidates(near: shoulderJoint.center,
                                                  in: [shoulder, chest, trapezius, shoulderJoint], maxCandidates: 4)
        #expect(result.first == "Left Shoulder Joint")
        #expect(Set(result) == ["Left Shoulder Joint", "Left Shoulder", "Left Chest", "Left Trapezius"])
    }

    @Test func primaryGroupSurfacesItsOwnSubHeads() {
        // Tap the biceps in the GAP between its two head boxes, so the primary
        // resolves to the GROUP (not a head) — then the sub-head pooling is the
        // only thing that can surface both heads. (A tap inside a head box would
        // make that head the primary, trivially satisfying the assertion.)
        let biceps    = vol("Left Biceps",            min: [0.10, 0.2, -0.1], max: [0.35, 0.6, 0.1])
        let longHead  = vol("Left Biceps Long Head",  min: [0.10, 0.2, -0.1], max: [0.18, 0.6, 0.1])
        let shortHead = vol("Left Biceps Short Head", min: [0.27, 0.2, -0.1], max: [0.35, 0.6, 0.1])
        let tap: SIMD3<Float> = [0.225, 0.4, 0.0]   // inside biceps, outside both head boxes
        let result = MuscleHitResolver.candidates(near: tap,
                                                  in: [biceps, longHead, shortHead], maxCandidates: 4)
        #expect(result.first == "Left Biceps")
        #expect(result.contains("Left Biceps Long Head"))
        #expect(result.contains("Left Biceps Short Head"))
    }

    @Test func candidatesCapAtMaxClosestFirst() {
        let chest = vol("Left Chest", min: [0.05, 0.3, 0.0], max: [0.35, 0.6, 0.25])
        let abs   = vol("Left Abs",      min: [0.0, 0.28, 0.0], max: [0.1, 0.4, 0.2])   // closest neighbor
        let obl   = vol("Left Obliques", min: [0.0, 0.1, 0.0], max: [0.2, 0.3, 0.2])
        let sh    = vol("Left Shoulder", min: [0.2, 0.55, 0.0], max: [0.4, 0.75, 0.2])
        let result = MuscleHitResolver.candidates(near: chest.center,
                                                  in: [chest, abs, obl, sh], maxCandidates: 2)
        #expect(result.count == 2)
        #expect(result.first == "Left Chest")
        #expect(result.last == "Left Abs")   // the closest adjacent neighbor survives the cap
    }

    @Test func candidatesOnEmptyVolumesReturnsEmpty() {
        #expect(MuscleHitResolver.candidates(near: [0, 0, 0], in: []) == [])
    }
}
