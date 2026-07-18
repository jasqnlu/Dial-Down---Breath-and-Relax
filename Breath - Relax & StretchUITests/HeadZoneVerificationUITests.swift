import XCTest

/// Simulator verification for the head fan-out: tapping the head should surface
/// the four evidence-based face zones (Forehead + one side's Eye, Temple, Jaw)
/// as pins, with the side inferred from the tapped x. Asserts the fan-out is
/// functionally correct and attaches screenshots.
///
/// ANCHOR TUNING: the on-face dot positions come from HeadZones.leftAnchors /
/// foreheadAnchor (currently estimates). To fine-tune, run this test in Xcode
/// and open the "02-head-zones-fanned" attachment in the Test Report (the CLI
/// xcresulttool export returns nothing under Xcode 26, but the Xcode Test
/// navigator shows the screenshots). Nudge the anchors until each dot sits on
/// its feature.
final class HeadZoneVerificationUITests: XCTestCase {

    override func setUpWithError() throws { continueAfterFailure = false }

    private func launchBodyTab() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES",
                                "-hasSeenAppGuide", "YES",
                                "-auth.isSignedIn", "YES",
                                "-auth.provider", "guest",
                                "-debugMarkMode", "YES"]
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
    func testHeadFansIntoFaceZones() throws {
        let app = launchBodyTab()
        let window = app.windows.firstMatch
        attach(app, "00-body-initial")

        // Tap the head, slightly right-of-centre.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.16)).tap()
        sleep(1)
        attach(app, "01-head-dot-placed")
        app.descendants(matching: .any)["Confirm marked area"].firstMatch.tap()
        sleep(2)
        attach(app, "02-head-zones-fanned")

        let hint = app.staticTexts["Which area did you mean?"]
        XCTAssertTrue(hint.waitForExistence(timeout: 3),
                      "Tapping the head should fan into the face-zone disambiguation")

        let labels = app.buttons.allElementsBoundByIndex.map(\.label).filter { $0.contains("—") }
        let names = Set(labels.map {
            String($0.split(separator: "—")[0]).trimmingCharacters(in: .whitespaces)
        })
        print("HEADZONE-CANDIDATE-LABELS:", labels.sorted())

        XCTAssertEqual(names.count, 4, "Head should fan into exactly four zones, got \(names)")
        XCTAssertTrue(names.contains("Forehead"), "Forehead (midline) should always appear")
        let sides = names.subtracting(["Forehead"])
        XCTAssertTrue(sides == ["Left Eye", "Left Temple", "Left Jaw"] ||
                      sides == ["Right Eye", "Right Temple", "Right Jaw"],
                      "The three bilateral zones should all be one side: \(sides)")
    }
}
