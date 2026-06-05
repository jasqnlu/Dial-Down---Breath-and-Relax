import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var auth: AuthManager
    @State private var twoFAOn: Bool = false
    @State private var showSignOutConfirm = false

    var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            if let profile = profile {
                List {
                    // MARK: Avatar + name
                    Section {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.18))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text(profile.displayName.prefix(1).uppercased())
                                        .font(.title2.bold())
                                        .foregroundStyle(Color.accentColor)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.headline)
                                if !auth.userEmail.isEmpty {
                                    Text(auth.userEmail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("🔥 \(profile.streak) day streak")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    // MARK: Stats
                    Section("Stats") {
                        LabeledContent("Total Minutes") { Text("\(profile.totalMinutes)") }
                        LabeledContent("Total Points")  { Text("\(profile.totalPoints)") }
                        LabeledContent("Current Streak") { Text("\(profile.streak) days") }
                        LabeledContent("Badges Earned") { Text("\(profile.badges.count)") }
                    }

                    // MARK: Badges
                    Section {
                        NavigationLink(destination: BadgesView(earnedBadges: profile.badges)) {
                            Label("View All Badges", systemImage: "medal")
                        }
                    }

                    // MARK: Security
                    Section("Security") {
                        Toggle(isOn: $twoFAOn) {
                            Label("Two-Factor Authentication", systemImage: "faceid")
                        }
                        .onChange(of: twoFAOn) { _, val in
                            auth.twoFAEnabled = val
                        }

                        LabeledContent("Signed in with") {
                            Text(auth.provider.rawValue.capitalized)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: Sign Out
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                .navigationTitle("Profile")
                .onAppear { twoFAOn = auth.twoFAEnabled }
                .confirmationDialog("Sign out of your account?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                    Button("Sign Out", role: .destructive) { auth.signOut() }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                ContentUnavailableView(
                    "No Profile",
                    systemImage: "person.circle",
                    description: Text("Sign in to track your progress and earn badges.")
                )
                .navigationTitle("Profile")
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
        .environmentObject(AuthManager.shared)
}
