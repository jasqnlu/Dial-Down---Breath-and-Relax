import Foundation

// MARK: - RoutineSharePayload
// Encodes a routine as a `breath://routine?data=...` deep link so it can be
// sent via Messages/Mail/AirDrop without needing a backend. Exercises are
// matched by name (not UUID) on import, since seed-exercise UUIDs aren't
// guaranteed to match across two installs unless Supabase is configured.

struct RoutineSharePayload: Codable {
    let name: String
    let exerciseNames: [String]

    var shareURL: URL? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        let base64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        var components = URLComponents()
        components.scheme = "breath"
        components.host = "routine"
        components.queryItems = [URLQueryItem(name: "data", value: base64)]
        return components.url
    }

    static func decode(from urlSafeBase64: String) -> RoutineSharePayload? {
        var base64 = urlSafeBase64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(RoutineSharePayload.self, from: data)
    }
}
