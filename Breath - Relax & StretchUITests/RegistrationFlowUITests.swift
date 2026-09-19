import XCTest

final class RegistrationFlowUITests: XCTestCase {

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"] + extra
        app.launch()
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Signed-in email account with a legacy single-string name and no stored
    /// first/last: must land on the name step, prefilled.
    func testUnregisteredAccountSeesPrefilledNameStepThenHome() {
        // Blank first/last explicitly: UserDefaults persists across tests in one
        // install, so a prior test (registered account) may have stored them.
        let app = launch(["-auth.isSignedIn", "YES", "-auth.provider", "email",
                          "-auth.firstName", "", "-auth.lastName", "",
                          "-auth.displayName", "Ada Lovelace"])
        let first = app.textFields["First name"]
        XCTAssertTrue(first.waitForExistence(timeout: 20), "Name step should appear")
        XCTAssertEqual(first.value as? String, "Ada")
        XCTAssertEqual(app.textFields["Last name"].value as? String, "Lovelace")
        attach(app, "1-name-step")

        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 10), "Home should follow")
        attach(app, "2-home-after-name")
    }

    /// A complete stored name means registered: straight to Home, no name step.
    func testRegisteredAccountSkipsTheNameStep() {
        let app = launch(["-auth.isSignedIn", "YES", "-auth.provider", "email",
                          "-auth.firstName", "Ada", "-auth.lastName", "Lovelace",
                          "-auth.displayName", "Ada Lovelace"])
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.textFields["First name"].exists)
        attach(app, "3-registered-home")
    }

    /// Guests never see the name step.
    func testGuestSkipsTheNameStep() {
        let app = launch(["-auth.isSignedIn", "YES", "-auth.provider", "guest"])
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.textFields["First name"].exists)
    }

    /// Fresh install: showcase pages appear, Skip jumps to the goal picker.
    func testFreshInstallShowsShowcaseAndSkipWorks() {
        let app = XCUIApplication()
        app.launch()   // no launch args: hasCompletedOnboarding is false
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 15))
        app.buttons["Next"].tap()                       // -> showcase 1
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 5))
        attach(app, "4-showcase-1")
        app.buttons["Skip"].tap()                       // -> goals page
        XCTAssertFalse(app.buttons["Skip"].exists)
        attach(app, "5-after-skip")
    }
}
