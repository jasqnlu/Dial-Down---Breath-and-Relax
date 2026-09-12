import Foundation
import Testing
@testable import BreathRelaxStretch

struct SupabaseDTOsTests {

    @Test func remoteProfileEncodesLastSessionAtUnderSnakeCaseKey() throws {
        let date = Date(timeIntervalSince1970: 1_757_000_000) // fixed, so this test never flakes
        let profile = RemoteProfile(
            id: "abc-123", displayName: "Jason", totalPoints: 40,
            streak: 3, totalMinutes: 12, lastSessionAt: date
        )
        let data = try JSONEncoder().encode(profile)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["last_session_at"] != nil)
        #expect(json["lastSessionAt"] == nil)
    }

    @Test func remoteProfileDecodesNullLastSessionAt() throws {
        let json = """
        {"id":"abc-123","display_name":"Jason","total_points":40,"streak":3,"total_minutes":12,"last_session_at":null}
        """
        let profile = try JSONDecoder().decode(RemoteProfile.self, from: Data(json.utf8))
        #expect(profile.lastSessionAt == nil)
    }

    @Test func remotePushTokenEncodesUnderSnakeCaseKeys() throws {
        let token = RemotePushToken(deviceToken: "aa11bb22", timezone: "America/Los_Angeles")
        let data = try JSONEncoder().encode(token)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["device_token"] as? String == "aa11bb22")
        #expect(json["timezone"] as? String == "America/Los_Angeles")
    }
}
