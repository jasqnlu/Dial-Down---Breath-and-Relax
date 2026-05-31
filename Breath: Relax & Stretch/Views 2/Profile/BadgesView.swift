import SwiftUI

struct BadgesView: View {
    let earnedBadges: [String]

    struct BadgeDefinition {
        let name: String
        let icon: String
        let description: String
    }

    let allBadges: [BadgeDefinition] = [
        BadgeDefinition(name: "First Breath",     icon: "wind",                       description: "Complete your first session"),
        BadgeDefinition(name: "Streak Starter",   icon: "flame",                      description: "Achieve a 3-day streak"),
        BadgeDefinition(name: "Full Body",         icon: "figure.mind.and.body",       description: "Target all major muscle groups in one session"),
        BadgeDefinition(name: "Routine Builder",   icon: "rectangle.stack.badge.plus", description: "Create your first custom routine"),
        BadgeDefinition(name: "Borrowed & Built",  icon: "arrow.triangle.branch",      description: "Fork a public routine and complete it"),
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
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        BadgesView(earnedBadges: ["First Breath", "Streak Starter"])
    }
}
