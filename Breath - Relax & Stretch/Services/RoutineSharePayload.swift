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

    // Anyone can construct a breath:// URL, so decoded values are untrusted
    // input — cap sizes so a crafted link can't inject absurd content.
    private static let maxEncodedLength = 16_384
    private static let maxNameLength    = 80
    private static let maxExercises     = 50

    static func decode(from urlSafeBase64: String) -> RoutineSharePayload? {
        guard urlSafeBase64.count <= maxEncodedLength else { return nil }
        var base64 = urlSafeBase64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONDecoder().decode(RoutineSharePayload.self, from: data),
              !payload.name.isEmpty,
              payload.name.count <= maxNameLength,
              payload.exerciseNames.count <= maxExercises,
              payload.exerciseNames.allSatisfy({ !$0.isEmpty && $0.count <= maxNameLength })
        else { return nil }
        return payload
    }
}
