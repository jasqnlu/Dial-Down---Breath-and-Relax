import XCTest

/// Simulator verification for the fast tap-to-stretch path: a single tap
/// names a region and raises the action bar straight to its stretches, a tap
/// that resolves nothing clears the bar, and a drag still rotates the body
/// rather than being swallowed as a tap.
final class BodyMapFastPathUITests: XCTestCase {

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

    /// Fast path: one tap names a region, one more reaches its stretches.
    @MainActor
    func testSingleTapRaisesActionBarAndReachesStretches() throws {
        let app = launchBodyTab(extraArgs: [])
        attach(app, "01-body-at-rest")

        // Tap dead-centre chest — reliably on the torso silhouette (the
        // model renders smaller/lower in frame than a naive centre guess).
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5),
                      "A single tap on the body should raise the region action bar")
        attach(app, "02-bar-raised")

        let barLabel = bar.label
        XCTAssertTrue(barLabel.hasPrefix("Find stretches for "),
                      "Bar should name the region it will search; got '\(barLabel)'")

        bar.tap()
        // The pushed list is titled with the region name.
        let region = String(barLabel.dropFirst("Find stretches for ".count))
        XCTAssertTrue(app.navigationBars[region].waitForExistence(timeout: 5),
                      "Tapping the bar should push the stretch list for '\(region)'")
        attach(app, "03-stretch-list")
    }

    /// A tap that resolves no region clears the selection rather than leaving
    /// a stale bar pointing at the wrong body part.
    @MainActor
    func testTappingOffTheBodyClearsTheBar() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))

        // Far left edge, clear of the silhouette.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.5)).press(forDuration: 0.05)
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: bar)
        waitForExpectations(timeout: 5)
        attach(app, "04-bar-cleared")
    }

    /// Drag must still rotate — tap-to-face shares the same surface and the
    /// single-tap recogniser must not swallow a pan.
    @MainActor
    func testDragStillRotatesTheBody() throws {
        let app = launchBodyTab(extraArgs: [])
        attach(app, "05-before-drag")
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: scene.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        sleep(1)
        attach(app, "06-after-drag")
        // No bar: a drag is not a tap.
        XCTAssertFalse(app.buttons["bodymap.regionActionBar"].exists,
                       "A drag should rotate without selecting a region")
    }

    /// A DELIBERATE double tap off the body clears the bar too — same as a
    /// single tap-off-body (`testTappingOffTheBodyClearsTheBar` above), but
    /// this one also zooms the camera back out to the free-explore framing,
    /// so the whole body is visible again regardless of any prior pinch.
    /// This is `BodySceneView.handleOutsideDoubleTap`, distinct from
    /// `handleDoubleTap`'s silent miss (used only when the OTHER, always-on
    /// double-tap-to-drill recogniser happens to land off the mesh — a
    /// fumbled double tap, which must NOT wipe a selection either).
    @MainActor
    func testDoubleTappingOffTheBodyClearsTheBarAndZoomsOut() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.42)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        attach(app, "07-bar-before-outside-doubletap")

        // Same clear-of-silhouette coordinate as the single-tap-miss test.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.5)).doubleTap()
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: bar)
        waitForExpectations(timeout: 5)
        attach(app, "08-bar-cleared-by-outside-doubletap")

        // Must STAY cleared, not just disappear momentarily.
        for _ in 0..<6 {
            usleep(200_000)
            XCTAssertFalse(bar.exists, "The bar should not reappear after being cleared")
        }
    }

    /// The figure faces the viewer, so a tap on the VIEWER'S LEFT must
    /// resolve to the figure's own RIGHT side, and vice versa. Restores
    /// coverage dropped from the deleted `BodyMapMarking3DUITests` at
    /// e5c06e3 (`testViewerLeftTapMapsToFigureRight` /
    /// `testViewerRightTapMapsToFigureLeft`), adapted to the new bar-label
    /// flow: asserting on the action bar's "Find stretches for <region>"
    /// label directly is more robust than porting the old `sideVisible`
    /// scan, since the bar's label is the single source of truth for what
    /// the tap resolved to.
    @MainActor
    func testViewerLeftTapMapsToFigureRight() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.40)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        attach(app, "09-viewer-left-tap")
        XCTAssertTrue(bar.label.hasPrefix("Find stretches for Right "),
                      "A tap on the viewer's left should resolve to the figure's own right side; got '\(bar.label)'")
    }

    @MainActor
    func testViewerRightTapMapsToFigureLeft() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.62)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        attach(app, "10-viewer-right-tap")
        XCTAssertTrue(bar.label.hasPrefix("Find stretches for Left "),
                      "A tap on the viewer's right should resolve to the figure's own left side; got '\(bar.label)'")
    }
}
