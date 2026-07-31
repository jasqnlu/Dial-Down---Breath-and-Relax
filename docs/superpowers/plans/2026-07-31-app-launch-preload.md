# App Launch Preload + Loading Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide the Body Map's first-use "Loading 3D model…" spinner behind a branded app-launch splash that preloads the anatomy mesh, shows a tappable body/stretching trivia fact while it waits, and holds for a short minimum duration so the fact is readable.

**Architecture:** A new `BodyTrivia` static fact list + picker, a new `AppLoadingView` SwiftUI splash reusing existing Lumina branding, and a small `isPreloading` gate added to `BreathRelaxStretchApp` that shows the splash until both `BodyMeshLoader.shared.anatomyParts()` and a 1.5s minimum timer finish, then crossfades into the existing `OnboardingGate { RootView() }` chain unchanged.

**Tech Stack:** SwiftUI, Swift Testing (`@Suite`/`@Test`/`#expect`, `@testable import BreathRelaxStretch`), XCUITest for simulator verification. Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new `.swift` files under `Breath - Relax & Stretch/` or `Breath - Relax & StretchTests/`/`Breath - Relax & StretchUITests/` are picked up automatically, no `.pbxproj` edits needed.

## Global Constraints

- Splash gates ONLY on `BodyMeshLoader.shared.anatomyParts()` + a 1.5s minimum timer — seed migration, Supabase sync, and `OnboardingGate`'s own logic stay exactly as they are today (spec Non-goals).
- Tapping the trivia card swaps the fact but does **not** extend the 1.5s minimum window (spec §1).
- No dismiss button, no determinate progress bar — indeterminate `ProgressView()` only (spec §1).
- Reuse existing Lumina design tokens (`Color.luminaSurface`, `Color.luminaPrimary`, `Color.luminaMintTint`, `Color.luminaOnSurface`, `.luminaDisplay`, `.luminaSubheadline`, `.luminaLabel`, `LuminaRadius.panel`) — no new colors/fonts.
- Hero badge is a `Circle()`, not a rounded square, so it nests inside the visual language already reviewed in `docs/mockups/app-loading-screen.html`.
- Build/test with scheme `BreathRelaxStretch`, destination `platform=iOS Simulator,name=iPhone 17`.

---

### Task 1: `BodyTrivia` fact list + random picker

**Files:**
- Create: `Breath - Relax & Stretch/Models/BodyTrivia.swift`
- Test: `Breath - Relax & StretchTests/BodyTriviaTests.swift`

**Interfaces:**
- Consumes: nothing (pure static data + pure function).
- Produces: `enum BodyTrivia { static let facts: [String]; static func randomFact(excluding current: String? = nil) -> String }` — `AppLoadingView` (Task 2) calls `BodyTrivia.randomFact()` on appear and `BodyTrivia.randomFact(excluding: currentFact)` on tap.

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/BodyTriviaTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

@Suite("Body trivia")
struct BodyTriviaTests {
    @Test("has a curated, non-empty fact list with no duplicates")
    func factListIsCuratedAndUnique() {
        #expect(BodyTrivia.facts.count >= 10)
        #expect(Set(BodyTrivia.facts).count == BodyTrivia.facts.count)
    }

    @Test("randomFact always returns a fact from the curated list")
    func randomFactComesFromCuratedList() {
        for _ in 0..<20 {
            #expect(BodyTrivia.facts.contains(BodyTrivia.randomFact()))
        }
    }

