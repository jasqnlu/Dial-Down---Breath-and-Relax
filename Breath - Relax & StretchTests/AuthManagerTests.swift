import Testing
import Foundation
@testable import BreathRelaxStretch

// AuthManager's real keychain (Security.framework SecItem calls) is
// unreliable/unavailable in the test runner's sandbox, so these construct
// AuthManager with a `FakeKeychainStore` instead of `.shared`. `isSignedIn`/
// `displayName`/etc. are still backed by `UserDefaults.standard` though, and
// Swift Testing runs every @Test in the same process — so each test resets
// those keys first to avoid leaking state from whichever test ran before it.
// .serialized: AuthManager persists to the process-global UserDefaults.standard,
// so running these tests concurrently (Swift Testing's default) races writes
// from one test against another's assertions.
@Suite(.serialized)
@MainActor
struct AuthManagerTests {

    private static let keysToReset = [
        "auth.isSignedIn", "auth.displayName", "auth.email",
        "auth.provider", "auth.appLockEnabled", "auth.twoFAEnabled", "auth.anonymousID",
        "auth.supabaseUserID"
    ]

    init() {
        let d = UserDefaults.standard
        for key in Self.keysToReset { d.removeObject(forKey: key) }
    }

    private func makeManager(supabase: SupabaseAuthenticating = FakeSupabaseAuthenticating()) -> AuthManager {
        AuthManager(keychain: FakeKeychainStore(), supabase: supabase)
    }

    // MARK: - signUp

    @Test func signUpSucceedsAndPersistsIdentity() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signUpWithPasswordResult = .success("new-user-1")
        let manager = makeManager(supabase: fake)

        let result = await manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")

