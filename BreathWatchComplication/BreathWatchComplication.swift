import WidgetKit
import SwiftUI

// MARK: - Streak complication
// Separate Widget Extension target embedded in the Watch App (same
// relationship as BreathWidget is to the iOS app). Reads the same App Group
// UserDefaults that WidgetDataService writes — set the App Groups capability
// on this target too, with the same group ID, and update appGroupID below.

private let appGroupID = "group.REPLACE_WITH_YOUR_BUNDLE_ID"

struct StreakComplicationEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct StreakComplicationProvider: TimelineProvider {
    private var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    func placeholder(in context: Context) -> StreakComplicationEntry {
        StreakComplicationEntry(date: .now, streak: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakComplicationEntry) -> Void) {
        completion(StreakComplicationEntry(date: .now, streak: defaults.integer(forKey: "wStreak")))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakComplicationEntry>) -> Void) {
        let entry = StreakComplicationEntry(date: .now, streak: defaults.integer(forKey: "wStreak"))
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StreakComplicationView: View {
    let entry: StreakComplicationEntry

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(entry.streak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .containerBackground(.background, for: .widget)
    }
}

struct BreathStreakComplication: Widget {
    let kind = "BreathStreakComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakComplicationProvider()) { entry in
            StreakComplicationView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current daily practice streak.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

@main
struct BreathWatchComplicationBundle: WidgetBundle {
    var body: some Widget {
        BreathStreakComplication()
    }
}
