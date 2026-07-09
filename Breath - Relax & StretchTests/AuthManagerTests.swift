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

    private func makeManager(hasher: @escaping PasswordHasher = AuthManager.pbkdf2) -> AuthManager {
        AuthManager(keychain: FakeKeychainStore(), hasher: hasher)
    }

    // MARK: - signUp

    @Test func signUpSucceedsAndPersistsIdentity() {
        let manager = makeManager()
        let result = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        #expect(result == nil)
        #expect(manager.isSignedIn)
        #expect(manager.displayName == "Ada")
        #expect(manager.userEmail == "ada@example.com")
        #expect(manager.provider == .email)
    }

    @Test func signUpRejectsEmptyName() {
        let manager = makeManager()
        #expect(manager.signUp(name: "", email: "a@b.com", password: "password123") == "Name is required.")
    }

    @Test func signUpRejectsInvalidEmail() {
        let manager = makeManager()
        #expect(manager.signUp(name: "Ada", email: "not-an-email", password: "password123") == "Enter a valid email address.")
    }

    @Test func signUpRejectsShortPassword() {
        let manager = makeManager()
        #expect(manager.signUp(name: "Ada", email: "a@b.com", password: "short") == "Password must be at least 8 characters.")
    }

    @Test func signUpRejectsDuplicateEmail() {
        let manager = makeManager()
        _ = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        let result = manager.signUp(name: "Ada Two", email: "ada@example.com", password: "password456")
        #expect(result == "An account with that email already exists.")
    }

    @Test func signUpRefusesToStoreAnEmptyHash() {
        // Simulates CommonCrypto failing inside pbkdf2 (it returns "" on error).
        let manager = makeManager(hasher: { _, _ in "" })
        let result = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        #expect(result == "Could not secure your password. Please try again.")
        #expect(!manager.isSignedIn)
    }

    // MARK: - signIn

    @Test func signInSucceedsWithCorrectPassword() {
        let manager = makeManager()
        _ = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        manager.signOut()

        let result = manager.signIn(email: "ada@example.com", password: "password123")
        #expect(result == nil)
        #expect(manager.isSignedIn)
        #expect(manager.displayName == "Ada")
    }

    @Test func signInRejectsUnknownEmail() {
        let manager = makeManager()
        #expect(manager.signIn(email: "nobody@example.com", password: "password123") == "No account found for this email.")
    }

    @Test func signInRejectsWrongPassword() {
        let manager = makeManager()
        _ = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        manager.signOut()

        #expect(manager.signIn(email: "ada@example.com", password: "wrongpassword") == "Incorrect password.")
    }

    @Test func signInRejectsCorruptedCredentialMissingSeparator() {
        let keychain = FakeKeychainStore()
        keychain.storage["ada@example.com"] = "not-a-valid-format"
        let manager = AuthManager(keychain: keychain, hasher: AuthManager.pbkdf2)

        #expect(manager.signIn(email: "ada@example.com", password: "password123")
                == "Account data is corrupted. Please create a new account.")
    }

    @Test func signInRejectsCorruptedCredentialInvalidHexSalt() {
        let keychain = FakeKeychainStore()
        keychain.storage["ada@example.com"] = "zz:deadbeef" // "zz" isn't valid hex
        let manager = AuthManager(keychain: keychain, hasher: AuthManager.pbkdf2)

        #expect(manager.signIn(email: "ada@example.com", password: "password123")
                == "Account data is corrupted. Please create a new account.")
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

    @Test func signOutDropsTheSupabaseIdentity() {
        let manager = makeManager()
        _ = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        UserDefaults.standard.set("supabase-uid-123", forKey: "auth.supabaseUserID")

        manager.signOut()
        #expect(!manager.isBackendAuthenticated)
        #expect(manager.backendID == manager.anonymousID)
    }

    @Test func deleteAccountDropsTheSupabaseIdentity() {
        let manager = makeManager()
        _ = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        UserDefaults.standard.set("supabase-uid-123", forKey: "auth.supabaseUserID")

        manager.deleteAccount()
        #expect(!manager.isBackendAuthenticated)
        #expect(!manager.isSignedIn)
    }

    @Test func signInRejectsWhenComputedHashIsEmpty() {
        // Simulates CommonCrypto failing on the sign-in side specifically —
        // a real credential exists, but re-deriving its hash comes back "".
        let hasher = ToggleableHasher()
        let manager = makeManager(hasher: hasher.hash)
        _ = manager.signUp(name: "Ada", email: "ada@example.com", password: "password123")
        manager.signOut()

        hasher.shouldFail = true
        #expect(manager.signIn(email: "ada@example.com", password: "password123") == "Incorrect password.")
    }
}

// MARK: - Test doubles

private final class FakeKeychainStore: KeychainStore {
    var storage: [String: String] = [:]
    func save(account: String, value: String) { storage[account] = value }
    func delete(account: String) { storage.removeValue(forKey: account) }
    func loadCredential(account: String) -> String? { storage[account] }
}

/// Wraps the real PBKDF2 implementation but can be flipped to return "" on
/// demand, so a test can simulate a CommonCrypto failure deterministically.
private final class ToggleableHasher {
    var shouldFail = false
    func hash(_ password: String, _ salt: Data) -> String {
        shouldFail ? "" : AuthManager.pbkdf2(password, salt: salt)
    }
}
