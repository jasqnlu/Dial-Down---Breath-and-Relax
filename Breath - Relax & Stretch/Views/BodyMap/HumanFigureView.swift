import SwiftUI

// MARK: - Which way the figure faces

enum BodyFacing: String, CaseIterable, Identifiable {
    case front = "Front"
    case back  = "Back"
    var id: String { rawValue }
}

// MARK: - Per-layer styling
//
// Shared so both the silhouette and the interactive overlays stay in sync.

extension BodyLayer {
    /// Colour used to highlight a marked / selected region.
    var highlightColor: Color {
        Color(red: 0.95, green: 0.55, blue: 0.25)
    }

    /// Accent colour used in region labels.
    var accentColor: Color {
        Color(red: 0.95, green: 0.55, blue: 0.25)
    }

    /// Gradient fill for the silhouette body — richer than plain tint.
    var silhouetteFill: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.82, blue: 0.68).opacity(0.55),
                Color(red: 0.94, green: 0.74, blue: 0.58).opacity(0.30),
            ],
            startPoint: .top, endPoint: .bottom))
    }
}

// MARK: - Silhouette Shape
//
// A single, continuous, front-facing body outline. We author only the RIGHT
// half (head-top → arm → hand fingers → torso → leg → foot → crotch) as data,
// then mirror-and-reverse it for the left half. One closed subpath means the
// non-zero fill rule never punches accidental holes where limbs meet the body.

struct SilhouetteShape: Shape {

