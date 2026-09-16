# Google + Email Supabase Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Google sign-in and email/password sign-up/sign-in create real Supabase Auth users (populating `auth.uid()`), exactly the way Sign in with Apple already does, so `AuthManager.isBackendAuthenticated` becomes true and existing best-effort RLS-gated uploads (`uploadProfile`, `registerPushToken`) start succeeding for these providers.

**Architecture:** Extend `SupabaseService`'s existing hand-rolled GoTrue REST calls (no SDK) with Google's `id_token` grant and Supabase's native email/password grant types, mirroring `signInWithApple`. Add an injectable `SupabaseAuthenticating` protocol (mirroring the existing `KeychainStore` seam) so `AuthManager` can be unit tested against a fake instead of the network. Remove the local PBKDF2/Keychain password scheme entirely — Supabase becomes the sole source of truth for email/password.

**Tech Stack:** Swift, SwiftUI, `actor` (SupabaseService), Swift Testing (`@Test`/`#expect`, not XCTest), `CryptoKit` (SHA-256), `CommonCrypto` (removed by this plan), Supabase GoTrue REST API (no supabase-swift SDK — zero-SPM-deps for auth is a deliberate project choice).

**Spec:** `docs/superpowers/specs/2026-09-16-google-email-supabase-auth-design.md`

## Global Constraints

- No new SPM dependencies — every network call is a hand-rolled `URLRequest` against Supabase's REST endpoints, matching the existing `signInWithApple` pattern.
- `user_metadata` (`raw_user_meta_data`) is used only to carry the display name for UI purposes — never for authorization decisions (per the project's Supabase security checklist).
- Every `AuthManager` public method keeps the existing `String?` error-message convention (`nil` = success) — no new error-shape plumbing at call sites.
- "Confirm email" will be disabled in the Supabase dashboard (Task 6) — `signUpWithPassword` must return a session immediately, not require a confirmation-pending state.
- No account-deletion changes, no routine/session sync changes — auth only, per the spec's explicit scope cut.

---

### Task 1: `SupabaseService` — injectable HTTP seam + Google id_token sign-in

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SupabaseService.swift`
- Test: `Breath - Relax & StretchTests/SupabaseServiceTests.swift`

**Interfaces:**
- Produces: `protocol SupabaseHTTPSession: Sendable { func data(for request: URLRequest) async throws -> (Data, URLResponse) }`, `extension URLSession: SupabaseHTTPSession {}`, `SupabaseService.init(keychain:urlSession:)`, `func signInWithGoogle(idToken: String, nonce: String? = nil) async throws -> String`.

`SupabaseService` currently calls `URLSession.shared` directly in five places (`signOut`, `tokenRequest`, `post`, `delete`, `get`), so there is no way to test any auth flow without hitting the real network. This task adds a seam and proves it works by routing the existing Apple sign-in through a shared helper, then adding Google alongside it.

- [ ] **Step 1: Write the failing test for the new seam + Google method**

Add to `Breath - Relax & StretchTests/SupabaseServiceTests.swift` (below the existing `@Test` methods, inside the `struct SupabaseServiceTests`, and a new fake session type + JSON fixture below the struct):

```swift
    @Test func signInWithGoogleReturnsTheUserIDFromASuccessfulGrant() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 200, body: Self.tokenGrantJSON(userID: "google-uid-1"))
        ])
        let service = SupabaseService(
            keychain: FakeSupabaseKeychainStore(),
            urlSession: session
        )
        let uid = try await service.signInWithGoogle(idToken: "fake-id-token", nonce: "fake-nonce")
        #expect(uid == "google-uid-1")
    }

    @Test func signInWithGoogleThrowsOnAnHTTPErrorStatus() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 400, body: Data("{}".utf8))
        ])
        let service = SupabaseService(
            keychain: FakeSupabaseKeychainStore(),
            urlSession: session
        )
        await #expect(throws: (any Error).self) {
            _ = try await service.signInWithGoogle(idToken: "fake-id-token", nonce: "fake-nonce")
        }
    }

    private static func tokenGrantJSON(userID: String) -> Data {
        Data("""
        {
          "access_token": "fake-access-token",
          "refresh_token": "fake-refresh-token",
          "expires_in": 3600,
          "user": { "id": "\(userID)" }
        }
        """.utf8)
    }
}

// MARK: - Test doubles

private final class FakeSupabaseKeychainStore: KeychainStore {
    var storage: [String: String] = [:]
    func save(account: String, value: String) { storage[account] = value }
    func delete(account: String) { storage.removeValue(forKey: account) }
    func loadCredential(account: String) -> String? { storage[account] }
}

/// Replays canned `(status, body)` pairs in call order, one per `data(for:)`
/// invocation — enough for these single-request auth flows without needing a
/// real request-matching mock.
private final class FakeHTTPSession: SupabaseHTTPSession, @unchecked Sendable {
    enum Canned {
        case success(status: Int, body: Data)
    }
    private var responses: [Canned]
    private let lock = NSLock()

