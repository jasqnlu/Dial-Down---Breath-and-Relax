import Foundation
import simd

/// Turns a tap on the coarse `Head` region into the four evidence-based face
/// zone candidates, fanned out as accurately-placed pins. Unlike muscle
/// disambiguation (geometric, from hit volumes), the head uses a fixed set with
/// hand-tuned anchor points — no per-feature hit boxes. Side is inferred from
/// the tap: person's Left is +X at front view (the app convention), so a tap
/// with `x >= 0` offers Left zones, `x < 0` offers Right.
enum HeadZones {

    /// Anchor points in rigNode-local normalized model space (height-2, centred
    /// on the whole-body bbox). Stored for the +X (person's Left) side; the
    /// Right side mirrors x. Forehead is midline (x = 0).
    ///
    /// NOTE: these are initial estimates. They MUST be tuned against the skin
    /// model in the simulator (Task 5) until each dot sits on its feature.
    private static let leftAnchors: [String: SIMD3<Float>] = [
        "Eye":    SIMD3(0.045, 0.86, 0.085),
        "Temple": SIMD3(0.075, 0.89, 0.050),
        "Jaw":    SIMD3(0.055, 0.79, 0.060),
    ]
    private static let foreheadAnchor = SIMD3<Float>(0.0, 0.93, 0.090)

    static func candidates(forTapAt point: SIMD3<Float>) -> [MarkCandidate] {
        let personLeft = point.x >= 0
        let side = personLeft ? "Left" : "Right"
        var out: [MarkCandidate] = [MarkCandidate(name: "Forehead", point: foreheadAnchor)]
        for base in ["Eye", "Temple", "Jaw"] {
            guard let a = leftAnchors[base] else { continue }
            let anchor = personLeft ? a : SIMD3(-a.x, a.y, a.z)
            out.append(MarkCandidate(name: "\(side) \(base)", point: anchor))
        }
        return out
    }
}
