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
            headCenter: CGPoint(x: 0.500, y: 0.248), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.500, y: 0.356), CGPoint(x: 0.500, y: 0.608)],
                [CGPoint(x: 0.320, y: 0.410), CGPoint(x: 0.500, y: 0.356), CGPoint(x: 0.716, y: 0.446)],
                [CGPoint(x: 0.320, y: 0.410), CGPoint(x: 0.212, y: 0.554)],
                [CGPoint(x: 0.716, y: 0.446), CGPoint(x: 0.842, y: 0.590)],
                [CGPoint(x: 0.500, y: 0.608), CGPoint(x: 0.320, y: 0.788), CGPoint(x: 0.212, y: 0.860)],
            ],
            jointDots: [
                CGPoint(x: 0.500, y: 0.356), CGPoint(x: 0.320, y: 0.410), CGPoint(x: 0.716, y: 0.446),
                CGPoint(x: 0.212, y: 0.554), CGPoint(x: 0.842, y: 0.590), CGPoint(x: 0.500, y: 0.608),
                CGPoint(x: 0.320, y: 0.788), CGPoint(x: 0.698, y: 0.770),
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
            headCenter: CGPoint(x: 0.329, y: 0.177), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.329, y: 0.272), CGPoint(x: 0.557, y: 0.462)],
                [CGPoint(x: 0.329, y: 0.272), CGPoint(x: 0.310, y: 0.519), CGPoint(x: 0.348, y: 0.766)],
                [CGPoint(x: 0.329, y: 0.272), CGPoint(x: 0.386, y: 0.557), CGPoint(x: 0.424, y: 0.804)],
                [CGPoint(x: 0.557, y: 0.462), CGPoint(x: 0.348, y: 0.652), CGPoint(x: 0.196, y: 0.690)],
                [CGPoint(x: 0.557, y: 0.462), CGPoint(x: 0.766, y: 0.652), CGPoint(x: 0.918, y: 0.690)],
            ],
            jointDots: [
                CGPoint(x: 0.329, y: 0.272), CGPoint(x: 0.310, y: 0.519), CGPoint(x: 0.386, y: 0.557),
                CGPoint(x: 0.557, y: 0.462), CGPoint(x: 0.348, y: 0.652), CGPoint(x: 0.766, y: 0.652),
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
            headCenter: CGPoint(x: 0.600, y: 0.218), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.566, y: 0.301), CGPoint(x: 0.500, y: 0.533)],
                [CGPoint(x: 0.566, y: 0.334), CGPoint(x: 0.716, y: 0.251), CGPoint(x: 0.849, y: 0.201)],
                [CGPoint(x: 0.566, y: 0.334), CGPoint(x: 0.467, y: 0.434), CGPoint(x: 0.417, y: 0.550)],
                [CGPoint(x: 0.500, y: 0.533), CGPoint(x: 0.434, y: 0.716), CGPoint(x: 0.417, y: 0.865)],
                [CGPoint(x: 0.500, y: 0.533), CGPoint(x: 0.566, y: 0.716), CGPoint(x: 0.583, y: 0.865)],
            ],
            jointDots: [
                CGPoint(x: 0.566, y: 0.301), CGPoint(x: 0.566, y: 0.334), CGPoint(x: 0.716, y: 0.251),
                CGPoint(x: 0.467, y: 0.434), CGPoint(x: 0.500, y: 0.533), CGPoint(x: 0.434, y: 0.716),
                CGPoint(x: 0.566, y: 0.716),
            ],
            seatRect: nil
        ),
        .supineNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.186, y: 0.500), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.304, y: 0.500), CGPoint(x: 0.618, y: 0.500)],
                [CGPoint(x: 0.343, y: 0.539), CGPoint(x: 0.343, y: 0.676), CGPoint(x: 0.343, y: 0.814)],
                [CGPoint(x: 0.402, y: 0.539), CGPoint(x: 0.402, y: 0.696), CGPoint(x: 0.402, y: 0.833)],
                [CGPoint(x: 0.618, y: 0.500), CGPoint(x: 0.794, y: 0.520), CGPoint(x: 0.951, y: 0.520)],
                [CGPoint(x: 0.618, y: 0.500), CGPoint(x: 0.794, y: 0.578), CGPoint(x: 0.951, y: 0.598)],
            ],
            jointDots: [
                CGPoint(x: 0.304, y: 0.500), CGPoint(x: 0.343, y: 0.539), CGPoint(x: 0.402, y: 0.539),
                CGPoint(x: 0.618, y: 0.500), CGPoint(x: 0.794, y: 0.520), CGPoint(x: 0.794, y: 0.578),
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
            headCenter: CGPoint(x: 0.814, y: 0.304), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.716, y: 0.363), CGPoint(x: 0.304, y: 0.441)],
                [CGPoint(x: 0.716, y: 0.363), CGPoint(x: 0.735, y: 0.559), CGPoint(x: 0.755, y: 0.755)],
                [CGPoint(x: 0.716, y: 0.363), CGPoint(x: 0.657, y: 0.578), CGPoint(x: 0.637, y: 0.774)],
                [CGPoint(x: 0.304, y: 0.441), CGPoint(x: 0.284, y: 0.637), CGPoint(x: 0.265, y: 0.814)],
                [CGPoint(x: 0.304, y: 0.441), CGPoint(x: 0.206, y: 0.618), CGPoint(x: 0.147, y: 0.794)],
            ],
            jointDots: [
                CGPoint(x: 0.716, y: 0.363), CGPoint(x: 0.735, y: 0.559), CGPoint(x: 0.657, y: 0.578),
                CGPoint(x: 0.304, y: 0.441), CGPoint(x: 0.284, y: 0.637), CGPoint(x: 0.206, y: 0.618),
            ],
            seatRect: nil
        ),
        .prone: PoseArchetype(
            headCenter: CGPoint(x: 0.846, y: 0.346), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.730, y: 0.423), CGPoint(x: 0.308, y: 0.558)],
                [CGPoint(x: 0.730, y: 0.423), CGPoint(x: 0.769, y: 0.577), CGPoint(x: 0.692, y: 0.692)],
                [CGPoint(x: 0.730, y: 0.423), CGPoint(x: 0.654, y: 0.558), CGPoint(x: 0.711, y: 0.673)],
                [CGPoint(x: 0.308, y: 0.558), CGPoint(x: 0.174, y: 0.577), CGPoint(x: 0.058, y: 0.577)],
                [CGPoint(x: 0.308, y: 0.558), CGPoint(x: 0.174, y: 0.615), CGPoint(x: 0.058, y: 0.634)],
            ],
            jointDots: [
                CGPoint(x: 0.730, y: 0.423), CGPoint(x: 0.769, y: 0.577), CGPoint(x: 0.654, y: 0.558),
                CGPoint(x: 0.308, y: 0.558), CGPoint(x: 0.174, y: 0.577), CGPoint(x: 0.174, y: 0.615),
            ],
            seatRect: nil
        ),
        .childsPose: PoseArchetype(
            headCenter: CGPoint(x: 0.746, y: 0.254), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.685, y: 0.346), CGPoint(x: 0.331, y: 0.562)],
                [CGPoint(x: 0.685, y: 0.346), CGPoint(x: 0.777, y: 0.269), CGPoint(x: 0.854, y: 0.207)],
                [CGPoint(x: 0.685, y: 0.346), CGPoint(x: 0.823, y: 0.361), CGPoint(x: 0.870, y: 0.300)],
                [CGPoint(x: 0.331, y: 0.562), CGPoint(x: 0.254, y: 0.669), CGPoint(x: 0.331, y: 0.777)],
                [CGPoint(x: 0.331, y: 0.562), CGPoint(x: 0.392, y: 0.700), CGPoint(x: 0.454, y: 0.793)],
            ],
            jointDots: [
                CGPoint(x: 0.685, y: 0.346), CGPoint(x: 0.777, y: 0.269), CGPoint(x: 0.823, y: 0.361),
                CGPoint(x: 0.331, y: 0.562), CGPoint(x: 0.254, y: 0.669), CGPoint(x: 0.392, y: 0.700),
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
