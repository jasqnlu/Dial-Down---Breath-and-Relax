# Breath Phase Timing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `SessionPlayerView` show and cue Breath exercises' actual inhale/hold/exhale
counts (e.g. "Inhale · 3", ticking down, with a beep + spoken phase name at each transition),
instead of cycling instruction text on a flat unrelated timer.

**Architecture:** A new pure `BreathPhaseStep`/`BreathPhaseCycle` pair resolves "which phase, how
many seconds left in it" from wall-clock-elapsed time — computed every tick inside
`SessionPlayerView`'s existing 1-second timer loop, not a new sleep-based task. `Exercise`
gains an optional authored `breathPattern`, stored as `Data` (mirroring the existing
`posesData`/`poses` pattern) and backfilled onto installed rows via a new `SeedMigrator.migrateV11`.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing (`@Test`/`#expect`), AudioToolbox
(`AudioServicesPlaySystemSound`), `AVSpeechSynthesizer` (via the existing `VoiceCueService`).

**Spec:** `docs/superpowers/specs/2026-08-13-breath-phase-timing-design.md`

## Global Constraints

- No new custom-enum-typed stored property on `Exercise` — SwiftData's lightweight migration
  cannot safely decode one added after real data exists (crashes with
  `swift_dynamicCastFailure`; see `Exercise.swift`'s `cueStyleRaw` doc comment and
  `ExerciseCueStyleTests.cueStyleFallsBackToHoldForUnparseableRawStorage`). New breath-pattern
  storage must be a primitive (`Data`) with a computed decode property, exactly like
  `posesData`/`poses`.
- Scope is Breath-type exercises with an authored pattern only. Stretch exercises and
  Breath exercises without a pattern are completely unchanged (existing flat 3.5s
  `instructionCueTask` cycling, from `2026-08-01-exercise-session-cues-design.md`).
- No new `SystemSoundID` — reuse the existing `soundCueBeep` (`SessionPlayerView.swift:69`).
- Migration follows the existing `SeedMigrator` ladder exactly: match by `seedID`, never touch
  rows with no `seedID` (user-created exercises), one-time version gate (`seedDataVersion < 11`),
  not the "run every launch" pattern used by `migrateV7`/`migrateV9`/`migrateV10` (this is a
  one-time authored-content backfill, not an ever-growing set).

---

### Task 1: `BreathPhaseStep` + `BreathPhaseCycle` (pure logic)

**Files:**
- Create: `Breath - Relax & Stretch/Models/BreathPhaseStep.swift`
- Create: `Breath - Relax & Stretch/Services/BreathPhaseCycle.swift`
- Test: `Breath - Relax & StretchTests/BreathPhaseCycleTests.swift`

**Interfaces:**
- Produces: `struct BreathPhaseStep: Codable, Equatable { let label: String; let seconds: Int }`
- Produces: `enum BreathPhaseCycle { struct Resolved: Equatable { let phaseIndex: Int; let secondsRemainingInPhase: Int }; static func resolve(pattern: [BreathPhaseStep], elapsedSeconds: Int) -> Resolved? }`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import BreathRelaxStretch

struct BreathPhaseCycleTests {
    private let boxBreathing = [
        BreathPhaseStep(label: "Inhale", seconds: 4),
        BreathPhaseStep(label: "Hold", seconds: 4),
        BreathPhaseStep(label: "Exhale", seconds: 4),
        BreathPhaseStep(label: "Hold", seconds: 4),
    ]

    @Test func emptyPatternResolvesToNil() {
        #expect(BreathPhaseCycle.resolve(pattern: [], elapsedSeconds: 0) == nil)
    }

