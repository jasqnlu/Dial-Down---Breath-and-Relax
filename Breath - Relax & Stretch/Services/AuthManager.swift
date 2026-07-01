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
        if keychainLoadCredential(account: email) != nil {
            return "An account with that email already exists."
        }
        let salt = generateSalt()
        let hash = pbkdf2(password, salt: salt)
        keychainSave(account: email, value: "\(salt.hexString):\(hash)")
        keychainSave(account: "name:\(email)", value: name)
        persist(name: name, email: email, providerVal: .email)
        return nil
    }

    func signIn(email: String, password: String) -> String? {
        guard let stored = keychainLoadCredential(account: email) else {
            return "No account found for this email."
        }
        let parts = stored.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let saltData = Data(hexString: parts[0]) else {
            return "Account data is corrupted. Please create a new account."
        }
        guard pbkdf2(password, salt: saltData) == parts[1] else {
            return "Incorrect password."
        }
        let name = keychainLoadCredential(account: "name:\(email)") ?? "User"
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

    private func keychainLoadCredential(account: String) -> String? {
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

    // MARK: - PBKDF2 (100k rounds, SHA-256, 16-byte random salt)

    private func generateSalt() -> Data {
        var salt = Data(repeating: 0, count: 16)
        salt.withUnsafeMutableBytes {
            _ = SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        return salt
    }

    private func pbkdf2(_ password: String, salt: Data) -> String {
        let passwordData = Data(password.utf8)
        var derivedKey = Data(repeating: 0, count: 32)
        var status = Int32(kCCSuccess)
        _ = derivedKey.withUnsafeMutableBytes { derivedPtr in
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
