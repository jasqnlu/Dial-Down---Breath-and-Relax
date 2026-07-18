import XCTest

/// Simulator verification for the single-focus confirm/zoom/disambiguation
/// flow: cap marking to one dot (new tap replaces, doesn't accumulate),
/// Confirm only enables once a dot exists, and confirming either navigates
/// straight to exercises (unambiguous tap) or shows a zoomed disambiguation
/// popup with candidate pins.
final class BodyMapConfirmZoomUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchBodyTab(debugMarkMode: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES",
                                "-hasSeenAppGuide", "YES",
                                "-auth.isSignedIn", "YES",
                                "-auth.provider", "guest"]
        if debugMarkMode {
            app.launchArguments += ["-debugMarkMode", "YES"]
        }
        app.launch()
        app.descendants(matching: .any)["Body"].firstMatch.tap()
        sleep(6) // async OBJ parse
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testConfirmDisabledUntilMarkPlacedThenReplaceThenConfirm() throws {
        let app = launchBodyTab()
        let window = app.windows.firstMatch

        let confirmButton = app.descendants(matching: .any)["Confirm marked area"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        XCTAssertFalse(confirmButton.isEnabled, "Confirm should be disabled with no dot placed")
        attach(app, "01-no-dot-confirm-disabled")

        // Place a first dot (viewer-right thigh, per existing anatomical test coords).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.62)).tap()
        sleep(1)
        attach(app, "02-first-dot-placed")
        XCTAssertTrue(confirmButton.isEnabled, "Confirm should enable once a dot exists")

        // Tap a different spot — should replace, not add, the dot.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.40)).tap()
        sleep(1)
        attach(app, "03-second-tap-replaces-dot")
        XCTAssertTrue(confirmButton.isEnabled, "Confirm should still be enabled after replacing the dot")

        // Confirm — either lands directly on an exercise list (unambiguous)
        // or shows the zoomed disambiguation popup with candidate pins.
        confirmButton.tap()
        sleep(2)
        attach(app, "04-after-confirm")

        let disambiguationHint = app.staticTexts["Which area did you mean?"]
        if disambiguationHint.waitForExistence(timeout: 2) {
            attach(app, "05-disambiguation-popup")
            // Pick whichever pin exists and confirm it routes to an exercise list.
            let pin = app.buttons.allElementsBoundByIndex.first {
                $0.label.hasSuffix("— view exercises")
            }
            XCTAssertNotNil(pin, "Disambiguation popup shown but no candidate pins found")
            pin?.tap()
            sleep(1)
            attach(app, "06-after-picking-candidate")
        }

        // Either path should end on a navigation-titled exercise list, not
        // still on the marking screen.
        XCTAssertFalse(app.navigationBars["Mark Areas"].exists,
                        "Should have navigated away from marking mode after confirm")
    }

    /// Regression test for the "nothing pops up" bug: from the real entry path
    /// (enter via "Mark", not the debug arg), placing a dot and pressing the
    /// prominent top-right checkmark must lead to stretches — via the
    /// disambiguation popup or straight to an exercise list — never a silent
    /// discard. Also guards against the duplicate/misleading "Finish marking"
    /// checkmark ever coming back.
    @MainActor
    func testRealEntryConfirmLeadsToStretches() throws {
        let app = launchBodyTab(debugMarkMode: false)
        attach(app, "10-body-map-initial")

        // Enter marking mode via the toolbar "Mark" button.
        app.descendants(matching: .any)["Mark areas by tapping"].firstMatch.tap()
        sleep(1)

        // The old misleading "Finish marking" checkmark must be gone.
        XCTAssertFalse(app.descendants(matching: .any)["Finish marking"].firstMatch.exists,
                        "The mark-discarding 'Finish marking' checkmark should no longer exist")

        // Confirm is disabled until a dot is placed.
        let confirm = app.descendants(matching: .any)["Confirm marked area"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertFalse(confirm.isEnabled, "Confirm should be disabled before a dot is placed")

        // Place a dot, then confirm via the prominent top-right checkmark.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.62)).tap()
        sleep(1)
        attach(app, "11-dot-placed")
        XCTAssertTrue(confirm.isEnabled, "Confirm should enable once a dot is placed")
        confirm.tap()
        sleep(2)
        attach(app, "12-after-confirm")

        // Confirm must zoom in and show the disambiguation pins — NOT jump
        // straight to a flat exercise list (the reported bug), and never a
        // silent discard. Then a pin must lead to that muscle's exercises.
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 3),
                       "Confirm must show the zoom + disambiguation pins, not a bare exercise list")
        let pin = app.buttons.allElementsBoundByIndex.first { $0.label.hasSuffix("— view exercises") }
        XCTAssertNotNil(pin, "Disambiguation popup shown but no candidate pins found")
        pin?.tap()
        sleep(1)
        attach(app, "13-after-picking-pin")
        XCTAssertFalse(app.navigationBars["Mark Areas"].exists,
                        "Tapping a pin should navigate to that muscle's exercises")
    }

    /// Visual repro of the "old dot lingers" bug: mark a spot, confirm through
    /// to exercises, come back, re-enter marking, and place a NEW dot. Only the
    /// new dot should be visible. (SceneKit dots aren't accessibility elements,
    /// so this captures screenshots for inspection rather than asserting count.)
    @MainActor
    func testNewDotDoesNotShowPreviousDot() throws {
        let app = launchBodyTab() // debug mark mode

        // First mark: place a leg dot, confirm, pick a pin → exercises.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.62)).tap()
        sleep(1)
        app.descendants(matching: .any)["Confirm marked area"].firstMatch.tap()
        sleep(2)
        if app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 3) {
            app.buttons.allElementsBoundByIndex.first { $0.label.hasSuffix("— view exercises") }?.tap()
            sleep(1)
        }
        attach(app, "20-first-mark-exercises")

        // Back out to the Body Map, then re-enter marking (fresh session).
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        app.descendants(matching: .any)["Mark areas by tapping"].firstMatch.tap()
        sleep(1)
        attach(app, "21-reentered-marking-should-be-clean")

        // Place a NEW dot in a different spot.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.40)).tap()
        sleep(1)
        attach(app, "22-second-dot-only-one-visible")
    }

    /// Phase C: after picking a candidate and viewing its exercises, the Back
    /// arrow must return to the *zoomed* disambiguation state (so the user can
    /// pick a different muscle/head) — not a reset, un-zoomed body.
    @MainActor
    func testBackFromExercisesRestoresZoom() throws {
        let app = launchBodyTab() // debug mark mode

        // Mark a spot and confirm to reach the zoomed disambiguation.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.62)).tap()
        sleep(1)
        app.descendants(matching: .any)["Confirm marked area"].firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 3),
                       "Confirm should show the zoomed disambiguation")
        attach(app, "30-zoomed-disambiguation")

        // Tap the focused candidate (its label ends '— view exercises') → exercises.
        let pin = app.buttons.allElementsBoundByIndex.first { $0.label.hasSuffix("— view exercises") }
        XCTAssertNotNil(pin, "No focused candidate label found")
        pin?.tap()
        sleep(1)
        XCTAssertFalse(app.navigationBars["Mark Areas"].exists, "Should have navigated to exercises")
        attach(app, "31-exercise-list")

        // Press Back — must land back on the zoomed disambiguation, NOT a reset body.
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 3),
                       "Back should restore the zoomed disambiguation state")
        // A candidate label is still present to re-pick from.
        XCTAssertTrue(app.buttons.allElementsBoundByIndex.contains {
            $0.label.hasSuffix("— view exercises") || $0.label.hasSuffix("— highlight region")
        }, "Candidate labels should still be shown after Back")
        attach(app, "32-back-restored-zoom")
    }
}
