import Foundation

// MARK: - ChallengePayload
// Encodes a streak/points snapshot as a `breath://challenge?data=...` deep
// link so a user can invite a friend to match their stats. Like
// RoutineSharePayload, this is a share-based invite, not a tracked two-way
// challenge — no backend round trip needed to send one.

struct ChallengePayload: Codable {
    let fromName: String
    let streak: Int
    let totalPoints: Int

    var shareURL: URL? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        let base64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        var components = URLComponents()
        components.scheme = "breath"
        components.host = "challenge"
        components.queryItems = [URLQueryItem(name: "data", value: base64)]
        return components.url
    }

    static func decode(from urlSafeBase64: String) -> ChallengePayload? {
        var base64 = urlSafeBase64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(ChallengePayload.self, from: data)
    }
}
