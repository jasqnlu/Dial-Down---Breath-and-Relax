import SwiftUI

/// Renders one PoseArchetype as a joined-path stick figure inside a
/// category-tinted circle badge — the Home tab's per-exercise pose icon.
/// See docs/superpowers/specs/2026-08-10-pose-glyph-icons-design.md for
/// the visual rationale (why a stick glyph over a filled illustration).
struct PoseGlyphIcon: View {
    let archetype: PoseArchetype
    let mirrored: Bool
    let color: Color
    let motion: MotionAccent
    var size: CGFloat = 96

    init(archetype: PoseArchetype, mirrored: Bool, color: Color,
         size: CGFloat = 96, motion: MotionAccent = .none) {
        self.archetype = archetype
        self.mirrored = mirrored
        self.color = color
        self.motion = motion
        self.size = size
    }

    /// Resolves the archetype + mirror flag from the exercise itself —
    /// the call site only needs to know the exercise and its category.
    init(exercise: Exercise, category: ExerciseCategory, size: CGFloat = 96) {
        let (id, mirrored) = PoseArchetypeMapping.resolve(for: exercise)
        self.init(
            archetype: PoseArchetypeLibrary.all[id] ?? PoseArchetypeLibrary.all[.standingNeutral]!,
            mirrored: mirrored,
            color: category.accentColor,
            size: size,
            motion: MotionAccent.resolve(for: exercise)
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle().fill(color.opacity(0.16))

            if let seatRect = archetype.seatRect {
                let midX = mirroredX(seatRect.midX)
                // clipShape(Circle()) below already guarantees this can't
                // render past the badge, but its flat ends land close to
                // tangent with the circle's curve at this width, which can
                // show a faint anti-aliasing fringe right at the clip edge.
                // Shrinking it gives real clearance instead of a
                // mathematically-exact fit.
                let seatWidth = seatRect.width * size * 0.82
                RoundedRectangle(cornerRadius: seatRect.height * size / 2, style: .continuous)
                    .fill(color.opacity(0.28))
                    .frame(width: seatWidth, height: seatRect.height * size)
                    .position(x: midX * size, y: seatRect.midY * size)
            }

            PoseGlyphPath(limbs: archetype.limbs, mirrored: mirrored)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.073, lineCap: .round, lineJoin: .round))

            ForEach(Array(archetype.jointDots.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(color)
                    .frame(width: size * 0.068, height: size * 0.068)
                    .position(x: mirroredX(point.x) * size, y: point.y * size)
            }

            Circle()
                .fill(color)
                .frame(width: archetype.headRadius * 2 * size, height: archetype.headRadius * 2 * size)
                .position(x: mirroredX(archetype.headCenter.x) * size, y: archetype.headCenter.y * size)

            if motion == .circular, size >= 48 {
                MotionAccentBadge(color: color, size: size * 0.24)
                    .padding(size * 0.04)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        // The seat bar (seated archetypes only) and, at extreme aspect
        // ratios, limb strokes near the edge can extend past the circle's
        // true boundary — clip so nothing ever pokes out past the badge.
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private func mirroredX(_ x: CGFloat) -> CGFloat {
        mirrored ? 1 - x : x
    }
}

private struct MotionAccentBadge: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .center) {
            Circle().fill(color)
            Image(systemName: "arrow.clockwise")
                .font(.system(size: size * 0.49, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
        .frame(width: size, height: size)
    }
}

/// Draws every limb chain (spine, both arms, both legs) as one continuous
/// joined stroke each — this is what keeps bends from showing a seam.
private struct PoseGlyphPath: Shape {
    let limbs: [[CGPoint]]
    let mirrored: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for limb in limbs {
            guard let first = limb.first else { continue }
            path.move(to: scaled(first, in: rect))
            for point in limb.dropFirst() {
                path.addLine(to: scaled(point, in: rect))
            }
        }
        return path
    }

    private func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        let x = mirrored ? 1 - point.x : point.x
        return CGPoint(x: x * rect.width, y: point.y * rect.height)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96))]) {
        ForEach(PoseArchetypeID.allCases, id: \.self) { id in
            PoseGlyphIcon(archetype: PoseArchetypeLibrary.all[id]!, mirrored: false, color: .teal, size: 96)
        }
    }
    .padding()
}