    init(responses: [Canned]) { self.responses = responses }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        guard !responses.isEmpty else {
            lock.unlock()
            throw URLError(.unknown)
        }
        let next = responses.removeFirst()
        lock.unlock()
        switch next {
        case .success(let status, let body):
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status,
                httpVersion: nil, headerFields: nil
            )!
            return (body, response)
        }
    }
}
```

Note: the closing `}` that used to end `struct SupabaseServiceTests` moves to right after `tokenGrantJSON` — the new test doubles live at file scope below the struct, same pattern the codebase already uses for `AuthManagerTests`' `FakeKeychainStore`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/SupabaseServiceTests`

Expected: FAIL to compile — `SupabaseService` has no `urlSession:` init parameter, no `SupabaseHTTPSession` protocol, and no `signInWithGoogle` method yet.

- [ ] **Step 3: Add the seam and refactor `signInWithApple` into a shared helper, add `signInWithGoogle`**

In `Breath - Relax & Stretch/Services/SupabaseService.swift`, add this new protocol just above `actor SupabaseService {` (after the `import Foundation` line):

```swift
// MARK: - HTTP seam
// Lets tests inject a fake session instead of hitting the real network —
// mirrors the KeychainStore seam already used for session persistence.
protocol SupabaseHTTPSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: SupabaseHTTPSession {}
```

Change the `init` (currently lines 11-13) to:

```swift
    init(
        keychain: KeychainStore = SecItemKeychainStore(service: "com.breathapp.supabase"),
        urlSession: SupabaseHTTPSession = URLSession.shared
    ) {
        self.keychain = keychain
        self.urlSession = urlSession
    }
```

Add the stored property next to `private let keychain: KeychainStore` (in the `// MARK: - Session state` block):

```swift
    private let keychain: KeychainStore
    private let urlSession: SupabaseHTTPSession
```

Replace every `URLSession.shared.data(for: request)` call in the file with `urlSession.data(for: request)` — there are five: in `signOut`, `tokenRequest`, `post`, `delete`, and `get`.

Replace `signInWithApple` (the whole method, currently under `// MARK: - Auth`) with:

```swift
    /// Exchanges an OIDC id_token (Apple or Google) for a Supabase Auth
    /// session and returns the Supabase user id (`auth.uid()`). `nonce` is
    /// the raw nonce whose hash was sent to the provider — Supabase verifies
    /// the pair when the provider's id_token includes a nonce claim.
    private func signInWithIdToken(provider: String, idToken: String, nonce: String?) async throws -> String {
        struct Body: Encodable {
            let provider: String
            let id_token: String
            let nonce: String?
        }
        let body = try JSONEncoder().encode(Body(provider: provider, id_token: idToken, nonce: nonce))
        let grant = try await tokenRequest(grantType: "id_token", body: body)
        return grant.user.id
    }

    /// Exchanges a Sign in with Apple identity token for a Supabase Auth
    /// session. Requires the Apple provider enabled in Supabase Dashboard →
    /// Authentication → Providers with this app's bundle ID.
    @discardableResult
    func signInWithApple(identityToken: String, nonce: String? = nil) async throws -> String {
        try await signInWithIdToken(provider: "apple", idToken: identityToken, nonce: nonce)
    }

    /// Exchanges a Google id_token for a Supabase Auth session. Requires the
    /// Google provider enabled in Supabase Dashboard → Authentication →
    /// Providers, with both the iOS and Web OAuth Client IDs listed (Web
    /// first) under Client IDs — see Task 6.
    @discardableResult
    func signInWithGoogle(idToken: String, nonce: String? = nil) async throws -> String {
        try await signInWithIdToken(provider: "google", idToken: idToken, nonce: nonce)
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/SupabaseServiceTests`

Expected: PASS — all existing `SupabaseServiceTests` plus the two new ones.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SupabaseService.swift" "Breath - Relax & StretchTests/SupabaseServiceTests.swift"
git commit -m "feat(auth): add injectable HTTP seam to SupabaseService, add Google id_token sign-in"
```

---

### Task 2: `SupabaseService` — email/password sign-up and sign-in

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SupabaseService.swift`
- Test: `Breath - Relax & StretchTests/SupabaseServiceTests.swift`

**Interfaces:**
- Consumes: `SupabaseHTTPSession`, `FakeHTTPSession`, `FakeSupabaseKeychainStore`, `tokenGrantJSON(userID:)` from Task 1.
- Produces: `func signUpWithPassword(email: String, password: String, name: String) async throws -> String`, `func signInWithPassword(email: String, password: String) async throws -> (userID: String, name: String?)`, `struct SupabaseAuthError: LocalizedError`, `protocol SupabaseAuthenticating: Sendable` with `signInWithGoogle`, `signUpWithPassword`, `signInWithPassword` requirements, `extension SupabaseService: SupabaseAuthenticating {}`.

