import SwiftUI

// MARK: - Body Figure Canvas
//
// One view, ONE coordinate space ("figure").  Everything — the silhouette,
// the saved ink, the interactive region overlays and the live-draw surface —
// is laid out against the same `figureSize`, so a drawn stroke maps exactly
// onto the body region beneath it.
//
// The important behaviour the user asked for:
//   • Drawing on the body MARKS the regions you draw over.
//   • Marked regions highlight in the layer colour and become the set of
//     areas the "Find Exercises" button trains on.
//   • Tapping a region (outside annotation mode) toggles its mark.
//
// Z-order (bottom → top):
//   1. Silhouette
//   2. Saved annotation ink (Canvas, isolated layer for eraser blend-mode)
//   3. Region overlays  (highlight + hit area)
//   4. Live-draw surface (annotation mode only)

struct BodyFigureCanvas: View {
    let layer: BodyLayer
    let facing: BodyFacing
    let detail: BodyDetail
    let annotationMode: Bool
    let selectedTool: DrawingTool
    let selectedSensation: SensationColor
    var sex: String = "male"            // "male" or "female"
    /// False when something else (e.g. the rotatable 3D skin model) is
    /// rendering behind this view — skips the vector silhouette + its
    /// facial/back detail lines so only regions + ink + live-draw show.
    var showSilhouette: Bool = true
    @ObservedObject var store: AnnotationStore
    @Binding var markedRegions: Set<String>

    @State private var currentPoints: [CGPoint] = []
    @State private var didDeriveMarks = false

    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let figureSpace = "figure"

    // TEMP: set true to visualise every region box for alignment tuning.
    private let debugRegions = false

