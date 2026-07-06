import Foundation

// MARK: - SupabaseSession
// The result of a Supabase Auth token grant (id_token exchange or refresh).
// Persisted as JSON in the keychain by SupabaseService so a Sign in with
// Apple session survives relaunches; access tokens expire after ~1 h, so
// `needsRefresh` drives the proactive refresh in currentAccessToken().

// `nonisolated`: the project defaults new types to @MainActor isolation, but
// this value type is used from inside the SupabaseService actor.
nonisolated struct SupabaseSession: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let userID: String
    let expiresAt: Date

    /// True within two minutes of expiry, so a request never leaves the
    /// device with a token that could die while it's in flight.
    func needsRefresh(at now: Date = Date()) -> Bool {
        now >= expiresAt.addingTimeInterval(-120)
    }
}
