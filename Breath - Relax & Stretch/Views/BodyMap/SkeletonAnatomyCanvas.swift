import SwiftUI

// MARK: - Skeleton Anatomy Canvas
//
// Stylised "major bones" replica of a front/back skeleton diagram. Same
// technique and coordinate space as MuscleAnatomyCanvas: filled blobs for
// bone masses, plain stroked lines for ribs/vertebra segments, right-side
// authored + mirrored for the left.

struct SkeletonAnatomyCanvas: View {
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

    private let boneFill   = Color(red: 0.93, green: 0.90, blue: 0.82).opacity(0.92)
    private let boneStroke = Color(red: 0.50, green: 0.47, blue: 0.41).opacity(0.85)

    // MARK: Drawing primitives

    private func bone(_ points: [CGPoint], in ctx: inout GraphicsContext, rect: CGRect) {
        let path = anatomyBlob(points, in: rect)
        ctx.fill(path, with: .color(boneFill))
        ctx.stroke(path, with: .color(boneStroke), style: StrokeStyle(lineWidth: 0.9))
    }

    private func bilateral(_ points: [CGPoint], in ctx: inout GraphicsContext, rect: CGRect) {
        bone(points, in: &ctx, rect: rect)
        bone(points.map(mirrorX), in: &ctx, rect: rect)
    }

