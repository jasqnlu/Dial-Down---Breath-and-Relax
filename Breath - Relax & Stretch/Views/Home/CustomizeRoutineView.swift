import SwiftUI

/// Presented from the Home hero's Customize button. Lets the user preview
/// today's session as a numbered roadmap, adjust each exercise's duration
/// or remove it, add more exercises via a cross-tab picking session on the
/// real Exercises tab (see ExercisePickingSession), and decide whether to
/// pin the result as their permanent Today routine — in which case the
/// duration overrides are saved onto that routine too.
struct CustomizeRoutineView: View {
    let title: String
    let isPinned: Bool
    let onDone: (_ exercises: [Exercise], _ pinned: Bool, _ durationOverrides: [UUID: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pinnedToggle: Bool
    @State private var currentExercises: [Exercise]
    @State private var indexPendingRemoval: Int?
    /// Per-exercise duration overrides, keyed by exercise UUID — seconds.
    /// Absent key means "use the exercise's own durationSeconds." Passed
    /// back through `onDone` so the caller can save it onto the pinned
    /// Today routine and thread it into today's SessionPlayerView.
    @State private var durationOverrides: [UUID: Int] = [:]
    @EnvironmentObject private var pickingSession: ExercisePickingSession

    init(title: String, exercises: [Exercise], isPinned: Bool,
         onDone: @escaping (_ exercises: [Exercise], _ pinned: Bool, _ durationOverrides: [UUID: Int]) -> Void) {
        self.title = title
        self.isPinned = isPinned
        self.onDone = onDone
        self._pinnedToggle = State(initialValue: isPinned)
        self._currentExercises = State(initialValue: exercises)
    }

    private var totalSeconds: Int { currentExercises.reduce(0) { $0 + duration(for: $1) } }
    private var totalMinutes: Int { max(1, Int((Double(totalSeconds) / 60).rounded())) }

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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(currentExercises.count) EXERCISES · \(totalMinutes) MIN")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)

                    RoadmapWave(exercises: currentExercises, numbered: true)

                    saveToggleRow

                    VStack(spacing: 10) {
                        ForEach(Array(currentExercises.enumerated()), id: \.element.uuid) { index, exercise in
                            exerciseRow(index: index, exercise: exercise)
                        }
                    }
                }
                .padding()
            }
            .background(Color.luminaSurface)
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        pickingSession.begin(context: .init(
                            title: title,
                            isPinned: pinnedToggle,
                            baseExercises: currentExercises,
                            originTab: 0,
                            editingRoutineID: nil,
                            durationOverrides: [:]
                        ))
                        dismiss()
                        // Same "dismiss + switch to Exercises tab" need
                        // SessionPlayerView already has (Views/Session/
                        // SessionPlayerView.swift) — reusing the existing
                        // notification rather than adding a second one.
                        NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                    } label: {
                        Label("Add Exercises", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
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
                    let removedID = currentExercises[index].uuid
                    currentExercises.remove(at: index)
                    durationOverrides.removeValue(forKey: removedID)
                    indexPendingRemoval = nil
                }
                Button("Cancel", role: .cancel) {}
            } message: { index in
                Text("\"\(currentExercises[index].name)\" will be removed from this routine.")
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onDone(currentExercises, pinnedToggle, durationOverrides)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Begin")
                    }
                }
                .buttonStyle(LuminaPillButtonStyle(kind: .prominent))
                .frame(maxWidth: .infinity)
                .padding()
                .background(.regularMaterial)
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

            Button(role: .destructive) {
                indexPendingRemoval = index
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
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
