import SwiftUI
import SwiftData

// MARK: - BodyMapView
//
// One freely-rotatable 3D body in both modes. "Mark" mode adds tap-to-mark:
// pick a sensation, tap a muscle to mark it (marker dot + chip), tap again
// with the same sensation to unmark, different sensation to recolor.
// Hit-testing raycasts the skin mesh and resolves the point in pure Swift
// (MuscleHitResolver), so rotation stays free while marking.

/// A tapped-but-not-yet-confirmed mark. Session-only — never touches
/// `BodyMarkStore` until the user taps Confirm, and there's at most one at a
/// time: a new tap silently replaces it rather than accumulating.
private struct PendingMark: Equatable {
    let region: String
    let point: SIMD3<Float>
}

struct BodyMapView: View {
    @State private var facing: BodyFacing = .front
    @State private var isMarking = UserDefaults.standard.bool(forKey: "debugMarkMode")
    @StateObject private var markStore = BodyMarkStore()
    @State private var selectedSensation: SensationColor = sensationColors[0]
    @State private var showMarkedExercises = false
    @State private var showLegend = false

    // MARK: - Single-focus confirm/disambiguate flow
    @State private var pendingMark: PendingMark?
    @State private var disambiguationCandidates: [MarkCandidate] = []
    /// The tapped dot the camera zooms onto — kept alive across navigation so
    /// Back returns to the same zoomed framing.
    @State private var focusPoint: SIMD3<Float>?
    /// The currently highlighted candidate (its region box brightened).
    @State private var focusedRegion: String?
    @State private var showConfirmedExercises = false
    @State private var confirmedRegion = ""
    /// Bumped when the exercise list is popped, to nudge BodySceneView to
    /// re-apply the zoom and re-project labels (the covered SCNView goes stale).
    @State private var refocusToken = 0

    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────────────────
                HStack(spacing: 8) {
                    if isDisambiguating {
                        Text("Which area did you mean?")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button("Cancel", role: .cancel) { cancelDisambiguation() }
                            .font(.caption.weight(.medium))
                    } else if isMarking {
                        Text(pendingMark == nil
                             ? "Tap a spot that feels tense or sore."
                             : "Tap ✓ above to see stretches for this spot.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button { showLegend = true } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("Colour guide")
                        Button("Cancel", role: .cancel) {
                            exitMarking()
                        }
                        .font(.caption.weight(.medium))
                        .accessibilityLabel("Cancel marking")
                    } else {
                        Spacer(minLength: 0)
                        facingToggleButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // ── The body — one freely-rotatable 3D view in both modes ────
                BodySceneView(facing: facing,
                              style: .anatomy,
                              marks: displayMarks,
                              onRegionTap: regionTapHandler,
                              disambiguationCandidates: disambiguationCandidates,
                              focusPoint: focusPoint,
                              focusedRegion: focusedRegion,
                              onCandidateFocused: handleCandidateFocused,
                              onCandidateSelected: handleCandidateSelected,
                              refocusToken: refocusToken)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Bottom bar ───────────────────────────────────────────────
                if isMarking && !isDisambiguating {
                    sensationPalette
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                } else if !markStore.marks.isEmpty && !isDisambiguating {
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
            .navigationDestination(isPresented: $showConfirmedExercises) {
                BodyPartExercisesView(bodyPart: confirmedRegion)
            }
            .onChange(of: showConfirmedExercises) { _, showing in
                // Popped back to the zoom — re-drive the scene so the body
                // re-renders and the labels re-project (Phase C).
                if !showing && !disambiguationCandidates.isEmpty {
                    refocusToken += 1
                }
            }
            .toolbar { markToolbar }
            .sheet(isPresented: $showLegend) { LegendSheet() }
            .onAppear { impact.prepare() }
        }
    }

    // The single primary action, in the prominent top-right slot users reach
    // for. While marking, it's Confirm (the ONE checkmark — see the bug where
    // a second, duplicate checkmark here silently discarded the mark). While
    // disambiguating, the in-view pins are the only action, so no toolbar
    // button. Otherwise it enters marking mode.
    @ToolbarContentBuilder
    private var markToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if isMarking && isDisambiguating {
                // Active disambiguation — the region boxes / side-rail labels
                // are the only action, so no toolbar button.
                EmptyView()
            } else if isMarking {
                Button {
                    confirmPendingMark()
                } label: {
                    Label("Confirm", systemImage: "checkmark.circle.fill")
                }
                .disabled(pendingMark == nil)
                .accessibilityLabel("Confirm marked area")
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Start each marking session fresh — clear the previously
                        // confirmed dot so it doesn't linger into the new one.
                        markStore.clear()
                        isMarking = true
                        resetSessionMarkState()
                    }
                } label: {
                    Label("Mark", systemImage: "hand.point.up.left.fill")
                }
                .accessibilityLabel("Mark areas by tapping")
            }
        }
    }

    private func exitMarking() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isMarking = false
            resetSessionMarkState()
        }
    }

    /// Taps only mark while in marking mode, and never while the
    /// disambiguation popup is up (pin taps are the only input then, and
    /// the camera is under programmatic control).
    private var regionTapHandler: ((String, SIMD3<Float>) -> Void)? {
        guard isMarking, !isDisambiguating else { return nil }
        return { region, point in handleRegionTap(region: region, point: point) }
    }

    /// One dot at a time: a tap always replaces whatever mark was pending,
    /// rather than accumulating. Nothing is persisted to `BodyMarkStore`
    /// until Confirm — see `confirmPendingMark`.
    private func handleRegionTap(region: String, point: SIMD3<Float>) {
        withAnimation(.easeInOut(duration: 0.18)) {
            pendingMark = PendingMark(region: region, point: point)
        }
        impact.impactOccurred()
    }

    /// Single-focus: while placing a dot, show ONLY the new pending dot — not
    /// the previously confirmed one — so a fresh tap never leaves the old dot
    /// behind. With no pending dot, show whatever single mark is persisted.
    private var displayMarks: [String: BodyMark] {
        if let pendingMark {
            return ["__pending__": BodyMark(sensationID: selectedSensation.id, point: pendingMark.point)]
        }
        return markStore.marks
    }

    private var isDisambiguating: Bool { !disambiguationCandidates.isEmpty }

    /// Confirm step: always zoom into the dot and surface the muscle groups
    /// plausibly meant by the tap (`MuscleHitResolver.candidates`) as labeled
    /// pins — the whole point is to let the user disambiguate *which* muscle
    /// they mean before seeing exercises. Only if no hit volume resolves at
    /// all (shouldn't happen for a real tap) do we fall back to navigating
    /// straight to the tapped region.
    private func confirmPendingMark() {
        guard let pendingMark else { return }

        // The head fans out into fixed, evidence-based face zones with
        // hand-tuned anchors instead of geometric hit-box candidates. Side is
        // inferred from the tapped x (see HeadZones).
        if pendingMark.region == "Head" {
            let pins = HeadZones.candidates(forTapAt: pendingMark.point)
            focusPoint = pendingMark.point
            focusedRegion = pins.first?.name
            disambiguationCandidates = pins
            return
        }
        // Pull a few extra candidates so that, after dropping any parent group
        // whose heads are already present, we still have a full set of ≤4.
        let raw = MuscleHitResolver.candidates(near: pendingMark.point,
                                               in: BodyHitVolumes.all, maxCandidates: 6)
        let presentParents = Set(raw.compactMap { MuscleGroup.parentOfHead($0) })
        let candidates = raw.filter { !presentParents.contains($0) }.prefix(4)
        let volumesByName = Dictionary(uniqueKeysWithValues: BodyHitVolumes.all.map { ($0.name, $0) })
        let pins = candidates.compactMap { name in
            volumesByName[name].map {
                MarkCandidate(name: name, point: $0.center,
                              minBound: $0.minBound, maxBound: $0.maxBound)
            }
        }
        if pins.isEmpty {
            commitAndNavigate(region: pendingMark.region, point: pendingMark.point)
        } else {
            // Zoom onto the actual tapped dot (not a candidate centre) and
            // auto-highlight the primary candidate.
            focusPoint = pendingMark.point
            focusedRegion = pins.first?.name
            disambiguationCandidates = pins
        }
    }

    /// First tap on a candidate (region box or side label) highlights it.
    private func handleCandidateFocused(_ region: String) {
        withAnimation(.easeInOut(duration: 0.15)) { focusedRegion = region }
        impact.impactOccurred()
    }

    /// Second tap on the focused candidate → drill into its exercises.
    private func handleCandidateSelected(_ region: String) {
        let point = focusPoint
            ?? BodyHitVolumes.all.first { $0.name == region }?.center
            ?? .zero
        commitAndNavigate(region: region, point: point)
    }

    /// Persists the mark at the tapped dot and navigates to the region's
    /// exercises — but deliberately KEEPS the zoom/candidate/focus state alive
    /// so pressing Back returns to the zoomed dot (see Phase C). The state is
    /// only torn down when the user taps Mark again (or Cancel).
    private func commitAndNavigate(region: String, point: SIMD3<Float>) {
        markStore.setMark(region: region, sensationID: selectedSensation.id, point: point)
        pendingMark = nil              // persisted mark now carries the dot
        isMarking = false
        confirmedRegion = region
        showConfirmedExercises = true
    }

    private func cancelDisambiguation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            disambiguationCandidates = []
            focusPoint = nil
            focusedRegion = nil
        }
    }

    private func resetSessionMarkState() {
        pendingMark = nil
        disambiguationCandidates = []
        focusPoint = nil
        focusedRegion = nil
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
