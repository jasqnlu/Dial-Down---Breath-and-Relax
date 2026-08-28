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
                        assign(.core, [.leftAbs, .rightAbs, .leftObliques, .rightObliques])
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
    /// parts. A part may be a top-level `MuscleGroup` raw value directly, or
    /// an anatomical sub-head ("Left Temple") — those resolve to their parent
    /// group (e.g. "Head") the same way `RegionExerciseResolver` does for the
    /// Body Map, so head-zone exercises still land on the Neck node instead of
    /// falling out of every category. Joint-region names (e.g. "Left Hip")
    /// aren't muscle groups and don't resolve on their own; every seeded
    /// joint-tagged exercise also carries a muscle-group tag it's found by.
    /// Names that still don't resolve are ignored.
    static func categories(for targetBodyParts: [String]) -> Set<ExerciseCategory> {
        Set(targetBodyParts.compactMap { part in
            membership[MuscleGroup.parentOfHead(part) ?? part]
        })
    }

    /// A single deterministic category for contexts that need one badge
    /// color rather than the full set `categories(for:)` returns — picks
    /// the first match in `allCases` declaration order. Falls back to
    /// `.core` when no target body part resolves to any category.
    static func primary(for targetBodyParts: [String]) -> ExerciseCategory {
        let matched = categories(for: targetBodyParts)
        return allCases.first(where: matched.contains) ?? .core
    }
}

// MARK: - Focus-area personalisation
//
// The user picks the body areas they want to train during onboarding
// (stored as a comma-separated list of category raw values in the
// `onboardingAreas` AppStorage key). The Home "Recommended" carousel uses
// that to surface exercises from those areas, each tagged with its category.

/// One recommendation: an exercise plus the focus area it represents.
struct RecommendedExercise: Identifiable {
    let exercise: Exercise
    let category: ExerciseCategory
    var id: UUID { exercise.uuid }
}

extension ExerciseCategory {
    /// Parses the stored `onboardingAreas` string into a set of categories.
    static func areas(from stored: String) -> Set<ExerciseCategory> {
        Set(stored
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap(ExerciseCategory.init(rawValue:)))
    }

    /// Serialises a set of categories back to the stored string form
    /// (stable order so the value is deterministic).
    static func store(_ areas: Set<ExerciseCategory>) -> String {
        allCases.filter(areas.contains).map(\.rawValue).joined(separator: ",")
    }

    /// Personalised recommendations for the Home carousel: exercises drawn
    /// from the user's chosen focus `areas`, interleaved round-robin so every
    /// selected area contributes, de-duplicated, each tagged with the area it
    /// represents. Falls back to all areas when none were chosen (e.g. users
    /// who onboarded before the focus-area step existed).
    static func recommendedExercises(from exercises: [Exercise],
                                     areas: Set<ExerciseCategory>,
                                     limit: Int) -> [RecommendedExercise] {
        let activeAreas = areas.isEmpty ? Set(allCases) : areas
        let orderedAreas = allCases.filter(activeAreas.contains)

        // Exercises per area, name-sorted for a stable, repeatable order.
        let perArea: [[RecommendedExercise]] = orderedAreas.map { area in
            exercises
                .filter { categories(for: $0.targetBodyParts).contains(area) }
                .sorted { $0.name < $1.name }
                .map { RecommendedExercise(exercise: $0, category: area) }
        }

        var seen = Set<UUID>()
        var result: [RecommendedExercise] = []
        var index = 0
        while result.count < limit {
            var addedAny = false
            for list in perArea where index < list.count {
                let candidate = list[index]
                if seen.insert(candidate.exercise.uuid).inserted {
                    result.append(candidate)
                    addedAny = true
                    if result.count >= limit { break }
                }
            }
            if !addedAny { break }
            index += 1
        }
        return result
    }
}
