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

    // MARK: - Final-review fixes

    @Test func userIDProviderIsReReadAfterTheSessionWait() async {
        let store = FakeProfileStore()   // missing row -> local name backfills
        let coordinator = makeCoordinator(store)
        var currentID = "anon-id"
        var polls = 0

        let outcome = await coordinator.resolve(
            userID: "anon-id", local: ada, providerPrefill: .empty,
            hasBackendSession: {
                polls += 1
                if polls > 3 { currentID = "real-uid"; return true }
                return false
            },
            userIDProvider: { currentID })

        #expect(store.fetchedIDs == ["real-uid"])
        #expect(outcome == .registered(name: ada, backfillRemote: true))
        #expect(store.upserts.first?.id == "real-uid")
    }

    @Test func withoutAUserIDProviderThePassedIDIsUsed() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)

        await coordinator.resolve(userID: "u1", local: ada, providerPrefill: .empty, hasBackendSession: { true })

        #expect(store.fetchedIDs == ["u1"])
        #expect(store.upserts.first?.id == "u1")
    }

    @Test func aCancelledResolveDoesNotLeaveTheCoordinatorChecking() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store, timeout: .seconds(30))

        let task = Task { @MainActor in
            await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: { false })
        }
        try? await Task.sleep(for: .milliseconds(80))
        #expect(coordinator.state == .checking)
        task.cancel()
        let outcome = await task.value

        #expect(outcome == nil)
        #expect(coordinator.state == .idle)
    }

    @Test func aSessionThatNeverAppearsGivesUpAfterTheSessionWaitNotTheFullTimeout() async {
        let store = FakeProfileStore()
        let coordinator = RegistrationCoordinator(store: store, lookupTimeout: .seconds(5),
                                                  sessionPollInterval: .milliseconds(10),
                                                  sessionWaitTimeout: .milliseconds(150))
        let clock = ContinuousClock()
        let start = clock.now

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: grace, hasBackendSession: { false })

        let elapsed = start.duration(to: clock.now)
        #expect(outcome == .needsName(prefill: grace))
        // the wait must end at the ~150ms session-wait cap, not run to the 5s overall timeout; 2.5s is far from both and tolerates a loaded machine
        #expect(elapsed < .milliseconds(2500))
        #expect(store.fetchCount == 0)
    }

    @Test func sessionWaitPlusFetchShareOneOverallDeadline() async {
        let store = FakeProfileStore()
        store.fetchDelay = .seconds(5)
        let coordinator = RegistrationCoordinator(store: store, lookupTimeout: .milliseconds(300),
                                                  sessionPollInterval: .milliseconds(10),
                                                  sessionWaitTimeout: .milliseconds(150))
        let clock = ContinuousClock()
        let start = clock.now
        var session = false
        Task { try? await Task.sleep(for: .milliseconds(100)); session = true }

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: grace,
                                                hasBackendSession: { session })

        let elapsed = start.duration(to: clock.now)
        // the remaining budget (~200ms) is floored to 1s so ~1.1s total; a fresh full fetch timeout or the 5s fetch delay would blow past 3s; 3s tolerates load
        #expect(elapsed < .seconds(3))
        #expect(outcome == .needsName(prefill: grace))
    }
}

final class FakeProfileStore: SupabaseProfileStoring, @unchecked Sendable {
    var fetchResult: Result<RemoteProfile?, Error> = .success(nil)
    var fetchDelay: Duration = .zero
    var upsertShouldFail = false
    private(set) var fetchCount = 0
    private(set) var fetchedIDs: [String] = []
    private(set) var upserts: [(id: String, name: PersonName)] = []

    func fetchProfile(id: String) async throws -> RemoteProfile? {
        fetchCount += 1
        fetchedIDs.append(id)
        try await Task.sleep(for: fetchDelay)
        return try fetchResult.get()
    }

    func upsertProfileName(id: String, name: PersonName) async throws {
        upserts.append((id, name))
        if upsertShouldFail { throw URLError(.notConnectedToInternet) }
    }
}
