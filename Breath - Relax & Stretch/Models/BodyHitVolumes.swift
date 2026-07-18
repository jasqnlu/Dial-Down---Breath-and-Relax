import Foundation
import simd

/// An axis-aligned hit volume in normalized model space (rigNode-local:
/// pivot = whole-body bbox center, scale = 2.0/height — see BodySceneView).
struct HitVolume: Equatable {
    let name: String
    let minBound: SIMD3<Float>
    let maxBound: SIMD3<Float>

    var center: SIMD3<Float> { (minBound + maxBound) / 2 }
    var volume: Float {
        let d = maxBound - minBound
        return d.x * d.y * d.z
    }

    func contains(_ p: SIMD3<Float>) -> Bool {
        p.x >= minBound.x && p.x <= maxBound.x &&
        p.y >= minBound.y && p.y <= maxBound.y &&
        p.z >= minBound.z && p.z <= maxBound.z
    }
}

enum BodyHitVolumes {
    /// All marking hit volumes: 40 muscle groups + optional anatomical sub-head
    /// boxes (nested inside their parent muscle; empty until the head export is
    /// dropped in — see Tools/blender/classify_head_hitboxes.py) + hand-placed
    /// joints. Nested head boxes win the smallest-volume tiebreak in
    /// `MuscleHitResolver`, so a tap inside a muscle resolves to the head.
    static let all: [HitVolume] =
        load(resource: "musclegroup_hitboxes")
        + load(resource: "musclegroup_head_hitboxes")
        + load(resource: "joint_hitboxes")

    private struct BoxEntry: Decodable {
        let min: [Float]
        let max: [Float]
    }

    static func load(resource: String, bundle: Bundle = .main) -> [HitVolume] {
        guard let url = bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([String: BoxEntry].self, from: data)
        else { return [] }
        return entries
            .compactMap { name, box -> HitVolume? in
                guard box.min.count == 3, box.max.count == 3 else { return nil }
                return HitVolume(name: name,
                                 minBound: SIMD3(box.min[0], box.min[1], box.min[2]),
                                 maxBound: SIMD3(box.max[0], box.max[1], box.max[2]))
            }
            .sorted { $0.name < $1.name }
    }
}

/// Resolves a surface point to a region: containment with smallest-volume
/// tiebreak (joint boxes are small, so they beat enclosing muscle boxes),
/// nearest-center fallback for points the muscle layer doesn't reach.
enum MuscleHitResolver {
    static func regionName(at point: SIMD3<Float>, in volumes: [HitVolume]) -> String? {
        let containing = volumes.filter { $0.contains(point) }
        if let best = containing.min(by: { $0.volume < $1.volume }) {
            return best.name
        }
        return volumes.min {
            simd_length_squared(point - $0.center) < simd_length_squared(point - $1.center)
        }?.name
    }

    /// Every region plausibly meant by a tap at `point`, for the confirm-step
    /// disambiguation popup: the resolved primary region (see `regionName`)
    /// plus other regions whose center falls within a radius of the tap. The
    /// radius is derived from the primary region's own bounding-box diagonal
    /// (× `radiusFactor`) rather than a fixed constant, so it scales
    /// automatically between small regions (calf) and large ones (back)
    /// instead of needing per-region tuning. Densely-packed areas (torso,
    /// where many small named regions sit close together) can still turn up
    /// more neighbors than are useful to show in a popup, so the result is
    /// capped to the `maxCandidates` closest to the tap, primary first.
    static func candidates(near point: SIMD3<Float>,
                            in volumes: [HitVolume],
                            radiusFactor: Float = 0.35,
                            maxCandidates: Int = 4) -> [String] {
        guard let primary = primaryVolume(at: point, in: volumes) else { return [] }
        let diagonal = simd_length(primary.maxBound - primary.minBound)
        let radius = diagonal * radiusFactor

        let neighbors = volumes
            .filter { $0.name != primary.name && simd_length(point - $0.center) <= radius }
            .sorted { simd_length_squared(point - $0.center) < simd_length_squared(point - $1.center) }
            .map(\.name)

        var result = [primary.name]
        for name in neighbors where result.count < maxCandidates {
            result.append(name)
        }
        return result
    }

    private static func primaryVolume(at point: SIMD3<Float>, in volumes: [HitVolume]) -> HitVolume? {
        let containing = volumes.filter { $0.contains(point) }
        if let best = containing.min(by: { $0.volume < $1.volume }) {
            return best
        }
        return volumes.min {
            simd_length_squared(point - $0.center) < simd_length_squared(point - $1.center)
        }
    }
}
