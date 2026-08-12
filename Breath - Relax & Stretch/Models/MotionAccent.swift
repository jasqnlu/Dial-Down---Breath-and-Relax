import Foundation

/// The visual cue for exercises whose defining movement is circular. This is
/// intentionally narrower than `ExerciseCueStyle.repeatMotion`: alternating
/// sides and other repeated movements do not imply a circular path.
enum MotionAccent: Equatable {
    case none
    case circular

    static func resolve(for exercise: Exercise) -> MotionAccent {
        if let seedID = exercise.seedID, circularSeedIDs.contains(seedID) {
            return .circular
        }
        return circularNames.contains(exercise.name) ? .circular : .none
    }

    private static let circularSeedIDs: Set<String> = [
        "13c14934-a407-5a14-8c90-6f7d85d523dc", // Seated Neck Rolls
        "3751fbd0-f483-527e-aa28-9857095d7a51", // Shoulder Roll
        "b1d30153-3e92-5934-bca8-19a6a28ed83d", // Wrist Circles
        "fe4dea3b-f897-5d26-bd98-456d2a9f96ca", // Ankle Alphabet
        "0510c366-18e8-4ff1-a341-6a19976e50a4", // Standing Hip Circles
    ]

    /// Name fallback keeps the accent working for pre-migration rows and
    /// makes previews/tests readable without constructing seed metadata.
    private static let circularNames: Set<String> = [
        "Shoulder Roll", "Seated Neck Rolls", "Neck Rolls", "Wrist Circles",
        "Hip Circles", "Standing Hip Circles", "Ankle Alphabet"
    ]
}
