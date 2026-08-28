# RoutineBuilder Cross-Tab Picking + Duration Overrides Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `RoutineBuilderView`'s "Add Exercise" button use the same cross-tab picking flow `CustomizeRoutineView` already has (instead of a local sheet), and let each exercise in a routine have its own duration, adjustable in 5-second steps, that actually takes effect during playback.

**Architecture:** Two features land together because both touch `RoutineBuilderView`'s exercise row and the picking-session plumbing. **Duration overrides** (Task 1-3): add `Routine.exerciseDurationOverrides: [UUID: Int]`, a +/− stepper per row in `RoutineBuilderView`, and a single `effectiveDuration(for:)` choke point in `SessionPlayerView` that every duration read goes through. **Cross-tab picking** (Task 4-6): `ExercisePickingSession.Context` gains `originTab`/`editingRoutineID`/`durationOverrides` fields so `HomeView` returns to whichever tab actually started the session (not always Home), and `RoutineBuilderView` gets a new `restoredState` parameter that does a hard **replace** of its form state — not the existing `initialExerciseIDs`/`RoutineIDMerge` **merge** logic, which would wrongly re-union a stale persisted routine's exercises back in and silently discard the user's not-yet-saved edits (see Task 5's design note). This is Phase 4 of 4 from the routines-tab-redesign spec; Phases 1-3 are already merged.

**Tech Stack:** SwiftUI, SwiftData (`Routine` model addition), `NotificationCenter`-based cross-tab coordination (existing `.exercisePickingFinished`/`.browseExercisesRequested` pattern). No new test target — this plan's verification is build + full unit suite, same as prior phases, since none of the touched views (`RoutineBuilderView`, `SessionPlayerView`, `HomeView`, `TodayView`, `RoutineListView`) has direct unit-test coverage of this logic (`CustomizeRoutineViewRenderingTests` only checks rendering, unaffected here).

**Spec:** `docs/superpowers/specs/2026-08-16-routines-tab-redesign-design.md` (sections "RoutineBuilderView — 'Add Exercise' rewiring", "RoutineBuilderView — per-exercise duration stepper", "SessionPlayerView — threading overrides into playback")

## Global Constraints

- Duration floor: 5 seconds. Step size: 5 seconds.
- `Routine.exerciseDurationOverrides: [UUID: Int] = [:]` — absent key means "use the exercise's own `durationSeconds`."
- Duration overrides apply only to `RoutineBuilderView`-owned routines — `CustomizeRoutineView`'s ad-hoc today-session is explicitly out of scope; its `Context` fields for this feature are always empty/unused.
- `ExercisePickingSession.Context` is shared by both `CustomizeRoutineView` (Home, tab 0) and `RoutineBuilderView` (Routines, tab 4) — every new field must have a sensible value at both call sites, not just the new one.
- Re-presenting `RoutineBuilderView` after a cross-tab pick must be an exact **replace** of name/selectedIDs/durationOverrides, never a merge through `RoutineIDMerge` — a merge would silently resurrect exercises the user had already removed in the current unsaved edit session (see Task 5).
- `ExercisePickerView` (the old local sheet struct in `RoutineBuilderView.swift`) is deleted once nothing calls it (Task 5).

---

### Task 1: Add exerciseDurationOverrides to the Routine model

**Files:**
- Modify: `Breath - Relax & Stretch/Models/Routine.swift`

**Interfaces:**
- Produces: `Routine.exerciseDurationOverrides: [UUID: Int]` and the matching `init` parameter — every later task in this plan reads or writes this field.

- [ ] **Step 1: Add the field and init parameter**

```swift
@Model
final class Routine {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var exerciseIDs: [UUID] = []
    var borrowedFromID: UUID? = nil
    var createdAt: Date = Date()

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        borrowedFromID: UUID? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.borrowedFromID = borrowedFromID
        self.createdAt = Date()
    }
}
```

becomes:

