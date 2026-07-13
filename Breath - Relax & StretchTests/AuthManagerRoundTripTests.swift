import Testing
import Foundation
@testable import BreathRelaxStretch

// Covers AuthManager's email/password round trip, especially the
// case-insensitivity fix: signing up with one email casing and signing in
// with another used to fail with "No account found for this email" despite
// a real matching account existing, since neither path normalized case
// before using the email as a Keychain account key.
//
// Uses AuthManager.shared (it's a singleton with a private init) against the
// real Keychain, so each test uses its own unique email to avoid colliding
// with other tests or real app data in the simulator, and signs out
// afterwards to avoid leaking @Published state between tests.
@MainActor
struct AuthManagerRoundTripTests {

    private func uniqueEmail() -> String {
        "test-\(UUID().uuidString.prefix(8))@example.com"
    }

    @Test func signInSucceedsWithDifferentCaseThanSignUp() {
        let auth = AuthManager.shared
        let email = uniqueEmail()
        let password = "supersecret1"

        #expect(auth.signUp(name: "Tester", email: email.uppercased(), password: password) == nil)
        #expect(auth.signIn(email: email.lowercased(), password: password) == nil)

        auth.signOut()
    }

    @Test func signInSucceedsWithLeadingTrailingWhitespaceDifference() {
        let auth = AuthManager.shared
        let email = uniqueEmail()
        let password = "supersecret1"

        #expect(auth.signUp(name: "Tester", email: "  \(email) ", password: password) == nil)
        #expect(auth.signIn(email: email, password: password) == nil)

        auth.signOut()
    }

    @Test func signInFailsWithWrongPasswordRegardlessOfEmailCase() {
        let auth = AuthManager.shared
        let email = uniqueEmail()

        _ = auth.signUp(name: "Tester", email: email, password: "supersecret1")
        #expect(auth.signIn(email: email.uppercased(), password: "wrongpassword") == "Incorrect password.")

        auth.signOut()
    }

    @Test func signUpRejectsDuplicateEmailRegardlessOfCase() {
        let auth = AuthManager.shared
        let email = uniqueEmail()

        _ = auth.signUp(name: "First", email: email, password: "supersecret1")
        let secondError = auth.signUp(name: "Second", email: email.uppercased(), password: "anotherpass1")
        #expect(secondError == "An account with that email already exists.")

        auth.signOut()
    }

    @Test func signInFailsForUnknownEmail() {
        let auth = AuthManager.shared
        #expect(auth.signIn(email: uniqueEmail(), password: "whatever1") == "No account found for this email.")
    }
}
