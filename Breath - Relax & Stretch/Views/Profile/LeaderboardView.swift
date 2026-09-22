import SwiftUI
import SwiftData

// MARK: - LeaderboardView
// Opt-in, pseudonymous community leaderboard. Nothing is published until the
// user taps Join; other people only ever see a generated handle (never a real
// name or email). Leaving deletes the row. The opt-in lives in the user's own
// server row, so it survives sign-out and restores on a new device.
// No-ops gracefully when Supabase isn't configured (same offline-first
// pattern as borrowed routines).

struct LeaderboardView: View {
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var auth: AuthManager

    @State private var entries: [RemoteLeaderboardEntry] = []
    @State private var isLoading = false
    @State private var isWorking = false
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var joinedHandle: String? = LeaderboardPreference.handle
    @State private var proposedHandle = LeaderboardHandle.generate()

    private var localProfile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if !SupabaseService.isConfigured {
                ContentUnavailableView(
                    "Leaderboard Not Set Up",
                    systemImage: "person.3",
                    description: Text("The community backend hasn't been configured yet.")
                )
            } else if !auth.isBackendAuthenticated {
                ContentUnavailableView(
                    "Sign In to Join",
                    systemImage: "person.crop.circle.badge.checkmark",
                    description: Text("Sign in with Apple or Google to see the leaderboard. Joining is optional and never shows your real name.")
                )
            } else if isLoading && entries.isEmpty && joinedHandle == nil {
                ProgressView("Loading leaderboard…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    optInSection
                    if let loadError, entries.isEmpty {
                        Section {
                            Text(loadError)
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                                .listRowBackground(Color.luminaCardFill)
                        }
                    } else if entries.isEmpty {
                        Section {
                            Text("No one has joined yet. Be the first!")
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                                .listRowBackground(Color.luminaCardFill)
                        }
                    } else {
                        Section {
                            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                                leaderboardRow(rank: index + 1, entry: entry)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.luminaSurface)
                .refreshable { await load() }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
        .task { await load() }
    }

    // MARK: Opt-in card

    @ViewBuilder
    private var optInSection: some View {
        Section {
            if let joinedHandle {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You appear as")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                    Text(joinedHandle)
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaOnSurface)
                    Text("Only this made-up name, your points, streak and minutes are shown. Your real name and email are never shared.")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                .listRowBackground(Color.luminaCardFill)

                Button("Leave Leaderboard", role: .destructive) {
                    Task { await leave() }
                }
                .disabled(isWorking)
                .listRowBackground(Color.luminaCardFill)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Join the leaderboard")
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaOnSurface)
                    Text("Optional. You'd appear under a made-up name — never your real name or email — with your points, streak and minutes. Leave any time.")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                .listRowBackground(Color.luminaCardFill)

                HStack {
                    Text(proposedHandle)
                        .font(.luminaBody)
                        .foregroundStyle(Color.luminaOnSurface)
                    Spacer()
                    Button("New Name") { proposedHandle = LeaderboardHandle.generate() }
                        .font(.luminaCaption)
                        .disabled(isWorking)
                }
                .listRowBackground(Color.luminaCardFill)

                Button("Join Leaderboard") {
                    Task { await join() }
                }
                .disabled(isWorking)
                .listRowBackground(Color.luminaCardFill)
            }

            if let actionError {
                Text(actionError)
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .listRowBackground(Color.luminaCardFill)
            }
        }
    }

    // MARK: Rows

    private func leaderboardRow(rank: Int, entry: RemoteLeaderboardEntry) -> some View {
        let isMe = entry.isMe
        return HStack(spacing: 12) {
            Text("\(rank)")
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.handle)
                    .font(isMe ? .luminaCardTitle : .luminaBody)
                    .foregroundStyle(Color.luminaOnSurface)
                Text("\(entry.streak) day streak · \(entry.totalMinutes) min")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }

            Spacer()

            Text("\(entry.totalPoints)")
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaPrimary)
        }
        .padding(.vertical, isMe ? 4 : 0)
        .listRowBackground(isMe ? Color.luminaPrimary.opacity(0.08) : Color.luminaCardFill)
    }

    // MARK: Actions

    private func currentRow(handle: String) -> RemoteLeaderboardRow {
        RemoteLeaderboardRow(
            userID: auth.backendID,
            handle: handle,
            totalPoints: localProfile?.totalPoints ?? 0,
            streak: localProfile?.streak ?? 0,
            totalMinutes: localProfile?.totalMinutes ?? 0
        )
    }

    private func join() async {
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await SupabaseService.shared.joinLeaderboard(currentRow(handle: proposedHandle))
            LeaderboardPreference.handle = proposedHandle
            joinedHandle = proposedHandle
            await load()
        } catch {
            actionError = "Couldn't join the leaderboard. Check your connection and try again."
        }
    }

    private func leave() async {
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await SupabaseService.shared.leaveLeaderboard()
            LeaderboardPreference.clear()
            joinedHandle = nil
            proposedHandle = LeaderboardHandle.generate()
            await load()
        } catch {
            actionError = "Couldn't leave the leaderboard. Check your connection and try again."
        }
    }

    private func load() async {
        guard SupabaseService.isConfigured, auth.isBackendAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }

        // The server row is the source of truth for the opt-in. A successful
        // read (row or nil) re-syncs the local cache — this is what restores
        // the choice after a sign-in or on a new device. A failed read leaves
        // the cache alone so an offline launch doesn't look like opting out.
        do {
            if let own = try await SupabaseService.shared.fetchOwnLeaderboardRow() {
                LeaderboardPreference.handle = own.handle
                joinedHandle = own.handle
            } else {
                LeaderboardPreference.clear()
                joinedHandle = nil
            }
        } catch {
            // Read failed — keep whatever the cache says.
        }

        // Only an opted-in user's stats are ever uploaded here. Best-effort:
        // a failed refresh just leaves the previous numbers on the board.
        if let handle = joinedHandle, localProfile != nil {
            try? await SupabaseService.shared.joinLeaderboard(currentRow(handle: handle))
        }

        do {
            entries = try await SupabaseService.shared.fetchLeaderboard()
            loadError = nil
        } catch SupabaseError.httpError(let code) {
            loadError = "The leaderboard service isn't available right now (error \(code)). Try again later."
        } catch {
            loadError = "Check your connection and try again."
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
            .modelContainer(for: UserProfile.self, inMemory: true)
            .environmentObject(AuthManager.shared)
    }
}
