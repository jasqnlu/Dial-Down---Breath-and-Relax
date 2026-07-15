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
    /// All marking hit volumes: 40 muscle groups + hand-placed joints.
    static let all: [HitVolume] =
        load(resource: "musclegroup_hitboxes") + load(resource: "joint_hitboxes")

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
}
