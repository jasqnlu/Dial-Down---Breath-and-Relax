import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Query private var routines: [Routine]
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext

    @State private var showingBuilder  = false
    @State private var showingBrowser  = false
    @State private var routineToPlay: Routine?
    @State private var routineToEdit: Routine?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: GuidedProgramsView()) {
                        Label("Guided Programs", systemImage: "calendar.badge.clock")
                    }
                    NavigationLink(destination: ContentPacksView()) {
                        Label("Content Packs", systemImage: "shippingbox.fill")
                    }
                }

                ForEach(routines) { routine in
                    RoutineRow(routine: routine) {
                        routineToPlay = routine
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(routine)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            routineToEdit = routine
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)

                        if let url = shareURL(for: routine) {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Routines")
            .floatingTabBarClearance()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingBuilder = true } label: {
                        Image(systemName: "plus")
                    }
                }
                // Community browsing needs the backend; hide the entry point
                // rather than showing a screen that can't load.
                if SupabaseService.isConfigured {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showingBrowser = true } label: {
                            Label("Browse", systemImage: "globe")
                        }
                    }
                }
            }
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines Yet",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text(SupabaseService.isConfigured
                            ? "Create your own or borrow one from the library."
                            : "Create your own routine from your favorite exercises.")
                    )
                }
            }
            .sheet(isPresented: $showingBuilder) {
                RoutineBuilderView()
                    .environmentObject(AuthManager.shared)
            }
            .sheet(item: $routineToEdit) { routine in
                RoutineBuilderView(routineToEdit: routine)
                    .environmentObject(AuthManager.shared)
            }
            .sheet(isPresented: $showingBrowser) {
                BorrowRoutineView()
                    .environmentObject(AuthManager.shared)
            }
            .sheet(item: $routineToPlay) { routine in
                let resolved = resolvedExercises(for: routine)
                if resolved.isEmpty {
                    ContentUnavailableView(
                        "No Exercises Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The exercises in this routine couldn't be loaded.")
                    )
                } else {
                    SessionPlayerView(
                        exercises: resolved,
                        routineID: routine.uuid,
                        isBorrowedRoutine: routine.borrowedFromID != nil
                    )
                }
            }
        }
    }

    private func resolvedExercises(for routine: Routine) -> [Exercise] {
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        return routine.exerciseIDs.compactMap { byID[$0] }
    }

    private func shareURL(for routine: Routine) -> URL? {
        let names = resolvedExercises(for: routine).map { $0.name }
        guard !names.isEmpty else { return nil }
        return RoutineSharePayload(name: routine.name, exerciseNames: names).shareURL
    }
}

// MARK: - Routine row

struct RoutineRow: View {
    let routine: Routine
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(routine.name)
                        .font(.headline)
                    if routine.borrowedFromID != nil {
                        Label("Borrowed", systemImage: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(routine.exerciseIDs.count) exercise\(routine.exerciseIDs.count == 1 ? "" : "s")",
                          systemImage: "list.number")
                    if routine.isPublic {
                        Label("Public", systemImage: "globe")
                            .foregroundStyle(.blue)
                    }
                    if routine.borrowCount > 0 {
                        Label("\(routine.borrowCount)", systemImage: "arrow.triangle.branch")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(routine.exerciseIDs.isEmpty ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(routine.exerciseIDs.isEmpty)
            .accessibilityLabel("Play \(routine.name)")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoutineListView()
        .modelContainer(for: [Routine.self, Exercise.self], inMemory: true)
}