    var body: some View {
        GeometryReader { geo in
            let figureSize = geo.size

            ZStack {
                if showSilhouette {
                    // 1. Silhouette (gender-specific)
                    silhouetteView

                    // 1b. Anatomical detail overlays — front view only
                    if facing == .front {
                        FacialFeaturesCanvas(sex: sex)
                        BodyDetailCanvas()
                    }

                    if facing == .back {
                        backDetailLines(in: figureSize)
                            .allowsHitTesting(false)
                    }
                }

                // 2. Saved ink for THIS facing — isolated compositing layer so the
                //    eraser's .destinationOut blend mode punches a transparent hole.
                Canvas { ctx, _ in
                    ctx.drawLayer { layerCtx in
                        for stroke in store.strokes where strokeFacing(stroke) == facing {
                            drawStroke(stroke, in: &layerCtx)
                        }
                    }
                }
                .allowsHitTesting(false)

                // 3. Region overlays — always rendered (highlights visible in
                //    both modes); only interactive when NOT drawing.
                regionOverlays(in: figureSize)

                // 4. Live-draw layer
                if annotationMode {
                    Canvas { ctx, _ in
                        guard !currentPoints.isEmpty else { return }
                        let path  = Path.smooth(through: currentPoints)
                        let style = StrokeStyle(lineWidth: selectedTool.lineWidth,
                                                lineCap: .round, lineJoin: .round)
                        if selectedTool == .eraser {
                            ctx.stroke(path, with: .color(.white.opacity(0.55)), style: style)
                        } else {
                            ctx.stroke(path,
                                       with: .color(selectedSensation.color.opacity(selectedTool.opacity)),
                                       style: style)
                        }
                    }
                    .allowsHitTesting(false)

                    Rectangle()
                        .fill(Color.white.opacity(0.001))   // invisible but hittable
                        .gesture(
                            DragGesture(minimumDistance: 0,
                                        coordinateSpace: .named(figureSpace))
                                .onChanged { currentPoints.append($0.location) }
                                .onEnded   { _ in commitStroke(in: figureSize) }
                        )
                }
            }
            .frame(width: figureSize.width, height: figureSize.height)
            .coordinateSpace(name: figureSpace)
            .onAppear {
                impact.prepare()
                guard !didDeriveMarks else { return }
                deriveMarks(in: figureSize)     // light up regions saved ink covers
                didDeriveMarks = true
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 6)
    }

    // MARK: - Gender-specific silhouette
    //
    // Skin stays a flat tinted silhouette; Muscle/Skeleton layer in the
    // anatomical artwork on top, clipped to the same outline.

    @ViewBuilder
    private var silhouetteView: some View {
        if sex == "female" {
            ZStack {
                FemaleSilhouetteShape().fill(layer.silhouetteFill)
                anatomyOverlay.clipShape(FemaleSilhouetteShape())
                FemaleSilhouetteShape().stroke(layer.accentColor.opacity(0.30), lineWidth: 1.2)
            }
        } else {
            ZStack {
                MaleSilhouetteShape().fill(layer.silhouetteFill)
                anatomyOverlay.clipShape(MaleSilhouetteShape())
                MaleSilhouetteShape().stroke(layer.accentColor.opacity(0.30), lineWidth: 1.2)
            }
        }
    }

    @ViewBuilder
    private var anatomyOverlay: some View {
        switch layer {
        case .skin:     EmptyView()
        case .muscle:   MuscleAnatomyCanvas(facing: facing)
        case .skeleton: SkeletonAnatomyCanvas(facing: facing)
        }
    }

    // MARK: - Region overlays

    @ViewBuilder
    private func regionOverlays(in size: CGSize) -> some View {
        let hl = layer.highlightColor

        ForEach(bodyRegions(for: facing, detail: detail)) { region in
            let r          = region.scaledRect(in: size)
            let isMarked   = markedRegions.contains(region.name)
            let cr         = region.cornerRadius * min(size.width, size.height) / 200
            let fillColor: Color   = isMarked ? hl.opacity(0.5)
                                   : (debugRegions ? Color.blue.opacity(0.10) : Color.white.opacity(0.001))
            let strokeColor: Color = isMarked ? hl
                                   : (debugRegions ? Color.blue.opacity(0.5) : Color.clear)

            // Highlight + hit area
            RoundedRectangle(cornerRadius: cr)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(strokeColor, lineWidth: isMarked ? 2 : 1)
                )
                .frame(width: r.width, height: r.height)
                .contentShape(Rectangle())
                .onTapGesture { toggle(region) }
                .position(x: r.midX, y: r.midY)
                .allowsHitTesting(!annotationMode)
                .accessibilityLabel(region.name)
                .accessibilityHint(isMarked
                    ? "Marked. Double tap to remove."
                    : "Double tap to mark this area and find exercises.")
                .accessibilityAddTraits(isMarked ? .isSelected : [])

            // Floating name label for marked regions
            if isMarked {
                Text(region.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(hl, in: Capsule())
                    .position(x: r.midX, y: r.minY - 8)
                    .allowsHitTesting(false)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Actions

    private func toggle(_ region: BodyRegion) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if markedRegions.contains(region.name) {
                markedRegions.remove(region.name)
            } else {
                markedRegions.insert(region.name)
                impact.impactOccurred()
            }
        }
    }

    /// Commit the in-progress stroke, then mark any regions it crossed.
    private func commitStroke(in size: CGSize) {
        defer { currentPoints = [] }
        guard !currentPoints.isEmpty else { return }

        let isEraser = selectedTool == .eraser
        store.strokes.append(
            AnnotationStroke(
                points:    currentPoints,
                colorID:   isEraser ? "eraser" : selectedSensation.id,
                lineWidth: selectedTool.lineWidth,
                opacity:   selectedTool.opacity,
                facing:    facing.rawValue
            )
        )
        store.save()

        guard !isEraser else { return }   // erasing removes ink, not marks

        // Which regions (of the current facing + detail) did this stroke cross?
        let newlyMarked = bodyRegions(for: facing, detail: detail)
            .filter { !markedRegions.contains($0.name) }
            .filter { region in
                let rect = region.scaledRect(in: size)
                return currentPoints.contains { rect.contains($0) }
            }
            .map(\.name)

        if !newlyMarked.isEmpty {
            withAnimation(.easeInOut(duration: 0.22)) {
                markedRegions.formUnion(newlyMarked)
            }
            impact.impactOccurred()
        }
    }

    /// On first appearance, light up regions covered by previously-saved ink.
    /// Each stroke is matched against the region set for its OWN facing, so
    /// front and back marks are derived correctly in one pass.
    private func deriveMarks(in size: CGSize) {
        for stroke in store.strokes where stroke.colorID != "eraser" {
            let pts     = stroke.cgPoints
            let regions = allRegions(for: strokeFacing(stroke))   // superset: catches fingers too
            for region in regions where !markedRegions.contains(region.name) {
                let rect = region.scaledRect(in: size)
                if pts.contains(where: { rect.contains($0) }) {
                    markedRegions.insert(region.name)
                }
            }
        }
    }

    private func strokeFacing(_ stroke: AnnotationStroke) -> BodyFacing {
        BodyFacing(rawValue: stroke.facing ?? BodyFacing.front.rawValue) ?? .front
    }

    // MARK: - Back-view detail (subtle spine + shoulder-blade hints)

    private func backDetailLines(in size: CGSize) -> some View {
        let w = size.width, h = size.height
        return Path { p in
            // Spine
            p.move(to: CGPoint(x: 0.50 * w, y: 0.180 * h))
            p.addLine(to: CGPoint(x: 0.50 * w, y: 0.470 * h))
            // Shoulder-blade hints
            p.move(to: CGPoint(x: 0.45 * w, y: 0.215 * h))
            p.addQuadCurve(to: CGPoint(x: 0.44 * w, y: 0.285 * h), control: CGPoint(x: 0.40 * w, y: 0.245 * h))
            p.move(to: CGPoint(x: 0.55 * w, y: 0.215 * h))
            p.addQuadCurve(to: CGPoint(x: 0.56 * w, y: 0.285 * h), control: CGPoint(x: 0.60 * w, y: 0.245 * h))
            // Waist / glute crease
            p.move(to: CGPoint(x: 0.50 * w, y: 0.490 * h))
            p.addLine(to: CGPoint(x: 0.50 * w, y: 0.545 * h))
        }
        .stroke(Color(.systemGray3).opacity(0.8),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    // MARK: - Canvas draw helper

    private func drawStroke(_ stroke: AnnotationStroke, in ctx: inout GraphicsContext) {
        let path  = stroke.smoothPath
        let style = StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        if stroke.colorID == "eraser" {
            ctx.blendMode = .destinationOut
            ctx.stroke(path, with: .color(.white), style: style)
            ctx.blendMode = .normal
        } else {
            let color = sensationColors.first { $0.id == stroke.colorID }?.color ?? .red
            ctx.stroke(path, with: .color(color.opacity(stroke.opacity)), style: style)
        }
    }
}