```swift
@Model
final class Routine {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var exerciseIDs: [UUID] = []
    var borrowedFromID: UUID? = nil
    var createdAt: Date = Date()
    /// Per-exercise duration overrides, keyed by exercise UUID — seconds.
    /// Absent key means "use the exercise's own durationSeconds." Set via
    /// RoutineBuilderView's +/− stepper, read by SessionPlayerView during
    /// playback (see `effectiveDuration(for:)`).
    var exerciseDurationOverrides: [UUID: Int] = [:]

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        borrowedFromID: UUID? = nil,
        exerciseDurationOverrides: [UUID: Int] = [:]
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.borrowedFromID = borrowedFromID
        self.createdAt = Date()
        self.exerciseDurationOverrides = exerciseDurationOverrides
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED` — the new field and parameter both have defaults, so every existing `Routine(...)` call site compiles unchanged. No `SchemaMigrationPlan`/`VersionedSchema` code is needed (same as every prior phase's model change) — SwiftData's lightweight migration handles an added field automatically.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Models/Routine.swift"
git commit -m "feat(routines): add per-exercise duration overrides to Routine"
```

---

### Task 2: Add the duration stepper to RoutineBuilderView

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift`

**Interfaces:**
- Consumes: `Routine.exerciseDurationOverrides` (Task 1).
- Produces: `RoutineBuilderView`'s `@State private var durationOverrides: [UUID: Int]` — Task 5's `restoredState` parameter and Task 5's "Add Exercise" button both read/write this same property.

- [ ] **Step 1: Add the state and helper methods**

```swift
    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var showingExercisePicker = false
    @State private var indexPendingRemoval: Int?
    /// Guards the "creating new" onAppear branch so initialExerciseIDs/
    /// initialName are only seeded once. Without this, a future dismiss-and-
    /// re-present of this same sheet (e.g. after a cross-tab exercise pick)
    /// would re-fire onAppear and silently overwrite a name the user had
    /// already typed.
    @State private var didApplySeed = false

    private var isEditing: Bool { routineToEdit != nil }

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + $1.durationSeconds }
    }
```

becomes:

```swift
    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var showingExercisePicker = false
    @State private var indexPendingRemoval: Int?
    /// Per-exercise duration overrides, keyed by exercise UUID — seconds.
    /// Absent key means "use the exercise's own durationSeconds." Persisted
    /// onto `Routine.exerciseDurationOverrides` on save.
    @State private var durationOverrides: [UUID: Int] = [:]
    /// Guards the "creating new" onAppear branch so initialExerciseIDs/
    /// initialName are only seeded once. Without this, a future dismiss-and-
    /// re-present of this same sheet (e.g. after a cross-tab exercise pick)
    /// would re-fire onAppear and silently overwrite a name the user had
    /// already typed.
    @State private var didApplySeed = false

    private var isEditing: Bool { routineToEdit != nil }

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + duration(for: $1) }
    }

    /// The exercise's duration after applying this form's own override, if
    /// any — the single point every duration read in this view goes
    /// through, mirroring SessionPlayerView's `effectiveDuration(for:)`.
    private func duration(for exercise: Exercise) -> Int {
        durationOverrides[exercise.uuid] ?? exercise.durationSeconds
    }

    private func adjustDuration(for exercise: Exercise, by delta: Int) {
        let next = max(5, duration(for: exercise) + delta)
        durationOverrides[exercise.uuid] = next
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }
```

- [ ] **Step 2: Replace the duration/type caption with a stepper in each exercise row**

```swift
                Section {
                    ForEach(selectedIDs.indices, id: \.self) { index in
                        if let exercise = exercises.first(where: { $0.uuid == selectedIDs[index] }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.luminaCardTitle)
                                        .foregroundStyle(Color.luminaOnSurface)
                                    Text("\(exercise.durationFormatted) · \(exercise.type.rawValue)")
                                        .font(.luminaCaption)
                                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    indexPendingRemoval = index
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .onMove { selectedIDs.move(fromOffsets: $0, toOffset: $1) }
```

becomes:

```swift
                Section {
                    ForEach(selectedIDs.indices, id: \.self) { index in
                        if let exercise = exercises.first(where: { $0.uuid == selectedIDs[index] }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.luminaCardTitle)
                                        .foregroundStyle(Color.luminaOnSurface)
                                    Text(exercise.type.rawValue)
                                        .font(.luminaCaption)
                                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                                }
                                Spacer()
                                durationStepper(for: exercise)
                                Button(role: .destructive) {
                                    indexPendingRemoval = index
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .onMove { selectedIDs.move(fromOffsets: $0, toOffset: $1) }
```

- [ ] **Step 3: Add the `durationStepper(for:)` view builder**

Add this new private method right after `saveRoutine()`'s closing brace, before the `ExercisePickerView` struct (or anywhere else in the file's private-helpers area — placement within the file doesn't matter, just keep it a `private` member of `RoutineBuilderView`):

```swift
    private func durationStepper(for exercise: Exercise) -> some View {
        HStack(spacing: 6) {
            // Outline icon here (vs. the row's own filled "minus.circle.fill"
            // remove button) so the two destructive-looking minus icons in
            // the same row read as visually distinct actions.
            Button {
                adjustDuration(for: exercise, by: -5)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.luminaPrimary)

            Text(formattedDuration(duration(for: exercise)))
                .font(.luminaCaption)
                .monospacedDigit()
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .frame(minWidth: 40)

            Button {
                adjustDuration(for: exercise, by: 5)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.luminaPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.name) duration, \(formattedDuration(duration(for: exercise)))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjustDuration(for: exercise, by: 5)
            case .decrement: adjustDuration(for: exercise, by: -5)
            @unknown default: break
            }
        }
    }
```

- [ ] **Step 4: Persist `durationOverrides` on save**

```swift
    private func saveRoutine() {
        if let r = routineToEdit {
            r.name        = routineName
            r.exerciseIDs = selectedIDs
        } else {
            let routine = Routine(
                name: routineName,
                exerciseIDs: selectedIDs
            )
            modelContext.insert(routine)
```

becomes:

```swift
    private func saveRoutine() {
        if let r = routineToEdit {
            r.name        = routineName
            r.exerciseIDs = selectedIDs
            r.exerciseDurationOverrides = durationOverrides
        } else {
            let routine = Routine(
                name: routineName,
                exerciseIDs: selectedIDs,
                exerciseDurationOverrides: durationOverrides
            )
            modelContext.insert(routine)
```

- [ ] **Step 5: Seed `durationOverrides` when editing an existing routine**

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                } else if !didApplySeed && (!initialExerciseIDs.isEmpty || initialName != nil) {
```

becomes:

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                    durationOverrides = r.exerciseDurationOverrides
                } else if !didApplySeed && (!initialExerciseIDs.isEmpty || initialName != nil) {
```

- [ ] **Step 6: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift"
git commit -m "feat(routines): add +/- 5s duration stepper to RoutineBuilderView rows"
```

---

### Task 3: Thread duration overrides into SessionPlayerView playback

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`

**Interfaces:**
- Consumes: `Routine.exerciseDurationOverrides` (Task 1).
- Produces: `SessionPlayerView.durationOverrides: [UUID: Int]` (new init param, default `[:]` — every other existing call site, e.g. quick-session/mini-routine/premade flows, is unaffected) and `effectiveDuration(for:)` — the single choke point every duration read in this view goes through.

- [ ] **Step 1: Add the property and the `effectiveDuration` helpers**

```swift
struct SessionPlayerView: View {
    let exercises: [Exercise]
    var routineID: UUID = UUID()
    var isBorrowedRoutine: Bool = false   // true when playing a forked public routine
    var onComplete: ((Int) -> Void)? = nil
```

becomes:

```swift
struct SessionPlayerView: View {
    let exercises: [Exercise]
    var routineID: UUID = UUID()
    var isBorrowedRoutine: Bool = false   // true when playing a forked public routine
    var onComplete: ((Int) -> Void)? = nil
    /// Per-exercise duration overrides from the Routine being played, keyed
    /// by exercise UUID — absent key means "use the exercise's own
    /// durationSeconds." Empty by default for sessions not started from a
    /// saved routine (quick sessions, mini-routines, premade previews).
    var durationOverrides: [UUID: Int] = [:]
```

```swift
    static func scaledDuration(base: Int, multiplier: Double) -> Int {
        max(1, Int(Double(base) * multiplier))
    }
```

becomes:

```swift
    static func scaledDuration(base: Int, multiplier: Double) -> Int {
        max(1, Int(Double(base) * multiplier))
    }

    /// The exercise's duration after applying this session's routine-level
    /// override, if any — the single point every duration read in this view
    /// goes through, so `durationOverrides` and the speed multiplier compose
    /// correctly no matter which call site reads it.
    private func effectiveDuration(for exercise: Exercise) -> Int {
        durationOverrides[exercise.uuid] ?? exercise.durationSeconds
    }

    private func effectiveDuration(for exercise: Exercise?) -> Int? {
        exercise.map { effectiveDuration(for: $0) }
    }
```

- [ ] **Step 2: Swap all 6 remaining `.durationSeconds` reads for `effectiveDuration(for:)`**

```swift
    private var totalSessionSeconds: Int {
        exercises.reduce(0) { total, exercise in
            total + Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
        }
    }

    private var elapsedSessionSeconds: Int {
        guard currentIndex < exercises.count else { return totalSessionSeconds }

        let completed = exercises.prefix(currentIndex).reduce(0) { total, exercise in
            total + Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
        }
        let currentDuration = Self.scaledDuration(base: exercises[currentIndex].durationSeconds, multiplier: durationMultiplier)
        let currentElapsed = max(0, min(currentDuration, currentDuration - secondsRemaining))
        return completed + currentElapsed
    }
```

becomes:

```swift
    private var totalSessionSeconds: Int {
        exercises.reduce(0) { total, exercise in
            total + Self.scaledDuration(base: effectiveDuration(for: exercise), multiplier: durationMultiplier)
        }
    }

    private var elapsedSessionSeconds: Int {
        guard currentIndex < exercises.count else { return totalSessionSeconds }

        let completed = exercises.prefix(currentIndex).reduce(0) { total, exercise in
            total + Self.scaledDuration(base: effectiveDuration(for: exercise), multiplier: durationMultiplier)
        }
        let currentDuration = Self.scaledDuration(base: effectiveDuration(for: exercises[currentIndex]), multiplier: durationMultiplier)
        let currentElapsed = max(0, min(currentDuration, currentDuration - secondsRemaining))
        return completed + currentElapsed
    }
```

```swift
    private func breathingCycleDuration(for exercise: Exercise) -> Double {
        let scaled = Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
```

becomes:

```swift
    private func breathingCycleDuration(for exercise: Exercise) -> Double {
        let scaled = Self.scaledDuration(base: effectiveDuration(for: exercise), multiplier: durationMultiplier)
```

```swift
    private func skipCompletion() -> Double {
        guard let duration = currentExercise?.durationSeconds else { return 0.5 }
        return GamificationService.skipCompletion(elapsedSeconds: duration - secondsRemaining, durationSeconds: duration)
    }

    private func startExercise() {
        let baseDuration = currentExercise?.durationSeconds ?? 60
        let duration = Self.scaledDuration(base: baseDuration, multiplier: durationMultiplier)
```

becomes:

```swift
    private func skipCompletion() -> Double {
        guard let duration = effectiveDuration(for: currentExercise) else { return 0.5 }
        return GamificationService.skipCompletion(elapsedSeconds: duration - secondsRemaining, durationSeconds: duration)
    }

    private func startExercise() {
        let baseDuration = effectiveDuration(for: currentExercise) ?? 60
        let duration = Self.scaledDuration(base: baseDuration, multiplier: durationMultiplier)
```

```swift
    private func updateBreathPhaseStepIfNeeded() {
        guard let pattern = activeBreathPattern, let exercise = currentExercise else { return }
        let totalDuration = Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
```

becomes:

```swift
    private func updateBreathPhaseStepIfNeeded() {
        guard let pattern = activeBreathPattern, let exercise = currentExercise else { return }
        let totalDuration = Self.scaledDuration(base: effectiveDuration(for: exercise), multiplier: durationMultiplier)
```

- [ ] **Step 3: Pass the saved routine's overrides in when RoutineListView presents the player**

```swift
            .sheet(item: $routineToPlay) { routine in
                let resolved = resolvedExercises(for: routine)
                if resolved.isEmpty {
                    ContentUnavailableView(
                        "No Exercises Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The exercises in this routine couldn't be loaded.")
                    )
                } else {
                    SessionPlayerView(
                        exercises: resolved,
                        routineID: routine.uuid,
                        isBorrowedRoutine: routine.borrowedFromID != nil
                    )
                }
            }
```

becomes:

```swift
            .sheet(item: $routineToPlay) { routine in
                let resolved = resolvedExercises(for: routine)
                if resolved.isEmpty {
                    ContentUnavailableView(
                        "No Exercises Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The exercises in this routine couldn't be loaded.")
                    )
                } else {
                    SessionPlayerView(
                        exercises: resolved,
                        routineID: routine.uuid,
                        isBorrowedRoutine: routine.borrowedFromID != nil,
                        durationOverrides: routine.exerciseDurationOverrides
                    )
                }
            }
```

- [ ] **Step 4: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: `** TEST SUCCEEDED **`, no failures.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift" "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift"
git commit -m "feat(routines): thread duration overrides into SessionPlayerView playback"
```

---

### Task 4: Extend ExercisePickingSession.Context and fix HomeView's tab-return logic

**Files:**
- Modify: `Breath - Relax & Stretch/Services/ExercisePickingSession.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/HomeView.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`

**Interfaces:**
- Produces: `ExercisePickingSession.Context` with three new fields — `originTab: Int`, `editingRoutineID: UUID?`, `durationOverrides: [UUID: Int]` — Task 5's `RoutineBuilderView` call site and Task 6's `RoutineListView` handler both depend on this exact shape.
- Consumes: nothing new.

**Why this task exists (context you won't get from the diff alone):** today, `HomeView`'s `.exercisePickingFinished` handler hardcodes `selectedTab = 0` because Customize (Home, tab 0) is the only thing that has ever started a picking session. Once `RoutineBuilderView` (Routines, tab 4) can start one too, that hardcoded `0` would strand a user who tapped "Add Exercise" from the Routines tab on the Today tab instead, with their in-progress routine gone. Similarly, `TodayView`'s handler currently consumes *any* finished pick unconditionally — once a second screen can also finish a pick, `TodayView` needs to check the pick was actually meant for it before consuming it (a `ExercisePickingSession.Context`'s `lastFinished` published value is a single slot, not a per-tab queue), otherwise it could steal a result `RoutineListView` (Task 6) needed.

- [ ] **Step 1: Extend `Context`**

```swift
    struct Context {
        let title: String
        let isPinned: Bool
        let baseExercises: [Exercise]
    }
```

becomes:

```swift
    struct Context {
        let title: String
        let isPinned: Bool
        let baseExercises: [Exercise]
        /// Which HomeView tab index started this picking session — read by
        /// HomeView's `.exercisePickingFinished` handler so it returns to
        /// whichever tab is actually waiting to re-present its sheet, not
        /// always Home. CustomizeRoutineView always passes 0 (Today); the
        /// RoutineBuilderView call site (Routines tab) passes 4.
        let originTab: Int
        /// The Routine being edited when picking started, if any — nil for
        /// a brand-new routine (or for CustomizeRoutineView, which has no
        /// underlying Routine at all until it's pinned). Carried through so
        /// RoutineListView can tell "update" from "create" apart after the
        /// cross-tab round trip.
        let editingRoutineID: UUID?
        /// Per-exercise duration overrides already set on the routine
        /// before picking started, keyed by exercise UUID — carried
        /// through so re-presenting the routine builder doesn't silently
        /// discard custom durations already set on exercises already in
        /// the list. Always empty for CustomizeRoutineView, which doesn't
        /// support duration overrides.
        let durationOverrides: [UUID: Int]
    }
```

- [ ] **Step 2: Update CustomizeRoutineView's existing call site**

```swift
                        pickingSession.begin(context: .init(
                            title: title,
                            isPinned: pinnedToggle,
                            baseExercises: currentExercises
                        ))
```

becomes:

```swift
                        pickingSession.begin(context: .init(
                            title: title,
                            isPinned: pinnedToggle,
                            baseExercises: currentExercises,
                            originTab: 0,
                            editingRoutineID: nil,
                            durationOverrides: [:]
                        ))
```

- [ ] **Step 3: Fix HomeView's hardcoded tab return**

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            selectedTab = 0
        }
```

becomes:

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.lastFinished else { return }
            selectedTab = result.context.originTab
        }
