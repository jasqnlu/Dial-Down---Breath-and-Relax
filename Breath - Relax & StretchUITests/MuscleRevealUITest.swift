import XCTest

/// Drives the Body Map to the confirm-step disambiguation and captures the
/// muscle-layer reveal for visual review against docs/mockups/bodymap-muscle-reveal.html.
final class MuscleRevealUITest: XCTestCase {

    func testMuscleLayerRevealOnConfirm() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        // Body tab.
        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        XCTAssertTrue(bodyTab.waitForExistence(timeout: 15), "Body tab not found")
        bodyTab.tap()
        sleep(2) // 3D model loads off-main
        attach(app, "01-body-map")

        // Enter marking mode.
        let mark = app.descendants(matching: .any)["Mark areas by tapping"].firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10), "Mark button not found")
        mark.tap()
        sleep(1)
        attach(app, "02-marking-mode")

        // Tap the upper torso — reliably hits the chest region, which yields
        // several muscle candidates (Left/Right Chest + Upper/Lower Chest heads).
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40)).tap()
        sleep(1) // dot + zoom dolly
        attach(app, "03-pending-dot")

        // Confirm → disambiguation + muscle reveal.
        let confirm = app.descendants(matching: .any)["Confirm marked area"].firstMatch
        if confirm.waitForExistence(timeout: 5) {
            confirm.tap()
        } else {
            // Fallback: tap slightly lower if the first tap missed the body.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.48)).tap()
            sleep(1)
            let confirm2 = app.descendants(matching: .any)["Confirm marked area"].firstMatch
            if confirm2.waitForExistence(timeout: 5) { confirm2.tap() }
        }
        sleep(3) // first-load: 13MB muscle OBJ parse (~2.7s) + fade (0.5s)
        attach(app, "04-muscle-reveal")

        sleep(4) // generous settle to fully rule out first-load parse timing
        attach(app, "05-muscle-reveal-settled")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
