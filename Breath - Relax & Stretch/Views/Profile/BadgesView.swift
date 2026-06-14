import SwiftUI

struct BadgesView: View {
    let earnedBadges: [String]

    struct BadgeDefinition {
        let name: String
        let icon: String
        let description: String
    }

    let allBadges: [BadgeDefinition] = [
        // First session
        BadgeDefinition(name: "First Breath",         icon: "wind",                        description: "Complete your very first session"),
        // Streak milestones
        BadgeDefinition(name: "Streak Starter",       icon: "flame",                       description: "Achieve a 3-day streak"),
        BadgeDefinition(name: "Weekly Warrior",       icon: "flame.fill",                  description: "Keep a 7-day streak"),
        BadgeDefinition(name: "Month of Mindfulness", icon: "calendar.badge.checkmark",    description: "Keep a 30-day streak"),
        // Time milestones
        BadgeDefinition(name: "30 Min Club",          icon: "clock",                       description: "Accumulate 30 minutes of practice"),
        BadgeDefinition(name: "Hour Hero",            icon: "clock.badge.checkmark",       description: "Accumulate 1 hour of practice"),
        BadgeDefinition(name: "5 Hour Club",          icon: "clock.badge.fill",            description: "Accumulate 5 hours of practice"),
        // Points milestones
        BadgeDefinition(name: "Century",              icon: "star",                        description: "Earn 100 total points"),
        BadgeDefinition(name: "High Achiever",        icon: "star.leadinghalf.filled",     description: "Earn 500 total points"),
        BadgeDefinition(name: "Elite Breather",       icon: "star.fill",                   description: "Earn 1,000 total points"),
        // Special
        BadgeDefinition(name: "Full Body",            icon: "figure.mind.and.body",        description: "Target 5+ muscle groups in one session"),
        BadgeDefinition(name: "Routine Builder",      icon: "rectangle.stack.badge.plus",  description: "Create your first custom routine"),
        BadgeDefinition(name: "Borrowed & Built",     icon: "arrow.triangle.branch",       description: "Complete a routine borrowed from the library"),
    ]

    var body: some View {
        List(allBadges, id: \.name) { badge in
            let earned = earnedBadges.contains(badge.name)
            HStack(spacing: 16) {
                Image(systemName: badge.icon)
                    .font(.title2)
                    .frame(width: 36)
                    .foregroundStyle(earned ? Color.yellow : Color.secondary.opacity(0.4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(badge.name)
                        .font(.headline)
                        .foregroundStyle(earned ? .primary : .secondary)
                    Text(badge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if earned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 6)
            .opacity(earned ? 1.0 : 0.5)
        }
        .navigationTitle("Badges")
    }
}

#Preview {
    NavigationStack {
        BadgesView(earnedBadges: ["First Breath", "Streak Starter"])
    }
}
