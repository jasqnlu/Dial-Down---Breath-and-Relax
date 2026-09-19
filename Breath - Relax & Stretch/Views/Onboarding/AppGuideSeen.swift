import Foundation

/// Whether an account has already been shown the coach-mark tour. Keyed per
/// account (`AuthManager.backendID`) so a new/unregistered account on an
/// already-onboarded device replays it. The old global `hasSeenAppGuide` flag
/// is honored only for guests (see `migrateLegacy`), preserving their behavior.
enum AppGuideSeen {
    private static let legacyKey = "hasSeenAppGuide"

    static func key(for userID: String) -> String { "hasSeenAppGuide.\(userID)" }

    static func isSeen(userID: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(for: userID))
    }

    static func markSeen(userID: String, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(for: userID))
    }

    /// Carries the pre-existing global "already saw the tour" flag over to one
    /// account so guests who already saw it don't see it again.
    static func migrateLegacy(userID: String, defaults: UserDefaults = .standard) {
        if defaults.bool(forKey: legacyKey) { markSeen(userID: userID, defaults: defaults) }
    }
}
