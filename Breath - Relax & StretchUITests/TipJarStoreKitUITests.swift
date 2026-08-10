import XCTest

// Regression coverage for the tip jar's infinite-spinner bug: TipJarView used
// to render a bare ProgressView() whenever StoreKit's product list was empty,
// with no distinction between "still loading" and "load failed/came back
// empty" — so a StoreKit hiccup left the sheet spinning forever. This test
// doesn't assert real products load (that depends on a StoreKit configuration
// being wired into the scheme and reachable App Store Connect products,
// neither guaranteed in CI); it asserts the spinner never gets stuck.
final class TipJarStoreKitUITests: XCTestCase {
    func testTipJarNeverSpinsForever() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        app.buttons["Profile"].tap()

        let supportButton = app.buttons["Support Development"]
        XCTAssertTrue(supportButton.waitForExistence(timeout: 10))
        supportButton.tap()

        let closeButton = app.buttons["Close"]
        let appeared = closeButton.waitForExistence(timeout: 8)
        if !appeared {
            // One retry with a second tap, in case the first tap landed
            // during a List/animation transition and got swallowed — a
            // simulator/XCUITest timing quirk unrelated to the app itself.
            supportButton.tap()
        }
        XCTAssertTrue(closeButton.waitForExistence(timeout: 8), "TipJarView sheet never appeared, even after a retry tap")

        // Give StoreKit's product request a generous window to resolve one
        // way or the other. Either real product rows or the "temporarily
        // unavailable" empty state is an acceptable landing spot — a
        // loading spinner still on screen after this window is not.
        sleep(10)
        let loadingSpinner = app.descendants(matching: .any)["Loading tip options"]
        XCTAssertFalse(loadingSpinner.exists, "Tip jar is still spinning after 10s — the loading state never resolved")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "TipJar after load"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