```

`HomeView` doesn't currently declare `pickingSession` — add the environment object property alongside its other `@EnvironmentObject`s:

```swift
struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var router: DeepLinkRouter
    @Environment(\.scenePhase) private var scenePhase
```

becomes:

```swift
struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var router: DeepLinkRouter
    @EnvironmentObject private var pickingSession: ExercisePickingSession
    @Environment(\.scenePhase) private var scenePhase
```

Note: `HomeView` peeks at `pickingSession.lastFinished` here — it does **not** call `consumeFinished()`. Only the tab-specific consumer (`TodayView` in Step 4, `RoutineListView` in Task 6) clears it, once it's confirmed the result is actually meant for that tab. `HomeView`'s handler and the destination tab's handler both fire off the same notification; `HomeView` reacting first and switching tabs, then the destination tab's own handler firing (it's already mounted, per `visitedTabs`) and doing the actual consume-and-re-present, is the intended order — nothing here depends on strict ordering between the two, since neither one mutates state the other reads before its own guard check.

- [ ] **Step 4: Make TodayView's handler check the result is actually meant for it before consuming**

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.consumeFinished() else { return }
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
```

becomes:

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.lastFinished, result.context.originTab == 0 else { return }
            _ = pickingSession.consumeFinished()
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
```

- [ ] **Step 5: Fix `ExercisePickingSessionTests.swift`'s `Context`-construction helper**

`Context` gained three required fields with no defaults, so this test file's helper won't compile without this change:

```swift
    private func makeContext(base: [Exercise] = []) -> ExercisePickingSession.Context {
        .init(title: "Wake Up", isPinned: false, baseExercises: base)
    }
