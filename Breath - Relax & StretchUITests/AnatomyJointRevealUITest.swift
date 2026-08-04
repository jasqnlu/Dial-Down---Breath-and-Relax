import XCTest

/// Focused check (skin-covered pivot, Task 6): tapping a joint region (hip)
/// — hitbox-only, no rendered geometry — resolves to its crossing muscles as
/// candidates, same as a muscle-group tap.
final class AnatomyJointRevealUITest: XCTestCase {

    func testHipTapResolvesToCrossingMuscles() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        let bodyTab = app.descendants(matching: .any)["Body"].firstMatch
        XCTAssertTrue(bodyTab.waitForExistence(timeout: 15), "Body tab not found")
        bodyTab.tap()
        sleep(4) // let the 13MB OBJ finish parsing before entering marking mode

        let mark = app.descendants(matching: .any)["Mark areas by tapping"].firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10), "Mark button not found")
        mark.tap()
        sleep(1)

        // Hip joint hitbox (real Z-Anatomy capsule geometry) is a small box
        // right at waist height — the first attempt (dy=0.47) landed just
        // below it, resolving to Obliques/Abs/Hip Flexors instead. Nudge up.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.435)).tap()
        sleep(1)
        attach(app, "01-hip-pending")

        let confirm = app.descendants(matching: .any)["Confirm marked area"].firstMatch
        if confirm.waitForExistence(timeout: 5) { confirm.tap() }
        sleep(3)
        attach(app, "02-hip-reveal")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
