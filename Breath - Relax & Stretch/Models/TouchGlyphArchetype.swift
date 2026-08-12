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
        .neck: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.62, y: 0.30), CGPoint(x: 0.56, y: 0.22)],
            contactPoint: CGPoint(x: 0.56, y: 0.225)
        ),
        .shoulders: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.60, y: 0.36), CGPoint(x: 0.42, y: 0.28)],
            contactPoint: CGPoint(x: 0.42, y: 0.28)
        ),
        .chest: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.58, y: 0.34), CGPoint(x: 0.46, y: 0.37)],
            contactPoint: CGPoint(x: 0.48, y: 0.37)
        ),
        .back: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.66, y: 0.44), CGPoint(x: 0.44, y: 0.58)],
            contactPoint: CGPoint(x: 0.47, y: 0.59)
        ),
        .core: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.56, y: 0.34), CGPoint(x: 0.48, y: 0.42)],
            contactPoint: CGPoint(x: 0.49, y: 0.43)
        ),
        .arms: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.42, y: 0.34), CGPoint(x: 0.34, y: 0.42)],
            contactPoint: CGPoint(x: 0.32, y: 0.44)
        ),
        .hipsGlutes: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.60, y: 0.42), CGPoint(x: 0.58, y: 0.53)],
            contactPoint: CGPoint(x: 0.58, y: 0.54)
        ),
        .legs: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.58, y: 0.46), CGPoint(x: 0.50, y: 0.63)],
            contactPoint: CGPoint(x: 0.50, y: 0.64)
        ),
    ]
}
