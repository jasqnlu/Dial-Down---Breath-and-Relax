import Testing
import SceneKit
import simd
@testable import BreathRelaxStretch

@MainActor struct BodyRigFocusTests {
    /// Focusing on a dot is a pure camera dolly — it must NEVER rotate the rig
    /// (the "slight rotation on select" guard).
    @Test func focusLeavesRigRotationUnchanged() {
        let rig = BodyRig(style: .anatomy)
        rig.rigNode.eulerAngles = SCNVector3(0, 0.7, 0)   // a committed turntable rotation
        let before = rig.rigNode.eulerAngles
        rig.focus(on: SIMD3<Float>(0.2, 0.3, 0.1))
        let after = rig.rigNode.eulerAngles
        #expect(before.x == after.x && before.y == after.y && before.z == after.z,
                "focus() must be a pure camera dolly — rig rotation changed")
    }

    /// The focus camera must not ROLL around its view axis (which would tilt the
    /// horizon and read as the figure rotating). Roll is measured by the camera's
    /// RIGHT vector leaving horizontal — NOT the up vector, which legitimately
    /// tilts when the camera pitches down at an off-axis dot.
    @Test func focusHasNoCameraRoll() {
        let rig = BodyRig(style: .anatomy)
        rig.focus(on: SIMD3<Float>(0.3, -0.2, 0.0))
        let right = rig.cameraNode.simdTransform.columns.0   // camera's local +X in world space
        #expect(abs(right.y) < 0.001, "camera rolled during focus (right.y=\(right.y))")
    }
}
