import XCTest

/// Verifies the exercise animation loop appears in the search-list row and on the
/// exercise detail screen for "Clasped-Hands Behind-Back Stretch".
final class AnimationDemoUITest: XCTestCase {

    func testClaspedHandsAnimationInListAndDetail() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        // Exercises tab.
        let exercisesTab = app.descendants(matching: .any)["Exercises"].firstMatch
        XCTAssertTrue(exercisesTab.waitForExistence(timeout: 15), "Exercises tab not found")
        exercisesTab.tap()

        // Search surfaces the flat list of rows.
        let search = app.textFields["Search exercises"]
        XCTAssertTrue(search.waitForExistence(timeout: 10), "Search field not found")
        search.tap()
        search.typeText("Clasped")

        // The row's combined accessibility label begins with the exercise name.
        let rowPredicate = NSPredicate(format: "label BEGINSWITH %@",
                                       "Clasped-Hands Behind-Back Stretch")
        let row = app.descendants(matching: .any).matching(rowPredicate).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 8), "Clasped-Hands row not found")

        Thread.sleep(forTimeInterval: 1.5)   // let the loop begin
        attach(app, "01-list-row-with-animation")

        row.tap()
        Thread.sleep(forTimeInterval: 1.5)   // detail card loop
        attach(app, "02-detail-with-animation")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
