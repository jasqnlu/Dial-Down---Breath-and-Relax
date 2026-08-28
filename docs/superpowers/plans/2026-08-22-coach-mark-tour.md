# Coach-Mark App Tour Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static `AppGuideView` slide carousel with a live, anchor-based coach-mark tour that walks the user through the real app — dimmed background, spotlight cutout, tooltip — auto-navigating across tabs, with one genuinely interactive step on the body map.

**Architecture:** A `TourCoordinator` (`ObservableObject`, environment-injected) owns a static `[TourStep]` catalog and a step-index state machine. Real UI elements tag themselves with `.tourAnchor(id:)`, publishing their frame into a `PreferenceKey`. One `TourSpotlightOverlay`, hosted in `HomeView`'s `ZStack`, reads that dictionary and renders the dim/cutout/tooltip for whatever step is current. `HomeView` and `ProfileView` each observe `coordinator.currentStep` to drive their own tab state, reusing state they already own rather than adding new sources of truth.

**Tech Stack:** SwiftUI (`PreferenceKey`/`anchorPreference`/`overlayPreferenceValue`, `ObservableObject`), Swift Testing (`@testable import BreathRelaxStretch`).

**Spec:** `docs/superpowers/specs/2026-08-22-coach-mark-tour-design.md`

## Global Constraints

