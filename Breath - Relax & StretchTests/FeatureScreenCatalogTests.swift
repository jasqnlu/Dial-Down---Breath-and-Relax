import Testing
import Foundation
@testable import BreathRelaxStretch

/// Every string the feature screens resolve through a plain-`String` path must
/// have a real translation in each shipped language — a missing or misspelled
/// catalog key silently falls back to English, so assert it explicitly.
struct FeatureScreenCatalogTests {
    static let keys = [
        "Inhale...",
        "Hold...",
        "Exhale...",
        "Rounds completed",
        "Points earned",
        "Pattern",
        "Create New Routine",
        "Name it and save these as a routine",
        "Add to Existing Routine",
        "Append these to one you already have",
        "Start Mini-Routine",
        "Play these now — nothing is saved",
        "All",
        "Easier",
        "Email",
        "Password",
        "Confirm Password",
        "Google (soon)",
        "Weak",
        "Fair",
        "Good",
        "Strong",
        "Passwords do not match.",
        "steady",
        "No change since first check-in",
        "Exercise Session",
        "Switch sides",
        "Stretch",
        "Both",
        "Pectoralis Minor",
        "Pectoralis Major",
        "General Chest",
        "Beginner",
        "Intermediate",
        "Advanced",
        "Head",
        "Upper Back",
        "Lower Back",
        "Hips",
        "Glutes",
        "Shoulder",
        "Left Shoulder",
        "Right Shoulder",
        "Arm",
        "Left Arm",
        "Right Arm",
        "Elbow",
        "Left Elbow",
        "Right Elbow",
        "Forearm",
        "Left Forearm",
        "Right Forearm",
        "Hand",
        "Left Hand",
        "Right Hand",
        "Leg",
        "Left Leg",
        "Right Leg",
        "Hamstring",
        "Left Hamstring",
        "Right Hamstring",
        "Knee",
        "Left Knee",
        "Right Knee",
        "Calf",
        "Left Calf",
        "Right Calf",
        "Shin",
        "Left Shin",
        "Right Shin",
        "Ankle",
        "Left Ankle",
        "Right Ankle",
        "Foot",
        "Left Foot",
        "Right Foot",
        "Related to %@",
        "More from this area",
        "No exercises target this exact spot yet — here are related ones for the same area.",
        "Other exercises that work the same area.",
        "No exercises target %@ directly yet — here are ones for nearby muscles.",
        "Other exercises that work near %@.",
        "No exercises target %@ yet.",
        "No exercises target the marked areas yet.",
    ]

    @Test(arguments: [AppLanguage.es, .fr, .zhHans])
    func everyFeatureScreenKeyIsTranslated(language: AppLanguage) {
        let missing = Self.keys.filter { L10n.string($0, language: language) == $0 }
        #expect(missing.isEmpty, "Untranslated for \(language.rawValue): \(missing)")
    }

    @Test func speechLanguageFollowsTheChosenLanguage() {
        #expect(AppLanguage.en.speechLanguage == "en-US")
        #expect(AppLanguage.es.speechLanguage == "es-ES")
        #expect(AppLanguage.fr.speechLanguage == "fr-FR")
        #expect(AppLanguage.zhHans.speechLanguage == "zh-CN")
        #expect(AppLanguage.system.speechLanguage == nil)
    }
}
