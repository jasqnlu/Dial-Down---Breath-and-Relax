import SwiftUI
import SwiftData

// MARK: - Account Tab

struct ProfileAccountTab: View {
    let profile: UserProfile?
    @EnvironmentObject private var auth: AuthManager
    @Binding var showSignOutConfirm: Bool
    @AppStorage("showStreakEmoji") private var showStreakEmoji = true
    @State private var twoFAOn = false

    var body: some View {
        Group {
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
    }

    // MARK: Helpers

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
