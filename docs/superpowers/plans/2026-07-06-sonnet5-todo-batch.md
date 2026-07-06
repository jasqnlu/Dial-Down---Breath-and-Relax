# Sonnet 5 TODO Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship 4 independent features from TODO.md: a session duration multiplier, a get-ready countdown between exercises, a time-aware Today-tab hero session, and a manual-restore streak freeze.

**Architecture:** Each feature is a self-contained workstream touching its own file set (see spec: `docs/superpowers/specs/2026-07-06-sonnet5-todo-batch-design.md`). Tasks 1–3 are SwiftUI view changes with small extracted pure-logic helpers for testability. Tasks 4–5 extend the existing `GamificationService`/`UserProfile` model layer, which already has full Swift Testing coverage to extend.

**Tech Stack:** SwiftUI, SwiftData (`@Model`), Swift Testing (`import Testing`, `@Test`, `#expect`), `@AppStorage` for persisted user prefs.

## Global Constraints

- Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`), NOT XCTest — `@testable import BreathRelaxStretch`.
- The `.xcodeproj` uses `PBXFileSystemSynchronizedRootGroup` — any `.swift` file dropped into `Breath - Relax & StretchTests/` is automatically part of the test target. No `project.pbxproj` editing.
- Build command: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
- Test command (full suite): `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
  - Scope to one suite with e.g. `-only-testing:"Breath - Relax & StretchTests/GamificationServiceTests"`.
