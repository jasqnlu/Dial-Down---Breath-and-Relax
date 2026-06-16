import WidgetKit

// MARK: - WidgetDataService
// Writes a small payload to a shared App Group UserDefaults so the
// Widget Extension can read current streak/session data without
// needing direct SwiftData access.
//
// SETUP (one-time in Xcode):
//   1. Main app target → Signing & Capabilities → + → App Groups → add "group.YOUR_BUNDLE_ID"
//   2. Widget Extension target → same capability → same group ID
//   3. Replace the groupID constant below with that same identifier.

enum WidgetDataService {
    // Replace with your actual App Group identifier (must match in both targets).
    static let groupID = "group.REPLACE_WITH_YOUR_BUNDLE_ID"

    private static var shared: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    struct Snapshot {
        let streak: Int
        let totalSessions: Int
        let lastSessionDate: Date?
    }

    static func write(streak: Int, totalSessions: Int, lastSessionDate: Date?) {
        shared.set(streak,           forKey: "wStreak")
        shared.set(totalSessions,    forKey: "wTotalSessions")
        shared.set(lastSessionDate,  forKey: "wLastSession")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func read() -> Snapshot {
        Snapshot(
            streak:          shared.integer(forKey: "wStreak"),
            totalSessions:   shared.integer(forKey: "wTotalSessions"),
            lastSessionDate: shared.object(forKey: "wLastSession") as? Date
        )
    }
}