- [ ] **Step 1: Write the failing tests**

Add to `Breath - Relax & StretchTests/SupabaseServiceTests.swift`, inside `struct SupabaseServiceTests` (before the closing brace / test-doubles section):

```swift
    @Test func signUpWithPasswordReturnsTheUserIDFromASuccessfulGrant() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 200, body: Self.tokenGrantJSON(userID: "new-user-1"))
        ])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        let uid = try await service.signUpWithPassword(email: "ada@example.com", password: "password123", name: "Ada")
        #expect(uid == "new-user-1")
    }

    @Test func signUpWithPasswordMapsUserAlreadyExistsToAReadableMessage() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 422, body: Data("""
            {"code":422,"error_code":"user_already_exists","msg":"User already registered"}
            """.utf8))
        ])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        do {
            _ = try await service.signUpWithPassword(email: "ada@example.com", password: "password123", name: "Ada")
            Issue.record("Expected signUpWithPassword to throw")
        } catch {
            #expect((error as? LocalizedError)?.errorDescription == "An account with that email already exists.")
        }
    }

    @Test func signInWithPasswordReturnsUserIDAndNameFromMetadata() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 200, body: Data("""
            {
              "access_token": "fake-access-token",
              "refresh_token": "fake-refresh-token",
              "expires_in": 3600,
              "user": { "id": "existing-user-1", "user_metadata": { "name": "Ada Lovelace" } }
            }
            """.utf8))
        ])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        let result = try await service.signInWithPassword(email: "ada@example.com", password: "password123")
        #expect(result.userID == "existing-user-1")
        #expect(result.name == "Ada Lovelace")
    }

    @Test func signInWithPasswordMapsInvalidCredentialsToAReadableMessage() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 400, body: Data("""
            {"error_code":"invalid_credentials","msg":"Invalid login credentials"}
            """.utf8))
        ])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        do {
            _ = try await service.signInWithPassword(email: "ada@example.com", password: "wrong")
            Issue.record("Expected signInWithPassword to throw")
        } catch {
            #expect((error as? LocalizedError)?.errorDescription == "Incorrect email or password.")
        }
    }
```

Also add `import Testing` already present handles `Issue.record` — no new import needed.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/SupabaseServiceTests`

Expected: FAIL to compile — `signUpWithPassword`/`signInWithPassword` don't exist yet.

- [ ] **Step 3: Implement the new methods**

In `Breath - Relax & Stretch/Services/SupabaseService.swift`, change the `TokenGrant` struct (under `// MARK: - Auth`) to decode optional user metadata:

```swift
    private struct TokenGrant: Decodable {
        struct UserMetadata: Decodable { let name: String? }
        struct User: Decodable {
            let id: String
            let user_metadata: UserMetadata?
        }
        let access_token: String
        let refresh_token: String
        let expires_in: Double
        let user: User
    }
```

Add this error type and body decoder near the bottom of the file, just above `// DTOs live in SupabaseDTOs.swift`:

```swift
// MARK: - Auth errors

/// Maps GoTrue's error response body to a readable message. GoTrue has
/// shipped two error body shapes across versions (`error_code`/`msg` and the
/// older `error`/`error_description`), so both are read; whichever is
/// present wins.
struct SupabaseAuthError: LocalizedError {
    let code: String?
    let message: String?

    var errorDescription: String? {
        switch code {
        case "user_already_exists":  return "An account with that email already exists."
        case "invalid_credentials":  return "Incorrect email or password."
        case "weak_password":        return message ?? "Password is too weak."
        default:                     return "Something went wrong, please try again."
        }
    }
}

private struct SupabaseAuthErrorBody: Decodable {
    let error_code: String?
    let msg: String?
    let error: String?
    let error_description: String?
}
```

Add the new auth methods right after `signInWithGoogle` (still under `// MARK: - Auth`):

