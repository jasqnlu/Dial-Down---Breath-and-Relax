import SwiftUI
import SwiftData

// MARK: - LeaderboardView
// Pulls public profiles from Supabase, sorted by points. Uploads the local
// profile first so the user's own row stays fresh. No-ops gracefully when
// Supabase isn't configured (same offline-first pattern as borrowed routines).

struct LeaderboardView: View {
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var auth: AuthManager

    @State private var entries: [RemoteProfile] = []
    @State private var isLoading = false
    @State private var loadError: String?

    private var localProfile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if !SupabaseService.isConfigured {
                ContentUnavailableView(
                    "Leaderboard Not Set Up",
                    systemImage: "person.3",
                    description: Text("The community backend hasn't been configured yet.")
                )
            } else if isLoading && entries.isEmpty {
                ProgressView("Loading leaderboard…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError, entries.isEmpty {
                ContentUnavailableView(
                    "Couldn't Load Leaderboard",
                    systemImage: "wifi.slash",
                    description: Text(loadError)
                )
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries Yet",
                    systemImage: "person.3",
                    description: Text("Be the first to appear on the leaderboard.")
                )
            } else {
                List {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        leaderboardRow(rank: index + 1, entry: entry)
                    }
                }
                .refreshable { await load() }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func leaderboardRow(rank: Int, entry: RemoteProfile) -> some View {
        let isMe = entry.id == auth.anonymousID
        return HStack(spacing: 12) {
            Text("\(rank)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName.isEmpty ? "Anonymous" : entry.displayName)
                    .font(.subheadline.weight(isMe ? .bold : .regular))
                Text("\(entry.streak) day streak · \(entry.totalMinutes) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.totalPoints)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, isMe ? 4 : 0)
        .listRowBackground(isMe ? Color.accentColor.opacity(0.08) : nil)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        // Identified by the anonymous per-install UUID — the email never
        // leaves the device (this table is publicly readable).
        if let local = localProfile {
            let remote = RemoteProfile(
                id: auth.anonymousID,
                displayName: local.displayName,
                totalPoints: local.totalPoints,
                streak: local.streak,
                totalMinutes: local.totalMinutes
            )
            try? await SupabaseService.shared.uploadProfile(remote)
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
