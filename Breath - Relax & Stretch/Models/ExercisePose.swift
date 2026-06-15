import Foundation

/// A single snapshot of the stick figure's joint positions.
struct ExercisePose: Codable, Hashable {
    /// Joint name → [x, y] in normalised 0–1 figure coordinates.
    var joints: [String: [Double]]
    var holdSeconds: Double
    var cue: String?
}

/// Constants for the stick figure's 15 joints, 14 bones, and body-part highlight mapping.
enum StickJoint {
    static let all: [String] = [
        "head", "neck",
        "leftShoulder", "rightShoulder",
        "leftElbow",    "rightElbow",
        "leftWrist",    "rightWrist",
        "hip",
        "leftKnee",  "rightKnee",
        "leftAnkle", "rightAnkle",
        "leftFoot",  "rightFoot"
    ]

    static let bones: [(String, String)] = [
        ("head",          "neck"),
        ("neck",          "leftShoulder"),  ("neck",          "rightShoulder"),
        ("leftShoulder",  "leftElbow"),     ("rightShoulder", "rightElbow"),
        ("leftElbow",     "leftWrist"),     ("rightElbow",    "rightWrist"),
        ("neck",          "hip"),
        ("hip",           "leftKnee"),      ("hip",           "rightKnee"),
        ("leftKnee",      "leftAnkle"),     ("rightKnee",     "rightAnkle"),
        ("leftAnkle",     "leftFoot"),      ("rightAnkle",    "rightFoot"),
    ]

    /// Maps each bone to the body-part names it represents for highlight purposes.
    static let boneBodyParts: [(a: String, b: String, parts: Set<String>)] = [
        ("head",          "neck",           ["Head", "Neck"]),
        ("neck",          "leftShoulder",   ["Neck", "Left Shoulder",  "Upper Back", "Chest"]),
        ("neck",          "rightShoulder",  ["Neck", "Right Shoulder", "Upper Back", "Chest"]),
        ("leftShoulder",  "leftElbow",      ["Left Shoulder",  "Left Arm"]),
        ("rightShoulder", "rightElbow",     ["Right Shoulder", "Right Arm"]),
        ("leftElbow",     "leftWrist",      ["Left Arm",  "Left Elbow",  "Left Forearm",  "Left Hand"]),
        ("rightElbow",    "rightWrist",     ["Right Arm", "Right Elbow", "Right Forearm", "Right Hand"]),
        ("neck",          "hip",            ["Upper Back", "Lower Back", "Core", "Chest"]),
        ("hip",           "leftKnee",       ["Hips", "Left Leg",  "Left Hamstring",  "Glutes"]),
        ("hip",           "rightKnee",      ["Hips", "Right Leg", "Right Hamstring", "Glutes"]),
        ("leftKnee",      "leftAnkle",      ["Left Leg",  "Left Knee",  "Left Calf",  "Left Shin"]),
        ("rightKnee",     "rightAnkle",     ["Right Leg", "Right Knee", "Right Calf", "Right Shin"]),
        ("leftAnkle",     "leftFoot",       ["Left Foot",  "Left Ankle",  "Left Shin",  "Left Calf"]),
        ("rightAnkle",    "rightFoot",      ["Right Foot", "Right Ankle", "Right Shin", "Right Calf"]),
    ]
}