    @Test func firstTickIsFirstPhaseAtFullDuration() {
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 0)
        #expect(resolved == .init(phaseIndex: 0, secondsRemainingInPhase: 4))
    }

    @Test func oneSecondIntoFirstPhase() {
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 1)
        #expect(resolved == .init(phaseIndex: 0, secondsRemainingInPhase: 3))
    }

    @Test func exactBoundaryLandsOnNextPhase() {
        // 4 seconds elapsed = exactly the end of phase 0 (Inhale) = start of phase 1 (Hold).
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 4)
        #expect(resolved == .init(phaseIndex: 1, secondsRemainingInPhase: 4))
    }

    @Test func midwayThroughThirdPhase() {
        // 4 (Inhale) + 4 (Hold) + 2 = 2 seconds into Exhale (index 2), 2 remaining.
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 10)
        #expect(resolved == .init(phaseIndex: 2, secondsRemainingInPhase: 2))
    }

    @Test func wrapsAroundAfterFullCycle() {
        // Box Breathing's cycle is 16s total; 16 seconds elapsed wraps back to phase 0.
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 16)
        #expect(resolved == .init(phaseIndex: 0, secondsRemainingInPhase: 4))
    }

    @Test func wrapsAroundMidwaySecondCycle() {
        // 16 (one full cycle) + 10 = same offset as midwayThroughThirdPhase.
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 26)
        #expect(resolved == .init(phaseIndex: 2, secondsRemainingInPhase: 2))
    }

    @Test func singlePhasePattern() {
        let pattern = [BreathPhaseStep(label: "Breathe", seconds: 5)]
        #expect(BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 0) == .init(phaseIndex: 0, secondsRemainingInPhase: 5))
        #expect(BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 3) == .init(phaseIndex: 0, secondsRemainingInPhase: 2))
        #expect(BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 5) == .init(phaseIndex: 0, secondsRemainingInPhase: 5))
    }

    @Test func patternWithAZeroSecondPhaseIsSkippedOver() {
        // Defensive: a malformed 0-second phase should never be selected as
        // the resolved phase (would show "· 0" forever) — resolve steps past it.
        let pattern = [
            BreathPhaseStep(label: "Inhale", seconds: 4),
            BreathPhaseStep(label: "Glitch", seconds: 0),
            BreathPhaseStep(label: "Exhale", seconds: 4),
        ]
        let resolved = BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 4)
        #expect(resolved?.phaseIndex == 2)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BreathPhaseCycleTests"`
Expected: FAIL to build — `BreathPhaseStep`/`BreathPhaseCycle` not defined.

- [ ] **Step 3: Write `BreathPhaseStep.swift`**

```swift
import Foundation

/// One phase of a breathing pattern — e.g. {"Inhale", 4} — authored per
/// exercise on `Exercise.breathPattern`. See BreathPhaseCycle for how a
/// sequence of these is resolved against elapsed time during a live session.
struct BreathPhaseStep: Codable, Equatable {
    let label: String
    let seconds: Int
}
```

- [ ] **Step 4: Write `BreathPhaseCycle.swift`**

```swift
import Foundation

/// Pure resolution of "which phase, how many seconds remain in it" from
/// elapsed time — no SwiftUI, no Date, no timers. SessionPlayerView calls
/// `resolve` once per second (piggybacking its existing 1Hz tick) rather
/// than running a separate sleep-based task per phase; because this derives
/// from wall-clock elapsed time rather than accumulated sleep(), it self-
/// corrects for free after the app backgrounds/foregrounds or the session
/// pauses/resumes — no special-case handling needed by the caller.
enum BreathPhaseCycle {
    struct Resolved: Equatable {
        let phaseIndex: Int
        let secondsRemainingInPhase: Int
    }

    static func resolve(pattern: [BreathPhaseStep], elapsedSeconds: Int) -> Resolved? {
        guard !pattern.isEmpty else { return nil }
        let cycleLength = pattern.reduce(0) { $0 + $1.seconds }
        guard cycleLength > 0 else { return nil }

        var offset = elapsedSeconds % cycleLength
        for (index, phase) in pattern.enumerated() {
            guard phase.seconds > 0 else { continue }
            if offset < phase.seconds {
                return Resolved(phaseIndex: index, secondsRemainingInPhase: phase.seconds - offset)
            }
            offset -= phase.seconds
        }
        // Elapsed lands exactly on a cycle boundary (offset == 0 after the
        // loop exhausts every phase) — that's the start of phase 0 again.
        guard let first = pattern.first(where: { $0.seconds > 0 }),
              let firstIndex = pattern.firstIndex(where: { $0.seconds > 0 }) else { return nil }
        return Resolved(phaseIndex: firstIndex, secondsRemainingInPhase: first.seconds)
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BreathPhaseCycleTests"`
Expected: PASS, all 9 tests.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Models/BreathPhaseStep.swift" "Breath - Relax & Stretch/Services/BreathPhaseCycle.swift" "Breath - Relax & StretchTests/BreathPhaseCycleTests.swift"
git commit -m "feat(breath): add BreathPhaseStep + BreathPhaseCycle pure resolution logic"
```

---

### Task 2: `Exercise.breathPattern`

**Files:**
- Modify: `Breath - Relax & Stretch/Models/Exercise.swift`
- Test: `Breath - Relax & StretchTests/ExerciseBreathPatternTests.swift`

**Interfaces:**
- Consumes: `BreathPhaseStep` (Task 1)
- Produces: `Exercise.breathPatternData: Data` (stored, default `Data()`), `Exercise.breathPattern: [BreathPhaseStep]` (computed get/set)

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

struct ExerciseBreathPatternTests {
    private func makeExercise() -> Exercise {
        Exercise(name: "X", type: .breath, targetBodyParts: [],
                 durationSeconds: 60, difficulty: 1, instructions: [])
    }

    @Test func defaultsToEmptyPattern() {
        #expect(makeExercise().breathPattern.isEmpty)
    }

    @Test func roundTripsThroughSetterAndGetter() {
        let e = makeExercise()
        let pattern = [BreathPhaseStep(label: "Inhale", seconds: 4), BreathPhaseStep(label: "Exhale", seconds: 6)]
        e.breathPattern = pattern
        #expect(e.breathPattern == pattern)
    }

    /// Mirrors `ExerciseCueStyleTests.cueStyleFallsBackToHoldForUnparseableRawStorage`:
    /// garbage raw storage (e.g. a pre-migration or corrupted row) must never
    /// crash the getter — it decodes to an empty pattern instead.
    @Test func fallsBackToEmptyForUnparseableRawStorage() {
        let e = makeExercise()
        e.breathPatternData = Data("not valid json".utf8)
        #expect(e.breathPattern.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseBreathPatternTests"`
