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
    @State private var routinePendingDelete: Routine?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: GuidedProgramsView()) {
                        entryRow(title: "Guided Programs", systemImage: "calendar.badge.clock")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    NavigationLink(destination: ContentPacksView()) {
                        entryRow(title: "Content Packs", systemImage: "shippingbox.fill")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(routines) { routine in
                    RoutineRow(routine: routine, resolvedCount: resolvedExercises(for: routine).count) {
                        routineToPlay = routine
                    }
                    .listRowBackground(Color.luminaCardFill)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            routinePendingDelete = routine
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
            .scrollContentBackground(.hidden)
            .background(Color.luminaSurface)
            .navigationTitle("Routines")
            // Left unset before, which defaults to a large title at the root
            // of a NavigationStack — made explicit and aligned to .inline to
            // match the other tab roots (see page-title convention audit).
            .navigationBarTitleDisplayMode(.inline)
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
                    ContentUnavailableView {
                        VStack(spacing: 16) {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                                .frame(width: 88, height: 88)
                                .background(Color.luminaContainer, in: Circle())
                            Text("No Routines Yet")
                                .font(.luminaHeadline)
                                .foregroundStyle(Color.luminaOnSurface)
                        }
                    } description: {
                        Text(SupabaseService.isConfigured
                            ? "Create your own or borrow one from the library."
                            : "Create your own routine from your favorite exercises.")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
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
            .confirmationDialog(
                "Delete this routine?",
                isPresented: Binding(
                    get: { routinePendingDelete != nil },
                    set: { if !$0 { routinePendingDelete = nil } }
                ),
                presenting: routinePendingDelete
            ) { routine in
                Button("Delete", role: .destructive) {
                    modelContext.delete(routine)
                    routinePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {}
            } message: { routine in
                Text("\"\(routine.name)\" will be permanently deleted. This can't be undone.")
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

    private func entryRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 44, height: 44)
                .background(Color.luminaMintTint, in: Circle())

            Text(title)
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaOnSurface)

            Spacer()
        }
        .luminaCard(padding: 14)
    }
}

// MARK: - Routine row

struct RoutineRow: View {
    let routine: Routine
    /// Count of exerciseIDs that actually resolve against the local catalog —
    /// can be lower than exerciseIDs.count (e.g. borrowed routines referencing
    /// exercises that don't exist on this install), so this is what actually
    /// determines whether the routine can play, not the raw ID count.
    let resolvedCount: Int
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(routine.name)
                        .font(.luminaCardTitle)
                    if routine.borrowedFromID != nil {
                        Label("Borrowed", systemImage: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(resolvedCount) exercise\(resolvedCount == 1 ? "" : "s")",
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
                .font(.luminaCaption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(resolvedCount == 0 ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(resolvedCount == 0)
            .accessibilityLabel("Play \(routine.name)")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoutineListView()
        .modelContainer(for: [Routine.self, Exercise.self], inMemory: true)
}