- SwiftData `@Model` classes (`UserProfile`) can be instantiated directly in tests without a `ModelContainer` for pure property-logic checks (see existing `GamificationServiceTests.swift`).
- Any new `@Model` property needs an inline default value (CloudKit schema compatibility requirement already followed by every field on `UserProfile`).
- This codebase has **no unit test harness for SwiftUI views** — only services/models are covered by Swift Testing. For the view-only pieces of Tasks 1–3 and all of Task 5, verification is `xcodebuild build` (compiles) plus a manual simulator check after all tasks land (via this project's `verify` skill) — not a unit test. Where a task's logic can be cleanly extracted into a pure, testable function (duration scaling, time-of-day selection), do that extraction and test the pure function; don't try to unit-test SwiftUI state/animation timing itself.

---

### Task 1: Duration multiplier (0.5x / 1x / 2x)

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`
- Test: `Breath - Relax & StretchTests/SessionPlayerViewTests.swift` (new)

**Interfaces:**
- Produces: `SessionPlayerView.scaledDuration(base: Int, multiplier: Double) -> Int` (static, internal access — used only by this task, but visible to tests via `@testable import`).

- [ ] **Step 1: Write the failing test**

Create `Breath - Relax & StretchTests/SessionPlayerViewTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct SessionPlayerViewTests {

    @Test func scaledDurationAppliesMultiplier() {
        #expect(SessionPlayerView.scaledDuration(base: 60, multiplier: 1.0) == 60)
        #expect(SessionPlayerView.scaledDuration(base: 60, multiplier: 0.5) == 30)
        #expect(SessionPlayerView.scaledDuration(base: 60, multiplier: 2.0) == 120)
    }

    @Test func scaledDurationNeverDropsBelowOneSecond() {
        #expect(SessionPlayerView.scaledDuration(base: 1, multiplier: 0.5) == 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SessionPlayerViewTests"`
Expected: FAIL to build — `scaledDuration` doesn't exist yet on `SessionPlayerView`.

- [ ] **Step 3: Add the `@AppStorage` property and the pure scaling function**

In `SessionPlayerView.swift`, add this line next to the other `@AppStorage` properties (currently lines 18–20, right after `@AppStorage("hasSeenInitialPaywall")`):

```swift
    @AppStorage("sessionDurationMultiplier") private var durationMultiplier: Double = 1.0
```

Add this static function anywhere inside the `SessionPlayerView` struct (e.g. right above `startExercise()`):

```swift
    static func scaledDuration(base: Int, multiplier: Double) -> Int {
        max(1, Int(Double(base) * multiplier))
    }
```

- [ ] **Step 4: Use it in `startExercise()`**

Replace the current `startExercise()` body:

```swift
    private func startExercise() {
        let duration = currentExercise?.durationSeconds ?? 60
        secondsRemaining = duration
        phaseEndDate = Date().addingTimeInterval(TimeInterval(duration))
        pausedRemaining = nil
        isPaused = false
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
    }
```

with:

```swift
    private func startExercise() {
        let baseDuration = currentExercise?.durationSeconds ?? 60
        let duration = Self.scaledDuration(base: baseDuration, multiplier: durationMultiplier)
        secondsRemaining = duration
        phaseEndDate = Date().addingTimeInterval(TimeInterval(duration))
        pausedRemaining = nil
        isPaused = false
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
    }
```

- [ ] **Step 5: Add the segmented control to the top bar**

Replace the current top bar `HStack` (inside `playerContent(exercise:)`, currently lines 130–141):

```swift
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(currentIndex + 1) / \(exercises.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
```

with:

```swift
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Speed", selection: $durationMultiplier) {
                    Text("0.5x").tag(0.5)
                    Text("1x").tag(1.0)
                    Text("2x").tag(2.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel("Exercise duration speed")
                Spacer()
                Text("\(currentIndex + 1) / \(exercises.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
```

- [ ] **Step 6: Run test to verify it passes**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SessionPlayerViewTests"`
Expected: PASS (2 tests).

- [ ] **Step 7: Build the whole target to confirm the UI change compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 8: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift" "Breath - Relax & StretchTests/SessionPlayerViewTests.swift"
git commit -m "feat: session duration multiplier (0.5x/1x/2x)"
```

---

### Task 2: Get-ready countdown + auto-skip setting

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift`

**Interfaces:**
- Consumes: nothing from Task 1 (independent — both modify the same file but different regions).
- Produces: `@AppStorage("autoSkipGetReadyCountdown")` flag, read by `SessionPlayerView`.

No unit test for this task — it's async UI transition timing with no existing view-test harness in this codebase (see Global Constraints). Verify by building and by manual simulator check after all tasks land.

- [ ] **Step 1: Add the setting toggle in Profile → Settings**

In `ProfileSettingsTab.swift`, add this line next to the existing `@AppStorage("voiceCuesEnabled")` (line 11):

```swift
    @AppStorage("autoSkipGetReadyCountdown") private var autoSkipGetReadyCountdown = false
```

Replace the current "Session" section (lines 112–121):

```swift
            // Session
            Section {
                Toggle(isOn: $voiceCuesEnabled) {
                    Label("Voice Cues", systemImage: "waveform")
                }
            } header: {
                Text("Session")
            } footer: {
                Text("Announces exercise names and breathing phases aloud during sessions.")
            }
```

with:

```swift
            // Session
            Section {
                Toggle(isOn: $voiceCuesEnabled) {
                    Label("Voice Cues", systemImage: "waveform")
                }
                Toggle(isOn: $autoSkipGetReadyCountdown) {
                    Label("Auto-Skip Get-Ready Countdown", systemImage: "forward.end")
                }
            } header: {
                Text("Session")
            } footer: {
                Text("Announces exercise names and breathing phases aloud during sessions. Auto-skip jumps straight into each exercise without the 3-2-1 countdown.")
            }
```

- [ ] **Step 2: Build to confirm the settings change compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit the settings toggle**

```bash
git add "Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift"
git commit -m "feat: add auto-skip get-ready countdown setting"
```

- [ ] **Step 4: Add get-ready state to `SessionPlayerView`**

Add these properties next to the other `@State` properties (after `@State private var pausedRemaining: TimeInterval? = nil`, currently line 36):

```swift
    @AppStorage("autoSkipGetReadyCountdown") private var autoSkipGetReadyCountdown = false
    @State private var isShowingGetReady = false
    @State private var getReadyExerciseName = ""
    @State private var getReadyCount = 3
```

- [ ] **Step 5: Add `beginNextExercise()` / `runGetReadyCountdown()` / `skipGetReady()`**

Add these functions right above `startExercise()`:

```swift
    private func beginNextExercise() {
        guard !autoSkipGetReadyCountdown, let exercise = currentExercise else {
            startExercise()
            return
        }
        getReadyExerciseName = exercise.name
        getReadyCount = 3
        isShowingGetReady = true
        runGetReadyCountdown()
    }

    private func runGetReadyCountdown() {
        Task { @MainActor in
            while isShowingGetReady, getReadyCount > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard isShowingGetReady else { return }
                getReadyCount -= 1
            }
            guard isShowingGetReady else { return }
            isShowingGetReady = false
            startExercise()
        }
    }

    private func skipGetReady() {
        isShowingGetReady = false
        startExercise()
    }
```

- [ ] **Step 6: Route session start and exercise-advance through `beginNextExercise()`**

In `.onAppear` (currently lines 79–88), replace `startExercise()` with `beginNextExercise()`:

```swift
        .onAppear {
            sessionStarted = Date()
            beginNextExercise()
            impactLight.prepare()
            impactMedium.prepare()
            notifySuccess.prepare()
            UIApplication.shared.isIdleTimerDisabled = true
        }
```

In `advanceToNext(completion:)` (currently lines 238–254), add a `showGetReady` parameter defaulting to `true`, and call `beginNextExercise()` instead of `startExercise()` when it's `true`:

```swift
    private func advanceToNext(completion: Double, showGetReady: Bool = true) {
        totalPointsEarned += GamificationService.points(for: currentExercise, completion: completion)

        if currentIndex + 1 < exercises.count {
            impactMedium.impactOccurred()
            AudioServicesPlaySystemSound(soundTransition)
            currentIndex += 1
            breathTick = 0
            if showGetReady {
                beginNextExercise()
            } else {
                startExercise()
            }
        } else {
            // Session complete
            notifySuccess.notificationOccurred(.success)
            AudioServicesPlaySystemSound(soundComplete)
            saveSession(completion: completion)
            showingSummary = true
        }
    }
```

- [ ] **Step 7: Bypass the countdown during background catch-up**

`catchUpAfterBackground()` fast-forwards through elapsed exercises synchronously — showing a 3-2-1 countdown for each skipped exercise would desync from the async countdown `Task` (the while-loop would race ahead before each countdown finishes). Replace `catchUpAfterBackground()` (currently lines 227–236):

```swift
    private func catchUpAfterBackground() {
        while !showingSummary {
            let remaining = phaseEndDate.timeIntervalSinceNow
            if remaining > 0 {
                secondsRemaining = Int(remaining.rounded(.up))
                break
            }
            advanceToNext(completion: 1.0)
        }
    }
```

with:

```swift
    private func catchUpAfterBackground() {
        while !showingSummary {
            let remaining = phaseEndDate.timeIntervalSinceNow
            if remaining > 0 {
                secondsRemaining = Int(remaining.rounded(.up))
                break
            }
            advanceToNext(completion: 1.0, showGetReady: false)
        }
    }
```

- [ ] **Step 8: Render the get-ready screen**

In `body` (currently lines 54–78), add a branch before the `currentExercise` branch:

```swift
        Group {
            if showingSummary {
                SessionSummaryView(pointsEarned: totalPointsEarned) {
                    onComplete?(totalPointsEarned)
                    dismiss()
                }
            } else if exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "figure.mind.and.body",
                    description: Text("There are no exercises to play.")
                )
                .overlay(alignment: .topLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            } else if isShowingGetReady {
                getReadyView(name: getReadyExerciseName)
            } else if let exercise = currentExercise {
                playerContent(exercise: exercise)
            }
        }
```

Add the new view builder near `playerContent(exercise:)`:

```swift
    @ViewBuilder
    private func getReadyView(name: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Get Ready")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(name)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("\(getReadyCount)")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .monospacedDigit()
            Spacer()
            Button("Skip") { skipGetReady() }
                .buttonStyle(.bordered)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { skipGetReady() }
        .accessibilityLabel("Get ready for \(name), starting in \(getReadyCount)")
        .accessibilityAddTraits(.updatesFrequently)
    }
```

- [ ] **Step 9: Build to confirm everything compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 10: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift"
git commit -m "feat: get-ready countdown between exercises"
```

---

### Task 3: Time-aware Today tab

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`
- Test: `Breath - Relax & StretchTests/GoalMetaTests.swift` (new)
- Test: `Breath - Relax & StretchTests/TodayViewTests.swift` (new)

**Interfaces:**
- Produces: `TodayView.TimeOfDayFocus` enum (`.wakeUp`, `.unwind`, `.none`) with `.heroTitle: String`; `TodayView.timeOfDayFocus(forHour: Int) -> TimeOfDayFocus` (static, internal).
- Consumes: `GoalMeta.recommend(from:activeGoalIDs:limit:)` (existing, unchanged signature) — this task reuses it directly with ad-hoc goal-ID sets (`["wake_up"]` / `["unwind"]`) instead of introducing a new pool type, since `recommend()` already takes an arbitrary `Set<String>` of goal IDs and doesn't care where they came from.

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/GoalMetaTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct GoalMetaTests {

    @Test func wakeUpAndUnwindPoolsExist() {
        #expect(GoalMeta.all.contains { $0.id == "wake_up" })
        #expect(GoalMeta.all.contains { $0.id == "unwind" })
    }

    @Test func wakeUpAndUnwindExerciseNamesExistInSeedData() throws {
        let seedNames = Set(try SeedDataTests.loadExercises().compactMap { $0["name"] as? String })
        let wakeUp = try #require(GoalMeta.all.first { $0.id == "wake_up" })
        let unwind = try #require(GoalMeta.all.first { $0.id == "unwind" })
        for name in wakeUp.exerciseNames + unwind.exerciseNames {
            #expect(seedNames.contains(name), "\(name) not found in SeedData.json")
        }
    }
}
```

Create `Breath - Relax & StretchTests/TodayViewTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct TodayViewTests {

    @Test func morningHoursAreWakeUp() {
        for hour in [5, 7, 10] {
            #expect(TodayView.timeOfDayFocus(forHour: hour) == .wakeUp)
        }
    }

    @Test func eveningAndOvernightHoursAreUnwind() {
        for hour in [20, 22, 23, 0, 2, 4] {
            #expect(TodayView.timeOfDayFocus(forHour: hour) == .unwind)
        }
    }

    @Test func middayHoursHaveNoTimeOfDayOverride() {
        for hour in [11, 14, 19] {
            #expect(TodayView.timeOfDayFocus(forHour: hour) == .none)
        }
    }

    @Test func heroTitlesMatchFocus() {
        #expect(TodayView.TimeOfDayFocus.wakeUp.heroTitle == "Wake Up")
        #expect(TodayView.TimeOfDayFocus.unwind.heroTitle == "Unwind")
        #expect(TodayView.TimeOfDayFocus.none.heroTitle == "Today's session")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/GoalMetaTests" -only-testing:"Breath - Relax & StretchTests/TodayViewTests"`
Expected: FAIL to build — `wake_up`/`unwind` goals and `TodayView.TimeOfDayFocus`/`timeOfDayFocus(forHour:)` don't exist yet.

- [ ] **Step 3: Add the two curated pools to `GoalMeta.all`**

In `ForYouSection.swift`, inside `static let all: [GoalMeta] = [...]` (currently lines 183–237), add two more entries after the existing `better_breathing` entry (before the closing `]`):

```swift
        GoalMeta(
            id: "wake_up",
            displayName: "Wake Up",
            exerciseNames: [
                "Box Breathing",
                "Cat-Cow Flow",
                "Shoulder Roll",
                "Standing Back Extension",
                "Doorway Shoulder & Chest Opener",
                "Seated Neck Rotation",
            ]
        ),
        GoalMeta(
            id: "unwind",
            displayName: "Unwind",
            exerciseNames: [
                "4-7-8 Breathing",
                "Deep Belly Breath",
                "Diaphragmatic Breath with Counting",
                "Child's Pose",
                "Happy Baby Pose",
                "Eye Palming",
            ]
        ),
```

- [ ] **Step 4: Add `TimeOfDayFocus` and the time-of-day selection logic to `TodayView`**

In `TodayView.swift`, add this enum and static function inside the `struct TodayView: View { ... }` body, near the top (after the `@State` properties, before `private var profile`):

```swift
    enum TimeOfDayFocus: Equatable {
        case wakeUp, unwind, none

        var heroTitle: String {
            switch self {
            case .wakeUp: return "Wake Up"
            case .unwind: return "Unwind"
            case .none:   return "Today's session"
            }
        }
    }

    static func timeOfDayFocus(forHour hour: Int) -> TimeOfDayFocus {
        switch hour {
        case 5..<11:         return .wakeUp
        case 20..<24, 0..<5: return .unwind
        default:             return .none
        }
    }

    private var timeOfDayFocus: TimeOfDayFocus {
        Self.timeOfDayFocus(forHour: Calendar.current.component(.hour, from: .now))
    }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/GoalMetaTests" -only-testing:"Breath - Relax & StretchTests/TodayViewTests"`
Expected: PASS (2 + 4 tests).

- [ ] **Step 6: Wire `timeOfDayFocus` into `sessionExercises` and the hero title**

Replace the current `sessionExercises` computed property (currently lines 30–33):

```swift
    private var sessionExercises: [Exercise] {
        let recommended = GoalMeta.recommend(from: exercises, activeGoalIDs: activeGoalIDs, limit: 4)
        return recommended.isEmpty ? Array(exercises.prefix(4)) : recommended
    }
```

with:

```swift
    private var sessionExercises: [Exercise] {
        switch timeOfDayFocus {
        case .wakeUp:
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["wake_up"], limit: 4)
            if !pool.isEmpty { return pool }
        case .unwind:
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["unwind"], limit: 4)
            if !pool.isEmpty { return pool }
        case .none:
            break
        }
        let recommended = GoalMeta.recommend(from: exercises, activeGoalIDs: activeGoalIDs, limit: 4)
        return recommended.isEmpty ? Array(exercises.prefix(4)) : recommended
    }
```

In `heroCard` (currently line 139), replace:

```swift
                    Text("Today's session")
                        .font(.system(.title3, design: .rounded, weight: .bold))
```

with:

```swift
                    Text(timeOfDayFocus.heroTitle)
                        .font(.system(.title3, design: .rounded, weight: .bold))
```

- [ ] **Step 7: Build to confirm everything compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 8: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift" "Breath - Relax & Stretch/Views/Home/TodayView.swift" "Breath - Relax & StretchTests/GoalMetaTests.swift" "Breath - Relax & StretchTests/TodayViewTests.swift"
git commit -m "feat: time-aware Wake Up / Unwind hero session on Today tab"
```

---

### Task 4: Streak freeze — model + service logic

**Files:**
- Modify: `Breath - Relax & Stretch/Models/UserProfile.swift`
- Modify: `Breath - Relax & Stretch/Services/GamificationService.swift`
- Modify: `Breath - Relax & StretchTests/GamificationServiceTests.swift`

**Interfaces:**
- Produces (consumed by Task 5): `UserProfile.streakFreezeTokens: Int`, `UserProfile.pendingStreakBreak: Int`; `GamificationService.checkForBrokenStreak(for: UserProfile) -> Int?`, `GamificationService.restoreStreak(for: UserProfile)`, `GamificationService.dismissStreakBreak(for: UserProfile)`.

- [ ] **Step 1: Write the failing tests**

In `GamificationServiceTests.swift`, replace the existing `makeProfile` helper (currently lines 21–33):

```swift
    private func makeProfile(streak: Int = 0,
                             minutes: Int = 0,
                             points: Int = 0,
                             badges: [String] = [],
                             lastSession: Date? = nil) -> UserProfile {
        let p = UserProfile(profileID: "test", displayName: "Tester")
        p.streak = streak
        p.totalMinutes = minutes
        p.totalPoints = points
        p.badges = badges
        p.lastSessionDate = lastSession
        return p
    }
```

with:

```swift
    private func makeProfile(streak: Int = 0,
                             minutes: Int = 0,
                             points: Int = 0,
                             badges: [String] = [],
                             lastSession: Date? = nil,
                             streakFreezeTokens: Int = 0,
                             pendingStreakBreak: Int = 0) -> UserProfile {
        let p = UserProfile(profileID: "test", displayName: "Tester")
        p.streak = streak
        p.totalMinutes = minutes
        p.totalPoints = points
        p.badges = badges
        p.lastSessionDate = lastSession
        p.streakFreezeTokens = streakFreezeTokens
        p.pendingStreakBreak = pendingStreakBreak
        return p
    }
```

Add this new section at the end of `GamificationServiceTests`, right before the closing `}` of the struct:

```swift

    // MARK: - Streak Freeze

    @Test func noBreakWhenLastSessionWasToday() {
        let p = makeProfile(streak: 5, lastSession: noon(daysAgo: 0))
        #expect(GamificationService.checkForBrokenStreak(for: p) == nil)
        #expect(p.streak == 5)
    }

    @Test func noBreakWhenLastSessionWasYesterday() {
        let p = makeProfile(streak: 5, lastSession: noon(daysAgo: 1))
        #expect(GamificationService.checkForBrokenStreak(for: p) == nil)
        #expect(p.streak == 5)
    }

    @Test func breakDetectedAfterMultipleMissedDays() {
        let p = makeProfile(streak: 6, lastSession: noon(daysAgo: 3))
        #expect(GamificationService.checkForBrokenStreak(for: p) == 6)
        #expect(p.streak == 0)
        #expect(p.pendingStreakBreak == 6)
    }

    @Test func streakOfOneDoesNotTriggerBreakPopup() {
        let p = makeProfile(streak: 1, lastSession: noon(daysAgo: 3))
        #expect(GamificationService.checkForBrokenStreak(for: p) == nil)
        #expect(p.streak == 1)
    }

    @Test func repeatedChecksReturnSamePendingValue() {
        let p = makeProfile(streak: 8, lastSession: noon(daysAgo: 5))
        #expect(GamificationService.checkForBrokenStreak(for: p) == 8)
        p.streak = 999 // something else touched it between checks
        #expect(GamificationService.checkForBrokenStreak(for: p) == 8)
    }

    @Test func restoreStreakSpendsTokenAndRestoresValue() {
        let p = makeProfile(pendingStreakBreak: 6, streakFreezeTokens: 2)
        GamificationService.restoreStreak(for: p)
        #expect(p.streak == 6)
        #expect(p.pendingStreakBreak == 0)
        #expect(p.streakFreezeTokens == 1)
        #expect(Calendar.current.isDateInToday(p.lastSessionDate ?? .distantPast))
    }

    @Test func restoreStreakNoOpWithoutTokens() {
        let p = makeProfile(pendingStreakBreak: 6, streakFreezeTokens: 0)
        GamificationService.restoreStreak(for: p)
        #expect(p.streak == 0)
        #expect(p.pendingStreakBreak == 6)
    }

    @Test func restoreStreakNoOpWithoutPendingBreak() {
        let p = makeProfile(pendingStreakBreak: 0, streakFreezeTokens: 3)
        GamificationService.restoreStreak(for: p)
        #expect(p.streak == 0)
        #expect(p.streakFreezeTokens == 3)
    }

    @Test func dismissStreakBreakClearsPendingWithoutSpendingToken() {
        let p = makeProfile(pendingStreakBreak: 6, streakFreezeTokens: 2)
        GamificationService.dismissStreakBreak(for: p)
        #expect(p.pendingStreakBreak == 0)
        #expect(p.streakFreezeTokens == 2)
        #expect(p.streak == 0)
    }

    @Test func updateStreakClearsStalePendingBreak() {
        let p = makeProfile(streak: 5, lastSession: noon(daysAgo: 1), pendingStreakBreak: 3)
        GamificationService.updateStreak(for: p)
        #expect(p.pendingStreakBreak == 0)
    }

    @Test func freezeTokenAwardedEverySevenSessions() {
        let p = makeProfile(lastSession: noon(daysAgo: 1))
        for _ in 0..<6 {
            GamificationService.updateStreak(for: p)
        }
        #expect(p.streakFreezeTokens == 0)
        #expect(p.sessionsTowardNextFreezeToken == 6)

        GamificationService.updateStreak(for: p)
        #expect(p.streakFreezeTokens == 1)
        #expect(p.sessionsTowardNextFreezeToken == 0)
    }

    @Test func freezeTokensAccumulateUncapped() {
        let p = makeProfile(lastSession: noon(daysAgo: 1))
        for _ in 0..<21 {
            GamificationService.updateStreak(for: p)
        }
        #expect(p.streakFreezeTokens == 3)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/GamificationServiceTests"`
Expected: FAIL to build — `UserProfile.streakFreezeTokens`/`pendingStreakBreak` and the three new `GamificationService` functions don't exist yet.

- [ ] **Step 3: Add the three new fields to `UserProfile`**

Replace `UserProfile.swift` in full:

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var profileID: String = ""
    var displayName: String = ""
    var totalMinutes: Int = 0
    var totalPoints: Int = 0
    var streak: Int = 0
    var lastSessionDate: Date? = nil
    var badges: [String] = []
    var streakFreezeTokens: Int = 0
    var sessionsTowardNextFreezeToken: Int = 0
    var pendingStreakBreak: Int = 0

    init(profileID: String, displayName: String) {
        self.profileID = profileID
        self.displayName = displayName
    }
}
```

- [ ] **Step 4: Update `updateStreak` and add the three new functions to `GamificationService`**

Replace the existing `updateStreak(for:)` (currently lines 22–35):

```swift
    static func updateStreak(for profile: UserProfile) {
        let calendar = Calendar.current
        if let last = profile.lastSessionDate {
            if calendar.isDateInYesterday(last) {
                profile.streak += 1
            } else if !calendar.isDateInToday(last) {
                profile.streak = 1
            }
            // If already completed a session today, don't change streak
        } else {
            profile.streak = 1
        }
        profile.lastSessionDate = Date()
    }
```

with:

```swift
    static func updateStreak(for profile: UserProfile) {
        profile.pendingStreakBreak = 0

        let calendar = Calendar.current
        if let last = profile.lastSessionDate {
            if calendar.isDateInYesterday(last) {
                profile.streak += 1
            } else if !calendar.isDateInToday(last) {
                profile.streak = 1
            }
            // If already completed a session today, don't change streak
        } else {
            profile.streak = 1
        }
        profile.lastSessionDate = Date()

        profile.sessionsTowardNextFreezeToken += 1
        if profile.sessionsTowardNextFreezeToken >= 7 {
            profile.sessionsTowardNextFreezeToken = 0
            profile.streakFreezeTokens += 1
        }
    }

    // MARK: - Streak Freeze

    /// Detects an unresolved break in the streak caused by inactivity (not by
    /// completing a session — that's handled above in `updateStreak`). Call
    /// this on app foreground, not on session completion. Idempotent: once a
    /// break is pending, repeated calls return the same value until resolved
    /// via `restoreStreak` or `dismissStreakBreak`.
    @discardableResult
    static func checkForBrokenStreak(for profile: UserProfile) -> Int? {
        if profile.pendingStreakBreak > 0 { return profile.pendingStreakBreak }
        guard let last = profile.lastSessionDate else { return nil }
        let calendar = Calendar.current
        guard !calendar.isDateInToday(last), !calendar.isDateInYesterday(last) else { return nil }
        guard profile.streak >= 2 else { return nil }
        profile.pendingStreakBreak = profile.streak
        profile.streak = 0
        return profile.pendingStreakBreak
    }

    /// Spends one freeze token to restore the streak lost in
    /// `checkForBrokenStreak`. No-op if there's no pending break or no
    /// tokens banked.
    static func restoreStreak(for profile: UserProfile) {
        guard profile.streakFreezeTokens > 0, profile.pendingStreakBreak > 0 else { return }
        profile.streakFreezeTokens -= 1
        profile.streak = profile.pendingStreakBreak
        profile.pendingStreakBreak = 0
        profile.lastSessionDate = Date()
    }

    /// Acknowledges a lost streak without spending a token.
    static func dismissStreakBreak(for profile: UserProfile) {
        profile.pendingStreakBreak = 0
    }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/GamificationServiceTests"`
Expected: PASS (all cases, including the 12 new ones).

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Models/UserProfile.swift" "Breath - Relax & Stretch/Services/GamificationService.swift" "Breath - Relax & StretchTests/GamificationServiceTests.swift"
git commit -m "feat: streak freeze token earning + manual restore logic"
```

---

### Task 5: Streak freeze — Today tab alert UI

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`

**Interfaces:**
- Consumes: `GamificationService.checkForBrokenStreak(for:)`, `.restoreStreak(for:)`, `.dismissStreakBreak(for:)`, `UserProfile.streakFreezeTokens` (all from Task 4 — this task depends on Task 4 being done first).

No unit test — SwiftUI alert wiring, no view-test harness in this codebase. Verify by building and by manual simulator check.

- [ ] **Step 1: Add `modelContext` and alert state**

In `TodayView.swift`, add these two properties (`modelContext` next to the other `@Environment` properties near the top, `brokenStreakValue` next to the other `@State` properties):

```swift
    @Environment(\.modelContext) private var modelContext
```

```swift
    @State private var brokenStreakValue: Int? = nil
```

- [ ] **Step 2: Check for a broken streak on appear**

Replace the current `.onAppear` block on the outer `NavigationStack`:

```swift
        .onAppear {
            guard !reduceMotion else { return }
            isBreathingIn = true
        }
```

with:

```swift
        .onAppear {
            if !reduceMotion { isBreathingIn = true }
            if let profile {
                brokenStreakValue = GamificationService.checkForBrokenStreak(for: profile)
                try? modelContext.save()
            }
        }
```

- [ ] **Step 3: Add the restore/dismiss alert**

Add this modifier right after the existing `.sheet(isPresented: $showingSession) { ... }` block:

```swift
        .alert(
            "Streak Lost",
            isPresented: Binding(
                get: { brokenStreakValue != nil },
                set: { if !$0 { brokenStreakValue = nil } }
            )
        ) {
            if let profile, profile.streakFreezeTokens > 0 {
                Button("Restore Streak (\(profile.streakFreezeTokens) left)") {
                    GamificationService.restoreStreak(for: profile)
                    try? modelContext.save()
                    brokenStreakValue = nil
                }
            }
            Button("Dismiss", role: .cancel) {
                if let profile {
                    GamificationService.dismissStreakBreak(for: profile)
                    try? modelContext.save()
                }
                brokenStreakValue = nil
            }
        } message: {
            if let brokenStreakValue {
                Text("Your \(brokenStreakValue)-day streak was lost.")
            }
        }
```

- [ ] **Step 4: Build to confirm everything compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat: streak-lost alert with manual restore on Today tab"
```

---

## After all 5 tasks land

Run the full test suite once: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`

Then use this project's `verify` skill to drive all 4 features in the simulator:
1. Start a stretch session, change the speed picker, confirm the next exercise's countdown reflects the new duration.
2. Confirm the get-ready countdown shows before the first exercise and each subsequent one; toggle "Auto-Skip Get-Ready Countdown" in Settings and confirm it's bypassed.
3. Change the simulator clock (or just note current hour) to confirm the Today tab hero shows "Wake Up" / "Unwind" / "Today's session" appropriately.
4. Simulate a broken streak (e.g. set `lastSessionDate` back via debug, or accept a multi-day gap) and confirm the alert appears once, with correct token count, and that Restore/Dismiss behave as designed.