Expected: FAIL to build — `breathPatternData`/`breathPattern` not defined on `Exercise`.

- [ ] **Step 3: Add the stored + computed property**

In `Breath - Relax & Stretch/Models/Exercise.swift`, immediately after the existing `posesData`/`poses` pair (the `var posesData: Data = Data()` property and its `var poses: [ExercisePose] { get set }` computed property), add:

```swift
/// Raw JSON-encoded storage for `breathPattern` — a primitive `Data`
/// property, not `[BreathPhaseStep]` directly, for the same reason `posesData`
/// and `cueStyleRaw` are: SwiftData's lightweight migration cannot safely
/// decode a newly-added non-primitive property on pre-existing on-disk
/// rows. Empty `Data()` (the default) means "no pattern authored" — the
/// session player falls back to the existing flat instruction-cycling.
var breathPatternData: Data = Data()

/// An authored inhale/hold/exhale sequence for Breath-type exercises,
/// e.g. Box Breathing's [Inhale 4, Hold 4, Exhale 4, Hold 4]. Empty for
/// every exercise until authored (see SeedData.json's "breathPattern" key)
/// and for any exercise this doesn't apply to. Falls back to `[]` for any
/// unparseable raw storage, same defensive treatment `poses`/`cueStyle` get.
var breathPattern: [BreathPhaseStep] {
    get { (try? JSONDecoder().decode([BreathPhaseStep].self, from: breathPatternData)) ?? [] }
    set { breathPatternData = (try? JSONEncoder().encode(newValue)) ?? Data() }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseBreathPatternTests"`
Expected: PASS, all 3 tests. Also re-run `Breath - Relax & StretchTests/ExerciseCueStyleTests` and `Breath - Relax & StretchTests/ExerciseTests` to confirm nothing about the existing `Exercise` model broke.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/Exercise.swift" "Breath - Relax & StretchTests/ExerciseBreathPatternTests.swift"
git commit -m "feat(breath): add Exercise.breathPattern (Data-backed, mirrors posesData)"
```

---

### Task 3: `SeedMigrator.migrateV11`

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SeedMigrator.swift`
- Test: `Breath - Relax & StretchTests/SeedMigratorTests.swift`

**Interfaces:**
- Consumes: `Exercise.breathPattern` (Task 2), `BreathPhaseStep` (Task 1)
- Produces: `SeedMigrator.migrateV11(context: ModelContext, rawExercises: [[String: Any]]) -> Bool`

- [ ] **Step 1: Write the failing tests**

Add to `Breath - Relax & StretchTests/SeedMigratorTests.swift` (mirrors the existing `v8BackfillsCueStyleBySeedID`/`v8IsNoOpWhenBundleCueStyleMatchesAlready`/`v8NeverTouchesUserCreatedExercises` block exactly, substituting `breathPattern` for `cueStyle`):

