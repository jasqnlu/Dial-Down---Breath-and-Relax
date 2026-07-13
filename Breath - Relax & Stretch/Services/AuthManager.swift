import Foundation
import Combine
import AuthenticationServices
import Security
import LocalAuthentication
import CommonCrypto
import CryptoKit
import os

// MARK: - Auth Provider

enum AuthProvider: String, Codable {
    case apple  = "apple"
    case google = "google"
    case email  = "email"
    case guest  = "guest"
}

// MARK: - Keychain seam
// Abstraction over Security.framework's SecItem calls so tests can swap in an
// in-memory store — the real keychain is unreliable/unavailable in the test
// runner's sandbox.

// `nonisolated`: the project defaults declarations to @MainActor isolation,
// but the keychain seam is also used from inside the SupabaseService actor
// (session persistence), so it must stay actor-agnostic.
nonisolated protocol KeychainStore {
    func save(account: String, value: String)
    func delete(account: String)
    func loadCredential(account: String) -> String?
}

nonisolated struct SecItemKeychainStore: KeychainStore {
    let service: String

    func save(account: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    func loadCredential(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - AuthManager

typealias PasswordHasher = (_ password: String, _ salt: Data) -> String

@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    // MARK: Published state
    @Published private(set) var isSignedIn: Bool    = false
    @Published private(set) var needsUnlock: Bool   = false
    @Published private(set) var displayName: String = ""
    @Published private(set) var userEmail: String   = ""
    @Published private(set) var provider: AuthProvider = .email

    var isGuest: Bool { isSignedIn && provider == .guest }

    // MARK: UserDefaults keys
    private let kIsSignedIn   = "auth.isSignedIn"
    private let kDisplayName  = "auth.displayName"
    private let kEmail        = "auth.email"
    private let kProvider     = "auth.provider"
    private let kAppLockEnabled = "auth.appLockEnabled"
    private let kTwoFAEnabled = "auth.twoFAEnabled" // legacy key migrated to kAppLockEnabled
    private let kAnonymousID  = "auth.anonymousID"
    private let kSupabaseUserID = "auth.supabaseUserID" // auth.uid() — not a secret; the tokens live in the keychain

    // MARK: - Anonymous identity
    // Backend-facing identity. A random UUID minted once per install and used
    // as profiles.id / routines.author_id / sessions.user_id — never the email,
    // because those tables are publicly readable. Survives sign-in/sign-out so
    // a guest who later creates an account keeps their leaderboard row.
    var anonymousID: String {
        let d = UserDefaults.standard
        if let existing = d.string(forKey: kAnonymousID) { return existing }
        let fresh = UUID().uuidString
        d.set(fresh, forKey: kAnonymousID)
        return fresh
    }

    // MARK: - Backend identity
    // What community rows (profiles.id, routines.author_id, sessions.user_id)
    // are keyed on. With a Supabase Auth session (Sign in with Apple) this is
    // the Supabase user id, so the auth.uid() RLS policies authorize writes;
    // otherwise it falls back to the anonymous per-install UUID, whose writes
    // the backend now rejects — community uploads are best-effort by design.
    var backendID: String {
        UserDefaults.standard.string(forKey: kSupabaseUserID) ?? anonymousID
    }

    /// True when a Supabase Auth session backs this user (writes to the
    /// community tables will be authorized as them).
    var isBackendAuthenticated: Bool {
        UserDefaults.standard.string(forKey: kSupabaseUserID) != nil
    }

    private let keychain: KeychainStore
    private let hashPassword: PasswordHasher

    /// Raw nonce for the in-flight Sign in with Apple request; its SHA-256 is
    /// embedded in the Apple identity token, and Supabase verifies the pair.
    private var pendingAppleNonce: String?

    /// `internal` (not `private`) so `@testable import` can construct
    /// instances with a fake keychain/hasher; production code should still
    /// go through `.shared`.
    init(
        keychain: KeychainStore = SecItemKeychainStore(service: "com.breathapp.auth"),
        hasher: @escaping PasswordHasher = AuthManager.pbkdf2
    ) {
        self.keychain = keychain
        self.hashPassword = hasher
        loadPersistedState()
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        let d = UserDefaults.standard
        migrateLegacyAppLockKeyIfNeeded(defaults: d)
        isSignedIn  = d.bool(forKey: kIsSignedIn)
        displayName = d.string(forKey: kDisplayName) ?? ""
        userEmail   = d.string(forKey: kEmail) ?? ""
        if let raw = d.string(forKey: kProvider), let p = AuthProvider(rawValue: raw) {
            provider = p
        }
        if isSignedIn && appLockEnabled {
            needsUnlock = true
        }
    }

    private func persist(name: String, email: String, providerVal: AuthProvider) {
        let d = UserDefaults.standard
        d.set(true,                 forKey: kIsSignedIn)
        d.set(name,                 forKey: kDisplayName)
        d.set(email,                forKey: kEmail)
        d.set(providerVal.rawValue, forKey: kProvider)
        displayName    = name
        userEmail      = email
        provider       = providerVal
        isSignedIn     = true
        // Note: App Lock is deliberately NOT triggered here — the user just
        // completed an interactive sign-in. The lock gates cold launches only
        // (see loadPersistedState).
    }

    // MARK: - Guest mode

    /// Use the app without an account. Everything stays on-device; the
    /// anonymous UUID is the only identity. Fully upgradeable later via the
    /// regular sign-in paths (which simply overwrite name/email/provider).
    func continueAsGuest() {
        persist(name: displayName.isEmpty ? "Guest" : displayName,
                email: "",
                providerVal: .guest)
    }

    // MARK: - App Lock (biometric gate on launch — not a second auth factor)

    var appLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: kAppLockEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: kAppLockEnabled) }
    }

    private func migrateLegacyAppLockKeyIfNeeded(defaults d: UserDefaults) {
        guard d.object(forKey: kAppLockEnabled) == nil,
              d.object(forKey: kTwoFAEnabled) != nil
        else { return }
        d.set(d.bool(forKey: kTwoFAEnabled), forKey: kAppLockEnabled)
        d.removeObject(forKey: kTwoFAEnabled)
    }

    func completeUnlock() {
        needsUnlock = false
    }

    // MARK: - Sign in with Apple

    /// Configures the ASAuthorization request: scopes plus a fresh nonce
    /// (SHA-256 on the request, raw kept for the Supabase exchange) so the
    /// identity token can't be replayed by a third party.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let raw = Self.randomNonce()
        pendingAppleNonce = raw
        request.nonce = SHA256.hash(data: Data(raw.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        var name = ""
        if let fn = credential.fullName?.givenName {
            name = fn
            if let ln = credential.fullName?.familyName { name += " \(ln)" }
        }
        if name.isEmpty { name = displayName.isEmpty ? "Apple User" : displayName }

        // Apple only returns `email` on the very first sign-in for a given app;
        // every sign-in after that returns nil, so falling back to `userEmail`
        // breaks after a reinstall (local state gone, nothing to fall back to).
        // credential.user is Apple's stable per-app identifier and is returned
        // on every sign-in, so we use it as a Keychain key to recover the email
        // Apple gave us the first time.
        let appleEmailAccount = "apple-email:\(credential.user)"
        let email: String
        if let freshEmail = credential.email, !freshEmail.isEmpty {
            email = freshEmail
            keychainSave(account: appleEmailAccount, value: freshEmail)
        } else if let recoveredEmail = keychainLoadCredential(account: appleEmailAccount) {
            email = recoveredEmail
        } else {
            email = userEmail
        }

        persist(name: name, email: email, providerVal: .apple)

        // Exchange the Apple identity token for a Supabase Auth session so
        // backend writes are authorized as this user (auth.uid() RLS).
        // Best-effort: on failure (offline, provider not enabled in the
        // dashboard) the app keeps working locally. Identity tokens are
        // single-use with a ~10 min TTL, so there is no stored-token retry —
        // the user can just sign in with Apple again.
        let nonce = pendingAppleNonce
        pendingAppleNonce = nil
        guard SupabaseService.isConfigured,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else { return }
        Task { [weak self] in
            do {
                let uid = try await SupabaseService.shared.signInWithApple(
                    identityToken: identityToken, nonce: nonce)
                guard let self else { return }
                UserDefaults.standard.set(uid, forKey: self.kSupabaseUserID)
                self.objectWillChange.send() // backendID/isBackendAuthenticated changed
            } catch {
                Logger(subsystem: "com.jasonlu.breath", category: "supabaseAuth")
                    .warning("Apple → Supabase token exchange failed: \(error)")
            }
        }
    }

    /// Random URL-safe nonce for Sign in with Apple. The slight modulo bias
    /// is irrelevant here — the nonce only needs to be unpredictable, not
    /// uniformly distributed.
    nonisolated private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        guard status == errSecSuccess else {
            // SecRandom failing is effectively impossible; fall back to a
            // UUID rather than sending a predictable constant.
            return UUID().uuidString
        }
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    // MARK: - Sign in with Google

    func handleGoogleSignIn(name: String, email: String) {
        persist(name: name, email: email, providerVal: .google)
    }

    // MARK: - Email / Password

    /// Lowercases and trims an email so it's stable as a Keychain account key
    /// regardless of how the user capitalized it at sign-up vs. sign-in.
    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Returns nil on success, error string on failure.
    func signUp(name: String, email: String, password: String) -> String? {
        let email = normalizedEmail(email)
        guard !name.isEmpty        else { return "Name is required." }
        guard email.contains("@") else { return "Enter a valid email address." }
        guard password.count >= 8 else { return "Password must be at least 8 characters." }
        if keychain.loadCredential(account: email) != nil {
            return "An account with that email already exists."
        }
        let salt = generateSalt()
        let hash = hashPassword(password, salt)
        // pbkdf2 returns "" if CommonCrypto fails; storing "salt:" would let
        // any future password match the empty hash. Refuse instead.
        guard !hash.isEmpty else { return "Could not secure your password. Please try again." }
        keychain.save(account: email, value: "\(salt.hexString):\(hash)")
        keychain.save(account: "name:\(email)", value: name)
        persist(name: name, email: email, providerVal: .email)
        return nil
    }

    func signIn(email: String, password: String) -> String? {
        let email = normalizedEmail(email)
        guard let stored = keychain.loadCredential(account: email) else {
            return "No account found for this email."
        }
        let parts = stored.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let saltData = Data(hexString: parts[0]) else {
            return "Account data is corrupted. Please create a new account."
        }
        let computed = hashPassword(password, saltData)
        guard !computed.isEmpty, computed == parts[1] else {
            return "Incorrect password."
        }
        let name = keychain.loadCredential(account: "name:\(email)") ?? "User"
        persist(name: name, email: email, providerVal: .email)
        return nil
    }

    // MARK: - Sign out

    func signOut() {
        endSupabaseSession()
        clearLocalSignIn()
    }

    private func clearLocalSignIn() {
        let d = UserDefaults.standard
        d.removeObject(forKey: kIsSignedIn)
        d.removeObject(forKey: kDisplayName)
        d.removeObject(forKey: kEmail)
        d.removeObject(forKey: kProvider)
        isSignedIn  = false
        needsUnlock = false
        displayName = ""
        userEmail   = ""
    }

    /// Drops the Supabase user id and (best-effort) revokes the session's
    /// refresh token server-side.
    private func endSupabaseSession() {
        UserDefaults.standard.removeObject(forKey: kSupabaseUserID)
        guard SupabaseService.isConfigured else { return }
        Task.detached { await SupabaseService.shared.signOut() }
    }

    // MARK: - Delete account
    // App Store Guideline 5.1.1(v): apps offering account creation must offer
    // in-app account deletion. Removes the stored credential + name from the
    // keychain, resets all auth state, and rotates the anonymous backend ID so
    // no future upload can be linked to the deleted identity. Local session
    // history (SwiftData) is untouched — it belongs to the device, not the account.

    func deleteAccount() {
        if provider == .email, !userEmail.isEmpty {
            keychain.delete(account: userEmail)
            keychain.delete(account: "name:\(userEmail)")
        }
        // Best-effort: remove the public leaderboard row before rotating the
        // identity — once rotated, nothing can ever address that row again.
        // Ordered inside one task: the profiles delete policy requires
        // id = auth.uid(), so the row must go *before* the session is revoked.
        if SupabaseService.isConfigured {
            let departingID = backendID
            Task.detached {
                try? await SupabaseService.shared.deleteProfile(id: departingID)
                await SupabaseService.shared.signOut()
            }
        }
        let d = UserDefaults.standard
        d.removeObject(forKey: kDisplayName)
        d.removeObject(forKey: kEmail)
        d.removeObject(forKey: kProvider)
        d.removeObject(forKey: kTwoFAEnabled)
        d.removeObject(forKey: kAnonymousID)
        d.removeObject(forKey: kSupabaseUserID)
        // Not signOut() — that would race a second Supabase sign-out against
        // the ordered delete-then-revoke task above.
        clearLocalSignIn()
    }

    // MARK: - Biometrics

    func authenticateWithBiometrics() async -> Bool {
        let ctx = LAContext()
        var err: NSError?
        let policy: LAPolicy = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        guard ctx.canEvaluatePolicy(policy, error: &err) else { return false }
        do {
            return try await ctx.evaluatePolicy(policy, localizedReason: "Verify it's you to continue")
        } catch {
            return false
        }
    }

    // MARK: - PBKDF2 (100k rounds, SHA-256, 16-byte random salt)

    private func generateSalt() -> Data {
        var salt = Data(repeating: 0, count: 16)
        salt.withUnsafeMutableBytes {
            _ = SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        return salt
    }

    /// The production `PasswordHasher`. `static` (no `self`) so it can be
    /// referenced as a default argument in `init`; `nonisolated` because it
    /// touches no actor-isolated state, matching `PasswordHasher`'s plain
    /// (non-`@MainActor`) function type.
    nonisolated static func pbkdf2(_ password: String, salt: Data) -> String {
        let passwordData = Data(password.utf8)
        var derivedKey = Data(repeating: 0, count: 32)
        var status = Int32(kCCSuccess)
        derivedKey.withUnsafeMutableBytes { derivedPtr in
            passwordData.withUnsafeBytes { passwordPtr in
                salt.withUnsafeBytes { saltPtr in
                    status = CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordPtr.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(100_000),
                        derivedPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }
        return status == kCCSuccess ? derivedKey.hexString : ""
    }
}

// MARK: - Data hex helpers (file-private)

nonisolated private extension Data {
    init?(hexString: String) {
        guard hexString.count.isMultiple(of: 2) else { return nil }
        let bytes = stride(from: 0, to: hexString.count, by: 2).compactMap {
            UInt8(hexString.dropFirst($0).prefix(2), radix: 16)
        }
        guard bytes.count == hexString.count / 2 else { return nil }
        self.init(bytes)
    }

    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
