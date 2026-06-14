import SwiftUI
import SwiftData

struct BorrowRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allRoutines: [Routine]
    @EnvironmentObject private var auth: AuthManager

    @State private var borrowedIDs: Set<UUID> = []
    @State private var showingConfirmation: Routine? = nil

    // Public routines from other users, ranked by popularity
    private var publicRoutines: [Routine] {
        allRoutines
            .filter { $0.isPublic && $0.authorID != auth.userEmail }
            .sorted { $0.borrowCount > $1.borrowCount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if publicRoutines.isEmpty {
                    ContentUnavailableView(
                        "No Public Routines",
                        systemImage: "globe",
                        description: Text("No one has shared a routine yet. Create one and publish it to the community!")
                    )
                } else {
                    List {
                        Section {
                            Text("Browse community routines, ranked by popularity. Fork one to add it to your library.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Section("Community Routines") {
                            ForEach(publicRoutines, id: \.uuid) { routine in
                                BorrowRoutineRow(
                                    routine: routine,
                                    isBorrowed: borrowedIDs.contains(routine.uuid)
                                ) {
                                    showingConfirmation = routine
                                }
                            }
                        }
                    }
                }
            }
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
            authorID: auth.userEmail,
            borrowedFromID: routine.uuid,
            isPublic: false
        )
        modelContext.insert(forked)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ SwiftData save failed in BorrowRoutineView: \(error)")
            #endif
        }
        borrowedIDs.insert(routine.uuid)
        showingConfirmation = nil
    }

    private func loadBorrowedIDs() {
        let borrowed = allRoutines.compactMap { $0.borrowedFromID }
        borrowedIDs = Set(borrowed)
    }
}

// MARK: - Row

private struct BorrowRoutineRow: View {
    let routine: Routine
    let isBorrowed: Bool
    let onBorrow: () -> Void

    private var displayAuthor: String? {
        routine.authorName ?? routine.authorID
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.headline)

                HStack(spacing: 10) {
                    Label("\(routine.exerciseIDs.count) exercise\(routine.exerciseIDs.count == 1 ? "" : "s")",
                          systemImage: "list.number")

                    if let author = displayAuthor, !author.isEmpty {
                        Label(author, systemImage: "person")
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Popularity badge
            if routine.borrowCount > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(routine.borrowCount)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .frame(width: 28)
            }

            if isBorrowed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    onBorrow()
                } label: {
                    Label("Fork", systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.12))
                        .foregroundStyle(.tint)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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