```swift
// MARK: - v11: breathPattern backfill

@Test func v11BackfillsBreathPatternBySeedID() throws {
    let context = makeContext()
    let exercise = Exercise(
        name: "Box Breathing", type: .breath,
        targetBodyParts: [], durationSeconds: 180,
        difficulty: 1, instructions: ["a", "b", "c"]
    )
    exercise.seedID = "box-breathing-id"
    #expect(exercise.breathPattern.isEmpty)
    context.insert(exercise)
    try context.save()

    var raw = rawExercise(id: "box-breathing-id", name: "Box Breathing")
    raw["breathPattern"] = [
        ["label": "Inhale", "seconds": 4],
        ["label": "Hold", "seconds": 4],
        ["label": "Exhale", "seconds": 4],
        ["label": "Hold", "seconds": 4],
    ]
    let changed = SeedMigrator.migrateV11(context: context, rawExercises: [raw])
    #expect(changed)

    let all = try context.fetch(FetchDescriptor<Exercise>())
    #expect(all[0].breathPattern == [
        BreathPhaseStep(label: "Inhale", seconds: 4),
        BreathPhaseStep(label: "Hold", seconds: 4),
        BreathPhaseStep(label: "Exhale", seconds: 4),
        BreathPhaseStep(label: "Hold", seconds: 4),
    ])
}

@Test func v11IsNoOpWhenBundleHasNoPattern() throws {
    let context = makeContext()
    let exercise = Exercise(
        name: "Alternate Nostril Breathing", type: .breath,
        targetBodyParts: [], durationSeconds: 180,
        difficulty: 1, instructions: ["a", "b", "c"]
    )
    exercise.seedID = "alt-nostril-id"
    context.insert(exercise)
    try context.save()

    let raw = rawExercise(id: "alt-nostril-id", name: "Alternate Nostril Breathing")
    // No "breathPattern" key — this exercise hasn't been authored yet.
    let changed = SeedMigrator.migrateV11(context: context, rawExercises: [raw])
    #expect(!changed)

    let all = try context.fetch(FetchDescriptor<Exercise>())
    #expect(all[0].breathPattern.isEmpty)
}

@Test func v11IsNoOpWhenBundlePatternMatchesAlready() throws {
    let context = makeContext()
    let exercise = Exercise(
        name: "Box Breathing", type: .breath,
        targetBodyParts: [], durationSeconds: 180,
        difficulty: 1, instructions: ["a", "b", "c"]
    )
    exercise.seedID = "box-breathing-id"
    exercise.breathPattern = [BreathPhaseStep(label: "Inhale", seconds: 4)]
    context.insert(exercise)
    try context.save()

    var raw = rawExercise(id: "box-breathing-id", name: "Box Breathing")
    raw["breathPattern"] = [["label": "Inhale", "seconds": 4]]
    let changed = SeedMigrator.migrateV11(context: context, rawExercises: [raw])
    #expect(!changed)
}

@Test func v11NeverTouchesUserCreatedExercises() throws {
    let context = makeContext()
    let custom = Exercise(
        name: "My Custom Breath", type: .breath,
        targetBodyParts: [], durationSeconds: 60,
        difficulty: 1, instructions: ["x", "y", "z"]
    )
    context.insert(custom)   // no seedID
    try context.save()

    var raw = rawExercise(id: "seed-1", name: "Some Seed")
    raw["breathPattern"] = [["label": "Inhale", "seconds": 4]]
    let changed = SeedMigrator.migrateV11(context: context, rawExercises: [raw])
    #expect(!changed)

    let all = try context.fetch(FetchDescriptor<Exercise>())
    #expect(all[0].breathPattern.isEmpty)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedMigratorTests"`
Expected: FAIL to build — `SeedMigrator.migrateV11` not defined.

- [ ] **Step 3: Write `migrateV11`**

Add to `Breath - Relax & Stretch/Services/SeedMigrator.swift`, after `migrateV10`:

```swift
/// v11 — backfills `Exercise.breathPattern` onto already-seeded rows,
/// matched by `seedID`. New installs already read `breathPattern` off the
/// bundle at seed-insert time; this only matters for users seeded before
/// the field existed. Unlike `migrateV7`/`migrateV9`/`migrateV10`, this IS
/// gated behind a one-time `seedDataVersion` bump (see the app's migration
/// ladder) — patterns are authored once per exercise, not an ever-growing
/// set added on every release, so there's no need to re-scan every launch.
@discardableResult
static func migrateV11(context: ModelContext, rawExercises: [[String: Any]]) -> Bool {
    var patternBySeedID: [String: [BreathPhaseStep]] = [:]
    for raw in rawExercises {
        guard let id = raw["id"] as? String,
              let rawPattern = raw["breathPattern"] as? [[String: Any]], !rawPattern.isEmpty
        else { continue }
        let phases = rawPattern.compactMap { entry -> BreathPhaseStep? in
            guard let label = entry["label"] as? String, let seconds = entry["seconds"] as? Int else { return nil }
            return BreathPhaseStep(label: label, seconds: seconds)
        }
        guard !phases.isEmpty else { continue }
        patternBySeedID[id] = phases
    }

    let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
    var changed = false
    for exercise in existing {
        guard let seedID = exercise.seedID,
              let pattern = patternBySeedID[seedID],
              exercise.breathPattern != pattern else { continue }
        exercise.breathPattern = pattern
        changed = true
    }
    return changed
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedMigratorTests"`
Expected: PASS, all tests including the new v11 block and every pre-existing v3–v10 test (unmodified, must stay green).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SeedMigrator.swift" "Breath - Relax & StretchTests/SeedMigratorTests.swift"
git commit -m "feat(breath): add SeedMigrator.migrateV11 for breathPattern backfill"
```

---

### Task 4: Wire migration + seed-insert parsing into app launch

**Files:**
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`

