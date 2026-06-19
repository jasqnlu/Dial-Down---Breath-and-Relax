import SwiftUI
import Combine

// MARK: - StickFigureView

struct StickFigureView: View {
    let poses: [ExercisePose]
    var activeBodyParts: Set<String> = []
    var isPaused: Bool = false

    @State private var poseIdx: Int = 0
    @State private var phase: Phase = .holding
    @State private var tick: Double = 0

    private enum Phase { case holding, transitioning }
    private let transitionDuration: Double = 1.2
    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private var nextIdx: Int {
        poses.count > 1 ? (poseIdx + 1) % poses.count : 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Canvas { ctx, size in
                guard !poses.isEmpty else { return }
                draw(&ctx, size: size, joints: interpolated(in: size))
            }

            if !isPaused, phase == .holding,
               let cue = poses[safe: poseIdx]?.cue, !cue.isEmpty {
                Text(cue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 6)
                    .transition(.opacity)
                    .id(cue)
            }
        }
        .aspectRatio(0.56, contentMode: .fit)
        .onReceive(timer) { _ in
            guard !isPaused, !poses.isEmpty else { return }
            advance()
        }
    }

    // MARK: - State machine

    private func advance() {
        tick += 1.0 / 30
        switch phase {
        case .holding:
            let hold = max(poses[safe: poseIdx]?.holdSeconds ?? 2.0, 0.5)
            if tick >= hold {
                guard poses.count > 1 else { tick = 0; return }
                tick = 0
                phase = .transitioning
            }
        case .transitioning:
            if tick >= transitionDuration {
                poseIdx = nextIdx
                tick = 0
                phase = .holding
            }
        }
    }

    // MARK: - Interpolation

    private func interpolated(in size: CGSize) -> [String: CGPoint] {
        let from = poses[poseIdx].joints
        let to   = phase == .transitioning ? poses[nextIdx].joints : from
        let t    = phase == .transitioning ? eio(min(tick / transitionDuration, 1)) : 0.0
        var result: [String: CGPoint] = [:]
        for j in StickJoint.all {
            let a = pt(from[j], size)
            let b = pt(to[j],   size)
            result[j] = CGPoint(x: a.x + (b.x - a.x) * t,
                                y: a.y + (b.y - a.y) * t)
        }
        return result
    }

    private func pt(_ xy: [Double]?, _ size: CGSize) -> CGPoint {
        guard let xy, xy.count == 2 else { return CGPoint(x: size.width / 2, y: size.height / 2) }
        return CGPoint(x: xy[0] * size.width, y: xy[1] * size.height)
    }

    // MARK: - Drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, joints j: [String: CGPoint]) {
        let accent = Color.accentColor
        let faint  = Color.primary.opacity(0.18)

        for (a, b) in StickJoint.bones {
            guard let pa = j[a], let pb = j[b] else { continue }
            let lit = boneLit(a, b)
            var path = Path()
            path.move(to: pa)
            path.addLine(to: pb)
            ctx.stroke(path,
                       with: .color(lit ? accent : faint),
                       style: StrokeStyle(lineWidth: lit ? 4 : 3, lineCap: .round))
        }

        // Head circle — radius derived from head→neck distance
        if let h = j["head"], let n = j["neck"] {
            let dx = n.x - h.x, dy = n.y - h.y
            let r = sqrt(dx * dx + dy * dy) * 0.65
            let rect = CGRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2)
            let lit = activeBodyParts.contains("Head") || activeBodyParts.contains("Neck")
            ctx.fill(Path(ellipseIn: rect),
                     with: .color(lit ? accent.opacity(0.22) : faint.opacity(0.6)))
            ctx.stroke(Path(ellipseIn: rect),
                       with: .color(lit ? accent : faint),
                       lineWidth: lit ? 3 : 2.5)
        }

        // Joint dots
        for name in StickJoint.all where name != "head" {
            guard let p = j[name] else { continue }
            let r: CGFloat = name == "neck" ? 4 : 3
            let lit = jointLit(name)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                     with: .color(lit ? accent : Color.primary.opacity(0.28)))
        }
    }

    private func boneLit(_ a: String, _ b: String) -> Bool {
        guard !activeBodyParts.isEmpty else { return false }
        return StickJoint.boneBodyParts
            .first { ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a) }
            .map { !$0.parts.isDisjoint(with: activeBodyParts) } ?? false
    }

    private func jointLit(_ name: String) -> Bool {
        guard !activeBodyParts.isEmpty else { return false }
        return StickJoint.boneBodyParts.contains {
            ($0.a == name || $0.b == name) && !$0.parts.isDisjoint(with: activeBodyParts)
        }
    }

    private func eio(_ x: Double) -> Double {
        x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }
}

// MARK: - Preview

#Preview("Hamstring Stretch") {
    StickFigureView(
        poses: [
            ExercisePose(joints: [
                "head": [0.50, 0.06], "neck": [0.50, 0.10],
                "leftShoulder": [0.415, 0.148], "rightShoulder": [0.585, 0.148],
                "leftElbow": [0.39, 0.24], "rightElbow": [0.61, 0.24],
                "leftWrist": [0.375, 0.34], "rightWrist": [0.625, 0.34],
                "hip": [0.50, 0.408],
                "leftKnee": [0.455, 0.58], "rightKnee": [0.545, 0.58],
                "leftAnkle": [0.45, 0.768], "rightAnkle": [0.55, 0.768],
                "leftFoot": [0.44, 0.828],  "rightFoot": [0.56, 0.828],
            ], holdSeconds: 2, cue: "Stand tall"),
            ExercisePose(joints: [
                "head": [0.50, 0.552], "neck": [0.50, 0.490],
                "leftShoulder": [0.455, 0.450], "rightShoulder": [0.545, 0.450],
                "leftElbow": [0.445, 0.532], "rightElbow": [0.555, 0.532],
                "leftWrist": [0.448, 0.658], "rightWrist": [0.552, 0.658],
                "hip": [0.50, 0.358],
                "leftKnee": [0.455, 0.58], "rightKnee": [0.545, 0.58],
                "leftAnkle": [0.45, 0.768], "rightAnkle": [0.55, 0.768],
                "leftFoot": [0.44, 0.828],  "rightFoot": [0.56, 0.828],
            ], holdSeconds: 3, cue: "Hinge at hips, reach down"),
        ],
        activeBodyParts: ["Left Leg", "Right Leg", "Lower Back"]
    )
    .frame(width: 200, height: 360)
    .padding()
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe idx: Int) -> Element? { indices.contains(idx) ? self[idx] : nil }
}
