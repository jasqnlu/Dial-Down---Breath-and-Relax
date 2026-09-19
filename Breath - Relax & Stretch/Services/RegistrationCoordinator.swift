import Foundation
import Combine

/// Decides whether the signed-in (non-guest) account still needs the name
/// step, by looking for a named `profiles` row. Owns no UI — RegistrationGate
/// renders `state`.
@MainActor
final class RegistrationCoordinator: ObservableObject {

    enum State: Equatable {
        case idle
        case checking
        case needsName(prefill: PersonName)
        case registered
    }

    @Published private(set) var state: State = .idle

    private let store: SupabaseProfileStoring
    private let lookupTimeout: Duration
    private let sessionPollInterval: Duration

    init(
        store: SupabaseProfileStoring = SupabaseService.shared,
        lookupTimeout: Duration = .seconds(6),
        sessionPollInterval: Duration = .milliseconds(200)
    ) {
        self.store = store
        self.lookupTimeout = lookupTimeout
        self.sessionPollInterval = sessionPollInterval
    }

    /// Returns nil when cancelled, or when the name step is already showing
    /// (a late re-resolve, e.g. the Apple → Supabase exchange finishing after
    /// the timeout, must not clobber what the user is typing).
    @discardableResult
    func resolve(
        userID: String,
        local: PersonName,
        providerPrefill: PersonName,
        hasBackendSession: () -> Bool
    ) async -> RegistrationOutcome? {
        if case .needsName = state { return nil }
        // Keep showing Home if we already resolved as registered; only a
        // first/unknown resolve shows the spinner.
        if state != .registered { state = .checking }

        let lookup = await lookup(userID: userID, hasBackendSession: hasBackendSession)
        guard !Task.isCancelled else { return nil }

        let outcome = RegistrationRouting.resolve(lookup: lookup, local: local, providerPrefill: providerPrefill)
        switch outcome {
        case .registered(let name, let backfill):
            state = .registered
            if backfill { try? await store.upsertProfileName(id: userID, name: name) }
        case .needsName(let prefill):
            state = .needsName(prefill: prefill)
        }
        return outcome
    }

    /// Called by the name step. The state flips first so the user is never
    /// blocked on the network; the upload is best-effort and, if it fails,
    /// `resolve` backfills it on a later launch from the locally stored name.
    @discardableResult
    func completeName(_ name: PersonName, userID: String) async -> Bool {
        state = .registered
        do {
            try await store.upsertProfileName(id: userID, name: name)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Lookup

    /// The profile can only be addressed by the Supabase uid, which for Sign in
    /// with Apple arrives asynchronously after `isSignedIn` flips — until then
    /// `backendID` is the anonymous UUID and a lookup would falsely say "no
    /// row". So wait (bounded) for a session before querying.
    private func lookup(userID: String, hasBackendSession: () -> Bool) async -> RemoteProfileLookup {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: lookupTimeout)
        while !hasBackendSession() {
            if Task.isCancelled || clock.now >= deadline { return .unavailable }
            try? await Task.sleep(for: sessionPollInterval)
        }

        let store = self.store
        let timeout = lookupTimeout
        let result: Result<RemoteProfile?, any Error> = await withTaskGroup(
            of: Result<RemoteProfile?, any Error>.self
        ) { group in
            group.addTask {
                do { return .success(try await store.fetchProfile(id: userID)) }
                catch { return .failure(error) }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return .failure(URLError(.timedOut))
            }
            let first = await group.next() ?? .failure(URLError(.timedOut))
            group.cancelAll()
            return first
        }

        switch result {
        case .failure:
            return .unavailable
        case .success(let row):
            guard let row else { return .notRegistered(rowPrefill: .empty) }
            let name = PersonName(first: row.firstName ?? "", last: row.lastName ?? "")
            if name.isComplete { return .named(name) }
            return .notRegistered(rowPrefill: PersonName.split(fullName: row.displayName))
        }
    }
}
