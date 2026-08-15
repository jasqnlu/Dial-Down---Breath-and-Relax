# Cross-Tab Exercise Picking Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `CustomizeRoutineView`'s "Add Exercises" flow (currently a disconnected local sheet, `ExercisePickerSheet`) with a picking mode on the real Exercises tab: tapping "Add Exercises" dismisses Customize, switches to the Exercises tab, and lets the user browse the real region graph with a persistent bottom bar; "Done" merges picks back into Customize.

**Architecture:** A new `ExercisePickingSession` `ObservableObject`, injected app-wide like `DeepLinkRouter`, holds picking state across the tab switch. `CustomizeRoutineView` starts a session and reuses the existing `.browseExercisesRequested` notification (already used by `SessionPlayerView` for the identical "dismiss + switch to Exercises tab" need) to get there. Leaf-level exercise taps (inside `ExerciseGroupCorpusSheet` and `ExerciseListView`'s search grid) branch on `pickingSession.isActive`. A new `.exercisePickingFinished` notification closes the loop: `HomeView` switches back to tab 0, `TodayView` re-presents `CustomizeRoutineView` with the merge applied.

**Tech Stack:** SwiftUI, Combine (`ObservableObject`), `NotificationCenter`, Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-14-roadmap-carousel-exercise-picking-design.md` (all sections except the RoadmapWave-carousel-specific parts of "Decisions" and "Architecture").

## Global Constraints

- `CustomizeRoutineView` is only ever presented from `TodayView` (confirmed by grep across the app target) — "Done" always returns to tab 0; no need to track or restore an "origin tab."
- The picking-mode bottom bar reflects **only the newly-picked exercises this session** (`pickingSession.picked`), never combined with the routine's pre-existing base list.
- Picking mode persists across tab switches — nothing but "Done" (or an explicit cancel, not exposed in UI yet) ends it.
- The region graph itself (`ExerciseGraphView`'s 8-circle ring, pinch/pan/focus gestures) is unchanged. Picking-mode behavior is scoped to leaf taps only: `ExerciseGroupCorpusSheet`'s `ExerciseGridTile`s and `ExerciseListView`'s search-mode grid. Satellite `ExerciseGroupNode` buttons keep navigating into `ExerciseGroupCorpusSheet` exactly as they do today, regardless of picking mode.
- "Add Exercises" is a labeled toolbar button (`Label("Add Exercises", systemImage: "plus")` with `.titleAndIcon`), not a bare icon — and stays in the toolbar, not the scrolling list (preserves the existing overlap-bug fix documented in `CustomizeRoutineView`'s toolbar comment).
- `ExercisePickerSheet.swift`, `ExercisePickerCandidates.swift`, and `ExercisePickerCandidatesTests.swift` are deleted once their only call site is removed. `MiniRoutineState` is untouched (still used by Body Map).
- Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new/deleted `.swift` files under a synchronized folder need no `project.pbxproj` edits, just filesystem `git add`/`rm`.

---

### Task 1: `ExercisePickingSession` state container

**Files:**
- Create: `Breath - Relax & Stretch/Services/ExercisePickingSession.swift`
- Test: `Breath - Relax & StretchTests/ExercisePickingSessionTests.swift`

**Interfaces:**
- Consumes: `CustomizeRoutineExerciseMerge.appending(_:to:)` (existing, `Views/Home/CustomizeRoutineExerciseMerge.swift`).
- Produces: `ExercisePickingSession: ObservableObject` with `Context` (`title: String`, `isPinned: Bool`, `baseExercises: [Exercise]`), `FinishedResult` (`context: Context`, `merged: [Exercise]`), `@Published isActive: Bool`, `@Published picked: [Exercise]`, `pickedTotalSeconds: Int`, `begin(context:)`, `toggle(_:)`, `isPicked(_:) -> Bool`, `finish() -> FinishedResult?`, `consumeFinished() -> FinishedResult?`, `cancel()`. Used by Tasks 2-6.

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/ExercisePickingSessionTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct ExercisePickingSessionTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name, type: .stretch, targetBodyParts: ["Lower Back"], durationSeconds: duration,
            difficulty: 1, instructions: [], cueStyle: .hold
        )
    }

    private func makeContext(base: [Exercise] = []) -> ExercisePickingSession.Context {
        .init(title: "Wake Up", isPinned: false, baseExercises: base)
    }

    @Test func startsInactiveWithNoPicks() {
        let session = ExercisePickingSession()
        #expect(session.isActive == false)
        #expect(session.picked.isEmpty)
    }

    @Test func beginActivatesAndClearsAnyPriorPicks() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        session.begin(context: makeContext())
        #expect(session.isActive == true)
        #expect(session.picked.isEmpty)
    }

    @Test func toggleAddsThenRemoves() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        let exercise = makeExercise(name: "Shoulder Roll", duration: 30)
        session.toggle(exercise)
        #expect(session.isPicked(exercise) == true)
        #expect(session.picked.count == 1)
        session.toggle(exercise)
        #expect(session.isPicked(exercise) == false)
        #expect(session.picked.isEmpty)
    }

    @Test func pickedTotalSecondsSumsOnlyPickedExercises() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        session.toggle(makeExercise(name: "B", duration: 45))
        #expect(session.pickedTotalSeconds == 75)
    }

    @Test func finishMergesPicksIntoBaseAndDeactivates() {
        let session = ExercisePickingSession()
        let base = [makeExercise(name: "Base", duration: 60)]
        session.begin(context: makeContext(base: base))
        let pickedExercise = makeExercise(name: "New", duration: 30)
        session.toggle(pickedExercise)

        let result = session.finish()

        #expect(result != nil)
        #expect(result?.merged.count == 2)
        #expect(result?.merged.last?.name == "New")
        #expect(session.isActive == false)
        #expect(session.picked.isEmpty)
    }

    @Test func finishSkipsDuplicatesAlreadyInBase() {
        let session = ExercisePickingSession()
        let shared = makeExercise(name: "Shared", duration: 30)
        session.begin(context: makeContext(base: [shared]))
        session.toggle(shared)

        let result = session.finish()

        #expect(result?.merged.count == 1)
    }

    @Test func finishWithNoActiveContextReturnsNil() {
        let session = ExercisePickingSession()
        #expect(session.finish() == nil)
    }

    @Test func consumeFinishedReturnsResultOnceThenNil() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        _ = session.finish()

        #expect(session.consumeFinished() != nil)
        #expect(session.consumeFinished() == nil)
    }

    @Test func cancelDeactivatesAndClearsPicksWithoutMerging() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        session.cancel()
        #expect(session.isActive == false)
        #expect(session.picked.isEmpty)
        #expect(session.finish() == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExercisePickingSessionTests"`
Expected: FAIL — `ExercisePickingSession` does not exist (build error).

- [ ] **Step 3: Implement `ExercisePickingSession`**

Create `Breath - Relax & Stretch/Services/ExercisePickingSession.swift`:

```swift
import Foundation
import Combine

/// Cross-tab picking state for CustomizeRoutineView's "Add Exercises" flow.
/// Unlike `DeepLinkAction` (a one-shot `Identifiable` enum driven through
/// `.sheet(item:)`), this is persistent and mutated by taps arbitrarily
/// deep inside the Exercises tab across any number of tab switches — so it
/// gets its own environment object, injected app-wide alongside
/// `DeepLinkRouter`/`AuthManager`, rather than overloading `DeepLinkAction`.
final class ExercisePickingSession: ObservableObject {
    /// Snapshot of the routine being built, captured when "Add Exercises"
    /// starts a session — carried through the tab switch so Done can
    /// re-present Customize exactly as the user left it, plus the picks.
    struct Context {
        let title: String
        let isPinned: Bool
        let baseExercises: [Exercise]
    }

    struct FinishedResult {
        let context: Context
        let merged: [Exercise]
    }

    @Published private(set) var isActive = false
    @Published private(set) var picked: [Exercise] = []
    private var context: Context?

    /// Set by `finish()`, read (once) by whoever re-presents Customize
    /// after the `.exercisePickingFinished` notification — kept separate
    /// from `isActive`/`picked` (which are cleared by `finish()`) so a
    /// listener that reacts to the notification a beat later still has
    /// something to read.
    @Published private(set) var lastFinished: FinishedResult?

    func begin(context: Context) {
        self.context = context
        picked = []
        isActive = true
    }

    func toggle(_ exercise: Exercise) {
        if let index = picked.firstIndex(where: { $0.uuid == exercise.uuid }) {
            picked.remove(at: index)
        } else {
            picked.append(exercise)
        }
    }

    func isPicked(_ exercise: Exercise) -> Bool {
        picked.contains { $0.uuid == exercise.uuid }
    }

    var pickedTotalSeconds: Int {
        picked.reduce(0) { $0 + $1.durationSeconds }
    }

    @discardableResult
    func finish() -> FinishedResult? {
        guard let context else { return nil }
        let merged = CustomizeRoutineExerciseMerge.appending(picked, to: context.baseExercises)
        let result = FinishedResult(context: context, merged: merged)
        lastFinished = result
        isActive = false
        picked = []
        self.context = nil
        return result
    }

    func consumeFinished() -> FinishedResult? {
        defer { lastFinished = nil }
        return lastFinished
    }

    func cancel() {
        isActive = false
        picked = []
        context = nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExercisePickingSessionTests"`
Expected: PASS, all 10 cases.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/ExercisePickingSession.swift" "Breath - Relax & StretchTests/ExercisePickingSessionTests.swift"
git commit -m "feat(exercises): add ExercisePickingSession cross-tab state container

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: New notification + app-root injection

**Files:**
- Modify: `Breath - Relax & Stretch/Services/AppNotifications.swift`
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift:6-9,84-87`

**Interfaces:**
- Consumes: `ExercisePickingSession` (Task 1).
- Produces: `Notification.Name.exercisePickingFinished`; `ExercisePickingSession` available via `@EnvironmentObject` to every view under `RootView` (Tasks 3-6).

- [ ] **Step 1: Add the notification name**

In `Breath - Relax & Stretch/Services/AppNotifications.swift`, add alongside the existing one:

```swift
import Foundation

extension Notification.Name {
    static let browseExercisesRequested = Notification.Name("browseExercisesRequested")
    /// Posted when the user taps "Done" in the Exercises tab's picking-mode
    /// bottom bar (Views/Exercises/ExerciseListView.swift). HomeView listens
    /// to switch back to the Home tab; TodayView listens to re-present
    /// CustomizeRoutineView with the merged picks.
    static let exercisePickingFinished = Notification.Name("exercisePickingFinished")
}
```

- [ ] **Step 2: Inject `ExercisePickingSession` at the app root**

In `Breath__Relax___StretchApp.swift`, add the `@StateObject` next to the existing ones (line 7-8):

```swift
    @StateObject private var auth = AuthManager.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var pickingSession = ExercisePickingSession()
```

Then add `.environmentObject(pickingSession)` next to the existing environment injections (around line 86-87, inside the `else` branch of `body`):

```swift
                    .environmentObject(auth)
                    .environmentObject(deepLinkRouter)
                    .environmentObject(pickingSession)
```

- [ ] **Step 3: Build to confirm no compile errors**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED (nothing consumes the notification or environment object yet — this task only wires plumbing).

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Services/AppNotifications.swift" "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift"
git commit -m "feat(exercises): add exercisePickingFinished notification + app-root injection

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: `CustomizeRoutineView` starts a picking session

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift`
- Modify: `Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests.swift`

**Interfaces:**
- Consumes: `ExercisePickingSession.begin(context:)` (Task 1), `Notification.Name.browseExercisesRequested` (existing).
- Produces: no new public interface — `CustomizeRoutineView`'s init signature is unchanged.

- [ ] **Step 1: Update the existing rendering tests to inject the environment object**

`CustomizeRoutineViewRenderingTests.swift` currently renders `CustomizeRoutineView` with no environment object. Once this task adds a required `@EnvironmentObject`, those tests will crash at render time unless updated. Update all three test bodies in `Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests.swift` to inject one, e.g.:

```swift
    @Test func rendersWithExercises() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180), makeExercise(name: "Cat-Cow Flow", duration: 90)]
        let view = CustomizeRoutineView(title: "Wake Up", exercises: exercises, isPinned: false, onDone: { _, _ in })
            .environmentObject(ExercisePickingSession())
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }
```

Apply the same `.environmentObject(ExercisePickingSession())` addition to `rendersWithPinnedStateOn` and `rendersWithNoExercises`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests"`
Expected: PASS still (no `@EnvironmentObject` required yet — this step just gets the tests ready ahead of Step 3's change, so nothing should actually break here; confirm green before proceeding).

- [ ] **Step 3: Wire the toolbar button to start picking mode**

In `Views/Home/CustomizeRoutineView.swift`:

Add the environment object next to the existing `@State` properties (after line 22 `@State private var showingPicker = false`):

```swift
    @EnvironmentObject private var pickingSession: ExercisePickingSession
```

Remove `@State private var showingPicker = false` entirely (no longer needed).

Replace the toolbar's `.primaryAction` button (currently):

```swift
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Exercises")
                }
```

with:

```swift
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        pickingSession.begin(context: .init(
                            title: title,
                            isPinned: pinnedToggle,
                            baseExercises: currentExercises
                        ))
                        dismiss()
                        // Same "dismiss + switch to Exercises tab" need
                        // SessionPlayerView already has (Views/Session/
                        // SessionPlayerView.swift) — reusing the existing
                        // notification rather than adding a second one.
                        NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                    } label: {
                        Label("Add Exercises", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                }
```

Remove the `.sheet(isPresented: $showingPicker) { ExercisePickerSheet(...) }` modifier block entirely (currently the last modifier before the closing braces of `body`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests"`
Expected: PASS, all three cases (now genuinely exercising the `@EnvironmentObject` requirement added in Step 3).

- [ ] **Step 5: Build the full target to confirm `ExercisePickerSheet` is now unused (don't delete yet)**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED — `ExercisePickerSheet.swift` still compiles (it's just no longer called from anywhere); deletion happens in Task 6 after Tasks 4-5 add the receiving end.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift" "Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests.swift"
git commit -m "feat(exercises): CustomizeRoutineView starts a picking session on Add Exercises

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Leaf-tap picking mode in the Exercises tab

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift`
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift:388-422` (the private `ExerciseGroupCorpusSheet`)

**Interfaces:**
- Consumes: `ExercisePickingSession.isActive`, `.picked`, `.isPicked(_:)`, `.toggle(_:)`, `.pickedTotalSeconds`, `.finish()` (Task 1); `Notification.Name.exercisePickingFinished` (Task 2); existing `ExerciseGridTile(exercise:badge:onTap:onBadgeTap:)`.
- Produces: no new public interface — both views' external signatures are unchanged; picking mode is read entirely from the environment object.

- [ ] **Step 1: Branch `ExerciseGroupCorpusSheet`'s leaf taps on picking mode**

In `Views/Exercises/ExerciseGraphView.swift`, add the environment object to the private `ExerciseGroupCorpusSheet` struct (currently lines 388-391):

```swift
private struct ExerciseGroupCorpusSheet: View {
    let selected: SelectedExerciseGraphGroup
    let onSelect: (Exercise) -> Void

    @EnvironmentObject private var pickingSession: ExercisePickingSession
```

Replace the tile loop (currently):

```swift
                ForEach(selected.group.exercises, id: \.uuid) { exercise in
                    ExerciseGridTile(exercise: exercise) {
                        onSelect(exercise)
                    }
                }
```

with:

```swift
                ForEach(selected.group.exercises, id: \.uuid) { exercise in
                    ExerciseGridTile(
                        exercise: exercise,
                        badge: pickingSession.isActive ? .add(isSelected: pickingSession.isPicked(exercise)) : .none
                    ) {
                        if pickingSession.isActive {
                            pickingSession.toggle(exercise)
                        } else {
                            onSelect(exercise)
                        }
                    } onBadgeTap: {
                        if pickingSession.isActive { pickingSession.toggle(exercise) }
                    }
                }
```

(The satellite `ExerciseGroupNode` `Button` in `ExerciseGraphView.categoryLayer(pair:categories:center:scale:)`, which pushes into this sheet, is untouched — it keeps navigating into `ExerciseGroupCorpusSheet` the same way regardless of picking mode, per the Global Constraints above.)

- [ ] **Step 2: Branch `ExerciseListView`'s search-mode grid on picking mode**

In `Views/Exercises/ExerciseListView.swift`, add the environment object next to the existing `@State` properties:

```swift
    @EnvironmentObject private var pickingSession: ExercisePickingSession
```

Replace the search-results tile loop inside `content` (currently):

```swift
                        ForEach(searchResults.visible, id: \.uuid) { exercise in
                            ExerciseGridTile(exercise: exercise) {
                                selectedExercise = exercise
                            }
                        }
```

with:

```swift
                        ForEach(searchResults.visible, id: \.uuid) { exercise in
                            ExerciseGridTile(
                                exercise: exercise,
                                badge: pickingSession.isActive ? .add(isSelected: pickingSession.isPicked(exercise)) : .none
                            ) {
                                if pickingSession.isActive {
                                    pickingSession.toggle(exercise)
                                } else {
                                    selectedExercise = exercise
                                }
                            } onBadgeTap: {
                                if pickingSession.isActive { pickingSession.toggle(exercise) }
                            }
                        }
```

- [ ] **Step 3: Add the picking-mode bottom bar**

Still in `ExerciseListView.swift`, add the bar as a `.safeAreaInset(edge: .bottom)` on the same modifier chain as `.floatingTabBarClearance()` (inside the `NavigationStack`'s `VStack`). Insert it right after `.floatingTabBarClearance()`:

```swift
            .floatingTabBarClearance()
            .safeAreaInset(edge: .bottom) {
                if pickingSession.isActive {
                    pickingBar
                }
            }
```

Add the `pickingBar` view and its duration helper as new private members of `ExerciseListView`:

```swift
    private var pickedMinutes: Int {
        pickingSession.picked.isEmpty ? 0 : max(1, Int((Double(pickingSession.pickedTotalSeconds) / 60).rounded()))
    }

    private var pickingBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(pickingSession.picked.count) exercise\(pickingSession.picked.count == 1 ? "" : "s")")
                    .font(.luminaCardTitle)
                Text("\(pickedMinutes) min")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            Spacer(minLength: 8)
            Button {
                pickingSession.finish()
                NotificationCenter.default.post(name: .exercisePickingFinished, object: nil)
            } label: {
                Text("Done")
            }
            .buttonStyle(LuminaPillButtonStyle(kind: .prominent, compact: true))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pickingSession.picked.count) exercises selected, \(pickedMinutes) minutes total. Done")
    }
```

- [ ] **Step 4: Build to confirm no compile errors**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED. (No existing test renders `ExerciseListView` or `ExerciseGraphView` via `ImageRenderer`, confirmed by grep across `Breath - Relax & StretchTests/` before this task — so no test updates are needed here the way Task 3 needed them for `CustomizeRoutineView`.)

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift" "Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift"
git commit -m "feat(exercises): leaf-tap picking mode + bottom bar in the Exercises tab

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: Close the loop — Done returns to Home with picks merged

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/HomeView.swift:47-55`
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`

**Interfaces:**
- Consumes: `Notification.Name.exercisePickingFinished` (Task 2); `ExercisePickingSession.consumeFinished() -> FinishedResult?` (Task 1).
- Produces: no new public interface.

- [ ] **Step 1: `HomeView` switches back to the Home tab on Done**

In `Views/Home/HomeView.swift`, add a second `.onReceive` next to the existing `.browseExercisesRequested` one (currently lines 53-55):

```swift
        .onReceive(NotificationCenter.default.publisher(for: .browseExercisesRequested)) { _ in
            selectedTab = 2
        }
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            selectedTab = 0
        }
```

- [ ] **Step 2: `TodayView` re-presents Customize with the merge applied**

In `Views/Home/TodayView.swift`, add the environment object next to the existing `@State` properties (after line 29 `@State private var pendingShowSessionAfterCustomize = false`):

```swift
    @EnvironmentObject private var pickingSession: ExercisePickingSession
    @State private var customizeOverride: (title: String, exercises: [Exercise], isPinned: Bool)?
```

Change the `CustomizeRoutineView(...)` call inside the `.sheet(isPresented: $showingCustomize, ...)` block (currently lines 146-180) to read from the override when present:

```swift
            CustomizeRoutineView(
                title: customizeOverride?.title ?? timeOfDayFocus.heroTitle,
                exercises: customizeOverride?.exercises ?? sessionExercises,
                isPinned: customizeOverride?.isPinned ?? (timeOfDayFocus == .wakeUp && pinnedSessionExercises != nil),
                onDone: { exercises, pinned in
                    customizeOverride = nil
                    if pinned {
```

(Leave the rest of the existing `onDone` closure body — the pin/unpin `Routine` handling — exactly as-is; only the two lines above change: the three `CustomizeRoutineView` init arguments now source from `customizeOverride` first, and the closure clears it on entry.)

Add a new `.onReceive` next to the existing `.sheet`/`.alert`/`.onAppear` modifiers on `TodayView`'s body (after the `.sheet(isPresented: $showingCustomize, ...)` block):

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.consumeFinished() else { return }
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
```

- [ ] **Step 3: Build to confirm no compile errors**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Manual verification of the full loop in the simulator**

Use the project's `verify` skill to build and launch. From Home: tap Customize → tap "Add Exercises" → confirm the Exercises tab appears with its region graph → tap a region → tap 2-3 tiles (confirm checkmarks + the bottom bar's count/time appear) → switch to another tab and back (confirm the bottom bar and selections are still there) → tap "Done" → confirm you land back on Home with Customize re-presented, its roadmap/list now including the newly-picked exercises, and the original title/pin toggle state preserved.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/HomeView.swift" "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat(exercises): Done returns to Home with picks merged into Customize

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: Delete the now-dead `ExercisePickerSheet` flow

**Files:**
- Delete: `Breath - Relax & Stretch/Views/Home/ExercisePickerSheet.swift`
- Delete: `Breath - Relax & Stretch/Views/Home/ExercisePickerCandidates.swift`
- Delete: `Breath - Relax & StretchTests/ExercisePickerCandidatesTests.swift`

**Interfaces:**
- Consumes: nothing (this task only removes dead code).
- Produces: nothing new.

- [ ] **Step 1: Re-confirm nothing still references these before deleting**

Run:
```bash
grep -rn "ExercisePickerSheet\|ExercisePickerCandidates" --include="*.swift" "Breath - Relax & Stretch" "Breath - Relax & StretchTests"
```
Expected: only the three files' own definitions/self-references — no call sites left in `CustomizeRoutineView.swift` (removed in Task 3) or anywhere else. If anything unexpected shows up, stop and investigate before deleting — do not delete a file something still references.

- [ ] **Step 2: Delete the files**

```bash
git rm "Breath - Relax & Stretch/Views/Home/ExercisePickerSheet.swift" \
       "Breath - Relax & Stretch/Views/Home/ExercisePickerCandidates.swift" \
       "Breath - Relax & StretchTests/ExercisePickerCandidatesTests.swift"
```

- [ ] **Step 3: Build and run the full test suite to confirm nothing broke**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED and the full suite passes (no references to the deleted files remain anywhere, including `MiniRoutineState`/`MiniRoutineStateTests`, which are unaffected — `MiniRoutineState` is Body Map's own state object, unrelated to `ExercisePickerCandidates`).

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(exercises): delete ExercisePickerSheet, now dead after the picking-mode rewire

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```
