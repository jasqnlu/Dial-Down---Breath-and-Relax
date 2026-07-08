import SwiftUI

/// Eight coarse groupings over MuscleGroup's ~40 fine-grained values, used
/// as the top-level nodes in the Exercises tab's pinch-zoom node graph.
enum ExerciseCategory: String, CaseIterable, Identifiable {
    case neck = "Neck"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case back = "Back"
    case core = "Core"
    case arms = "Arms"
    case hipsGlutes = "Hips & Glutes"
    case legs = "Legs"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .neck:       return .teal
        case .shoulders:  return .orange
        case .chest:      return .pink
        case .back:       return .indigo
        case .core:       return .yellow
        case .arms:       return .blue
        case .hipsGlutes: return .purple
        case .legs:       return .green
        }
    }

    /// MuscleGroup raw value -> the one category it belongs to.
    private static let membership: [String: ExerciseCategory] = {
        var map: [String: ExerciseCategory] = [:]
        func assign(_ category: ExerciseCategory, _ groups: [MuscleGroup]) {
            for group in groups { map[group.rawValue] = category }
        }
        assign(.neck, [.neckFront, .neckBack, .head])
        assign(.shoulders, [.leftDelts, .rightDelts, .leftTraps, .rightTraps])
        assign(.chest, [.leftChest, .rightChest])
        assign(.back, [.leftLats, .rightLats, .spinalErectors, .lowerBack])
        assign(.core, [.abs, .leftObliques, .rightObliques])
        assign(.arms, [.leftBiceps, .rightBiceps, .leftTriceps, .rightTriceps,
                       .leftForearm, .rightForearm, .leftHand, .rightHand])
        assign(.hipsGlutes, [.leftGlutes, .rightGlutes, .leftHipFlexors, .rightHipFlexors,
                              .leftAdductors, .rightAdductors])
        assign(.legs, [.leftQuads, .rightQuads, .leftHamstrings, .rightHamstrings,
                       .leftCalves, .rightCalves, .leftTibialis, .rightTibialis,
                       .leftFoot, .rightFoot])
        return map
    }()

    /// Categories an exercise belongs to, derived from its target body
    /// parts. Names that aren't a known MuscleGroup raw value are ignored.
    static func categories(for targetBodyParts: [String]) -> Set<ExerciseCategory> {
        Set(targetBodyParts.compactMap { membership[$0] })
    }
}
