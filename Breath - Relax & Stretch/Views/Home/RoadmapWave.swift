import SwiftUI

// MARK: - RoadmapWaveGeometry
//
// Pure math — a session's exercises laid out as evenly-spaced nodes on a
// cosine curve. Spacing is fixed (never "fit everything to the available
// width"): this is what makes exercise 1 land at the same leading-edge
// position whether the session has 4 exercises or 40, and lets a long
// routine scroll instead of compressing into illegible, overlapping nodes.
enum RoadmapWaveGeometry {
    static let nodeSpacing: CGFloat = 62
    static let amplitude: CGFloat = 24
    static let leadingPadding: CGFloat = 24
    static let trailingPadding: CGFloat = 24
    static let minNodeSize: CGFloat = 36
    static let maxNodeSize: CGFloat = 58

    static func totalWidth(count: Int) -> CGFloat {
        let base = leadingPadding + trailingPadding
        guard count > 1 else { return base }
        return base + nodeSpacing * CGFloat(count - 1)
    }

    static func x(at index: Int) -> CGFloat {
        leadingPadding + nodeSpacing * CGFloat(index)
    }

    static func x(atContinuous t: CGFloat) -> CGFloat {
        leadingPadding + nodeSpacing * t
    }

    static func y(at index: Int, midY: CGFloat) -> CGFloat {
        midY - amplitude * cos(CGFloat(index) * .pi)
    }

    static func y(atContinuous t: CGFloat, midY: CGFloat) -> CGFloat {
        midY - amplitude * cos(t * .pi)
    }

    static func nodeSize(forDuration duration: Int, in durations: [Int]) -> CGFloat {
        guard let minD = durations.min(), let maxD = durations.max(), maxD > minD else {
            return (minNodeSize + maxNodeSize) / 2
        }
        let fraction = CGFloat(duration - minD) / CGFloat(maxD - minD)
        return minNodeSize + fraction * (maxNodeSize - minNodeSize)
    }

    // MARK: - Carousel focus falloff
    //
    // Pure functions of pixel distance from the viewport's horizontal
    // center to whichever node/curve-segment is being styled. Ported 1:1
    // from the interactive HTML mockup reviewed before this shipped (see
    // docs/superpowers/specs/2026-08-14-roadmap-carousel-exercise-picking-design.md)
    // so the tuning here is deliberate, not arbitrary: the node's transform
    // pivots near its duration label (RoadmapWave applies the scale with a
    // bottom-weighted anchor), so distance-based growth pushes the glyph
    // upward into headroom instead of the label into the container edge.

    /// Leading/trailing padding needed so node 0 and the last node can each
    /// reach the *center* of the viewport, not just its leading edge —
    /// unlike `nodeSpacing`, this is legitimately viewport-dependent (the
    /// "never fit to available width" invariant above is about spacing,
    /// not padding). Falls back to the fixed `leadingPadding` for a
    /// zero/near-zero width (e.g. a first layout pass before geometry is
    /// known), so a node is never pushed off both edges at once.
    static func viewportPadding(visibleWidth: CGFloat) -> CGFloat {
        let half = visibleWidth / 2
        return half > leadingPadding ? half : leadingPadding
    }

    static func focusScale(distance: CGFloat) -> CGFloat {
        max(0.48, 1.62 - (distance / nodeSpacing) * 0.85)
    }

    static func focusOpacity(distance: CGFloat) -> CGFloat {
        max(0.26, 1 - (distance / nodeSpacing) * 0.62)
    }

    static func focusBlur(distance: CGFloat) -> CGFloat {
        min(2.1, max(0, (distance / nodeSpacing - 0.3) * 1.7))
    }

    static func segmentStrokeWidth(distance: CGFloat) -> CGFloat {
        max(0.8, 5.8 - (distance / nodeSpacing) * 3.1)
    }

    static func segmentOpacity(distance: CGFloat) -> CGFloat {
        max(0.24, 1 - (distance / nodeSpacing) * 0.58)
    }

    static func segmentBlur(distance: CGFloat) -> CGFloat {
        min(1.8, max(0, (distance / nodeSpacing - 0.4) * 1.5))
    }
}

// MARK: - RoadmapWaveShape
//
// Kept temporarily alongside RoadmapWaveCurve below: RoadmapWave.body still
// instantiates this (Task 3 rewires that call site to RoadmapWaveCurve and
// removes this struct). Retained here only so the target keeps compiling
// between Task 2 and Task 3.

