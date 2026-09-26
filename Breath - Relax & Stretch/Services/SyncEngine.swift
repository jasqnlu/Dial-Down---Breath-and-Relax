import Foundation
import SwiftData
import os

/// Drains `SyncOutbox` (push) and merges the remote `routines`/`sessions`
/// tables into local SwiftData (pull). See docs/superpowers/specs/
/// 2026-09-23-routine-session-sync-engine-design.md for the full design;
/// `RoutineSessionMerge` has the (pure, tested) merge decisions this class
/// applies.
@MainActor
final class SyncEngine {
    static let shared = SyncEngine()

    /// After this many failed attempts, an op is dropped rather than kept
    /// forever — matches how every other best-effort upload in this app
    /// (`uploadProfile`, `registerPushToken`) eventually just gives up and
    /// logs, rather than retrying indefinitely.
    private let retryLimit = 5
    private let outbox = SyncOutbox()
    private let log = Logger(subsystem: "com.jasonlu.breath", category: "sync")

    // MARK: - Push

    func drain(context: ModelContext) async {
        guard SupabaseService.isConfigured, AuthManager.shared.isBackendAuthenticated else { return }

        for op in outbox.pendingOps(in: context) where isDue(op) {
            do {
                switch op.entityType {
                case .routine:
                    guard let routine = fetchRoutine(id: op.entityID, in: context) else {
                        outbox.clear(op, in: context)   // nothing left to push
                        continue
                    }
                    try await SupabaseService.shared.uploadRoutine(dto(for: routine))
                case .session:
                    guard let session = fetchSession(id: op.entityID, in: context) else {
                        outbox.clear(op, in: context)
                        continue
                    }
                    try await SupabaseService.shared.uploadSession(dto(for: session))
                }
                outbox.clear(op, in: context)
            } catch {
                outbox.recordFailure(op, error: error, in: context)
                if op.attemptCount + 1 >= retryLimit {
                    log.warning("Dropping \(op.entityType.rawValue) op after \(self.retryLimit) attempts: \(error)")
                    outbox.clear(op, in: context)
                }
            }
        }
    }

    /// Exponential backoff capped at 5 minutes, so a foreground/reconnect
    /// event doesn't hammer the backend on every single trigger while
    /// something is failing.
    private func isDue(_ op: PendingSyncOp) -> Bool {
        guard let last = op.lastAttemptAt else { return true }
        let backoff = min(pow(2, Double(op.attemptCount)), 300)
        return Date().timeIntervalSince(last) >= backoff
    }

    // MARK: - Pull

    func pullRemote(context: ModelContext) async {
        guard SupabaseService.isConfigured, AuthManager.shared.isBackendAuthenticated else { return }
        let ownerID = AuthManager.shared.backendID

        if let remoteRoutines = try? await SupabaseService.shared.fetchRoutines(ownerID: ownerID) {
            mergeRoutines(remoteRoutines, in: context)
        }
        if let remoteSessions = try? await SupabaseService.shared.fetchSessions(userID: ownerID) {
            mergeSessions(remoteSessions, in: context)
        }
        do {
            try context.save()
        } catch {
            log.warning("Pull-merge save failed: \(error)")
        }
    }

    private func mergeRoutines(_ remote: [RemoteRoutine], in context: ModelContext) {
        for r in remote {
            guard let uuid = UUID(uuidString: r.id) else { continue }
            let existing = fetchRoutine(id: uuid, in: context)
            let snapshot = existing.map {
                RoutineSessionMerge.LocalRoutineSnapshot(updatedAt: $0.updatedAt, deletedAt: $0.deletedAt)
            }
            switch RoutineSessionMerge.decideRoutine(local: snapshot, remote: r) {
            case .insertLocal:
                context.insert(makeRoutine(from: r))
            case .updateLocal:
                if let existing { apply(r, to: existing) }
            case .keepLocal:
                break
            }
        }
    }

