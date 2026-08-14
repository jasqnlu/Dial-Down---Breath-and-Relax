# Breath Phase Timing — Design Spec

**Date:** 2026-08-13
**Status:** Approved via chat design review, not yet implemented.
**Supersedes (partially):** `2026-08-01-exercise-session-cues-design.md`'s Non-goals line
*"No per-exercise custom cue text, phase timing, or multi-state badges"* — for Breath-type
exercises that opt in with an authored pattern, per this spec. Everything else in that spec
(the cue badge, the flat 3.5s instruction-cycling for exercises without a pattern, the four
existing beep call sites) is unchanged and stays in force.

## Why

`Exercise.instructions` already encodes real phase timing as prose — e.g. Box Breathing's
steps read "Inhale through your nose for 4 counts," "Hold for 4 counts," "Exhale through your
mouth for 4 counts," "Hold for 4 counts" — but `SessionPlayerView` cycles every instruction
line on a flat 3.5s dwell timer regardless of what the text says. A user following along has
no way to know when to actually switch from inhaling to holding; the on-screen text and the
real breath count are unrelated. This spec makes the display and audio cues track the real,
authored count for exercises that have one.

## Scope

**Breath-type exercises only**, and only those with an authored pattern. Stretch-type
exercises (and Breath-type exercises without an authored pattern) are completely unchanged —
they keep the existing flat instruction-cycling from the Aug 1 spec.

## Data model

New pure value type:

```swift
struct BreathPhase: Codable, Equatable {
    let label: String   // "Inhale", "Hold", "Exhale"
    let seconds: Int
}
```

`Exercise` gains a primitive-typed stored property, mirroring the existing `posesData`/`poses`
pattern exactly (`Exercise.swift`'s documented constraint: SwiftData's lightweight migration
cannot safely decode a custom-enum-typed property added after real data exists — every field
added post-launch uses a primitive raw store + computed decode property for this reason):

```swift
var breathPatternData: Data = Data()

var breathPattern: [BreathPhase] {
    get { (try? JSONDecoder().decode([BreathPhase].self, from: breathPatternData)) ?? [] }
    set { breathPatternData = (try? JSONEncoder().encode(newValue)) ?? Data() }
}
```

An empty array (the default) means "no pattern authored" — falls back to existing behavior.

### Pure logic: `BreathPhaseCycle`

```swift
enum BreathPhaseCycle {
    struct Resolved: Equatable {
        let phaseIndex: Int
        let secondsRemainingInPhase: Int
    }
    static func resolve(pattern: [BreathPhase], elapsedSeconds: Int) -> Resolved?
}
```

Given the pattern and seconds elapsed since the exercise began, wraps `elapsedSeconds` by the
pattern's total duration (sum of all phases' `seconds`) to find position within the repeating
cycle, then walks phases to find which one that position falls into and how many seconds
remain in it. Returns `nil` for an empty pattern. No SwiftUI, no timers, no `Date` — a pure
function, directly unit-testable (same shape as `RoadmapWaveGeometry`, `ExercisePickerCandidates`,
`CustomizeRoutineExerciseMerge`).

### Seed data + migration

`SeedData.json`'s Breath exercises gain an optional `breathPattern` array, e.g. Box Breathing:

```json
"breathPattern": [
  {"label": "Inhale", "seconds": 4},
  {"label": "Hold",    "seconds": 4},
  {"label": "Exhale",  "seconds": 4},
  {"label": "Hold",    "seconds": 4}
]
```

Authored for a first batch with clean, unambiguous counts: Box Breathing, 4-7-8 Breathing,
Deep Belly Breath, Pursed-Lip Breathing, Diaphragmatic Breath with Counting. The remaining
Breath exercises ship with no `breathPattern` and keep today's flat-cycling behavior until
authored later — this is additive and never blocks on covering all ~25 at once.

New installs read `breathPattern` off the bundle JSON at seed-insert time, same place
`cueStyle`/`animationName` are read today. Already-seeded installs get `SeedMigrator.migrateV11`,
following the `migrateV7`/`migrateV8` pattern exactly: match by `seedID`, only fill when the
bundle has a non-empty pattern, never touch user-created rows. `seedDataVersion` advances to 11
in `Breath__Relax___StretchApp.swift`'s migration ladder. `latestContentSeedVersion` is **not**
bumped — data-only migration, not new exercise content, matching `migrateV8`'s treatment.

## Timing mechanism

Not a sleep-based async task (unlike the existing `instructionCueTask`). To show a live
per-second countdown ("Inhale · 3"), the current phase is computed **inside the existing
1-second `Timer.publish` tick** that already drives `secondsRemaining` and calls
`checkSideSwitch()` — no new task, no new sleep loop:

1. `startExercise()` checks `exercise.breathPattern.isEmpty`:
   - Non-empty: skip starting the existing `instructionCueTask`; breath-phase state is derived
     each tick instead (below).
   - Empty: unchanged — `instructionCueTask` starts exactly as it does today.
2. Every existing 1-second tick (the `.task { Timer.publish(...) }` loop), when a pattern is
   active: compute `elapsed = scaledDuration(exercise) - secondsRemaining`, call
   `BreathPhaseCycle.resolve(pattern:, elapsedSeconds: elapsed)`.
   - Update `@State private var breathPhaseSecondsRemaining` to the resolved value every tick
     (drives the live "· 3" countdown).
   - If the resolved `phaseIndex` differs from the previous tick's (a transition): update
     `@State private var currentBreathPhaseIndex`, play `soundCueBeep` (the same existing
     sound, no new `SystemSoundID`), and call `VoiceCueService.shared.speak(phase.label)`.
3. Pause: the tick loop already no-ops while `isPaused` (existing `guard`), so breath-phase
   state simply stops updating too — no separate pause handling needed.
4. Backgrounding: because this is derived from `phaseEndDate`-based elapsed time (the same
   wall-clock math `secondsRemaining` and `catchUpAfterBackground()` already use), the correct
   phase and remaining-seconds are recomputed automatically on the next tick after returning
   to the foreground. No special-case code, and — unlike `instructionCueTask`'s existing
   sleep-based cycling, which does *not* self-correct after backgrounding — this mechanism has
   no equivalent drift to inherit.

## UI

Replaces the existing `instructionCue(for:)` view in the same slot (between the media/breathing
circle and the countdown timer), only when `exercise.breathPattern` is non-empty:

- Current phase label + live countdown: `"Inhale · 3"`, ticking down each second, same font
  (`.luminaLabel`) and the same `.asymmetric` slide-in/fade-out transition already used for
  instruction cycling, triggered on phase change (not every second — only the label/beep
  moment animates; the countdown digit itself just updates in place).
- A small row of dots below it, one per phase in the pattern, current one highlighted —
  answers "where am I in the whole cycle," which the countdown alone doesn't (e.g. distinguishes
  the first "Hold" from the second one in Box Breathing's 4-phase pattern).
- The existing large countdown numerals (exercise's total remaining time) are unchanged —
  no second big number; the phase countdown is smaller, inline with the label text.
- The existing cue badge (`cueBadge(for:)`, "Hold"/"Keep Going") is unchanged — static,
  unrelated to the phase cycle.

### Get-ready screen

For exercises with a `breathPattern`, `exercise.instructions` (the prose setup lines — "Sit
comfortably...", "Exhale completely to start.") is no longer cycled live during the exercise.
It's shown as a compact preview on the existing `getReadyView(name:)` screen instead (which
already shows name + caution before the exercise starts) — a natural home for one-time setup
context, cleanly separating it from the repeating phase loop. Exercises without a pattern are
unaffected; their `instructions` keep cycling live exactly as today.

## Non-goals

- No change to Stretch-type exercises, or to Breath-type exercises without an authored pattern
  — both keep the exact existing Aug 1 behavior (cue badge, flat instruction-cycling).
- No change to `cueStyle`, `isBilateral`/side-switch logic, points (`GamificationService`), or
  `SessionRecorder` — purely a display/audio concern for pattern-bearing Breath exercises.
- No attempt to author all ~25 Breath exercises' patterns in this pass — five to start,
  the rest follow later as a content task, not a code change.
- No new `SystemSoundID` — reuses the existing `soundCueBeep` (1103).
- No UI change to `BreathingCircle`'s pulse animation — it keeps its current duration-derived
  cadence, independent of the phase cycle (a future spec could sync them; out of scope here).

## Testing

- `BreathPhaseCycle.resolve`: pure Swift Testing unit tests — phase resolution at various
  elapsed times, wraparound after the pattern's total duration, empty-pattern → `nil`,
  single-phase pattern, elapsed time landing exactly on a phase boundary.
- `Exercise.breathPattern`: encode/decode round-trip test, mirroring
  `ExerciseCueStyleTests.swift`'s existing coverage of `cueStyleRaw`/`cueStyle`.
- `SeedMigrator.migrateV11`: backfill test mirroring `SeedMigratorTests.swift`'s existing
  `migrateV7`/`migrateV8` coverage — matched by `seedID`, never touches user-created rows,
  no-op when the bundle has no pattern for a given exercise.
- Live simulator verification (temporary XCUITest per this session's established practice,
  deleted before commit): drive one real pattern (Box Breathing, 4-4-4-4) and confirm the
  displayed phase/countdown actually advances at the right seconds, not just that the unit
  tests pass. Beeps and voice cues are audio-only and not screenshot-verifiable — spot-checked
  by ear during manual verification, matching the Aug 1 spec's same caveat for its own beeps.
