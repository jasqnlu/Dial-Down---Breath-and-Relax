# Exercise Session Cues — Hold vs. Keep-Going, Design

**Date:** 2026-08-01
**Status:** Approved (mockup reviewed at `docs/mockups/exercise-session-cue-badges.html`)

## Goal

During an exercise in `SessionPlayerView`, show on-screen text that tells the
user whether this exercise is a **static hold** (stay in position for the
duration) or something they should **do consistently/rhythmically** for the
duration (repeated motion). Today the player shows the exercise name, type
badge, media, and a countdown — nothing distinguishes "hold this" from "keep
moving," and `Exercise.instructions` (already authored, stored per exercise)
is never shown anywhere in the session flow.

## Data model

Add a new field to `Exercise`:

```swift
enum ExerciseCueStyle: String, Codable, CaseIterable {
    case hold = "Hold"
    case repeatMotion = "Repeat"
}

var cueStyle: ExerciseCueStyle = .hold
```

- Inline default `.hold`, matching the CloudKit-safe-default pattern already
  used for every other `Exercise` field.
- `init(...)` gains a `cueStyle: ExerciseCueStyle = .hold` parameter,
  following the existing `isBilateral` parameter's pattern exactly.

### Seed data + migration

`SeedData.json`'s 207 exercises each get an authored `"cueStyle"` value
(lowercase `"hold"` or `"repeat"`, matching the existing lowercase `"type"`
convention — `Breath__Relax___StretchApp.swift`'s seed-insert path parses
`ExerciseType` via `ExerciseType(rawValue: typeStr.capitalized)`, and
`cueStyle` follows the same `rawStr.capitalized` lookup against
`ExerciseCueStyle`'s `"Hold"`/`"Repeat"` rawValues), hand-classified from
each exercise's actual instructions (not guessed from `type` — many
`stretch`-typed exercises are dynamic mobility drills, e.g. arm circles,
cat-cow, marching in place, and some `breath` exercises describe a single
sustained hold). The classification pass and its output are tracked
separately from this spec; every seed exercise ships with a real, reviewed
value — no heuristic fallback baked into the app.

New installs read `cueStyle` off the bundle JSON at seed-insert time
(`BreathRelaxStretchApp.swift`'s existing insert path, same place
`animationName` and `isBilateral` are read today, defaulting to `.hold` when
the field is absent/unparseable — same optional-with-fallback treatment
`isBilateral` gets via `?? true`). Already-seeded installs get a new migration,
following the `migrateV6`/`migrateV7` pattern (match by `seedID`, only fill
when the bundle has a value, never touch user-created rows):

```swift
/// v8 — backfills `Exercise.cueStyle` onto already-seeded rows, matched by
/// `seedID`. New installs already read `cueStyle` at insert time; this only
/// matters for users seeded before the field existed. Parses the bundle's
/// lowercase string via `ExerciseCueStyle(rawValue: raw.capitalized)`, same
/// as the insert-time parsing.
static func migrateV8(context: ModelContext, rawExercises: [[String: Any]]) -> Bool
```

`seedDataVersion` advances to 8 in `BreathRelaxStretchApp.swift`, following
the `migrateSeedIfNeeded` ladder pattern exactly (`guard seedDataVersion < 8`,
run `migrateV8`, `seedDataVersion = 8`). `latestContentSeedVersion` (used for
the "New Content Added" alert) is **not** bumped — this is a data-only
migration like v5's `isBilateral` backfill, not new exercise content.

User-created exercises default to `.hold` (the inline default) and are never
touched by the migration — same treatment `isBilateral`/`seedID` get.

## UI: `SessionPlayerView`

Two additions to `playerContent(exercise:)`, both new — nothing existing
changes position or behavior:

### 1. Cue badge

A small pill directly under the exercise name/type (already-established
Lumina styling — `Color.luminaMintTint` background, `Color.luminaPrimary`
text, pill shape, uppercase `.luminaLabel`-weight text):

- `.hold` → static "Hold" badge, no animation.
- `.repeatMotion` → "Keep Going" badge that continuously pulses (scale
  1 → 1.07 → 1, opacity 1 → 0.82 → 1, ease-in-out, ~1.1s loop) — a passive
  rhythm cue, independent of the instruction-cycling cadence below.

### 2. Instruction cue text

Between the media card (`ExerciseMediaCard` / `BreathingCircle`) and the
countdown timer: the current step from `exercise.instructions`, one line at
a time.

- If `instructions.isEmpty`, this view is omitted entirely (no empty space).
- If `instructions.count == 1`, that single instruction is shown statically
  — no cycling, no transition.
- Otherwise, steps cycle on a fixed **3.5s dwell timer**, looping back to the
  first step after the last. The dwell time is the same for `.hold` and
  `.repeatMotion` — cycling speed communicates nothing here; the badge
  already carries the hold/repeat signal. (This deliberately overrides the
  mockup's per-mode `stepMs`, which was tuned for a fast demo loop, not real
  reading comfort.)

