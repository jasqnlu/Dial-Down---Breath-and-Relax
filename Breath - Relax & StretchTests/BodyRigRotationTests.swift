import Testing
import Foundation
import simd
import SceneKit
@testable import BreathRelaxStretch

/// The rig rotates about Y only, so "turn to face the tap" is one azimuth.
/// `rotationToFace` returns an ABSOLUTE target; the shortest-arc walk to it
/// belongs to the existing `snap(to:)`, which is why the wrapping helper is
/// tested separately here.
struct BodyRigRotationTests {

    private let deg = CGFloat.pi / 180

    // MARK: - shortestDelta

    @Test func shortestDeltaHopsAcrossTheSeamInsteadOfUnwinding() {
        // 170° → −170° is a 20° hop over the ±π seam, not a 340° unwind.
        let delta = BodyRig.shortestDelta(from: 170 * deg, to: -170 * deg)
        #expect(abs(delta - 20 * deg) < 1e-9)
    }

    @Test func shortestDeltaIsSignedTowardTheNearerSide() {
        #expect(BodyRig.shortestDelta(from: 0, to: 150 * deg) > 0)
        #expect(BodyRig.shortestDelta(from: 0, to: -150 * deg) < 0)
    }

    @Test func shortestDeltaNeverExceedsHalfATurn() {
        // 190° away is really 170° the other way.
        let delta = BodyRig.shortestDelta(from: 0, to: 190 * deg)
        #expect(abs(delta - (-170 * deg)) < 1e-9)
        #expect(abs(delta) <= CGFloat.pi + 1e-9)
    }

    // MARK: - rotationToFace

    @Test func aPointOnTheRigsPlusXSwingsRoundToTheCamera() {
        // Camera sits on world +Z. A point at local (1, 0, 0) has bearing
        // +90°, so the rig must land on −90° to bring it to +Z.
        let target = try! #require(BodyRig.rotationToFace(localPoint: [1, 0, 0], currentY: 0))
        #expect(abs(target - (-90 * deg)) < 1e-6)
    }

    @Test func aPointAlreadyFacingTheCameraNeedsNoRotation() {
        // Local (0, 0.4, 1) is dead-on the camera axis with the rig at 0.
        #expect(BodyRig.rotationToFace(localPoint: [0, 0.4, 1], currentY: 0) == nil)
    }

    @Test func aTapJustInsideTheDeadZoneIsANoOp() {
        let threeDeg = Float(3 * Double.pi / 180)
        let point = SIMD3<Float>(sin(threeDeg), 0.4, cos(threeDeg))
        #expect(BodyRig.rotationToFace(localPoint: point, currentY: 0) == nil)
    }

    @Test func aTapJustOutsideTheDeadZoneStillRotates() {
        let twelveDeg = Float(12 * Double.pi / 180)
        let point = SIMD3<Float>(sin(twelveDeg), 0.4, cos(twelveDeg))
        #expect(BodyRig.rotationToFace(localPoint: point, currentY: 0) != nil)
    }

    @Test func theTargetIsIndependentOfCurrentRotation() {
        // localPoint is rigNode-LOCAL, so the rig's rotation is already
        // factored out — the absolute target must not move with currentY.
        let point = SIMD3<Float>(0.5, 0.2, -0.5)
        let fromFront = try! #require(BodyRig.rotationToFace(localPoint: point, currentY: 0))
        let fromBack  = try! #require(BodyRig.rotationToFace(localPoint: point, currentY: .pi))
        #expect(abs(fromFront - fromBack) < 1e-9)
    }

    @Test func heightDoesNotAffectBearing() {
        let low  = try! #require(BodyRig.rotationToFace(localPoint: [0.4, -0.9, 0.3], currentY: 0))
        let high = try! #require(BodyRig.rotationToFace(localPoint: [0.4,  0.9, 0.3], currentY: 0))
        #expect(abs(low - high) < 1e-9)
    }

    @Test func aPointOnTheYAxisHasNoBearing() {
        #expect(BodyRig.rotationToFace(localPoint: [0, 1, 0], currentY: 0) == nil)
    }
}

/// The "you tapped here" dot. One at a time, no sensation colour — the
/// palette that used to drive it is deleted in this rework.
struct BodyRigSelectionDotTests {

    @Test @MainActor func aSelectionAddsExactlyOneNamedDot() {
        let rig = BodyRig()
        rig.updateSelection(point: [0.1, 0.3, 0.05])
        #expect(rig.marksNode.childNodes.count == 1)
        #expect(rig.marksNode.childNodes.first?.name == "selection-dot")
    }

    @Test @MainActor func aNewSelectionReplacesRatherThanAccumulates() {
        let rig = BodyRig()
        rig.updateSelection(point: [0.1, 0.3, 0.05])
        rig.updateSelection(point: [-0.2, 0.1, 0.4])
        #expect(rig.marksNode.childNodes.count == 1)
    }

    @Test @MainActor func theDotSitsAtTheTappedPoint() {
        let rig = BodyRig()
        rig.updateSelection(point: [-0.2, 0.1, 0.4])
        let dot = try! #require(rig.marksNode.childNodes.first)
        #expect(abs(dot.position.x - (-0.2)) < 1e-6)
        #expect(abs(dot.position.y - 0.1) < 1e-6)
        #expect(abs(dot.position.z - 0.4) < 1e-6)
    }

    @Test @MainActor func passingNilClearsTheDot() {
        let rig = BodyRig()
        rig.updateSelection(point: [0.1, 0.3, 0.05])
        rig.updateSelection(point: nil)
        #expect(rig.marksNode.childNodes.isEmpty)
    }
}