```

becomes:

```swift
    private func makeContext(base: [Exercise] = []) -> ExercisePickingSession.Context {
        .init(title: "Wake Up", isPinned: false, baseExercises: base, originTab: 0, editingRoutineID: nil, durationOverrides: [:])
    }
```

- [ ] **Step 6: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: `** TEST SUCCEEDED **`, no failures.

- [ ] **Step 8: Commit**

```bash
git add "Breath - Relax & Stretch/Services/ExercisePickingSession.swift" "Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift" "Breath - Relax & Stretch/Views/Home/HomeView.swift" "Breath - Relax & Stretch/Views/Home/TodayView.swift" "Breath - Relax & StretchTests/ExercisePickingSessionTests.swift"
git commit -m "feat(routines): extend ExercisePickingSession.Context for multi-origin picking"
```

---

### Task 5: Add restoredState to RoutineBuilderView and rewire its Add Exercise button

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift`

**Interfaces:**
- Consumes: `ExercisePickingSession.Context` (Task 4)'s new shape, `ExercisePickingSession` (`@EnvironmentObject`, already injected app-wide — no new wiring needed at this view's presentation sites).
- Produces: `RoutineBuilderView.restoredState: (name: String, exerciseIDs: [UUID], durationOverrides: [UUID: Int])?` — Task 6's `RoutineListView` sheet call site is the only consumer.

