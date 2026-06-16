import WidgetKit
import SwiftUI

// MARK: - Shared App Group (must match WidgetDataService.groupID in main app)
private let appGroupID = "group.REPLACE_WITH_YOUR_BUNDLE_ID"

// MARK: - Timeline Entry

struct BreathEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalSessions: Int
    let lastSessionDate: Date?
}

// MARK: - Provider

struct BreathProvider: TimelineProvider {
    private var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    func placeholder(in context: Context) -> BreathEntry {
        BreathEntry(date: .now, streak: 7, totalSessions: 42, lastSessionDate: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (BreathEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreathEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh once per hour — data only changes after sessions
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> BreathEntry {
        BreathEntry(
            date:            .now,
            streak:          defaults.integer(forKey: "wStreak"),
            totalSessions:   defaults.integer(forKey: "wTotalSessions"),
            lastSessionDate: defaults.object(forKey: "wLastSession") as? Date
        )
    }
}

// MARK: - Small Widget View

struct StreakWidgetSmall: View {
    let entry: BreathEntry

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text("\(entry.streak)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(entry.streak == 1 ? "day streak" : "day streak")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Medium Widget View

struct StreakWidgetMedium: View {
    let entry: BreathEntry

    var lastSessionText: String {
        guard let date = entry.lastSessionDate else { return "No sessions yet" }
        if Calendar.current.isDateInToday(date)     { return "Last session: Today" }
        if Calendar.current.isDateInYesterday(date) { return "Last session: Yesterday" }
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .full
        return "Last session: \(fmt.localizedString(for: date, relativeTo: .now))"
    }

    var body: some View {
        HStack(spacing: 20) {
            // Streak
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
                Text("\(entry.streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("day streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                Label("\(entry.totalSessions) sessions", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(lastSessionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "breath://quick-session")!) {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget Definition

struct BreathStreakWidget: Widget {
    let kind = "BreathStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreathProvider()) { entry in
            Group {
                switch WidgetFamily.systemSmall {
                default:
                    StreakWidgetSmall(entry: entry)
                }
            }
        }
        .configurationDisplayName("Streak")
        .description("Your current daily practice streak.")
        .supportedFamilies([.systemSmall])
    }
}

struct BreathStatsWidget: Widget {
    let kind = "BreathStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreathProvider()) { entry in
            StreakWidgetMedium(entry: entry)
        }
        .configurationDisplayName("Stats")
        .description("Streak, total sessions, and a quick-start button.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct BreathWidgetBundle: WidgetBundle {
    var body: some Widget {
        BreathStreakWidget()
        BreathStatsWidget()
    }
}
