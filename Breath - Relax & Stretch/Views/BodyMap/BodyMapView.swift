import SwiftUI
import SwiftData

// MARK: - BodyMapView

struct BodyMapView: View {
    @AppStorage("bodyMapSex") private var bodyMapSex = "male"

    // Skin is the only body layer now — marking region colours still key off
    // BodyLayer, so this stays as the single source of truth for those tokens.
    private let currentLayer: BodyLayer = .skin
    @State private var facing: BodyFacing = .front

    // Regions the user has marked (by drawing on them or tapping them).
    // This is the single source of truth for "areas to train on".
    @State private var markedRegions: Set<String> = BodyMapLaunchState.initialMarkedRegions()
    @State private var showMarkedExercises = false

    // Annotation state
    @State private var annotationMode = UserDefaults.standard.bool(forKey: "debugMarkMode")
    @StateObject private var annotationStore = AnnotationStore()
    @State private var selectedTool: DrawingTool       = .pen
    @State private var selectedSensation: SensationColor = sensationColors[0]
    @State private var showLegend = false

    // Zoom & pan
    @State private var zoomScale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var lastPan: CGSize = .zero

    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 4
    private let fingerZoomThreshold: CGFloat = 2.2

    /// Individual fingers become tappable once zoomed in past the threshold.
    private var detailLevel: BodyDetail { zoomScale >= fingerZoomThreshold ? .fine : .normal }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────────────────
                if annotationMode {
                    annotationToolbarView
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                } else {
                    HStack(spacing: 8) {
                        Spacer(minLength: 0)
                        facingToggleButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // ── The body figure ───────────────────────────────────────────
                // All three layers (skin, muscle, skeleton) are freely-rotatable
                // 3D models with their own drag/pinch gestures. Marking needs a
                // fixed front/back projection, so entering Mark mode locks the
                // model's rotation and overlays the same invisible region grid,
                // calibrated to the same footprint regardless of layer.
                Group {
                    if !annotationMode {
                        BodySceneView(facing: facing, style: .skin)
                    } else {
                        GeometryReader { geo in
                            ZStack {
                                // Matches BodyFigureCanvas's own internal figure
                                // padding so the 3D render and the region grid it
                                // carries land in the same box.
                                BodySceneView(facing: facing,
                                              style: .skin,
                                              interactive: false)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 6)
                                BodyFigureCanvas(layer: currentLayer,
                                                 facing: facing,
                                                 detail: detailLevel,
                                                 annotationMode: annotationMode,
                                                 selectedTool: selectedTool,
                                                 selectedSensation: selectedSensation,
                                                 sex: bodyMapSex,
                                                 showSilhouette: false,
                                                 store: annotationStore,
                                                 markedRegions: $markedRegions)
                            }
                                .scaleEffect(zoomScale, anchor: .center)
                                .offset(panOffset)
                                // scaleEffect/offset are reversed during hit-testing, so
                                // taps and drawing still map onto the true region geometry.
                                .frame(width: geo.size.width, height: geo.size.height)
                                .contentShape(Rectangle())
                                .gesture(panGesture(container: geo.size))
                                .simultaneousGesture(magnifyGesture)
                                .clipped()
                                .overlay(alignment: .bottomTrailing) {
                                    zoomControls.padding(12)
                                }
                                .overlay(alignment: .top) {
                                    if detailLevel == .fine {
                                        Text("Zoom detail — tap fingers, toes, eyes & nose")
                                            .font(.caption2.weight(.medium))
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(.regularMaterial, in: Capsule())
                                            .padding(.top, 6)
                                            .transition(.opacity)
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.15), value: detailLevel)

                // ── Bottom bar ───────────────────────────────────────────────
                if annotationMode {
                    annotationPaletteView
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                } else if !markedRegions.isEmpty {
                    MarkedAreasBanner(
                        regionNames: markedRegions.sorted(),
                        onFind:  { showMarkedExercises = true },
                        onClear: { withAnimation { markedRegions.removeAll() } }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .floatingTabBarClearance()
            .navigationTitle(annotationMode ? "Mark Your Body" : "Body Map")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.25), value: facing)
            .animation(.easeInOut(duration: 0.2),  value: markedRegions.isEmpty)
            .animation(.easeInOut(duration: 0.2),  value: annotationMode)
            .navigationDestination(isPresented: $showMarkedExercises) {
                BodyPartExercisesView(bodyParts: markedRegions.sorted())
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            annotationMode.toggle()
                        }
                    } label: {
                        Label(
                            annotationMode ? "Done" : "Mark",
                            systemImage: annotationMode
                                ? "checkmark.circle.fill"
                                : "pencil.tip.crop.circle"
                        )
                    }
                    .accessibilityLabel(annotationMode ? "Finish marking" : "Mark areas by drawing")
                }
            }
            .sheet(isPresented: $showLegend) { LegendSheet() }
            .onAppear {
                markedRegions = BodyMapLaunchState.initialMarkedRegions(
                    savedRegions: UserDefaults.standard.stringArray(forKey: "bodymap.markedRegions")
                )
            }
        }
    }

    // MARK: - Facing control

    // Not a multi-option picker — a single toggle
    // between Front/Back — so it keeps its directional icon, restyled with
    // the same chip tokens (unselected LuminaChip look) rather than wrapped
    // in LuminaChip itself (which is text-only).
    private var facingToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.28)) {
                facing = facing == .front ? .back : .front
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .medium))
                Text(facing.rawValue)
                    .font(.luminaLabel)
            }
            .foregroundStyle(Color.luminaOnSurfaceVariant)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.luminaContainer, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle body facing — currently \(facing.rawValue)")
    }

    // MARK: - Zoom & pan

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(lastScale * value.magnification, minZoom), maxZoom)
            }
            .onEnded { _ in
                lastScale = zoomScale
                if zoomScale <= minZoom + 0.01 { resetZoom() }
            }
    }

    private func panGesture(container: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoomScale > 1, !annotationMode else { return }
                let proposed = CGSize(width:  lastPan.width  + value.translation.width,
                                      height: lastPan.height + value.translation.height)
                panOffset = clampPan(proposed, container: container)
            }
            .onEnded { _ in lastPan = panOffset }
    }

    private func clampPan(_ offset: CGSize, container: CGSize) -> CGSize {
        let maxX = max(0, (zoomScale - 1) * container.width  / 2)
        let maxY = max(0, (zoomScale - 1) * container.height / 2)
        return CGSize(width:  min(max(offset.width,  -maxX), maxX),
                      height: min(max(offset.height, -maxY), maxY))
    }

    private func stepZoom(_ delta: CGFloat) {
        let target = min(max(zoomScale + delta, minZoom), maxZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = target
            lastScale = target
            panOffset = .zero          // re-centre on button zoom
            lastPan   = .zero
        }
    }

    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = 1; lastScale = 1; panOffset = .zero; lastPan = .zero
        }
    }

    private var zoomControls: some View {
        VStack(spacing: 0) {
            zoomButton("plus")  { stepZoom(0.6) }
                .disabled(zoomScale >= maxZoom - 0.01)
            Divider().frame(width: 30)
            zoomButton("minus") { stepZoom(-0.6) }
                .disabled(zoomScale <= minZoom + 0.01)
            if zoomScale > minZoom + 0.01 {
                Divider().frame(width: 30)
                zoomButton("arrow.counterclockwise") { resetZoom() }
            }
        }
        .frame(width: 38)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.systemGray4), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
    }

    private func zoomButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 38, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon == "plus" ? "Zoom in"
                          : icon == "minus" ? "Zoom out" : "Reset zoom")
    }

    // MARK: - Annotation toolbar (top)

    private var annotationToolbarView: some View {
        HStack(spacing: 12) {
            // Tool picker
            HStack(spacing: 0) {
                ForEach(DrawingTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        Image(systemName: tool.icon)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 40, height: 36)
                            .foregroundStyle(selectedTool == tool ? .white : .primary)
                            .background(selectedTool == tool ? Color.accentColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel(tool.label)
                }
            }
            .background(Color.luminaContainer,
                        in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            Button { annotationStore.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .disabled(annotationStore.strokes.isEmpty)
            .accessibilityLabel("Undo last stroke")

            Button(role: .destructive) {
                withAnimation {
                    annotationStore.clear()
                    markedRegions.removeAll()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .disabled(annotationStore.strokes.isEmpty && markedRegions.isEmpty)
            .accessibilityLabel("Clear all marks")

            Button { showLegend = true } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Colour guide")
        }
    }

    // MARK: - Annotation palette (bottom)

    private var annotationPaletteView: some View {
        VStack(spacing: 8) {
            Text("Draw on the areas that hurt or feel tight — they’ll light up.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(sensationColors) { sc in
                    Button {
                        selectedSensation = sc
                        if selectedTool == .eraser { selectedTool = .pen }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(sc.color)
                                    .frame(width: 30, height: 30)
                                if selectedSensation.id == sc.id && selectedTool != .eraser {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 2.5)
                                        .frame(width: 30, height: 30)
                                }
                            }
                            Text(sc.label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(selectedSensation.id == sc.id && selectedTool != .eraser
                                                ? sc.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel("\(sc.label) colour")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyMapView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
