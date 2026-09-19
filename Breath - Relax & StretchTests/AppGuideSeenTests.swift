import Testing
import Foundation
@testable import BreathRelaxStretch

@MainActor
struct AppGuideSeenTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "AppGuideSeenTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func unseenByDefault() {
        #expect(!AppGuideSeen.isSeen(userID: "u1", defaults: makeDefaults()))
    }

    @Test func markSeenIsScopedToTheAccount() {
        let defaults = makeDefaults()
        AppGuideSeen.markSeen(userID: "u1", defaults: defaults)
        #expect(AppGuideSeen.isSeen(userID: "u1", defaults: defaults))
        #expect(!AppGuideSeen.isSeen(userID: "u2", defaults: defaults))
    }

    @Test func legacyGlobalFlagMigratesToTheGivenAccount() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "hasSeenAppGuide")
        AppGuideSeen.migrateLegacy(userID: "guest-1", defaults: defaults)
        #expect(AppGuideSeen.isSeen(userID: "guest-1", defaults: defaults))
    }

    @Test func migrationDoesNothingWithoutTheLegacyFlag() {
        let defaults = makeDefaults()
        AppGuideSeen.migrateLegacy(userID: "guest-1", defaults: defaults)
        #expect(!AppGuideSeen.isSeen(userID: "guest-1", defaults: defaults))
    }
}
