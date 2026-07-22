import XCTest

/// Drives the skin-covered Body Map (Plan 4 pivot) and captures the key
/// visual states for review: a clean skin-covered resting figure, a chest
/// confirm-reveal (skin fades, candidates colorize, no arm), a joint tap
/// (hip) that resolves to its crossing muscles, and dismiss (skin fades
/// back in).
final class AnatomyRevealUITest: XCTestCase {

    func testSkinModelRendersAndReveals() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        // Body tab → resting figure (should read as a clean skin-covered
        // body: no patch seams, no groin hole, no half-grey seam).
        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        XCTAssertTrue(bodyTab.waitForExistence(timeout: 15), "Body tab not found")
        bodyTab.tap()
        sleep(3) // OBJ parses off-main
        attach(app, "01-resting-skin")

        // Enter marking mode.
        let mark = app.descendants(matching: .any)["Mark areas by tapping"].firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10), "Mark button not found")
        mark.tap()
        sleep(1)
        attach(app, "02-marking-mode")

        // Tap the upper torso (chest) and confirm → skin fades, grayscale
        // muscles appear, candidates colorize.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40)).tap()
        sleep(1)
        attach(app, "03-chest-pending")
        tapConfirm(app)
        sleep(3)
        attach(app, "04-chest-reveal")

        // Dismiss → skin should fade back in (muscle hidden again).
        let cancel = app.descendants(matching: .any)["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 3) { cancel.tap(); sleep(2) }
        attach(app, "05-dismissed-skin-restored")

        // Tap near the hip (joint region, hitbox-only — no rendered geometry)
        // → resolves to the joint's crossing muscles as candidates.
        let mark2 = app.descendants(matching: .any)["Mark areas by tapping"].firstMatch
        if mark2.waitForExistence(timeout: 5) { mark2.tap(); sleep(1) }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.56)).tap()
        sleep(1)
        attach(app, "06-hip-pending")
        tapConfirm(app)
        sleep(3)
        attach(app, "07-hip-reveal")
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