    private func boneLine(_ points: [CGPoint], width: CGFloat = 1,
                           in ctx: inout GraphicsContext, rect: CGRect) {
        ctx.stroke(anatomyLine(points, in: rect), with: .color(boneStroke),
                   style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func bilateralLine(_ points: [CGPoint], width: CGFloat = 1,
                                in ctx: inout GraphicsContext, rect: CGRect) {
        boneLine(points, width: width, in: &ctx, rect: rect)
        boneLine(points.map(mirrorX), width: width, in: &ctx, rect: rect)
    }

    /// Shared pelvis outline — anatomically the front/back views differ, but at
    /// this stylisation level the same silhouette reads fine clipped from
    /// either facing (sacrum/pubic-arch hint differs, drawn separately).
    private var pelvisOutline: [CGPoint] {
        [pt(0.500, 0.450), pt(0.560, 0.452), pt(0.620, 0.465), pt(0.648, 0.490),
         pt(0.630, 0.515), pt(0.580, 0.520), pt(0.540, 0.515), pt(0.500, 0.525),
         pt(0.460, 0.515), pt(0.420, 0.520), pt(0.370, 0.515), pt(0.352, 0.490),
         pt(0.380, 0.465), pt(0.440, 0.452)]
    }

    private var humerus: [CGPoint] {
        [pt(0.700, 0.225), pt(0.715, 0.222), pt(0.722, 0.300),
         pt(0.715, 0.355), pt(0.700, 0.358), pt(0.692, 0.300)]
    }
    private var radius: [CGPoint] {
        [pt(0.700, 0.365), pt(0.710, 0.363), pt(0.718, 0.470),
         pt(0.710, 0.515), pt(0.700, 0.513), pt(0.694, 0.470)]
    }
    private var ulna: [CGPoint] {
        [pt(0.715, 0.365), pt(0.725, 0.363), pt(0.732, 0.460),
         pt(0.726, 0.505), pt(0.716, 0.503), pt(0.710, 0.460)]
    }
    private var handBones: [CGPoint] {
        [pt(0.700, 0.520), pt(0.730, 0.518), pt(0.745, 0.560),
         pt(0.730, 0.580), pt(0.700, 0.578), pt(0.690, 0.550)]
    }
    private var femur: [CGPoint] {
        [pt(0.560, 0.530), pt(0.575, 0.528), pt(0.585, 0.620),
         pt(0.580, 0.695), pt(0.560, 0.698), pt(0.550, 0.620)]
    }
    private var tibia: [CGPoint] {
        [pt(0.555, 0.715), pt(0.570, 0.713), pt(0.578, 0.820),
         pt(0.572, 0.875), pt(0.558, 0.873), pt(0.548, 0.820)]
    }
    private var fibula: [CGPoint] {
        [pt(0.585, 0.718), pt(0.594, 0.716), pt(0.600, 0.810),
         pt(0.594, 0.860), pt(0.586, 0.858), pt(0.580, 0.810)]
    }
    private var footBones: [CGPoint] {
        [pt(0.545, 0.880), pt(0.580, 0.878), pt(0.615, 0.895),
         pt(0.610, 0.918), pt(0.560, 0.925), pt(0.535, 0.910), pt(0.535, 0.890)]
    }

    private func drawLimbs(in ctx: inout GraphicsContext, rect: CGRect, includePatella: Bool) {
        bilateral(humerus, in: &ctx, rect: rect)
        bilateral(radius, in: &ctx, rect: rect)
        bilateral(ulna, in: &ctx, rect: rect)
        bilateral(handBones, in: &ctx, rect: rect)
        bilateral(femur, in: &ctx, rect: rect)
        if includePatella {
            bilateral([pt(0.553, 0.695), pt(0.575, 0.693), pt(0.580, 0.712),
                       pt(0.565, 0.722), pt(0.550, 0.710)], in: &ctx, rect: rect)
        }
        bilateral(tibia, in: &ctx, rect: rect)
        bilateral(fibula, in: &ctx, rect: rect)
        bilateral(footBones, in: &ctx, rect: rect)
    }

    // MARK: - Front

    private func drawFront(in ctx: inout GraphicsContext, rect: CGRect) {
        // Skull + jaw (symmetric — drawn once, not mirrored)
        bone([pt(0.500, 0.006), pt(0.560, 0.020), pt(0.585, 0.055), pt(0.580, 0.095),
              pt(0.558, 0.125), pt(0.520, 0.140), pt(0.500, 0.142), pt(0.480, 0.140),
              pt(0.442, 0.125), pt(0.420, 0.095), pt(0.415, 0.055), pt(0.440, 0.020)],
             in: &ctx, rect: rect)

        // Eye sockets
        bilateral([pt(0.440, 0.070), pt(0.462, 0.063), pt(0.484, 0.070), pt(0.462, 0.085)],
                   in: &ctx, rect: rect)
        // Nasal cavity
        bone([pt(0.492, 0.085), pt(0.508, 0.085), pt(0.500, 0.105)], in: &ctx, rect: rect)

        // Cervical spine
        bone([pt(0.488, 0.145), pt(0.512, 0.145), pt(0.514, 0.185), pt(0.486, 0.185)],
             in: &ctx, rect: rect)
        boneLine([pt(0.487, 0.155), pt(0.513, 0.155)], width: 0.7, in: &ctx, rect: rect)
        boneLine([pt(0.487, 0.165), pt(0.513, 0.165)], width: 0.7, in: &ctx, rect: rect)
        boneLine([pt(0.487, 0.175), pt(0.513, 0.175)], width: 0.7, in: &ctx, rect: rect)

        // Clavicle
        bilateral([pt(0.512, 0.178), pt(0.560, 0.172), pt(0.610, 0.178), pt(0.650, 0.195),
                   pt(0.640, 0.205), pt(0.600, 0.190), pt(0.555, 0.184), pt(0.512, 0.188)],
                  in: &ctx, rect: rect)

        // Sternum
        bone([pt(0.490, 0.190), pt(0.510, 0.190), pt(0.512, 0.300), pt(0.500, 0.310),
              pt(0.488, 0.300)], in: &ctx, rect: rect)

        // Ribcage (stroked curves, sternum → side)
        let ribsFront: [[CGPoint]] = [
            [pt(0.495, 0.195), pt(0.560, 0.198), pt(0.605, 0.215)],
            [pt(0.495, 0.215), pt(0.565, 0.220), pt(0.618, 0.240)],
            [pt(0.495, 0.235), pt(0.568, 0.242), pt(0.625, 0.265)],
            [pt(0.495, 0.255), pt(0.568, 0.264), pt(0.628, 0.290)],
            [pt(0.495, 0.275), pt(0.565, 0.286), pt(0.622, 0.312)],
            [pt(0.495, 0.293), pt(0.558, 0.305), pt(0.610, 0.330)],
        ]
        for rib in ribsFront { bilateralLine(rib, width: 1.1, in: &ctx, rect: rect) }

        // Pelvis
        bone(pelvisOutline, in: &ctx, rect: rect)

        drawLimbs(in: &ctx, rect: rect, includePatella: true)
    }

    // MARK: - Back

    private func drawBack(in ctx: inout GraphicsContext, rect: CGRect) {
        // Skull (no jaw line — smooth from behind)
        bone([pt(0.500, 0.006), pt(0.560, 0.020), pt(0.582, 0.055), pt(0.578, 0.095),
              pt(0.555, 0.125), pt(0.500, 0.135), pt(0.445, 0.125), pt(0.422, 0.095),
              pt(0.418, 0.055), pt(0.440, 0.020)], in: &ctx, rect: rect)

        // Cervical + thoracic + lumbar spine (fully visible from behind)
        bone([pt(0.490, 0.145), pt(0.510, 0.145), pt(0.516, 0.300), pt(0.518, 0.400),
              pt(0.508, 0.450), pt(0.492, 0.450), pt(0.482, 0.400), pt(0.484, 0.300)],
             in: &ctx, rect: rect)
        for i in 0..<14 {
            let y = 0.155 + Double(i) * 0.021
            let inset = 0.001 * Double(i)
            boneLine([pt(0.486 + inset, y), pt(0.514 - inset, y)], width: 0.6, in: &ctx, rect: rect)
        }

        // Scapula
        bilateral([pt(0.560, 0.200), pt(0.620, 0.210), pt(0.635, 0.260),
                   pt(0.610, 0.300), pt(0.575, 0.290), pt(0.558, 0.240)], in: &ctx, rect: rect)

        // Ribcage (posterior curves, spine → side)
        let ribsBack: [[CGPoint]] = [
            [pt(0.508, 0.195), pt(0.560, 0.200), pt(0.600, 0.218)],
            [pt(0.510, 0.215), pt(0.565, 0.222), pt(0.612, 0.242)],
            [pt(0.512, 0.235), pt(0.568, 0.244), pt(0.618, 0.266)],
            [pt(0.512, 0.255), pt(0.568, 0.266), pt(0.620, 0.290)],
        ]
        for rib in ribsBack { bilateralLine(rib, width: 1.1, in: &ctx, rect: rect) }

        // Pelvis + sacrum
        bone(pelvisOutline, in: &ctx, rect: rect)
        bone([pt(0.485, 0.450), pt(0.515, 0.450), pt(0.512, 0.490), pt(0.500, 0.500),
              pt(0.488, 0.490)], in: &ctx, rect: rect)

        drawLimbs(in: &ctx, rect: rect, includePatella: false)
    }
}

// MARK: - Preview

#Preview("Skeleton — Front vs Back") {
    HStack(spacing: 24) {
        ZStack {
            MaleSilhouetteShape().fill(BodyLayer.skeleton.silhouetteFill)
            SkeletonAnatomyCanvas(facing: .front).clipShape(MaleSilhouetteShape())
            MaleSilhouetteShape().stroke(Color(.systemGray3), lineWidth: 1)
        }
        .frame(width: 160, height: 380)

        ZStack {
            MaleSilhouetteShape().fill(BodyLayer.skeleton.silhouetteFill)
            SkeletonAnatomyCanvas(facing: .back).clipShape(MaleSilhouetteShape())
            MaleSilhouetteShape().stroke(Color(.systemGray3), lineWidth: 1)
        }
        .frame(width: 160, height: 380)
    }
    .padding(40)
}
