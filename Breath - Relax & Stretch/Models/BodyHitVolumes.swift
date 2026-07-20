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
    /// plus its anatomically adjacent regions (`RegionAdjacency`) and its own
    /// muscle sub-heads (`MuscleGroup.muscleHeads`). Anatomy — not 3D distance
    /// — decides which regions are plausible; a bounding-box-diagonal radius
    /// (× `radiusFactor`) is kept only as a light sanity check against a
    /// pooled region whose loaded box happens to sit implausibly far from the
    /// tap. Densely-packed areas (torso, where many small named regions sit
    /// close together) can still turn up more neighbors than are useful to
    /// show in a popup, so the result is capped to the `maxCandidates`
    /// closest to the tap, primary first.
    static func candidates(near point: SIMD3<Float>,
                            in volumes: [HitVolume],
                            radiusFactor: Float = 1.6,
                            maxCandidates: Int = 4) -> [String] {
        guard let primary = primaryVolume(at: point, in: volumes) else { return [] }
        // The group/joint key for the primary: a head resolves via its parent
        // group, everything else is its own key.
        let primaryKey = MuscleGroup.parentOfHead(primary.name) ?? primary.name

        // Candidate pool: the primary group's own sub-heads (so a group tap
        // offers its heads) plus its anatomical neighbors (groups + joints).
        var pool = Set(RegionAdjacency.adjacent(to: primaryKey))
        for (head, group) in MuscleGroup.muscleHeads where group == primaryKey {
            pool.insert(head)
        }
        pool.remove(primary.name)

        // Light sanity check: keep only pooled regions with a loaded volume whose
        // center is near the tap — adjacency is the selector, distance just
        // guards against an anatomically-listed but implausibly-far box.
        let byName = Dictionary(volumes.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        let radius = simd_length(primary.maxBound - primary.minBound) * radiusFactor
        // Broken into explicitly-typed steps: the equivalent single chained
        // expression trips Swift's "unable to type-check in reasonable time".
        let pooledVolumes: [HitVolume] = pool.compactMap { byName[$0] }
        let nearby: [HitVolume] = pooledVolumes.filter { simd_length(point - $0.center) <= radius }
        let sortedNearby: [HitVolume] = nearby.sorted {
            simd_length_squared(point - $0.center) < simd_length_squared(point - $1.center)
        }
        let neighbors: [String] = sortedNearby.map(\.name)

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