**Transition, per the reviewed mockup's animation note:** each new line pops
in from the left — starts offset ~24pt left and 0 opacity, animates to its
resting position and full opacity over ~0.35s (ease-out) — dwells, then
fades out in place (opacity only, ~0.25s, no horizontal motion) immediately
before the next line's pop-in begins. Implement as a `.transition` pair on
the `Text(currentInstruction)` view, keyed by the instruction index so
SwiftUI treats each step as a distinct view for the transition:

```swift
.transition(.asymmetric(
    insertion: .move(edge: .leading).combined(with: .opacity),
    removal: .opacity
))
```

driven by `withAnimation(.easeOut(duration: 0.35))` on insert and
`withAnimation(.easeIn(duration: 0.25))` on the remove that a `Timer`-driven
index change triggers — mirroring the existing `.task { Timer.publish(...) }`
loop already in `SessionPlayerView` (a second lightweight tick, not
reusing the countdown timer's 1Hz tick, since 3.5s doesn't divide it cleanly).

### 3. Cue reminder beeps

A short, quiet beep — a fourth `SystemSoundID`, distinct from the three
already in `SessionPlayerView` (`soundTick` 1104, `soundTransition` 1057,
`soundComplete` 1016) — plays as a lightweight audio reminder each time a
new cue *pops up on screen*, plus at the start and natural end of each
exercise:

```swift
private let soundCueBeep: SystemSoundID = 1103  // soft low tock — cue reminder
```

`1103` is a reasonable low/soft system tone candidate; confirm it reads as
"low beep" (not jarring, distinguishable from the other three) on a real
device during implementation and swap it if not — this is a listen-and-adjust
value, not load-bearing on anything else.

Fires at exactly four call sites, all already-existing methods:

- **Exercise start** — in `startExercise()`, alongside the existing
  `VoiceCueService.shared.speak(exercise.name)` call.
- **Instruction cue pop-in** — inside the new instruction-cycling tick
  (§2), each time the displayed instruction advances. Not fired when
  `instructions.count <= 1` (nothing ever pops, per §2).
- **Side switch** — in the existing `checkSideSwitch()`, alongside the
  existing `VoiceCueService.shared.speak("Switch sides")` call. This is the
  one existing behavior this spec touches: unilateral exercises' halfway-point
  "switch sides" moment gets the same reminder beep as the new cues, since
  it's the same kind of "look, a new instruction" moment. No timing or
  trigger-condition change — only the added beep.
- **Exercise natural end** — in the `.task` countdown loop, right before
  `advanceToNext(completion: 1.0)` fires because `remaining <= 0` (i.e. the
  exercise's own timer ran out). Does **not** fire on manual skip (the skip
  button's own tap handler calls `advanceToNext` directly and already has
  its own feedback — a haptic `impactLight` — so a second sound there would
  be redundant/confusing for a user-initiated skip).

## Non-goals

- No change to exercise duration, countdown, or pause/skip logic. Side-switch
  logic itself (timing, trigger condition) is unchanged — it only gains the
  reminder beep described in §3.
- No change to the exercise list/detail pages, `ExerciseMediaCard`, or the
  get-ready screen — the badge, instruction cue, and beeps exist only inside
  the active `playerContent` exercise screen, matching the reviewed mockup.
- No new exercise content beyond the `cueStyle` field itself — the "switch to
  the other side/finger/toe," "hold," and "keep going" cues for exercises
  with alternating movements (the 12 exercises flagged low-confidence during
  classification: toe/finger stretches, Frontalis/Suboccipital release,
  Wrist & Forearm Release, etc.) come from their existing, already-authored
  `instructions` steps via the instruction-cycling in §2 — no per-exercise
  timing/phase data model. All 12 are classified `repeat`.
- No per-exercise custom cue text, phase timing, or multi-state badges — the
  badge is always exactly one of two states for an exercise's whole duration.
- `ExerciseCueStyle` does not affect `isBilateral`/side-switch logic, points
  (`GamificationService`), or `SessionRecorder` — purely a display/audio
  concern.

## Testing

- Unit tests: `Exercise.cueStyle` default, `SeedMigrator.migrateV8` (mirrors
  existing `v6BackfillsSeedIDForLegacyRowsByName`/`v7...` test shapes —
  matched-by-seedID backfill, never touches user-created rows, never
  clobbers an already-set value... though note `cueStyle` has no "unset"
  state to preserve, unlike `animationName`'s empty-string check, so this
  migration always overwrites from the bundle when `seedID` matches, same
  as `migrateV5`'s `isBilateral` backfill).
- UITest / simulator verification: confirm the badge and instruction text
  render during a live session for one `.hold` and one `.repeatMotion`
  exercise, screenshot-checked per the repo's `verify` skill. Beeps are
  audio-only and not screenshot-verifiable — spot-check by ear on the
  simulator/device during manual verification instead of via UITest.
