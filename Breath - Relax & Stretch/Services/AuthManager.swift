import Foundation
import Combine
import AuthenticationServices
import Security
import LocalAuthentication
import CommonCrypto

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

protocol KeychainStore {
    func save(account: String, value: String)
    func delete(account: String)
    func loadCredential(account: String) -> String?
}

struct SecItemKeychainStore: KeychainStore {
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
    private let kTwoFAEnabled = "auth.twoFAEnabled" // legacy key name; now drives App Lock
    private let kAnonymousID  = "auth.anonymousID"

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

    private let keychain: KeychainStore
    private let hashPassword: PasswordHasher

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
        get { UserDefaults.standard.bool(forKey: kTwoFAEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: kTwoFAEnabled) }
    }

    func completeUnlock() {
        needsUnlock = false
    }

    // MARK: - Sign in with Apple

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        var name = ""
        if let fn = credential.fullName?.givenName {
            name = fn
            if let ln = credential.fullName?.familyName { name += " \(ln)" }
        }
        if name.isEmpty { name = displayName.isEmpty ? "Apple User" : displayName }
        let email = credential.email ?? userEmail
        persist(name: name, email: email, providerVal: .apple)
    }

    // MARK: - Sign in with Google

    func handleGoogleSignIn(name: String, email: String) {
        persist(name: name, email: email, providerVal: .google)
    }

    // MARK: - Email / Password

    /// Returns nil on success, error string on failure.
    func signUp(name: String, email: String, password: String) -> String? {
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
        UserDefaults.standard.set(false, forKey: kIsSignedIn)
        isSignedIn  = false
        needsUnlock = false
        displayName = ""
        userEmail   = ""
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
        // anonymous ID — once rotated, nothing can ever address that row again.
        if SupabaseService.isConfigured {
            let departingID = anonymousID
            Task.detached {
                try? await SupabaseService.shared.deleteProfile(id: departingID)
            }
        }
        let d = UserDefaults.standard
        d.removeObject(forKey: kDisplayName)
        d.removeObject(forKey: kEmail)
        d.removeObject(forKey: kProvider)
        d.removeObject(forKey: kTwoFAEnabled)
        d.removeObject(forKey: kAnonymousID)
        signOut()
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

private extension Data {
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