        #expect(result == nil)
        #expect(manager.isSignedIn)
        #expect(manager.displayName == "Ada")
        #expect(manager.userEmail == "ada@example.com")
        #expect(manager.provider == .email)
        #expect(manager.backendID == "new-user-1")
        #expect(manager.isBackendAuthenticated)
    }

    @Test func signUpRejectsEmptyName() async {
        let manager = makeManager()
        let result = await manager.signUp(name: "", email: "a@b.com", password: "password123")
        #expect(result == "Name is required.")
    }

    @Test func signUpRejectsInvalidEmail() async {
        let manager = makeManager()
        let result = await manager.signUp(name: "Ada", email: "not-an-email", password: "password123")
        #expect(result == "Enter a valid email address.")
    }

    @Test func signUpRejectsShortPassword() async {
        let manager = makeManager()
        let result = await manager.signUp(name: "Ada", email: "a@b.com", password: "short")
        #expect(result == "Password must be at least 8 characters.")
    }

    @Test func signUpSurfacesTheSupabaseErrorAndDoesNotSignIn() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signUpWithPasswordResult = .failure(SupabaseAuthError(code: "user_already_exists", message: nil))
        let manager = makeManager(supabase: fake)

        let result = await manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")

        #expect(result == "An account with that email already exists.")
        #expect(!manager.isSignedIn)
        #expect(!manager.isBackendAuthenticated)
    }

    // MARK: - signIn

    @Test func signInSucceedsAndRestoresNameFromMetadata() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithPasswordResult = .success((userID: "existing-user-1", name: "Ada Lovelace"))
        let manager = makeManager(supabase: fake)

        let result = await manager.signIn(email: "ada@example.com", password: "password123")

        #expect(result == nil)
        #expect(manager.isSignedIn)
        #expect(manager.displayName == "Ada Lovelace")
        #expect(manager.backendID == "existing-user-1")
        #expect(manager.isBackendAuthenticated)
    }

    @Test func signInFallsBackToAGenericNameWhenMetadataHasNone() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithPasswordResult = .success((userID: "existing-user-1", name: nil))
        let manager = makeManager(supabase: fake)

        _ = await manager.signIn(email: "ada@example.com", password: "password123")

        #expect(manager.displayName == "User")
    }

    @Test func signInSurfacesTheSupabaseErrorAndDoesNotSignIn() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithPasswordResult = .failure(SupabaseAuthError(code: "invalid_credentials", message: nil))
        let manager = makeManager(supabase: fake)

        let result = await manager.signIn(email: "ada@example.com", password: "wrongpassword")

        #expect(result == "Incorrect email or password.")
        #expect(!manager.isSignedIn)
        #expect(!manager.isBackendAuthenticated)
    }

    // MARK: - backendID (Supabase auth.uid() vs anonymous fallback)

    @Test func backendIDFallsBackToAnonymousID() {
        let manager = makeManager()
        #expect(manager.backendID == manager.anonymousID)
        #expect(!manager.isBackendAuthenticated)
    }

    @Test func backendIDPrefersStoredSupabaseUserID() {
        let manager = makeManager()
        UserDefaults.standard.set("supabase-uid-123", forKey: "auth.supabaseUserID")
        #expect(manager.backendID == "supabase-uid-123")
        #expect(manager.isBackendAuthenticated)
    }

    @Test func signOutDropsTheSupabaseIdentity() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signUpWithPasswordResult = .success("supabase-uid-123")
        let manager = makeManager(supabase: fake)
        _ = await manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")

        manager.signOut()
        #expect(!manager.isBackendAuthenticated)
        #expect(manager.backendID == manager.anonymousID)
    }

    @Test func deleteAccountDropsTheSupabaseIdentity() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signUpWithPasswordResult = .success("supabase-uid-123")
        let manager = makeManager(supabase: fake)
        _ = await manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")

        manager.deleteAccount()
        #expect(!manager.isBackendAuthenticated)
        #expect(!manager.isSignedIn)
    }

    // MARK: - Google sign-in (real Supabase account)

    @Test func handleGoogleSignInCreatesABackendSessionOnSuccess() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithGoogleResult = .success("google-uid-1")
        let manager = makeManager(supabase: fake)

        let result = await manager.handleGoogleSignIn(
            idToken: "fake-id-token", nonce: "fake-nonce",
            name: "Ada", email: "ada@example.com"
        )

        #expect(result == nil)
        #expect(manager.isSignedIn)
        #expect(manager.provider == .google)
        #expect(manager.displayName == "Ada")
        #expect(manager.backendID == "google-uid-1")
        #expect(manager.isBackendAuthenticated)
    }

    @Test func handleGoogleSignInSurfacesTheSupabaseErrorAndDoesNotSignIn() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithGoogleResult = .failure(SupabaseAuthError(code: "invalid_grant", message: nil))
        let manager = makeManager(supabase: fake)

        let result = await manager.handleGoogleSignIn(
            idToken: "fake-id-token", nonce: "fake-nonce",
            name: "Ada", email: "ada@example.com"
        )

        #expect(result != nil)
        #expect(!manager.isSignedIn)
        #expect(!manager.isBackendAuthenticated)
    }
}

// MARK: - Test doubles

private final class FakeKeychainStore: KeychainStore {
    var storage: [String: String] = [:]
    func save(account: String, value: String) { storage[account] = value }
    func delete(account: String) { storage.removeValue(forKey: account) }
    func loadCredential(account: String) -> String? { storage[account] }
}

private final class FakeSupabaseAuthenticating: SupabaseAuthenticating, @unchecked Sendable {
    var signInWithGoogleResult: Result<String, Error> = .failure(SupabaseAuthError(code: nil, message: nil))
    var signUpWithPasswordResult: Result<String, Error> = .failure(SupabaseAuthError(code: nil, message: nil))
    var signInWithPasswordResult: Result<(userID: String, name: String?), Error> =
        .failure(SupabaseAuthError(code: nil, message: nil))

    func signInWithGoogle(idToken: String, nonce: String?) async throws -> String {
        try signInWithGoogleResult.get()
    }
    func signUpWithPassword(email: String, password: String, name: String) async throws -> String {
        try signUpWithPasswordResult.get()
    }
    func signInWithPassword(email: String, password: String) async throws -> (userID: String, name: String?) {
        try signInWithPasswordResult.get()
    }
}
