import Foundation

/// One exercise's translated content. `needsReview` is required (no default):
/// machine drafts start `true`, and only a human reviewer editing the overlay
/// file clears it.
struct ExerciseTranslation: Codable, Equatable {
    var name: String
    var instructions: [String]
    var caution: String?
    var callout: String?
    var needsReview: Bool
}

/// `Resources/Localized/exercises.<lang>.json`: translations keyed by the
/// exercise's lowercase UUID string (the seed `id`).
struct ExerciseOverlay: Codable {
    var language: String
    var exercises: [String: ExerciseTranslation]
}

/// Looks up translated exercise content. Exercise text is data, not UI copy, so it
/// lives outside the string catalog; anything missing falls back to the English
/// stored on the `Exercise` itself (user-created exercises always do).
enum ExerciseL10n {
    private final class Cache: @unchecked Sendable {
        private let lock = NSLock()
        private var overlays: [String: ExerciseOverlay?] = [:]

        func overlay(for language: AppLanguage) -> ExerciseOverlay? {
            lock.lock(); defer { lock.unlock() }
            if let cached = overlays[language.rawValue] { return cached }
            let loaded = Self.load(language)
            overlays[language.rawValue] = .some(loaded)
            return loaded
        }

        private static func load(_ language: AppLanguage) -> ExerciseOverlay? {
            let name = "exercises.\(language.rawValue)"
            let url = Bundle.main.url(forResource: name, withExtension: "json")
                ?? Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Localized")
            guard let url, let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(ExerciseOverlay.self, from: data)
        }
    }

    private static let cache = Cache()

    static func translation(for id: UUID, language: AppLanguage = .current()) -> ExerciseTranslation? {
        let resolved = language.resolved
        guard resolved != .en, let overlay = cache.overlay(for: resolved) else { return nil }
        return overlay.exercises[id.uuidString.lowercased()]
    }
}

extension Exercise {
    func localizedName(language: AppLanguage = .current()) -> String {
        ExerciseL10n.translation(for: uuid, language: language)?.name ?? name
    }

    /// Falls back to the English steps unless the translation has the same number
    /// of steps — the session player indexes into this array by step.
    func localizedInstructions(language: AppLanguage = .current()) -> [String] {
        guard let t = ExerciseL10n.translation(for: uuid, language: language),
              t.instructions.count == instructions.count else { return instructions }
        return t.instructions
    }

    func localizedCaution(language: AppLanguage = .current()) -> String? {
        guard let caution else { return nil }
        return ExerciseL10n.translation(for: uuid, language: language)?.caution ?? caution
    }

    func localizedCallout(language: AppLanguage = .current()) -> AnimationCallout? {
        guard var callout = animationCallout else { return nil }
        if let text = ExerciseL10n.translation(for: uuid, language: language)?.callout {
            callout.text = text
        }
        return callout
    }
}
