import Foundation

/// What the `profiles` lookup for the signed-in account found.
nonisolated enum RemoteProfileLookup: Equatable, Sendable {
    /// A row exists with a complete first + last name.
    case named(PersonName)
    /// No row, or a row without a complete name. `rowPrefill` is the row's
    /// `display_name` split into parts (empty when there was no row).
    case notRegistered(rowPrefill: PersonName)
    /// Offline, timed out, or the backend errored — the answer is unknown.
    case unavailable
}

nonisolated enum RegistrationOutcome: Equatable, Sendable {
    /// Skip the name step. `backfillRemote` means the row is confirmed missing
    /// but a complete local name exists, so upload it best-effort.
    case registered(name: PersonName, backfillRemote: Bool)
    case needsName(prefill: PersonName)
}

nonisolated enum RegistrationRouting {
    static func resolve(
        lookup: RemoteProfileLookup,
        local: PersonName,
        providerPrefill: PersonName
    ) -> RegistrationOutcome {
        switch lookup {
        case .named(let remote):
            return .registered(name: remote, backfillRemote: false)
        case .notRegistered(let rowPrefill):
            if local.isComplete { return .registered(name: local, backfillRemote: true) }
            return .needsName(prefill: rowPrefill == .empty ? providerPrefill : rowPrefill)
        case .unavailable:
            // Unknown remote state: trust a complete local name so a flaky
            // connection never forces re-onboarding, but never overwrite the
            // remote row from here.
            if local.isComplete { return .registered(name: local, backfillRemote: false) }
            return .needsName(prefill: providerPrefill)
        }
    }
}
