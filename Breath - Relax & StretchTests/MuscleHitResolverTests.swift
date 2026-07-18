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
        #expect(volumes.count == 40)
        #expect(volumes.allSatisfy { $0.volume > 0 })
    }

    // MARK: - candidates(near:in:)

    @Test func candidatesReturnsOnlyPrimaryWhenNoNeighborsNearby() {
        let a = vol("A", min: [0, 0, 0], max: [1, 1, 1])
        let farAway = vol("Far", min: [100, 0, 0], max: [101, 1, 1])
        #expect(MuscleHitResolver.candidates(near: [0.5, 0.5, 0.5], in: [a, farAway]) == ["A"])
    }

    @Test func candidatesIncludesNeighborsWithinRadiusOfPrimary() {
        // Primary box has diagonal ~1.73, so radiusFactor 0.6 → radius ~1.04.
        let primary = vol("Calves", min: [0, 0, 0], max: [1, 1, 1])       // center (0.5,0.5,0.5)
        let neighbor = vol("Tibialis", min: [1.2, 0, 0], max: [2.2, 1, 1]) // center (1.7,0.5,0.5), dist ~1.2 from primary center
        let closeNeighbor = vol("Achilles", min: [0.8, 0, 0], max: [1.8, 1, 1]) // center (1.3,0.5,0.5), dist 0.8
        let far = vol("Neck", min: [50, 0, 0], max: [51, 1, 1])
        let result = MuscleHitResolver.candidates(near: [0.5, 0.5, 0.5], in: [primary, neighbor, closeNeighbor, far],
                                                    radiusFactor: 0.6)
        #expect(result.first == "Calves")
        #expect(result.contains("Achilles"))
        #expect(!result.contains("Neck"))
    }

    @Test func candidatesCapsToMaxCandidatesClosestFirst() {
        let primary = vol("Chest", min: [0, 0, 0], max: [1, 1, 1]) // center (0.5,0.5,0.5), diagonal ~1.73
        // Five neighbors, all within the default radiusFactor (0.35 → radius ~0.6), at increasing distance.
        let neighbors = (1...5).map { i -> HitVolume in
            let center = 0.5 + Float(i) * 0.1
            return vol("Neighbor\(i)", min: [center - 0.05, 0.45, 0.45], max: [center + 0.05, 0.55, 0.55])
        }
        let result = MuscleHitResolver.candidates(near: [0.5, 0.5, 0.5], in: [primary] + neighbors, maxCandidates: 3)
        #expect(result.count == 3)
        #expect(result == ["Chest", "Neighbor1", "Neighbor2"])
    }

    @Test func candidatesOnEmptyVolumesReturnsEmpty() {
        #expect(MuscleHitResolver.candidates(near: [0, 0, 0], in: []) == [])
    }
}
