import Foundation
import SwiftData

/// Queue of pending writes waiting to reach Supabase, persisted as
/// `PendingSyncOp` rows so they survive a force-quit or being offline. See
/// docs/superpowers/specs/2026-09-23-routine-session-sync-engine-design.md.
///
/// A plain struct, not a class — it holds no state of its own, every method
/// takes the `ModelContext` it should operate on. Matches how
/// `UserProfile.dedupe(in:)` is a static function rather than an instance
/// with its own stored context; this project's SwiftData helpers generally
/// don't own a context, they borrow one from the caller.
@MainActor
struct SyncOutbox {

    /// Queues `id` for sync, collapsing with any already-pending op for the
    /// same entity instead of adding a second one. An upsert queued while an
    /// earlier upsert is still pending just resets that op's `createdAt`/
    /// `attemptCount` — the drain step always reads the entity's *current*
    /// local state, so there's nothing stale to worry about. An upsert
    /// followed by a delete (or vice versa) overwrites `opType`, since the
    /// entity's fate is whatever the most recent call says it is.
    func enqueue(_ entityType: PendingSyncOp.EntityType, id: UUID, op: PendingSyncOp.OpType, in context: ModelContext) {
        if let existing = existingOp(for: entityType, id: id, in: context) {
            existing.opType = op
            existing.createdAt = Date()
            existing.attemptCount = 0
            existing.lastAttemptAt = nil
            existing.lastError = nil
        } else {
            context.insert(PendingSyncOp(entityType: entityType, entityID: id, opType: op))
        }
        try? context.save()

        // Best-effort immediate push, so a write made while online reaches
        // Supabase right away instead of waiting for the next foreground/
        // reconnect drain. Centralized here (rather than at every call site
        // that calls `enqueue`) so nothing can forget it. If this fails
        // (offline, etc.) the op is still queued and the scheduled drains
        // will retry it.
        Task { await SyncEngine.shared.drain(context: context) }
    }

    func pendingOps(in context: ModelContext) -> [PendingSyncOp] {
        (try? context.fetch(FetchDescriptor<PendingSyncOp>())) ?? []
    }

    func clear(_ op: PendingSyncOp, in context: ModelContext) {
        context.delete(op)
        try? context.save()
    }

    func recordFailure(_ op: PendingSyncOp, error: Error, in context: ModelContext) {
        op.attemptCount += 1
        op.lastAttemptAt = Date()
        op.lastError = String(describing: error)
        try? context.save()
    }

    private func existingOp(for entityType: PendingSyncOp.EntityType, id: UUID, in context: ModelContext) -> PendingSyncOp? {
        let descriptor = FetchDescriptor<PendingSyncOp>(
            predicate: #Predicate { $0.entityID == id }
        )
        // Filtered again in Swift rather than in the #Predicate: #Predicate's
        // macro reliably handles primitives (String, Int, UUID, Date, Bool)
        // but is finicky about comparing custom Codable enums like
        // PendingSyncOp.EntityType directly, so the predicate only narrows by
        // entityID (a UUID) and the entityType check happens after the fetch.
        return (try? context.fetch(descriptor))?.first { $0.entityType == entityType }
    }
}
