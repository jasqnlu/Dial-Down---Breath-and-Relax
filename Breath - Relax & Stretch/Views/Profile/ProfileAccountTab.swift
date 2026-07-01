import SwiftUI
import SwiftData

// MARK: - Account Tab

struct ProfileAccountTab: View {
    let profile: UserProfile?
    @EnvironmentObject private var auth: AuthManager
    @Binding var showSignOutConfirm: Bool
    @ObservedObject private var store = StoreManager.shared
    @State private var twoFAOn = false
    @State private var showingPaywall = false

    var body: some View {
        Group {
            // Upgrade
            if !store.isPro {
                Section {
                    Button {
                        showingPaywall = true
                    } label: {
                        Label("Upgrade to Breath Pro", systemImage: "sparkles")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            // Stats
            if let profile {
                Section("Your Stats") {
                    statsRow(icon: "clock.fill",  color: .blue,
                             label: "Total Minutes", value: "\(profile.totalMinutes) min")
                    statsRow(icon: "star.fill",   color: .yellow,
                             label: "Total Points",  value: "\(profile.totalPoints) pts")
                    statsRow(icon: "flame.fill",  color: .orange,
                             label: "Current Streak", value: "\(profile.streak) days")
                    statsRow(icon: "medal.fill",  color: .purple,
                             label: "Badges Earned", value: "\(profile.badges.count)")
                }

                Section {
                    NavigationLink(destination: BadgesView(earnedBadges: profile.badges)) {
                        Label("View All Badges", systemImage: "medal")
                    }
                    NavigationLink(destination: ProgressChartsView()) {
                        Label("Progress & Charts", systemImage: "chart.bar.xaxis")
                    }
                }

                Section("Community") {
                    NavigationLink(destination: LeaderboardView()) {
                        Label("Leaderboard", systemImage: "list.number")
                    }
                    if let url = challengeURL(for: profile) {
                        ShareLink(item: url) {
                            Label("Challenge a Friend", systemImage: "figure.2")
                        }
                    }
                }
            }

            // Auth
            Section("Authentication") {
                Toggle(isOn: $twoFAOn) {
                    Label("Two-Factor Authentication", systemImage: "faceid")
                }
                .onChange(of: twoFAOn) { _, val in auth.twoFAEnabled = val }

                LabeledContent("Signed in with") {
                    Text(auth.provider.rawValue.capitalized).foregroundStyle(.secondary)
                }
            }

            // Sign out
            Section {
                if auth.isSignedIn {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } else {
                    Label("Not signed in", systemImage: "person.slash")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { twoFAOn = auth.twoFAEnabled }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: Helpers

    private func challengeURL(for profile: UserProfile) -> URL? {
        ChallengePayload(fromName: profile.displayName, streak: profile.streak, totalPoints: profile.totalPoints).shareURL
    }

    private func statsRow(icon: String, color: Color,
                          label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 28)
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary).fontWeight(.medium)
        }
    }
}
