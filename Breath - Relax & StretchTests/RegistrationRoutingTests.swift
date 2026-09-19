import Testing
@testable import BreathRelaxStretch

@MainActor
struct RegistrationRoutingTests {
    private let ada = PersonName(first: "Ada", last: "Lovelace")
    private let grace = PersonName(first: "Grace", last: "Hopper")

    @Test func namedRemoteRowMeansRegisteredWithTheRemoteName() {
        let outcome = RegistrationRouting.resolve(lookup: .named(ada), local: .empty, providerPrefill: grace)
        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func remoteNameWinsOverADifferentLocalName() {
        let outcome = RegistrationRouting.resolve(lookup: .named(ada), local: grace, providerPrefill: .empty)
        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func noRemoteRowButCompleteLocalNameIsRegisteredAndBackfills() {
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: .empty), local: ada, providerPrefill: .empty)
        #expect(outcome == .registered(name: ada, backfillRemote: true))
    }

    @Test func noRemoteRowAndNoLocalNameNeedsNamePrefilledFromTheRow() {
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: grace), local: .empty, providerPrefill: ada)
        #expect(outcome == .needsName(prefill: grace))
    }

    @Test func noRemoteRowAndNoLocalNameFallsBackToTheProviderPrefill() {
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: .empty), local: .empty, providerPrefill: ada)
        #expect(outcome == .needsName(prefill: ada))
    }

    @Test func incompleteLocalNameDoesNotCountAsRegistered() {
        let partial = PersonName(first: "Ada", last: "")
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: .empty), local: partial, providerPrefill: .empty)
        #expect(outcome == .needsName(prefill: .empty))
    }

    @Test func unavailableLookupWithLocalNameIsRegisteredWithoutBackfill() {
        let outcome = RegistrationRouting.resolve(lookup: .unavailable, local: ada, providerPrefill: .empty)
        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func unavailableLookupWithoutLocalNameNeedsNameWithProviderPrefill() {
        let outcome = RegistrationRouting.resolve(lookup: .unavailable, local: .empty, providerPrefill: grace)
        #expect(outcome == .needsName(prefill: grace))
    }
}
