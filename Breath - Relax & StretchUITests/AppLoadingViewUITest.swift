import XCTest

final class AppLoadingViewUITest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches cold (no onboarding/auth skip — the splash sits above
    /// `OnboardingGate`) and confirms the trivia card is visible immediately
    /// after launch, then confirms the app has moved past the splash well
    /// within a few seconds.
    func testSplashShowsTriviaThenDismisses() throws {
        let app = XCUIApplication()
        app.launch()

        // AppLoadingView gives the trivia card an explicit combined
        // accessibilityLabel ("Body trivia fact"), so — per the repo's
        // `verify` skill gotcha — query that label via `descendants`, not
        // `staticTexts["Did you know?"]` (the raw child text is absorbed
        // into the combined element and won't match).
        let triviaCard = app.descendants(matching: .any)["Body trivia fact"]
        XCTAssertTrue(triviaCard.waitForExistence(timeout: 5), "Trivia card should appear on cold launch")

        let splashScreenshot = XCTAttachment(screenshot: app.screenshot())
        splashScreenshot.lifetime = .keepAlways
        splashScreenshot.name = "01-splash-with-trivia"
        add(splashScreenshot)

        // Splash holds for >= 1.5s minimum; give generous headroom for the
        // mesh parse + crossfade before asserting it's gone.
        let dismissed = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: dismissed, object: triviaCard)
        let result = XCTWaiter().wait(for: [expectation], timeout: 10)
        XCTAssertEqual(result, .completed, "Splash should dismiss within 10s of launch")

        let postSplashScreenshot = XCTAttachment(screenshot: app.screenshot())
        postSplashScreenshot.lifetime = .keepAlways
        postSplashScreenshot.name = "02-post-splash"
        add(postSplashScreenshot)
    }
}
