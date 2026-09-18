import Testing
import Foundation
@testable import BreathRelaxStretch

// Regression coverage for the "looks configured, isn't" bug class: the
// dashboard URL (supabase.com/dashboard/project/...) is a real, non-placeholder
// URL, so a check that only looked for the literal "YOUR_PROJECT" placeholder
// string incorrectly reported isConfigured == true and let the app attempt
// real network calls against a host that returns HTML/404, not JSON.
struct SupabaseServiceTests {

    @Test func rejectsTheDashboardURLSpecifically() {
        #expect(!SupabaseService.isValidAPIHost("https://supabase.com/dashboard/project/wmsutfittuxrvcwuywrk"))
    }

    @Test func acceptsARealProjectAPIHost() {
        #expect(SupabaseService.isValidAPIHost("https://wmsutfittuxrvcwuywrk.supabase.co"))
    }

    @Test func rejectsMalformedOrHostlessURLs() {
        #expect(!SupabaseService.isValidAPIHost("not a url"))
        #expect(!SupabaseService.isValidAPIHost(""))
    }

    @Test func rejectsLookalikeHostsThatArentActuallySupabaseCo() {
        // A host merely containing "supabase.co" isn't enough — must be a real subdomain of it.
        #expect(!SupabaseService.isValidAPIHost("https://supabase.co.evil.com"))
        #expect(!SupabaseService.isValidAPIHost("https://notsupabase.co"))
    }

    @Test func currentlyConfiguredCredentialsPassTheRealCheck() {
        // Guards against this regressing back to a non-API host in the future.
        #expect(SupabaseService.isConfigured)
    }

    @Test func signInWithGoogleReturnsTheUserIDFromASuccessfulGrant() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 200, body: Self.tokenGrantJSON(userID: "google-uid-1"))
        ])
        let service = SupabaseService(
            keychain: FakeSupabaseKeychainStore(),
            urlSession: session
        )
        let uid = try await service.signInWithGoogle(idToken: "fake-id-token", nonce: "fake-nonce")
        #expect(uid == "google-uid-1")
    }

    @Test func signInWithGoogleThrowsOnAnHTTPErrorStatus() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 400, body: Data("{}".utf8))
        ])
        let service = SupabaseService(
            keychain: FakeSupabaseKeychainStore(),
            urlSession: session
        )
        await #expect(throws: (any Error).self) {
            _ = try await service.signInWithGoogle(idToken: "fake-id-token", nonce: "fake-nonce")
        }
    }

    private static func tokenGrantJSON(userID: String) -> Data {
        Data("""
        {
          "access_token": "fake-access-token",
          "refresh_token": "fake-refresh-token",
          "expires_in": 3600,
          "user": { "id": "\(userID)" }
        }
        """.utf8)
    }
}

// MARK: - Test doubles

private final class FakeSupabaseKeychainStore: KeychainStore {
    var storage: [String: String] = [:]
    func save(account: String, value: String) { storage[account] = value }
    func delete(account: String) { storage.removeValue(forKey: account) }
    func loadCredential(account: String) -> String? { storage[account] }
}

/// Replays canned `(status, body)` pairs in call order, one per `data(for:)`
/// invocation — enough for these single-request auth flows without needing a
/// real request-matching mock.
private final class FakeHTTPSession: SupabaseHTTPSession, @unchecked Sendable {
    enum Canned {
        case success(status: Int, body: Data)
    }
    private var responses: [Canned]
    private let lock = NSLock()

    init(responses: [Canned]) { self.responses = responses }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        guard !responses.isEmpty else {
            lock.unlock()
            throw URLError(.unknown)
        }
        let next = responses.removeFirst()
        lock.unlock()
        switch next {
        case .success(let status, let body):
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status,
                httpVersion: nil, headerFields: nil
            )!
            return (body, response)
        }
    }
}