private struct RoadmapWaveShape: Shape {
    let count: Int
    let midY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 1 else { return path }
        let stepsPerSegment = 16
        let totalSteps = (count - 1) * stepsPerSegment
        for step in 0...totalSteps {
            let t = CGFloat(step) / CGFloat(stepsPerSegment)
            let point = CGPoint(
                x: RoadmapWaveGeometry.x(atContinuous: t),
                y: RoadmapWaveGeometry.y(atContinuous: t, midY: midY)
            )
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - RoadmapWaveCurve
//
// One Canvas-drawn path segment per inter-node span (not one continuous
// Path for the whole timeline) so each span's stroke-width/opacity/blur can
// be pushed toward `focusCenterX` independently — this, paired with the
// node-level falloff in RoadmapWave's ForEach below, is what reads as the
// camera zooming into a specific point on the curve rather than just that
// point's icon growing while a flat, uniformly-styled line sits under it.
struct RoadmapWaveCurve: View {
    let count: Int
    let midY: CGFloat
    /// The x-coordinate, in this curve's own (unscrolled content)
    /// coordinate space, currently centered in the viewport.
    let focusCenterX: CGFloat

    var body: some View {
        Canvas { context, _ in
            guard count > 1 else { return }
            let stepsPerSegment = 16
            let gradient = Gradient(colors: [Color.luminaGradientStart, Color.luminaGradientEnd])

            for segment in 0..<(count - 1) {
                var path = Path()
                for step in 0...stepsPerSegment {
                    let t = CGFloat(segment) + CGFloat(step) / CGFloat(stepsPerSegment)
                    let point = CGPoint(
                        x: RoadmapWaveGeometry.x(atContinuous: t),
                        y: RoadmapWaveGeometry.y(atContinuous: t, midY: midY)
                    )
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }

                let midX = RoadmapWaveGeometry.x(atContinuous: CGFloat(segment) + 0.5)
                let distance = abs(midX - focusCenterX)
                let width = RoadmapWaveGeometry.segmentStrokeWidth(distance: distance)
                let opacity = RoadmapWaveGeometry.segmentOpacity(distance: distance)
                let blur = RoadmapWaveGeometry.segmentBlur(distance: distance)

                context.drawLayer { layer in
                    if blur > 0.01 { layer.addFilter(.blur(radius: blur)) }
                    layer.opacity = opacity
                    layer.stroke(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: RoadmapWaveGeometry.x(at: 0), y: midY),
                            endPoint: CGPoint(x: RoadmapWaveGeometry.x(at: count - 1), y: midY)
                        ),
                        style: StrokeStyle(lineWidth: width, lineCap: .round)
                    )
                }
            }
        }
    }
}

// MARK: - RoadmapWave
//
// A session's exercises as duration-sized PoseGlyphIcon nodes on a
// continuous curve, in a horizontal ScrollView. Node 0 always renders at
// the leading edge (an un-scrolled ScrollView shows its content's leading
// edge first in LTR layouts) — the user scrolls right to reveal the rest,
// at any exercise count. Stays PoseGlyphIcon-only by design: this is
// compact wayfinding, not the primary browsing surface, so it's exempt
// from the general animation-vs-glyph size rule (see ExerciseArt, Task 6).
struct RoadmapWave: View {
    let exercises: [Exercise]
    var numbered: Bool = false

    private var midY: CGFloat {
        RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + (numbered ? 14 : 4)
    }

    private var contentHeight: CGFloat {
        midY + RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + 22
    }

    private var durations: [Int] { exercises.map(\.durationSeconds) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                RoadmapWaveShape(count: exercises.count, midY: midY)
                    .stroke(
                        LinearGradient(colors: [Color.luminaGradientStart, Color.luminaGradientEnd], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )

                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
                    let size = RoadmapWaveGeometry.nodeSize(forDuration: exercise.durationSeconds, in: durations)
                    let x = RoadmapWaveGeometry.x(at: index)
                    let y = RoadmapWaveGeometry.y(at: index, midY: midY)

                    PoseGlyphIcon(exercise: exercise, category: category, size: size)
                        .position(x: x, y: y)

                    if numbered {
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 15, height: 15)
                            .background(Color.luminaPrimary, in: Circle())
                            .position(x: x, y: y - size / 2 - 8)
                    }

                    Text(exercise.durationFormatted)
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                        .position(x: x, y: y + size / 2 + 12)
                }
            }
            .frame(width: RoadmapWaveGeometry.totalWidth(count: exercises.count), height: contentHeight)
        }
        .frame(height: contentHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard !exercises.isEmpty else { return "No exercises" }
        let items = exercises.map { "\($0.name), \($0.durationFormatted)" }.joined(separator: "; ")
        return "\(exercises.count) exercise\(exercises.count == 1 ? "" : "s"): \(items)"
    }
}
