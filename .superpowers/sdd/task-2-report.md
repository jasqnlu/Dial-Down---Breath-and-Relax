# Task 2 Report: Remove stick figure, YouTube video, pose editing; add placeholder video slot

## What was implemented

- Added `Exercise.localVideoName: String?` (stored, inline default `nil`) and computed
  `Exercise.localVideoURL: URL?` to `Models/Exercise.swift`. `localVideoURL` resolves the
  name against `Bundle.main`; returns `nil` when unset or the file isn't actually bundled,
  so the UI always has a safe fallback.
- Created `Views/Exercises/ExerciseMediaCard.swift` exactly per the brief: renders a
  looping, muted `AVPlayer`/`VideoPlayer` when `exercise.localVideoURL` resolves, else a
  "Video coming soon" placeholder card. Never renders a broken player.
- Rewired `Views/Exercises/ExerciseDetailView.swift`: removed the `videoSource` computed
  property, the stick-figure block, and the `VideoPreviewCard` block; inserted
  `ExerciseMediaCard(exercise: exercise)` directly after the caution card, before the
  "Targets" section.
- Stripped `Views/Exercises/CreateExerciseView.swift`'s video-URL UI: removed the
  `videoURL` state, `detectedVideo` computed property, the entire `videoSection`, and its
  reference in the `Form` body and in `saveExercise()` (which no longer passes `mediaURL`,
  so new exercises default to `nil` — `Exercise.mediaURL` itself is untouched as a stored
  property). No pose-editor UI existed in this file to strip.
- Deleted the three dead files: `StickFigureView.swift`, `VideoSource.swift`,
  `VideoPreviewCard.swift`.
- Fixed every other consumer found via grep (see below).

## Judgment calls (per brief's "your judgment" callout)

- **`ForYouSection.swift` (`ForYouCard`)**: this renders many cards side-by-side in a
  horizontal scroll on the home/list screen. Autoplaying several looping `AVPlayer`
  instances at once would be wasteful and distracting, so I did not wire
  `ExerciseMediaCard` in here. Instead the stick-figure branch was removed and the card
  always shows the existing static SF Symbol placeholder (the same icon that was already
  the "no poses" fallback). This keeps the change minimal and avoids a new performance
  concern the brief didn't ask for.
- **`SessionPlayerView.swift`**: this shows exactly one exercise full-screen at a time
  during an active session, so a single looping demo video is appropriate and not wasteful.
  Replaced the `StickFigureView` block with `ExerciseMediaCard(exercise: exercise)` inside
  the existing `if exercise.type != .breath { … } else { BreathingCircle(...) }` branch.
  Note: `ExerciseMediaCard` doesn't observe `isPaused` (the brief's card has no such
  parameter) — the demo video keeps looping even if the user pauses the countdown timer.
  This matches the brief's card contract as given; I did not add pause-wiring since the
  brief didn't ask for it and doing so would mean deviating from the "verbatim" card code.

## Every grep hit fixed

`grep -rn "VideoSource\|VideoPreviewCard\|StickFigureView" "Breath - Relax & Stretch"` before
the change hit 8 files (2 of which were the deleted source files themselves). Fixed/removed
each:

1. `Views/Exercises/ExerciseDetailView.swift` — removed `videoSource` prop, stick-figure
   block, `VideoPreviewCard` block; added `ExerciseMediaCard`.
2. `Views/Exercises/VideoPreviewCard.swift` — deleted.
3. `Views/Exercises/StickFigureView.swift` — deleted.
4. `Views/Exercises/ExerciseListView.swift` — `ExerciseRow` had a `videoSource`/
   `videoBadgeTint` pair used only to badge rows that have a video. Replaced with a plain
   `hasVideo: Bool` (`exercise.localVideoURL != nil`) and a single-tint `film.fill` icon;
   updated the `accessibilityLabel` string that referenced `videoSource != nil`.
5. `Views/Exercises/VideoSource.swift` — deleted.
6. `Views/Exercises/CreateExerciseView.swift` — removed `videoURL` state, `detectedVideo`,
   `videoSection`, and the `mediaURL:` argument in `saveExercise()`.
7. `Views/Exercises/ForYouSection.swift` — `ForYouCard` StickFigureView branch removed;
   card always shows the static placeholder icon now (see judgment call above).
8. `Views/Session/SessionPlayerView.swift` — `StickFigureView` block replaced with
   `ExerciseMediaCard(exercise: exercise)` (see judgment call above).

Also grepped for `poses` usage in Views per the brief: only hits were the same
`ExerciseDetailView`/`ForYouSection`/`SessionPlayerView` StickFigureView call sites already
listed above (all fixed), plus `ExercisePose.swift`/`Exercise.swift` in Models, which were
deliberately left untouched — `Exercise.poses`/`posesData` remain as the brief instructed
("prefer keeping the model untouched except for the added `localVideoName`/`localVideoURL`").
The `StickJoint` enum in `Models/ExercisePose.swift` is now unused (was only consumed by the
deleted `StickFigureView`) but was left in place since it lives in a model file the brief
said not to touch, and Swift doesn't emit dead-code warnings for unused enums.

## TDD Evidence

**RED** — `xcodebuild test ... -only-testing:"Breath - Relax & StretchTests/ExerciseMediaTests"`
run before the model change, with only the test file in place:

