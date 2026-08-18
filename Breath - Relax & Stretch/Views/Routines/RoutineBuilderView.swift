import SwiftUI
import SwiftData
import os

struct RoutineBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var pickingSession: ExercisePickingSession

    @Query private var exercises: [Exercise]

    var routineToEdit: Routine? = nil
    /// Exercise IDs to fold in on appear — e.g. a set just picked in the
    /// Exercises tab's standalone picking mode (see
    /// `MiniRoutineReviewView`). Appended after `routineToEdit`'s existing
    /// exercises (or seeded fresh when creating), de-duped via
    /// `RoutineIDMerge` so a pick that's already in the routine isn't
    /// doubled.
    var initialExerciseIDs: [UUID] = []
    /// Suggested name to pre-fill when creating a brand-new routine from a
    /// template (e.g. a tapped PremadeRoutine card) — nil for the normal
    /// create/edit flows, which leave the name field blank or pull it from
    /// `routineToEdit`. Never applied when `routineToEdit` is set — editing
    /// an existing routine always keeps its own name.
    var initialName: String? = nil
    /// Called right after a successful save (create or update), before
    /// `dismiss()`. Distinct from dismissal itself so a caller driving this
    /// view from a review flow (`MiniRoutineReviewView`) can tell "saved"
    /// apart from "cancelled" — the sheet's own `onDismiss` fires either way
    /// and can't make that distinction.
    var onSaved: (() -> Void)? = nil
    /// Exact form state to restore after a cross-tab "Add Exercise" round
    /// trip — a hard replace, not a merge. Set only by RoutineListView's
    /// re-presentation after `.exercisePickingFinished`; nil for every
    /// other entry into this view. When set, takes priority over
    /// `routineToEdit`/`initialExerciseIDs`/`initialName` entirely — see
    /// this task's design note for why a merge here would be wrong.
    var restoredState: (name: String, exerciseIDs: [UUID], durationOverrides: [UUID: Int])? = nil

    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var indexPendingRemoval: Int?
    /// Per-exercise duration overrides, keyed by exercise UUID — seconds.
    /// Absent key means "use the exercise's own durationSeconds." Persisted
    /// onto `Routine.exerciseDurationOverrides` on save.
    @State private var durationOverrides: [UUID: Int] = [:]
    /// Guards the "creating new" onAppear branch so initialExerciseIDs/
    /// initialName are only seeded once. Without this, a future dismiss-and-
    /// re-present of this same sheet (e.g. after a cross-tab exercise pick)
    /// would re-fire onAppear and silently overwrite a name the user had
    /// already typed.
    @State private var didApplySeed = false

    private var isEditing: Bool { routineToEdit != nil }

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + duration(for: $1) }
    }

    /// The exercise's duration after applying this form's own override, if
    /// any — the single point every duration read in this view goes
    /// through, mirroring SessionPlayerView's `effectiveDuration(for:)`.
    private func duration(for exercise: Exercise) -> Int {
        durationOverrides[exercise.uuid] ?? exercise.durationSeconds
    }

    private func adjustDuration(for exercise: Exercise, by delta: Int) {
        let next = max(5, duration(for: exercise) + delta)
        durationOverrides[exercise.uuid] = next
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Morning Wake-Up", text: $routineName)
                        .font(.luminaBody)
                } header: {
                    Text("Routine Name")
                        .font(.luminaLabel)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }

                Section {
                    ForEach(selectedIDs.indices, id: \.self) { index in
                        if let exercise = exercises.first(where: { $0.uuid == selectedIDs[index] }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.luminaCardTitle)
                                        .foregroundStyle(Color.luminaOnSurface)
                                    Text(exercise.type.rawValue)
                                        .font(.luminaCaption)
                                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                                }
                                Spacer()
                                durationStepper(for: exercise)
                                Button(role: .destructive) {
                                    indexPendingRemoval = index
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .onMove { selectedIDs.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        pickingSession.begin(context: .init(
                            title: routineName,
                            isPinned: false,
                            baseExercises: selectedExercises,
                            originTab: 4,
                            editingRoutineID: routineToEdit?.uuid,
                            durationOverrides: durationOverrides
                        ))
                        dismiss()
                        // Same "dismiss + switch to Exercises tab" need
                        // CustomizeRoutineView's own Add Exercises button
                        // has — reusing the existing notification rather
                        // than adding a second one.
                        NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaPrimary)
                    }
                } header: {
                    HStack {
                        Text("Exercises")
                            .font(.luminaLabel)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                        Spacer()
                        if !selectedIDs.isEmpty {
                            Text(totalDuration < 60 ? "\(totalDuration)s total" : "\(totalDuration / 60)m total")
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.luminaSurface)
            .listRowBackground(Color.luminaCardFill)
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { saveRoutine() }
                        .disabled(routineName.isEmpty || selectedIDs.isEmpty)
                }
            }
            .confirmationDialog(
                "Remove this exercise?",
                isPresented: Binding(
                    get: { indexPendingRemoval != nil },
                    set: { if !$0 { indexPendingRemoval = nil } }
                ),
                presenting: indexPendingRemoval
            ) { index in
                Button("Remove", role: .destructive) {
                    selectedIDs.remove(at: index)
                    indexPendingRemoval = nil
                }
                Button("Cancel", role: .cancel) {}
            } message: { index in
                if let exercise = exercises.first(where: { $0.uuid == selectedIDs[index] }) {
                    Text("\"\(exercise.name)\" will be removed from this routine.")
                } else {
                    Text("This exercise will be removed from this routine.")
                }
            }
            .onAppear {
                if let restoredState {
                    routineName       = restoredState.name
                    selectedIDs       = restoredState.exerciseIDs
                    durationOverrides = restoredState.durationOverrides
                } else if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                    durationOverrides = r.exerciseDurationOverrides
                } else if !didApplySeed && (!initialExerciseIDs.isEmpty || initialName != nil) {
                    didApplySeed = true
                    selectedIDs = RoutineIDMerge.appending(initialExerciseIDs, to: selectedIDs)
                    if let initialName {
                        routineName = initialName
                    }
                }
            }
        }
    }

    private func saveRoutine() {
        if let r = routineToEdit {
            r.name        = routineName
            r.exerciseIDs = selectedIDs
            r.exerciseDurationOverrides = durationOverrides
        } else {
            let routine = Routine(
                name: routineName,
                exerciseIDs: selectedIDs,
                exerciseDurationOverrides: durationOverrides
            )
            modelContext.insert(routine)

            if let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first {
                GamificationService.awardBadge("Routine Builder", to: profile)
            }
        }

        do {
            try modelContext.save()
            onSaved?()
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "routineBuilder").warning("Save failed: \(error)")
        }

        dismiss()
    }

    private func durationStepper(for exercise: Exercise) -> some View {
        HStack(spacing: 6) {
            // Outline icon here (vs. the row's own filled "minus.circle.fill"
            // remove button) so the two destructive-looking minus icons in
            // the same row read as visually distinct actions.
            Button {
                adjustDuration(for: exercise, by: -5)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.luminaPrimary)

            Text(formattedDuration(duration(for: exercise)))
                .font(.luminaCaption)
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
        .accessibilityLabel("\(exercise.name) duration, \(formattedDuration(duration(for: exercise)))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjustDuration(for: exercise, by: 5)
            case .decrement: adjustDuration(for: exercise, by: -5)
            @unknown default: break
            }
        }
    }
}
