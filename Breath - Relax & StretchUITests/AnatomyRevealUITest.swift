import XCTest

/// Drives the single-anatomy Body Map (Plan 3) and captures the key visual
/// states for review against docs/mockups/bodymap-anatomy-reveal.html:
/// grayscale resting figure, a chest confirm-reveal (candidates colorize, no
/// arm), and a face tap (skin head fades to expose facial muscles).
final class AnatomyRevealUITest: XCTestCase {

    func testAnatomyModelRendersAndReveals() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        // Body tab → resting figure (should read grayscale: bare muscles + skin head).
        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        XCTAssertTrue(bodyTab.waitForExistence(timeout: 15), "Body tab not found")
        bodyTab.tap()
        sleep(3) // anatomy OBJ parses off-main
        attach(app, "01-resting-grayscale")

        // Enter marking mode.
        let mark = app.descendants(matching: .any)["Mark areas by tapping"].firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10), "Mark button not found")
        mark.tap()
        sleep(1)
        attach(app, "02-marking-mode")

        // Tap the upper torso (chest) and confirm → candidates colorize.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40)).tap()
        sleep(1)
        attach(app, "03-chest-pending")
        tapConfirm(app)
        sleep(3)
        attach(app, "04-chest-reveal")

        // Cancel back out, then tap the head/face → skin head should fade to
        // expose a facial muscle.
        let cancel = app.descendants(matching: .any)["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 3) { cancel.tap(); sleep(1) }
        let mark2 = app.descendants(matching: .any)["Mark areas by tapping"].firstMatch
        if mark2.waitForExistence(timeout: 5) { mark2.tap(); sleep(1) }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.16)).tap()
        sleep(1)
        attach(app, "05-face-pending")
        tapConfirm(app)
        sleep(3)
        attach(app, "06-face-reveal")
    }

    private func tapConfirm(_ app: XCUIApplication) {
        let confirm = app.descendants(matching: .any)["Confirm marked area"].firstMatch
        if confirm.waitForExistence(timeout: 5) { confirm.tap() }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
