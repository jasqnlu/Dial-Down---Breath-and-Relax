import SwiftUI
import SwiftData
import os

struct BorrowRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allRoutines: [Routine]
    @Query private var allExercises: [Exercise]
    @EnvironmentObject private var auth: AuthManager

    @State private var borrowedIDs: Set<UUID> = []
    @State private var showingConfirmation: Routine? = nil

    // Public routines from other users, ranked by popularity
    private var publicRoutines: [Routine] {
        allRoutines
            .filter { $0.isPublic && $0.authorID != auth.backendID }
            .sorted { $0.borrowCount > $1.borrowCount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if publicRoutines.isEmpty {
                    ContentUnavailableView {
                        VStack(spacing: 16) {
                            Image(systemName: "globe")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                                .frame(width: 88, height: 88)
                                .background(Color.luminaContainer, in: Circle())
                            Text("No Public Routines")
                                .font(.luminaHeadline)
                                .foregroundStyle(Color.luminaOnSurface)
                        }
                    } description: {
                        Text("No one has shared a routine yet. Create one and publish it to the community!")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
                } else {
                    List {
                        Section {
                            Text("Browse community routines, ranked by popularity. Fork one to add it to your library.")
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                        .listRowBackground(Color.clear)

                        Section {
                            ForEach(publicRoutines, id: \.uuid) { routine in
                                BorrowRoutineRow(
                                    routine: routine,
                                    resolvedCount: resolvedCount(for: routine),
                                    isBorrowed: borrowedIDs.contains(routine.uuid)
                                ) {
                                    showingConfirmation = routine
                                }
                            }
                            .listRowBackground(Color.luminaCardFill)
                        } header: {
                            Text("Community Routines")
                                .font(.luminaLabel)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.luminaSurface)
                }
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .navigationTitle("Browse Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Add \"\(showingConfirmation?.name ?? "")\" to your routines?",
                isPresented: Binding(
                    get: { showingConfirmation != nil },
                    set: { if !$0 { showingConfirmation = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let routine = showingConfirmation {
                    Button("Fork Routine") { fork(routine) }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text("A copy will be added to your routines. You can edit it freely.")
            }
            .onAppear { loadBorrowedIDs() }
        }
    }

    // MARK: - Fork logic

    private func fork(_ routine: Routine) {
        routine.borrowCount += 1

        let forked = Routine(
            name: routine.name + " (Borrowed)",
            exerciseIDs: routine.exerciseIDs,
            authorID: auth.backendID,
            borrowedFromID: routine.uuid,
            isPublic: false
        )
        modelContext.insert(forked)
        do {
            try modelContext.save()
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "borrowRoutine").warning("Save failed: \(error)")
        }
        borrowedIDs.insert(routine.uuid)
        showingConfirmation = nil
    }

    private func loadBorrowedIDs() {
        let borrowed = allRoutines.compactMap { $0.borrowedFromID }
        borrowedIDs = Set(borrowed)
    }

    private func resolvedCount(for routine: Routine) -> Int {
        let byID = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.uuid, $0) })
        return routine.exerciseIDs.filter { byID[$0] != nil }.count
    }
}

// MARK: - Row

private struct BorrowRoutineRow: View {
    let routine: Routine
    /// Count of exerciseIDs that actually resolve against the local catalog —
    /// borrowed routines can reference exercises that don't exist on this
    /// install (seed exercise UUIDs weren't stable across installs).
    let resolvedCount: Int
    let isBorrowed: Bool
    let onBorrow: () -> Void

    // authorID is an opaque anonymous UUID — never show it. Only the
    // self-chosen display name is fit for the UI.
    private var displayAuthor: String? {
        routine.authorName
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)

                HStack(spacing: 10) {
                    Label("\(resolvedCount) exercise\(resolvedCount == 1 ? "" : "s")",
                          systemImage: "list.number")

                    if let author = displayAuthor, !author.isEmpty {
                        Label(author, systemImage: "person")
                            .lineLimit(1)
                    }
                }
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
            }

            Spacer()

            // Popularity badge
            if routine.borrowCount > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.luminaOrange)
                    Text("\(routine.borrowCount)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.luminaOrange)
                }
                .frame(width: 28)
            }

            if isBorrowed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.luminaPrimary)
            } else {
                Button {
                    onBorrow()
                } label: {
                    Label("Fork", systemImage: "arrow.triangle.branch")
                }
                .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BorrowRoutineView()
        .modelContainer(for: Routine.self, inMemory: true)
        .environmentObject(AuthManager.shared)
}
