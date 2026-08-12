import SwiftUI

/// One ExerciseCategory drawn as a standing figure touching its own body
/// region — the Exercises tab's category-circle icon. See
/// TouchGlyphArchetype (Models/TouchGlyphArchetype.swift) for why this is a
/// separate glyph family from PoseGlyphIcon.
struct CategoryTouchGlyph: View {
    let category: ExerciseCategory
    var size: CGFloat = 84

    private var archetype: TouchGlyphArchetype {
        TouchGlyphLibrary.all[category] ?? TouchGlyphLibrary.all[.core]!
    }

    var body: some View {
        ZStack {
            Circle().fill(category.accentColor.opacity(0.16))

            TouchGlyphPath(chains: [
                archetype.spine, archetype.legLeft, archetype.legRight,
                archetype.restingArm, archetype.pointingArm,
            ])
            .stroke(category.accentColor, style: StrokeStyle(lineWidth: size * 0.066, lineCap: .round, lineJoin: .round))

            Circle()
                .fill(category.accentColor)
                .frame(width: archetype.headRadius * 2 * size, height: archetype.headRadius * 2 * size)
                .position(x: archetype.headCenter.x * size, y: archetype.headCenter.y * size)

            Circle()
                .fill(category.accentColor)
                .frame(width: size * 0.092, height: size * 0.092)
                .overlay(Circle().strokeBorder(.white, lineWidth: size * 0.017))
                .position(x: archetype.contactPoint.x * size, y: archetype.contactPoint.y * size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct TouchGlyphPath: Shape {
    let chains: [[CGPoint]]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for chain in chains {
            guard let first = chain.first else { continue }
            path.move(to: scaled(first, in: rect))
            for point in chain.dropFirst() {
                path.addLine(to: scaled(point, in: rect))
            }
        }
        return path
    }

    private func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: point.x * rect.width, y: point.y * rect.height)
    }
}
