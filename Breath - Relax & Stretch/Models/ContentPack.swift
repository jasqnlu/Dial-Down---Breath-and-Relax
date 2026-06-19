import Foundation

// MARK: - ContentPack
// One-time-purchase exercise bundles. id matches a StoreManager.ProductID
// non-consumable product. Exercise names are resolved against the live
// Exercise table at render time, same pattern as GoalMeta.

struct ContentPack: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let exerciseNames: [String]

    static let all: [ContentPack] = [
        ContentPack(
            id: StoreManager.ProductID.deskWorkerPack,
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
            id: StoreManager.ProductID.athleteRecoveryPack,
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
    ]
}
