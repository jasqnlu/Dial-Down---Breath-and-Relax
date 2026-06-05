import Foundation
import Combine
import AuthenticationServices
import Security
import LocalAuthentication
import CryptoKit

// MARK: - Auth Provider

enum AuthProvider: String, Codable {
    case apple  = "apple"
    case google = "google"
    case email  = "email"
}

// MARK: - AuthManager

@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    // MARK: Published state
    @Published private(set) var isSignedIn: Bool    = false
    @Published private(set) var needsTwoFactor: Bool = false
    @Published private(set) var displayName: String = ""
    @Published private(set) var userEmail: String   = ""
    @Published private(set) var provider: AuthProvider = .email

    // MARK: UserDefaults keys
    private let kIsSignedIn   = "auth.isSignedIn"
    private let kDisplayName  = "auth.displayName"
    private let kEmail        = "auth.email"
    private let kProvider     = "auth.provider"
    private let kTwoFAEnabled = "auth.twoFAEnabled"

    private init() { loadPersistedState() }

    // MARK: - Persistence

    private func loadPersistedState() {
        let d = UserDefaults.standard
        isSignedIn  = d.bool(forKey: kIsSignedIn)
        displayName = d.string(forKey: kDisplayName) ?? ""
        userEmail   = d.string(forKey: kEmail) ?? ""
        if let raw = d.string(forKey: kProvider), let p = AuthProvider(rawValue: raw) {
            provider = p
        }
        if isSignedIn && twoFAEnabled {
            needsTwoFactor = true
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
        if twoFAEnabled { needsTwoFactor = true }
    }

    // MARK: - Two-Factor Auth

    var twoFAEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: kTwoFAEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: kTwoFAEnabled) }
    }

    func completeTwoFactor() {
        needsTwoFactor = false
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

    // MARK: - Sign in with Google (stub)

    func signInWithGoogle(name: String, email: String) {
        persist(name: name, email: email, providerVal: .google)
    }

    // MARK: - Email / Password

    /// Returns nil on success, error string on failure.
    func signUp(name: String, email: String, password: String) -> String? {
        guard !name.isEmpty          else { return "Name is required." }
        guard email.contains("@")   else { return "Enter a valid email address." }
        guard password.count >= 8   else { return "Password must be at least 8 characters." }
        if keychainLoad(account: email) != nil { return "An account with that email already exists." }
        keychainSave(account: email, value: sha256(password))
        persist(name: name, email: email, providerVal: .email)
        return nil
    }

    func signIn(email: String, password: String) -> String? {
        guard let stored = keychainLoad(account: email) else { return "No account found for this email." }
        guard stored == sha256(password) else { return "Incorrect password." }
        let name = UserDefaults.standard.string(forKey: kDisplayName) ?? "User"
        persist(name: name, email: email, providerVal: .email)
        return nil
    }

    // MARK: - Sign out

    func signOut() {
        UserDefaults.standard.set(false, forKey: kIsSignedIn)
        isSignedIn     = false
        needsTwoFactor = false
        displayName    = ""
        userEmail      = ""
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

    // MARK: - Keychain

    private let keychainService = "com.breathapp.auth"

    private func keychainSave(account: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: account,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func keychainLoad(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - SHA-256

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
