import SwiftUI

// MARK: - Shared drawing helpers for the Muscle/Skeleton anatomy canvases
//
// Both canvases author shapes as short lists of NORMALISED (0–1) control
// points, right-side-of-body only, then mirror for the left side — the same
// technique SilhouetteShape uses for the body outline.

/// Mirrors a normalised point across the vertical centreline (x = 0.5).
func mirrorX(_ p: CGPoint) -> CGPoint { CGPoint(x: 1 - p.x, y: p.y) }

/// A closed, rounded blob through normalised control points — used for
/// muscle bellies and bone masses. Each point pulls the curve toward itself
/// (same midpoint-smoothing trick as SilhouetteShape), so a handful of
/// points is enough to suggest an organic muscle/bone contour.
func anatomyBlob(_ points: [CGPoint], in rect: CGRect) -> Path {
    guard points.count > 2 else { return Path() }
    func P(_ n: CGPoint) -> CGPoint { CGPoint(x: n.x * rect.width, y: n.y * rect.height) }
    func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }

    var path = Path()
    path.move(to: P(mid(points[points.count - 1], points[0])))
    for i in 0..<points.count {
        let next = points[(i + 1) % points.count]
        path.addQuadCurve(to: P(mid(points[i], next)), control: P(points[i]))
    }
    path.closeSubpath()
    return path
}

/// An open polyline through normalised points — used for tendon lines,
/// muscle-segment dividers (e.g. the abs' tendinous intersections), and
/// suture-style detail lines on bones. Straight segments (no smoothing),
/// which reads as more "engraved line" than "soft muscle".
func anatomyLine(_ points: [CGPoint], in rect: CGRect) -> Path {
    guard let first = points.first else { return Path() }
    func P(_ n: CGPoint) -> CGPoint { CGPoint(x: n.x * rect.width, y: n.y * rect.height) }
    var path = Path()
    path.move(to: P(first))
    for p in points.dropFirst() { path.addLine(to: P(p)) }
    return path
}

/// Convenience for `CGPoint(x:y:)` literals when authoring point lists —
/// keeps the long coordinate tables below terse and scannable.
func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
