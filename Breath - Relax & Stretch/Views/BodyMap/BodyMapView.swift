import SwiftUI
import SwiftData

// MARK: - BodyMapView
//
// One freely-rotatable 3D body in both modes. "Mark" mode adds tap-to-mark:
// pick a sensation, tap a muscle to mark it (marker dot + chip), tap again
// with the same sensation to unmark, different sensation to recolor.
// Hit-testing raycasts the skin mesh and resolves the point in pure Swift
// (MuscleHitResolver), so rotation stays free while marking.

struct BodyMapView: View {
    @State private var facing: BodyFacing = .front
    @State private var isMarking = UserDefaults.standard.bool(forKey: "debugMarkMode")
    @StateObject private var markStore = BodyMarkStore()
    @State private var selectedSensation: SensationColor = sensationColors[0]
    @State private var showMarkedExercises = false
    @State private var showLegend = false

    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────────────────
                HStack(spacing: 8) {
                    if isMarking {
                        Text("Tap a muscle to mark it — tap again to remove.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button { showLegend = true } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("Colour guide")
                        Button(role: .destructive) {
                            withAnimation { markStore.clear() }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 36)
                        }
                        .disabled(markStore.marks.isEmpty)
                        .accessibilityLabel("Clear all marks")
                    } else {
                        Spacer(minLength: 0)
                        facingToggleButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // ── The body — one freely-rotatable 3D view in both modes ────
                BodySceneView(facing: facing,
                              style: .skin,
                              marks: markStore.marks,
                              onRegionTap: regionTapHandler)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Bottom bar ───────────────────────────────────────────────
                if isMarking {
                    sensationPalette
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                } else if !markStore.marks.isEmpty {
                    MarkedAreasBanner(
                        regionNames: markStore.markedRegions.sorted(),
                        onFind:  { showMarkedExercises = true },
                        onClear: { withAnimation { markStore.clear() } }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .floatingTabBarClearance()
            .navigationTitle(isMarking ? "Mark Areas" : "Body Map")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.2), value: markStore.marks.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: isMarking)
            .navigationDestination(isPresented: $showMarkedExercises) {
                BodyPartExercisesView(bodyParts: markStore.markedRegions.sorted())
            }
            .toolbar { markToolbar }
            .sheet(isPresented: $showLegend) { LegendSheet() }
            .onAppear { impact.prepare() }
        }
    }

    @ToolbarContentBuilder
    private var markToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isMarking.toggle() }
            } label: {
                Label(isMarking ? "Done" : "Mark",
                      systemImage: isMarking ? "checkmark.circle.fill" : "hand.point.up.left.fill")
            }
            .accessibilityLabel(isMarking ? "Finish marking" : "Mark areas by tapping")
        }
    }

    /// Taps only mark while in marking mode; plain viewing never hit-tests.
    private var regionTapHandler: ((String, SIMD3<Float>) -> Void)? {
        guard isMarking else { return nil }
        return { region, point in handleRegionTap(region: region, point: point) }
    }

    private func handleRegionTap(region: String, point: SIMD3<Float>) {
        withAnimation(.easeInOut(duration: 0.18)) {
            markStore.toggle(region: region, sensationID: selectedSensation.id, point: point)
        }
        impact.impactOccurred()
    }

    // MARK: - Facing control

    // Not a multi-option picker — a single toggle between Front/Back — so it
    // keeps its directional icon, restyled with the same chip tokens
    // (unselected LuminaChip look) rather than wrapped in LuminaChip itself
    // (which is text-only). Hidden while marking: rotation is free, so the
    // user just drags.
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

    // MARK: - Sensation palette (bottom, marking mode)

    private var sensationPalette: some View {
        HStack(spacing: 0) {
            ForEach(sensationColors) { sc in
                Button { selectedSensation = sc } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(sc.color).frame(width: 30, height: 30)
                            if selectedSensation.id == sc.id {
                                Circle().strokeBorder(.white, lineWidth: 2.5)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        Text(sc.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(selectedSensation.id == sc.id ? sc.color : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("\(sc.label) colour")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyMapView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
