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
}
