import Foundation

/// The kept, stretchable joint regions the Body Map resolves as tappable areas
/// (distinct from `MuscleGroup` — joints carry their own hit volumes). Tapping
/// a joint surfaces exercises tagged with the joint's own raw value directly
/// (dedicated joint-mobility content), falling back to their crossing muscles'
/// stretches — see `RegionExerciseResolver`. Names are chosen NOT to collide
/// with any `MuscleGroup` raw value (hence `Shoulder Joint`, since
/// `Left/Right Shoulder` is the deltoid group).
/// Left = the figure's own left = world +x.
enum JointRegion: String, CaseIterable {
    case neck = "Neck"
    case lowerSpine = "Lower Spine"
    case leftShoulder = "Left Shoulder Joint", rightShoulder = "Right Shoulder Joint"
    case leftHip = "Left Hip",                 rightHip = "Right Hip"

    /// The 6 region names.
    static let allNames: Set<String> = Set(allCases.map(\.rawValue))

    /// Whether `name` is one of the joint regions.
    static func isJoint(_ name: String) -> Bool { allNames.contains(name) }
}
