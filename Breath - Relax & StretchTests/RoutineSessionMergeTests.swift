import Testing
import Foundation
@testable import BreathRelaxStretch

/// Pure decision-logic tests — no ModelContext, no network. See
/// docs/superpowers/specs/2026-09-23-routine-session-sync-engine-design.md.
struct RoutineSessionMergeTests {

    private func makeRemoteRoutine(
        updatedAt: Date,
        deletedAt: Date? = nil
    ) -> RemoteRoutine {
        RemoteRoutine(
            id: UUID().uuidString, name: "Test", exerciseIDs: [], authorID: "u1",
            borrowedFromID: nil, exerciseDurationOverrides: [:],
            isPinnedToToday: false, pinnedOrder: 0,
            updatedAt: updatedAt, deletedAt: deletedAt
        )
    }

    // MARK: - decideRoutine

    @Test func noLocalRowInsertsTheRemoteOne() {
        let remote = makeRemoteRoutine(updatedAt: .now)
        #expect(RoutineSessionMerge.decideRoutine(local: nil, remote: remote) == .insertLocal)
    }

    @Test func newerRemoteUpdatesLocal() {
        let local = RoutineSessionMerge.LocalRoutineSnapshot(updatedAt: .now.addingTimeInterval(-100), deletedAt: nil)
        let remote = makeRemoteRoutine(updatedAt: .now)
        #expect(RoutineSessionMerge.decideRoutine(local: local, remote: remote) == .updateLocal)
    }

    @Test func newerLocalKeepsLocal() {
        let local = RoutineSessionMerge.LocalRoutineSnapshot(updatedAt: .now, deletedAt: nil)
        let remote = makeRemoteRoutine(updatedAt: .now.addingTimeInterval(-100))
        #expect(RoutineSessionMerge.decideRoutine(local: local, remote: remote) == .keepLocal)
    }

    @Test func exactTieKeepsLocalRatherThanChurning() {
        let now = Date.now
        let local = RoutineSessionMerge.LocalRoutineSnapshot(updatedAt: now, deletedAt: nil)
        let remote = makeRemoteRoutine(updatedAt: now)
        #expect(RoutineSessionMerge.decideRoutine(local: local, remote: remote) == .keepLocal)
    }

    @Test func newerRemoteDeleteWinsAndPropagatesAsAnUpdate() {
        // A remote tombstone is just "remote is newer" from this decision's
        // point of view — SyncEngine.apply(_:to:) is what actually copies
        // deletedAt onto the local row once .updateLocal comes back.
        let local = RoutineSessionMerge.LocalRoutineSnapshot(updatedAt: .now.addingTimeInterval(-100), deletedAt: nil)
        let remote = makeRemoteRoutine(updatedAt: .now, deletedAt: .now)
        #expect(RoutineSessionMerge.decideRoutine(local: local, remote: remote) == .updateLocal)
    }

    @Test func olderRemoteDeleteDoesNotResurrectAlreadyNewerLocalEdit() {
        let local = RoutineSessionMerge.LocalRoutineSnapshot(updatedAt: .now, deletedAt: nil)
        let remote = makeRemoteRoutine(updatedAt: .now.addingTimeInterval(-100), deletedAt: .now.addingTimeInterval(-100))
        #expect(RoutineSessionMerge.decideRoutine(local: local, remote: remote) == .keepLocal)
    }

    // MARK: - decideSession

    @Test func missingSessionInsertsIt() {
        #expect(RoutineSessionMerge.decideSession(existsLocally: false) == .insertLocal)
    }

    @Test func existingSessionIsLeftAlone() {
        #expect(RoutineSessionMerge.decideSession(existsLocally: true) == .alreadyPresent)
    }
}