**Why `restoredState` is a separate parameter from `initialExerciseIDs`/`initialName` (design note — this is the one place in this plan where the design goes beyond a literal transcription of the spec, worked out during planning):** `initialExerciseIDs` is deliberately a **merge** — `RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)` unions the two lists, which is exactly right for "fold a fresh pick into whatever's already saved on this routine." But re-presenting `RoutineBuilderView` after *this* screen's own cross-tab round trip needs the opposite: `result.merged` (from `ExercisePickingSession.finish()`) already **is** the complete, correct exercise list — computed by merging the picks into the form's in-progress `selectedExercises` snapshot (`Context.baseExercises`), not into the stale, still-saved `routineToEdit.exerciseIDs`. Reusing the `initialExerciseIDs`/`RoutineIDMerge` path here would union `result.merged` a second time with `r.exerciseIDs`, which can resurrect an exercise the user had already removed in this same unsaved edit session (it's still present in `r.exerciseIDs` since nothing was saved yet, so the union brings it right back). `restoredState` sidesteps this entirely: it's a hard **replace**, checked first in `onAppear`, and short-circuits both the `routineToEdit` and `initialExerciseIDs` branches.

- [ ] **Step 1: Add the `pickingSession` environment object and the `restoredState` parameter**

```swift
struct RoutineBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var exercises: [Exercise]

    var routineToEdit: Routine? = nil
```

becomes:

```swift
struct RoutineBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var pickingSession: ExercisePickingSession

    @Query private var exercises: [Exercise]

    var routineToEdit: Routine? = nil
```

```swift
    /// Called right after a successful save (create or update), before
    /// `dismiss()`. Distinct from dismissal itself so a caller driving this
    /// view from a review flow (`MiniRoutineReviewView`) can tell "saved"
    /// apart from "cancelled" — the sheet's own `onDismiss` fires either way
    /// and can't make that distinction.
    var onSaved: (() -> Void)? = nil
```

becomes:

```swift
    /// Called right after a successful save (create or update), before
    /// `dismiss()`. Distinct from dismissal itself so a caller driving this
    /// view from a review flow (`MiniRoutineReviewView`) can tell "saved"
    /// apart from "cancelled" — the sheet's own `onDismiss` fires either way
    /// and can't make that distinction.
    var onSaved: (() -> Void)? = nil
    /// Exact form state to restore after a cross-tab "Add Exercise" round
    /// trip — a hard replace, not a merge. Set only by RoutineListView's
    /// re-presentation after `.exercisePickingFinished`; nil for every
    /// other entry into this view. When set, takes priority over
    /// `routineToEdit`/`initialExerciseIDs`/`initialName` entirely — see
    /// this task's design note for why a merge here would be wrong.
    var restoredState: (name: String, exerciseIDs: [UUID], durationOverrides: [UUID: Int])? = nil
```

- [ ] **Step 2: Check `restoredState` first in `onAppear`**

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                    durationOverrides = r.exerciseDurationOverrides
                } else if !didApplySeed && (!initialExerciseIDs.isEmpty || initialName != nil) {
                    didApplySeed = true
                    selectedIDs = RoutineIDMerge.appending(initialExerciseIDs, to: selectedIDs)
                    if let initialName {
                        routineName = initialName
                    }
                }
            }
