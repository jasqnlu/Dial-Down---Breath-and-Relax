import Testing
import Foundation
import SwiftData
@testable import BreathRelaxStretch

@MainActor
struct SyncOutboxTests {

    private func makeContext() -> ModelContext {
        let container = try! ModelContainer(
            for: PendingSyncOp.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func allOps(_ context: ModelContext) -> [PendingSyncOp] {
        (try? context.fetch(FetchDescriptor<PendingSyncOp>())) ?? []
    }

    @Test func enqueueInsertsANewOp() {
        let context = makeContext()
        let outbox = SyncOutbox()
        let id = UUID()

        outbox.enqueue(.routine, id: id, op: .upsert, in: context)

        let ops = allOps(context)
        #expect(ops.count == 1)
        #expect(ops.first?.entityID == id)
        #expect(ops.first?.entityType == .routine)
        #expect(ops.first?.opType == .upsert)
    }

    @Test func enqueueTwiceForTheSameEntityCollapsesToOneOp() {
        let context = makeContext()
        let outbox = SyncOutbox()
        let id = UUID()

        outbox.enqueue(.routine, id: id, op: .upsert, in: context)
        outbox.enqueue(.routine, id: id, op: .upsert, in: context)

        #expect(allOps(context).count == 1)
    }

    @Test func enqueueingADeleteAfterAnUpsertOverwritesTheOpType() {
        let context = makeContext()
        let outbox = SyncOutbox()
        let id = UUID()

        outbox.enqueue(.routine, id: id, op: .upsert, in: context)
        outbox.enqueue(.routine, id: id, op: .delete, in: context)

        let ops = allOps(context)
        #expect(ops.count == 1)
        #expect(ops.first?.opType == .delete)
    }

    @Test func sameEntityIDDifferentEntityTypesAreSeparateOps() {
        // A Routine and a Session could theoretically share an entityID by
        // coincidence (both are just UUIDs) — entityType must be part of
        // identity, not just entityID.
        let context = makeContext()
        let outbox = SyncOutbox()
        let id = UUID()

        outbox.enqueue(.routine, id: id, op: .upsert, in: context)
        outbox.enqueue(.session, id: id, op: .upsert, in: context)

        #expect(allOps(context).count == 2)
    }

    @Test func retryingAFailedOpResetsItsAttemptCount() {
        let context = makeContext()
        let outbox = SyncOutbox()
        let id = UUID()

        outbox.enqueue(.routine, id: id, op: .upsert, in: context)
        let op = allOps(context)[0]
        outbox.recordFailure(op, error: URLError(.notConnectedToInternet), in: context)
        outbox.recordFailure(op, error: URLError(.notConnectedToInternet), in: context)
        #expect(op.attemptCount == 2)

        outbox.enqueue(.routine, id: id, op: .upsert, in: context)
        #expect(allOps(context)[0].attemptCount == 0)
    }

    @Test func clearRemovesTheOp() {
        let context = makeContext()
        let outbox = SyncOutbox()
        outbox.enqueue(.routine, id: UUID(), op: .upsert, in: context)
        let op = allOps(context)[0]

        outbox.clear(op, in: context)

        #expect(allOps(context).isEmpty)
    }

    @Test func recordFailureIncrementsAttemptCountAndStoresTheError() {
        let context = makeContext()
        let outbox = SyncOutbox()
        outbox.enqueue(.routine, id: UUID(), op: .upsert, in: context)
        let op = allOps(context)[0]

        outbox.recordFailure(op, error: URLError(.timedOut), in: context)

        #expect(op.attemptCount == 1)
        #expect(op.lastAttemptAt != nil)
        #expect(op.lastError != nil)
    }
}
