import Foundation

// MARK: - SupabaseService

actor SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    // Replace these two values with your actual Supabase project URL and anon key.
    // Dashboard → Settings → API
    // Static lets on an actor are nonisolated — no @MainActor contamination.
    private static let supabaseURL     = "https://YOUR_PROJECT.supabase.co"
    private static let supabaseAnonKey = "YOUR_ANON_KEY"

    /// True once real credentials are filled in above. While false (placeholder
    /// values), the app skips all remote calls and runs purely on the bundled
    /// seed catalog — so everything works offline / before the backend exists.
    nonisolated static var isConfigured: Bool {
        !supabaseURL.contains("YOUR_PROJECT") && !supabaseAnonKey.contains("YOUR_ANON_KEY")
    }

    // Bearer token set after sign-in
    private var accessToken: String? = nil

    func setAccessToken(_ token: String?) {
        accessToken = token
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

    /// Upserts a routine to the remote database.
    func uploadRoutine(_ routine: Routine, authorEmail: String) async throws {
        let body = RemoteRoutine(
            id:             routine.uuid.uuidString,
            name:           routine.name,
            exerciseIDs:    routine.exerciseIDs.map { $0.uuidString },
            authorID:       authorEmail,
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

    // MARK: - Sessions

    /// Inserts a completed session to the remote database.
    func uploadSession(_ session: Session, userEmail: String) async throws {
        let body = RemoteSession(
            id:                session.uuid.uuidString,
            userID:            userEmail,
            routineID:         session.routineID.uuidString,
            startedAt:         ISO8601DateFormatter().string(from: session.startedAt),
            completedAt:       session.completedAt.map { ISO8601DateFormatter().string(from: $0) },
            completionPercent: session.completionPercent,
            pointsEarned:      session.pointsEarned
        )
        // Same @MainActor isolation reason as uploadRoutine above.
        let data = try await MainActor.run { try JSONEncoder().encode(body) }
        try await post(path: "/rest/v1/sessions", body: data, upsert: false)
    }

    // MARK: - Auth helpers

    /// Sign in with Apple identity token via Supabase Auth.
    func signInWithApple(identityToken: String) async throws -> String {
        struct Body: Encodable { let provider = "apple"; let id_token: String }
        struct Response: Decodable { let access_token: String }
        let body = try JSONEncoder().encode(Body(id_token: identityToken))
        let data = try await post(path: "/auth/v1/token?grant_type=id_token", body: body, upsert: false)
        let response = try JSONDecoder().decode(Response.self, from: data ?? Data())
        accessToken = response.access_token
        return response.access_token
    }

    // MARK: - HTTP helpers

    @discardableResult
    private func post(path: String, body: Data, upsert: Bool) async throws -> Data? {
        var request = makeRequest(path: path, method: "POST")
        request.httpBody = body
        if upsert { request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return data
    }

    private func get(path: String) async throws -> Data {
        let request = makeRequest(path: path, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return data
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: URL(string: Self.supabaseURL + path)!)
        request.httpMethod = method
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(Self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        }
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
