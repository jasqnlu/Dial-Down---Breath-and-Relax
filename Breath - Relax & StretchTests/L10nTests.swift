import Testing
import Foundation
@testable import BreathRelaxStretch

struct L10nTests {
    @Test func resolvesAKeyInTheChosenLanguage() {
        #expect(L10n.string("Body Map", language: .es) == "Mapa Corporal")
        #expect(L10n.string("Body Map", language: .fr) == "Carte du Corps")
        #expect(L10n.string("Body Map", language: .zhHans) == "身体图谱")
    }

    @Test func englishAndUnknownKeysFallBackToTheKeyItself() {
        #expect(L10n.string("Body Map", language: .en) == "Body Map")
        #expect(L10n.string("A key that is in no catalog", language: .es) == "A key that is in no catalog")
    }

    @Test func systemDefaultNeverReturnsEmpty() {
        #expect(!L10n.string("Body Map", language: .system).isEmpty)
    }

    @Test func currentLanguageReadsTheStoredPreference() {
        let defaults = UserDefaults(suiteName: "L10nTests-\(UUID().uuidString)")!
        defaults.set("fr", forKey: AppLanguage.storageKey)
        #expect(AppLanguage.current(defaults: defaults) == .fr)
        defaults.removeObject(forKey: AppLanguage.storageKey)
        #expect(AppLanguage.current(defaults: defaults) == .system)
    }

    @Test func effectiveLocaleFallsBackToTheDeviceForSystem() {
        #expect(AppLanguage.es.effectiveLocale.identifier == "es")
        #expect(AppLanguage.system.effectiveLocale == Locale.autoupdatingCurrent)
    }
}
