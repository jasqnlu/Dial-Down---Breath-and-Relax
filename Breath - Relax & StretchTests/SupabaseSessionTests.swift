import Testing
import Foundation
@testable import BreathRelaxStretch

// SupabaseSession is the pure-value half of the Supabase Auth wiring: the
// keychain persistence format and the refresh policy. The networked half
// (token grants in SupabaseService) is a thin JSON mapping over these.
struct SupabaseSessionTests {

    private func makeSession(expiresAt: Date) -> SupabaseSession {
        SupabaseSession(
            accessToken: "access-abc",
            refreshToken: "refresh-def",
            userID: "9a2f1c3e-0000-0000-0000-000000000000",
            expiresAt: expiresAt
        )
    }

    // MARK: - Keychain persistence format

    @Test func codableRoundTripPreservesEverything() throws {
        let original = makeSession(expiresAt: Date(timeIntervalSince1970: 1_800_000_000))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SupabaseSession.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Refresh policy (refresh within 120 s of expiry)

    @Test func freshTokenDoesNotNeedRefresh() {
        let session = makeSession(expiresAt: Date(timeIntervalSinceNow: 3600))
        #expect(!session.needsRefresh())
    }

    @Test func tokenNearExpiryNeedsRefresh() {
        let now = Date()
        let session = makeSession(expiresAt: now.addingTimeInterval(119))
        #expect(session.needsRefresh(at: now))
    }

    @Test func tokenJustOutsideTheWindowDoesNotNeedRefresh() {
        let now = Date()
        let session = makeSession(expiresAt: now.addingTimeInterval(121))
        #expect(!session.needsRefresh(at: now))
    }

    @Test func expiredTokenNeedsRefresh() {
        let now = Date()
        let session = makeSession(expiresAt: now.addingTimeInterval(-10))
        #expect(session.needsRefresh(at: now))
    }
}