**Interfaces:**
- Consumes: `SeedMigrator.migrateV11` (Task 3), `Exercise.breathPatternData` (Task 2)

No new unit tests in this task — `seedIfNeeded`/`migrateSeedIfNeeded` are app-entry-point
wrappers around already-tested `SeedMigrator` functions (same reason `migrateSeedToV8IfNeeded`
etc. have no tests of their own; the logic they call does). Verified by Task 8's live run and
by re-running the full unit suite to confirm no regression.

- [ ] **Step 1: Add `breathPattern` parsing to `seedIfNeeded`**

In `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`, inside `seedIfNeeded()`'s `for raw in exercises` loop, right after the existing `if let posesRaw = raw["poses"], ...` block (around line 204-207):

```swift
if let posesRaw = raw["poses"],
   let posesData = try? JSONSerialization.data(withJSONObject: posesRaw) {
    exercise.posesData = posesData
}
if let breathPatternRaw = raw["breathPattern"],
   let breathPatternData = try? JSONSerialization.data(withJSONObject: breathPatternRaw) {
    exercise.breathPatternData = breathPatternData
}
context.insert(exercise)
```

- [ ] **Step 2: Add the v11 migration wrapper**

After the existing `migrateSeedToV10IfNeeded()` function, add:

```swift
private func migrateSeedToV11IfNeeded() {
    guard seedDataVersion < 11 else { return }
    if let rawExercises = loadSeedExercises() {
        let context = sharedModelContainer.mainContext
        if SeedMigrator.migrateV11(context: context, rawExercises: rawExercises) {
            try? context.save()
        }
    }
    seedDataVersion = 11
}
```

- [ ] **Step 3: Add it to the migration ladder**

In `migrateSeedIfNeeded()`, after the existing `migrateSeedToV10IfNeeded()` call:

```swift
private func migrateSeedIfNeeded() {
    migrateSeedToV3IfNeeded()
    migrateSeedToV4IfNeeded()
    migrateSeedToV5IfNeeded()
    migrateSeedToV6IfNeeded()
    migrateSeedToV7IfNeeded()
    migrateSeedToV8IfNeeded()
    migrateSeedToV9IfNeeded()
    migrateSeedToV10IfNeeded()
    migrateSeedToV11IfNeeded()
}
```

