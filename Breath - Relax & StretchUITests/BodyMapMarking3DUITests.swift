import XCTest

/// Simulator verification for the 3D tap-marking system:
/// hitbox↔mesh alignment (debug boxes), anatomical L/R, marker dots,
/// and drag-rotate coexisting with tap-to-mark.
final class BodyMapMarking3DUITests: XCTestCase {

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
        // Cold/fresh-install launches run seed insertion + up to 5 sequential
        // SwiftData migration passes synchronously in `.onAppear` — wait that
        // out before assuming the tab bar exists, or later steps fail against
        // a still-launching app rather than testing what they mean to test.
        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        _ = bodyTab.waitForExistence(timeout: 30)
        bodyTab.tap()
        // Wait out the async OBJ parse ("Loading 3D model…" placeholder).
        sleep(6)
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Debug-box alignment pass: renders every hit volume over the skin.
    @MainActor
    func testDebugHitboxAlignment() throws {
        let app = launchBodyTab(extraArgs: ["-debugHitboxes", "YES"])
        attach(app, "01-front-debug-boxes")

        // Drag-rotate roughly half a turn and capture the back.
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.45))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: end)
        sleep(1)
        attach(app, "02-rotated-debug-boxes")
    }

    /// True if any figure-side-prefixed region name (`Left …` / `Right …`) is
    /// currently visible — as a disambiguation pin, an exercise-list nav title,
    /// or a static label. Covers both post-confirm outcomes (popup vs. direct
    /// navigation) without the test needing to know which happened.
    private func sideVisible(_ app: XCUIApplication, prefix: String) -> Bool {
        let needle = "\(prefix) "
        for b in app.buttons.allElementsBoundByIndex where b.label.hasPrefix(needle) { return true }
        for n in app.navigationBars.allElementsBoundByIndex where n.identifier.hasPrefix(needle) { return true }
        for t in app.staticTexts.allElementsBoundByIndex where t.label.hasPrefix(needle) { return true }
        return false
    }

    /// Taps a point, confirms it via the top-right checkmark, and returns
    /// whichever region-name surface (pins or exercise list) results.
    private func markConfirmAndCapture(_ app: XCUIApplication,
                                       at offset: CGVector,
                                       stage: String) {
        app.windows.firstMatch.coordinate(withNormalizedOffset: offset).tap()
        sleep(1)
        attach(app, "\(stage)-dot-placed")
        app.descendants(matching: .any)["Confirm marked area"].firstMatch.tap()
        sleep(2)
        attach(app, "\(stage)-after-confirm")
    }

    /// Headline correctness: anatomical L/R convention + accurate resolution.
    /// The figure faces the viewer, so a tap on the VIEWER'S LEFT resolves to
    /// a "Right …" region (the figure's own right).
    @MainActor
    func testViewerLeftTapMapsToFigureRight() throws {
        let app = launchBodyTab(extraArgs: ["-debugMarkMode", "YES"])
        markConfirmAndCapture(app, at: CGVector(dx: 0.42, dy: 0.40), stage: "03-viewer-left")
        XCTAssertTrue(sideVisible(app, prefix: "Right"),
                      "Viewer-left tap should surface a figure-Right region")
    }

    /// The mirror case: a tap on the VIEWER'S RIGHT resolves to a "Left …"
    /// region (the figure's own left).
    @MainActor
    func testViewerRightTapMapsToFigureLeft() throws {
        let app = launchBodyTab(extraArgs: ["-debugMarkMode", "YES"])
        markConfirmAndCapture(app, at: CGVector(dx: 0.58, dy: 0.62), stage: "04-viewer-right")
        XCTAssertTrue(sideVisible(app, prefix: "Left"),
                      "Viewer-right tap should surface a figure-Left region")
    }

    /// Reported freeze repro: mark a region (auto-navigates to its exercise
    /// list via `showConfirmedExercises`), go Back to the body (re-driving
    /// `BodySceneView` via `refocusToken`), then tap the "Find Exercises"
    /// banner button, which pushes `BodyPartExercisesView` a SECOND time via
    /// the separate `showMarkedExercises` navigationDestination on the same
    /// stack. Asserts the list actually appears within a bounded wait rather
    /// than hanging indefinitely.
    @MainActor
    func testFindExercisesAfterBackDoesNotHang() throws {
        let app = launchBodyTab(extraArgs: ["-debugMarkMode", "YES"])
        markConfirmAndCapture(app, at: CGVector(dx: 0.42, dy: 0.40), stage: "05-mark")

        // Back to the body map — this is where refocusToken re-drives the scene.
        app.navigationBars.buttons.firstMatch.tap()
        sleep(2)
        attach(app, "06-after-back")

        let findButton = app.descendants(matching: .any)["Find exercises for marked areas"].firstMatch
        XCTAssertTrue(findButton.waitForExistence(timeout: 8), "Find Exercises banner button not found")
        findButton.tap()

        // If this hangs, waitForExistence times out instead of the test itself
        // hanging forever — that's the signal we're after.
        let listAppeared = app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 10)
        attach(app, "07-after-find-exercises")
        XCTAssertTrue(listAppeared, "BodyPartExercisesView did not appear within 10s — possible hang")
    }
}
