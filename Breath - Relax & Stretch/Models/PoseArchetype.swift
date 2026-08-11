import CoreGraphics

/// Names one distinct stick-figure body position/movement. The classifier
/// in PoseArchetypeMapping.swift routes every Exercise to exactly one of
/// these. Grow this list by adding a case here + an entry in
/// PoseArchetypeLibrary.all + a classifier rule — everything else (the
/// renderer, the completeness tests) picks new cases up automatically.
enum PoseArchetypeID: String, CaseIterable {
    case seatedTwist, seatedNeck, seatedForwardFold, seatedFigureFour, seatedNeutral
    case standingNeutral, standingForwardFold, standingTwist, standingSideBend
    case supineNeutral, supineKneeToChest, bridge
    case quadruped, prone, childsPose, breathSeated
}

/// Hand-authored stick-figure geometry for one archetype, in normalized
/// 0–1 figure space (same convention as the app's ExercisePose/StickJoint
/// model). `PoseGlyphIcon` scales every coordinate by its rendered size.
///
/// `limbs` is a list of continuous path chains — each inner array is drawn
/// as ONE joined stroke (spine, left arm, right arm, left leg, right leg)
/// so bends never show a seam. `jointDots` are the small filled circles
/// drawn at every bend (elbows, knees, shoulders, hips); the head is drawn
/// separately, larger, at `headCenter`/`headRadius`. `seatRect` is nil for
/// standing/supine/prone/quadruped archetypes; seated ones get a flat bar
/// drawn behind the figure.
struct PoseArchetype {
    let headCenter: CGPoint
    let headRadius: CGFloat
    let limbs: [[CGPoint]]
    let jointDots: [CGPoint]
    let seatRect: CGRect?
}