- Replaces `AppGuideView`/`AppGuideContent` entirely — do not leave the old carousel reachable from anywhere once this plan finishes.
- Visual style uses the existing Lumina theme (`Color.luminaSurface`/`luminaPrimary`/`luminaCardFill`/`luminaOnSurface`/`luminaOnSurfaceVariant`/`luminaMintTint`/`luminaOutline`, `LuminaPillButtonStyle`, `LuminaRadius.card`, `.luminaTitle`/`.luminaBody`/`.luminaCaption` fonts) — no new color or font tokens.
- The tour auto-navigates: switching to a step with a non-nil `tabIndex` switches the real tab/section itself; the user only taps Next/Back/Skip, except the two body-map steps which wait for a real tap.
- "Skip" jumps to the next section (next tab's first step); a separate small "X" exits the tour entirely at any step.
- Toolbar-hosted callouts (`ToolbarItem` content) use `TourStep.fixedFrame`, not `.tourAnchor` — `NavigationStack`'s UIKit bridge does not reliably forward SwiftUI preferences from toolbar content to ancestors outside the stack (same class of issue as the documented `floatingTabBarClearance` gotcha).
- Same two trigger points as today: auto-shown once after onboarding (gated by the existing `hasSeenAppGuide` flag), replayable from Profile → Settings → Help.
- 19-step catalog, grouped into 6 sections by tab — see the spec's step table for the authoritative id/tabIndex/interactive list.

---

## File Structure

**New:**
- `Views/Onboarding/TourCoordinator.swift` — `TourStep` model, the 19-step catalog, `TourCoordinator` state machine
- `Views/Onboarding/TourAnchorPreference.swift` — `PreferenceKey`, `.tourAnchor(id:)` modifier, shared coordinate-space name
- `Views/Onboarding/TourSpotlightOverlay.swift` — dim/cutout rendering + Lumina tooltip card

**Removed (Task 13):**
- `Views/Onboarding/AppGuideView.swift`
- `Views/Onboarding/AppGuideContent.swift`

**Modified:** `Breath__Relax___StretchApp.swift`, `Views/Onboarding/OnboardingView.swift`, `Views/Home/HomeView.swift`, `Views/Home/CustomTabBar.swift`, `Views/Home/TodayView.swift`, `Views/BodyMap/BodyMapView.swift`, `Views/BodyMap/BodyMapComponents.swift`, `Views/Exercises/ExerciseListView.swift`, `Views/Breathing/BreathingView.swift`, `Views/Routines/RoutineListView.swift`, `Views/Profile/ProfileView.swift`, `Views/Profile/ProfileAccountTab.swift`, `Views/Profile/ProfileSettingsTab.swift`

**Test:** `Breath - Relax & StretchTests/TourCoordinatorTests.swift`

---

### Task 1: `TourStep` model + step catalog

**Files:**
- Create: `Breath - Relax & Stretch/Views/Onboarding/TourCoordinator.swift`
- Test: `Breath - Relax & StretchTests/TourCoordinatorTests.swift`

**Interfaces:**
- Produces: `TourStep` (struct: `id: String`, `tabIndex: Int?`, `title: String`, `message: String`, `isInteractive: Bool`, `fixedFrame: ((GeometryProxy) -> CGRect)?`), `TourStep.allSteps: [TourStep]` (the 19-step catalog)

- [ ] **Step 1: Write the failing test for the catalog's shape**

```swift
import Testing
@testable import BreathRelaxStretch

struct TourCoordinatorTests {
    @Test func catalogHasNineteenStepsWithUniqueIDs() {
        let steps = TourStep.allSteps
        #expect(steps.count == 19)
        #expect(Set(steps.map(\.id)).count == 19)
    }

    @Test func catalogHasSixSections() {
        let sectionStarts = TourStep.allSteps.filter { $0.tabIndex != nil }
        #expect(sectionStarts.count == 6)
        #expect(sectionStarts.map(\.tabIndex) == [0, 1, 2, 3, 4, 5])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:"Breath - Relax & StretchTests/TourCoordinatorTests"`
Expected: FAIL — `TourStep` does not exist yet (build error).

- [ ] **Step 3: Write `TourStep` and the 19-step catalog**

```swift
import SwiftUI

/// One stop on the coach-mark tour. `id` matches a `.tourAnchor(id:)` tag
/// on the real view being called out (or is used purely as a lookup key
/// for `fixedFrame` steps, which skip anchor tracking entirely — see the
/// spec's "Toolbar items" section for why).
struct TourStep: Identifiable {
    let id: String
    /// Which `HomeView` tab this step needs. `nil` means "stay on whatever
    /// tab the previous step left us on" — every section's first step
    /// carries a tabIndex, no other step does.
    let tabIndex: Int?
    let title: String
    let message: String
    /// True only for the two body-map steps, which wait for a real tap
    /// instead of a Next button.
    let isInteractive: Bool
    /// Screen-relative fallback for the two toolbar-hosted callouts, where
    /// `.tourAnchor` can't cross the `NavigationStack` → `UINavigationController`
    /// boundary reliably. `nil` for every other step, which uses real anchor
    /// tracking instead.
    let fixedFrame: ((GeometryProxy) -> CGRect)?

    init(id: String, tabIndex: Int? = nil, title: String, message: String,
         isInteractive: Bool = false, fixedFrame: ((GeometryProxy) -> CGRect)? = nil) {
        self.id = id
        self.tabIndex = tabIndex
        self.title = title
        self.message = message
        self.isInteractive = isInteractive
        self.fixedFrame = fixedFrame
    }
}

extension TourStep: Equatable {
    // Closures aren't Equatable — steps are uniquely identified by id anyway,
    // so equality only needs to compare that.
    static func == (lhs: TourStep, rhs: TourStep) -> Bool { lhs.id == rhs.id }
}

extension TourStep {
    /// Both toolbar-hosted callouts (the body-map Confirm button and the
    /// Routines "+" button) render in `.primaryAction` placement, which iOS
    /// always docks top-trailing — so one shared fallback rect covers both.
    private static let toolbarPrimaryActionFrame: (GeometryProxy) -> CGRect = { proxy in
        CGRect(x: proxy.size.width - 60, y: proxy.safeAreaInsets.top + 4, width: 44, height: 40)
    }

    static let allSteps: [TourStep] = [
        // MARK: Today
        TourStep(id: "tabbar.today", tabIndex: 0,
                 title: "Today", message: "Start here each day — this is your Today tab."),
        TourStep(id: "today.heroCard",
                 title: "Today's Session", message: "Your picked routine for right now. Customize it or tap Begin to start."),
        TourStep(id: "today.recommended",
                 title: "Recommended for You", message: "More routines picked from your goals — swipe through for other options."),

        // MARK: Body
        TourStep(id: "tabbar.body", tabIndex: 1,
                 title: "Body", message: "Rotate the body and tap an area that's bothering you."),
        TourStep(id: "bodymap.tapMarkAndRegion",
                 title: "Mark a Spot", message: "Tap Mark up top, then tap a spot on the body that feels tense or sore.",
                 isInteractive: true),
        TourStep(id: "bodymap.confirmMark",
                 title: "Confirm It", message: "Tap the checkmark to confirm — if it asks you to pick between a couple of spots, tap the one you meant.",
                 isInteractive: true, fixedFrame: toolbarPrimaryActionFrame),
        TourStep(id: "bodymap.regionResults",
                 title: "Exercises for This Spot", message: "Here's everything that targets the area you picked."),

        // MARK: Exercises
        TourStep(id: "tabbar.exercises", tabIndex: 2,
                 title: "Exercises", message: "Browse the full library any time."),
        TourStep(id: "exercises.search",
                 title: "Search", message: "Search by name, or filter by type with the icon next to it."),
        TourStep(id: "exercises.browseByArea",
                 title: "Browse by Area", message: "Or explore the map below — grouped by body region."),

        // MARK: Breathe
        TourStep(id: "tabbar.breathe", tabIndex: 3,
                 title: "Breathe", message: "Guided breathing patterns, any time you need to reset."),
        TourStep(id: "breathe.patternPicker",
                 title: "Pick a Pattern", message: "Choose the pattern that fits how you're feeling."),
        TourStep(id: "breathe.previewCircle",
                 title: "Preview or Begin", message: "Tap the circle for a one-round preview, or use the controls below to start a full session."),

        // MARK: Routines
        TourStep(id: "tabbar.routines", tabIndex: 4,
                 title: "Routines", message: "Build your own routines or borrow ready-made ones."),
        TourStep(id: "routines.sharedList",
                 title: "Premade Routines", message: "Start from a ready-made routine built around a goal."),
        TourStep(id: "routines.createButton",
                 title: "Create Your Own", message: "Tap + to build a routine from your favorite exercises.",
                 fixedFrame: toolbarPrimaryActionFrame),

        // MARK: Profile
        TourStep(id: "tabbar.profile", tabIndex: 5,
                 title: "Profile", message: "Track your progress and manage settings here."),
        TourStep(id: "profile.stats",
                 title: "Your Stats", message: "Streaks, points, and badges — a running record of your practice."),
        TourStep(id: "profile.restartTour",
                 title: "Come Back Anytime", message: "Restart this tour whenever you like from here. That's the tour — enjoy!"),
    ]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:"Breath - Relax & StretchTests/TourCoordinatorTests"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/TourCoordinator.swift" "Breath - Relax & StretchTests/TourCoordinatorTests.swift"
git commit -m "feat(onboarding): add TourStep model and 19-step tour catalog"
```

---

### Task 2: `TourCoordinator` state machine

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Onboarding/TourCoordinator.swift`
- Test: `Breath - Relax & StretchTests/TourCoordinatorTests.swift`

**Interfaces:**
- Consumes: `TourStep.allSteps` (Task 1)
- Produces: `TourCoordinator` (`ObservableObject`): `isActive: Bool`, `currentStepIndex: Int`, `currentStep: TourStep?`, `stepNumber: Int`, `totalSteps: Int`, `isFirstStepInSection: Bool`, `restart()`, `advance()`, `back()`, `skipToNextSection()`, `finish()`, `notifyInteraction(id: String)`

- [ ] **Step 1: Write the failing tests**

```swift
    private func makeCoordinator() -> TourCoordinator {
        let coordinator = TourCoordinator()
        coordinator.restart()
        return coordinator
    }

    @Test func restartActivatesAtStepZero() {
        let coordinator = makeCoordinator()
        #expect(coordinator.isActive == true)
        #expect(coordinator.currentStepIndex == 0)
        #expect(coordinator.currentStep?.id == "tabbar.today")
    }

    @Test func advanceMovesToNextStep() {
        let coordinator = makeCoordinator()
        coordinator.advance()
        #expect(coordinator.currentStep?.id == "today.heroCard")
    }

    @Test func advanceOnLastStepFinishes() {
        let coordinator = TourCoordinator(steps: [
            TourStep(id: "only", tabIndex: 0, title: "T", message: "M"),
        ])
        coordinator.restart()
        coordinator.advance()
        #expect(coordinator.isActive == false)
    }

    @Test func backStaysWithinASection() {
        let coordinator = makeCoordinator()
        coordinator.advance() // today.heroCard
        coordinator.advance() // today.recommended
        coordinator.back()
        #expect(coordinator.currentStep?.id == "today.heroCard")
        coordinator.back()
        #expect(coordinator.currentStep?.id == "tabbar.today") // first step of the section — back() stops here
        coordinator.back()
        #expect(coordinator.currentStep?.id == "tabbar.today") // no-op past the section boundary
    }

    @Test func skipToNextSectionJumpsToNextTabsFirstStep() {
        let coordinator = makeCoordinator()
        coordinator.advance() // today.heroCard
        coordinator.skipToNextSection()
        #expect(coordinator.currentStep?.id == "tabbar.body")
    }

    @Test func skipFromLastSectionFinishesTheTour() {
        let coordinator = makeCoordinator()
        for _ in 0..<18 { coordinator.advance() } // walk to the last step, profile.restartTour
        coordinator.skipToNextSection()
        #expect(coordinator.isActive == false)
    }

    @Test func notifyInteractionAdvancesOnlyWhenIDMatchesTheCurrentInteractiveStep() {
        let coordinator = makeCoordinator()
        for _ in 0..<4 { coordinator.advance() } // land on bodymap.tapMarkAndRegion
        #expect(coordinator.currentStep?.id == "bodymap.tapMarkAndRegion")

        coordinator.notifyInteraction(id: "some.other.id")
        #expect(coordinator.currentStep?.id == "bodymap.tapMarkAndRegion") // no-op: id doesn't match

        coordinator.notifyInteraction(id: "bodymap.tapMarkAndRegion")
        #expect(coordinator.currentStep?.id == "bodymap.confirmMark") // matches: advances
    }

    @Test func notifyInteractionIsNoOpOnANonInteractiveStep() {
        let coordinator = makeCoordinator() // tabbar.today — not interactive
        coordinator.notifyInteraction(id: "tabbar.today")
        #expect(coordinator.currentStep?.id == "tabbar.today")
    }

    @Test func notifyInteractionIsNoOpWhenTourIsInactive() {
        let coordinator = TourCoordinator()
        coordinator.notifyInteraction(id: "tabbar.today")
        #expect(coordinator.isActive == false)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:"Breath - Relax & StretchTests/TourCoordinatorTests"`
Expected: FAIL — `TourCoordinator` does not exist yet.

- [ ] **Step 3: Write `TourCoordinator`**

Append to `TourCoordinator.swift`:

```swift
/// Drives the coach-mark tour: which step is current, and how
/// Back/Next/Skip/Restart move through the 19-step catalog. Pure state —
/// `TourSpotlightOverlay` renders whatever `currentStep` says, and
/// `HomeView`/`ProfileView` read it to drive their own tab state.
final class TourCoordinator: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var currentStepIndex = 0

    let steps: [TourStep]

    init(steps: [TourStep] = TourStep.allSteps) {
        self.steps = steps
    }

    var currentStep: TourStep? {
        steps.indices.contains(currentStepIndex) ? steps[currentStepIndex] : nil
    }

    var stepNumber: Int { currentStepIndex + 1 }
    var totalSteps: Int { steps.count }

    /// True on the first step of the tour, or any step that switches tabs —
    /// `back()` refuses to walk past this, so it never re-triggers a
    /// backward tab switch.
    var isFirstStepInSection: Bool {
        guard currentStepIndex > 0 else { return true }
        return steps[currentStepIndex].tabIndex != nil
    }

    func restart() {
        currentStepIndex = 0
        isActive = true
    }

    func advance() {
        guard isActive else { return }
        if currentStepIndex >= steps.count - 1 {
            finish()
        } else {
            currentStepIndex += 1
        }
    }

    func back() {
        guard isActive, !isFirstStepInSection else { return }
        currentStepIndex -= 1
    }

    /// Jumps to the next section's first step (the next step with a
    /// non-nil tabIndex different from the current section's), or finishes
    /// the tour if already in the last section.
    func skipToNextSection() {
        guard isActive else { return }
        let currentTab = sectionTab(atOrBefore: currentStepIndex)
        let remaining = steps[(currentStepIndex + 1)...]
        if let nextIndex = remaining.firstIndex(where: { $0.tabIndex != nil && $0.tabIndex != currentTab }) {
            currentStepIndex = nextIndex
        } else {
            finish()
        }
    }

    func finish() {
        isActive = false
    }

    /// Real views call this when the user performs the action an
    /// interactive step is waiting for. No-op unless the current step is
    /// interactive and its id matches — so a stray call from an unrelated
    /// screen, or a call after the tour already moved on, does nothing.
    func notifyInteraction(id: String) {
        guard isActive, let step = currentStep, step.isInteractive, step.id == id else { return }
        advance()
    }

    /// Walks backward from `index` to the most recent step that declared a
    /// tabIndex — needed because most steps in a section (including both
    /// interactive body-map steps) carry `tabIndex == nil`.
    private func sectionTab(atOrBefore index: Int) -> Int? {
        for i in stride(from: index, through: 0, by: -1) {
            if let tab = steps[i].tabIndex { return tab }
        }
        return nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:"Breath - Relax & StretchTests/TourCoordinatorTests"`
Expected: PASS (11 tests)

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/TourCoordinator.swift" "Breath - Relax & StretchTests/TourCoordinatorTests.swift"
git commit -m "feat(onboarding): add TourCoordinator step state machine"
```

---

### Task 3: `.tourAnchor` preference plumbing

**Files:**
- Create: `Breath - Relax & Stretch/Views/Onboarding/TourAnchorPreference.swift`

**Interfaces:**
- Produces: `tourCoordinateSpace: String`, `TourAnchorPreferenceKey` (`PreferenceKey`, `[String: Anchor<CGRect>]`), `View.tourAnchor(_ id: String) -> some View`

No automated test here — `Anchor<CGRect>` values can only be produced by SwiftUI's own layout pass, not fabricated in a unit test. This task's implementation is verified visually in Task 5, once something is actually hosting the overlay.

- [ ] **Step 1: Write the file**

```swift
import SwiftUI

/// The coordinate space every `.tourAnchor` frame and `TourSpotlightOverlay`
/// agree on. `TourSpotlightOverlay` declares it (in `HomeView`'s ZStack);
/// every `.tourAnchor` below that point in the tree resolves against it
/// regardless of nesting depth.
let tourCoordinateSpace = "tourSpace"

struct TourAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Tags this view as a coach-mark target. `TourSpotlightOverlay` looks
    /// up the reported frame by `id` to know where to cut the spotlight and
    /// place the tooltip.
    func tourAnchor(_ id: String) -> some View {
        anchorPreference(key: TourAnchorPreferenceKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }
}
```

- [ ] **Step 2: Build to confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/TourAnchorPreference.swift"
git commit -m "feat(onboarding): add .tourAnchor preference plumbing"
```

---

### Task 4: `TourSpotlightOverlay`

**Files:**
- Create: `Breath - Relax & Stretch/Views/Onboarding/TourSpotlightOverlay.swift`

**Interfaces:**
- Consumes: `TourCoordinator` (Task 2, via `@EnvironmentObject`), `TourAnchorPreferenceKey`/`tourCoordinateSpace` (Task 3)
- Produces: `TourSpotlightOverlay` (a `View` with no init parameters — reads `TourCoordinator` from the environment)

- [ ] **Step 1: Write the file**

```swift
import SwiftUI

/// Dims the screen, cuts a spotlight around the current tour step's target,
/// and shows a Lumina-styled tooltip beside it. Mounted once, inside
/// `HomeView`'s ZStack, above `CustomTabBar` — renders nothing when the
/// tour isn't active.
struct TourSpotlightOverlay: View {
    @EnvironmentObject private var coordinator: TourCoordinator

    var body: some View {
        if coordinator.isActive, let step = coordinator.currentStep {
            GeometryReader { proxy in
                Color.clear
                    .overlayPreferenceValue(TourAnchorPreferenceKey.self) { anchors in
                        let targetRect = resolvedRect(for: step, anchors: anchors, proxy: proxy)
                        ZStack {
                            dimLayer(cutout: targetRect, size: proxy.size)
                            if let targetRect {
                                tooltipCard(step: step, targetRect: targetRect, screenSize: proxy.size)
                            }
                        }
                    }
            }
            .ignoresSafeArea()
            .coordinateSpace(name: tourCoordinateSpace)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: step.id)
        }
    }

    private func resolvedRect(for step: TourStep, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) -> CGRect? {
        if let fixedFrame = step.fixedFrame {
            return fixedFrame(proxy)
        }
        guard let anchor = anchors[step.id] else { return nil }
        return proxy[anchor]
    }

    /// A full-screen dim `Path` with the target rect subtracted via an
    /// even-odd fill. Because the cutout is excluded from the path's own
    /// geometry, SwiftUI's default hit-testing lets taps inside it reach the
    /// real view underneath — no extra hit-testing code needed. This is
    /// what makes the interactive body-map steps work.
    private func dimLayer(cutout: CGRect?, size: CGSize) -> some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: size))
            if let cutout {
                let inset = cutout.insetBy(dx: -8, dy: -8)
                path.addRoundedRect(in: inset, cornerSize: CGSize(width: 16, height: 16))
            }
        }
        .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
    }

    private func tooltipCard(step: TourStep, targetRect: CGRect, screenSize: CGSize) -> some View {
        let placeBelow = targetRect.midY < screenSize.height * 0.55
        let cardWidth = min(screenSize.width - 48, 340)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(step.title)
                    .font(.luminaTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                Spacer()
                Button {
                    coordinator.finish()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                .accessibilityLabel("Exit tour")
            }

            Text(step.message)
                .font(.luminaBody)
                .foregroundStyle(Color.luminaOnSurfaceVariant)

            HStack(spacing: 6) {
                ForEach(0..<coordinator.totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == coordinator.currentStepIndex ? Color.luminaPrimary : Color.luminaOutline)
                        .frame(width: index == coordinator.currentStepIndex ? 16 : 6, height: 6)
                }
            }
            .accessibilityLabel("Step \(coordinator.stepNumber) of \(coordinator.totalSteps)")

            HStack(spacing: 10) {
                if !coordinator.isFirstStepInSection {
                    Button("Back") { coordinator.back() }
                        .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))
                }

                Button("Skip") { coordinator.skipToNextSection() }
                    .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))

                Spacer(minLength: 0)

                if !step.isInteractive {
                    Button(coordinator.stepNumber == coordinator.totalSteps ? "Done" : "Next") {
                        coordinator.advance()
                    }
                    .buttonStyle(LuminaPillButtonStyle(compact: true))
                }
            }
        }
        .padding(20)
        .frame(width: cardWidth, alignment: .leading)
        .background(Color.luminaCardFill, in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
        .position(
            x: screenSize.width / 2,
            y: placeBelow
                ? min(targetRect.maxY + 110, screenSize.height - 140)
                : max(targetRect.minY - 110, 140)
        )
    }
}

// MARK: - Preview

#Preview {
    let coordinator = TourCoordinator()
    coordinator.restart()
    return ZStack {
        Color.luminaSurface.ignoresSafeArea()
        TourSpotlightOverlay()
    }
    .environmentObject(coordinator)
}
```

- [ ] **Step 2: Build to confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Check the preview**

Open `TourSpotlightOverlay.swift` in Xcode and check the canvas preview. Since no anchors are registered in the preview, `targetRect` will be `nil` and only the flat dim layer renders — confirms the file compiles and the dim color/opacity read correctly. Full spotlight-cutout + tooltip verification happens in Task 5, once `HomeView` actually hosts real anchors.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/TourSpotlightOverlay.swift"
git commit -m "feat(onboarding): add TourSpotlightOverlay dim/cutout/tooltip rendering"
```

---

### Task 5: Wire `TourCoordinator` into the app root, `OnboardingGate`, and `HomeView`

**Files:**
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`
- Modify: `Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/HomeView.swift`

**Interfaces:**
- Consumes: `TourCoordinator` (Task 2), `TourSpotlightOverlay` (Task 4)

- [ ] **Step 1: Inject `TourCoordinator` at the app root**

In `Breath__Relax___StretchApp.swift`, alongside the existing `@StateObject` properties (near line 7-9):

```swift
    @StateObject private var auth = AuthManager.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var pickingSession = ExercisePickingSession()
    @StateObject private var tourCoordinator = TourCoordinator()
```

And alongside the existing `.environmentObject` calls (near line 87-89):

```swift
                    .environmentObject(auth)
                    .environmentObject(deepLinkRouter)
                    .environmentObject(pickingSession)
                    .environmentObject(tourCoordinator)
```

- [ ] **Step 2: Swap `OnboardingGate`'s sheet for a live-start**

Replace the whole `OnboardingGate` struct in `OnboardingView.swift`:

```swift
struct OnboardingGate<Content: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenAppGuide") private var hasSeenAppGuide = false
    @EnvironmentObject private var tourCoordinator: TourCoordinator
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if hasCompletedOnboarding {
            content
                .onAppear {
                    // The tour runs live, in HomeView's own ZStack — it can't
                    // be a sheet, since it needs to switch real tabs
                    // underneath itself. `hasSeenAppGuide` only gates whether
                    // it *auto*-starts; TourCoordinator.finish() is what
                    // actually ends it later.
                    guard !hasSeenAppGuide else { return }
                    hasSeenAppGuide = true
                    tourCoordinator.restart()
                }
        } else {
            OnboardingView()
        }
    }
}
```

- [ ] **Step 3: Host the overlay in `HomeView` and drive `selectedTab` from it**

In `HomeView.swift`, add the environment object near the other `@EnvironmentObject` declarations (near line 5-7):

```swift
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var router: DeepLinkRouter
    @EnvironmentObject private var pickingSession: ExercisePickingSession
    @EnvironmentObject private var tourCoordinator: TourCoordinator
```

Add the overlay to the `ZStack` and the tab-driving `.onChange`, right after the existing `CustomTabBar`:

```swift
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 10)

            TourSpotlightOverlay()
        }
        .onChange(of: tourCoordinator.currentStep?.tabIndex) { _, tab in
            if let tab { selectedTab = tab }
        }
        .onChange(of: selectedTab) { _, tab in
```

(That last line is the existing `.onChange(of: selectedTab)` handler already in the file — the new `.onChange(of: tourCoordinator...)` is inserted immediately before it, both hanging off the same closing `}` of the outer `ZStack`.)

- [ ] **Step 4: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Manual verification via the `verify` skill**

Launch the app in the simulator with a fresh `hasCompletedOnboarding=true, hasSeenAppGuide=false` state (the `verify` skill's launch-arg injection covers this — see its SKILL.md for the exact args). Confirm:
- The tour auto-starts on Today, dimmed background visible, tooltip showing "Today" / step 1 of 19.
- Tapping Next advances through steps 1-3 without visible target rects yet (no anchors tagged until Task 7) — the dim layer alone rendering correctly is enough to confirm the wiring works; full spotlight-cutout verification happens once anchors exist.
- Tapping the X exits the tour (`coordinator.finish()`), and the app underneath is fully interactive again.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift" "Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift" "Breath - Relax & Stretch/Views/Home/HomeView.swift"
git commit -m "feat(onboarding): wire TourCoordinator into app root, OnboardingGate, and HomeView"
```

---

### Task 6: Tag the tab bar's 6 icons

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/CustomTabBar.swift`

- [ ] **Step 1: Add anchor ids to each tab button**

`CustomTabBar`'s `tabs` array (line 29-36) is in the same order as `TourStep.allSteps`' tab-icon steps (`tabbar.today`, `tabbar.body`, `tabbar.exercises`, `tabbar.breathe`, `tabbar.routines`, `tabbar.profile`). Add an `anchorID` to `TabItem` and thread it through:

```swift
    private struct TabItem {
        let icon: String
        let activeIcon: String
        let label: String
        let anchorID: String
    }

    private let tabs: [TabItem] = [
        TabItem(icon: "sun.max",                activeIcon: "sun.max.fill",            label: "Today",     anchorID: "tabbar.today"),
        TabItem(icon: "figure.stand",          activeIcon: "figure.stand",           label: "Body",       anchorID: "tabbar.body"),
        TabItem(icon: "list.bullet",            activeIcon: "list.bullet",             label: "Exercises",  anchorID: "tabbar.exercises"),
        TabItem(icon: "wind",                   activeIcon: "wind",                    label: "Breathe",    anchorID: "tabbar.breathe"),
        TabItem(icon: "rectangle.stack",        activeIcon: "rectangle.stack.fill",    label: "Routines",   anchorID: "tabbar.routines"),
        TabItem(icon: "person.circle",          activeIcon: "person.circle.fill",      label: "Profile",    anchorID: "tabbar.profile"),
    ]
```

In `tabButton(index:)`, add `.tourAnchor(tab.anchorID)` right before `.buttonStyle(.plain)`:

```swift
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .tourAnchor(tab.anchorID)
        .buttonStyle(.plain)
```

- [ ] **Step 2: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Manual verification**

Restart the tour (Profile → Settings → Help → Restart App Tutorial, once Task 12 lands that wiring — until then, temporarily flip `hasSeenAppGuide` to `false` via the simulator's launch-arg state injection and relaunch, per the `verify` skill). Confirm the step-1 spotlight cutout sits exactly on the Today tab button, and stepping through the tab-bar steps (skipping past the not-yet-tagged content steps once those exist) lands the cutout on each real tab icon in turn.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/CustomTabBar.swift"
git commit -m "feat(onboarding): tag CustomTabBar's 6 icons for the tour"
```

---

### Task 7: Tag Today's hero card and recommended carousel

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`

- [ ] **Step 1: Tag `heroCard`**

The `heroCard` computed property ends with `.clipShape(RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))` (line 416). Add the anchor right after it:

```swift
        .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
        .tourAnchor("today.heroCard")
    }
```

- [ ] **Step 2: Tag `recommendedSection`**

`recommendedSection` wraps its `VStack` conditionally (`if !items.isEmpty`). Add the anchor to the inner `VStack`, right after `RecommendedCarousel(items: items)`:

```swift
            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended for You")
                    .font(.luminaTitle)
                RecommendedCarousel(items: items)
            }
            .tourAnchor("today.recommended")
        }
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Manual verification**

Restart the tour, step past `tabbar.today` to `today.heroCard` and `today.recommended`. Confirm the spotlight cutout matches each real element's on-screen bounds, and — since these sit inside a `ScrollView`, not a `List` — that the cutout stays correctly positioned even if the card is scrolled partway offscreen (SwiftUI's anchor resolves against live layout, so this should track automatically; flag it if it doesn't).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat(onboarding): tag Today's hero card and recommended carousel"
```

---

### Task 8: Body-map anchors and interactive hooks

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift`
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift`

**Interfaces:**
- Consumes: `TourCoordinator.notifyInteraction(id:)` (Task 2)

- [ ] **Step 1: Read `TourCoordinator` from the environment in `BodyMapView`**

Add near the other `@State`/`@StateObject` declarations (line 21-24):

```swift
struct BodyMapView: View {
    @EnvironmentObject private var tourCoordinator: TourCoordinator
    @State private var facing: BodyFacing = .front
```

- [ ] **Step 2: Tag the body silhouette**

The `BodySceneView(...)` call (lines 100-109) already ends with `.frame(maxWidth: .infinity, maxHeight: .infinity)`. Add the anchor:

```swift
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tourAnchor("bodymap.tapMarkAndRegion")
```

- [ ] **Step 3: Hook step 5's unblock into `handleRegionTap`**

```swift
    private func handleRegionTap(region: String, point: SIMD3<Float>) {
        withAnimation(.easeInOut(duration: 0.18)) {
            pendingMark = PendingMark(region: region, point: point)
        }
        impact.impactOccurred()
        tourCoordinator.notifyInteraction(id: "bodymap.tapMarkAndRegion")
    }
```

- [ ] **Step 4: Hook step 6's unblock into `commitAndNavigate`**

`commitAndNavigate` (not `confirmPendingMark`) is the single choke point both the direct-confirm and disambiguate-then-select paths funnel through:

```swift
    private func commitAndNavigate(region: String, point: SIMD3<Float>) {
        markStore.setMark(region: region, sensationID: selectedSensation.id, point: point)
        pendingMark = nil              // persisted mark now carries the dot
        isMarking = false
        exercisesRoute = .confirmed(region)
        tourCoordinator.notifyInteraction(id: "bodymap.confirmMark")
    }
```

- [ ] **Step 5: Tag the results view**

In `BodyMapComponents.swift`, `BodyPartExercisesView`'s `ScrollView` (line 162-177) gets the anchor:

```swift
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if bodyParts.count > 1 {
                            Text(bodyParts.joined(separator: ", "))
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                        if !resolver.direct.isEmpty {
                            exerciseSection(title: "\(resolver.direct.count) exercise\(resolver.direct.count == 1 ? "" : "s")", exercises: resolver.direct)
                        }
                        if !resolver.related.isEmpty {
                            exerciseSection(title: relatedSectionTitle, footer: relatedFooterText, exercises: resolver.related)
                        }
                    }
                    .padding()
                }
                .tourAnchor("bodymap.regionResults")
```

- [ ] **Step 6: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Manual verification**

Restart the tour, step to `tabbar.body`. Confirm:
- Step 5's spotlight sits generally over the body silhouette; tapping Mark then tapping a spot on the body actually advances the tour to step 6 (no Next button should be visible on this step).
- Step 6's spotlight uses the `fixedFrame` rect near the Confirm button (top-trailing) — check it visually lines up close enough to the real button; adjust the offset constants in `TourStep.toolbarPrimaryActionFrame` if it's noticeably off on the test device.
- Tapping Confirm (handling a disambiguation tap if one appears) advances to step 7, whose spotlight now covers the pushed exercises-for-region list.
- Tapping Skip during either interactive step jumps straight to `tabbar.exercises`.

- [ ] **Step 8: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift" "Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift"
git commit -m "feat(onboarding): tag body-map anchors and hook the two interactive steps"
```

---

### Task 9: Exercises anchors

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift`

- [ ] **Step 1: Tag the search bar**

`searchBar` is a computed property (line 174). Wherever it's used in `header` (line 132: `searchBar`), wrap the reference with the anchor instead of touching the property itself, so it stays reusable if referenced elsewhere:

```swift
    private var header: some View {
        HStack(spacing: 10) {
            searchBar
                .tourAnchor("exercises.search")
```

- [ ] **Step 2: Tag the browse content area**

`content` (line 76-124) is a `Group` that shows `ExerciseGraphView` when the search is empty. Add the anchor to the `Group` itself, so the callout covers whichever branch is showing (the graph view is what renders when a fresh tour reaches this step, since search is empty by default):

```swift
    @ViewBuilder
    private var content: some View {
        Group {
            if normalizedSearchText.isEmpty {
                ExerciseGraphView(exercises: exercises, typeFilter: selectedType) { exercise in
                    selectedExercise = exercise
                }
            } else {
                ScrollView {
```

...and after the `Group`'s closing brace (currently line 123-124):

```swift
            }
        }
        .tourAnchor("exercises.browseByArea")
    }
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Manual verification**

Restart the tour, step to `tabbar.exercises`. Confirm the spotlight cutout lands on the search field, then on the browse-by-area graph area.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift"
git commit -m "feat(onboarding): tag exercises search bar and browse-by-area anchors"
```

---

### Task 10: Breathing anchors

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Breathing/BreathingView.swift`

- [ ] **Step 1: Tag `patternPicker` and `circleSection`**

```swift
    private var patternPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BreathingPattern.allCases) { pattern in
                    patternCard(pattern)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .tourAnchor("breathe.patternPicker")
    }
```

`circleSection`'s `VStack` (the same one `patternPicker` sits alongside) closes with a single `.padding(.horizontal, 20)` modifier already applied. Add the anchor after it:

```swift
            }
        }
        .padding(.horizontal, 20)
        .tourAnchor("breathe.previewCircle")
    }