    @Test("randomFact never repeats the excluded fact")
    func randomFactNeverRepeatsExcluded() {
        let current = BodyTrivia.facts[0]
        for _ in 0..<50 {
            #expect(BodyTrivia.randomFact(excluding: current) != current)
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BodyTriviaTests"`
Expected: FAIL to build — `BodyTrivia` does not exist.

- [ ] **Step 3: Write the implementation**

Create `Breath - Relax & Stretch/Models/BodyTrivia.swift`:

```swift
import Foundation

/// Curated, launch-splash trivia about the body, stretching, and breathing —
/// shown one at a time on `AppLoadingView` while the anatomy mesh preloads.
enum BodyTrivia {
    static let facts: [String] = [
        "Your body has over 600 muscles — about 40% of your total body weight.",
        "The hamstrings cross two joints, which is why they're tight for almost everyone.",
        "The masseter, in your jaw, is the strongest muscle for its size.",
        "Fascia, the connective tissue wrapping your muscles, carries almost as many nerve endings as your skin.",
        "A slow exhale switches on your parasympathetic nervous system — the body's built-in calm-down response.",
        "You take roughly 20,000 breaths a day without ever thinking about one.",
        "You're born with 33 vertebrae — nine fuse together by adulthood, leaving 26.",
        "Muscles only pull. Every joint needs an opposing pair just to move both ways.",
        "Fascia takes about 4-6 weeks of consistent stretching to actually lengthen, not just relax.",
        "The soleus, a deep calf muscle, is nicknamed the 'second heart' for how it helps pump blood back up from your legs.",
        "A yawn stretches your jaw and lungs at once — it's thought to help cool and reoxygenate the brain.",
        "Sitting for long stretches is one of the most common causes of tight hip flexors.",
        "Box breathing — inhale, hold, exhale, hold, each for 4 counts — is used by Navy SEALs to stay calm under pressure.",
        "Your diaphragm does about 70% of the work in a normal breath.",
        "Cats and dogs stretch right after waking for the same reason you do — it resets muscle tone after stillness.",
        "The IT band isn't a muscle at all — it's a thick strip of fascia running from hip to shin.",
        "Holding a stretch for about 30 seconds gives the stretch reflex time to relax into a real release.",
    ]

    /// A random fact, guaranteed different from `current` when more than one
    /// fact exists (falls back to the only fact when there's just one).
    static func randomFact(excluding current: String? = nil) -> String {
        guard facts.count > 1 else { return facts[0] }
        var next = facts.randomElement()!
        while next == current {
            next = facts.randomElement()!
        }
        return next
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BodyTriviaTests"`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/BodyTrivia.swift" "Breath - Relax & StretchTests/BodyTriviaTests.swift"
git commit -m "feat(launch): add curated body/stretching trivia fact list"
```

---

### Task 2: `AppLoadingView` splash screen

**Files:**
- Create: `Breath - Relax & Stretch/Views/Launch/AppLoadingView.swift`

**Interfaces:**
- Consumes: `BodyTrivia.facts`, `BodyTrivia.randomFact(excluding:)` (Task 1); `Color.luminaSurface`, `Color.luminaPrimary`, `Color.luminaMintTint`, `Color.luminaOnSurface`, `Color.luminaOnSurfaceVariant`, `Font.luminaDisplay`, `Font.luminaSubheadline`, `Font.luminaLabel`, `LuminaRadius.panel` (all existing, from `Views/Theme/LuminaTheme.swift`).
- Produces: `struct AppLoadingView: View` with a no-argument initializer — Task 3 instantiates it as `AppLoadingView()`, no parameters, no callbacks (it has no dismiss action; the app-level gate controls when it's removed from the view tree).

This view has no business logic to unit test (pure layout + local `@State` for the displayed fact); it's verified visually in Task 4. This step is still TDD-adjacent in spirit: build-verify after writing.

- [ ] **Step 1: Write the view**

Create `Breath - Relax & Stretch/Views/Launch/AppLoadingView.swift`:

```swift
import SwiftUI

/// Shown at app launch while `BodyMeshLoader` preloads the anatomy mesh, so
/// Body Map never has to show its own "Loading 3D model…" spinner later.
/// Purely a launch-time gate — no dismiss action; `BreathRelaxStretchApp`
/// removes it from the view tree once preloading finishes (see
/// `docs/superpowers/specs/2026-07-31-app-launch-preload-design.md`).
struct AppLoadingView: View {
    @State private var currentFact = BodyTrivia.randomFact()

    var body: some View {
        ZStack {
            Color.luminaSurface.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.luminaMintTint)
                        .frame(width: 76, height: 76)
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.luminaPrimary)
                }

                Text("Breath: Relax & Stretch")
                    .font(.luminaDisplay)
                    .foregroundStyle(Color.luminaOnSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                ProgressView()
                    .controlSize(.large)
                    .tint(Color.luminaPrimary)

                triviaCard
            }
            .padding(.horizontal, 24)
        }
    }