```swift
    /// Runs a POST against an auth endpoint that returns a full session
    /// directly (signup with email confirmation disabled, or a token grant
    /// with a query-string grant_type). Distinct from `tokenRequest`
    /// (which always targets `/auth/v1/token`) so this can target
    /// `/auth/v1/signup` too, and so its richer error-body mapping doesn't
    /// change `tokenRequest`'s existing `SupabaseError.httpError` contract
    /// that `refreshSession` pattern-matches on.
    private func authRequest(path: String, grantQuery: String? = nil, body: Data) async throws -> TokenGrant {
        let fullPath = grantQuery.map { "\(path)?grant_type=\($0)" } ?? path
        var request = bareRequest(path: fullPath, method: "POST")
        request.httpBody = body
        let (data, response) = try await urlSession.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let errorBody = try? JSONDecoder().decode(SupabaseAuthErrorBody.self, from: data)
            throw SupabaseAuthError(
                code: errorBody?.error_code ?? errorBody?.error,
                message: errorBody?.msg ?? errorBody?.error_description
            )
        }
        let grant = try JSONDecoder().decode(TokenGrant.self, from: data)
        storeSession(SupabaseSession(
            accessToken:  grant.access_token,
            refreshToken: grant.refresh_token,
            userID:       grant.user.id,
            expiresAt:    Date().addingTimeInterval(grant.expires_in)
        ))
        return grant
    }

    /// Signs up a new Supabase Auth user with email/password. `name` is
    /// stored as `data: {"name": name}`, landing in `raw_user_meta_data` —
    /// used only to redisplay the name on a later sign-in, never for
    /// authorization. Requires the Email provider enabled and "Confirm
    /// email" disabled in Supabase Dashboard → Authentication → Providers
    /// (see Task 6) — otherwise this returns a pending-confirmation user
    /// with no session, and the throw path here won't fire since that's a
    /// 200 response with a null session, which JSONDecoder would then fail
    /// on decoding as TokenGrant (surfacing as a decode error, which is
    /// correct: the app doesn't support the confirmation-pending state).
    func signUpWithPassword(email: String, password: String, name: String) async throws -> String {
        struct Body: Encodable {
            let email: String
            let password: String
            let data: [String: String]
        }
        let body = try JSONEncoder().encode(Body(email: email, password: password, data: ["name": name]))
        let grant = try await authRequest(path: "/auth/v1/signup", body: body)
        return grant.user.id
    }

    /// Signs in an existing Supabase Auth user with email/password. Returns
    /// the display name from `raw_user_meta_data` alongside the user id so
    /// callers can restore it after a reinstall (there is no local Keychain
    /// copy of it once email/password auth lives entirely in Supabase).
    func signInWithPassword(email: String, password: String) async throws -> (userID: String, name: String?) {
        struct Body: Encodable {
            let email: String
            let password: String
        }
        let body = try JSONEncoder().encode(Body(email: email, password: password))
        let grant = try await authRequest(path: "/auth/v1/token", grantQuery: "password", body: body)
        return (grant.user.id, grant.user.user_metadata?.name)
    }
```

Add the injectable protocol at the very bottom of the file, replacing the final line comment:

```swift
// MARK: - Auth seam
// Lets AuthManager depend on an abstraction instead of the concrete actor,
// so tests can inject a fake instead of hitting the network — mirrors the
// KeychainStore seam.
protocol SupabaseAuthenticating: Sendable {
    func signInWithGoogle(idToken: String, nonce: String?) async throws -> String
    func signUpWithPassword(email: String, password: String, name: String) async throws -> String
    func signInWithPassword(email: String, password: String) async throws -> (userID: String, name: String?)
}

extension SupabaseService: SupabaseAuthenticating {}

// DTOs live in SupabaseDTOs.swift — kept separate so Swift 6 never
// infers @MainActor isolation on their synthesised Codable conformances.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/SupabaseServiceTests`

Expected: PASS — all `SupabaseServiceTests`, including the four new ones.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SupabaseService.swift" "Breath - Relax & StretchTests/SupabaseServiceTests.swift"
git commit -m "feat(auth): add Supabase email/password signup and sign-in"
```

---

### Task 3: `GoogleAuthService` — nonce + id_token plumbing

**Files:**
- Modify: `Breath - Relax & Stretch/Services/GoogleAuthService.swift`
- Create: `Breath - Relax & StretchTests/GoogleAuthServiceTests.swift`

**Interfaces:**
- Produces: `struct GoogleAuthService.GoogleSignInResult { let idToken: String; let nonce: String; let user: GoogleUser }`, `GoogleAuthService.signIn(presentationAnchor:) async throws -> GoogleSignInResult` (return type changed from `GoogleUser`), `internal static func GoogleAuthService.sha256Hex(_:) -> String` (testable).

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/GoogleAuthServiceTests.swift`:

```swift
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
                "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b85")
    }

    @Test func sha256HexIsDeterministicForTheSameInput() {
        #expect(GoogleAuthService.sha256Hex("nonce-value") == GoogleAuthService.sha256Hex("nonce-value"))
    }

    @Test func sha256HexDiffersForDifferentInput() {
        #expect(GoogleAuthService.sha256Hex("a") != GoogleAuthService.sha256Hex("b"))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/GoogleAuthServiceTests`