enum PoseArchetypeLibrary {
    static let all: [PoseArchetypeID: PoseArchetype] = [
        .seatedTwist: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.22), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.50, y: 0.62)],
                [CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.74, y: 0.44)],
                [CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.18, y: 0.56)],
                [CGPoint(x: 0.74, y: 0.44), CGPoint(x: 0.88, y: 0.60)],
                [CGPoint(x: 0.50, y: 0.62), CGPoint(x: 0.30, y: 0.82), CGPoint(x: 0.18, y: 0.90)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.74, y: 0.44),
                CGPoint(x: 0.18, y: 0.56), CGPoint(x: 0.88, y: 0.60), CGPoint(x: 0.50, y: 0.62),
                CGPoint(x: 0.30, y: 0.82), CGPoint(x: 0.72, y: 0.80),
            ],
            seatRect: CGRect(x: 0.14, y: 0.64, width: 0.72, height: 0.09)
        ),
        .seatedNeck: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.22), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.50, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.26, y: 0.46), CGPoint(x: 0.14, y: 0.40)],
                [CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.74, y: 0.46), CGPoint(x: 0.86, y: 0.40)],
                [CGPoint(x: 0.50, y: 0.58), CGPoint(x: 0.38, y: 0.74), CGPoint(x: 0.34, y: 0.90)],
                [CGPoint(x: 0.50, y: 0.58), CGPoint(x: 0.62, y: 0.74), CGPoint(x: 0.66, y: 0.90)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.26, y: 0.46),
                CGPoint(x: 0.74, y: 0.46), CGPoint(x: 0.50, y: 0.58), CGPoint(x: 0.38, y: 0.74),
                CGPoint(x: 0.62, y: 0.74),
            ],
            seatRect: CGRect(x: 0.14, y: 0.60, width: 0.72, height: 0.09)
        ),
        .seatedForwardFold: PoseArchetype(
            headCenter: CGPoint(x: 0.28, y: 0.44), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.50, y: 0.60)],
                [CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.40, y: 0.66), CGPoint(x: 0.46, y: 0.78)],
                [CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.46, y: 0.68), CGPoint(x: 0.54, y: 0.80)],
                [CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.70, y: 0.62), CGPoint(x: 0.90, y: 0.62)],
                [CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.72, y: 0.66), CGPoint(x: 0.92, y: 0.68)],
            ],
            jointDots: [
                CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.40, y: 0.66), CGPoint(x: 0.46, y: 0.68),
                CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.70, y: 0.62), CGPoint(x: 0.72, y: 0.66),
            ],
            seatRect: CGRect(x: 0.14, y: 0.58, width: 0.40, height: 0.08)
        ),
        .seatedFigureFour: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42), CGPoint(x: 0.34, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.66, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.68, y: 0.58), CGPoint(x: 0.82, y: 0.52)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.36, y: 0.68), CGPoint(x: 0.30, y: 0.82)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42),
                CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.68, y: 0.58),
                CGPoint(x: 0.36, y: 0.68),
            ],
            seatRect: CGRect(x: 0.14, y: 0.58, width: 0.72, height: 0.09)
        ),
        .seatedNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42), CGPoint(x: 0.34, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.66, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.34, y: 0.60), CGPoint(x: 0.20, y: 0.62)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.66, y: 0.60), CGPoint(x: 0.80, y: 0.62)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42),
                CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.34, y: 0.60),
                CGPoint(x: 0.66, y: 0.60),
            ],
            seatRect: CGRect(x: 0.14, y: 0.58, width: 0.72, height: 0.09)
        ),
        .standingNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.52)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.34, y: 0.42), CGPoint(x: 0.28, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.66, y: 0.42), CGPoint(x: 0.72, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.42, y: 0.74), CGPoint(x: 0.40, y: 0.92)],
                [CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.58, y: 0.74), CGPoint(x: 0.60, y: 0.92)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.34, y: 0.42),
                CGPoint(x: 0.66, y: 0.42), CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.42, y: 0.74),
                CGPoint(x: 0.58, y: 0.74),
            ],
            seatRect: nil
        ),
        .standingForwardFold: PoseArchetype(
            headCenter: CGPoint(x: 0.32, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.56, y: 0.46)],
                [CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.30, y: 0.52), CGPoint(x: 0.34, y: 0.78)],
                [CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.38, y: 0.56), CGPoint(x: 0.42, y: 0.82)],
                [CGPoint(x: 0.56, y: 0.46), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.18, y: 0.70)],
                [CGPoint(x: 0.56, y: 0.46), CGPoint(x: 0.78, y: 0.66), CGPoint(x: 0.94, y: 0.70)],
            ],
            jointDots: [
                CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.30, y: 0.52), CGPoint(x: 0.38, y: 0.56),
                CGPoint(x: 0.56, y: 0.46), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.78, y: 0.66),
            ],
            seatRect: nil
        ),
        .standingTwist: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.68, y: 0.36), CGPoint(x: 0.84, y: 0.30)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.16, y: 0.48)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76), CGPoint(x: 0.40, y: 0.94)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.58, y: 0.76), CGPoint(x: 0.60, y: 0.94)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.68, y: 0.36),
                CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76),
                CGPoint(x: 0.58, y: 0.76),
            ],
            seatRect: nil
        ),
        .standingSideBend: PoseArchetype(
            headCenter: CGPoint(x: 0.62, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.58, y: 0.26), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.76, y: 0.20), CGPoint(x: 0.92, y: 0.14)],
                [CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.46, y: 0.42), CGPoint(x: 0.40, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76), CGPoint(x: 0.40, y: 0.94)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.58, y: 0.76), CGPoint(x: 0.60, y: 0.94)],
            ],
            jointDots: [
                CGPoint(x: 0.58, y: 0.26), CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.76, y: 0.20),
                CGPoint(x: 0.46, y: 0.42), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76),
                CGPoint(x: 0.58, y: 0.76),
            ],
            seatRect: nil
        ),
        .supineNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.18, y: 0.50), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.62, y: 0.50)],
                [CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.34, y: 0.68), CGPoint(x: 0.34, y: 0.82)],
                [CGPoint(x: 0.40, y: 0.54), CGPoint(x: 0.40, y: 0.70), CGPoint(x: 0.40, y: 0.84)],
                [CGPoint(x: 0.62, y: 0.50), CGPoint(x: 0.80, y: 0.52), CGPoint(x: 0.96, y: 0.52)],
                [CGPoint(x: 0.62, y: 0.50), CGPoint(x: 0.80, y: 0.58), CGPoint(x: 0.96, y: 0.60)],
            ],
            jointDots: [
                CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.40, y: 0.54),
                CGPoint(x: 0.62, y: 0.50), CGPoint(x: 0.80, y: 0.52), CGPoint(x: 0.80, y: 0.58),
            ],
            seatRect: nil
        ),
        .supineKneeToChest: PoseArchetype(
            headCenter: CGPoint(x: 0.18, y: 0.50), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.56, y: 0.50)],
                [CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.44, y: 0.44), CGPoint(x: 0.52, y: 0.36)],
                [CGPoint(x: 0.40, y: 0.54), CGPoint(x: 0.48, y: 0.46), CGPoint(x: 0.56, y: 0.40)],
                [CGPoint(x: 0.56, y: 0.50), CGPoint(x: 0.52, y: 0.32), CGPoint(x: 0.44, y: 0.20)],
                [CGPoint(x: 0.56, y: 0.50), CGPoint(x: 0.76, y: 0.52), CGPoint(x: 0.94, y: 0.52)],
            ],
            jointDots: [
                CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.40, y: 0.54),
                CGPoint(x: 0.56, y: 0.50), CGPoint(x: 0.52, y: 0.32), CGPoint(x: 0.76, y: 0.52),
            ],
            seatRect: nil
        ),
        .bridge: PoseArchetype(
            headCenter: CGPoint(x: 0.18, y: 0.62), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.30, y: 0.62), CGPoint(x: 0.56, y: 0.44)],
                [CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.34, y: 0.78), CGPoint(x: 0.34, y: 0.90)],
                [CGPoint(x: 0.40, y: 0.66), CGPoint(x: 0.40, y: 0.80), CGPoint(x: 0.40, y: 0.92)],
                [CGPoint(x: 0.56, y: 0.44), CGPoint(x: 0.60, y: 0.64), CGPoint(x: 0.60, y: 0.82)],
                [CGPoint(x: 0.56, y: 0.44), CGPoint(x: 0.68, y: 0.62), CGPoint(x: 0.72, y: 0.80)],
            ],
            jointDots: [
                CGPoint(x: 0.30, y: 0.62), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.40, y: 0.66),
                CGPoint(x: 0.56, y: 0.44), CGPoint(x: 0.60, y: 0.64), CGPoint(x: 0.68, y: 0.62),
            ],
            seatRect: nil
        ),
        .quadruped: PoseArchetype(
            headCenter: CGPoint(x: 0.82, y: 0.30), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.30, y: 0.44)],
                [CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.74, y: 0.56), CGPoint(x: 0.76, y: 0.76)],
                [CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.66, y: 0.58), CGPoint(x: 0.64, y: 0.78)],
                [CGPoint(x: 0.30, y: 0.44), CGPoint(x: 0.28, y: 0.64), CGPoint(x: 0.26, y: 0.82)],
                [CGPoint(x: 0.30, y: 0.44), CGPoint(x: 0.20, y: 0.62), CGPoint(x: 0.14, y: 0.80)],
            ],
            jointDots: [
                CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.74, y: 0.56), CGPoint(x: 0.66, y: 0.58),
                CGPoint(x: 0.30, y: 0.44), CGPoint(x: 0.28, y: 0.64), CGPoint(x: 0.20, y: 0.62),
            ],
            seatRect: nil
        ),
        .prone: PoseArchetype(
            headCenter: CGPoint(x: 0.86, y: 0.34), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.30, y: 0.56)],
                [CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.78, y: 0.58), CGPoint(x: 0.70, y: 0.70)],
                [CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.66, y: 0.56), CGPoint(x: 0.72, y: 0.68)],
                [CGPoint(x: 0.30, y: 0.56), CGPoint(x: 0.16, y: 0.58), CGPoint(x: 0.04, y: 0.58)],
                [CGPoint(x: 0.30, y: 0.56), CGPoint(x: 0.16, y: 0.62), CGPoint(x: 0.04, y: 0.64)],
            ],
            jointDots: [
                CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.78, y: 0.58), CGPoint(x: 0.66, y: 0.56),
                CGPoint(x: 0.30, y: 0.56), CGPoint(x: 0.16, y: 0.58), CGPoint(x: 0.16, y: 0.62),
            ],
            seatRect: nil
        ),
        .childsPose: PoseArchetype(
            headCenter: CGPoint(x: 0.82, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.28, y: 0.58)],
                [CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.86, y: 0.20), CGPoint(x: 0.96, y: 0.12)],
                [CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.92, y: 0.32), CGPoint(x: 0.98, y: 0.24)],
                [CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.18, y: 0.72), CGPoint(x: 0.28, y: 0.86)],
                [CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.36, y: 0.76), CGPoint(x: 0.44, y: 0.88)],
            ],
            jointDots: [
                CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.86, y: 0.20), CGPoint(x: 0.92, y: 0.32),
                CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.18, y: 0.72), CGPoint(x: 0.36, y: 0.76),
            ],
            seatRect: nil
        ),
        .breathSeated: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.38, y: 0.44), CGPoint(x: 0.36, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.64, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.30, y: 0.60), CGPoint(x: 0.62, y: 0.66)],
                [CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.70, y: 0.60), CGPoint(x: 0.38, y: 0.68)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.38, y: 0.44),
                CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.30, y: 0.60),
                CGPoint(x: 0.70, y: 0.60),
            ],
            seatRect: CGRect(x: 0.14, y: 0.60, width: 0.72, height: 0.09)
        ),
    ]
}
