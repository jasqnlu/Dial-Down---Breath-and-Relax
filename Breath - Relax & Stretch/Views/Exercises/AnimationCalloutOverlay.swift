import SwiftUI

/// Draws the flash-an-arrow-and-instruction overlay for an authored
/// `AnimationCallout`. Positioning (via `callout.anchor`) and fade timing are
/// entirely the caller's responsibility — `ExerciseMediaCard` places this
/// inside a `GeometryReader` and drives `opacity` from an `AVPlayer` periodic
/// time observer via `AnimationCallout.opacity(atLoopTime:)`. Keeping this
/// view stateless makes it trivially previewable and keeps the fade math
/// (the only part that needs unit tests) out of the view layer entirely.
struct AnimationCalloutOverlay: View {
    let callout: AnimationCallout
    /// 0...1 — the caller drives this from the fade envelope (or pins it to 1
    /// for Reduce Motion, where the underlying video is paused rather than
    /// looping).
    var opacity: Double = 1

    private let arrowSize: CGFloat = 44

    var body: some View {
        // Center-aligned so the arrow — usually the wider pill's caption is
        // what pushes the VStack's width — stays centered on `anchor`
        // (positioned by the caller) instead of drifting to whichever side
        // `.leading` would pin it to.
        VStack(alignment: .center, spacing: 6) {
            arrow
                .frame(width: arrowSize, height: arrowSize)
                .accessibilityHidden(true)
            textPill
                .accessibilityHidden(true)
        }
        .opacity(opacity)
        .accessibilityElement(children: .ignore)
        // Exposed regardless of the fade's current opacity — VoiceOver users
        // get the instruction independent of playback position.
        .accessibilityLabel(callout.text)
    }

    @ViewBuilder
    private var arrow: some View {
        switch callout.shape {
        case .rotate:
            RotateArrowShape()
                .stroke(Color.luminaPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-callout.angle))
        case .swingArc:
            SwingArcShape()
                .stroke(Color.luminaPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-callout.angle))
        case .pushPull:
            PushPullArrowShape()
                .stroke(Color.luminaPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-callout.angle))
        case .pulse:
            PulsingRing()
        }
    }

    private var textPill: some View {
        Text(callout.text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.luminaOnPrimary)
            .multilineTextAlignment(.center)
            // Capped so a longer instruction wraps to 2-3 lines instead of
            // growing wide enough to run past the video frame's edge when
            // `anchor` sits near a corner.
            .frame(maxWidth: 150)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.luminaPrimary, in: RoundedRectangle(cornerRadius: LuminaRadius.chip, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shape primitives
//
// Each draws within the unit rect passed by SwiftUI's `Shape` protocol, so
// `.frame(width:height:)` on the call site controls the actual on-screen
// size. `angle` (applied by the caller via `.rotationEffect`) orients the
// whole shape — the paths below are drawn in a fixed "pointing right"
// baseline orientation, per case documented on `AnimationCallout.Shape`.

/// `.rotate` — a near-full circle with a break and an arrowhead, indicating
/// a joint rotating in place (ankle circles, wrist circles, shoulder rolls).
struct RotateArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 3

        // Sweep almost all the way around, leaving a gap for the arrowhead.
        let startAngle = Angle.degrees(-20)
        let endAngle = Angle.degrees(250)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        // Arrowhead at the sweep's end, pointing along the direction of travel.
        let endRad = endAngle.radians
        let tip = CGPoint(x: center.x + radius * cos(endRad), y: center.y + radius * sin(endRad))
        let tangent = endRad + .pi / 2
        let headLength: CGFloat = 7
        let spread: Double = 0.5
        path.move(to: tip)
        path.addLine(to: CGPoint(x: tip.x - headLength * cos(tangent - spread),
                                  y: tip.y - headLength * sin(tangent - spread)))
        path.move(to: tip)
        path.addLine(to: CGPoint(x: tip.x - headLength * cos(tangent + spread),
                                  y: tip.y - headLength * sin(tangent + spread)))
        return path
    }
}

/// `.swingArc` — a partial arc with an arrowhead, for a limb swinging
/// through a partial range (flexion/extension, e.g. tracing the ankle
/// alphabet). Sweeps a ~110° wedge centered on the baseline direction.
struct SwingArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 3

        let startAngle = Angle.degrees(-55)
        let endAngle = Angle.degrees(55)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        let endRad = endAngle.radians
        let tip = CGPoint(x: center.x + radius * cos(endRad), y: center.y + radius * sin(endRad))
        let tangent = endRad + .pi / 2
        let headLength: CGFloat = 7
        let spread: Double = 0.5
        path.move(to: tip)
        path.addLine(to: CGPoint(x: tip.x - headLength * cos(tangent - spread),
                                  y: tip.y - headLength * sin(tangent - spread)))
        path.move(to: tip)
        path.addLine(to: CGPoint(x: tip.x - headLength * cos(tangent + spread),
                                  y: tip.y - headLength * sin(tangent + spread)))
        return path
    }
}

/// `.pushPull` — a straight arrow, for a linear direction (push forward,
/// reach up, press back). Drawn pointing screen-right at `angle == 0`;
/// `.rotationEffect` handles every other direction.
struct PushPullArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let tailX = rect.minX + 4
        let tipX = rect.maxX - 4

        path.move(to: CGPoint(x: tailX, y: midY))
        path.addLine(to: CGPoint(x: tipX, y: midY))

        let headLength: CGFloat = 8
        let spread: CGFloat = 6
        path.move(to: CGPoint(x: tipX, y: midY))
        path.addLine(to: CGPoint(x: tipX - headLength, y: midY - spread))
        path.move(to: CGPoint(x: tipX, y: midY))
        path.addLine(to: CGPoint(x: tipX - headLength, y: midY + spread))
        return path
    }
}

/// `.pulse` — an expanding, fading ring with no directional cue, for
/// "focus here" emphasis (e.g. "rest your eyes here"). Animates continuously
/// while it's part of the view tree; the caller's `opacity` envelope still
/// controls whether it's visible at all.
struct PulsingRing: View {
    @State private var expanded = false

    var body: some View {
        Circle()
            .stroke(Color.luminaPrimary, lineWidth: 2.5)
            .scaleEffect(expanded ? 1.5 : 0.7)
            .opacity(expanded ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    expanded = true
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("Rotate") {
    AnimationCalloutOverlay(callout: AnimationCallout(
        text: "Rotate your wrists in a circle", shape: .rotate,
        anchor: CGPoint(x: 0.5, y: 0.5), angle: 0, startTime: 0, duration: 2
    ))
    .padding(40)
    .background(Color.black)
}

#Preview("Swing arc") {
    AnimationCalloutOverlay(callout: AnimationCallout(
        text: "Move your foot through a small arc", shape: .swingArc,
        anchor: CGPoint(x: 0.5, y: 0.5), angle: -30, startTime: 0, duration: 2
    ))
    .padding(40)
    .background(Color.black)
}

#Preview("Push/pull") {
    AnimationCalloutOverlay(callout: AnimationCallout(
        text: "Press your hips up and back", shape: .pushPull,
        anchor: CGPoint(x: 0.5, y: 0.5), angle: 60, startTime: 0, duration: 2
    ))
    .padding(40)
    .background(Color.black)
}

#Preview("Pulse") {
    AnimationCalloutOverlay(callout: AnimationCallout(
        text: "Rest your palms gently over your eyes", shape: .pulse,
        anchor: CGPoint(x: 0.5, y: 0.5), angle: 0, startTime: 0, duration: 2
    ))
    .padding(40)
    .background(Color.black)
}
