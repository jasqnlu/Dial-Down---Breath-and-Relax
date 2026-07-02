import Testing
import Foundation
@testable import BreathRelaxStretch

// RoutineSharePayload and ChallengePayload are the app's "no backend needed"
// sharing format: a payload is JSON-encoded, URL-safe-base64'd, and stuffed
// into a breath:// deep link. The padding/character swapping is hand-rolled,
// so these tests pin the encode -> link -> decode round trip and the failure
// cases where decode must return nil rather than crash.
struct SharePayloadTests {

    // Pulls the `data` query value back out of a generated share URL, the same
    // way DeepLinkRouter does when a link is opened.
    private func dataParam(of url: URL?) -> String? {
        guard let url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return nil }
        return items.first(where: { $0.name == "data" })?.value
    }

    // MARK: - RoutineSharePayload

    @Test func routineRoundTripsThroughShareURL() throws {
        let original = RoutineSharePayload(name: "Morning Reset",
                                           exerciseNames: ["Neck Roll", "Cat-Cow", "Child's Pose"])
        let token = try #require(dataParam(of: original.shareURL))
        let decoded = try #require(RoutineSharePayload.decode(from: token))
        #expect(decoded.name == original.name)
        #expect(decoded.exerciseNames == original.exerciseNames)
    }

    @Test func routineShareURLUsesBreathScheme() throws {
        let url = try #require(RoutineSharePayload(name: "X", exerciseNames: []).shareURL)
        #expect(url.scheme == "breath")
        #expect(url.host == "routine")
    }

    @Test func routineTokenIsURLSafeWithNoPadding() throws {
        // Unicode + punctuation makes standard base64 produce +, /, and = — the
        // encoder must strip/replace all three or the link breaks in transit.
        let payload = RoutineSharePayload(name: "Café ☕ & Stretch?!",
                                          exerciseNames: ["¡Hola!", "深呼吸", "🧘‍♀️ flow"])
        let token = try #require(dataParam(of: payload.shareURL))
        #expect(!token.contains("+"))
        #expect(!token.contains("/"))
        #expect(!token.contains("="))
    }

    @Test func routineRoundTripsUnicodeAndEmoji() throws {
        let original = RoutineSharePayload(name: "Café ☕ & Stretch?!",
                                           exerciseNames: ["¡Hola!", "深呼吸", "🧘‍♀️ flow"])
        let token = try #require(dataParam(of: original.shareURL))
        let decoded = try #require(RoutineSharePayload.decode(from: token))
        #expect(decoded.name == original.name)
        #expect(decoded.exerciseNames == original.exerciseNames)
    }

    @Test func routineRoundTripsAcrossVaryingLengths() throws {
        // Different payload sizes land on different base64 padding counts (0, 1,
        // 2), exercising every branch of the `while count % 4` re-padding.
        // Names start at length 1 — decode (correctly) rejects nameless routines.
        for count in 1...7 {
            let names = (0..<count).map { "Exercise number \($0)" }
            let original = RoutineSharePayload(name: String(repeating: "n", count: count),
                                               exerciseNames: names)
            let token = try #require(dataParam(of: original.shareURL))
            let decoded = try #require(RoutineSharePayload.decode(from: token))
            #expect(decoded.exerciseNames == original.exerciseNames)
        }
    }

    // MARK: - Untrusted-input limits
    // breath:// links can be crafted by anyone, so decode enforces size caps
    // and returns nil instead of importing absurd content.

    @Test func routineDecodeRejectsEmptyName() throws {
        let payload = RoutineSharePayload(name: "", exerciseNames: ["A"])
        let token = try #require(dataParam(of: payload.shareURL))
        #expect(RoutineSharePayload.decode(from: token) == nil)
    }

    @Test func routineDecodeRejectsOversizedName() throws {
        let payload = RoutineSharePayload(name: String(repeating: "n", count: 81),
                                          exerciseNames: ["A"])
        let token = try #require(dataParam(of: payload.shareURL))
        #expect(RoutineSharePayload.decode(from: token) == nil)
    }

    @Test func routineDecodeRejectsTooManyExercises() throws {
        let payload = RoutineSharePayload(name: "Flood",
                                          exerciseNames: (0..<51).map { "Exercise \($0)" })
        let token = try #require(dataParam(of: payload.shareURL))
        #expect(RoutineSharePayload.decode(from: token) == nil)
    }

    @Test func routineDecodeAcceptsMaximumSizes() throws {
        // The caps are inclusive: exactly 80-char names and 50 exercises pass.
        let payload = RoutineSharePayload(name: String(repeating: "n", count: 80),
                                          exerciseNames: (0..<50).map { "Exercise \($0)" })
        let token = try #require(dataParam(of: payload.shareURL))
        let decoded = try #require(RoutineSharePayload.decode(from: token))
        #expect(decoded.exerciseNames.count == 50)
    }

    @Test func challengeDecodeRejectsAbsurdStats() throws {
        // Fake streak brags: a crafted link with a negative or million-day
        // streak must not decode.
        let negative = ChallengePayload(fromName: "X", streak: -1, totalPoints: 10)
        let token1 = try #require(dataParam(of: negative.shareURL))
        #expect(ChallengePayload.decode(from: token1) == nil)

        let absurd = ChallengePayload(fromName: "X", streak: 1_000_001, totalPoints: 10)
        let token2 = try #require(dataParam(of: absurd.shareURL))
        #expect(ChallengePayload.decode(from: token2) == nil)
    }

    @Test func challengeDecodeRejectsOversizedName() throws {
        let payload = ChallengePayload(fromName: String(repeating: "n", count: 81),
                                       streak: 3, totalPoints: 100)
        let token = try #require(dataParam(of: payload.shareURL))
        #expect(ChallengePayload.decode(from: token) == nil)
    }

    @Test func routineDecodeRejectsGarbage() {
        #expect(RoutineSharePayload.decode(from: "") == nil)
        #expect(RoutineSharePayload.decode(from: "!!! not base64 !!!") == nil)
        // Valid base64, but the JSON underneath isn't a routine payload.
        let wrongShape = Data(#"{"foo":1}"#.utf8).base64EncodedString()
        #expect(RoutineSharePayload.decode(from: wrongShape) == nil)
    }

    // MARK: - ChallengePayload

    @Test func challengeRoundTripsThroughShareURL() throws {
        let original = ChallengePayload(fromName: "Jason", streak: 12, totalPoints: 3450)
        let token = try #require(dataParam(of: original.shareURL))
        let decoded = try #require(ChallengePayload.decode(from: token))
        #expect(decoded.fromName == original.fromName)
        #expect(decoded.streak == original.streak)
        #expect(decoded.totalPoints == original.totalPoints)
    }

    @Test func challengeShareURLUsesBreathScheme() throws {
        let url = try #require(ChallengePayload(fromName: "A", streak: 0, totalPoints: 0).shareURL)
        #expect(url.scheme == "breath")
        #expect(url.host == "challenge")
    }

    @Test func challengeTokenIsURLSafeWithNoPadding() throws {
        let token = try #require(dataParam(of: ChallengePayload(fromName: "François 🏆",
                                                                streak: 999,
                                                                totalPoints: 123456).shareURL))
        #expect(!token.contains("+"))
        #expect(!token.contains("/"))
        #expect(!token.contains("="))
    }

    @Test func challengeDecodeRejectsGarbage() {
        #expect(ChallengePayload.decode(from: "") == nil)
        #expect(ChallengePayload.decode(from: "%%%%") == nil)
    }
}