    /// Right-half perimeter, head-top → crotch. Each entry is (destination,
    /// quad-curve control) in normalised 0–1 coordinates, x ≥ 0.5.
    private static let rightHalf: [(d: CGPoint, c: CGPoint)] = [
        // Head & neck
        (CGPoint(x: 0.585, y: 0.052), CGPoint(x: 0.564, y: 0.004)),  // crown
        (CGPoint(x: 0.574, y: 0.094), CGPoint(x: 0.592, y: 0.070)),  // side of skull
        (CGPoint(x: 0.548, y: 0.140), CGPoint(x: 0.572, y: 0.122)),  // cheek → jaw
        (CGPoint(x: 0.542, y: 0.168), CGPoint(x: 0.546, y: 0.150)),  // side of neck (short)
        // Shoulder & arm (outer edge)
        (CGPoint(x: 0.690, y: 0.190), CGPoint(x: 0.598, y: 0.178)),  // trapezius → shoulder
        (CGPoint(x: 0.744, y: 0.254), CGPoint(x: 0.752, y: 0.208)),  // deltoid
        (CGPoint(x: 0.760, y: 0.354), CGPoint(x: 0.758, y: 0.302)),  // upper arm
        (CGPoint(x: 0.772, y: 0.522), CGPoint(x: 0.763, y: 0.442)),  // forearm
        (CGPoint(x: 0.776, y: 0.560), CGPoint(x: 0.776, y: 0.544)),  // wrist
        // Hand: palm bulges wider than the wrist, then four fingers as
        // shallow scallops (held together), plus a distinct thumb.
        (CGPoint(x: 0.794, y: 0.598), CGPoint(x: 0.786, y: 0.574)),  // palm bulge (outer)
        (CGPoint(x: 0.790, y: 0.618), CGPoint(x: 0.797, y: 0.610)),  // outer palm bottom
        (CGPoint(x: 0.778, y: 0.629), CGPoint(x: 0.784, y: 0.628)),  // pinky tip
        (CGPoint(x: 0.766, y: 0.619), CGPoint(x: 0.770, y: 0.622)),  // valley
        (CGPoint(x: 0.754, y: 0.631), CGPoint(x: 0.760, y: 0.630)),  // ring tip
        (CGPoint(x: 0.742, y: 0.619), CGPoint(x: 0.746, y: 0.622)),  // valley
        (CGPoint(x: 0.730, y: 0.631), CGPoint(x: 0.736, y: 0.630)),  // middle tip
        (CGPoint(x: 0.718, y: 0.619), CGPoint(x: 0.722, y: 0.622)),  // valley
        (CGPoint(x: 0.706, y: 0.626), CGPoint(x: 0.711, y: 0.625)),  // index tip
        (CGPoint(x: 0.700, y: 0.600), CGPoint(x: 0.701, y: 0.614)),  // palm inner bottom
        (CGPoint(x: 0.686, y: 0.576), CGPoint(x: 0.692, y: 0.590)),  // thumb tip
        (CGPoint(x: 0.705, y: 0.556), CGPoint(x: 0.695, y: 0.560)),  // thumb base
        // Arm inner edge (back up to armpit)
        (CGPoint(x: 0.716, y: 0.524), CGPoint(x: 0.712, y: 0.536)),  // inner wrist
        (CGPoint(x: 0.707, y: 0.420), CGPoint(x: 0.715, y: 0.480)),  // inner forearm
        (CGPoint(x: 0.701, y: 0.386), CGPoint(x: 0.703, y: 0.406)),  // inner elbow
        (CGPoint(x: 0.683, y: 0.300), CGPoint(x: 0.699, y: 0.342)),  // inner upper arm
        (CGPoint(x: 0.648, y: 0.236), CGPoint(x: 0.670, y: 0.252)),  // armpit
        // Torso (right side): ribs → waist → hip
        (CGPoint(x: 0.640, y: 0.315), CGPoint(x: 0.648, y: 0.272)),  // ribs
        (CGPoint(x: 0.620, y: 0.400), CGPoint(x: 0.633, y: 0.358)),  // waist (narrowest)
        (CGPoint(x: 0.660, y: 0.486), CGPoint(x: 0.628, y: 0.450)),  // hip flare
        // Right leg (outer)
        (CGPoint(x: 0.636, y: 0.620), CGPoint(x: 0.658, y: 0.548)),  // thigh
        (CGPoint(x: 0.628, y: 0.716), CGPoint(x: 0.632, y: 0.672)),  // knee
        (CGPoint(x: 0.620, y: 0.815), CGPoint(x: 0.628, y: 0.772)),  // calf
        (CGPoint(x: 0.606, y: 0.888), CGPoint(x: 0.614, y: 0.858)),  // ankle
        // Right foot — wider, rounded, bulging outward/forward
        (CGPoint(x: 0.642, y: 0.928), CGPoint(x: 0.628, y: 0.902)),  // ball of foot (outer)
        (CGPoint(x: 0.612, y: 0.962), CGPoint(x: 0.646, y: 0.956)),  // toes
        (CGPoint(x: 0.558, y: 0.958), CGPoint(x: 0.586, y: 0.970)),  // across to inner toe
        (CGPoint(x: 0.548, y: 0.900), CGPoint(x: 0.546, y: 0.930)),  // inner heel → ankle
        // Right leg (inner) back up to crotch
        (CGPoint(x: 0.536, y: 0.792), CGPoint(x: 0.540, y: 0.852)),  // inner calf
        (CGPoint(x: 0.532, y: 0.716), CGPoint(x: 0.534, y: 0.752)),  // inner knee
        (CGPoint(x: 0.514, y: 0.566), CGPoint(x: 0.524, y: 0.640)),  // inner thigh
        (CGPoint(x: 0.500, y: 0.520), CGPoint(x: 0.508, y: 0.536)),  // crotch (centre)
    ]

    private static let crown = CGPoint(x: 0.500, y: 0.004)

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func P(_ n: CGPoint) -> CGPoint { CGPoint(x: n.x * w, y: n.y * h) }            // as-is
        func M(_ n: CGPoint) -> CGPoint { CGPoint(x: (1 - n.x) * w, y: n.y * h) }      // mirrored

        let right = Self.rightHalf
        var path = Path()
        path.move(to: P(Self.crown))

        // Right half: head-top → crotch
        for seg in right {
            path.addQuadCurve(to: P(seg.d), control: P(seg.c))
        }

        // Left half: crotch → head-top, mirrored & reversed.
        // dests[i] is the START point of segment i; reversing a quad keeps the
        // same control point and swaps endpoints.
        let dests = [Self.crown] + right.map { $0.d }
        for i in stride(from: right.count - 1, through: 0, by: -1) {
            path.addQuadCurve(to: M(dests[i]), control: M(right[i].c))
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Silhouette") {
    SilhouetteShape()
        .fill(BodyLayer.skin.silhouetteFill)
        .overlay(SilhouetteShape().stroke(Color(.systemGray3), lineWidth: 1.2))
        .frame(width: 240, height: 520)
        .padding(40)
}

