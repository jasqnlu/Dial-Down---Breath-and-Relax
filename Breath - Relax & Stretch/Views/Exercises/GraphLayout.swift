import CoreGraphics

/// Pure node-position math for the Exercises tab's node graph, in a
/// normalised -1...1 space independent of screen size. Deterministic
/// (no physics simulation) so the layout is calm and reproducible.
enum GraphLayout {
    static let defaultFocusZoom: CGFloat = 1.6

    struct RingConfiguration {
        let baseRadius: CGFloat
        let ringSpacing: CGFloat
        let perRing: Int
    }

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

    /// Positions for `count` nodes distributed across concentric rings
    /// around `center`, so a category with many exercises doesn't cram them
    /// all onto one ring. Ring 0 sits at `baseRadius`; each further-out ring
    /// adds `ringSpacing` to the radius and has room for more nodes (larger
    /// circumference). Returns exactly `count` points, in ring order
    /// (innermost ring first, filled before moving outward).
    static func ringPositions(count: Int, around center: CGPoint,
                               baseRadius: CGFloat, ringSpacing: CGFloat,
                               perRing: Int = 7) -> [CGPoint] {
        guard count > 0 else { return [] }
        var positions: [CGPoint] = []
        var remaining = count
        var ring = 0
        while remaining > 0 {
            let capacity = perRing + ring * 2
            let onThisRing = min(remaining, capacity)
            let radius = baseRadius + CGFloat(ring) * ringSpacing
            for i in 0..<onThisRing {
                let angle = (CGFloat(i) / CGFloat(onThisRing)) * 2 * .pi
                positions.append(CGPoint(x: center.x + cos(angle) * radius,
                                          y: center.y + sin(angle) * radius))
            }
            remaining -= onThisRing
            ring += 1
        }
        return positions
    }

    static func clampedZoom(_ zoomScale: CGFloat, min minZoom: CGFloat, max maxZoom: CGFloat) -> CGFloat {
        Swift.min(Swift.max(zoomScale, minZoom), maxZoom)
    }

    static func labelOpacity(zoomScale: CGFloat, isFocused: Bool,
                             fadeStart: CGFloat = 1.55,
                             fadeEnd: CGFloat = 2.2) -> Double {
        if isFocused {
            return 1
        }
        guard fadeEnd > fadeStart else {
            return zoomScale >= fadeEnd ? 1 : 0
        }
        let progress = (zoomScale - fadeStart) / (fadeEnd - fadeStart)
        return Double(clampedZoom(progress, min: 0, max: 1))
    }

    static func namedExerciseRingConfiguration(for nodeCount: Int) -> RingConfiguration {
        exerciseSatelliteRingConfiguration(for: nodeCount, isFocused: true)
    }

    static func exerciseSatelliteRingConfiguration(for nodeCount: Int, isFocused: Bool) -> RingConfiguration {
        if !isFocused {
            let hasManyNodes = nodeCount > 10
            return RingConfiguration(
                baseRadius: hasManyNodes ? 0.34 : 0.31,
                ringSpacing: hasManyNodes ? 0.14 : 0.12,
                perRing: hasManyNodes ? 10 : 8
            )
        }

        let needsOuterRoom = nodeCount > 8
        return RingConfiguration(
            baseRadius: needsOuterRoom ? 0.52 : 0.46,
            ringSpacing: needsOuterRoom ? 0.35 : 0.29,
            perRing: 4
        )
    }

    static func exerciseSatelliteDiameter(isFocused: Bool) -> CGFloat {
        isFocused ? 54 : 22
    }
}