```
/Users/.../ExerciseMediaTests.swift:8:19: error: value of type 'Exercise' has no member 'localVideoURL'
/Users/.../ExerciseMediaTests.swift:14:11: error: value of type 'Exercise' has no member 'localVideoName'
/Users/.../ExerciseMediaTests.swift:15:19: error: value of type 'Exercise' has no member 'localVideoURL'
Testing failed:
	Value of type 'Exercise' has no member 'localVideoURL'
	Value of type 'Exercise' has no member 'localVideoName'
	Value of type 'Exercise' has no member 'localVideoURL'
	Testing cancelled because the build failed.
** TEST FAILED **
```

**GREEN** — same command after adding `localVideoName`/`localVideoURL` to `Exercise.swift`:

```
** TEST SUCCEEDED **
Test suite 'ExerciseMediaTests' started on 'Clone 1 of iPhone 17 - BreathRelaxStretch (31067)'
Test case 'ExerciseMediaTests/localVideoURLNilWhenUnset()' passed (0.003 seconds)
Test case 'ExerciseMediaTests/localVideoURLNilWhenFileMissing()' passed (0.003 seconds)
```

## Full suite run (after all rewiring + deletions)

`xcodebuild build ...` — `** BUILD SUCCEEDED **` (confirmed the three deleted files left no
dangling references anywhere in the app target; DerivedData cleanly dropped their stale
object files).

`xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`:

```
** TEST SUCCEEDED **
```

All 4 suites passed, 40 test cases total, 0 failures:
`ExerciseMediaTests` (2), `BreathRelaxStretchTests` (1), `SharePayloadTests` (13),
`MuscleGroupsTests` (4), `GamificationServiceTests` (20).

## Files changed/deleted

Modified:
- `Breath - Relax & Stretch/Models/Exercise.swift`
- `Breath - Relax & Stretch/Views/Exercises/CreateExerciseView.swift`
- `Breath - Relax & Stretch/Views/Exercises/ExerciseDetailView.swift`
- `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift`
- `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift`
- `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`

Created:
- `Breath - Relax & Stretch/Views/Exercises/ExerciseMediaCard.swift`
- `Breath - Relax & StretchTests/ExerciseMediaTests.swift`

Deleted:
- `Breath - Relax & Stretch/Views/Exercises/StickFigureView.swift`
- `Breath - Relax & Stretch/Views/Exercises/VideoSource.swift`
- `Breath - Relax & Stretch/Views/Exercises/VideoPreviewCard.swift`

Commit: `a6fefe3` — "feat: local-video media card; remove stick figures and YouTube embeds"
(only these 11 files staged/committed; the other pre-existing unrelated working-tree
modifications from earlier tasks were left untouched and unstaged).

## Self-review

- **Completeness**: re-grepped `VideoSource|VideoPreviewCard|StickFigureView` across the
  whole app/test targets post-change — zero hits. Re-grepped `poses:`/`.poses =` — only hit
  is the pre-existing `Exercise.poses` computed property itself, which the brief said to
  leave alone. Full build + full test suite both green.
- **Quality**: `ExerciseMediaCard` was used verbatim from the brief, including its
  `NotificationCenter` observer for looping — that observer is added in `onAppear` but only
  torn down implicitly by the player being deallocated in `onDisappear` (the observer token
  itself is never explicitly removed). This is a pre-existing characteristic of the exact
  code the brief specified verbatim, not something I introduced; flagging it here rather
  than silently deviating from the given implementation.
- **YAGNI**: did not add any pause-syncing, preloading, or caching for the media card beyond
  what the brief specified. Did not touch `ExercisePose.swift`/`StickJoint` since the model
  contract was explicitly out of scope beyond the two new members.
- **Test realism**: the two tests exercise real behavior — one confirms the nil-name path,
  the other confirms that even a set-but-unbundled filename still resolves to `nil` (the
  actual `Bundle.main.url(forResource:withExtension:)` lookup runs for real in the test
  process; it isn't mocked). No fake/placeholder assertions.
- **Open item for a future task**: no exercise in seed data currently sets
  `localVideoName`, so every media card in the app will show the placeholder until Jason's
  own footage and seed-data wiring land (mentioned as separate task P1.T3 in the project's
  task list) — expected and by design for this task.

## Fix: AVPlayer observer leak

**What changed**: In `ExerciseMediaCard.swift`:
1. Added `@State private var loopObserver: NSObjectProtocol?` to store the observer token.
2. Added guard in `onAppear` to prevent double-setup when SwiftUI re-fires it: `guard player == nil else { return }`.
3. Captured the observer token from `NotificationCenter.default.addObserver()` and stored it in state.
4. In `onDisappear`, explicitly removed the observer using the stored token before nilling state vars.

This fixes the strong-capture cycle (player captured by the observer block, token never removed) and prevents orphaned player/observer pairs if `onAppear` fires twice.

**Test command**:
```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseMediaTests"
```

**Test result**:
```
** TEST SUCCEEDED **
Test suite 'ExerciseMediaTests' started on 'Clone 1 of iPhone 17 - BreathRelaxStretch'
Test case 'ExerciseMediaTests/localVideoURLNilWhenUnset()' passed (0.002 seconds)
Test case 'ExerciseMediaTests/localVideoURLNilWhenFileMissing()' passed (0.002 seconds)
```