    private func mergeSessions(_ remote: [RemoteSession], in context: ModelContext) {
        for r in remote {
            guard let uuid = UUID(uuidString: r.id) else { continue }
            let exists = fetchSession(id: uuid, in: context) != nil
            if case .insertLocal = RoutineSessionMerge.decideSession(existsLocally: exists) {
                context.insert(makeSession(from: r))
            }
        }
    }

    // MARK: - SwiftData <-> DTO conversion

    private func fetchRoutine(id: UUID, in context: ModelContext) -> Routine? {
        let descriptor = FetchDescriptor<Routine>(predicate: #Predicate { $0.uuid == id })
        return (try? context.fetch(descriptor))?.first
    }

    private func fetchSession(id: UUID, in context: ModelContext) -> Session? {
        let descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.uuid == id })
        return (try? context.fetch(descriptor))?.first
    }

    private func dto(for routine: Routine) -> RemoteRoutine {
        RemoteRoutine(
            id: routine.uuid.uuidString,
            name: routine.name,
            exerciseIDs: routine.exerciseIDs.map(\.uuidString),
            authorID: routine.ownerID,
            borrowedFromID: routine.borrowedFromID?.uuidString,
            exerciseDurationOverrides: Dictionary(
                uniqueKeysWithValues: routine.exerciseDurationOverrides.map { ($0.key.uuidString, $0.value) }
            ),
            isPinnedToToday: routine.isPinnedToToday,
            pinnedOrder: routine.pinnedOrder,
            updatedAt: routine.updatedAt,
            deletedAt: routine.deletedAt
        )
    }

    private func apply(_ remote: RemoteRoutine, to routine: Routine) {
        routine.name = remote.name
        routine.exerciseIDs = remote.exerciseIDs.compactMap { UUID(uuidString: $0) }
        routine.borrowedFromID = remote.borrowedFromID.flatMap { UUID(uuidString: $0) }
        routine.exerciseDurationOverrides = Dictionary(
            uniqueKeysWithValues: remote.exerciseDurationOverrides.compactMap { key, value in
                UUID(uuidString: key).map { ($0, value) }
            }
        )
        routine.isPinnedToToday = remote.isPinnedToToday
        routine.pinnedOrder = remote.pinnedOrder
        routine.updatedAt = remote.updatedAt
        routine.deletedAt = remote.deletedAt
    }

    private func makeRoutine(from remote: RemoteRoutine) -> Routine {
        let routine = Routine(
            uuid: UUID(uuidString: remote.id) ?? UUID(),
            name: remote.name,
            exerciseIDs: remote.exerciseIDs.compactMap { UUID(uuidString: $0) },
            borrowedFromID: remote.borrowedFromID.flatMap { UUID(uuidString: $0) },
            exerciseDurationOverrides: Dictionary(
                uniqueKeysWithValues: remote.exerciseDurationOverrides.compactMap { key, value in
                    UUID(uuidString: key).map { ($0, value) }
                }
            ),
            isPinnedToToday: remote.isPinnedToToday,
            pinnedOrder: remote.pinnedOrder,
            ownerID: remote.authorID
        )
        routine.updatedAt = remote.updatedAt
        routine.deletedAt = remote.deletedAt
        return routine
    }

    private func dto(for session: Session) -> RemoteSession {
        RemoteSession(
            id: session.uuid.uuidString,
            userID: AuthManager.shared.backendID,
            routineID: session.routineID.uuidString,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            completionPercent: session.completionPercent,
            pointsEarned: session.pointsEarned
        )
    }

    private func makeSession(from remote: RemoteSession) -> Session {
        let session = Session(
            uuid: UUID(uuidString: remote.id) ?? UUID(),
            routineID: UUID(uuidString: remote.routineID) ?? UUID(),
            startedAt: remote.startedAt,
            completionPercent: remote.completionPercent,
            pointsEarned: remote.pointsEarned
        )
        session.completedAt = remote.completedAt
        return session
    }
}
