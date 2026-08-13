import SwiftUI

/// Presented from the Home hero's Customize button. Lets the user preview
/// today's session as a numbered roadmap, nudge each exercise's duration
/// for today only, decide whether to pin this list as their permanent
/// morning routine, and jump into the Exercises tab to add more.
///
/// Duration edits are local-only (`durationOverrides`) — Exercise is a
/// shared SwiftData object, so this view must never write back to
/// `exercise.durationSeconds` directly. See the "Explicitly deferred"
/// section of docs/superpowers/plans/2026-08-11-home-exercises-redesign.md
/// for why overrides aren't (yet) threaded into the session player.
struct CustomizeRoutineView: View {
    let title: String
    let exercises: [Exercise]
    let isPinned: Bool
    let onAddExercisesRequested: () -> Void
    let onDone: (_ exercises: [Exercise], _ pinned: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pinnedToggle: Bool
    @State private var durationOverrides: [UUID: Int] = [:]

    init(title: String, exercises: [Exercise], isPinned: Bool,
         onAddExercisesRequested: @escaping () -> Void,
         onDone: @escaping (_ exercises: [Exercise], _ pinned: Bool) -> Void) {
        self.title = title
        self.exercises = exercises
        self.isPinned = isPinned
        self.onAddExercisesRequested = onAddExercisesRequested
        self.onDone = onDone
        self._pinnedToggle = State(initialValue: isPinned)
    }

    private var totalSeconds: Int { exercises.reduce(0) { $0 + duration(for: $1) } }
    private var totalMinutes: Int { max(1, Int((Double(totalSeconds) / 60).rounded())) }

    private func duration(for exercise: Exercise) -> Int {
        durationOverrides[exercise.uuid] ?? exercise.durationSeconds
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }

    private func adjust(_ exercise: Exercise, by delta: Int) {
        let current = duration(for: exercise)
        durationOverrides[exercise.uuid] = max(15, current + delta)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(exercises.count) EXERCISES · \(totalMinutes) MIN")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)

                    RoadmapWave(exercises: exercises, numbered: true)

                    saveToggleRow

                    VStack(spacing: 10) {
                        ForEach(Array(exercises.enumerated()), id: \.element.uuid) { index, exercise in
                            exerciseRow(index: index, exercise: exercise)
                        }

                        HStack {
                            Spacer()
                            Button(action: onAddExercisesRequested) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 8, weight: .bold))
                                        .frame(width: 18, height: 18)
                                        .background(Color.luminaMintTint, in: Circle())
                                    Text("Add Exercises")
                                }
                                .font(.luminaLabel)
                                .foregroundStyle(Color.luminaPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .overlay(Capsule().strokeBorder(Color.luminaOutline, style: StrokeStyle(lineWidth: 1.3, dash: [4, 3])))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.top, 6)
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
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onDone(exercises, pinnedToggle)
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

            HStack(spacing: 8) {
                Button { adjust(exercise, by: -15) } label: {
                    Image(systemName: "minus").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Color.luminaContainer, in: Circle())

                Text(formatted(duration(for: exercise)))
                    .font(.luminaLabel)
                    .monospacedDigit()
                    .frame(minWidth: 44)

                Button { adjust(exercise, by: 15) } label: {
                    Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Color.luminaContainer, in: Circle())
            }
        }
        .luminaCard(padding: 12)
    }
}
