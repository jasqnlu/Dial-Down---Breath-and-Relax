import Foundation

/// The kept, stretchable joint regions the Body Map resolves as tappable areas
/// (distinct from `MuscleGroup` — joints carry their own hit volumes and, until
/// dedicated joint-mobility content lands, resolve to their crossing muscles'
/// stretches). Names are chosen NOT to collide with any `MuscleGroup` raw value
/// (hence `Shoulder Joint`, since `Left/Right Shoulder` is the deltoid group).
/// Left = the figure's own left = world +x.
enum JointRegion: String, CaseIterable {
    case neck = "Neck"
    case upperSpine = "Upper Spine"
    case lowerSpine = "Lower Spine"
    case leftShoulder = "Left Shoulder Joint",   rightShoulder = "Right Shoulder Joint"
    case leftElbow = "Left Elbow",               rightElbow = "Right Elbow"
    case leftWrist = "Left Wrist",               rightWrist = "Right Wrist"
    case leftHip = "Left Hip",                   rightHip = "Right Hip"
    case leftKnee = "Left Knee",                 rightKnee = "Right Knee"
    case leftAnkle = "Left Ankle",               rightAnkle = "Right Ankle"

    /// The 15 region names.
    static let allNames: Set<String> = Set(allCases.map(\.rawValue))

    /// Whether `name` is one of the joint regions.
    static func isJoint(_ name: String) -> Bool { allNames.contains(name) }
}
