import Testing
import Foundation
@testable import BreathRelaxStretch

/// Exercise names, instructions, cautions and callouts are content, not UI
/// strings, so they live in per-language overlay files keyed by exercise id
/// (`Resources/Localized/exercises.<lang>.json`) with English as the fallback.
struct ExerciseL10nTests {
    // MARK: Seed fixture

    struct SeedExercise {
        let id: String
        let name: String
        let instructions: [String]
        let caution: String?
        let callout: String?
    }

    static let seed: [SeedExercise] = {
        guard let url = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = root["exercises"] as? [[String: Any]] else { return [] }
        return rows.map {
            SeedExercise(id: ($0["id"] as? String ?? "").lowercased(),
                         name: $0["name"] as? String ?? "",
                         instructions: $0["instructions"] as? [String] ?? [],
                         caution: $0["caution"] as? String,
                         callout: ($0["animationCallout"] as? [String: Any])?["text"] as? String)
        }
    }()

    static let shipped: [AppLanguage] = [.es, .fr, .zhHans]

    /// ASCII digit runs only: Swift's `isNumber` is also true for 一/二/两…, which
    /// would flag a perfectly good "twice as long" → "两倍".
    private static func digits(_ text: String) -> [String] {
        text.split(whereSeparator: { !($0.isASCII && $0.isNumber) }).map(String.init)
    }

    // MARK: Schema + fallback

    @Test func overlayJSONDecodes() throws {
        let json = """
        {"language":"es","exercises":{"abc":{"name":"Puente","instructions":["Sube."],"caution":"Cuidado.","callout":"Empuja","needsReview":true}}}
        """
        let overlay = try JSONDecoder().decode(ExerciseOverlay.self, from: Data(json.utf8))
        #expect(overlay.language == "es")
        #expect(overlay.exercises["abc"]?.name == "Puente")
        #expect(overlay.exercises["abc"]?.needsReview == true)
    }

    @Test func seedFixtureLoaded() {
        #expect(Self.seed.count > 300)
    }

    @Test func englishNeedsNoOverlay() {
        let id = UUID(uuidString: Self.seed[0].id)!
        #expect(ExerciseL10n.translation(for: id, language: .en) == nil)
    }

    /// "System Default" on a Spanish device must give Spanish exercises too,
    /// not just Spanish chrome.
    @Test func systemDefaultFollowsThePreferredLocalization() {
        let id = UUID(uuidString: Self.seed[0].id)!
        let resolved = AppLanguage.system.resolved
        #expect(resolved != .system)
        #expect(ExerciseL10n.translation(for: id, language: .system)
                == ExerciseL10n.translation(for: id, language: resolved))
    }

    @Test func exerciseWithoutATranslationKeepsItsOwnText() {
        let exercise = Exercise(name: "My Custom Stretch", type: .stretch, targetBodyParts: [],
                                durationSeconds: 30, difficulty: 1,
                                instructions: ["Do it."], caution: "Careful.")
        #expect(exercise.localizedName(language: .es) == "My Custom Stretch")
        #expect(exercise.localizedInstructions(language: .es) == ["Do it."])
        #expect(exercise.localizedCaution(language: .es) == "Careful.")
    }

    // MARK: Coverage of the shipped seed (arguments = each shipped language)

    @Test(arguments: shipped)
    func coversEverySeedExercise(language: AppLanguage) {
        let missing = Self.seed.filter {
            guard let id = UUID(uuidString: $0.id) else { return true }
            return ExerciseL10n.translation(for: id, language: language) == nil
        }.map(\.name)
        #expect(missing.isEmpty, "\(language.rawValue) missing \(missing.count): \(missing.prefix(5))")
    }

    @Test(arguments: shipped)
    func instructionCountsMatchTheEnglish(language: AppLanguage) {
        let bad = Self.seed.filter {
            guard let id = UUID(uuidString: $0.id),
                  let t = ExerciseL10n.translation(for: id, language: language) else { return false }
            return t.instructions.count != $0.instructions.count || t.instructions.contains { $0.isEmpty }
        }.map(\.name)
        #expect(bad.isEmpty, "\(language.rawValue): \(bad.prefix(5))")
    }

    /// A translation must never silently change a duration, count or repetition.
    @Test(arguments: shipped)
    func numbersArePreserved(language: AppLanguage) {
        var bad: [String] = []
        for exercise in Self.seed {
            guard let id = UUID(uuidString: exercise.id),
                  let t = ExerciseL10n.translation(for: id, language: language) else { continue }
            for (english, translated) in zip(exercise.instructions, t.instructions)
            where Self.digits(english) != Self.digits(translated) {
                bad.append("\(exercise.name): \(english)")
            }
            if let c = exercise.caution, let tc = t.caution, Self.digits(c) != Self.digits(tc) {
                bad.append("\(exercise.name) caution")
            }
        }
        #expect(bad.isEmpty, "\(language.rawValue): \(bad.prefix(5))")
    }

    @Test(arguments: shipped)
    func cautionsAndCalloutsExistExactlyWhereTheEnglishHasThem(language: AppLanguage) {
        let bad = Self.seed.filter {
            guard let id = UUID(uuidString: $0.id),
                  let t = ExerciseL10n.translation(for: id, language: language) else { return false }
            let cautionOK = ($0.caution == nil) == (t.caution == nil) && (t.caution?.isEmpty != true)
            let calloutOK = ($0.callout == nil) == (t.callout == nil) && (t.callout?.isEmpty != true)
            return !(cautionOK && calloutOK)
        }.map(\.name)
        #expect(bad.isEmpty, "\(language.rawValue): \(bad.prefix(5))")
    }
}
