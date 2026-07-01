import SwiftUI

// MARK: - Body Region
//
// A tappable / paintable area of the body, defined in NORMALISED coordinates
// (0–1) so it scales to any canvas size.  `scaledRect(in:)` converts to points.

struct BodyRegion: Identifiable, Hashable {
    let name: String
    let rect: CGRect          // normalised 0-1 on the figure canvas
    let cornerRadius: CGFloat

    var id: String { name }

    func scaledRect(in size: CGSize) -> CGRect {
        CGRect(
            x:      rect.minX * size.width,
            y:      rect.minY * size.height,
            width:  rect.width  * size.width,
            height: rect.height * size.height
        )
    }
}

// MARK: - Which way the figure faces

enum BodyFacing: String, CaseIterable, Identifiable {
    case front = "Front"
    case back  = "Back"
    var id: String { rawValue }
}

// MARK: - All body regions (normalised, aligned to SilhouetteShape below)
//
// "Left" / "Right" follow the on-screen side (screen-left == "Left"), matching
// the exercise seed data. The silhouette outline is identical front/back, so
// only the region set changes between the two facings.

/// FRONT view: chest, abs, quads, shins, plus granular arm/leg joints.
let frontRegions: [BodyRegion] = [
    BodyRegion(name: "Head",           rect: CGRect(x: 0.405, y: 0.000, width: 0.190, height: 0.135), cornerRadius: 50),
    BodyRegion(name: "Neck",           rect: CGRect(x: 0.450, y: 0.120, width: 0.100, height: 0.050), cornerRadius: 6),
    BodyRegion(name: "Left Shoulder",  rect: CGRect(x: 0.250, y: 0.160, width: 0.150, height: 0.085), cornerRadius: 12),
    BodyRegion(name: "Right Shoulder", rect: CGRect(x: 0.600, y: 0.160, width: 0.150, height: 0.085), cornerRadius: 12),
    BodyRegion(name: "Chest",          rect: CGRect(x: 0.360, y: 0.185, width: 0.280, height: 0.105), cornerRadius: 10),
    BodyRegion(name: "Core",           rect: CGRect(x: 0.380, y: 0.295, width: 0.240, height: 0.110), cornerRadius: 10),
    BodyRegion(name: "Left Arm",       rect: CGRect(x: 0.205, y: 0.205, width: 0.110, height: 0.150), cornerRadius: 12),
    BodyRegion(name: "Right Arm",      rect: CGRect(x: 0.685, y: 0.205, width: 0.110, height: 0.150), cornerRadius: 12),
    BodyRegion(name: "Left Elbow",     rect: CGRect(x: 0.200, y: 0.355, width: 0.105, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Right Elbow",    rect: CGRect(x: 0.695, y: 0.355, width: 0.105, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Left Forearm",   rect: CGRect(x: 0.195, y: 0.415, width: 0.110, height: 0.110), cornerRadius: 12),
    BodyRegion(name: "Right Forearm",  rect: CGRect(x: 0.695, y: 0.415, width: 0.110, height: 0.110), cornerRadius: 12),
    BodyRegion(name: "Left Hand",      rect: CGRect(x: 0.190, y: 0.535, width: 0.130, height: 0.110), cornerRadius: 14),
    BodyRegion(name: "Right Hand",     rect: CGRect(x: 0.680, y: 0.535, width: 0.130, height: 0.110), cornerRadius: 14),
    BodyRegion(name: "Hips",           rect: CGRect(x: 0.340, y: 0.460, width: 0.320, height: 0.080), cornerRadius: 10),
    BodyRegion(name: "Left Leg",       rect: CGRect(x: 0.340, y: 0.550, width: 0.150, height: 0.150), cornerRadius: 14),
    BodyRegion(name: "Right Leg",      rect: CGRect(x: 0.510, y: 0.550, width: 0.150, height: 0.150), cornerRadius: 14),
    BodyRegion(name: "Left Knee",      rect: CGRect(x: 0.350, y: 0.700, width: 0.130, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Right Knee",     rect: CGRect(x: 0.520, y: 0.700, width: 0.130, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Left Shin",      rect: CGRect(x: 0.350, y: 0.760, width: 0.120, height: 0.120), cornerRadius: 12),
    BodyRegion(name: "Right Shin",     rect: CGRect(x: 0.530, y: 0.760, width: 0.120, height: 0.120), cornerRadius: 12),
    BodyRegion(name: "Left Foot",      rect: CGRect(x: 0.335, y: 0.895, width: 0.150, height: 0.080), cornerRadius: 8),
    BodyRegion(name: "Right Foot",     rect: CGRect(x: 0.515, y: 0.895, width: 0.150, height: 0.080), cornerRadius: 8),
]

/// BACK view: upper/lower back, glutes, hamstrings, calves.
let backRegions: [BodyRegion] = [
    BodyRegion(name: "Head",           rect: CGRect(x: 0.405, y: 0.000, width: 0.190, height: 0.135), cornerRadius: 50),
    BodyRegion(name: "Neck",           rect: CGRect(x: 0.450, y: 0.120, width: 0.100, height: 0.050), cornerRadius: 6),
    BodyRegion(name: "Left Shoulder",  rect: CGRect(x: 0.250, y: 0.160, width: 0.150, height: 0.085), cornerRadius: 12),
    BodyRegion(name: "Right Shoulder", rect: CGRect(x: 0.600, y: 0.160, width: 0.150, height: 0.085), cornerRadius: 12),
    BodyRegion(name: "Upper Back",     rect: CGRect(x: 0.360, y: 0.185, width: 0.280, height: 0.115), cornerRadius: 10),
    BodyRegion(name: "Lower Back",     rect: CGRect(x: 0.375, y: 0.305, width: 0.250, height: 0.150), cornerRadius: 10),
    BodyRegion(name: "Left Arm",       rect: CGRect(x: 0.205, y: 0.205, width: 0.110, height: 0.150), cornerRadius: 12),
    BodyRegion(name: "Right Arm",      rect: CGRect(x: 0.685, y: 0.205, width: 0.110, height: 0.150), cornerRadius: 12),
    BodyRegion(name: "Left Elbow",     rect: CGRect(x: 0.200, y: 0.355, width: 0.105, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Right Elbow",    rect: CGRect(x: 0.695, y: 0.355, width: 0.105, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Left Forearm",   rect: CGRect(x: 0.195, y: 0.415, width: 0.110, height: 0.110), cornerRadius: 12),
    BodyRegion(name: "Right Forearm",  rect: CGRect(x: 0.695, y: 0.415, width: 0.110, height: 0.110), cornerRadius: 12),
    BodyRegion(name: "Left Hand",      rect: CGRect(x: 0.190, y: 0.535, width: 0.130, height: 0.110), cornerRadius: 14),
    BodyRegion(name: "Right Hand",     rect: CGRect(x: 0.680, y: 0.535, width: 0.130, height: 0.110), cornerRadius: 14),
    BodyRegion(name: "Glutes",         rect: CGRect(x: 0.345, y: 0.460, width: 0.310, height: 0.090), cornerRadius: 12),
    BodyRegion(name: "Left Hamstring", rect: CGRect(x: 0.340, y: 0.555, width: 0.150, height: 0.145), cornerRadius: 14),
    BodyRegion(name: "Right Hamstring",rect: CGRect(x: 0.510, y: 0.555, width: 0.150, height: 0.145), cornerRadius: 14),
    BodyRegion(name: "Left Knee",      rect: CGRect(x: 0.350, y: 0.700, width: 0.130, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Right Knee",     rect: CGRect(x: 0.520, y: 0.700, width: 0.130, height: 0.060), cornerRadius: 10),
    BodyRegion(name: "Left Calf",      rect: CGRect(x: 0.350, y: 0.760, width: 0.120, height: 0.120), cornerRadius: 12),
    BodyRegion(name: "Right Calf",     rect: CGRect(x: 0.530, y: 0.760, width: 0.120, height: 0.120), cornerRadius: 12),
    BodyRegion(name: "Left Foot",      rect: CGRect(x: 0.335, y: 0.895, width: 0.150, height: 0.080), cornerRadius: 8),
    BodyRegion(name: "Right Foot",     rect: CGRect(x: 0.515, y: 0.895, width: 0.150, height: 0.080), cornerRadius: 8),
]

// MARK: - Detail level (revealed by zoom)

enum BodyDetail {
    case normal   // hands as single regions
    case fine     // hands split into individual fingers (needs zoom to tap)
}

/// Individual finger regions, shared by both facings. Tiny — only practical to
/// tap once the user has zoomed in, which is why they're gated behind `.fine`.
/// "Left"/"Right" follow the on-screen side; pinky is outermost, thumb innermost.
let handFingerRegions: [BodyRegion] = [
    // Right hand (screen-right): pinky → thumb, outer → inner
    BodyRegion(name: "Right Pinky",  rect: CGRect(x: 0.773, y: 0.600, width: 0.026, height: 0.048), cornerRadius: 7),
    BodyRegion(name: "Right Ring",   rect: CGRect(x: 0.745, y: 0.600, width: 0.027, height: 0.052), cornerRadius: 7),
    BodyRegion(name: "Right Middle", rect: CGRect(x: 0.717, y: 0.600, width: 0.027, height: 0.054), cornerRadius: 7),
    BodyRegion(name: "Right Index",  rect: CGRect(x: 0.690, y: 0.598, width: 0.027, height: 0.050), cornerRadius: 7),
    BodyRegion(name: "Right Thumb",  rect: CGRect(x: 0.665, y: 0.552, width: 0.030, height: 0.046), cornerRadius: 7),
    // Left hand (screen-left): mirror of the right
    BodyRegion(name: "Left Pinky",   rect: CGRect(x: 0.201, y: 0.600, width: 0.026, height: 0.048), cornerRadius: 7),
    BodyRegion(name: "Left Ring",    rect: CGRect(x: 0.228, y: 0.600, width: 0.027, height: 0.052), cornerRadius: 7),
    BodyRegion(name: "Left Middle",  rect: CGRect(x: 0.256, y: 0.600, width: 0.027, height: 0.054), cornerRadius: 7),
    BodyRegion(name: "Left Index",   rect: CGRect(x: 0.283, y: 0.598, width: 0.027, height: 0.050), cornerRadius: 7),
    BodyRegion(name: "Left Thumb",   rect: CGRect(x: 0.305, y: 0.552, width: 0.030, height: 0.046), cornerRadius: 7),
]

/// Individual toe regions — FRONT view only. Aligned with BodyDetailCanvas toe drawings.
/// "Left"/"Right" follow the on-screen side; big toe is innermost (closest to centre).
let toeRegions: [BodyRegion] = [
    // Right foot (screen-right): big toe (inner/lower-x) → pinky (outer/higher-x)
    BodyRegion(name: "Right Big Toe",    rect: CGRect(x: 0.551, y: 0.932, width: 0.018, height: 0.028), cornerRadius: 7),
    BodyRegion(name: "Right 2nd Toe",    rect: CGRect(x: 0.568, y: 0.938, width: 0.016, height: 0.024), cornerRadius: 6),
    BodyRegion(name: "Right Middle Toe", rect: CGRect(x: 0.582, y: 0.939, width: 0.014, height: 0.022), cornerRadius: 6),
    BodyRegion(name: "Right 4th Toe",    rect: CGRect(x: 0.594, y: 0.938, width: 0.013, height: 0.020), cornerRadius: 6),
    BodyRegion(name: "Right Pinky Toe",  rect: CGRect(x: 0.607, y: 0.934, width: 0.012, height: 0.018), cornerRadius: 5),
    // Left foot (screen-left): mirror of the right
    BodyRegion(name: "Left Big Toe",     rect: CGRect(x: 0.431, y: 0.932, width: 0.018, height: 0.028), cornerRadius: 7),
    BodyRegion(name: "Left 2nd Toe",     rect: CGRect(x: 0.416, y: 0.938, width: 0.016, height: 0.024), cornerRadius: 6),
    BodyRegion(name: "Left Middle Toe",  rect: CGRect(x: 0.404, y: 0.939, width: 0.014, height: 0.022), cornerRadius: 6),
    BodyRegion(name: "Left 4th Toe",     rect: CGRect(x: 0.393, y: 0.938, width: 0.013, height: 0.020), cornerRadius: 6),
    BodyRegion(name: "Left Pinky Toe",   rect: CGRect(x: 0.381, y: 0.934, width: 0.012, height: 0.018), cornerRadius: 5),
]

/// Facial fine-detail regions — FRONT view only. Aligned with FacialFeaturesCanvas drawings.
/// Only revealed in `.fine` detail (zoom ≥ threshold), since they sit inside the Head region.
let faceFrontFineRegions: [BodyRegion] = [
    BodyRegion(name: "Left Eye",  rect: CGRect(x: 0.434, y: 0.056, width: 0.046, height: 0.018), cornerRadius: 9),
    BodyRegion(name: "Right Eye", rect: CGRect(x: 0.520, y: 0.056, width: 0.046, height: 0.018), cornerRadius: 9),
    BodyRegion(name: "Nose",      rect: CGRect(x: 0.477, y: 0.072, width: 0.046, height: 0.032), cornerRadius: 6),
]

/// Region set for a given facing + detail level.
/// In `.fine`: fingers replace hands; toes replace feet; eye/nose regions are added (front only).
func bodyRegions(for facing: BodyFacing, detail: BodyDetail = .normal) -> [BodyRegion] {
    let base = facing == .front ? frontRegions : backRegions
    guard detail == .fine else { return base }

    var regions = base.filter { $0.name != "Left Hand" && $0.name != "Right Hand" }
    regions += handFingerRegions

    if facing == .front {
        regions = regions.filter { $0.name != "Left Foot" && $0.name != "Right Foot" }
        regions += toeRegions + faceFrontFineRegions
    }

    return regions
}

/// Superset of every region (both detail levels) for a facing — used when
/// deriving marks from saved ink so all fine regions are caught regardless of zoom.
func allRegions(for facing: BodyFacing) -> [BodyRegion] {
    var all = (facing == .front ? frontRegions : backRegions) + handFingerRegions
    if facing == .front {
        all += toeRegions + faceFrontFineRegions
    }
    return all
}

// MARK: - Per-layer styling
//
// Shared so both the silhouette and the interactive overlays stay in sync.

extension BodyLayer {
    /// Colour used to highlight a marked / selected region.
    var highlightColor: Color {
        switch self {
        case .skin:     return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .muscle:   return Color(red: 0.82, green: 0.14, blue: 0.14)
        case .skeleton: return Color(red: 0.52, green: 0.48, blue: 0.44)
        }
    }

    /// Accent colour used in the layer picker and region labels.
    var accentColor: Color {
        switch self {
        case .skin:     return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .muscle:   return Color(red: 0.82, green: 0.14, blue: 0.14)
        case .skeleton: return Color(red: 0.48, green: 0.44, blue: 0.38)
        }
    }

    /// Gradient fill for the silhouette body — richer than plain tint.
    var silhouetteFill: AnyShapeStyle {
        switch self {
        case .skin:
            return AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.82, blue: 0.68).opacity(0.55),
                    Color(red: 0.94, green: 0.74, blue: 0.58).opacity(0.30),
                ],
                startPoint: .top, endPoint: .bottom))
        case .muscle:
            return AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.24, blue: 0.20).opacity(0.26),
                    Color(red: 0.75, green: 0.14, blue: 0.18).opacity(0.14),
                ],
                startPoint: .top, endPoint: .bottom))
        case .skeleton:
            return AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.86, blue: 0.80).opacity(0.50),
                    Color(red: 0.78, green: 0.76, blue: 0.70).opacity(0.28),
                ],
                startPoint: .top, endPoint: .bottom))
        }
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

