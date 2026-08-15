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
    /// Leading offset for node 0, matching RoadmapWave's own viewport-
    /// dependent `padding` (RoadmapWaveGeometry.viewportPadding) — not the
    /// fixed `RoadmapWaveGeometry.leadingPadding` baked into `.x(at:)`/
    /// `.x(atContinuous:)`. Those two padding notions diverge on any real
    /// device width, so this curve must place its points using the same
    /// `padding` the nodes use, or the path renders under the wrong x.
    let padding: CGFloat

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
                        x: padding + RoadmapWaveGeometry.nodeSpacing * t,
                        y: RoadmapWaveGeometry.y(atContinuous: t, midY: midY)
                    )
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }

                let midX = padding + RoadmapWaveGeometry.nodeSpacing * (CGFloat(segment) + 0.5)
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
                            startPoint: CGPoint(x: padding, y: midY),
                            endPoint: CGPoint(x: padding + RoadmapWaveGeometry.nodeSpacing * CGFloat(count - 1), y: midY)
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
// continuous curve, paging one exercise at a time in a horizontal
// ScrollView: the centered node and the curve segment under it read as
// zoomed in (larger, sharper, brighter), while neighbors recede (smaller,
// blurred, dimmed toward a vignette). Node 0 always renders first (an
// un-scrolled ScrollView shows its content's leading edge first in LTR
// layouts), and the user pages right to bring each subsequent exercise
// into focus. Spacing between nodes is fixed regardless of exercise count
// (RoadmapWaveGeometry.nodeSpacing) — only the leading/trailing padding is
// viewport-dependent, so node 0 and the last node can each reach dead
// center. Stays PoseGlyphIcon-only by design: this is compact wayfinding,
// not the primary browsing surface, so it's exempt from the general
// animation-vs-glyph size rule (see ExerciseArt, Task 6).
struct RoadmapWave: View {
    let exercises: [Exercise]
    var numbered: Bool = false

    /// Continuous horizontal content-offset, read every scroll frame via
    /// `.onScrollGeometryChange` — not just the settled post-snap position
    /// — because the "glide" the carousel needs (nodes/curve scaling
    /// *during* the drag, not only once it stops) needs per-frame position.
    @State private var contentOffsetX: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0

    private var midY: CGFloat {
        RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + (numbered ? 14 : 4)
    }

    private var contentHeight: CGFloat {
        midY + RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + 22
    }

    private var durations: [Int] { exercises.map(\.durationSeconds) }

    private var padding: CGFloat {
        RoadmapWaveGeometry.viewportPadding(visibleWidth: viewportWidth)
    }

    private var totalWidth: CGFloat {
        let base = padding * 2
        guard exercises.count > 1 else { return base }
        return base + RoadmapWaveGeometry.nodeSpacing * CGFloat(exercises.count - 1)
    }

    /// The x-coordinate (in content space) currently centered in the
    /// viewport — what every node/curve-segment measures its distance from.
    private var focusCenterX: CGFloat {
        contentOffsetX + viewportWidth / 2
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                RoadmapWaveCurve(count: exercises.count, midY: midY, focusCenterX: focusCenterX, padding: padding)

                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    nodeView(index: index, exercise: exercise)
                }
            }
            .frame(width: totalWidth, height: contentHeight)
        }
        .frame(height: contentHeight)
        .scrollTargetBehavior(RoadmapPagingBehavior(padding: padding))
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.x }) { _, newOffset in
            contentOffsetX = newOffset
        }
        .background {
            GeometryReader { geo in
                Color.clear.onAppear { viewportWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in viewportWidth = newWidth }
            }
        }
        .overlay { carouselVignette }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func nodeView(index: Int, exercise: Exercise) -> some View {
        let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
        let size = RoadmapWaveGeometry.nodeSize(forDuration: exercise.durationSeconds, in: durations)
        let x = padding + RoadmapWaveGeometry.nodeSpacing * CGFloat(index)
        let y = RoadmapWaveGeometry.y(at: index, midY: midY)
        let distance = abs(x - focusCenterX)
        let scale = RoadmapWaveGeometry.focusScale(distance: distance)
        let opacity = RoadmapWaveGeometry.focusOpacity(distance: distance)
        let blur = RoadmapWaveGeometry.focusBlur(distance: distance)

        VStack(spacing: 8) {
            if numbered {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 15, height: 15)
                    .background(Color.luminaPrimary, in: Circle())
                    .opacity(scale > 1.05 ? 1 : 0)
            }
            PoseGlyphIcon(exercise: exercise, category: category, size: size)
            Text(exercise.durationFormatted)
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        // Pivoting near the bottom of the stack (by the duration label)
        // rather than dead-center means scaling up pushes the glyph
        // further UP into open headroom above the curve, and leaves the
        // duration label roughly anchored — nodes on the low side of the
        // curve (odd indices, per RoadmapWaveGeometry.y) no longer grow
        // downward into the container edge as they scale up.
        .scaleEffect(scale, anchor: UnitPoint(x: 0.5, y: 0.84))
        .opacity(opacity)
        .blur(radius: blur)
        .position(x: x, y: y)
        .zIndex(Double(scale))
    }

    private var carouselVignette: some View {
        // Fixed over the viewport (this overlay does not scroll with the
        // content) — stays clear near center, dims toward the edges, like
        // looking through a lens centered on whichever node is focused.
        RadialGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.clear,
                Color.luminaSurface.opacity(0.55),
            ]),
            center: .center,
            startRadius: 10,
            endRadius: max(viewportWidth, 1) * 0.62
        )
        .allowsHitTesting(false)
    }

    private var accessibilityLabel: String {
        guard !exercises.isEmpty else { return "No exercises" }
        let items = exercises.map { "\($0.name), \($0.durationFormatted)" }.joined(separator: "; ")
        return "\(exercises.count) exercise\(exercises.count == 1 ? "" : "s"): \(items)"
    }
}

// MARK: - RoadmapPagingBehavior
//
// `.scrollTargetBehavior(.paging)` snaps to multiples of the *container*
// width — the wrong fit here, since RoadmapWaveGeometry.nodeSpacing is a
// fixed constant independent of container width. This snaps to the
// nearest node-spacing multiple instead, so a node always lands centered
// in the viewport regardless of how wide that viewport is.
private struct RoadmapPagingBehavior: ScrollTargetBehavior {
    let padding: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let raw = target.rect.minX
        let stepsFromStart = ((raw - padding) / RoadmapWaveGeometry.nodeSpacing).rounded()
        let snapped = padding + stepsFromStart * RoadmapWaveGeometry.nodeSpacing
        target.rect.origin.x = max(0, snapped)
    }
}
