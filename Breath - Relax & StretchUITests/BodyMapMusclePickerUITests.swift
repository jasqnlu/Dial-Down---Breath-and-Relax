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

    /// Follows the double-tap path all the way to a candidate: focus an
    /// unfocused rail label, confirm its accessibility label flips from
    /// "— highlight region" to "— view exercises", then tap it again to
    /// drill into its stretch list. Deliberately targets an UNFOCUSED
    /// candidate rather than the auto-focused first one
    /// (`focusedRegion = pins.first?.name` on open) — this exercises both
    /// halves of `handleCandidateTap`'s focus/select branch instead of only
    /// the already-focused half, which is strictly more coverage.
    @MainActor
    func testTappingACandidateFocusesThenSelectsIt() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).doubleTap()
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 8))
        attach(app, "04-picker-open")

        let unfocused = app.buttons.matching(
            NSPredicate(format: "label ENDSWITH '— highlight region'")
        ).firstMatch
        XCTAssertTrue(unfocused.waitForExistence(timeout: 5),
                      "Expected at least one unfocused candidate on the rail")
        let fullLabel = unfocused.label
        let name = String(fullLabel.dropLast(" — highlight region".count))

        unfocused.tap()

        let focused = app.buttons["\(name) — view exercises"]
        XCTAssertTrue(focused.waitForExistence(timeout: 5),
                      "Tapping an unfocused candidate should flip its label to '— view exercises'")
        attach(app, "05-candidate-focused")

        focused.tap()

        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5),
                      "Tapping the now-focused candidate should push the stretch list for '\(name)'")
        attach(app, "06-candidate-stretch-list")
    }
}
