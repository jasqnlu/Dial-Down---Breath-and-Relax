import Foundation

// MARK: - SupabaseService

actor SupabaseService {
    static let shared = SupabaseService()

    /// `internal` (not `private`) for the same reason as AuthManager.init —
    /// tests construct instances with a FakeKeychainStore; production code
    /// should still go through `.shared`.
    init(keychain: KeychainStore = SecItemKeychainStore(service: "com.breathapp.supabase")) {
        self.keychain = keychain
    }

    // The API base URL (https://<project-ref>.supabase.co) — NOT the dashboard
    // page URL. Dashboard → Settings → API → Project URL.
    // Static lets on an actor are nonisolated — no @MainActor contamination.
    private static let supabaseURL     = "https://wmsutfittuxrvcwuywrk.supabase.co"
    // Decision (open question closed, do not reopen): committing this anon key is
    // intentional, not a leak — Supabase anon/publishable keys are designed to be
    // client-embedded, RLS policies are the actual security boundary, and every
    // Supabase quick-start ships this way. Move it to a config file only if that
    // ever changes.
    private static let supabaseAnonKey = "sb_publishable_fpbIp20MIAf3OV1Two6DhQ_MpZvy2Dc"

    /// True once real credentials are filled in above. While false, the app
    /// skips all remote calls and runs purely on the bundled seed catalog —
    /// so everything works offline / before the backend exists. Validates the
    /// URL is an actual *.supabase.co API host so a pasted dashboard link
    /// can't silently pass as "configured" and 404 every request.
    nonisolated static var isConfigured: Bool {
        !supabaseAnonKey.isEmpty && !supabaseAnonKey.contains("YOUR_ANON_KEY")
            && isValidAPIHost(supabaseURL)
    }

    /// Extracted as its own testable function so config-sanity tests don't
    /// depend on whatever supabaseURL happens to be set to — this is what
    /// would have caught it being the dashboard URL instead of the API host.
    nonisolated static func isValidAPIHost(_ urlString: String) -> Bool {
        URL(string: urlString)?.host?.hasSuffix(".supabase.co") == true
    }

    // MARK: - JSON coders (PostgREST wire format)
    //
    // Every PostgREST request/response in this file goes through these two,
    // so a `Date` field added to any DTO in future is handled correctly by
    // default. Swift's out-of-the-box strategy is `.deferredToDate` — a bare
    // epoch-seconds `Double` — which Postgres `timestamptz` columns reject on
    // write and which can't parse the ISO-8601 strings PostgREST sends back.
    //
    // Deliberately NOT used for the keychain session blob (storeSession /
    // loadSessionIfNeeded): that's a private local round-trip whose already
    // written-to-disk values are epoch doubles, and switching its strategy
    // would make every existing signed-in user's stored session undecodable.

    /// Encoder for anything sent to PostgREST. `.iso8601` emits
    /// `2026-09-04T15:33:20Z`, which Postgres accepts for `timestamptz`.
    nonisolated static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    /// Decoder for anything read back from PostgREST.
    ///
    /// Not plain `.iso8601`: Postgres renders `timestamptz` with microsecond
    /// precision (`2026-09-04T15:33:20.123456+00:00`), and
    /// `ISO8601DateFormatter` only parses fractional seconds when explicitly
    /// configured with `.withFractionalSeconds` — which then *stops* parsing
    /// whole-second timestamps (`2026-09-04T15:33:20+00:00`), which Postgres
    /// emits whenever the stored value happens to have no sub-second part.
    /// Both shapes are real server output, so both must decode.
    nonisolated static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: raw) { return date }
            let whole = ISO8601DateFormatter()
            whole.formatOptions = [.withInternetDateTime]
            if let date = whole.date(from: raw) { return date }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Expected an ISO-8601 timestamp, got \"\(raw)\"."
            ))
        }
        return decoder
    }

    // MARK: - Session state
    // A SupabaseSession exists only for users who signed in with Apple (the
    // id_token exchange below). Guests / local email accounts have none —
    // their requests carry the anon key and can only reach public-read data
    // once the auth.uid() RLS policies in supabase_schema.sql are applied.

    private let keychain: KeychainStore
    private static let sessionAccount = "supabase.session"

    private var session: SupabaseSession?
    private var didLoadSession = false

    // Note: these two use plain JSONEncoder/JSONDecoder, *not* makeEncoder/
    // makeDecoder — see the comment on those. This blob never leaves the
    // device, and its already-persisted `expiresAt` values are epoch doubles.
    private func loadSessionIfNeeded() {
        guard !didLoadSession else { return }
        didLoadSession = true
        guard let json = keychain.loadCredential(account: Self.sessionAccount),
              let data = json.data(using: .utf8),
              let stored = try? JSONDecoder().decode(SupabaseSession.self, from: data) else { return }
        session = stored
    }

    private func storeSession(_ new: SupabaseSession?) {
        session = new
        didLoadSession = true
        if let new,
           let data = try? JSONEncoder().encode(new),
           let json = String(data: data, encoding: .utf8) {
            keychain.save(account: Self.sessionAccount, value: json)
        } else {
            keychain.delete(account: Self.sessionAccount)
        }
    }

    /// The Supabase user id (`auth.uid()`) of the current session, if any.
    var supabaseUserID: String? {
        loadSessionIfNeeded()
        return session?.userID
    }

    // MARK: - Exercises

    /// Fetches all exercises from the remote library.
    ///
    /// Expected Supabase table `exercises` (Dashboard → Table editor):
    ///   id                uuid          primary key  (default gen_random_uuid())
    ///   name              text          not null
    ///   type              text          not null     ('stretch' | 'breath' | 'both')
    ///   target_body_parts text[]        not null
    ///   duration_seconds  int4          not null
    ///   difficulty        int4          not null     (1–3)
    ///   instructions      text[]        not null
    ///   media_url         text          null
    ///   caution           text          null
    /// Enable RLS with a "read for all" select policy so the anon key can fetch.
    func fetchExercises() async throws -> [RemoteExercise] {
        let data = try await get(path: "/rest/v1/exercises?select=*&order=name")
        return try Self.makeDecoder().decode([RemoteExercise].self, from: data)
    }

    // MARK: - Community (leaderboard / public profile)

    /// Upserts the local profile to a public-readable table so it can appear
    /// on the leaderboard. Only points/streak/minutes are shared — no email;
    /// `id` is the anonymous per-install UUID (AuthManager.anonymousID) used
    /// to dedupe rows.
    ///
    /// Expected Supabase table `profiles`:
    ///   id            text  primary key  (anonymous UUID, never an email)
    ///   display_name  text  not null
    ///   total_points  int4  not null
    ///   streak        int4  not null
    ///   total_minutes int4  not null
    /// Enable RLS with a "read for all" select policy for the leaderboard.
    func uploadProfile(_ profile: RemoteProfile) async throws {
        // RemoteProfile.encode(to:) is @MainActor-isolated (Swift 6 inference);
        // hop to main actor for the encode, then continue in the actor.
        let data = try await MainActor.run { try Self.makeEncoder().encode(profile) }
        try await post(path: "/rest/v1/profiles", body: data, upsert: true)
    }

    /// Deletes the leaderboard row for an anonymous ID. Called on account
    /// deletion so the display name/points don't stay public forever after
    /// the local identity is rotated. Requires the profiles delete policy in
    /// supabase_schema.sql.
    func deleteProfile(id: String) async throws {
        // Strict percent-encoding (unreserved characters only): the id should
        // always be a UUID, but it round-trips through UserDefaults, so never
        // let a stray `&`/`=` rewrite the PostgREST filter expression.
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? ""
        try await delete(path: "/rest/v1/profiles?id=eq.\(encoded)")
    }

    // MARK: - Push tokens (streak-about-to-break notifications)

    /// Upserts this device's APNs token + IANA timezone. Requires a Supabase
    /// Auth session (`AuthManager.isBackendAuthenticated`) — RLS rejects the
    /// write otherwise, which is fine: this call is always best-effort
    /// (`try?`) at every call site, exactly like `uploadProfile`.
    ///
    /// Expected Supabase table `push_tokens` — see supabase_schema.sql.
    ///
    /// `user_id` is read from `AuthManager.backendID` — the same identity
    /// `uploadProfile`'s callers key `profiles.id` on, which is exactly what
    /// `push_tokens.user_id` joins against server-side. It's read inside the
    /// `MainActor.run` hop this method already needs for encoding (AuthManager
    /// is `@MainActor`), so no actor isolation is crossed unsafely.
    func registerPushToken(deviceToken: String, timezone: String) async throws {
        let data = try await MainActor.run {
            let payload = RemotePushToken(
                userID: AuthManager.shared.backendID,
                deviceToken: deviceToken,
                timezone: timezone
            )
            return try Self.makeEncoder().encode(payload)
        }
        try await post(path: "/rest/v1/push_tokens", body: data, upsert: true)
    }

    /// Deletes this user's push_tokens row (e.g. the notifications toggle
    /// was switched off). Deletes by the currently authenticated user's own
    /// row — the RLS delete policy only ever lets a session remove
    /// `auth.uid()`'s own row, so no id needs to be passed.
    func deletePushToken() async throws {
        guard let userID = supabaseUserID else { return }
        let encoded = userID.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? ""
        try await delete(path: "/rest/v1/push_tokens?user_id=eq.\(encoded)")
    }

    /// Fetches the top profiles by points for the leaderboard.
    func fetchLeaderboard(limit: Int = 50) async throws -> [RemoteProfile] {
        let data = try await get(path: "/rest/v1/profiles?select=*&order=total_points.desc&limit=\(limit)")
        return try Self.makeDecoder().decode([RemoteProfile].self, from: data)
    }

    // Note: sessions had a write path (uploadSession) that was removed as
    // dead code — nothing in the app called it. See supabase_schema.sql for
    // the matching RLS policy removal.

    // MARK: - Auth

    private struct TokenGrant: Decodable {
        struct User: Decodable { let id: String }
        let access_token: String
        let refresh_token: String
        let expires_in: Double
        let user: User
    }

    /// Exchanges a Sign in with Apple identity token for a Supabase Auth
    /// session and returns the Supabase user id (`auth.uid()`), which becomes
    /// the app's backend identity (AuthManager.backendID). `nonce` is the raw
    /// nonce whose SHA-256 was set on the ASAuthorization request. Requires
    /// the Apple provider enabled in Supabase Dashboard → Authentication →
    /// Providers with this app's bundle ID.
    @discardableResult
    func signInWithApple(identityToken: String, nonce: String? = nil) async throws -> String {
        struct Body: Encodable {
            let provider = "apple"
            let id_token: String
            let nonce: String?
        }
        let body = try JSONEncoder().encode(Body(id_token: identityToken, nonce: nonce))
        let grant = try await tokenRequest(grantType: "id_token", body: body)
        return grant.user.id
    }

    /// Best-effort server-side revocation of the refresh token, then clears
    /// the local session. Never throws — signing out locally must always work.
    func signOut() async {
        loadSessionIfNeeded()
        if let token = session?.accessToken {
            var request = bareRequest(path: "/auth/v1/logout", method: "POST")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
        storeSession(nil)
    }

    /// Refreshes an expiring session. A 4xx from the refresh endpoint means
    /// the refresh token was revoked/expired server-side — the session is
    /// dead, so it's cleared rather than retried forever.
    private func refreshSession(_ current: SupabaseSession) async throws -> SupabaseSession? {
        struct Body: Encodable { let refresh_token: String }
        let body = try JSONEncoder().encode(Body(refresh_token: current.refreshToken))
        do {
            _ = try await tokenRequest(grantType: "refresh_token", body: body)
            return session
        } catch SupabaseError.httpError(let code) where (400..<500).contains(code) {
            storeSession(nil)
            return nil
        }
    }

    /// Runs a token grant against /auth/v1/token and stores the session.
    /// Uses bareRequest (anon Authorization) so a refresh can never recurse
    /// through the data-request path that triggered it.
    private func tokenRequest(grantType: String, body: Data) async throws -> TokenGrant {
        var request = bareRequest(path: "/auth/v1/token?grant_type=\(grantType)", method: "POST")
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        let grant = try JSONDecoder().decode(TokenGrant.self, from: data)
        storeSession(SupabaseSession(
            accessToken:  grant.access_token,
            refreshToken: grant.refresh_token,
            userID:       grant.user.id,
            expiresAt:    Date().addingTimeInterval(grant.expires_in)
        ))
        return grant
    }

    /// A valid (refreshed if needed) access token, or nil when signed out or
    /// the refresh failed transiently — callers then fall back to the anon key.
    private func currentAccessToken() async -> String? {
        loadSessionIfNeeded()
        guard let current = session else { return nil }
        guard current.needsRefresh() else { return current.accessToken }
        return (try? await refreshSession(current))?.accessToken
    }

    // MARK: - HTTP helpers

    @discardableResult
    private func post(path: String, body: Data, upsert: Bool) async throws -> Data? {
        var request = await makeRequest(path: path, method: "POST")
        request.httpBody = body
        if upsert { request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return data
    }

    private func delete(path: String) async throws {
        let request = await makeRequest(path: path, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    private func get(path: String) async throws -> Data {
        let request = await makeRequest(path: path, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return data
    }

    /// apikey + Content-Type only — no Authorization. Auth endpoints build on
    /// this directly so token grants never depend on having a token.
    private func bareRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: URL(string: Self.supabaseURL + path)!)
        request.httpMethod = method
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func makeRequest(path: String, method: String) async -> URLRequest {
        var request = bareRequest(path: path, method: method)
        let bearer = await currentAccessToken() ?? Self.supabaseAnonKey
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SupabaseError.httpError(code)
        }
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case httpError(Int)
    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Supabase request failed with status \(code)."
        }
    }
}

// DTOs live in SupabaseDTOs.swift — kept separate so Swift 6 never
// infers @MainActor isolation on their synthesised Codable conformances.
