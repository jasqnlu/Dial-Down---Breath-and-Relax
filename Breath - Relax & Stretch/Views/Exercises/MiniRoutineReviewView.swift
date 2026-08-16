import SwiftUI
import SwiftData

/// Presented when "Continue" is tapped on the `PickingBar` for a standalone
/// (no-Customize-context) picking session — see `ExercisePickingSession
/// .begin()`. Shows the picks as a numbered roadmap, same look as
/// `CustomizeRoutineView`'s preview, then offers three terminal actions
/// instead of Customize's single "Begin".
struct MiniRoutineReviewView: View {
    let pickedExercises: [Exercise]
    /// Called once one of the three destinations actually completes (a
    /// routine was saved, or the mini-routine session was dismissed) so the
    /// caller can clear the picking session. Not called if the user just
    /// backs out without finishing any of them.
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingNewRoutineBuilder = false
    @State private var showingRoutineChooser = false
    @State private var showingMiniSession = false

    private var totalSeconds: Int { pickedExercises.reduce(0) { $0 + $1.durationSeconds } }
    private var totalMinutes: Int { max(1, Int((Double(totalSeconds) / 60).rounded())) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(pickedExercises.count) EXERCISE\(pickedExercises.count == 1 ? "" : "S") · \(totalMinutes) MIN")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)

                    RoadmapWave(exercises: pickedExercises, numbered: true)

                    VStack(spacing: 10) {
                        destinationRow(
                            title: "Create New Routine",
                            subtitle: "Name it and save these as a routine",
                            systemImage: "plus.circle.fill"
                        ) { showingNewRoutineBuilder = true }

                        destinationRow(
                            title: "Add to Existing Routine",
                            subtitle: "Append these to one you already have",
                            systemImage: "text.badge.plus"
                        ) { showingRoutineChooser = true }

                        destinationRow(
                            title: "Start Mini-Routine",
                            subtitle: "Play these now — nothing is saved",
                            systemImage: "play.fill"
                        ) { showingMiniSession = true }
                    }
                }
                .padding()
            }
            .background(Color.luminaSurface)
            .navigationTitle("Review Picks")
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
            .sheet(isPresented: $showingNewRoutineBuilder) {
                RoutineBuilderView(initialExerciseIDs: pickedExercises.map(\.uuid)) {
                    onFinished()
                    dismiss()
                }
                .environmentObject(AuthManager.shared)
            }
            .sheet(isPresented: $showingRoutineChooser) {
                RoutineChooserView(pickedExercises: pickedExercises) {
                    onFinished()
                    dismiss()
                }
            }
            // Unlike the routine-builder destinations (which distinguish
            // Save from Cancel via `onSaved`), starting a mini-routine has
            // no "did nothing" outcome to guard against — any dismissal of
            // the player (finished or backed out early) ends this flow.
            .sheet(isPresented: $showingMiniSession, onDismiss: {
                onFinished()
                dismiss()
            }) {
                SessionPlayerView(exercises: pickedExercises)
            }
        }
    }

    private func destinationRow(title: String, subtitle: String, systemImage: String,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.luminaPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.luminaMintTint, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaOnSurface)
                    Text(subtitle)
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            .luminaCard(padding: 14)
        }
        .buttonStyle(.plain)
        // Overrides the default combined-children label (title + subtitle
        // concatenated) so both VoiceOver and UI tests can address the row
        // by its title alone — matches ExerciseGridTile's convention.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Existing-routine chooser

/// Lightweight routine picker for the "Add to Existing Routine" destination.
/// Selecting a routine pushes into `RoutineBuilderView` pre-seeded with the
/// picks, mirroring how `RoutineListView` presents editing.
private struct RoutineChooserView: View {
    let pickedExercises: [Exercise]
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var routines: [Routine]
    @State private var routineToAddTo: Routine?

    var body: some View {
        NavigationStack {
            List(routines) { routine in
                Button {
                    routineToAddTo = routine
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(routine.name)
                                .font(.luminaCardTitle)
                                .foregroundStyle(Color.luminaOnSurface)
                            Text("\(routine.exerciseIDs.count) exercise\(routine.exerciseIDs.count == 1 ? "" : "s")")
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.luminaSurface)
            .navigationTitle("Add to Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines Yet",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Create a routine first, or start this as a mini-routine instead.")
                    )
                }
            }
            .sheet(item: $routineToAddTo) { routine in
                RoutineBuilderView(routineToEdit: routine, initialExerciseIDs: pickedExercises.map(\.uuid)) {
                    onSaved()
                    dismiss()
                }
                .environmentObject(AuthManager.shared)
            }
        }
    }
}
