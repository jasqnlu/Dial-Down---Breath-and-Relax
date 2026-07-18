import Foundation

/// The body-map / exercise vocabulary: ~40 major muscle groups plus coarse
/// fallback areas (head/hands/feet) that muscles don't cover.
enum MuscleGroup: String, CaseIterable, Codable {
    // Neck & shoulders
    case neckFront = "Front Neck", neckBack = "Back Neck"
    case leftTraps = "Left Trapezius",   rightTraps = "Right Trapezius"
    case leftDelts = "Left Shoulder",    rightDelts = "Right Shoulder"
    // Torso
    case leftChest = "Left Chest",       rightChest = "Right Chest"
    case abs = "Abs"
    case leftObliques = "Left Obliques", rightObliques = "Right Obliques"
    case leftLats = "Left Lats",         rightLats = "Right Lats"
    case spinalErectors = "Spinal Erectors"
    case lowerBack = "Lower Back"
    // Arms
    case leftBiceps = "Left Biceps",     rightBiceps = "Right Biceps"
    case leftTriceps = "Left Triceps",   rightTriceps = "Right Triceps"
    case leftForearm = "Left Forearm",   rightForearm = "Right Forearm"
    // Hips & legs
    case leftGlutes = "Left Glutes",     rightGlutes = "Right Glutes"
    case leftHipFlexors = "Left Hip Flexors", rightHipFlexors = "Right Hip Flexors"
    case leftAdductors = "Left Adductors",    rightAdductors = "Right Adductors"
    case leftQuads = "Left Quadriceps",  rightQuads = "Right Quadriceps"
    case leftHamstrings = "Left Hamstrings", rightHamstrings = "Right Hamstrings"
    case leftCalves = "Left Calves",     rightCalves = "Right Calves"
    case leftTibialis = "Left Tibialis", rightTibialis = "Right Tibialis"
    // Coarse fallback areas (no skeletal muscle proxy coverage)
    case head = "Head"
    case leftHand = "Left Hand",  rightHand = "Right Hand"
    case leftFoot = "Left Foot",  rightFoot = "Right Foot"

    /// Legacy body-map region name → new group names.
    static let oldRegionMap: [String: [String]] = [
        "Head": ["Head"], "Neck": ["Front Neck", "Back Neck"],
        "Left Shoulder": ["Left Shoulder"], "Right Shoulder": ["Right Shoulder"],
        "Chest": ["Left Chest", "Right Chest"],
        "Core": ["Abs"],
        "Upper Back": ["Left Trapezius", "Right Trapezius"],
        "Lower Back": ["Lower Back"],
        "Left Arm": ["Left Biceps", "Left Triceps"],
        "Right Arm": ["Right Biceps", "Right Triceps"],
        "Left Elbow": ["Left Biceps", "Left Triceps", "Left Forearm"],
        "Right Elbow": ["Right Biceps", "Right Triceps", "Right Forearm"],
        "Left Wrist": ["Left Forearm"], "Right Wrist": ["Right Forearm"],
        "Left Ankle": ["Left Calves", "Left Tibialis", "Left Foot"],
        "Right Ankle": ["Right Calves", "Right Tibialis", "Right Foot"],
        "Left Forearm": ["Left Forearm"], "Right Forearm": ["Right Forearm"],
        "Left Hand": ["Left Hand"], "Right Hand": ["Right Hand"],
        "Hips": ["Left Hip Flexors", "Right Hip Flexors"],
        "Glutes": ["Left Glutes", "Right Glutes"],
        "Left Leg": ["Left Quadriceps"], "Right Leg": ["Right Quadriceps"],
        "Left Hamstring": ["Left Hamstrings"], "Right Hamstring": ["Right Hamstrings"],
        "Left Knee": ["Left Quadriceps", "Left Hamstrings", "Left Calves"],
        "Right Knee": ["Right Quadriceps", "Right Hamstrings", "Right Calves"],
        "Left Shin": ["Left Tibialis"], "Right Shin": ["Right Tibialis"],
        "Left Calf": ["Left Calves"], "Right Calf": ["Right Calves"],
        "Left Foot": ["Left Foot"], "Right Foot": ["Right Foot"],
    ]

    // MARK: - Muscle sub-heads

    /// Anatomical sub-head display name → its parent muscle group. Head hit
    /// volumes are *optional* data (`musclegroup_head_hitboxes.json`, generated
    /// by `Tools/blender/classify_head_hitboxes.py`): when present they surface
    /// as disambiguation candidates and resolve to their own exercises, falling
    /// back to the parent muscle's list. These names MUST match the Blender
    /// script's output exactly.
    static let muscleHeads: [String: String] = {
        // Base head names per group (side-agnostic); expanded to Left/Right.
        let byGroup: [(group: String, heads: [String])] = [
            ("Shoulder",   ["Anterior Deltoid", "Lateral Deltoid", "Posterior Deltoid"]),
            ("Chest",      ["Upper Chest", "Lower Chest"]),
            ("Biceps",     ["Biceps Long Head", "Biceps Short Head"]),
            ("Triceps",    ["Triceps Long Head", "Triceps Lateral Head", "Triceps Medial Head"]),
            ("Trapezius",  ["Upper Trapezius", "Middle Trapezius", "Lower Trapezius"]),
            ("Quadriceps", ["Rectus Femoris", "Vastus Lateralis", "Vastus Medialis"]),
            ("Hamstrings", ["Biceps Femoris", "Semitendinosus", "Semimembranosus"]),
            ("Calves",     ["Medial Gastrocnemius", "Lateral Gastrocnemius", "Soleus"]),
            ("Glutes",     ["Gluteus Maximus", "Gluteus Medius"]),
        ]
        var map: [String: String] = [:]
        for entry in byGroup {
            for side in ["Left", "Right"] {
                for head in entry.heads {
                    map["\(side) \(head)"] = "\(side) \(entry.group)"
                }
            }
        }
        return map
    }()

    /// The parent muscle group for a sub-head name, or nil if `name` isn't a head.
    static func parentOfHead(_ name: String) -> String? { muscleHeads[name] }

    /// Maps legacy names to group names; unknown names pass through unchanged.
    /// Order-preserving, deduplicated.
    static func migrate(_ oldNames: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for old in oldNames {
            for name in oldRegionMap[old] ?? [old] where seen.insert(name).inserted {
                out.append(name)
            }
        }
        return out
    }
}
