import Foundation

/// Hand-authored anatomical adjacency: which regions may legitimately appear
/// together as disambiguation candidates. Replaces the old 3D-distance radius,
/// which surfaced arm muscles for a chest/leg tap because the arms hang close
/// to the torso in the anatomical pose. Authored as directed edges and
/// symmetrized at build, so the relation is symmetric by construction.
///
/// Lists cross-region neighbors only (muscle groups + joints). A muscle group's
/// own sub-heads are added separately by `MuscleHitResolver.candidates()` (from
/// `MuscleGroup.muscleHeads`), so they are intentionally absent here. `Head`
/// disambiguation is owned by `HeadZones`, so `Head` is absent too.
enum RegionAdjacency {
    /// Directed edges, authored once per pair. Bilateral limbs list `L`; the
    /// build mirrors each to the matching `R` region automatically.
    private static let authored: [String: [String]] = {
        var e: [String: [String]] = [
            // ── Axial / torso (midline + both-sides) ──
            "Front Neck": ["Back Neck", "Neck"],
            "Back Neck": ["Spinal Erectors", "Neck"],
            "Spinal Erectors": ["Lower Back", "Lower Spine", "Neck"],
            "Lower Back": ["Lower Spine"],
            "Abs": ["Left Obliques", "Right Obliques", "Left Chest", "Right Chest",
                    "Left Hip Flexors", "Right Hip Flexors"],
            "Neck": ["Left Trapezius", "Right Trapezius"],
            "Lower Spine": ["Left Glutes", "Right Glutes"],
        ]
        // ── Per-side chains (authored for Left; mirrored to Right at build) ──
        let leftEdges: [String: [String]] = [
            "Left Trapezius": ["Left Shoulder", "Back Neck", "Front Neck", "Spinal Erectors", "Neck"],
            "Left Shoulder": ["Left Trapezius", "Left Chest", "Left Biceps", "Left Triceps",
                              "Left Lats", "Left Shoulder Joint"],
            "Left Chest": ["Left Obliques", "Left Shoulder", "Left Shoulder Joint"],
            "Left Obliques": ["Left Chest", "Left Lats", "Lower Back", "Left Hip Flexors"],
            "Left Lats": ["Left Obliques", "Spinal Erectors", "Left Shoulder", "Left Trapezius", "Lower Back"],
            "Left Biceps": ["Left Triceps", "Left Shoulder", "Left Forearm", "Left Shoulder Joint"],
            "Left Triceps": ["Left Biceps", "Left Shoulder", "Left Forearm", "Left Shoulder Joint"],
            "Left Forearm": ["Left Hand"],
            "Left Hand": [],
            "Left Glutes": ["Lower Back", "Left Hip Flexors", "Left Hamstrings", "Left Adductors", "Left Hip"],
            "Left Hip Flexors": ["Left Adductors", "Left Quadriceps", "Left Glutes", "Left Hip", "Lower Back"],
            "Left Adductors": ["Left Quadriceps", "Left Hamstrings", "Left Glutes", "Left Hip"],
            "Left Quadriceps": ["Left Adductors", "Left Hamstrings", "Left Hip"],
            "Left Hamstrings": ["Left Glutes", "Left Adductors", "Left Quadriceps", "Left Calves", "Left Hip"],
            "Left Calves": ["Left Tibialis", "Left Foot"],
            "Left Tibialis": ["Left Foot"],
            "Left Foot": [],
            // joints → their crossing muscles
            "Left Shoulder Joint": ["Left Shoulder", "Left Chest", "Left Trapezius"],
            "Left Hip": ["Left Glutes", "Left Hip Flexors", "Left Adductors", "Left Quadriceps", "Left Hamstrings", "Lower Back"],
        ]
        for (k, v) in leftEdges {
            e[k] = v
            // Mirror Left → Right by swapping the side prefix on the key and each
            // neighbor that carries a side. Midline neighbors (Abs, Lower Back,
            // Spinal Erectors, Neck, Lower Spine) pass through unchanged.
            e[mirror(k)] = v.map(mirror)
        }
        return e
    }()

    /// Swap a `Left `/`Right ` prefix; leave midline names unchanged.
    private static func mirror(_ name: String) -> String {
        if name.hasPrefix("Left ")  { return "Right " + name.dropFirst(5) }
        if name.hasPrefix("Right ") { return "Left "  + name.dropFirst(6) }
        return name
    }

    /// Symmetric adjacency: every authored edge plus its reverse.
    static let neighbors: [String: Set<String>] = {
        var m: [String: Set<String>] = [:]
        for (region, list) in authored {
            for n in list {
                m[region, default: []].insert(n)
                m[n, default: []].insert(region)   // symmetrize
            }
        }
        return m
    }()

    /// The regions anatomically adjacent to `region` (empty if none authored).
    static func adjacent(to region: String) -> Set<String> { neighbors[region] ?? [] }
}