Expected: FAIL to compile — `sha256Hex` doesn't exist, and the new test file isn't in the target yet (Xcode auto-syncs the Tests folder per this project's existing convention — no manual project.pbxproj edit needed, matching how other test files were added).

- [ ] **Step 3: Implement nonce generation, id_token capture, and the new return type**

In `Breath - Relax & Stretch/Services/GoogleAuthService.swift`:

Change `private static func codeChallenge` block to also add a new hashing helper right after it (still inside `// MARK: - PKCE helpers`):

```swift
    private static func codeChallenge(for verifier: String) -> String {
        let hashed = SHA256.hash(data: Data(verifier.utf8))
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Hex-digest SHA-256, for the OIDC nonce (Google/Supabase expect hex,
    /// unlike the base64url PKCE code_challenge above). Not `private` so
    /// GoogleAuthServiceTests can verify it against a known test vector —
    /// same pattern as `SupabaseService.isValidAPIHost`.
    static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
```

Add the new result struct next to `struct GoogleUser` (replace that block):

```swift
    struct GoogleUser {
        let email: String
        let name: String
    }

    /// Everything a caller needs to complete a Supabase id_token exchange
    /// after a successful Google sign-in.
    struct GoogleSignInResult {
        let idToken: String
        let nonce: String
        let user: GoogleUser
    }
```

Replace the `signIn(presentationAnchor:)` method:

```swift
    @MainActor
    func signIn(presentationAnchor: ASPresentationAnchor) async throws -> GoogleSignInResult {
        guard Self.isConfigured else { throw GoogleAuthError.notConfigured }
        self.presentationAnchor = presentationAnchor

        let verifier = Self.randomURLSafeString(length: 64)
        let challenge = Self.codeChallenge(for: verifier)
        let state = Self.randomURLSafeString(length: 16)
        let rawNonce = Self.randomURLSafeString(length: 32)
        let hashedNonce = Self.sha256Hex(rawNonce)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: hashedNonce),
        ]

        let callbackURL = try await authenticate(url: components.url!, callbackScheme: redirectScheme)

        guard
            let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            let returnedState = callbackComponents.queryItems?.first(where: { $0.name == "state" })?.value,
            returnedState == state,
            let code = callbackComponents.queryItems?.first(where: { $0.name == "code" })?.value
        else { throw GoogleAuthError.invalidResponse }

        let tokens = try await exchangeCode(code: code, verifier: verifier)
        let user = try await fetchUserInfo(accessToken: tokens.accessToken)
        return GoogleSignInResult(idToken: tokens.idToken, nonce: rawNonce, user: user)
    }
```

Replace `TokenResponse` and `exchangeCode`:

```swift
    private struct TokenResponse: Decodable {
        let accessToken: String
        let idToken: String
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case idToken = "id_token"
        }
    }

    private func exchangeCode(code: String, verifier: String) async throws -> (accessToken: String, idToken: String) {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params = [
            "client_id": clientID,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI,
        ]
        request.httpBody = params
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw GoogleAuthError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        return (decoded.accessToken, decoded.idToken)
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/GoogleAuthServiceTests`

Expected: PASS — all four `GoogleAuthServiceTests`.

Note: this task does not yet update `AuthView.signInWithGoogle()`, which still calls `.signIn(presentationAnchor:)` expecting the old `GoogleUser` return type — the project will not build end-to-end until Task 4 updates that call site. Build only the test target/scheme's unit tests in this task, not the full app target; the full-app build is verified in Task 4.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/GoogleAuthService.swift" "Breath - Relax & StretchTests/GoogleAuthServiceTests.swift"
git commit -m "feat(auth): add nonce + id_token support to GoogleAuthService"
```

---

### Task 4: `AuthManager` — Google sign-in creates a real Supabase account

**Files:**
- Modify: `Breath - Relax & Stretch/Services/AuthManager.swift`
- Modify: `Breath - Relax & Stretch/Views/Auth/AuthView.swift:210-221`
- Test: `Breath - Relax & StretchTests/AuthManagerTests.swift`

**Interfaces:**
- Consumes: `SupabaseAuthenticating`, `SupabaseAuthError` (Task 2), `GoogleAuthService.GoogleSignInResult` (Task 3).
- Produces: `AuthManager.init(keychain:hasher:supabase:)` (adds `supabase` param), `func handleGoogleSignIn(idToken: String, nonce: String, name: String, email: String) async -> String?` (signature changed from the old synchronous `handleGoogleSignIn(name:email:)`).

- [ ] **Step 1: Write the failing tests**

Add to `Breath - Relax & StretchTests/AuthManagerTests.swift`. First, change `makeManager` to accept an injectable fake Supabase dependency:

```swift
    private func makeManager(
        hasher: @escaping PasswordHasher = AuthManager.pbkdf2,
        supabase: SupabaseAuthenticating = FakeSupabaseAuthenticating()
    ) -> AuthManager {
        AuthManager(keychain: FakeKeychainStore(), hasher: hasher, supabase: supabase)
    }
```

Add a new test group (anywhere inside `struct AuthManagerTests`, e.g. after the `backendID` section):

```swift
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
```

Add the fake dependency at the bottom of the file, in `// MARK: - Test doubles`:

```swift
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/AuthManagerTests`

Expected: FAIL to compile — `AuthManager.init` has no `supabase:` parameter, and `handleGoogleSignIn` doesn't accept `idToken`/`nonce` or return a value.

- [ ] **Step 3: Wire `AuthManager` to Supabase for Google sign-in**

In `Breath - Relax & Stretch/Services/AuthManager.swift`, add the stored property next to `private let hashPassword: PasswordHasher`:

```swift
    private let keychain: KeychainStore
    private let hashPassword: PasswordHasher
    private let supabase: SupabaseAuthenticating
```

Change `init` to:

```swift
    init(
        keychain: KeychainStore = SecItemKeychainStore(service: "com.breathapp.auth"),
        hasher: @escaping PasswordHasher = AuthManager.pbkdf2,
        supabase: SupabaseAuthenticating = SupabaseService.shared
    ) {
        self.keychain = keychain
        self.hashPassword = hasher
        self.supabase = supabase
        loadPersistedState()
    }
```

Replace the `// MARK: - Sign in with Google` section:

```swift
    // MARK: - Sign in with Google

    /// Exchanges the Google id_token for a real Supabase Auth session before
    /// persisting local sign-in state, so a failed exchange (offline,
    /// provider misconfigured, revoked token) surfaces as an error instead
    /// of silently creating a cosmetic-only local account. Returns nil on
    /// success, error string on failure — same convention as signUp/signIn.
    func handleGoogleSignIn(idToken: String, nonce: String, name: String, email: String) async -> String? {
        guard SupabaseService.isConfigured else {
            return "Google sign-in isn't available right now. Please try again later."
        }
        do {
            let uid = try await supabase.signInWithGoogle(idToken: idToken, nonce: nonce)
            UserDefaults.standard.set(uid, forKey: kSupabaseUserID)
            objectWillChange.send() // backendID/isBackendAuthenticated changed
            persist(name: name, email: email, providerVal: .google)
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription
                ?? "Couldn't sign in with Google. Please try again."
        }
    }
```

- [ ] **Step 4: Update the `AuthView` call site**

In `Breath - Relax & Stretch/Views/Auth/AuthView.swift`, replace `signInWithGoogle()` (lines 210-221):

```swift
    private func signInWithGoogle() async {
        guard let anchor = ASPresentationAnchor.currentWindow else { return }
        do {
            let result = try await GoogleAuthService.shared.signIn(presentationAnchor: anchor)
            authError = await auth.handleGoogleSignIn(
                idToken: result.idToken, nonce: result.nonce,
                name: result.user.name, email: result.user.email
            )
        } catch GoogleAuthService.GoogleAuthError.cancelled {
            // User dismissed the sheet — not an error worth surfacing.
        } catch {
            authError = error.localizedDescription
        }
    }
```

- [ ] **Step 5: Run the tests to verify they pass, then build the full app target**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/AuthManagerTests`

Expected: PASS — all `AuthManagerTests`, including the two new ones.

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`

Expected: BUILD SUCCEEDED — confirms `AuthView`'s call site compiles against the new `GoogleSignInResult`/`handleGoogleSignIn` signatures (the project won't fully build until this step, since Task 3 alone left this call site broken).

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Services/AuthManager.swift" "Breath - Relax & Stretch/Views/Auth/AuthView.swift" "Breath - Relax & StretchTests/AuthManagerTests.swift"
git commit -m "feat(auth): Google sign-in creates a real Supabase Auth account"
```

---

### Task 5: `AuthManager` — email/password becomes Supabase-backed, remove PBKDF2

**Files:**
- Modify: `Breath - Relax & Stretch/Services/AuthManager.swift`
- Modify: `Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift:131-159`
- Test: `Breath - Relax & StretchTests/AuthManagerTests.swift`

**Interfaces:**
- Consumes: `SupabaseAuthenticating.signUpWithPassword`/`signInWithPassword` (Task 2).
- Produces: `AuthManager.init(keychain:supabase:)` (drops the `hasher` param entirely), `func signUp(name:email:password:) async -> String?`, `func signIn(email:password:) async -> String?` (both now `async`, replacing the old synchronous versions).

This task replaces the *existing* `signUp`/`signIn` tests (they currently assert on local PBKDF2/Keychain storage, which no longer exists) rather than adding new ones alongside them.

- [ ] **Step 1: Rewrite the signUp/signIn tests as async, against the Supabase fake**

In `Breath - Relax & StretchTests/AuthManagerTests.swift`, replace the entire `// MARK: - signUp` and `// MARK: - signIn` sections (from `@Test func signUpSucceedsAndPersistsIdentity()` through the end of `signInRejectsCorruptedCredentialInvalidHexSalt()`) with:

