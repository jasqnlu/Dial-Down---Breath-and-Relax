import Foundation

// MARK: - Supabase Remote DTOs
//
// Kept in their own file so Swift 6 never infers @MainActor isolation on
// the synthesised Codable conformances (which would happen if these structs
// shared a file with the `actor SupabaseService` declaration).

struct RemoteExercise: Codable, Sendable {
    let id: String
    let name: String
    let type: String
    let targetBodyParts: [String]
    let durationSeconds: Int
    let difficulty: Int
    let instructions: [String]
    let mediaURL: String?
    let caution: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type, difficulty, instructions, caution
        case targetBodyParts = "target_body_parts"
        case durationSeconds = "duration_seconds"
        case mediaURL        = "media_url"
    }
}

struct RemoteProfile: Codable, Sendable, Identifiable {
    let id: String              // stable identifier — AuthManager.backendID (anonymous UUID), never an email
    let displayName: String
    let totalPoints: Int
    let streak: Int
    let totalMinutes: Int
    /// Local wall-clock time of the most recent completed session, used
    /// server-side (via get_streak_warning_candidates) to tell whether a
    /// user has already practiced today in their own timezone.
    let lastSessionAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName  = "display_name"
        case totalPoints  = "total_points"
        case streak
        case totalMinutes = "total_minutes"
        case lastSessionAt = "last_session_at"
    }
}

/// Upsert body for `push_tokens`. `user_id` *must* be sent explicitly: it's
/// the table's primary key, `not null` with no default (see
/// supabase_schema.sql), so PostgREST rejects a body without it. RLS still
/// enforces that it matches `auth.uid()` — sending it is how the row gets
/// addressed, not how it gets authorized.
struct RemotePushToken: Codable, Sendable {
    let userID: String
    let deviceToken: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case userID      = "user_id"
        case deviceToken = "device_token"
        case timezone
    }
}

// RemoteSession was removed along with SupabaseService.uploadSession() — it
// existed solely to support that dead write path (no in-app caller).
