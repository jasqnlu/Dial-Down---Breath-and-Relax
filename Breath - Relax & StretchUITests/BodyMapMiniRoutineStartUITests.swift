import XCTest

/// Reproduces the exact user-reported path: BodyMap → double-tap → drill
/// into a region's stretch list → add an exercise to the mini routine →
/// "Next" opens the shared Customize screen → "Start" → land in
/// SessionPlayerView. Checks that the back/skip buttons are not just
/// present in the accessibility tree but actually *hittable* — `.exists`
/// alone doesn't prove visibility, which is exactly how a real bug here
/// slipped past manual testing: some exercises (ones with an extra
/// AnimationAccuracyNote caveat line) pushed the whole button row off the
/// bottom of the screen in the old non-scrolling layout, still "existing"
/// but neither visible nor tappable.
final class BodyMapMiniRoutineStartUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testStartFromBodyMapMiniRoutineBarShowsSkipAndBackButtons() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES", "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES", "-auth.provider", "guest",
        ]
        app.launch()

        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        XCTAssertTrue(bodyTab.waitForExistence(timeout: 30))
        bodyTab.tap()
        sleep(6) // async OBJ parse — mirrors BodyMapMusclePickerUITests

        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).doubleTap()
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 8))
        attach(app, "01-muscle-picker")

        // The auto-focused candidate (picker opens with the first pin
        // already focused) drills straight into that region's stretch list.
        let focusedCandidate = app.buttons.matching(
            NSPredicate(format: "label ENDSWITH '— view exercises'")
        ).firstMatch
        XCTAssertTrue(focusedCandidate.waitForExistence(timeout: 5))
        let regionName = String(focusedCandidate.label.dropLast(" — view exercises".count))
        focusedCandidate.tap()

        XCTAssertTrue(app.navigationBars[regionName].waitForExistence(timeout: 5))
        attach(app, "02-region-stretch-list")

        // Add the first exercise tile to the mini routine via its badge
        // (bottom-trailing corner of the tile — the badge collapses into
        // the tile's single combined accessibility element, so a plain
        // element query can't address it separately; a coordinate tap on
        // its known corner position is the reliable way to hit it).
        let firstTile = app.descendants(matching: .any).matching(identifier: "exerciseGridTile").firstMatch
        XCTAssertTrue(firstTile.waitForExistence(timeout: 10))
        firstTile.coordinate(withNormalizedOffset: CGVector(dx: 0.83, dy: 0.61)).tap()

        // "Next" (not "Start" — the bar now opens the shared Customize
        // screen instead of jumping straight into the session).
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Mini-routine bar with Next should appear once an exercise is added")
        attach(app, "03-mini-routine-bar-appeared")
        nextButton.tap()

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Next should open the shared Customize screen with a Start action")
        attach(app, "04-customize-screen")
        startButton.tap()

        // The actual reported symptom: does this entry point's session
        // screen show the back/skip buttons, actually visible and
        // tappable (not merely present off-screen in the hierarchy)?
        let pauseButton = app.buttons["Pause session"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 10), "Should land in the session player")
        attach(app, "05-session-player-from-bodymap")

        let backButton = app.buttons["Previous exercise"]
        let skipButton = app.buttons["Skip exercise"]
        XCTAssertTrue(backButton.exists && backButton.isHittable, "Back button should be visible and tappable, not just present in the hierarchy")
        XCTAssertTrue(skipButton.exists && skipButton.isHittable, "Skip button should be visible and tappable, not just present in the hierarchy")
    }
}
