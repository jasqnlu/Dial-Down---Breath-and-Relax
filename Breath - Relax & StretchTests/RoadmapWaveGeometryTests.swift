import Testing
import CoreGraphics
@testable import BreathRelaxStretch

struct RoadmapWaveGeometryTests {
    /// A realistic on-device viewport for the roadmap (iPhone-width card,
    /// minus the surrounding card/screen padding).
    private static let viewportWidth: CGFloat = 321
    private static var padding: CGFloat {
        RoadmapWaveGeometry.viewportPadding(visibleWidth: viewportWidth)
    }

    @Test func firstNodeSitsAtTheGivenPadding() {
        #expect(RoadmapWaveGeometry.x(at: 0, padding: Self.padding) == Self.padding)
    }

    @Test func nodesAreEvenlySpacedByTheFixedConstant() {
        let x0 = RoadmapWaveGeometry.x(at: 0, padding: Self.padding)
        let x1 = RoadmapWaveGeometry.x(at: 1, padding: Self.padding)
        let x2 = RoadmapWaveGeometry.x(at: 2, padding: Self.padding)
        #expect(x1 - x0 == RoadmapWaveGeometry.nodeSpacing)
        #expect(x2 - x1 == RoadmapWaveGeometry.nodeSpacing)
    }

    @Test func continuousXMatchesDiscreteXAtIntegerT() {
        for i in 0..<4 {
            let discrete = RoadmapWaveGeometry.x(at: i, padding: Self.padding)
            let continuous = RoadmapWaveGeometry.x(atContinuous: CGFloat(i), padding: Self.padding)
            #expect(abs(discrete - continuous) < 0.0001)
        }
    }

    @Test func totalWidthGrowsLinearlyWithCount() {
        let w4 = RoadmapWaveGeometry.totalWidth(count: 4, padding: Self.padding)
        let w10 = RoadmapWaveGeometry.totalWidth(count: 10, padding: Self.padding)
        #expect(w10 - w4 == RoadmapWaveGeometry.nodeSpacing * 6)
    }

    @Test func totalWidthForZeroOrOneIsPaddingOnBothSides() {
        let base = Self.padding * 2
        #expect(RoadmapWaveGeometry.totalWidth(count: 0, padding: Self.padding) == base)
        #expect(RoadmapWaveGeometry.totalWidth(count: 1, padding: Self.padding) == base)
    }

    // MARK: - Snapping
    //
    // The offset that centers node `i` is `x(at: i) - viewportWidth / 2`.
    // Each case nudges the scroll a few points off that offset and asserts
    // it snaps back to exactly node `i`'s x once the half-viewport is added
    // back. Interior indices are the ones that matter: the old
    // `padding`-anchored lattice passed at the (range-clamped) first and
    // last nodes while sitting ~25pt off-center everywhere in between.

    private func centeredNodeX(snappingFrom delta: CGFloat, index: Int) -> CGFloat {
        let nodeX = RoadmapWaveGeometry.x(at: index, padding: Self.padding)
        let proposed = nodeX - Self.viewportWidth / 2 + delta
        let snapped = RoadmapWaveGeometry.snappedContentOffset(
            proposed: proposed,
            padding: Self.padding,
            containerWidth: Self.viewportWidth
        )
        return snapped + Self.viewportWidth / 2
    }