```swift
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
```

Delete these now-obsolete tests entirely (they exercise removed PBKDF2/Keychain-credential code): `signUpRejectsDuplicateEmail`, `signUpRefusesToStoreAnEmptyHash`, `signInRejectsUnknownEmail`, `signInRejectsWrongPassword`, `signInRejectsCorruptedCredentialMissingSeparator`, `signInRejectsCorruptedCredentialInvalidHexSalt`, `signOutDropsTheSupabaseIdentity` (rewritten below since it currently calls `manager.signUp(...)` synchronously), `deleteAccountDropsTheSupabaseIdentity` (same reason), `signInRejectsWhenComputedHashIsEmpty` (tests the removed hasher-failure path on sign-in).

Replace `signOutDropsTheSupabaseIdentity` and `deleteAccountDropsTheSupabaseIdentity` (in the `// MARK: - backendID` section) with:

```swift
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
```

Finally, remove the now-unused `hasher` parameter path from `makeManager` and every remaining call site that still passes `hasher:` explicitly (`signUpRefusesToStoreAnEmptyHash` and `signInRejectsWhenComputedHashIsEmpty` are already deleted above, so the only remaining explicit-hasher call sites were those two — confirm no others remain, then simplify `makeManager`):

```swift
    private func makeManager(supabase: SupabaseAuthenticating = FakeSupabaseAuthenticating()) -> AuthManager {
        AuthManager(keychain: FakeKeychainStore(), supabase: supabase)
    }
```

