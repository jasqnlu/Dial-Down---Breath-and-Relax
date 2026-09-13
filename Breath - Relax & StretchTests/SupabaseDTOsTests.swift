import Foundation
import Testing
@testable import BreathRelaxStretch

struct SupabaseDTOsTests {

    // Every test here goes through SupabaseService.makeEncoder()/makeDecoder()
    // rather than a bare JSONEncoder()/JSONDecoder() on purpose: those are the
    // coders the real PostgREST call sites use, and the whole point of the
    // date-strategy assertions below is that the *wire* format is right.

    @Test func remoteProfileEncodesLastSessionAtAsAnISO8601String() throws {
        let date = Date(timeIntervalSince1970: 1_757_000_000) // fixed, so this test never flakes
        let profile = RemoteProfile(
            id: "abc-123", displayName: "Jason", totalPoints: 40,
            streak: 3, totalMinutes: 12, lastSessionAt: date
        )
        let data = try SupabaseService.makeEncoder().encode(profile)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["lastSessionAt"] == nil)
        // Not merely "not nil": Swift's default strategy would put an
        // epoch-seconds Double here, which Postgres `timestamptz` rejects.
        #expect(json["last_session_at"] as? String == "2025-09-04T15:33:20Z")
    }

    @Test func remoteProfileDecodesNullLastSessionAt() throws {
        let json = """
        {"id":"abc-123","display_name":"Jason","total_points":40,"streak":3,"total_minutes":12,"last_session_at":null}
        """
        let profile = try SupabaseService.makeDecoder().decode(RemoteProfile.self, from: Data(json.utf8))
        #expect(profile.lastSessionAt == nil)
    }

    /// The shape PostgREST actually returns for a `timestamptz`: microsecond
    /// fractional seconds and a `+00:00`-style offset. A plain `.iso8601`
    /// decoding strategy cannot parse this on every OS version we ship to.
    @Test func remoteProfileDecodesPostgRESTTimestampWithFractionalSeconds() throws {
        let json = """
        {"id":"abc-123","display_name":"Jason","total_points":40,"streak":3,"total_minutes":12,"last_session_at":"2026-09-04T15:33:20.123456+00:00"}
        """
        let profile = try SupabaseService.makeDecoder().decode(RemoteProfile.self, from: Data(json.utf8))
        let decoded = try #require(profile.lastSessionAt)
        // 2026-09-04T15:33:20Z — sub-second precision is intentionally dropped.
        #expect(abs(decoded.timeIntervalSince1970 - 1_788_536_000) < 1)
    }

    /// Postgres omits the fractional part when the stored value has none, so
    /// the whole-second form has to decode through the same coder.
    @Test func remoteProfileDecodesWholeSecondTimestampAndNonUTCOffset() throws {
        for stamp in ["2026-09-04T15:33:20+00:00", "2026-09-04T15:33:20Z", "2026-09-04T08:33:20.123456-07:00"] {
            let json = """
            {"id":"abc-123","display_name":"Jason","total_points":40,"streak":3,"total_minutes":12,"last_session_at":"\(stamp)"}
            """
            let profile = try SupabaseService.makeDecoder().decode(RemoteProfile.self, from: Data(json.utf8))
            let decoded = try #require(profile.lastSessionAt, "failed to decode \(stamp)")
            #expect(abs(decoded.timeIntervalSince1970 - 1_788_536_000) < 1, "wrong instant for \(stamp)")
        }
    }

    /// The end-to-end contract: what uploadProfile writes is what
    /// fetchLeaderboard can read back.
    @Test func remoteProfileRoundTripsLastSessionAt() throws {
        let date = Date(timeIntervalSince1970: 1_757_000_000)
        let profile = RemoteProfile(
            id: "abc-123", displayName: "Jason", totalPoints: 40,
            streak: 3, totalMinutes: 12, lastSessionAt: date
        )
        let data = try SupabaseService.makeEncoder().encode(profile)
        let decoded = try SupabaseService.makeDecoder().decode(RemoteProfile.self, from: data)
        #expect(decoded.lastSessionAt == date)
    }

    @Test func remotePushTokenEncodesUnderSnakeCaseKeys() throws {
        let token = RemotePushToken(
            userID: "11111111-2222-3333-4444-555555555555",
            deviceToken: "aa11bb22",
            timezone: "America/Los_Angeles"
        )
        let data = try SupabaseService.makeEncoder().encode(token)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        // user_id is push_tokens' primary key (not null, no default) — every
        // upsert without it is rejected outright by PostgREST.
        #expect(json["user_id"] as? String == "11111111-2222-3333-4444-555555555555")
        #expect(json["userID"] == nil)
        #expect(json["device_token"] as? String == "aa11bb22")
        #expect(json["timezone"] as? String == "America/Los_Angeles")
    }
}
