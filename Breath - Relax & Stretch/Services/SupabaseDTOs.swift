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

struct RemoteRoutine: Codable, Sendable {
    let id: String
    let name: String
    let exerciseIDs: [String]
    let authorID: String?
    let authorName: String?      // display name at publish time; nil on legacy records
    let borrowedFromID: String?
    let isPublic: Bool
    let borrowCount: Int?        // nil on legacy records — treat as 0

    enum CodingKeys: String, CodingKey {
        case id, name
        case exerciseIDs    = "exercise_ids"
        case authorID       = "author_id"
        case authorName     = "author_name"
        case borrowedFromID = "borrowed_from_id"
        case isPublic       = "is_public"
        case borrowCount    = "borrow_count"
    }
}

struct RemoteProfile: Codable, Sendable, Identifiable {
    let id: String              // stable identifier — the user's auth email
    let displayName: String
    let totalPoints: Int
    let streak: Int
    let totalMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id
        case displayName  = "display_name"
        case totalPoints  = "total_points"
        case streak
        case totalMinutes = "total_minutes"
    }
}

struct RemoteSession: Codable, Sendable {
    let id: String
    let userID: String
    let routineID: String
    let startedAt: String
    let completedAt: String?
    let completionPercent: Double
    let pointsEarned: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userID            = "user_id"
        case routineID         = "routine_id"
        case startedAt         = "started_at"
        case completedAt       = "completed_at"
        case completionPercent = "completion_percent"
        case pointsEarned      = "points_earned"
    }
}
