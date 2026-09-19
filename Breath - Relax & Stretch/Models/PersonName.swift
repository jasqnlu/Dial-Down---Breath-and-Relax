import Foundation

/// A person's first + last name as collected by the name step. Parts are
/// trimmed and clamped so they always fit the `profiles` column limits
/// (display_name <= 80, so 35 + 1 + 35 = 71).
nonisolated struct PersonName: Equatable, Sendable {
    static let maxComponentLength = 35
    static let empty = PersonName(first: "", last: "")

    /// Provider-supplied stand-ins that must never prefill the name step.
    private static let placeholders: Set<String> = ["", "user", "guest", "apple user"]

    let first: String
    let last: String

    init(first: String, last: String) {
        self.first = Self.clean(first)
        self.last = Self.clean(last)
    }

    var isComplete: Bool { !first.isEmpty && !last.isEmpty }

    var fullName: String {
        [first, last].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Best-effort split of a single display string: first word is the first
    /// name, the remainder is the last name. Placeholder names give `.empty`.
    static func split(fullName: String) -> PersonName {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !placeholders.contains(trimmed.lowercased()) else { return .empty }
        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let head = parts.first else { return .empty }
        return PersonName(first: String(head), last: parts.count > 1 ? String(parts[1]) : "")
    }

    private static func clean(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxComponentLength))
    }
}
