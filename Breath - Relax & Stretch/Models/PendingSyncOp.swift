import Foundation
import SwiftData

/// One queued write waiting to reach Supabase. See
/// docs/superpowers/specs/2026-09-23-routine-session-sync-engine-design.md.
///
/// At most one row exists per `(entityType, entityID)` at a time —
/// `SyncOutbox.enqueue` updates the existing row in place (and resets
/// `attemptCount`) instead of inserting a second one, so an edit made while
/// an earlier edit is still queued always uploads the latest state, and an
/// edit-then-delete collapses to a single `.delete`.
@Model
final class PendingSyncOp {
    enum EntityType: String, Codable {
        case routine
        case session
    }

    enum OpType: String, Codable {
        case upsert
        case delete
    }

    var id: UUID = UUID()
    var entityType: EntityType = EntityType.routine
    var entityID: UUID = UUID()
    var opType: OpType = OpType.upsert
    var createdAt: Date = Date()
    var attemptCount: Int = 0
    var lastAttemptAt: Date? = nil
    var lastError: String? = nil

    init(entityType: EntityType, entityID: UUID, opType: OpType) {
        self.id = UUID()
        self.entityType = entityType
        self.entityID = entityID
        self.opType = opType
        self.createdAt = Date()
    }
}