- [ ] **Step 4: Build and run the full unit suite**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: PASS, full suite (no regressions).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift"
git commit -m "feat(breath): wire breathPattern seed-insert parsing + migrateV11 into launch ladder"
```

---

### Task 5: Author `breathPattern` for the first 5 exercises

**Files:**
- Modify: `Breath - Relax & Stretch/Resources/SeedData.json`

**Interfaces:**
- Consumes: nothing code-level — pure data addition, parsed by Task 4's already-built code.

- [ ] **Step 1: Add `breathPattern` to the 5 exercises**

Using each exercise's existing `"id"` to locate it in `SeedData.json`, add a `"breathPattern"`
array (a new key on each of these 5 JSON objects — do not modify any other field):

**Deep Belly Breath** (`id: "2528b87c-95b0-5143-8c46-3b8320565370"`) — "for 4 counts" /
"Hold for 2 counts" / "for 6 counts":
```json
"breathPattern": [
  {"label": "Inhale", "seconds": 4},
  {"label": "Hold", "seconds": 2},
  {"label": "Exhale", "seconds": 6}
]
```

**Box Breathing** (`id: "96903a29-2150-5848-a5cb-422770cd4600"`) — "for 4 counts" / "Hold for
4 counts" / "for 4 counts" / "Hold for 4 counts":
```json
"breathPattern": [
  {"label": "Inhale", "seconds": 4},
  {"label": "Hold", "seconds": 4},
  {"label": "Exhale", "seconds": 4},
  {"label": "Hold", "seconds": 4}
]
```

**4-7-8 Breathing** (`id: "a262ed03-3f8e-5f38-bfc3-d5b560833c73"`) — "for 4 counts" / "for 7
counts" / "for 8 counts":
```json
"breathPattern": [
  {"label": "Inhale", "seconds": 4},
  {"label": "Hold", "seconds": 7},
  {"label": "Exhale", "seconds": 8}
]
```

**Pursed-Lip Breathing** (`id: "f1661f4f-3967-5b83-a894-d36a42185c80"`) — "for 2 counts" / "for
4 counts":
```json
"breathPattern": [
  {"label": "Inhale", "seconds": 2},
  {"label": "Exhale", "seconds": 4}
]
```

**Diaphragmatic Breath with Counting** (`id: "3466f1c9-40ec-5b71-96c1-92323f236b55"`) —
"counting to 4" / "counting to 6":
```json
"breathPattern": [
  {"label": "Inhale", "seconds": 4},
  {"label": "Exhale", "seconds": 6}
]
```

- [ ] **Step 2: Validate the JSON**

Run: `python3 -c "import json; json.load(open('Breath - Relax & Stretch/Resources/SeedData.json'))" && echo "valid JSON"`
Expected: `valid JSON` — confirms no syntax error was introduced.

- [ ] **Step 3: Run the seed data integrity tests**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedDataTests" -only-testing:"Breath - Relax & StretchTests/CuratedContentIntegrityTests"`
Expected: PASS — adding a new key doesn't affect either suite's existing assertions (neither
enforces a closed key set).

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Resources/SeedData.json"
git commit -m "content(breath): author breathPattern for Box, 4-7-8, Deep Belly, Pursed-Lip, Diaphragmatic"
```

---

### Task 6: Wire the phase-timing state into `SessionPlayerView`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`
- Test: `Breath - Relax & StretchTests/SessionPlayerViewTests.swift` (only if a new pure/static
  helper is added — see Step 3; the stateful wiring itself is verified live in Task 8, matching
  this file's existing convention of only unit-testing its static functions like `scaledDuration`)

**Interfaces:**
- Consumes: `Exercise.breathPattern` (Task 2), `BreathPhaseCycle.resolve` (Task 1),
  `VoiceCueService.shared.speak(_:)` (existing)
- Produces: `@State private var currentBreathPhaseStepIndex: Int`, `@State private var
  breathPhaseSecondsRemaining: Int`, `private var activeBreathPattern: [BreathPhaseStep]?` — all
  consumed by Task 7's UI.

- [ ] **Step 1: Add the new `@State` and helper property**

Near the existing `instructionCueIndex`/`instructionCueTask` declarations (around line 72-73 —
right after `@State private var instructionCueTask: Task<Void, Never>? = nil`):

```swift
@State private var currentBreathPhaseStepIndex = 0
@State private var breathPhaseSecondsRemaining = 0
```

Near `currentExercise` (around line 75-78, right after its closing brace):

```swift
/// Non-nil only for a Breath exercise with an authored pattern — everything
/// else (Stretch exercises, Breath exercises with no pattern yet) falls
/// back to the existing flat instructionCueTask cycling untouched.
private var activeBreathPattern: [BreathPhaseStep]? {
    guard let pattern = currentExercise?.breathPattern, !pattern.isEmpty else { return nil }
    return pattern
}
```

- [ ] **Step 2: Branch `startExercise()` on whether a pattern is active**

In `startExercise()` (around line 451-490), replace the existing tail —

```swift
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
        AudioServicesPlaySystemSound(soundCueBeep)
        instructionCueTask?.cancel()
        instructionCueIndex = 0
        if let count = currentExercise?.instructions.count, count > 1 {
            instructionCueTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3.5))
                    guard !Task.isCancelled else { return }
                    // Mirrors the existing countdown `.task` loop's own
                    // `guard !isPaused` skip — while the session is paused,
                    // or during a get-ready transition / the summary screen,
                    // this tick is a no-op rather than advancing/beeping.
                    guard !isPaused, !isShowingGetReady, !showingSummary else { continue }
                    withAnimation(.easeOut(duration: 0.35)) {
                        instructionCueIndex = (instructionCueIndex + 1) % count
                    }
                    AudioServicesPlaySystemSound(soundCueBeep)
                }
            }
        }
    }
```

— with:

```swift
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
        AudioServicesPlaySystemSound(soundCueBeep)
        instructionCueTask?.cancel()
        instructionCueIndex = 0
        if let pattern = activeBreathPattern {
            // Breath-pattern exercises are driven by the main 1Hz tick's
            // BreathPhaseCycle computation (see the .task loop below), not
            // a sleep-based task — reset to phase 0 and announce it here so
            // the first phase is correct immediately, before the first tick.
            currentBreathPhaseStepIndex = 0
            breathPhaseSecondsRemaining = pattern[0].seconds
            VoiceCueService.shared.speak(pattern[0].label)
        } else if let count = currentExercise?.instructions.count, count > 1 {
            instructionCueTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3.5))
                    guard !Task.isCancelled else { return }
                    // Mirrors the existing countdown `.task` loop's own
                    // `guard !isPaused` skip — while the session is paused,
                    // or during a get-ready transition / the summary screen,
                    // this tick is a no-op rather than advancing/beeping.
                    guard !isPaused, !isShowingGetReady, !showingSummary else { continue }
                    withAnimation(.easeOut(duration: 0.35)) {
                        instructionCueIndex = (instructionCueIndex + 1) % count
                    }
                    AudioServicesPlaySystemSound(soundCueBeep)
                }
            }
        }
    }
```

- [ ] **Step 3: Compute the phase each tick in the existing `.task` loop**

In the `body`'s `.task { for await _ in Timer.publish(...) ... }` block (around line 154-168),
replace:

```swift
        .task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                guard !isPaused, !showingSummary, !isShowingGetReady else { continue }
                let remaining = Int(phaseEndDate.timeIntervalSinceNow.rounded(.up))
                if remaining > 0 {
                    secondsRemaining = remaining
                    checkSideSwitch()
                    breathTick += 1
                    if breathTick % 4 == 0 { AudioServicesPlaySystemSound(soundTick) }
                } else {
                    AudioServicesPlaySystemSound(soundCueBeep)
                    advanceToNext(completion: 1.0)
                }
            }
        }
```

— with:

```swift
        .task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                guard !isPaused, !showingSummary, !isShowingGetReady else { continue }
                let remaining = Int(phaseEndDate.timeIntervalSinceNow.rounded(.up))
                if remaining > 0 {
                    secondsRemaining = remaining
                    checkSideSwitch()
                    updateBreathPhaseStepIfNeeded()
                    breathTick += 1
                    if breathTick % 4 == 0 { AudioServicesPlaySystemSound(soundTick) }
                } else {
                    AudioServicesPlaySystemSound(soundCueBeep)
                    advanceToNext(completion: 1.0)
                }
            }
        }
```

- [ ] **Step 4: Add `updateBreathPhaseStepIfNeeded()`**

In the `// MARK: - Logic` section, right after `checkSideSwitch()` (around line 495-503), add:

```swift
    /// Called every 1Hz tick when a breath pattern is active. Derives the
    /// current phase from elapsed time (not accumulated sleep), so it's
    /// automatically correct after pause/resume or backgrounding — no
    /// special-case handling needed, unlike instructionCueTask's cycling.
    private func updateBreathPhaseStepIfNeeded() {
        guard let pattern = activeBreathPattern, let exercise = currentExercise else { return }
        let totalDuration = Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
        let elapsed = max(0, totalDuration - secondsRemaining)
        guard let resolved = BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: elapsed) else { return }

        breathPhaseSecondsRemaining = resolved.secondsRemainingInPhase
        guard resolved.phaseIndex != currentBreathPhaseStepIndex else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            currentBreathPhaseStepIndex = resolved.phaseIndex
        }
        AudioServicesPlaySystemSound(soundCueBeep)
        VoiceCueService.shared.speak(pattern[resolved.phaseIndex].label)
    }
```

- [ ] **Step 5: Show setup instructions on the get-ready screen for pattern exercises**

In `getReadyView(name:)` (around line 347-382), after the existing caution card block —

```swift
            if let caution = currentExercise?.caution, !caution.isEmpty {
                CautionCard(text: caution)
                    .padding(.horizontal)
            }
            Spacer()
```

— insert a setup-instructions preview, shown only when the upcoming exercise has both a
breath pattern and setup instructions (so exercises without a pattern are unaffected — their
instructions still cycle live during the exercise, unchanged):

```swift
            if let caution = currentExercise?.caution, !caution.isEmpty {
                CautionCard(text: caution)
                    .padding(.horizontal)
            }
            if let exercise = currentExercise, !exercise.breathPattern.isEmpty, !exercise.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(exercise.instructions, id: \.self) { line in
                        Text(line)
                            .font(.luminaCaption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
```

- [ ] **Step 6: Skip the flat instruction cue's use of `instructions` during the live exercise**

`instructionCue(for:)` (Task 7 replaces its call site entirely for pattern exercises), so no
change is needed here — Task 7 handles branching the call site itself.

- [ ] **Step 7: Build and run the full unit suite**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: PASS, full suite (no regressions — this task adds no new unit tests of its own,
since the logic it wires together is already covered by Tasks 1-3's tests; this step exists to
confirm the wiring compiles and doesn't break anything else).

- [ ] **Step 8: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift"
git commit -m "feat(breath): derive live phase state from the existing 1Hz tick in SessionPlayerView"
```

---

### Task 7: Phase-cue UI (label, live countdown, phase dots)

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`

**Interfaces:**
- Consumes: `activeBreathPattern`, `currentBreathPhaseStepIndex`, `breathPhaseSecondsRemaining` (Task 6)

- [ ] **Step 1: Branch the `playerContent` call site**

In `playerContent(exercise:)` (around line 257), replace:

```swift
            instructionCue(for: exercise)
```

— with:

```swift
            if let pattern = activeBreathPattern {
                breathPhaseCue(pattern: pattern)
            } else {
                instructionCue(for: exercise)
            }
```

- [ ] **Step 2: Add the `breathPhaseCue(pattern:)` view**

Right after the existing `instructionCue(for:)` function (around line 325-345), add:

```swift
    @ViewBuilder
    private func breathPhaseCue(pattern: [BreathPhaseStep]) -> some View {
        let index = min(currentBreathPhaseStepIndex, pattern.count - 1)
        let phase = pattern[index]

        VStack(spacing: 8) {
            Text("\(phase.label) · \(breathPhaseSecondsRemaining)")
                .id(index)
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurface)
                .monospacedDigit()
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity)
                        .animation(.easeOut(duration: 0.35)),
                    removal: .opacity
                        .animation(.easeIn(duration: 0.25))
                ))

            HStack(spacing: 6) {
                ForEach(Array(pattern.enumerated()), id: \.offset) { dotIndex, _ in
                    Circle()
                        .fill(dotIndex == index ? Color.luminaPrimary : Color.luminaOutline)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .accessibilityLabel("Breath phase")
        .accessibilityValue("\(phase.label), \(breathPhaseSecondsRemaining) seconds remaining, phase \(index + 1) of \(pattern.count)")
    }
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift"
git commit -m "feat(breath): add breathPhaseCue view (label + live countdown + phase dots)"
```

---

### Task 8: End-to-end live verification

**Files:**
- Create (temporary, deleted before the final commit): `Breath - Relax & StretchUITests/BreathPhaseStepTimingUITest.swift`

**Interfaces:**
- Consumes: the complete feature (Tasks 1-7).

- [ ] **Step 1: Write a temporary XCUITest driving a real Box Breathing session**

```swift
import XCTest

/// Temporary end-to-end verification for breath phase timing. Drives a real
/// Box Breathing session (4-4-4-4) and confirms the phase label/countdown
/// actually advances at the right seconds. Deleted after manual
/// verification; not part of the permanent suite.
final class BreathPhaseStepTimingUITest: XCTestCase {
    func testBoxBreathingPhaseAdvancesOnSchedule() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
        ]
        app.launch()

        // Navigate to Exercises tab, search for Box Breathing, open it, and start it.
        app.buttons["Exercises"].tap()
        let searchField = app.textFields["Search exercises"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("Box Breathing")

        let tile = app.staticTexts["Box Breathing"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()

        let startButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Start'")).firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Skip the get-ready countdown if present.
        let skipButton = app.buttons["Skip"]
        if skipButton.waitForExistence(timeout: 3) { skipButton.tap() }

        let phaseText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Inhale ·'")).firstMatch
        XCTAssertTrue(phaseText.waitForExistence(timeout: 5), "Expected the Inhale phase to show first")
        attach(app, name: "01-inhale-phase")

        // Box Breathing's first phase (Inhale) is 4 seconds — wait past it
        // and confirm the phase actually advanced to Hold.
        let holdText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Hold ·'")).firstMatch
        XCTAssertTrue(holdText.waitForExistence(timeout: 6), "Expected the Hold phase after ~4 seconds")
        attach(app, name: "02-hold-phase")
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

- [ ] **Step 2: Run it**

Run: `xcrun simctl uninstall "iPhone 17" com.jasonlu.Breath--Relax---Stretch; xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/BreathPhaseStepTimingUITest" -resultBundlePath /tmp/BreathPhaseStepTiming.xcresult`
Expected: PASS. If any element query doesn't match the real accessibility tree, adjust the
query (not the production code) using `xcrun xcresulttool export attachments` on the failed
run's `.xcresult` to inspect the actual hierarchy dump, same as this session's established
practice for every prior feature's live verification.

- [ ] **Step 3: Export and inspect the screenshots**

```bash
mkdir -p /tmp/breath-phase-attach
xcrun xcresulttool export attachments --path /tmp/BreathPhaseStepTiming.xcresult --output-path /tmp/breath-phase-attach
```

Read both PNGs. Confirm visually: phase label + live countdown number, phase dots with the
correct one highlighted, and (per the spec) the exercise's own big countdown timer lower on
screen is unaffected/still counting down independently.

- [ ] **Step 4: Delete the temporary test and result bundle**

```bash
rm "Breath - Relax & StretchUITests/BreathPhaseStepTimingUITest.swift"
rm -rf /tmp/BreathPhaseStepTiming.xcresult /tmp/breath-phase-attach
```

- [ ] **Step 5: Run the full unit suite one final time**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: PASS, full suite.

- [ ] **Step 6: Nothing to commit**

Task 8 produces no permanent files (the UITest is deleted in Step 4) — this task's only
lasting output is the verification confidence carried into wrap-up. No commit here.