    private var triviaCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("Did you know?")
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
            }
            .font(.luminaLabel)
            .foregroundStyle(Color.luminaPrimary)

            Text(currentFact)
                .id(currentFact)
                .transition(.opacity)
                .font(.luminaSubheadline)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: 280)
        .background(Color.luminaMintTint.opacity(0.78), in: RoundedRectangle(cornerRadius: LuminaRadius.panel))
        .contentShape(RoundedRectangle(cornerRadius: LuminaRadius.panel))
        // Explicit label/value (not the raw combined child texts) so this
        // reads as one stable VoiceOver element regardless of which random
        // fact is showing — also gives AppLoadingViewUITest (Task 4) a
        // predictable query target. See the repo's `verify` skill: a
        // container with an explicit `.accessibilityLabel` replaces its
        // child texts in the XCUI hierarchy, so query the container's own
        // label, not `staticTexts`.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Body trivia fact")
        .accessibilityValue(currentFact)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to show another fact")
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentFact = BodyTrivia.randomFact(excluding: currentFact)
            }
        }
    }
}

// MARK: - Preview

#Preview { AppLoadingView() }
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Launch/AppLoadingView.swift"
git commit -m "feat(launch): add AppLoadingView splash with tappable trivia card"
```

---

### Task 3: Wire the preload gate into `BreathRelaxStretchApp`

**Files:**
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`

**Interfaces:**
- Consumes: `AppLoadingView()` (Task 2), `BodyMeshLoader.shared.anatomyParts()` (existing `actor BodyMeshLoader` in `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift:70-91`, internal-visibility, no import needed — same module).
- Produces: nothing new consumed elsewhere — this is the top of the view tree.

- [ ] **Step 1: Add the `isPreloading` state property**

In `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`, find:

```swift
    @AppStorage("seedDataVersion") private var seedDataVersion: Int = 0
```

Add directly above it:

```swift
    /// Gates the splash (`AppLoadingView`) until the anatomy mesh is warm and
    /// a minimum readable duration has elapsed. See `minimumSplashDuration`.
    @State private var isPreloading = true
    private static let minimumSplashDuration: UInt64 = 1_500_000_000 // 1.5s, in nanoseconds

    @AppStorage("seedDataVersion") private var seedDataVersion: Int = 0
```

- [ ] **Step 2: Replace the `body` scene to gate on `isPreloading`**

Find the existing `body` property:

```swift
    var body: some Scene {
        WindowGroup {
            OnboardingGate {
                RootView()
            }
            .preferredColorScheme(resolvedColorScheme)
            .environmentObject(auth)
            .environmentObject(deepLinkRouter)
            .onAppear {
                let freshInstall = seedIfNeeded()
                migrateSeedIfNeeded()
                if freshInstall {
                    // A first-ever launch already has all the content — don't
                    // greet new users with a "New Content Added" alert.
                    notifiedSeedVersion = seedDataVersion
                } else if notifiedSeedVersion < Self.latestContentSeedVersion {
                    // Only greet users about versions that actually added new
                    // exercises. Data-only migrations (e.g. v5's isBilateral
                    // flag) bump seedDataVersion but shouldn't pop the alert.
                    showNewContentAlert = true
                }
                if Self.didFallBackToInMemoryStore {
                    showDataNotSavingAlert = true
                }
            }
            .alert("New Content Added", isPresented: $showNewContentAlert) {
                Button("Got it") { notifiedSeedVersion = seedDataVersion }
            } message: {
                Text("New stretches were added covering every muscle group — find them in the Exercises tab.")
            }
            .alert("Changes Won't Be Saved", isPresented: $showDataNotSavingAlert) {
                Button("OK") {}
            } message: {
                Text("Your saved data couldn't be opened, so this session is running in a temporary mode — anything you do now will be lost when you close the app. Reopening the app again may restore normal saving.")
            }
            .task { await syncRemoteCatalog() }
            .onOpenURL { url in
                deepLinkRouter.handle(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
```

Replace it with:

