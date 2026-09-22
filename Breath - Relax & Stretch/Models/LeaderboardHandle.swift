import Foundation

// MARK: - LeaderboardHandle
// The leaderboard is opt-in and pseudonymous: other users only ever see a
// generated handle like "Calm Otter 4821", never a real name. Handles are
// generated (not typed) on purpose — a free-text field invites people to type
// their real name and would need moderation.

enum LeaderboardHandle {
    static let adjectives = [
        "Calm", "Gentle", "Quiet", "Steady", "Serene", "Mellow", "Bright", "Easy",
        "Soft", "Still", "Warm", "Breezy", "Lucid", "Balanced", "Peaceful", "Supple",
    ]
    static let animals = [
        "Otter", "Heron", "Panda", "Fox", "Koala", "Crane", "Lynx", "Finch",
        "Seal", "Fawn", "Wren", "Tortoise", "Swan", "Hare", "Owl", "Dolphin",
    ]
    static let lengthRange = 2...32

    static func generate<G: RandomNumberGenerator>(using generator: inout G) -> String {
        let adjective = adjectives.randomElement(using: &generator) ?? "Calm"
        let animal = animals.randomElement(using: &generator) ?? "Otter"
        let number = Int.random(in: 1000...9999, using: &generator)
        return "\(adjective) \(animal) \(number)"
    }

    static func generate() -> String {
        var generator = SystemRandomNumberGenerator()
        return generate(using: &generator)
    }

    /// Matches the `leaderboard.handle` check constraint.
    static func isValid(_ handle: String) -> Bool {
        lengthRange.contains(handle.count)
    }
}

// MARK: - LeaderboardPreference
// Device-local cache of the opt-in so uploads can be gated without a network
// round trip. The server row is the source of truth — the leaderboard screen
// re-syncs this from the caller's own row on every load, which is also how a
// new device or a fresh sign-in restores the choice. Cleared on sign-out so
// the next account on this device never inherits it.

enum LeaderboardPreference {
    static let key = "leaderboardHandle"

    static var handle: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set {
            if let newValue, LeaderboardHandle.isValid(newValue) {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    static var isOptedIn: Bool { handle != nil }

    static func clear() { handle = nil }
}
