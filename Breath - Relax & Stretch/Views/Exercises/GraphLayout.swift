import CoreGraphics

/// Pure node-position math for the Exercises tab's node graph, in a
/// normalised -1...1 space independent of screen size. Deterministic
/// (no physics simulation) so the layout is calm and reproducible.
enum GraphLayout {
    /// Evenly spaced position on a unit ring for one of `count` categories.
    /// Index 0 sits at 12 o'clock; indices proceed clockwise.
    static func categoryPosition(index: Int, count: Int) -> CGPoint {
        guard count > 0 else { return .zero }
        let angle = (CGFloat(index) / CGFloat(count)) * 2 * .pi - .pi / 2
        return CGPoint(x: cos(angle), y: sin(angle))
    }

    /// Position for the nth of `count` exercise nodes on a ring of `radius`
    /// around `center`, in the same normalised space.
    static func exercisePosition(index: Int, count: Int, around center: CGPoint, radius: CGFloat) -> CGPoint {
        guard count > 0 else { return center }
        let angle = (CGFloat(index) / CGFloat(count)) * 2 * .pi
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}
