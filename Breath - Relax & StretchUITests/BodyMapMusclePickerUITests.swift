import XCTest

/// Simulator verification for the precise path: a double tap opens the
/// muscle-selection overlay directly (camera dolly, skin fade, ≤4 candidate
/// muscles on a labelled rail) — no Mark mode, no colour, no checkmark — and
/// Cancel returns to the plain body without navigating.
final class BodyMapMusclePickerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchBodyTab(extraArgs: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES",
                                "-hasSeenAppGuide", "YES",
                                "-auth.isSignedIn", "YES",
                                "-auth.provider", "guest"]
        app.launchArguments += extraArgs
        app.launch()
        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        _ = bodyTab.waitForExistence(timeout: 30)
        bodyTab.tap()
        sleep(6) // async OBJ parse
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Precise path: a double tap opens the muscle picker directly — no Mark
    /// mode, no colour, no checkmark.
    @MainActor
    func testDoubleTapOpensTheMusclePicker() throws {
        let app = launchBodyTab(extraArgs: [])
        attach(app, "01-body-at-rest")

        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).doubleTap()

        // The picker replaces the facing toggle with a Cancel affordance and
        // the "Which area did you mean?" prompt.
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 8),
                      "A double tap should open the muscle-selection overlay")
        attach(app, "02-muscle-picker")

        XCTAssertTrue(app.buttons["Cancel"].exists,
                      "The picker should offer a way out")
    }

    /// Cancelling the picker returns to the plain body without navigating.
    @MainActor
    func testCancellingThePickerReturnsToTheBody() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).doubleTap()
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 8))

        app.buttons["Cancel"].tap()
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["Which area did you mean?"])
        waitForExpectations(timeout: 5)
        attach(app, "03-back-to-body")
    }
}
