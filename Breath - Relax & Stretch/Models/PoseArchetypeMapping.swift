import Foundation

/// Routes any Exercise to exactly one PoseArchetypeID + a mirror flag, for
/// PoseGlyphIcon to render. Pure functions of name/type — no persisted
/// state, so growing the seed catalog never needs a migration here.
///
/// Resolution order: exact manual overrides (for names whose pose doesn't
/// parse cleanly from keywords) > keyword classifier > standingNeutral
/// fallback. Every exercise always resolves to something real.
enum PoseArchetypeMapping {
    static func resolve(for exercise: Exercise) -> (id: PoseArchetypeID, mirrored: Bool) {
        resolve(name: exercise.name, type: exercise.type)
    }

    static func resolve(name: String, type: ExerciseType) -> (id: PoseArchetypeID, mirrored: Bool) {
        let mirrored = name.contains("Right")
        if type == .breath {
            return (.breathSeated, mirrored)
        }
        if let overrideID = manualOverrides[name] {
            return (overrideID, mirrored)
        }
        return (classify(name.lowercased()), mirrored)
    }

    /// Names whose pose doesn't parse cleanly from keywords — routed
    /// directly to the closest-fitting archetype in the initial 16.
    private static let manualOverrides: [String: PoseArchetypeID] = [
        "World's Greatest Stretch (Left Lead Leg)": .standingTwist,
        "World's Greatest Stretch (Right Lead Leg)": .standingTwist,
        "Pigeon Pose (Left Leg Forward)": .seatedFigureFour,
        "Pigeon Pose (Right Leg Forward)": .seatedFigureFour,
        "Left Pigeon Pose Hip Stretch": .seatedFigureFour,
        "Right Pigeon Pose Hip Stretch": .seatedFigureFour,
        "Downward-Facing Dog": .quadruped,
        "Left Cossack Squat Stretch": .standingSideBend,
        "Right Cossack Squat Stretch": .standingSideBend,
        "Left Couch Stretch": .standingNeutral,
        "Right Couch Stretch": .standingNeutral,
        "Sun Salutation Warm-Up": .standingNeutral,
        "Dynamic Standing Leg Swings": .standingNeutral,
        "Standing Hip Circles": .standingNeutral,
        "Runner's Lunge with Rotation (Left)": .standingTwist,
        "Runner's Lunge with Rotation (Right)": .standingTwist,
    ]

    /// True for any name describing a lying-down position. Checked BEFORE
    /// the `twist` / `forward fold` / `hamstring` clauses on purpose: the
    /// initial 16 archetypes have no supine-twist or supine-fold pose, and
    /// an honest "lying down" figure beats a confidently wrong seated one
    /// (a seated glyph, complete with seat bar, for a supine exercise).
    private static func isLyingDown(_ n: String) -> Bool {
        n.contains("supine") || n.contains("reclined") || n.contains("lying")
            || n.contains("legs up the wall") || n.contains("pelvic tilt")
    }

    private static func classify(_ n: String) -> PoseArchetypeID {
        if n.contains("child's pose") { return .childsPose }
        if n.contains("neck") || n.contains("chin") || n.contains("jaw") || n.contains("eye")
            || n.contains("temple") || n.contains("temporalis") || n.contains("brow")
            || n.contains("forehead") || n.contains("frontalis") || n.contains("tongue")
            || n.contains("20-20-20") || n.contains("suboccipital") {
            return .seatedNeck
        }
        if n.contains("figure-four") || n.contains("figure four") || n.contains("figure-4")
            || n.contains("butterfly") {
            return .seatedFigureFour
        }
        if n.contains("cat-cow") || n.contains("thread the needle") { return .quadruped }
        if n.contains("cobra") || n.contains("sphinx") || n.contains("prone") { return .prone }
        if n.contains("bridge") { return .bridge }
        if n.contains("knee-to-chest") || n.contains("happy baby") { return .supineKneeToChest }
        // Lying-down check sits above twist / fold / hamstring deliberately.
        if isLyingDown(n) { return .supineNeutral }
        if n.contains("twist") {
            return (n.contains("standing") || n.contains("lunge")) ? .standingTwist : .seatedTwist
        }
        if n.contains("side bend") || n.contains("side reach") || n.contains("crescent moon")
            || n.contains("side stretch") {
            return .standingSideBend
        }
        if n.contains("forward fold") || n.contains("hamstring") || n.contains("ragdoll") {
            return n.contains("standing") ? .standingForwardFold : .seatedForwardFold
        }
        if n.contains("seated") { return .seatedNeutral }
        return .standingNeutral
    }
}