```

(That's the tail of the existing `circleSection` computed property — the closing `}` of its inner phase/round-selector `if`/`else`, then the `}` that closes the outer `VStack(spacing: 20) { ... }` started earlier in the same property, then the existing `.padding(.horizontal, 20)`. Only the `.tourAnchor(...)` line is new.)

- [ ] **Step 2: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Manual verification**

Restart the tour, step to `tabbar.breathe`. Confirm the spotlight lands on the pattern picker, then on the breathing circle.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Breathing/BreathingView.swift"
git commit -m "feat(onboarding): tag breathing pattern picker and preview circle"
```

---

### Task 11: Routines anchors

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`

- [ ] **Step 1: Tag the shared-routines row**

```swift
                Section {
                    NavigationLink(destination: PremadeRoutinesView()) {
                        entryRow(title: "Premade Routines", systemImage: "sparkles")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .tourAnchor("routines.sharedList")
                }
```

- [ ] **Step 2: No tag needed for the create-routine button**

`routines.createButton` uses `fixedFrame` (Task 1's catalog already set this) because the `+` button lives in a `ToolbarItem`. No edit needed here — confirmed by inspecting `.toolbar { ToolbarItem(placement: .primaryAction) { Button { showingBuilder = true } ... } }`, which stays untouched.

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Manual verification**

Restart the tour, step to `tabbar.routines`. Confirm:
- The spotlight for `routines.sharedList` lines up on the "Premade Routines" row. Since this row lives inside a `List` (UICollectionView-bridged), this is the first real check of whether `.tourAnchor` survives that boundary — if the cutout is badly misaligned or missing, that confirms the same class of issue documented for `ToolbarItem`s, and the fix is to switch this step to `fixedFrame` too (a fixed rect near the top of the list, computed the same way as the toolbar steps).
- The spotlight for `routines.createButton` (fixedFrame) sits close to the real `+` button.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift"
git commit -m "feat(onboarding): tag routines shared-list row"
```

---

### Task 12: Profile anchors, inner-tab driving, and restart wiring

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileView.swift`
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileAccountTab.swift`
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift`

**Interfaces:**
- Consumes: `TourCoordinator` (Task 2)

- [ ] **Step 1: Drive `ProfileView`'s inner tab from the tour**

`ProfileView` owns `@State private var selectedTab: ProfileTab`, separate from `HomeView`'s tab index — steps `profile.stats` and `profile.restartTour` need it on `.account` and `.settings` respectively. Add:

```swift
struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var tourCoordinator: TourCoordinator

    @State private var selectedTab: ProfileTab = .account
```

And an `.onChange` alongside the view's existing ones (after `.onAppear { profileImage = loadProfilePhoto() }`, line 91):

```swift
            .onAppear { profileImage = loadProfilePhoto() }
            .onChange(of: tourCoordinator.currentStep?.id) { _, stepID in
                switch stepID {
                case "profile.stats":       selectedTab = .account
                case "profile.restartTour": selectedTab = .settings
                default: break
                }
            }
```

- [ ] **Step 2: Tag the stats section**

In `ProfileAccountTab.swift` (lines 32-41), add the anchor after the `Section`'s closing brace — everything inside is unchanged:

```swift
                Section("Your Stats") {
                    statsRow(icon: "clock.fill",  color: .blue,
                             label: "Total Minutes", value: "\(profile.totalMinutes) min")
                    statsRow(icon: "star.fill",   color: .yellow,
                             label: "Total Points",  value: "\(profile.totalPoints) pts")
                    statsRow(icon: "flame.fill",  color: .orange,
                             label: "Current Streak", value: "\(profile.streak) days")
                    statsRow(icon: "medal.fill",  color: .purple,
                             label: "Badges Earned", value: "\(profile.badges.count)")
                }
                .tourAnchor("profile.stats")
```

- [ ] **Step 3: Tag the restart-tutorial row and point it at the coordinator**

In `ProfileSettingsTab.swift`, remove the now-unused `@State private var showingAppGuide = false` (line 14) and its `.sheet` (lines 293-295), and change the Help section's button:

```swift
            // Help
            Section("Help") {
                Button {
                    tourCoordinator.restart()
                } label: {
                    Label("Restart App Tutorial", systemImage: "questionmark.circle")
                }
            }
            .tourAnchor("profile.restartTour")
```

Add the environment object near the top of the struct:

```swift
struct ProfileSettingsTab: View {
    @EnvironmentObject private var tourCoordinator: TourCoordinator
```

(Check the struct's actual existing property list before inserting — add this line alongside whatever `@AppStorage`/`@State` declarations are already there, don't replace them.)

- [ ] **Step 4: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED — this step should also surface any remaining reference to `AppGuideView`/`showingAppGuide` that needs cleanup before Task 13 removes those files.

- [ ] **Step 5: Manual verification**

Restart the tour (now reachable for real, via Profile → Settings → Help → Restart App Tutorial), step through to `tabbar.profile`. Confirm:
- `profile.stats` switches `ProfileView` to the Account sub-tab and the spotlight lands on the "Your Stats" section — check whether the `List`-hosted anchor resolves correctly here too (same caveat as Task 11's `routines.sharedList`).
- `profile.restartTour` switches to the Settings sub-tab and the spotlight lands on the "Restart App Tutorial" row; tapping Done ends the tour.
- Tapping "Restart App Tutorial" mid-app (tour already finished) restarts the whole 19-step sequence from `tabbar.today`.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Profile/ProfileView.swift" "Breath - Relax & Stretch/Views/Profile/ProfileAccountTab.swift" "Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift"
git commit -m "feat(onboarding): tag profile anchors, drive inner tab, wire restart-tour button"
```

---

### Task 13: Remove `AppGuideView`/`AppGuideContent`

**Files:**
- Delete: `Breath - Relax & Stretch/Views/Onboarding/AppGuideView.swift`
- Delete: `Breath - Relax & Stretch/Views/Onboarding/AppGuideContent.swift`

- [ ] **Step 1: Confirm nothing still references them**

Run: `grep -rn "AppGuideView\|AppGuideContent\|AppGuidePage" "Breath - Relax & Stretch" --include="*.swift"`
Expected: no output (both call sites were migrated in Tasks 5 and 12).

- [ ] **Step 2: Delete the files**

```bash
git rm "Breath - Relax & Stretch/Views/Onboarding/AppGuideView.swift" "Breath - Relax & Stretch/Views/Onboarding/AppGuideContent.swift"
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run the full test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "BreathRelaxStretch" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
Expected: PASS (aside from any pre-existing failures already documented as not-regressions — see `[[exercise_animation_app_integration]]` memory on `CuratedContentIntegrityTests`/UITest-runner if any of those show up)

- [ ] **Step 5: Commit**

```bash
git commit -m "chore(onboarding): remove the superseded AppGuideView slide carousel"
```

---

### Task 14: End-to-end walkthrough verification

**Files:** none — verification only.

- [ ] **Step 1: Full 19-step pass**

Via the `verify` skill, launch with a fresh onboarding-complete/guide-unseen state and walk the entire tour from `tabbar.today` to `profile.restartTour` without using Skip, screenshotting each step. Confirm every spotlight cutout visually matches its real target and every auto-navigated tab switch actually lands on the right screen.

- [ ] **Step 2: Skip and interactive-step behavior**

Restart the tour again. Confirm:
- Skip on a mid-section step (e.g. `today.heroCard`) jumps straight to `tabbar.body`.
- Skip on the interactive `bodymap.tapMarkAndRegion` step also jumps to `tabbar.exercises` (bypassing `bodymap.confirmMark`/`bodymap.regionResults` entirely).
- Skip on the last section (`profile.stats` or `profile.restartTour`) ends the tour the same as Done would.
- The X button ends the tour immediately from any step, and the underlying app is fully interactive afterward (no leftover `.allowsHitTesting(false)` from the dim layer).

- [ ] **Step 3: Report findings**

If any spotlight cutout is misaligned (most likely candidates: the `fixedFrame` toolbar rects from Task 1, or the `List`-hosted anchors flagged as a risk in Tasks 11/12), fix the specific offending constant or switch that step to `fixedFrame`, rebuild, and re-verify just that step — no plan changes needed for a pure positioning tweak.
