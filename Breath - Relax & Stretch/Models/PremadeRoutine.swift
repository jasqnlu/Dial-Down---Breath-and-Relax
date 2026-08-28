import Foundation

// MARK: - PremadeRoutine
// Curated, single-session routine templates — free, like everything else in
// the app. Tapping one (in PremadeRoutinesView or TodayView's horizontal
// row) never creates a Routine by itself: it opens RoutineBuilderView
// pre-seeded with these exercises and this title, exactly like every other
// path into that screen (a picking session, editing an existing routine).
// Nothing is persisted until the user hits Save there.
//
// Exercise names are resolved against the live Exercise table at render
// time, same pattern GoalMeta and the deleted ContentPack used — see
// CuratedContentIntegrityTests for the safety net that keeps these names
// honest against SeedData.json.

struct PremadeRoutine: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let exerciseNames: [String]

    /// Resolves `exerciseNames` against the live catalog, in order,
    /// skipping any name that doesn't currently exist.
    func resolvedExercises(in exercises: [Exercise]) -> [Exercise] {
        let byName = Dictionary(grouping: exercises, by: \.name).compactMapValues(\.first)
        return exerciseNames.compactMap { byName[$0] }
    }

    static let all: [PremadeRoutine] = [
        PremadeRoutine(
            id: "pack_deskworker",
            title: "Office Stretch",
            summary: "Targeted relief for neck, shoulders, wrists, and lower back from sitting all day.",
            icon: "desktopcomputer",
            exerciseNames: [
                "Chin Tuck (Forward Head Reset)",
                "Seated Neck Rolls",
                "Shoulder Roll",
                "Reverse Prayer Stretch",
                "Wrist Circles",
                "Wrist & Forearm Release",
                "Left Wrist Flexor Stretch",
                "Right Wrist Flexor Stretch",
                "Left Cross-Body Rear Delt Stretch",
                "Right Cross-Body Rear Delt Stretch",
                "Left Overhead Triceps Stretch",
                "Right Overhead Triceps Stretch",
                "Left Seated Spinal Twist",
                "Right Seated Spinal Twist",
                "Left Standing Reach-Through Twist",
                "Right Standing Reach-Through Twist",
                "Doorway Shoulder & Chest Opener",
            ]
        ),
        PremadeRoutine(
            id: "pack_athlete_recovery",
            title: "Athletic Recovery",
            summary: "Deeper lower-body stretches and breathing for active recovery days.",
            icon: "figure.run",
            exerciseNames: [
                "Standing Hamstring Stretch",
                "Left Seated Hamstring Stretch",
                "Right Seated Hamstring Stretch",
                "Left Seated Figure-Four Stretch",
                "Right Seated Figure-Four Stretch",
                "Bridge Pose",
                "Pelvic Tilt",
                "Cat-Cow Flow",
                "4-7-8 Breathing",
                "Left Standing Quad Stretch",
                "Right Standing Quad Stretch",
                "Left Standing Figure-4 Stretch",
                "Right Standing Figure-4 Stretch",
                "Left Standing Hip-Flexor Stretch (Foot Elevated)",
                "Right Standing Hip-Flexor Stretch (Foot Elevated)",
                "Calf Stretch at Wall (Straight-Knee)",
                "Bent-Knee Wall Calf Stretch (Soleus)",
            ]
        ),
        PremadeRoutine(
            id: "pack_bettersleep",
            title: "Better Sleep & Breathing",
            summary: "Wind-down breathing techniques and gentle stretches to help you fall asleep faster.",
            icon: "moon.stars.fill",
            exerciseNames: [
                "Extended Exhale Breathing",
                "Counting Down Sleep Breath",
                "Cooling Sitali Breath",
                "Three-Part Breath (Dirga Pranayama)",
                "Body Scan Breathing",
                "Segmented Exhale Breathing (Viloma)",
                "Progressive Relaxation Breath",
                "Left-Nostril Calming Breath (Chandra Bhedana)",
                "Legs Up the Wall",
                "Child's Pose",
                "Cat-Cow Flow",
            ]
        ),
        PremadeRoutine(
            id: "pack_runner",
            title: "Runner's Warm-Up & Cooldown",
            summary: "Dynamic mobility to open up before a run, plus targeted stretches to cool down after.",
            icon: "figure.run.circle.fill",
            exerciseNames: [
                "Standing IT Band Side Stretch (Left)",
                "Standing IT Band Side Stretch (Right)",
                "Dynamic Standing Leg Swings",
                "Standing Hip Circles",
                "Runner's Lunge with Rotation (Left)",
                "Runner's Lunge with Rotation (Right)",
                "Standing Ankle Dorsiflexion Stretch (Left)",
                "Standing Ankle Dorsiflexion Stretch (Right)",
                "Runner's Calf Stretch (Staggered Stance)",
                "Ankle Alphabet",
                "Standing Hamstring Stretch",
                "Left Standing Quad Stretch",
                "Right Standing Quad Stretch",
            ]
        ),
        // Unlike the other four (hand-curated, verified against SeedData.json
        // when they were ContentPack entries), this one is built from
        // GoalMeta's pools at definition time rather than hand-typed — every
        // name it can produce is already covered by
        // everyGoalMetaExerciseNameExistsInSeedCatalog, so there's no new
        // hand-typed-name drift risk to introduce.
        //
        // One name per goal (in GoalMeta.all's order), deduped, so the result
        // is a genuine cross-goal sweep rather than an alphabetical slice
        // that happens to cluster on one or two goals. Falls back to a
        // goal's second name if its first collides with an earlier goal's
        // pick, rather than dropping the goal or reintroducing a global sort.
        {
            var seen = Set<String>()
            var picks: [String] = []
            for goal in GoalMeta.all {
                if let name = goal.exerciseNames.first(where: { !seen.contains($0) }) {
                    seen.insert(name)
                    picks.append(name)
                }
            }
            return PremadeRoutine(
                id: "premade_full_body_reset",
                title: "Full Body Reset",
                summary: "No particular theme — a balanced sweep across flexibility, breathing, and posture.",
                icon: "sparkles",
                exerciseNames: picks
            )
        }(),
    ]
}
