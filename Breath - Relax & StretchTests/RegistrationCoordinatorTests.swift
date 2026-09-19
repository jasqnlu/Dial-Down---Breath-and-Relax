import Testing
import Foundation
@testable import BreathRelaxStretch

@MainActor
struct RegistrationCoordinatorTests {
    private let ada = PersonName(first: "Ada", last: "Lovelace")
    private let grace = PersonName(first: "Grace", last: "Hopper")

    private func row(first: String?, last: String?, display: String) -> RemoteProfile {
        RemoteProfile(id: "u1", displayName: display, totalPoints: 0, streak: 0, totalMinutes: 0,
                      lastSessionAt: nil, firstName: first, lastName: last)
    }

    private func makeCoordinator(_ store: FakeProfileStore,
                                 timeout: Duration = .seconds(2)) -> RegistrationCoordinator {
        RegistrationCoordinator(store: store, lookupTimeout: timeout, sessionPollInterval: .milliseconds(10))
    }

    @Test func namedRowIsRegistered() async {
        let store = FakeProfileStore()
        store.fetchResult = .success(row(first: "Ada", last: "Lovelace", display: "Ada Lovelace"))
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: { true })

        #expect(outcome == .registered(name: ada, backfillRemote: false))
        #expect(coordinator.state == .registered)
        #expect(store.upserts.isEmpty)
    }

    @Test func missingRowWithNoLocalNameNeedsNameWithProviderPrefill() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })

        #expect(outcome == .needsName(prefill: ada))
        #expect(coordinator.state == .needsName(prefill: ada))
    }

    @Test func legacyRowWithOnlyADisplayNamePrefillsFromIt() async {
        let store = FakeProfileStore()
        store.fetchResult = .success(row(first: nil, last: nil, display: "Grace Hopper"))
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })

        #expect(outcome == .needsName(prefill: grace))
    }

    @Test func fetchFailureWithACompleteLocalNameIsRegistered() async {
        let store = FakeProfileStore()
        store.fetchResult = .failure(URLError(.notConnectedToInternet))
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: ada, providerPrefill: .empty, hasBackendSession: { true })

        #expect(outcome == .registered(name: ada, backfillRemote: false))
        #expect(store.upserts.isEmpty)
    }

    @Test func slowLookupTimesOutAsUnavailable() async {
        let store = FakeProfileStore()
        store.fetchDelay = .seconds(5)
        let coordinator = makeCoordinator(store, timeout: .milliseconds(50))

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: grace, hasBackendSession: { true })

        #expect(outcome == .needsName(prefill: grace))
    }

    @Test func missingRowWithACompleteLocalNameBackfillsTheRemoteRow() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: ada, providerPrefill: .empty, hasBackendSession: { true })

        #expect(outcome == .registered(name: ada, backfillRemote: true))
        #expect(store.upserts.count == 1)
        #expect(store.upserts.first?.id == "u1")
        #expect(store.upserts.first?.name == ada)
    }

    @Test func withoutABackendSessionItWaitsThenTreatsTheLookupAsUnavailable() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store, timeout: .milliseconds(60))

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: grace, hasBackendSession: { false })

        #expect(outcome == .needsName(prefill: grace))
        #expect(store.fetchCount == 0)   // never queried with an unauthenticated (anonymous) id
    }

    @Test func aBackendSessionThatAppearsLateIsWaitedFor() async {
        let store = FakeProfileStore()
        store.fetchResult = .success(row(first: "Ada", last: "Lovelace", display: "Ada Lovelace"))
        let coordinator = makeCoordinator(store, timeout: .seconds(2))
        var polls = 0

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: {
            polls += 1
            return polls > 3
        })

        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func aSecondResolveWhileTheNameStepIsShownIsIgnored() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)
        await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })
        #expect(coordinator.state == .needsName(prefill: ada))

        store.fetchResult = .success(row(first: "Ada", last: "Lovelace", display: "Ada Lovelace"))
        let again = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })

        #expect(again == nil)
        #expect(coordinator.state == .needsName(prefill: ada))   // never clobbers what the user is typing
    }

    @Test func completeNameUploadsAndRegisters() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)
        await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: { true })

        let uploaded = await coordinator.completeName(ada, userID: "u1")

        #expect(uploaded)
        #expect(coordinator.state == .registered)
        #expect(store.upserts.first?.name == ada)
    }

    @Test func completeNameStillRegistersWhenTheUploadFails() async {
        let store = FakeProfileStore()
        store.upsertShouldFail = true
        let coordinator = makeCoordinator(store)

        let uploaded = await coordinator.completeName(ada, userID: "u1")

        #expect(!uploaded)
        #expect(coordinator.state == .registered)   // offline-first: the local name is kept, backfilled later
    }
}

final class FakeProfileStore: SupabaseProfileStoring, @unchecked Sendable {
    var fetchResult: Result<RemoteProfile?, Error> = .success(nil)
    var fetchDelay: Duration = .zero
    var upsertShouldFail = false
    private(set) var fetchCount = 0
    private(set) var upserts: [(id: String, name: PersonName)] = []

    func fetchProfile(id: String) async throws -> RemoteProfile? {
        fetchCount += 1
        try await Task.sleep(for: fetchDelay)
        return try fetchResult.get()
    }

    func upsertProfileName(id: String, name: PersonName) async throws {
        upserts.append((id, name))
        if upsertShouldFail { throw URLError(.notConnectedToInternet) }
    }
}
