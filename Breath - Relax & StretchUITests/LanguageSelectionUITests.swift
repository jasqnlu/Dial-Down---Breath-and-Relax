import XCTest

final class LanguageSelectionUITests: XCTestCase {

    private func launchIntoOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        // Don't pass `-appLanguage`: launch arguments live in the argument
        // domain, which shadows every write the app makes to that key.
        app.launchArguments += ["-hasCompletedOnboarding", "NO",
                                "-AppleLanguages", "(en)",
                                "-AppleLocale", "en_US"]
        app.launch()
        // The chosen language persists in the simulator between tests; reset
        // via the row's identifier, which doesn't depend on the display language.
        let system = app.buttons["language.system"]
        if system.waitForExistence(timeout: 15) { system.tap() }
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Language is the very first onboarding screen, and picking a language
    /// re-renders the UI in it immediately (no relaunch).
    func testFirstOnboardingScreenSwitchesLanguageLive() {
        let app = launchIntoOnboarding()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 15),
                      "Language should be the first onboarding screen")
        XCTAssertTrue(app.buttons["Next"].exists)
        attach(app, "language-page-english")

        app.buttons["language.es"].tap()
        XCTAssertTrue(app.buttons["Siguiente"].waitForExistence(timeout: 5),
                      "Next button should now read Siguiente")
        XCTAssertTrue(app.staticTexts["Elige tu idioma"].exists)
        attach(app, "language-page-spanish")

        app.buttons["language.fr"].tap()
        XCTAssertTrue(app.buttons["Suivant"].waitForExistence(timeout: 5))

        app.buttons["language.zh-Hans"].tap()
        XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 5))
        attach(app, "language-page-chinese")
    }

    /// Every onboarding screen renders in the chosen language — not just the
    /// ones whose copy happens to be a SwiftUI string literal.
    func testEveryOnboardingScreenIsTranslatedToSpanish() {
        let app = launchIntoOnboarding()
        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 15))
        app.buttons["language.es"].tap()

        func onScreen(_ label: String) -> Bool {
            app.descendants(matching: .any)[label].waitForExistence(timeout: 5)
        }
        func next() { app.buttons["Siguiente"].tap() }

        next() // Welcome
        XCTAssertTrue(onScreen("Guías de respiración"))
        XCTAssertTrue(onScreen("Calma tu sistema nervioso en minutos"))
        next() // Showcase 1
        XCTAssertTrue(onScreen("Toca un músculo, obtén el estiramiento"))
        next() // Showcase 2
        XCTAssertTrue(onScreen("Más de 200 ejercicios guiados"))
        next() // Showcase 3
        XCTAssertTrue(onScreen("Crea tu rutina"))
        next() // Goals
        XCTAssertTrue(onScreen("Flexibilidad"))
        next() // Focus areas
        XCTAssertTrue(onScreen("Cuello"))
        XCTAssertTrue(onScreen("Caderas y Glúteos"))
        next() // Body map intro
        XCTAssertTrue(onScreen("Toca cualquier región del cuerpo para explorar ejercicios específicos"))
    }

    /// Settings offers the same choice at any time, and it applies live —
    /// including navigation titles, which SwiftUI won't re-resolve on its own —
    /// without bouncing the user off the Settings screen.
    func testSettingsLanguagePickerSwitchesLanguageLive() {
        // A previous test may have left a language persisted; reset it through
        // onboarding's identifier-based row, then relaunch as a registered user.
        let reset = launchIntoOnboarding()
        reset.terminate()

        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES",
                                "-auth.anonymousID", UUID().uuidString,
                                "-auth.isSignedIn", "YES",
                                "-auth.provider", "email",
                                "-auth.firstName", "Ada", "-auth.lastName", "Lovelace",
                                "-auth.displayName", "Ada Lovelace",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let profileTab = app.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 20))
        profileTab.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()

        let picker = app.descendants(matching: .any)["settings.language"]
        for _ in 0..<5 where !picker.exists { app.swipeUp() }
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Settings should offer a Language picker")
        picker.tap()
        app.buttons["Français"].tap()

        XCTAssertTrue(app.staticTexts["Langue"].waitForExistence(timeout: 5),
                      "Language section header should now read Langue")
        attach(app, "settings-language-french")
        XCTAssertTrue(app.navigationBars["Profil"].waitForExistence(timeout: 5),
                      "Navigation title should follow the live switch too")
        XCTAssertTrue(app.descendants(matching: .any)["settings.language"].exists,
                      "User should still be on the Settings segment")

        // Restore System Default so the simulator's persisted choice doesn't leak.
        app.descendants(matching: .any)["settings.language"].tap()
        app.buttons["Par défaut du système"].tap()
        XCTAssertTrue(app.staticTexts["Language"].waitForExistence(timeout: 5))
    }

    /// The chrome a user sees on every launch — tab bar, Profile segments, home
    /// greeting and the medical disclaimer — is in the chosen language.
    /// (`-appLanguage` is fine here: this test only reads the value.)
    func testAlwaysVisibleChromeIsTranslatedToSpanish() {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES",
                                "-appLanguage", "es",
                                "-auth.anonymousID", UUID().uuidString,
                                "-auth.isSignedIn", "YES",
                                "-auth.provider", "email",
                                "-auth.firstName", "Ada", "-auth.lastName", "Lovelace",
                                "-auth.displayName", "Ada Lovelace",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let greeting = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS ', Ada' AND (label BEGINSWITH 'Buen' OR label BEGINSWITH 'Hora')")).firstMatch
        XCTAssertTrue(greeting.waitForExistence(timeout: 20), "Home greeting should be Spanish")
        XCTAssertTrue(app.buttons["Hoy"].exists, "Tab bar: Today")

        app.buttons["Perfil"].tap()
        XCTAssertTrue(app.buttons["Ajustes"].waitForExistence(timeout: 5), "Profile segment: Settings")
        XCTAssertTrue(app.buttons["Apariencia"].exists, "Profile segment: Appearance")
        app.buttons["Ajustes"].tap()

        let safety = app.buttons["Salud y Seguridad"]
        for _ in 0..<8 where !safety.exists { app.swipeUp() }
        XCTAssertTrue(safety.waitForExistence(timeout: 5))
        safety.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(
            format: "label BEGINSWITH 'Esta app ofrece únicamente'")).firstMatch.waitForExistence(timeout: 5),
                      "Medical disclaimer must be translated")
        attach(app, "safety-spanish")
    }

    /// Exercise names, instructions and cautions are content (per-language overlay
    /// files), not catalog strings — a Spanish user must see them translated.
    func testExerciseContentIsTranslatedToSpanish() {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES",
                                "-appLanguage", "es",
                                "-auth.anonymousID", UUID().uuidString,
                                "-auth.isSignedIn", "YES",
                                "-auth.provider", "email",
                                "-auth.firstName", "Ada", "-auth.lastName", "Lovelace",
                                "-auth.displayName", "Ada Lovelace",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let tab = app.buttons["Ejercicios"]
        XCTAssertTrue(tab.waitForExistence(timeout: 20))
        tab.tap()

        // Search works on the localized name, and the result tile leads with it.
        let search = app.textFields["Buscar ejercicios"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Postura del ni")
        let tile = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH 'Postura del niño'")).firstMatch
        attach(app, "exercises-search-spanish")
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "Exercise tile should use the Spanish name")
        XCTAssertFalse(app.descendants(matching: .any)["Child's Pose"].exists)
        tile.tap()

        XCTAssertTrue(app.navigationBars["Postura del niño"].waitForExistence(timeout: 10),
                      "Detail title should be the Spanish name")
        let instruction = app.staticTexts.containing(NSPredicate(
            format: "label BEGINSWITH 'Arrodíllate en el suelo'")).firstMatch
        for _ in 0..<6 where !instruction.exists { app.swipeUp() }
        XCTAssertTrue(instruction.waitForExistence(timeout: 5), "Instructions should be Spanish")
        let caution = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS 'Omítelo si arrodillarte'")).firstMatch
        for _ in 0..<6 where !caution.exists { app.swipeDown() }
        XCTAssertTrue(caution.waitForExistence(timeout: 5), "Safety caution should be Spanish")
        attach(app, "exercise-detail-spanish")
    }

    /// The choice survives leaving the language page — the Welcome page that
    /// follows is already in the chosen language.
    func testChosenLanguagePersistsToNextPage() {
        let app = launchIntoOnboarding()
        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 15))

        app.buttons["language.es"].tap()
        app.buttons["Siguiente"].tap()

        XCTAssertTrue(app.staticTexts["Tu guía diaria para respirar, estirarte y sentirte mejor."]
                        .waitForExistence(timeout: 5))
        attach(app, "welcome-page-spanish")
    }
}
