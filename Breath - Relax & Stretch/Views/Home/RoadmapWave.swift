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
}

// MARK: - RoadmapWaveShape

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
