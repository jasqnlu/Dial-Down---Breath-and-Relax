import SwiftUI

/// Presented from the Home hero's Customize button. Lets the user preview
/// today's session as a numbered roadmap, add more exercises via a
/// cross-tab picking session on the real Exercises tab (see
/// ExercisePickingSession), and decide whether to pin the result as their
/// permanent Wake Up routine.
///
/// Per-exercise duration editing is intentionally not interactive here:
/// threading duration overrides into the session player is a real feature
/// that hasn't been built yet. Showing a control that looked live but
/// silently discarded the edit on Begin was worse than not having one —
/// see the "Explicitly deferred" section of
/// docs/superpowers/plans/2026-08-11-home-exercises-redesign.md.
struct CustomizeRoutineView: View {
    let title: String
    let isPinned: Bool
    let onDone: (_ exercises: [Exercise], _ pinned: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pinnedToggle: Bool
    @State private var currentExercises: [Exercise]
    @EnvironmentObject private var pickingSession: ExercisePickingSession

    init(title: String, exercises: [Exercise], isPinned: Bool,
         onDone: @escaping (_ exercises: [Exercise], _ pinned: Bool) -> Void) {
        self.title = title
        self.isPinned = isPinned
        self.onDone = onDone
        self._pinnedToggle = State(initialValue: isPinned)
        self._currentExercises = State(initialValue: exercises)
    }

    private var totalSeconds: Int { currentExercises.reduce(0) { $0 + $1.durationSeconds } }
    private var totalMinutes: Int { max(1, Int((Double(totalSeconds) / 60).rounded())) }

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
                            baseExercises: currentExercises
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
            .safeAreaInset(edge: .bottom) {
                Button {
                    onDone(currentExercises, pinnedToggle)
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
                Text("Keep as my \(title) routine")
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

            Text(formatted(exercise.durationSeconds))
                .font(.luminaLabel)
                .monospacedDigit()
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        .luminaCard(padding: 12)
    }
}
