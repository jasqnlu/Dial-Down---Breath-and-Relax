import SwiftUI

/// The shared "preview a set of exercises, adjust duration/order, decide
/// what to do with it" screen. Originally just Today's Customize button,
/// now reused by three flows that all boil down to the same job — review a
/// roadmap of exercises, tweak per-exercise duration and ordering, then
/// commit to an action:
///   - Today: `showsNameField: false`, `showsPinToggle: true`, "Begin" —
///     preview today's session, optionally pin it as the permanent Today
///     routine, then play it.
///   - Create New Routine: `showsNameField: true`, `showsPinToggle: false`,
///     "Save Routine" — name it and save to the Routines list.
///   - Start Mini-Routine: `showsNameField: false`, `showsPinToggle: false`,
///     "Start" — play once, nothing saved.
/// `RoutineBuilderView` remains the separate screen for *editing* an
/// already-saved routine (it also owns the Save/Update toolbar semantics
/// that make sense there but not here).
struct CustomizeRoutineView: View {
    let title: String
    let isPinned: Bool
    /// Shows a routine-name text field at the top, for flows that create a
    /// new saved `Routine` (Create New Routine). Today and Start
    /// Mini-Routine leave this off — neither one names anything.
    var showsNameField: Bool = false
    var initialName: String = ""
    /// Shows the "Keep as my Today routine" pin toggle — only meaningful
    /// for Today's own Customize flow.
    var showsPinToggle: Bool = true
    var primaryActionLabel: String = "Begin"
    var primaryActionIcon: String = "play.fill"
    /// Which tab index the cross-tab "Add Exercises" picking session should
    /// return to — see `ExercisePickingSession.Context.originTab`. Today's
    /// Customize is opened from the Today tab (0); routine-creation flows
    /// pass the tab they were opened from instead.
    var pickingOriginTab: Int = 0
    /// Hides the "Add Exercises" toolbar button — for flows already nested
    /// inside another `ExercisePickingSession` (MiniRoutineReviewView's
    /// "Create New Routine"/"Start Mini-Routine", both presented from a
    /// screen that only exists because a pick just finished). Beginning a
    /// second, cross-tab picking session from inside one of those doesn't
    /// have anywhere consistent to round-trip back to, so it mirrors
    /// RoutineBuilderView's own `allowsCrossTabAddExercise: false` for the
    /// same call sites, pre-unification.
    var showsAddExercisesButton: Bool = true
    let onDone: (_ name: String, _ exercises: [Exercise], _ pinned: Bool, _ durationOverrides: [UUID: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pinnedToggle: Bool
    @State private var currentExercises: [Exercise]
    /// Per-exercise duration overrides, keyed by exercise UUID — seconds.
    /// Absent key means "use the exercise's own durationSeconds." Passed
    /// back through `onDone` so the caller can save it onto the pinned
    /// Today routine / new routine and thread it into the SessionPlayerView
    /// that follows.
    @State private var durationOverrides: [UUID: Int] = [:]
    @State private var routineName: String
    @EnvironmentObject private var pickingSession: ExercisePickingSession
    /// Shared drag state for the exercise list's border-only drag handle
    /// (see `reorderableByBorder`/`RowReorderState`).
    @StateObject private var reorderState = RowReorderState()

    init(
        title: String, exercises: [Exercise], isPinned: Bool,
        showsNameField: Bool = false, initialName: String = "",
        showsPinToggle: Bool = true,
        primaryActionLabel: String = "Begin", primaryActionIcon: String = "play.fill",
        pickingOriginTab: Int = 0, showsAddExercisesButton: Bool = true,
        onDone: @escaping (_ name: String, _ exercises: [Exercise], _ pinned: Bool, _ durationOverrides: [UUID: Int]) -> Void
    ) {
        self.title = title
        self.isPinned = isPinned
        self.showsNameField = showsNameField
        self.initialName = initialName
        self.showsPinToggle = showsPinToggle
        self.primaryActionLabel = primaryActionLabel
        self.primaryActionIcon = primaryActionIcon
        self.pickingOriginTab = pickingOriginTab
        self.showsAddExercisesButton = showsAddExercisesButton
        self.onDone = onDone
        self._pinnedToggle = State(initialValue: isPinned)
        self._currentExercises = State(initialValue: exercises)
        self._routineName = State(initialValue: initialName)
    }

    private var totalSeconds: Int { currentExercises.reduce(0) { $0 + duration(for: $1) } }
    private var totalMinutes: Int { max(1, Int((Double(totalSeconds) / 60).rounded())) }

    private var canSubmit: Bool {
        !currentExercises.isEmpty
            && (!showsNameField || !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    /// The exercise's duration after applying this session's own override,
    /// if any — mirrors RoutineBuilderView's/SessionPlayerView's identically
    /// named helper.
    private func duration(for exercise: Exercise) -> Int {
        durationOverrides[exercise.uuid] ?? exercise.durationSeconds
    }

    private func adjustDuration(for exercise: Exercise, by delta: Int) {
        let next = max(5, duration(for: exercise) + delta)
        durationOverrides[exercise.uuid] = next
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }

    var body: some View {
        NavigationStack {
            // ZStack, not the List directly: the dragged row's floating
            // ghost (ReorderDragOverlay) needs to be a true sibling of the
            // List, not a `.overlay()` attached to it — List hosts each
            // row in its own UIKit-backed cell, and those cells composite
            // above a same-list overlay regardless of its z-order, so the
            // ghost rendered (confirmed correct position via logging) but
            // stayed invisible behind the rows. A ZStack sibling is a
            // separate layer stacked on top, outside the List's own
            // compositing.
            ZStack {
                // A List (rather than the old plain ScrollView+VStack) so
                // the exercise section can host drag-to-reorder rows (via
                // .reorderableByBorder, not List's own .onMove — see
                // LuminaTheme.swift) — same mechanism RoutineBuilderView's
                // own exercise list already uses. The summary/roadmap/
                // pin-toggle block above it rides along as a second,
                // non-reorderable section.
                List {
                    Section {
                        if showsNameField {
                            TextField("Routine name", text: $routineName)
                                .font(.luminaBody)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }

                        Text("\(currentExercises.count) EXERCISE\(currentExercises.count == 1 ? "" : "S") · \(totalMinutes) MIN")
                            .font(.luminaCaption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        RoadmapWave(exercises: currentExercises, numbered: true, durationOverrides: durationOverrides)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        if showsPinToggle {
                            saveToggleRow
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    Section {
                        ForEach(Array(currentExercises.enumerated()), id: \.element.uuid) { index, exercise in
                            exerciseRow(index: index, exercise: exercise)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                // Stable, index-based (not name-based) hook
                                // for UI tests to drag-reorder by — a
                                // name-based query would break once two
                                // rows swap places.
                                .accessibilityIdentifier("customizeExerciseRow-\(index)")
                                .reorderableByBorder(index: index, state: reorderState) {
                                    currentExercises.move(fromOffsets: $0, toOffset: $1)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.luminaSurface)

                ReorderDragOverlay(state: reorderState) { index in
                    if currentExercises.indices.contains(index) {
                        exerciseRow(index: index, exercise: currentExercises[index])
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                // Lives in the toolbar, not the scrolling list — a real
                // XCUITest run caught the earlier in-list placement landing
                // right against the fixed Begin bar below it (same class of
                // bug as the floating-tab-bar/safeAreaInset issue Task 15
                // hit): a tap meant for "Add Exercises" as the list's last
                // row actually triggered Begin instead. The toolbar has no
                // such neighbor and needs no scrolling to reach.
                if showsAddExercisesButton {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            pickingSession.begin(context: .init(
                                title: title,
                                isPinned: pinnedToggle,
                                baseExercises: currentExercises,
                                originTab: pickingOriginTab,
                                editingRoutineID: nil,
                                durationOverrides: [:]
                            ))
                            dismiss()
                            // Same "dismiss + switch tabs" need SessionPlayerView
                            // already has (Views/Session/SessionPlayerView.swift)
                            // — reusing the existing notification rather than
                            // adding a second one.
                            NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                        } label: {
                            Label("Add Exercises", systemImage: "plus")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onDone(routineName, currentExercises, pinnedToggle, durationOverrides)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: primaryActionIcon)
                        Text(primaryActionLabel)
                    }
                }
                .buttonStyle(LuminaPillButtonStyle(kind: .prominent))
                .frame(maxWidth: .infinity)
                .padding()
                .background(.regularMaterial)
                .disabled(!canSubmit)
            }
        }
    }

    private var saveToggleRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 34, height: 34)
                .background(Color.luminaMintTint, in: RoundedRectangle(cornerRadius: LuminaRadius.chip, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text("Keep as my Today routine")
                    .font(.luminaCardTitle)
                Text("Starts your day automatically · off = just for today")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $pinnedToggle)
                .labelsHidden()
                .tint(Color.luminaPrimary)
        }
        .luminaCard(padding: 14)
    }

    private func exerciseRow(index: Int, exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .frame(width: 22, height: 22)
                .background(Color.luminaContainer, in: Circle())

            let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
            PoseGlyphIcon(exercise: exercise, category: category, size: 46)

            Text(exercise.name)
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaOnSurface)
                .lineLimit(1)

            Spacer(minLength: 8)

            durationStepper(for: exercise)

            TapAgainToConfirmButton(
                // Default .top alignment centers the caption over the
                // button; since this remove button sits at the row's
                // trailing edge, the caption's right half clipped past
                // the card/screen edge. .topTrailing pins the caption's
                // trailing corner to the button's, so it grows leftward
                // and stays fully visible — mirrors SessionPlayerView's
                // own .leading override for its leading-edge close button.
                captionAlignment: .topTrailing,
                captionAnchor: .topTrailing,
                action: {
                    let removedID = currentExercises[index].uuid
                    currentExercises.remove(at: index)
                    durationOverrides.removeValue(forKey: removedID)
                }
            ) {
                Image(systemName: "minus.circle.fill")
            }
            .accessibilityLabel("Remove \(exercise.name)")
            .accessibilityIdentifier("removeExercise-\(exercise.uuid)")
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        // Without this, the row's own "customizeExerciseRow-N" identifier
        // (used for drag-reorder testing) swallows this remove button's
        // identifier into one merged row-level element — this keeps the
        // remove button (and the duration stepper's +/- buttons)
        // independently reachable, both for VoiceOver and UI tests.
        .accessibilityElement(children: .contain)
        .luminaCard(padding: 12)
    }

    /// Same stepper as RoutineBuilderView's identically named helper — 5s
    /// floor, 5s step, outline icons (vs. the row's own filled destructive
    /// remove button) so the two minus icons in the row read as distinct.
    private func durationStepper(for exercise: Exercise) -> some View {
        HStack(spacing: 6) {
            Button {
                adjustDuration(for: exercise, by: -5)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.luminaPrimary)

            Text(formatted(duration(for: exercise)))
                .font(.luminaLabel)
                .monospacedDigit()
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .frame(minWidth: 40)

            Button {
                adjustDuration(for: exercise, by: 5)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.luminaPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.name) duration, \(formatted(duration(for: exercise)))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjustDuration(for: exercise, by: 5)
            case .decrement: adjustDuration(for: exercise, by: -5)
            @unknown default: break
            }
        }
    }
}
