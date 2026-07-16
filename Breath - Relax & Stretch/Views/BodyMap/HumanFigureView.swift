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

// MARK: - Gender-specific silhouette shapes
//
// Both shapes use the same mirrored-half technique as SilhouetteShape.
// Only the RIGHT half path data differs between male and female.

private protocol MirroredHalfShape: Shape {
    var rightHalf: [(d: CGPoint, c: CGPoint)] { get }
    var crown: CGPoint { get }
}

extension MirroredHalfShape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func P(_ n: CGPoint) -> CGPoint { CGPoint(x: n.x * w, y: n.y * h) }
        func M(_ n: CGPoint) -> CGPoint { CGPoint(x: (1 - n.x) * w, y: n.y * h) }
        let right = rightHalf
        var path = Path()
        path.move(to: P(crown))
        for seg in right { path.addQuadCurve(to: P(seg.d), control: P(seg.c)) }
        let dests = [crown] + right.map { $0.d }
        for i in stride(from: right.count - 1, through: 0, by: -1) {
            path.addQuadCurve(to: M(dests[i]), control: M(right[i].c))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: Male: broader shoulders, flatter torso, less hip flare

struct MaleSilhouetteShape: MirroredHalfShape {
    var crown: CGPoint = CGPoint(x: 0.500, y: 0.004)
    var rightHalf: [(d: CGPoint, c: CGPoint)] = [
        // Head & neck — slightly squarer jaw
        (CGPoint(x: 0.585, y: 0.052), CGPoint(x: 0.564, y: 0.004)),
        (CGPoint(x: 0.577, y: 0.092), CGPoint(x: 0.594, y: 0.068)),
        (CGPoint(x: 0.551, y: 0.138), CGPoint(x: 0.575, y: 0.118)),
        (CGPoint(x: 0.544, y: 0.168), CGPoint(x: 0.549, y: 0.150)),
        // Shoulder & arm — wider
        (CGPoint(x: 0.714, y: 0.192), CGPoint(x: 0.604, y: 0.178)),
        (CGPoint(x: 0.758, y: 0.256), CGPoint(x: 0.768, y: 0.210)),
        (CGPoint(x: 0.770, y: 0.356), CGPoint(x: 0.766, y: 0.304)),
        (CGPoint(x: 0.774, y: 0.522), CGPoint(x: 0.768, y: 0.444)),
        (CGPoint(x: 0.778, y: 0.560), CGPoint(x: 0.778, y: 0.544)),
        // Hand — palm + 4 fingers + thumb
        (CGPoint(x: 0.796, y: 0.598), CGPoint(x: 0.788, y: 0.574)),
        (CGPoint(x: 0.792, y: 0.618), CGPoint(x: 0.799, y: 0.610)),
        (CGPoint(x: 0.780, y: 0.630), CGPoint(x: 0.786, y: 0.629)),
        (CGPoint(x: 0.768, y: 0.620), CGPoint(x: 0.772, y: 0.623)),
        (CGPoint(x: 0.756, y: 0.632), CGPoint(x: 0.762, y: 0.631)),
        (CGPoint(x: 0.744, y: 0.620), CGPoint(x: 0.748, y: 0.623)),
        (CGPoint(x: 0.732, y: 0.632), CGPoint(x: 0.738, y: 0.631)),
        (CGPoint(x: 0.720, y: 0.620), CGPoint(x: 0.724, y: 0.623)),
        (CGPoint(x: 0.708, y: 0.627), CGPoint(x: 0.713, y: 0.626)),
        (CGPoint(x: 0.702, y: 0.600), CGPoint(x: 0.703, y: 0.615)),
        (CGPoint(x: 0.688, y: 0.578), CGPoint(x: 0.694, y: 0.592)),
        (CGPoint(x: 0.707, y: 0.558), CGPoint(x: 0.697, y: 0.562)),
        // Arm inner edge
        (CGPoint(x: 0.718, y: 0.526), CGPoint(x: 0.714, y: 0.538)),
        (CGPoint(x: 0.709, y: 0.422), CGPoint(x: 0.717, y: 0.482)),
        (CGPoint(x: 0.703, y: 0.388), CGPoint(x: 0.705, y: 0.408)),
        (CGPoint(x: 0.683, y: 0.302), CGPoint(x: 0.699, y: 0.344)),
        (CGPoint(x: 0.646, y: 0.238), CGPoint(x: 0.668, y: 0.254)),
        // Torso — flat chest, gentle waist, modest hip
        (CGPoint(x: 0.637, y: 0.316), CGPoint(x: 0.644, y: 0.270)),
        (CGPoint(x: 0.628, y: 0.400), CGPoint(x: 0.634, y: 0.358)),
        (CGPoint(x: 0.644, y: 0.486), CGPoint(x: 0.622, y: 0.448)),
        // Right leg (outer)
        (CGPoint(x: 0.634, y: 0.620), CGPoint(x: 0.652, y: 0.550)),
        (CGPoint(x: 0.626, y: 0.718), CGPoint(x: 0.632, y: 0.674)),
        (CGPoint(x: 0.618, y: 0.815), CGPoint(x: 0.628, y: 0.774)),
        (CGPoint(x: 0.604, y: 0.888), CGPoint(x: 0.612, y: 0.858)),
        // Right foot
        (CGPoint(x: 0.642, y: 0.928), CGPoint(x: 0.628, y: 0.902)),
        (CGPoint(x: 0.612, y: 0.962), CGPoint(x: 0.646, y: 0.956)),
        (CGPoint(x: 0.558, y: 0.958), CGPoint(x: 0.586, y: 0.970)),
        (CGPoint(x: 0.548, y: 0.900), CGPoint(x: 0.546, y: 0.930)),
        // Right leg (inner)
        (CGPoint(x: 0.536, y: 0.792), CGPoint(x: 0.540, y: 0.852)),
        (CGPoint(x: 0.532, y: 0.716), CGPoint(x: 0.534, y: 0.752)),
        (CGPoint(x: 0.514, y: 0.566), CGPoint(x: 0.524, y: 0.640)),
        (CGPoint(x: 0.500, y: 0.520), CGPoint(x: 0.508, y: 0.536)),
    ]
}

// MARK: Female: narrower shoulders, breast curve, pronounced waist, wider hips

struct FemaleSilhouetteShape: MirroredHalfShape {
    var crown: CGPoint = CGPoint(x: 0.500, y: 0.004)
    var rightHalf: [(d: CGPoint, c: CGPoint)] = [
        // Head & neck — slightly rounder, softer jaw
        (CGPoint(x: 0.584, y: 0.052), CGPoint(x: 0.563, y: 0.004)),
        (CGPoint(x: 0.572, y: 0.094), CGPoint(x: 0.590, y: 0.070)),
        (CGPoint(x: 0.546, y: 0.140), CGPoint(x: 0.569, y: 0.124)),
        (CGPoint(x: 0.540, y: 0.168), CGPoint(x: 0.544, y: 0.151)),
        // Shoulder & arm — narrower
        (CGPoint(x: 0.670, y: 0.190), CGPoint(x: 0.594, y: 0.178)),
        (CGPoint(x: 0.734, y: 0.252), CGPoint(x: 0.744, y: 0.206)),
        (CGPoint(x: 0.752, y: 0.352), CGPoint(x: 0.750, y: 0.300)),
        (CGPoint(x: 0.762, y: 0.518), CGPoint(x: 0.756, y: 0.440)),
        (CGPoint(x: 0.766, y: 0.556), CGPoint(x: 0.766, y: 0.540)),
        // Hand — slightly slimmer
        (CGPoint(x: 0.782, y: 0.594), CGPoint(x: 0.775, y: 0.570)),
        (CGPoint(x: 0.778, y: 0.614), CGPoint(x: 0.785, y: 0.606)),
        (CGPoint(x: 0.766, y: 0.626), CGPoint(x: 0.772, y: 0.625)),
        (CGPoint(x: 0.754, y: 0.616), CGPoint(x: 0.758, y: 0.619)),
        (CGPoint(x: 0.742, y: 0.628), CGPoint(x: 0.748, y: 0.627)),
        (CGPoint(x: 0.730, y: 0.616), CGPoint(x: 0.734, y: 0.619)),
        (CGPoint(x: 0.718, y: 0.628), CGPoint(x: 0.724, y: 0.627)),
        (CGPoint(x: 0.706, y: 0.616), CGPoint(x: 0.710, y: 0.619)),
        (CGPoint(x: 0.694, y: 0.623), CGPoint(x: 0.699, y: 0.622)),
        (CGPoint(x: 0.688, y: 0.596), CGPoint(x: 0.689, y: 0.611)),
        (CGPoint(x: 0.675, y: 0.574), CGPoint(x: 0.680, y: 0.588)),
        (CGPoint(x: 0.693, y: 0.554), CGPoint(x: 0.683, y: 0.558)),
        // Arm inner edge
        (CGPoint(x: 0.704, y: 0.522), CGPoint(x: 0.700, y: 0.534)),
        (CGPoint(x: 0.695, y: 0.418), CGPoint(x: 0.703, y: 0.478)),
        (CGPoint(x: 0.689, y: 0.384), CGPoint(x: 0.691, y: 0.404)),
        (CGPoint(x: 0.670, y: 0.298), CGPoint(x: 0.686, y: 0.340)),
        (CGPoint(x: 0.637, y: 0.236), CGPoint(x: 0.657, y: 0.252)),
        // Torso — breast curve + narrow waist + wide hip
        (CGPoint(x: 0.657, y: 0.263), CGPoint(x: 0.642, y: 0.243)),  // upper breast slope
        (CGPoint(x: 0.664, y: 0.298), CGPoint(x: 0.671, y: 0.278)),  // breast fullness
        (CGPoint(x: 0.645, y: 0.330), CGPoint(x: 0.659, y: 0.318)),  // underbreast
        (CGPoint(x: 0.596, y: 0.402), CGPoint(x: 0.612, y: 0.364)),  // waist (narrow)
        (CGPoint(x: 0.700, y: 0.490), CGPoint(x: 0.620, y: 0.454)),  // hip (wide)
        // Right leg (outer)
        (CGPoint(x: 0.636, y: 0.622), CGPoint(x: 0.654, y: 0.552)),
        (CGPoint(x: 0.628, y: 0.718), CGPoint(x: 0.634, y: 0.674)),
        (CGPoint(x: 0.618, y: 0.815), CGPoint(x: 0.628, y: 0.774)),
        (CGPoint(x: 0.604, y: 0.888), CGPoint(x: 0.612, y: 0.858)),
        // Right foot
        (CGPoint(x: 0.640, y: 0.928), CGPoint(x: 0.626, y: 0.902)),
        (CGPoint(x: 0.610, y: 0.960), CGPoint(x: 0.644, y: 0.954)),
        (CGPoint(x: 0.558, y: 0.956), CGPoint(x: 0.584, y: 0.968)),
        (CGPoint(x: 0.548, y: 0.900), CGPoint(x: 0.546, y: 0.928)),
        // Right leg (inner)
        (CGPoint(x: 0.536, y: 0.792), CGPoint(x: 0.540, y: 0.852)),
        (CGPoint(x: 0.532, y: 0.716), CGPoint(x: 0.534, y: 0.752)),
        (CGPoint(x: 0.514, y: 0.566), CGPoint(x: 0.524, y: 0.640)),
        (CGPoint(x: 0.500, y: 0.520), CGPoint(x: 0.508, y: 0.536)),
    ]
}

// MARK: - Preview

#Preview("Silhouette") {
    SilhouetteShape()
        .fill(BodyLayer.skin.silhouetteFill)
        .overlay(SilhouetteShape().stroke(Color(.systemGray3), lineWidth: 1.2))
        .frame(width: 240, height: 520)
        .padding(40)
}

#Preview("Male vs Female") {
    HStack(spacing: 24) {
        MaleSilhouetteShape()
            .fill(BodyLayer.skin.silhouetteFill)
            .overlay(MaleSilhouetteShape().stroke(Color(.systemBlue).opacity(0.5), lineWidth: 1.2))
            .frame(width: 110, height: 260)

        FemaleSilhouetteShape()
            .fill(BodyLayer.skin.silhouetteFill)
            .overlay(FemaleSilhouetteShape().stroke(Color(.systemPink).opacity(0.5), lineWidth: 1.2))
            .frame(width: 110, height: 260)
    }
    .padding(40)
}
