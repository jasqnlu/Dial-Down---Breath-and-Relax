import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]

    var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            if let profile = profile {
                List {
                    // Avatar + name
                    Section {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.18))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text(profile.displayName.prefix(1).uppercased())
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.accentColor)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.headline)
                                Text("🔥 \(profile.streak) day streak")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    // Stats
                    Section("Stats") {
                        LabeledContent("Total Minutes") { Text("\(profile.totalMinutes)") }
                        LabeledContent("Total Points") { Text("\(profile.totalPoints)") }
                        LabeledContent("Current Streak") { Text("\(profile.streak) days") }
                        LabeledContent("Badges Earned") { Text("\(profile.badges.count)") }
                    }

                    // Badges link
                    Section {
                        NavigationLink(destination: BadgesView(earnedBadges: profile.badges)) {
                            Label("View All Badges", systemImage: "medal")
                        }
                    }
                }
                .navigationTitle("Profile")
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
}
