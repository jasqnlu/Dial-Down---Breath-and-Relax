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
