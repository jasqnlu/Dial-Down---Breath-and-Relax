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
    private static let supabaseAnonKey = "sb_publishable_fpbIp20MIAf3OV1Two6DhQ_MpZvy2Dc"

    /// True once real credentials are filled in above. While false, the app
    /// skips all remote calls and runs purely on the bundled seed catalog —
    /// so everything works offline / before the backend exists. Validates the
    /// URL is an actual *.supabase.co API host so a pasted dashboard link
    /// can't silently pass as "configured" and 404 every request.
    nonisolated static var isConfigured: Bool {
        guard !supabaseAnonKey.isEmpty, !supabaseAnonKey.contains("YOUR_ANON_KEY"),
              let host = URL(string: supabaseURL)?.host else { return false }
        return host.hasSuffix(".supabase.co")
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
        return try JSONDecoder().decode([RemoteExercise].self, from: data)
    }

    // MARK: - Public Routines

    /// Fetches all routines marked is_public = true.
    func fetchPublicRoutines() async throws -> [RemoteRoutine] {
        let data = try await get(path: "/rest/v1/routines?select=*&is_public=eq.true&order=name")
        return try JSONDecoder().decode([RemoteRoutine].self, from: data)
    }

    /// Upserts a routine to the remote database. `authorID` must be the
    /// anonymous UUID (AuthManager.anonymousID) — never an email; the table
    /// is publicly readable.
    func uploadRoutine(_ routine: Routine, authorID: String) async throws {
        let body = RemoteRoutine(
            id:             routine.uuid.uuidString,
            name:           routine.name,
            exerciseIDs:    routine.exerciseIDs.map { $0.uuidString },
            authorID:       authorID,
            authorName:     routine.authorName,
            borrowedFromID: routine.borrowedFromID?.uuidString,
            isPublic:       routine.isPublic,
            borrowCount:    routine.borrowCount
        )
        // RemoteRoutine.encode(to:) is @MainActor-isolated (Swift 6 inference);
        // hop to main actor for the encode, then continue in the actor.
        let data = try await MainActor.run { try JSONEncoder().encode(body) }
        try await post(path: "/rest/v1/routines", body: data, upsert: true)
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
        let data = try await MainActor.run { try JSONEncoder().encode(profile) }
        try await post(path: "/rest/v1/profiles", body: data, upsert: true)
    }

    /// Deletes the leaderboard row for an anonymous ID. Called on account
    /// deletion so the display name/points don't stay public forever after
    /// the local identity is rotated. Requires the profiles delete policy in
    /// supabase_schema.sql.
    func deleteProfile(id: String) async throws {
        try await delete(path: "/rest/v1/profiles?id=eq.\(id)")
    }

    /// Fetches the top profiles by points for the leaderboard.
    func fetchLeaderboard(limit: Int = 50) async throws -> [RemoteProfile] {
        let data = try await get(path: "/rest/v1/profiles?select=*&order=total_points.desc&limit=\(limit)")
        return try JSONDecoder().decode([RemoteProfile].self, from: data)
    }

    // MARK: - Sessions

    /// Inserts a completed session to the remote database. `userID` must be
    /// the anonymous UUID (AuthManager.anonymousID) — never an email.
    func uploadSession(_ session: Session, userID: String) async throws {
        let formatter = ISO8601DateFormatter()
        let body = RemoteSession(
            id:                session.uuid.uuidString,
            userID:            userID,
            routineID:         session.routineID.uuidString,
            startedAt:         formatter.string(from: session.startedAt),
            completedAt:       session.completedAt.map { formatter.string(from: $0) },
            completionPercent: session.completionPercent * 100,
            pointsEarned:      session.pointsEarned
        )
        // Same @MainActor isolation reason as uploadRoutine above.
        let data = try await MainActor.run { try JSONEncoder().encode(body) }
        try await post(path: "/rest/v1/sessions", body: data, upsert: false)
    }

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