Also remove the two direct `AuthManager(keychain: keychain, hasher: AuthManager.pbkdf2)` construction sites in `signInRejectsCorruptedCredentialMissingSeparator`/`signInRejectsCorruptedCredentialInvalidHexSalt` — already covered since those whole tests were deleted above.

The `FakeSupabaseAuthenticating` class from Task 4 stays as-is; no changes needed there.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/AuthManagerTests`

Expected: FAIL to compile — `AuthManager.signUp`/`signIn` are still synchronous with the old PBKDF2 body, and `init` still requires `hasher:`.

- [ ] **Step 3: Replace `signUp`/`signIn` with Supabase-backed versions, remove PBKDF2**

In `Breath - Relax & Stretch/Services/AuthManager.swift`, change `init` to drop `hasher`:

```swift
    init(
        keychain: KeychainStore = SecItemKeychainStore(service: "com.breathapp.auth"),
        supabase: SupabaseAuthenticating = SupabaseService.shared
    ) {
        self.keychain = keychain
        self.supabase = supabase
        loadPersistedState()
    }
```

Remove the `private let hashPassword: PasswordHasher` property (keep `private let supabase: SupabaseAuthenticating`), and remove the top-level `typealias PasswordHasher = (_ password: String, _ salt: Data) -> String` declaration entirely.

Replace the whole `// MARK: - Email / Password` section:

```swift
    // MARK: - Email / Password

    /// Lowercases and trims an email so it's stable as an identifier
    /// regardless of how the user capitalized it at sign-up vs. sign-in.
    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Returns nil on success, error string on failure. Delegates to
    /// Supabase Auth entirely — no local password storage.
    func signUp(name: String, email: String, password: String) async -> String? {
        let email = normalizedEmail(email)
        guard !name.isEmpty        else { return "Name is required." }
        guard email.contains("@") else { return "Enter a valid email address." }
        guard password.count >= 8 else { return "Password must be at least 8 characters." }
        guard SupabaseService.isConfigured else {
            return "Account creation isn't available right now. Please try again later."
        }
        do {
            let uid = try await supabase.signUpWithPassword(email: email, password: password, name: name)
            UserDefaults.standard.set(uid, forKey: kSupabaseUserID)
            objectWillChange.send()
            persist(name: name, email: email, providerVal: .email)
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription
                ?? "Couldn't create your account. Please try again."
        }
    }

    /// Returns nil on success, error string on failure. `name` comes back
    /// from Supabase's `raw_user_meta_data` (set at signup) since there is
    /// no local copy of it once email/password auth lives entirely there.
    func signIn(email: String, password: String) async -> String? {
        let email = normalizedEmail(email)
        guard SupabaseService.isConfigured else {
            return "Sign-in isn't available right now. Please try again later."
        }
        do {
            let (uid, name) = try await supabase.signInWithPassword(email: email, password: password)
            UserDefaults.standard.set(uid, forKey: kSupabaseUserID)
            objectWillChange.send()
            persist(name: name ?? "User", email: email, providerVal: .email)
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription
                ?? "Incorrect email or password."
        }
    }
```

