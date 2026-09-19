import Testing
@testable import BreathRelaxStretch

struct GoogleAuthServiceTests {

    @Test func isConfiguredIsTrueWithARealClientID() {
        // Regression guard: the shipped clientID must not be the placeholder
        // string GoogleAuthService.isConfigured checks against.
        #expect(GoogleAuthService.isConfigured)
    }

    @Test func sha256HexMatchesAKnownTestVector() {
        // SHA-256("") — a standard test vector, independent of any app logic.
        #expect(GoogleAuthService.sha256Hex("") ==
                "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    @Test func sha256HexIsDeterministicForTheSameInput() {
        #expect(GoogleAuthService.sha256Hex("nonce-value") == GoogleAuthService.sha256Hex("nonce-value"))
    }

    @Test func sha256HexDiffersForDifferentInput() {
        #expect(GoogleAuthService.sha256Hex("a") != GoogleAuthService.sha256Hex("b"))
    }
}
