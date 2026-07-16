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
        app.descendants(matching: .any)["Body"].firstMatch.tap()
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

    /// Taps a point, exits marking mode so the MarkedAreasBanner surfaces the
    /// marked region name, and returns it.
    private func markAndReadRegion(_ app: XCUIApplication,
                                   at offset: CGVector,
                                   stage: String) -> String? {
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: offset).tap()
        sleep(1)
        attach(app, "\(stage)-marking")
        // Exit marking → banner shows the region name as its title.
        app.descendants(matching: .any)["Finish marking"].firstMatch.tap()
        sleep(1)
        attach(app, "\(stage)-banner")
        // The single-region banner title is the region name; find any label
        // matching a known muscle-group prefix.
        for el in app.staticTexts.allElementsBoundByIndex {
            let v = el.label
            if v.hasPrefix("Left ") || v.hasPrefix("Right ") || v == "Abs" {
                return v
            }
        }
        return nil
    }

    /// Headline correctness: anatomical L/R convention + accurate resolution.
    /// The figure faces the viewer, so a tap on the VIEWER'S LEFT resolves to
    /// a "Right …" region (the figure's own right), and vice-versa.
    @MainActor
    func testTapMarkingAnatomicalSides() throws {
        // Fresh state so a prior run's marks don't seed the banner.
        let app = launchBodyTab(extraArgs: ["-debugMarkMode", "YES"])

        // Viewer-left torso → figure's RIGHT chest.
        let left = markAndReadRegion(app, at: CGVector(dx: 0.42, dy: 0.40),
                                     stage: "03-viewer-left")
        XCTAssertNotNil(left, "Tap on viewer-left torso marked nothing")
        XCTAssertTrue(left?.hasPrefix("Right ") ?? false,
                      "Viewer-left tap should map to a figure-Right region, got \(left ?? "nil")")

        // Re-enter marking mode and clear the first mark so the next banner
        // shows a single region name (not "2 areas marked").
        app.descendants(matching: .any)["Mark areas by tapping"].firstMatch.tap()
        sleep(1)
        app.descendants(matching: .any)["Clear all marks"].firstMatch.tap()
        sleep(1)
        // Viewer-right thigh → figure's LEFT quadriceps.
        let right = markAndReadRegion(app, at: CGVector(dx: 0.58, dy: 0.62),
                                      stage: "04-viewer-right")
        XCTAssertNotNil(right, "Tap on viewer-right thigh marked nothing")
        XCTAssertTrue(right?.hasPrefix("Left ") ?? false,
                      "Viewer-right tap should map to a figure-Left region, got \(right ?? "nil")")
    }
}