Remove the `provider == .email` Keychain-deletion branch from `deleteAccount()` (it's dead — nothing writes an email credential to the Keychain anymore):

```swift
    func deleteAccount() {
        // Best-effort: remove the public leaderboard row before rotating the
```

(i.e. delete the `if provider == .email, !userEmail.isEmpty { keychain.delete(...); keychain.delete(...) }` block that currently precedes that comment.)

Remove the entire `// MARK: - PBKDF2 (100k rounds, SHA-256, 16-byte random salt)` section (`generateSalt()` and `pbkdf2(_:salt:)`), and remove the file-private `// MARK: - Data hex helpers (file-private)` extension at the bottom of the file (`Data(hexString:)` / `hexString`) — both are now unused. Also remove the now-unused `import CommonCrypto` line at the top of the file.

- [ ] **Step 4: Update the `EmailAuthView` call site**

In `Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift`, replace `submit()` (lines 131-159):

```swift
    private func submit() {
        errorMsg = nil
        isLoading = true
        notifyFeedback.prepare()
        Task {
            if isSignUp {
                guard password == confirmPwd else {
                    errorMsg = "Passwords do not match."
                    notifyFeedback.notificationOccurred(.error)
                    isLoading = false
                    return
                }
                if let err = await auth.signUp(name: name, email: email, password: password) {
                    errorMsg = err
                    notifyFeedback.notificationOccurred(.error)
                } else {
                    notifyFeedback.notificationOccurred(.success)
                    dismiss()
                }
            } else {
                if let err = await auth.signIn(email: email, password: password) {
                    errorMsg = err
                    notifyFeedback.notificationOccurred(.error)
                } else {
                    notifyFeedback.notificationOccurred(.success)
                    dismiss()
                }
            }
            isLoading = false
        }
    }
```

- [ ] **Step 5: Run the tests to verify they pass, then build the full app target**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/AuthManagerTests`

Expected: PASS — every `AuthManagerTests` test.

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`

Expected: BUILD SUCCEEDED and full test suite PASS — confirms nothing else in the app still references `PasswordHasher`, `AuthManager.pbkdf2`, or the old synchronous `signUp`/`signIn`/`handleGoogleSignIn` signatures.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Services/AuthManager.swift" "Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift" "Breath - Relax & StretchTests/AuthManagerTests.swift"
git commit -m "feat(auth): email/password becomes Supabase-backed, remove local PBKDF2 scheme"
```

---

### Task 6: Dashboard configuration + end-to-end manual verification

**Files:** none (dashboard/console configuration only, no code changes).

This task has no automated test — it configures the external services the previous five tasks' code depends on, then manually verifies all three sign-in providers end-to-end in the simulator, since OAuth consent screens and email delivery can't be driven by Swift Testing.

- [ ] **Step 1: Create a Web-type OAuth client in Google Cloud Console**

Go to Google Cloud Console → APIs & Services → Credentials → Create Credentials → OAuth client ID → **Web application** type. Name it something like "Breath — Supabase audience" (it is never called directly by the app; Supabase only needs its Client ID to validate token audiences against). Save the generated Client ID — you do NOT need its secret for this project.

- [ ] **Step 2: Configure the Google provider in Supabase**

Go to `https://supabase.com/dashboard/project/wmsutfittuxrvcwuywrk/auth/providers` → **Google** → enable the provider. In the **Client IDs** field, enter both Client IDs comma-separated, **Web client ID first**:

```
<web-client-id>.apps.googleusercontent.com,100179065649-o6avkunmdq6sf6gvd3huimp1lkcbft2p.apps.googleusercontent.com
```

(the second one is the existing iOS Client ID already hardcoded in `GoogleAuthService.swift:23`). Leave "Skip nonce check" **off** — Task 3 implements the nonce properly.

- [ ] **Step 3: Configure the Email provider in Supabase**

Same Providers page → **Email** → enable the provider → disable **"Confirm email"** (so `signUpWithPassword` returns a usable session immediately, per the spec's decision).

- [ ] **Step 4: Build and run in the simulator, verify all three providers**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`

Then launch the app in the simulator (via Xcode or the project's `run`/`verify` skill if one is set up) and manually check:
1. **Google**: tap "Google" on the welcome screen, complete the consent flow with a real Google account → should land signed in with no error banner.
2. **Email sign-up**: tap "Email" → create an account with a fresh email/password → should land signed in immediately (no "check your email" step).
3. **Email sign-in**: sign out, sign back in with the same email/password → should succeed and show the same display name.
4. **Error path**: try signing up again with the same email → should show "An account with that email already exists." instead of crashing or hanging.

In the Supabase Dashboard → Authentication → Users, confirm all three test accounts now appear as real `auth.users` rows with the correct provider.

- [ ] **Step 5: Commit** (only if any incidental fixes were needed during manual verification; otherwise skip — this task has no code changes to commit)

```bash
git add -A
git commit -m "chore(auth): note dashboard configuration for Google + email providers"
```

(Only run this if there is something to commit — e.g. a doc note. `git status` first; if clean, there is nothing to commit and this step is a no-op.)
