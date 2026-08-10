import Foundation

// MARK: - ContentPack
// Themed exercise bundles, free like the rest of the app (these were once
// paid packs; the ids are retained so existing references stay stable).
// Exercise names are resolved against the live Exercise table at render
// time, same pattern as GoalMeta.

struct ContentPack: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let exerciseNames: [String]

    static let all: [ContentPack] = [
        ContentPack(
            id: "pack_deskworker",
            title: "Desk Worker Pack",
            summary: "Targeted relief for neck, shoulders, wrists, and lower back from sitting all day.",
            icon: "desktopcomputer",
            // No-equipment stretches first, then the one exercise that needs a
            // doorway. Names below are matched against SeedData.json, which
            // lateralized most of these into Left/Right pairs after this pack
            // was first written — see CuratedContentIntegrityTests.
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
        ContentPack(
            id: "pack_athlete_recovery",
            title: "Athlete Recovery Pack",
            summary: "Deeper lower-body stretches and breathing for active recovery days.",
            icon: "figure.run",
            // No-equipment stretches first, then the ones that need a wall,
            // chair, or step for balance/support. Names matched against
            // SeedData.json — see CuratedContentIntegrityTests.
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
        ContentPack(
            id: "pack_bettersleep",
            title: "Better Sleep & Breathing Pack",
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
        ContentPack(
            id: "pack_runner",
            title: "Runner's Warm-Up & Cooldown Pack",
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
    ]
}
