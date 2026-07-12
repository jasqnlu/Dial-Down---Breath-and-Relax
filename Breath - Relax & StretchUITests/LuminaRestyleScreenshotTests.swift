import XCTest

/// Screenshot pass for the Tier-1 Lumina restyle (session player, auth,
/// onboarding, paywall). Not assertions of behavior — each test navigates to
/// a restyled screen and attaches a screenshot for visual review.
final class LuminaRestyleScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAuthScreensDark() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-hasSeenAppGuide", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["Email"].waitForExistence(timeout: 10))
        attach(app, "auth-dark")

        app.buttons["Email"].tap()
        XCTAssertTrue(app.buttons["Create Account"].waitForExistence(timeout: 5))
        attach(app, "email-auth-dark")
        app.buttons["Cancel"].tap()
    }

    func testAuthScreenLight() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-hasSeenAppGuide", "YES",
                                "-colorSchemeOverride", "1"]
        app.launch()
        XCTAssertTrue(app.buttons["Email"].waitForExistence(timeout: 10))
        attach(app, "auth-light")
    }

    func testOnboardingScreensDark() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-auth.isSignedIn", "YES", "-auth.provider", "guest",
                                "-hasCompletedOnboarding", "NO", "-hasSeenAppGuide", "YES"]
        app.launch()
        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        attach(app, "onboarding-1-welcome-dark")

        for name in ["2-gender", "3-goals", "4-bodymap"] {
            next.tap()
            sleep(1)
            attach(app, "onboarding-\(name)-dark")
        }
        next.tap()
        sleep(1)
        attach(app, "onboarding-5-notifications-dark")
    }

    func testOnboardingWelcomeLight() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-auth.isSignedIn", "YES", "-auth.provider", "guest",
                                "-hasCompletedOnboarding", "NO", "-hasSeenAppGuide", "YES",
                                "-colorSchemeOverride", "1"]
        app.launch()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        attach(app, "onboarding-1-welcome-light")
    }

    func testSessionPlayerDark() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-auth.isSignedIn", "YES", "-auth.provider", "guest",
                                "-hasCompletedOnboarding", "YES", "-hasSeenAppGuide", "YES"]
        app.launch()

        // Today is the frontmost tab at launch; its hero CTA starts a session.
        let begin = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Begin today'")
        ).firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 15)) // allows first-launch seeding
        begin.tap()
        sleep(1)
        attach(app, "session-getready-dark")

        let skip = app.buttons["Skip"].firstMatch
        if skip.waitForExistence(timeout: 3) { skip.tap() }
        sleep(1)
        attach(app, "session-player-dark")
    }

    func testPaywallDark() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-auth.isSignedIn", "YES", "-auth.provider", "guest",
                                "-hasCompletedOnboarding", "YES", "-hasSeenAppGuide", "YES"]
        app.launch()

        let profileTab = app.buttons["Profile"].firstMatch
        XCTAssertTrue(profileTab.waitForExistence(timeout: 15))
        profileTab.tap()

        let upgrade = app.buttons["Upgrade to Breath Pro"].firstMatch
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5))
        upgrade.tap()

        let notNow = app.buttons["Not Now"]
        if !notNow.waitForExistence(timeout: 5) {
            upgrade.tap() // one retry — first tap occasionally lands during tab transition
            XCTAssertTrue(notNow.waitForExistence(timeout: 5))
        }
        sleep(1)
        attach(app, "paywall-dark")
    }
}
