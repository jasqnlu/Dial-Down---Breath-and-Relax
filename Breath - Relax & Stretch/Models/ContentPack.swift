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
            exerciseNames: [
                "Chin Tuck (Forward Head Reset)",
                "Seated Neck Rolls",
                "Shoulder Roll",
                "Doorway Chest Opener",
                "Thoracic Open Book",
                "Reverse Prayer Hands",
                "Wrist Flexor Stretch",
                "Wrist Circles",
                "Wrist & Forearm Release",
                "Cross-Body Arm Stretch",
                "Triceps & Elbow Stretch",
                "Seated Spinal Twist",
            ]
        ),
        ContentPack(
            id: "pack_athlete_recovery",
            title: "Athlete Recovery Pack",
            summary: "Deeper lower-body stretches and breathing for active recovery days.",
            icon: "figure.run",
            exerciseNames: [
                "Standing Quad Stretch",
                "Standing Hamstring Stretch",
                "Seated Hamstring Stretch",
                "Hip Flexor Stretch",
                "Seated Figure-Four Stretch",
                "Figure-4 Glute Stretch",
                "Glute Bridge",
                "Pelvic Tilt",
                "Cat-Cow Flow",
                "Calf Stretch at Wall",
                "Standing Calf Stretch",
                "4-7-8 Breathing",
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