```swift
    var body: some Scene {
        WindowGroup {
            Group {
                if isPreloading {
                    AppLoadingView()
                        .transition(.opacity)
                } else {
                    OnboardingGate {
                        RootView()
                    }
                    .preferredColorScheme(resolvedColorScheme)
                    .environmentObject(auth)
                    .environmentObject(deepLinkRouter)
                    .onAppear {
                        let freshInstall = seedIfNeeded()
                        migrateSeedIfNeeded()
                        if freshInstall {
                            // A first-ever launch already has all the content — don't
                            // greet new users with a "New Content Added" alert.
                            notifiedSeedVersion = seedDataVersion
                        } else if notifiedSeedVersion < Self.latestContentSeedVersion {
                            // Only greet users about versions that actually added new
                            // exercises. Data-only migrations (e.g. v5's isBilateral
                            // flag) bump seedDataVersion but shouldn't pop the alert.
                            showNewContentAlert = true
                        }
                        if Self.didFallBackToInMemoryStore {
                            showDataNotSavingAlert = true
                        }
                    }
                    .alert("New Content Added", isPresented: $showNewContentAlert) {
                        Button("Got it") { notifiedSeedVersion = seedDataVersion }
                    } message: {
                        Text("New stretches were added covering every muscle group — find them in the Exercises tab.")
                    }
                    .alert("Changes Won't Be Saved", isPresented: $showDataNotSavingAlert) {
                        Button("OK") {}
                    } message: {
                        Text("Your saved data couldn't be opened, so this session is running in a temporary mode — anything you do now will be lost when you close the app. Reopening the app again may restore normal saving.")
                    }
                    .task { await syncRemoteCatalog() }
                    .onOpenURL { url in
                        deepLinkRouter.handle(url)
                    }
                }
            }
            .task {
                async let meshWarm: Void = warmBodyMesh()
                async let minimumDelay: Void = pauseForReadability()
                await meshWarm
                await minimumDelay
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPreloading = false
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Launch preload

    /// Warms `BodyMeshLoader`'s in-memory cache so the first `BodySceneView`
    /// the user opens never has to parse the 12MB anatomy OBJ itself. Result
    /// is discarded — a parse failure just means `BodySceneView` falls back
    /// to its existing "3D Model Unavailable" state later, on demand.
    private func warmBodyMesh() async {
        _ = await BodyMeshLoader.shared.anatomyParts()
    }

    /// Keeps the splash up for at least `minimumSplashDuration` even when the
    /// mesh preloads faster than that, so the trivia fact is readable.
    private func pauseForReadability() async {
        try? await Task.sleep(nanoseconds: Self.minimumSplashDuration)
    }
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Run the existing test suite to confirm no regressions**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: PASS (all existing tests + the new `BodyTriviaTests` from Task 1).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift"
git commit -m "feat(launch): gate app startup on AppLoadingView until mesh preload + 1.5s minimum"
```

---

### Task 4: Simulator verification (UITest + manual screenshot check)

**Files:**
- Create: `Breath - Relax & StretchUITests/AppLoadingViewUITest.swift`

**Interfaces:**
- Consumes: nothing from app code directly — drives the app as a black box via `XCUIApplication()`, per `.claude/skills/verify/SKILL.md`.
- Produces: nothing consumed by later tasks — this is the terminal verification task.

- [ ] **Step 1: Write the UITest**

Create `Breath - Relax & StretchUITests/AppLoadingViewUITest.swift`:

```swift
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
        XCTAssertTrue(triviaCard.waitForExistence(timeout: 2), "Trivia card should appear on cold launch")

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
```

- [ ] **Step 2: Run the UITest and export screenshots**

Run:
```bash
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/AppLoadingViewUITest" -resultBundlePath /tmp/app-loading-verify.xcresult
```
Expected: `Test case '-[AppLoadingViewUITest testSplashShowsTriviaThenDismisses]' passed`.

Then export and inspect the screenshots:
```bash
xcrun xcresulttool export attachments --path /tmp/app-loading-verify.xcresult --output-path /tmp/app-loading-verify-screens
```
Read `01-splash-with-trivia.png` (via the manifest's `suggestedHumanReadableName`) and confirm visually: circular lung badge, wordmark, spinner, and a readable trivia fact, styled per `docs/mockups/app-loading-screen.html`.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & StretchUITests/AppLoadingViewUITest.swift"
git commit -m "test(launch): UITest verifying splash shows trivia and dismisses"
```