```

becomes:

```swift
            .onAppear {
                if let restoredState {
                    routineName       = restoredState.name
                    selectedIDs       = restoredState.exerciseIDs
                    durationOverrides = restoredState.durationOverrides
                } else if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                    durationOverrides = r.exerciseDurationOverrides
                } else if !didApplySeed && (!initialExerciseIDs.isEmpty || initialName != nil) {
                    didApplySeed = true
                    selectedIDs = RoutineIDMerge.appending(initialExerciseIDs, to: selectedIDs)
                    if let initialName {
                        routineName = initialName
                    }
                }
            }
```

- [ ] **Step 3: Rewire the "Add Exercise" button to the cross-tab picking flow**

```swift
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaPrimary)
                    }
```

becomes:

```swift
                    Button {
                        pickingSession.begin(context: .init(
                            title: routineName,
                            isPinned: false,
                            baseExercises: selectedExercises,
                            originTab: 4,
                            editingRoutineID: routineToEdit?.uuid,
                            durationOverrides: durationOverrides
                        ))
                        dismiss()
                        // Same "dismiss + switch to Exercises tab" need
                        // CustomizeRoutineView's own Add Exercises button
                        // has — reusing the existing notification rather
                        // than adding a second one.
                        NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaPrimary)
                    }
```

- [ ] **Step 4: Delete the local sheet, its state, and the now-dead `ExercisePickerView` struct**

```swift
    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var showingExercisePicker = false
    @State private var indexPendingRemoval: Int?
