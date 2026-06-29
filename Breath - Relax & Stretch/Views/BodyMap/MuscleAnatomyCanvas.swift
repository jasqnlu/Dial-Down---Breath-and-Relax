import SwiftUI

// MARK: - Muscle Anatomy Canvas
//
// Stylised "major muscle groups" replica of a front/back muscle diagram —
// drawn as filled blobs (anatomyBlob) over the existing body silhouette,
// clipped to it by the caller (BodyFigureCanvas). Coordinates are normalised
// 0–1 in the SAME space as SilhouetteShape/BodyRegion, authored right-side-
// only and mirrored for the left (mirrorX), except for the handful of
// muscles that straddle the centreline (abs, back trapezius).
//
// This intentionally matches the granularity of the app's existing tap
// regions (Chest, Core, Arm, Leg, …) rather than replicating every individual
// muscle subdivision from a textbook plate — enough to read as "a muscle
// diagram" at phone-screen size without becoming illegible clutter.

struct MuscleAnatomyCanvas: View {
    let facing: BodyFacing

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            if facing == .front {
                drawFront(in: &ctx, rect: rect)
            } else {
                drawBack(in: &ctx, rect: rect)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Palette

    private let muscleBase  = Color(red: 0.80, green: 0.16, blue: 0.15)
    private var fill: Color      { muscleBase.opacity(0.62) }
    private var fillDeep: Color  { muscleBase.opacity(0.40) }
    private var lineStroke: Color { muscleBase.opacity(0.90) }
    private var tendon: Color    { Color.white.opacity(0.55) }

    // MARK: Drawing primitives

    private func blob(_ points: [CGPoint], deep: Bool = false,
                       in ctx: inout GraphicsContext, rect: CGRect) {
        let path = anatomyBlob(points, in: rect)
        ctx.fill(path, with: .color(deep ? fillDeep : fill))
        ctx.stroke(path, with: .color(lineStroke), style: StrokeStyle(lineWidth: 0.8))
    }

    private func bilateral(_ points: [CGPoint], deep: Bool = false,
                            in ctx: inout GraphicsContext, rect: CGRect) {
        blob(points, deep: deep, in: &ctx, rect: rect)
        blob(points.map(mirrorX), deep: deep, in: &ctx, rect: rect)
    }

    private func divider(_ points: [CGPoint], width: CGFloat = 1, color: Color? = nil,
                          in ctx: inout GraphicsContext, rect: CGRect) {
        ctx.stroke(anatomyLine(points, in: rect), with: .color(color ?? tendon),
                   style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func bilateralDivider(_ points: [CGPoint], width: CGFloat = 1, color: Color? = nil,
                                   in ctx: inout GraphicsContext, rect: CGRect) {
        divider(points, width: width, color: color, in: &ctx, rect: rect)
        divider(points.map(mirrorX), width: width, color: color, in: &ctx, rect: rect)
    }

    // MARK: - Front

    private func drawFront(in ctx: inout GraphicsContext, rect: CGRect) {
        // Trapezius (front sliver, neck → shoulder)
        bilateral([pt(0.544, 0.172), pt(0.605, 0.182), pt(0.658, 0.208),
                   pt(0.615, 0.232), pt(0.560, 0.202)], in: &ctx, rect: rect)

        // Pectoralis major
        bilateral([pt(0.502, 0.196), pt(0.560, 0.188), pt(0.625, 0.198),
                   pt(0.665, 0.232), pt(0.648, 0.268), pt(0.598, 0.288),
                   pt(0.540, 0.270), pt(0.505, 0.240)], in: &ctx, rect: rect)

        // Deltoid (shoulder cap)
        bilateral([pt(0.605, 0.183), pt(0.672, 0.183), pt(0.730, 0.225),
                   pt(0.745, 0.270), pt(0.715, 0.300), pt(0.670, 0.270),
                   pt(0.650, 0.220)], in: &ctx, rect: rect)

        // Biceps brachii
        bilateral([pt(0.700, 0.260), pt(0.735, 0.258), pt(0.755, 0.300),
                   pt(0.748, 0.345), pt(0.725, 0.358), pt(0.700, 0.330),
                   pt(0.695, 0.290)], in: &ctx, rect: rect)

        // Forearm flexor mass
        bilateral([pt(0.705, 0.420), pt(0.745, 0.418), pt(0.768, 0.460),
                   pt(0.762, 0.500), pt(0.735, 0.515), pt(0.708, 0.495),
                   pt(0.700, 0.455)], in: &ctx, rect: rect)

        // Serratus anterior (texture hint — short diagonal lines, below armpit)
        bilateralDivider([pt(0.612, 0.272), pt(0.598, 0.296)], width: 0.8, in: &ctx, rect: rect)
        bilateralDivider([pt(0.625, 0.282), pt(0.610, 0.306)], width: 0.8, in: &ctx, rect: rect)
        bilateralDivider([pt(0.636, 0.294), pt(0.620, 0.316)], width: 0.8, in: &ctx, rect: rect)

        // External oblique
        bilateral([pt(0.600, 0.310), pt(0.635, 0.322), pt(0.628, 0.380),
                   pt(0.605, 0.400), pt(0.585, 0.385), pt(0.585, 0.335)], in: &ctx, rect: rect)

        // Rectus abdominis (straddles centreline — drawn once, not mirrored)
        blob([pt(0.420, 0.300), pt(0.580, 0.300), pt(0.600, 0.330),
              pt(0.595, 0.395), pt(0.500, 0.402), pt(0.405, 0.395),
              pt(0.400, 0.330)], in: &ctx, rect: rect)
        divider([pt(0.500, 0.300), pt(0.500, 0.400)], in: &ctx, rect: rect)
        divider([pt(0.415, 0.328), pt(0.585, 0.328)], in: &ctx, rect: rect)
        divider([pt(0.408, 0.355), pt(0.592, 0.355)], in: &ctx, rect: rect)
        divider([pt(0.403, 0.380), pt(0.597, 0.380)], in: &ctx, rect: rect)

        // Adductors (inner thigh sliver, hugs centreline)
        bilateral([pt(0.500, 0.560), pt(0.518, 0.580), pt(0.520, 0.620),
                   pt(0.514, 0.655), pt(0.500, 0.665)], in: &ctx, rect: rect)

        // Quadriceps
        bilateral([pt(0.520, 0.560), pt(0.560, 0.545), pt(0.610, 0.555),
                   pt(0.630, 0.600), pt(0.625, 0.660), pt(0.600, 0.700),
                   pt(0.560, 0.708), pt(0.530, 0.690), pt(0.515, 0.640),
                   pt(0.510, 0.590)], in: &ctx, rect: rect)
        bilateralDivider([pt(0.555, 0.560), pt(0.548, 0.620), pt(0.545, 0.680)],
                          in: &ctx, rect: rect)
        bilateralDivider([pt(0.595, 0.560), pt(0.598, 0.620), pt(0.590, 0.685)],
                          in: &ctx, rect: rect)

        // Tibialis anterior
        bilateral([pt(0.560, 0.770), pt(0.590, 0.768), pt(0.600, 0.800),
                   pt(0.590, 0.850), pt(0.570, 0.860), pt(0.555, 0.820)], in: &ctx, rect: rect)
    }

    // MARK: - Back

    private func drawBack(in ctx: inout GraphicsContext, rect: CGRect) {
        // Trapezius (big kite, neck → mid-back, straddles centreline)
        blob([pt(0.500, 0.160), pt(0.560, 0.168), pt(0.640, 0.200),
              pt(0.660, 0.230), pt(0.600, 0.280), pt(0.560, 0.320),
              pt(0.500, 0.340), pt(0.440, 0.320), pt(0.400, 0.280),
              pt(0.340, 0.230), pt(0.360, 0.200), pt(0.440, 0.168)],
             deep: true, in: &ctx, rect: rect)

        // Latissimus dorsi
        bilateral([pt(0.628, 0.260), pt(0.650, 0.300), pt(0.640, 0.350),
                   pt(0.610, 0.390), pt(0.560, 0.400), pt(0.555, 0.360),
                   pt(0.580, 0.300), pt(0.605, 0.270)], deep: true, in: &ctx, rect: rect)

        // Deltoid (rear head)
        bilateral([pt(0.605, 0.183), pt(0.670, 0.185), pt(0.728, 0.225),
                   pt(0.742, 0.270), pt(0.712, 0.300), pt(0.668, 0.270),
                   pt(0.648, 0.220)], in: &ctx, rect: rect)

        // Triceps brachii
        bilateral([pt(0.700, 0.265), pt(0.738, 0.262), pt(0.758, 0.305),
                   pt(0.750, 0.350), pt(0.722, 0.360), pt(0.698, 0.330),
                   pt(0.694, 0.292)], in: &ctx, rect: rect)

        // Forearm extensor mass
        bilateral([pt(0.705, 0.422), pt(0.748, 0.420), pt(0.770, 0.462),
                   pt(0.762, 0.502), pt(0.733, 0.516), pt(0.706, 0.497),
                   pt(0.700, 0.457)], in: &ctx, rect: rect)

        // Erector spinae
        bilateral([pt(0.500, 0.330), pt(0.520, 0.342), pt(0.525, 0.420),
                   pt(0.515, 0.450), pt(0.500, 0.452)], in: &ctx, rect: rect)

        // Gluteus maximus
        bilateral([pt(0.502, 0.465), pt(0.560, 0.462), pt(0.610, 0.478),
                   pt(0.628, 0.510), pt(0.615, 0.545), pt(0.560, 0.552),
                   pt(0.510, 0.540), pt(0.500, 0.500)], in: &ctx, rect: rect)

        // Hamstrings
        bilateral([pt(0.520, 0.560), pt(0.565, 0.552), pt(0.615, 0.565),
                   pt(0.628, 0.610), pt(0.620, 0.660), pt(0.595, 0.698),
                   pt(0.555, 0.700), pt(0.525, 0.670), pt(0.512, 0.610)],
                  in: &ctx, rect: rect)
        bilateralDivider([pt(0.578, 0.558), pt(0.582, 0.620), pt(0.572, 0.692)],
                          in: &ctx, rect: rect)

        // Calves — gastrocnemius outer + inner heads
        bilateral([pt(0.600, 0.762), pt(0.622, 0.770), pt(0.627, 0.800),
                   pt(0.610, 0.828), pt(0.590, 0.815), pt(0.588, 0.780)],
                  in: &ctx, rect: rect)
        bilateral([pt(0.555, 0.765), pt(0.580, 0.770), pt(0.585, 0.800),
                   pt(0.570, 0.828), pt(0.548, 0.815), pt(0.545, 0.780)],
                  in: &ctx, rect: rect)
    }
}

// MARK: - Preview

#Preview("Muscle — Front vs Back") {
    HStack(spacing: 24) {
        ZStack {
            MaleSilhouetteShape().fill(BodyLayer.muscle.silhouetteFill)
            MuscleAnatomyCanvas(facing: .front).clipShape(MaleSilhouetteShape())
            MaleSilhouetteShape().stroke(Color(.systemGray3), lineWidth: 1)
        }
        .frame(width: 160, height: 380)

        ZStack {
            MaleSilhouetteShape().fill(BodyLayer.muscle.silhouetteFill)
            MuscleAnatomyCanvas(facing: .back).clipShape(MaleSilhouetteShape())
            MaleSilhouetteShape().stroke(Color(.systemGray3), lineWidth: 1)
        }
        .frame(width: 160, height: 380)
    }
    .padding(40)
}
