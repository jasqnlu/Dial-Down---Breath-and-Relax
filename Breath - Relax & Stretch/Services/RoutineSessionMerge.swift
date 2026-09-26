import Foundation

/// Pure pull-merge decisions for the sync engine — no `ModelContext`, no
/// network, just data in and a decision out. `SyncEngine` is the thin
/// adapter that calls these and applies the result to real SwiftData
/// objects; keeping the decision itself pure is what makes it cheap to unit
/// test (see `RoutineSessionMergeTests`). See
/// docs/superpowers/specs/2026-09-23-routine-session-sync-engine-design.md.
enum RoutineSessionMerge {

    /// The handful of local `Routine` fields the merge decision actually
    /// needs — deliberately not the whole SwiftData model, so tests can
    /// construct one without touching a `ModelContext` at all.
    struct LocalRoutineSnapshot {
        let updatedAt: Date
        let deletedAt: Date?
    }

    enum RoutineDecision: Equatable {
        /// Remote has this routine, local doesn't (yet) — insert it.
        case insertLocal
        /// Remote's `updatedAt` is newer than local's — overwrite local's
        /// fields with remote's (this also covers a remote delete: a newer
        /// `deletedAt` just comes along as part of "remote is newer").
        case updateLocal
        /// Local is newer (or equal) — remote is stale, nothing to do here.
        /// If local truly has unsynced changes, that's `SyncOutbox`'s job,
        /// not the pull side's.
        case keepLocal
    }

    /// `local == nil` means no local row exists with this uuid at all.
    static func decideRoutine(local: LocalRoutineSnapshot?, remote: RemoteRoutine) -> RoutineDecision {
        guard let local else { return .insertLocal }
        return remote.updatedAt > local.updatedAt ? .updateLocal : .keepLocal
    }

    enum SessionDecision: Equatable {
        case insertLocal
        /// Sessions are append-only — anything already present locally needs
        /// no further action, ever.
        case alreadyPresent
    }

    static func decideSession(existsLocally: Bool) -> SessionDecision {
        existsLocally ? .alreadyPresent : .insertLocal
    }
}
