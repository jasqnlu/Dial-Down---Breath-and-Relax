import XCTest

/// Not an assertion test — a repeatable way to regenerate the onboarding
/// showcase screenshots straight from the app. Export the attachments with
/// `xcrun xcresulttool export attachments` (see .claude/skills/verify/SKILL.md).
final class ShowcaseScreenshotUITests: XCTestCase {

    func testCaptureShowcaseScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            // Legacy global flag: RegistrationGate migrates it to the guest's
            // per-account flag, so the coach-mark tour stays out of the shots.
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES", "-auth.provider", "guest",
        ]
        app.launch()

        capture(app, tab: "Body", name: "showcase-bodymap", settle: 6)      // 3D model warm-up
        capture(app, tab: "Exercises", name: "showcase-exercises", settle: 2)
        capture(app, tab: "Routines", name: "showcase-routines", settle: 2)
    }

    private func capture(_ app: XCUIApplication, tab: String, name: String, settle: TimeInterval) {
        let button = app.buttons[tab]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing tab button \(tab)")
        button.tap()
        Thread.sleep(forTimeInterval: settle)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
