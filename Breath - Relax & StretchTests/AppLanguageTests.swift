import Testing
import Foundation
@testable import BreathRelaxStretch

struct AppLanguageTests {
    @Test func offersSystemPlusTheFourShippedLanguages() {
        #expect(AppLanguage.allCases.map(\.rawValue) == ["system", "en", "es", "fr", "zh-Hans"])
    }

    @Test func systemHasNoLocaleOverride() {
        #expect(AppLanguage.system.locale == nil)
    }

    @Test func explicitLanguagesMapToTheirLocaleIdentifier() {
        #expect(AppLanguage.en.locale?.identifier == "en")
        #expect(AppLanguage.es.locale?.identifier == "es")
        #expect(AppLanguage.fr.locale?.identifier == "fr")
        #expect(AppLanguage.zhHans.locale?.identifier == "zh-Hans")
    }

    @Test func displayNamesAreNativeNotTranslated() {
        #expect(AppLanguage.en.nativeName == "English")
        #expect(AppLanguage.es.nativeName == "Español")
        #expect(AppLanguage.fr.nativeName == "Français")
        #expect(AppLanguage.zhHans.nativeName == "简体中文")
    }

    @Test func storedRawValueRoundTrips() {
        for language in AppLanguage.allCases {
            #expect(AppLanguage(stored: language.rawValue) == language)
        }
    }

    @Test func unknownOrEmptyStoredValueFallsBackToSystem() {
        #expect(AppLanguage(stored: "") == .system)
        #expect(AppLanguage(stored: "klingon") == .system)
    }
}
