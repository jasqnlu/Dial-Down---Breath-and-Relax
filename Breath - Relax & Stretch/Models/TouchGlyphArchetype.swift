import CoreGraphics

/// Geometry for one ExerciseCategory's "touch glyph" — a standing figure
/// with one arm bent to touch the body region that category represents.
/// Separate from PoseArchetype (Models/PoseArchetype.swift): that library
/// encodes whole-body stretch positions for one exercise; a category node
/// represents an entire body region, which no single stretch pose
/// communicates cleanly. Shared base skeleton (head/spine/legs/resting
/// arm) is identical across all 8; only the pointing arm and contact point
/// differ per category.
struct TouchGlyphArchetype {
    let headCenter: CGPoint
    let headRadius: CGFloat
    let spine: [CGPoint]
    let legLeft: [CGPoint]
    let legRight: [CGPoint]
    let restingArm: [CGPoint]
    let pointingArm: [CGPoint]
    let contactPoint: CGPoint
}

enum TouchGlyphLibrary {
    private static let headCenter = CGPoint(x: 0.50, y: 0.16)
    private static let headRadius: CGFloat = 0.09
    private static let spine = [CGPoint(x: 0.50, y: 0.25), CGPoint(x: 0.50, y: 0.55)]
    private static let legLeft = [CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.42, y: 0.78), CGPoint(x: 0.40, y: 0.95)]
    private static let legRight = [CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.58, y: 0.78), CGPoint(x: 0.60, y: 0.95)]
    private static let restingArm = [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.36, y: 0.42), CGPoint(x: 0.32, y: 0.58)]

    private static func archetype(pointingArm: [CGPoint], contactPoint: CGPoint) -> TouchGlyphArchetype {
        TouchGlyphArchetype(
            headCenter: headCenter, headRadius: headRadius, spine: spine,
            legLeft: legLeft, legRight: legRight, restingArm: restingArm,
            pointingArm: pointingArm, contactPoint: contactPoint
        )
    }

    static let all: [ExerciseCategory: TouchGlyphArchetype] = [
        // Reaches UP toward the head — the only upward gesture in the set.
        .neck: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.72, y: 0.22), CGPoint(x: 0.62, y: 0.13)],
            contactPoint: CGPoint(x: 0.62, y: 0.12)
        ),
        // Sweeps nearly the full width horizontally at shoulder height:
        // elbow far right, hand far left. Wide and flat, not diagonal.
        .shoulders: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.74, y: 0.22), CGPoint(x: 0.30, y: 0.24)],
            contactPoint: CGPoint(x: 0.29, y: 0.24)
        ),
        // Deliberately the shortest reach of all 8 — barely leaves the
        // shoulder. Its distinctiveness is length, not direction.
        .chest: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.54, y: 0.30), CGPoint(x: 0.50, y: 0.33)],
            contactPoint: CGPoint(x: 0.50, y: 0.34)
        ),
        .back: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.66, y: 0.44), CGPoint(x: 0.44, y: 0.58)],
            contactPoint: CGPoint(x: 0.47, y: 0.59)
        ),
        // Elbow flares LEFT before the hand returns to center — a mirror of
        // .back's right-swinging elbow, so the two read differently even
        // though their contact points land at similar heights.
        .core: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.40, y: 0.38), CGPoint(x: 0.48, y: 0.50)],
            contactPoint: CGPoint(x: 0.48, y: 0.51)
        ),
        .arms: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.42, y: 0.34), CGPoint(x: 0.34, y: 0.42)],
            contactPoint: CGPoint(x: 0.32, y: 0.44)
        ),
        // Swings wide to the RIGHT and stays there — the opposite side from
        // .back's left-leaning lower-back reach (contact x=0.47).
        .hipsGlutes: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.78, y: 0.42), CGPoint(x: 0.70, y: 0.52)],
            contactPoint: CGPoint(x: 0.70, y: 0.53)
        ),
        .legs: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.58, y: 0.46), CGPoint(x: 0.50, y: 0.63)],
            contactPoint: CGPoint(x: 0.50, y: 0.64)
        ),
    ]
}