// MARK: - Facial Features Overlay
//
// Drawn in normalized figure coordinates (0–1) using Canvas. Front view only.
// Eyes, brows, ears, nose bridge, nostrils, and lips.

struct FacialFeaturesCanvas: View {
    let sex: String  // "male" or "female"

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * w, y: y * h) }
            func oval(_ cx: Double, _ cy: Double, _ rw: Double, _ rh: Double) -> CGRect {
                CGRect(x: (cx - rw / 2) * w, y: (cy - rh / 2) * h,
                       width: rw * w, height: rh * h)
            }

            let isFemale = (sex == "female")
            let line  = GraphicsContext.Shading.color(.primary.opacity(0.58))
            let faint = GraphicsContext.Shading.color(.primary.opacity(0.33))
            let dark  = GraphicsContext.Shading.color(.primary.opacity(0.82))
            let browWidth: CGFloat = isFemale ? 1.1 : 1.6

            // ── Ears ──────────────────────────────────────────────────────────
            for isLeft in [true, false] {
                let ex: Double = isLeft ? 0.413 : 0.587
                let cx: Double = isLeft ? 0.400 : 0.600
                var ear = Path()
                ear.move(to: pt(ex, 0.063))
                ear.addQuadCurve(to: pt(ex, 0.090), control: pt(cx, 0.076))
                ctx.stroke(ear, with: line,
                           style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }

            // ── Eyebrows ──────────────────────────────────────────────────────
            let browPeak: Double = isFemale ? 0.041 : 0.044
            for isLeft in [true, false] {
                let x0: Double = isLeft ? 0.438 : 0.523
                let x1: Double = isLeft ? 0.477 : 0.562
                let cx: Double = isLeft ? 0.457 : 0.543
                var brow = Path()
                brow.move(to: pt(x0, 0.053))
                brow.addQuadCurve(to: pt(x1, 0.050), control: pt(cx, browPeak))
                ctx.stroke(brow, with: line,
                           style: StrokeStyle(lineWidth: browWidth, lineCap: .round))
            }

            // ── Eyes ──────────────────────────────────────────────────────────
            let eyeH: Double = 0.015
            for isLeft in [true, false] {
                let eyeCX: Double = isLeft ? 0.458 : 0.542
                let eyeRect = oval(eyeCX, 0.065, 0.040, eyeH)
                ctx.fill(Path(ellipseIn: eyeRect), with: .color(.white.opacity(0.88)))
                ctx.stroke(Path(ellipseIn: eyeRect), with: line,
                           style: StrokeStyle(lineWidth: 1.0))
                // Iris
                ctx.fill(Path(ellipseIn: eyeRect.insetBy(dx: eyeRect.width * 0.22,
                                                          dy: eyeRect.height * 0.04)),
                         with: .color(.primary.opacity(0.20)))
                // Pupil
                ctx.fill(Path(ellipseIn: eyeRect.insetBy(dx: eyeRect.width * 0.36,
                                                          dy: eyeRect.height * 0.10)),
                         with: dark)
            }

            // ── Nose ──────────────────────────────────────────────────────────
            // Bridge
            var bridge = Path()
            bridge.move(to: pt(0.494, 0.075))
            bridge.addQuadCurve(to: pt(0.487, 0.093), control: pt(0.485, 0.082))
            bridge.move(to: pt(0.506, 0.075))
            bridge.addQuadCurve(to: pt(0.513, 0.093), control: pt(0.515, 0.082))
            ctx.stroke(bridge, with: faint,
                       style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            // Nostrils
            for cx in [0.486, 0.514] as [Double] {
                ctx.stroke(Path(ellipseIn: oval(cx, 0.096, 0.013, 0.008)),
                           with: faint, style: StrokeStyle(lineWidth: 0.9))
            }
            // Tip arc
            var tip = Path()
            tip.move(to: pt(0.481, 0.098))
            tip.addQuadCurve(to: pt(0.519, 0.098), control: pt(0.500, 0.102))
            ctx.stroke(tip, with: faint,
                       style: StrokeStyle(lineWidth: 0.9, lineCap: .round))

            // ── Lips ──────────────────────────────────────────────────────────
            let lipY: Double   = 0.109
            let belly: Double  = isFemale ? 0.122 : 0.119
            // Upper lip M-curve
            var upper = Path()
            upper.move(to: pt(0.469, lipY))
            upper.addQuadCurve(to: pt(0.484, 0.104), control: pt(0.474, lipY))
            upper.addQuadCurve(to: pt(0.500, 0.108), control: pt(0.492, 0.105))
            upper.addQuadCurve(to: pt(0.516, 0.104), control: pt(0.508, 0.105))
            upper.addQuadCurve(to: pt(0.531, lipY),  control: pt(0.526, lipY))
            ctx.stroke(upper, with: line,
                       style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
            // Lower lip
            var lower = Path()
            lower.move(to: pt(0.469, lipY))
            lower.addQuadCurve(to: pt(0.531, lipY), control: pt(0.500, belly))
            ctx.stroke(lower, with: line,
                       style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Body Detail Overlay (fingernails + individual toes)
//
// Front view only. Draws small rounded shapes at each fingertip and toe.

struct BodyDetailCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func oval(_ cx: Double, _ cy: Double, _ rw: Double, _ rh: Double) -> CGRect {
                CGRect(x: (cx - rw / 2) * w, y: (cy - rh / 2) * h,
                       width: rw * w, height: rh * h)
            }

            let nailFill   = GraphicsContext.Shading.color(.white.opacity(0.82))
            let nailStroke = GraphicsContext.Shading.color(.primary.opacity(0.28))
            let toeStroke  = GraphicsContext.Shading.color(.primary.opacity(0.32))
            let nailStyle  = StrokeStyle(lineWidth: 0.7)
            let toeStyle   = StrokeStyle(lineWidth: 0.8, lineCap: .round)

            // ── Fingernails ────────────────────────────────────────────────────
            // Right hand: pinky → index → thumb
            let rNails: [(Double, Double)] = [
                (0.778, 0.622), (0.754, 0.624),
                (0.730, 0.624), (0.706, 0.619), (0.686, 0.569),
            ]
            for (cx, cy) in rNails + rNails.map({ (1.0 - $0.0, $0.1) }) {
                let r = oval(cx, cy, 0.010, 0.007)
                let rr = Path(roundedRect: r, cornerRadius: r.width * 0.4)
                ctx.fill(rr, with: nailFill)
                ctx.stroke(rr, with: nailStroke, style: nailStyle)
            }

            // ── Toes ────────────────────────────────────────────────────────────
            // Right foot: big toe (inner/lower-x) → pinky (outer/higher-x)
            let rToes: [(Double, Double, Double, Double)] = [
                (0.560, 0.946, 0.017, 0.028),
                (0.576, 0.950, 0.013, 0.024),
                (0.590, 0.950, 0.012, 0.022),
                (0.602, 0.948, 0.011, 0.020),
                (0.613, 0.944, 0.010, 0.018),
            ]
            let allToes = rToes + rToes.map { (1.0 - $0.0, $0.1, $0.2, $0.3) }
            for (cx, cy, tw, th) in allToes {
                let r   = oval(cx, cy, tw, th)
                let rr  = Path(roundedRect: r, cornerRadius: r.width * 0.5)
                ctx.stroke(rr, with: toeStroke, style: toeStyle)
                // Toenail
                let nr  = oval(cx, cy - th * 0.25, tw * 0.76, th * 0.30)
                let nrr = Path(roundedRect: nr, cornerRadius: nr.width * 0.4)
                ctx.fill(nrr, with: .color(.white.opacity(0.70)))
                ctx.stroke(nrr, with: toeStroke, style: StrokeStyle(lineWidth: 0.5))
            }
        }
        .allowsHitTesting(false)
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
