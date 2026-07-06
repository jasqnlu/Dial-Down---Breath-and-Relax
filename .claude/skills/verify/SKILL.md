---
name: verify
description: How to build, launch, drive, and screenshot the Breath app in the iOS simulator to verify UI changes end-to-end
---

# Verifying Breath app changes in the simulator

## Build / unit tests
- Scheme `BreathRelaxStretch`, destination `platform=iOS Simulator,name=iPhone 17`.
- Unit tests (Swift Testing): `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- Both targets are `PBXFileSystemSynchronizedRootGroup` — dropping a `.swift` file in the folder adds it to the target, no pbxproj edits.

## Driving the UI (this is the part that's non-obvious)
- **No `idb`; `cliclick`/AppleScript taps are silently dropped** (no Accessibility permission). Don't try.
- **Use XCUITest as the driver** (works since 2026-07-06, when `TEST_TARGET_NAME` was fixed to `BreathRelaxStretch` — it pointed at a stale target name and every UI test run died with "UITargetAppPath should be provided").
- Drop a test in `Breath - Relax & StretchUITests/`, run with `-only-testing:"Breath - Relax & StretchUITests/<ClassName>"` and `-resultBundlePath <dir>.xcresult`.
- Skip onboarding/auth with launch arguments (every `@AppStorage`/UserDefaults key works this way):
  `app.launchArguments += ["-hasCompletedOnboarding","YES","-hasSeenAppGuide","YES","-auth.isSignedIn","YES","-auth.provider","guest"]`
- `xcrun simctl uninstall "iPhone 17" com.jasonlu.Breath--Relax---Stretch` first when persisted SwiftData/UserDefaults from a previous run would mask the state under test.

## Capturing evidence
- In the test: `XCTAttachment(screenshot: app.screenshot())`, `lifetime = .keepAlways`, named per stage.
- Export: `xcrun xcresulttool export attachments --path <bundle>.xcresult --output-path <dir>` → PNGs + `manifest.json` (match `suggestedHumanReadableName`), then Read the PNGs.
- Standalone screenshot (no test running): `xcrun simctl io "iPhone 17" screenshot <path>`.

## Gotchas
- Tab bar is the custom floating `CustomTabBar`; buttons match by accessibility label ("Today", "Body", "Exercises", "Breathe", "Routines", "Profile"). Inactive tabs show icon-only but the label still matches.
- A container with `.accessibilityLabel(...)` **replaces its child texts** in the XCUI hierarchy — query the container's label (`app.descendants(matching: .any)["<label>"]`), not the inner `staticTexts`.
- Progress screen lives at Profile tab → "Progress & Charts".
- Occasional `SimError ... server died` noise in teardown logs is simulator-clone cleanup, not a test failure — trust the `Test case ... passed/failed` line.