    @Test func snappingNearNodeZeroCentersNodeZero() {
        for delta in [CGFloat(-7), 0, 9] {
            #expect(abs(centeredNodeX(snappingFrom: delta, index: 0)
                        - RoadmapWaveGeometry.x(at: 0, padding: Self.padding)) < 0.0001)
        }
    }

    @Test func snappingNearAnInteriorNodeCentersThatNode() {
        for index in 1...4 {
            for delta in [CGFloat(-11), -3, 0, 5, 13] {
                let centered = centeredNodeX(snappingFrom: delta, index: index)
                #expect(abs(centered - RoadmapWaveGeometry.x(at: index, padding: Self.padding)) < 0.0001)
            }
        }
    }

    @Test func snappingNearTheLastNodeCentersThatNode() {
        let last = 7
        for delta in [CGFloat(-9), 0, 9] {
            #expect(abs(centeredNodeX(snappingFrom: delta, index: last)
                        - RoadmapWaveGeometry.x(at: last, padding: Self.padding)) < 0.0001)
        }
    }

    @Test func snappedOffsetsAreExactlyOneNodeSpacingApart() {
        let a = centeredNodeX(snappingFrom: 0, index: 2)
        let b = centeredNodeX(snappingFrom: 0, index: 3)
        #expect(abs((b - a) - RoadmapWaveGeometry.nodeSpacing) < 0.0001)
    }

    @Test func snappedOffsetNeverGoesNegative() {
        let snapped = RoadmapWaveGeometry.snappedContentOffset(
            proposed: -500,
            padding: Self.padding,
            containerWidth: Self.viewportWidth
        )
        #expect(snapped >= 0)
    }

    @Test func snappingHoldsAcrossRealDeviceWidths() {
        for width in [CGFloat(320), 321, 353, 390] {
            let padding = RoadmapWaveGeometry.viewportPadding(visibleWidth: width)
            for index in 0...5 {
                let nodeX = RoadmapWaveGeometry.x(at: index, padding: padding)
                let snapped = RoadmapWaveGeometry.snappedContentOffset(
                    proposed: nodeX - width / 2 + 8,
                    padding: padding,
                    containerWidth: width
                )
                #expect(abs((snapped + width / 2) - nodeX) < 0.0001)
            }
        }
    }

    @Test func badgeOpacityRampsSmoothlyAndIsClamped() {
        #expect(RoadmapWaveGeometry.badgeOpacity(scale: 0.5) == 0)
        #expect(RoadmapWaveGeometry.badgeOpacity(scale: 1.62) == 1)
        let near = RoadmapWaveGeometry.badgeOpacity(scale: 1.1)
        let nearer = RoadmapWaveGeometry.badgeOpacity(scale: 1.25)
        #expect(near > 0 && near < 1)
        #expect(nearer > near)
        // A settled carousel puts the neighbours exactly one node-spacing
        // out; they must still show a (fainter) number, since the numbered
        // variant exists to communicate order. Two spacings out fades away.
        let neighbour = RoadmapWaveGeometry.badgeOpacity(
            scale: RoadmapWaveGeometry.focusScale(distance: RoadmapWaveGeometry.nodeSpacing))
        let farther = RoadmapWaveGeometry.badgeOpacity(
            scale: RoadmapWaveGeometry.focusScale(distance: RoadmapWaveGeometry.nodeSpacing * 2))
        #expect(neighbour > 0)
        #expect(neighbour < 1)
        #expect(farther == 0)
    }

    // MARK: - Focus headroom
    //
    // The container has to fit the focused node at full scale. These
    // reproduce the transform independently (scale about `focusAnchorY`
    // applied to a stack centered on the node) and check the reserved
    // extents cover it — the numbered variant is the tall case, and it was
    // the one visibly clipping at the top before headroom was reserved.

    private func measuredExtents(numbered: Bool) -> (top: CGFloat, bottom: CGFloat) {
        let h = RoadmapWaveGeometry.nodeStackHeight(numbered: numbered)
        let scale = RoadmapWaveGeometry.focusScale(distance: 0)
        let anchorFromCenter = (RoadmapWaveGeometry.focusAnchorY - 0.5) * h
        // Stack spans [-h/2, +h/2] around the node center before scaling.
        let top = (anchorFromCenter + h / 2) * scale - anchorFromCenter
        let bottom = (h / 2 - anchorFromCenter) * scale + anchorFromCenter
        return (top, bottom)
    }

    @Test func focusExtentsCoverTheFullyScaledNodeStack() {
        for numbered in [false, true] {
            let measured = measuredExtents(numbered: numbered)
            #expect(abs(RoadmapWaveGeometry.focusTopExtent(numbered: numbered) - measured.top) < 0.0001)
            #expect(abs(RoadmapWaveGeometry.focusBottomExtent(numbered: numbered) - measured.bottom) < 0.0001)
        }
    }

    @Test func aFullyScaledCrestNodeFitsAboveTheContainerTop() {
        for numbered in [false, true] {
            let midY = RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.focusTopExtent(numbered: numbered)
            let crestY = RoadmapWaveGeometry.y(at: 0, midY: midY)
            #expect(crestY - measuredExtents(numbered: numbered).top >= -0.0001)
        }
    }

    @Test func aFullyScaledTroughNodeFitsAboveTheContainerBottom() {
        for numbered in [false, true] {
            let midY = RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.focusTopExtent(numbered: numbered)
            let contentHeight = midY + RoadmapWaveGeometry.amplitude
                + RoadmapWaveGeometry.focusBottomExtent(numbered: numbered)
            let troughY = RoadmapWaveGeometry.y(at: 1, midY: midY)
            #expect(troughY + measuredExtents(numbered: numbered).bottom <= contentHeight + 0.0001)
        }
    }

    @Test func numberedVariantReservesMoreHeadroomThanPlain() {
        #expect(RoadmapWaveGeometry.focusTopExtent(numbered: true)
                > RoadmapWaveGeometry.focusTopExtent(numbered: false))
        #expect(RoadmapWaveGeometry.focusTopExtent(numbered: false) > 0)
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

    @Test func viewportPaddingIsHalfTheVisibleWidth() {
        #expect(RoadmapWaveGeometry.viewportPadding(visibleWidth: 300) == 150)
    }

    @Test func viewportPaddingFallsBackToLeadingPaddingForTinyOrZeroWidth() {
        #expect(RoadmapWaveGeometry.viewportPadding(visibleWidth: 0) == RoadmapWaveGeometry.leadingPadding)
        #expect(RoadmapWaveGeometry.viewportPadding(visibleWidth: 20) == RoadmapWaveGeometry.leadingPadding)
    }

    @Test func focusScaleIsMaximalAtZeroDistanceAndClampedAtFloor() {
        #expect(RoadmapWaveGeometry.focusScale(distance: 0) == 1.62)
        #expect(RoadmapWaveGeometry.focusScale(distance: 10_000) == 0.48)
    }

    @Test func focusScaleDecreasesMonotonicallyWithDistance() {
        let near = RoadmapWaveGeometry.focusScale(distance: RoadmapWaveGeometry.nodeSpacing * 0.5)
        let far = RoadmapWaveGeometry.focusScale(distance: RoadmapWaveGeometry.nodeSpacing * 1.5)
        #expect(near > far)
    }

    @Test func focusOpacityIsMaximalAtZeroDistanceAndClampedAtFloor() {
        #expect(RoadmapWaveGeometry.focusOpacity(distance: 0) == 1.0)
        #expect(RoadmapWaveGeometry.focusOpacity(distance: 10_000) == 0.26)
    }

    @Test func focusBlurIsZeroNearCenterAndClampedAtCeiling() {
        #expect(RoadmapWaveGeometry.focusBlur(distance: 0) == 0)
        #expect(RoadmapWaveGeometry.focusBlur(distance: 10_000) == 2.1)
    }

    @Test func segmentStrokeWidthIsWidestAtZeroDistanceAndClampedAtFloor() {
        #expect(RoadmapWaveGeometry.segmentStrokeWidth(distance: 0) == 5.8)
        #expect(RoadmapWaveGeometry.segmentStrokeWidth(distance: 10_000) == 0.8)
    }

    @Test func segmentOpacityAndBlurFollowTheSameFalloffShape() {
        #expect(RoadmapWaveGeometry.segmentOpacity(distance: 0) == 1.0)
        #expect(RoadmapWaveGeometry.segmentOpacity(distance: 10_000) == 0.24)
        #expect(RoadmapWaveGeometry.segmentBlur(distance: 0) == 0)
        #expect(RoadmapWaveGeometry.segmentBlur(distance: 10_000) == 1.8)
    }
}