```

becomes:

```swift
    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var indexPendingRemoval: Int?
```

```swift
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(allExercises: Array(exercises), selectedIDs: selectedIDs) { id in
                    if !selectedIDs.contains(id) { selectedIDs.append(id) }
                }
            }
            .confirmationDialog(
```

becomes:

```swift
            .confirmationDialog(
```

Delete everything from the `// MARK: - Exercise picker sheet` comment through the end of the file — the whole now-unused `ExercisePickerView` struct:

```swift
// MARK: - Exercise picker sheet

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let allExercises: [Exercise]
    let selectedIDs: [UUID]
    let onSelect: (UUID) -> Void
    @State private var searchText = ""

    private var filtered: [Exercise] {
        allExercises.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    exerciseRows(filtered)
                }
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .searchable(text: $searchText)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseRows(_ items: [Exercise]) -> some View {
        ForEach(items, id: \.uuid) { ex in
            Button {
                onSelect(ex.uuid)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.luminaCardTitle)
                            .foregroundStyle(Color.luminaOnSurface)
                        Text("\(ex.durationFormatted) · \(ex.type.rawValue)")
                            .font(.luminaCaption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
                    Spacer()
                    if selectedIDs.contains(ex.uuid) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.luminaPrimary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            Divider().padding(.leading)
        }
    }
}
```

That entire block is deleted — nothing replaces it, the file ends at `RoutineBuilderView`'s closing `}` (the one that closes the struct itself, immediately after `saveRoutine()`/`durationStepper(for:)`/the other helpers added in Task 2).

- [ ] **Step 5: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`. If it fails on an unresolved `ExercisePickerView` reference somewhere, that's a real signal another call site depended on it that this plan didn't anticipate — search the repo for `ExercisePickerView` before assuming Step 4 was simply incomplete.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift"
git commit -m "feat(routines): rewire RoutineBuilderView's Add Exercise to cross-tab picking"
```

---

### Task 6: RoutineListView re-presents RoutineBuilderView after a cross-tab pick

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`

**Interfaces:**
- Consumes: `ExercisePickingSession` (already available via the ambient environment — `RoutineListView` is part of `HomeView`'s tab hierarchy, same as `TodayView`), `RoutineBuilderView.restoredState` (Task 5).
- Produces: nothing new for later tasks — this is the last task in the plan.

- [ ] **Step 1: Add the environment object, override state, and re-presentation flag**

```swift
struct RoutineListView: View {
    @Query private var routines: [Routine]
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext

    @State private var showingBuilder  = false
    @State private var routineToPlay: Routine?
    @State private var routineToEdit: Routine?
    @State private var routinePendingDelete: Routine?
```

becomes:

```swift
struct RoutineListView: View {
    @Query private var routines: [Routine]
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var pickingSession: ExercisePickingSession

    @State private var showingBuilder  = false
    @State private var routineToPlay: Routine?
    @State private var routineToEdit: Routine?
    @State private var routinePendingDelete: Routine?
    /// Snapshot to restore into RoutineBuilderView after a cross-tab
    /// "Add Exercise" round trip — set by the `.exercisePickingFinished`
    /// handler below, consumed by the `showingBuilderAfterPick` sheet.
    @State private var builderRestoredState: (routineToEdit: Routine?, name: String, exerciseIDs: [UUID], durationOverrides: [UUID: Int])?
    @State private var showingBuilderAfterPick = false
```

- [ ] **Step 2: Add the `.onReceive` handler and the new sheet**

```swift
            .sheet(isPresented: $showingBuilder) {
                RoutineBuilderView()
            }
            .sheet(item: $routineToEdit) { routine in
                RoutineBuilderView(routineToEdit: routine)
            }
```

becomes:

```swift
            .sheet(isPresented: $showingBuilder) {
                RoutineBuilderView()
            }
            .sheet(item: $routineToEdit) { routine in
                RoutineBuilderView(routineToEdit: routine)
            }
            .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
                guard let result = pickingSession.lastFinished, result.context.originTab == 4 else { return }
                _ = pickingSession.consumeFinished()
                let editingRoutine = result.context.editingRoutineID.flatMap { id in
                    routines.first(where: { $0.uuid == id })
                }
                builderRestoredState = (
                    routineToEdit: editingRoutine,
                    name: result.context.title,
                    exerciseIDs: result.merged.map(\.uuid),
                    durationOverrides: result.context.durationOverrides
                )
                showingBuilderAfterPick = true
            }
            .sheet(isPresented: $showingBuilderAfterPick, onDismiss: {
                builderRestoredState = nil
            }) {
                RoutineBuilderView(
                    routineToEdit: builderRestoredState?.routineToEdit,
                    restoredState: builderRestoredState.map {
                        (name: $0.name, exerciseIDs: $0.exerciseIDs, durationOverrides: $0.durationOverrides)
                    }
                )
            }
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: `** TEST SUCCEEDED **`, no failures.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift"
git commit -m "feat(routines): re-present RoutineBuilderView after a cross-tab pick"
```

---

## Plan complete

At this point: every exercise row in `RoutineBuilderView` has a working +/− 5s duration stepper, saved durations actually change playback speed through `SessionPlayerView`, and tapping "Add Exercise" from the routine builder switches to the Exercises tab and returns to a correctly-restored builder — same name, same exercises (base + newly picked, not a stale re-union), same duration overrides — whether the user was creating a new routine or editing an existing one. This is Phase 4 of 4; all four phases of the routines-tab redesign spec are now implemented.
