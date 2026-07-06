import SwiftUI
import SwiftData

// MARK: - BodyMapView
//
// One 3D skin body map. Free-rotate to browse; enter Mark mode to freeze the
// current rotation and draw on the visible projection. Strokes resolve to
// anatomical muscle groups (via the invisible muscle proxy) and glow through the
// skin in 3D. Marks persist in `MuscleMarkStore`; the marked-areas banner feeds
// the exercise finder.

struct BodyMapView: View {
    @State private var rig = BodyRig()
    @StateObject private var store = MuscleMarkStore()

    @State private var facing: BodyFacing = .front
    @State private var annotationMode = UserDefaults.standard.bool(forKey: "debugMarkMode")

    @State private var selectedTool: DrawingTool        = .pen
    @State private var selectedSensation: SensationColor = sensationColors[0]
    @State private var showLegend = false
    @State private var showMarkedExercises = false

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
                    HStack {
                        Spacer()
                        facingToggleButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // ── The 3D body ──────────────────────────────────────────────
                if rig.loadFailed {
                    ContentUnavailableView(
                        "3D Model Unavailable",
                        systemImage: "figure.stand",
                        description: Text("The body model couldn't be loaded.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ZStack(alignment: .top) {
                        MarkableBodyView(
                            rig: rig,
                            markMode: annotationMode,
                            inkColor: inkColor,
                            onStrokePoint: handleStrokePoint,
                            onStrokeEnded: {}
                        )
                        Text(annotationMode ? "Draw on the areas that hurt or feel tight"
                                            : "Drag to rotate · pinch to zoom")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.top, 6)
                            .opacity(0.85)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // ── Bottom bar ───────────────────────────────────────────────
                if annotationMode {
                    annotationPaletteView
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                } else if !store.marks.isEmpty {
                    MarkedAreasBanner(
                        regionNames: store.markedNames.sorted(),
                        onFind:  { showMarkedExercises = true },
                        onClear: { withAnimation { store.clear() } }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .floatingTabBarClearance()
            .navigationTitle(annotationMode ? "Mark Areas" : "Body Map")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.25), value: facing)
            .animation(.easeInOut(duration: 0.2),  value: store.marks.isEmpty)
            .animation(.easeInOut(duration: 0.2),  value: annotationMode)
            .navigationDestination(isPresented: $showMarkedExercises) {
                BodyPartExercisesView(bodyParts: store.markedNames.sorted())
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { annotationMode.toggle() }
                    } label: {
                        Label(annotationMode ? "Done" : "Mark",
                              systemImage: annotationMode
                                  ? "checkmark.circle.fill"
                                  : "pencil.tip.crop.circle")
                    }
                    .accessibilityLabel(annotationMode ? "Finish marking" : "Mark areas by drawing")
                }
            }
            .sheet(isPresented: $showLegend) { LegendSheet() }
            .onAppear(perform: applyHighlights)
            .onChange(of: store.marks) { _, _ in applyHighlights() }
        }
    }

    // MARK: - Stroke handling

    private var inkColor: UIColor {
        selectedTool == .eraser ? UIColor.systemGray : UIColor(selectedSensation.color)
    }

    private func handleStrokePoint(_ group: MuscleGroup?) {
        guard let group else { return }
        if selectedTool == .eraser {
            store.unmark(group)
        } else {
            store.mark(group, colorID: selectedSensation.id)
        }
    }

    private func applyHighlights() {
        let colors: [String: UIColor] = store.marks.reduce(into: [:]) { dict, pair in
            let swiftColor = sensationColors.first { $0.id == pair.value }?.color ?? .red
            dict[pair.key] = UIColor(swiftColor)
        }
        rig.setHighlights(colors, resolver: { rig.proxyGroups[$0] })
    }

    // MARK: - Facing control

    private var facingToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.28)) {
                facing = facing == .front ? .back : .front
            }
            rig.snap(to: facing == .front ? 0 : .pi)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .medium))
                Text(facing.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle body facing — currently \(facing.rawValue)")
    }

    // MARK: - Annotation toolbar (top)

    private var annotationToolbarView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(DrawingTool.allCases) { tool in
                    Button { selectedTool = tool } label: {
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
            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            Button { store.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .disabled(store.marks.isEmpty)
            .accessibilityLabel("Undo last mark")

            Button(role: .destructive) {
                withAnimation { store.clear() }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .disabled(store.marks.isEmpty)
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
