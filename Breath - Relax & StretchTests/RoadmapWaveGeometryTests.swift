import Testing
import CoreGraphics
@testable import BreathRelaxStretch

struct RoadmapWaveGeometryTests {
    @Test func firstNodeSitsAtLeadingPadding() {
        #expect(RoadmapWaveGeometry.x(at: 0) == RoadmapWaveGeometry.leadingPadding)
    }

    @Test func nodesAreEvenlySpacedByTheFixedConstant() {
        let x0 = RoadmapWaveGeometry.x(at: 0)
        let x1 = RoadmapWaveGeometry.x(at: 1)
        let x2 = RoadmapWaveGeometry.x(at: 2)
        #expect(x1 - x0 == RoadmapWaveGeometry.nodeSpacing)
        #expect(x2 - x1 == RoadmapWaveGeometry.nodeSpacing)
    }

    @Test func totalWidthGrowsLinearlyWithCount() {
        let w4 = RoadmapWaveGeometry.totalWidth(count: 4)
        let w10 = RoadmapWaveGeometry.totalWidth(count: 10)
        #expect(w10 - w4 == RoadmapWaveGeometry.nodeSpacing * 6)
    }

    @Test func totalWidthForZeroOrOneStillIncludesPadding() {
        let base = RoadmapWaveGeometry.leadingPadding + RoadmapWaveGeometry.trailingPadding
        #expect(RoadmapWaveGeometry.totalWidth(count: 0) == base)
        #expect(RoadmapWaveGeometry.totalWidth(count: 1) == base)
    }

    @Test func yAlternatesCrestAndTroughAtIntegerIndices() {
        let mid: CGFloat = 50
        #expect(RoadmapWaveGeometry.y(at: 0, midY: mid) == mid - RoadmapWaveGeometry.amplitude)
        #expect(RoadmapWaveGeometry.y(at: 1, midY: mid) == mid + RoadmapWaveGeometry.amplitude)
        #expect(RoadmapWaveGeometry.y(at: 2, midY: mid) == mid - RoadmapWaveGeometry.amplitude)
    }

    @Test func continuousYMatchesDiscreteYAtIntegerT() {
        let mid: CGFloat = 50
        for i in 0..<4 {
            #expect(abs(RoadmapWaveGeometry.y(at: i, midY: mid) - RoadmapWaveGeometry.y(atContinuous: CGFloat(i), midY: mid)) < 0.0001)
        }
    }

    @Test func nodeSizeScalesBetweenMinAndMaxByRelativeDuration() {
        let durations = [30, 90, 180]
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 30, in: durations) == RoadmapWaveGeometry.minNodeSize)
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 180, in: durations) == RoadmapWaveGeometry.maxNodeSize)
        let mid = RoadmapWaveGeometry.nodeSize(forDuration: 90, in: durations)
        #expect(mid > RoadmapWaveGeometry.minNodeSize && mid < RoadmapWaveGeometry.maxNodeSize)
    }

    @Test func nodeSizeFallsBackToMidpointWhenAllDurationsMatch() {
        let expected = (RoadmapWaveGeometry.minNodeSize + RoadmapWaveGeometry.maxNodeSize) / 2
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 45, in: [45, 45, 45]) == expected)
    }

    @Test func nodeSizeFallsBackToMidpointForEmptyDurations() {
        let expected = (RoadmapWaveGeometry.minNodeSize + RoadmapWaveGeometry.maxNodeSize) / 2
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 60, in: []) == expected)
    }
}
