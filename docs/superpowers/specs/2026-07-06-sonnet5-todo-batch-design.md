# Sonnet 5 TODO batch — design

Four independent, small features pulled from TODO.md's "Bend-inspired features" and
"High Priority" sections, all tagged for Sonnet 5. Each is scoped tightly enough
to implement directly off this spec — no further exploration needed per section.

(Skipped: `uploadSession`/`uploadRoutine` decision, TODO.md:135 — explicitly
gated on "after the auth task lands," and that auth task, TODO.md:132, is still
unchecked.)

---

## 1. Duration multiplier (0.5x / 1x / 2x)

**Where:** `SessionPlayerView` only. `BreathingView`'s pattern-phase durations
are untouched — this only scales `Exercise.durationSeconds`.

**State:** `@AppStorage("sessionDurationMultiplier") private var durationMultiplier: Double = 1.0`
— global, remembered across sessions.

**UI:** A `Picker(.segmented)` with 0.5x / 1x / 2x, placed in the top bar next
to the `"\(currentIndex + 1) / \(exercises.count)"` counter.

**Behavior:** `startExercise()` computes
`Int(Double(currentExercise?.durationSeconds ?? 60) * durationMultiplier)`
instead of the raw value. Changing the control mid-exercise does not
retroactively rescale the exercise already in progress — it takes effect the
next time `startExercise()` runs (i.e. on the next exercise). This avoids
having to reconcile "how much of the elapsed fraction do I preserve"
mid-countdown for a control that's a nice-to-have, not a core mechanic.

**Out of scope:** persisting the multiplier per-routine, or applying it
retroactively to the in-progress exercise.

---

## 2. Get-ready countdown between exercises

**Where:** `SessionPlayerView.advanceToNext()` / the transition into
`startExercise()`.

**State:** new `@State private var isShowingGetReady: Bool` (or an enum case
folded into a `SessionPhase` if that reads cleaner once written) holding the
upcoming exercise for display. New setting:
`@AppStorage("autoSkipGetReadyCountdown") private var autoSkipGetReady: Bool = false`,
surfaced as a toggle in Settings (Session section, alongside the existing Voice
Cues toggle).

**Behavior:**
- Before every exercise — including the first, on session start — show a
  brief 3-2-1 interstitial with the next exercise's name (and its media
  thumbnail if cheap to include; text-only is fine for v1).
- Tapping the interstitial (or its existing skip-forward control) advances
  immediately into `startExercise()`.
- If `autoSkipGetReadyCountdown` is on, the interstitial is never shown at all
  — go straight to `startExercise()`. This is a persistent user preference,
  not a per-session toggle.
- The countdown itself does not count against the exercise's own duration or
  earn/lose points; it's purely a transition UI.

**Out of scope:** voice cue integration for the countdown itself (existing
`VoiceCueService.speak(exercise.name)` in `startExercise()` already announces
the name once the exercise begins — no need to duplicate it in the countdown).

---

## 3. Time-aware Today tab

**Where:** `TodayView.sessionExercises`, plus a new pool definition alongside
`GoalMeta` in `ForYouSection.swift` (or a new small file, e.g.
`TimeOfDayMeta.swift`, if `ForYouSection.swift` is getting crowded).

**Pools:** Two curated exercise-name lists, same shape as `GoalMeta`
(`id`, `displayName`, `exerciseNames`), reusing `GoalMeta.recommend()`'s
interleaving/dedup logic (that function already takes `allExercises` +
arbitrary goal-shaped input, so either genericize it slightly or duplicate the
~15 lines — decide during implementation based on how clean the generic looks):
- `wake_up` — energizing stretches/breathing from existing `SeedData`
  (e.g. Cat-Cow Flow, Standing Side Stretch, Box Breathing — finalize exact
  list from what's already in `SeedData.json` during implementation).
- `unwind` — calming stretches/breathing (e.g. Child's Pose, 4-7-8 Breathing,
  Seated Neck Rolls).

**Selection logic:**
```
5am–11am   -> "Wake Up" pool overrides goal-based recommendation
8pm–5am    -> "Unwind" pool overrides goal-based recommendation
11am–8pm   -> existing goal-based GoalMeta.recommend() behavior, unchanged
```
When a time-of-day pool is active, `heroCard`'s title changes from "Today's
session" to "Wake Up" / "Unwind" respectively so the override is visible, not
silent. Falls back to today's existing "first 4 catalog exercises" behavior
if the time-of-day pool is empty for some reason (mirrors the existing
fallback for goal-based recs).

**Out of scope:** touching `ForYouSection`'s "For You" carousel (goal-based,
stays as-is) — only the single hero session card on the Today tab is
time-aware.

---

## 4. Streak freeze / repair

The most involved of the four — manual restore flow with a UI prompt, per
discussion (not the original "silent auto-consume" idea from TODO.md).

**`UserProfile` — three new fields** (inline defaults, required for CloudKit
schema compatibility, matching every other field on this model):
```swift
var streakFreezeTokens: Int = 0            // uncapped
var sessionsTowardNextFreezeToken: Int = 0 // 0...6, wraps to 0 awarding a token at 7
var pendingStreakBreak: Int = 0            // 0 = no unresolved break; else the lost streak value
```

**`GamificationService` — new functions:**

```swift
/// Called on app foreground / TodayView.onAppear, NOT on session completion.
/// Detects an unresolved break in the streak from pure inactivity (as
/// opposed to updateStreak's own reset, which only fires when a session is
/// actually completed after a gap).
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

static func restoreStreak(for profile: UserProfile) {
    guard profile.streakFreezeTokens > 0, profile.pendingStreakBreak > 0 else { return }
    profile.streakFreezeTokens -= 1
    profile.streak = profile.pendingStreakBreak
    profile.pendingStreakBreak = 0
    profile.lastSessionDate = Date() // re-anchors the chain for tomorrow's normal increment
}

static func dismissStreakBreak(for profile: UserProfile) {
    profile.pendingStreakBreak = 0 // streak already 0 from detection; token untouched
}
```

**`updateStreak(for:)` changes:** clear `profile.pendingStreakBreak = 0` at
the top of the function — completing a session is forward progress that
supersedes any unresolved break UI, regardless of which branch (increment /
reset / same-day-noop) runs afterward. Also add token earning at the end:
```swift
profile.sessionsTowardNextFreezeToken += 1
if profile.sessionsTowardNextFreezeToken >= 7 {
    profile.sessionsTowardNextFreezeToken = 0
    profile.streakFreezeTokens += 1
}
```

**UI — `TodayView`:** on `.onAppear`, call `checkForBrokenStreak(for: profile)`;
if non-nil, present an alert (SwiftUI `.alert` with two buttons is sufficient —
no need for a custom sheet):
- Title: "Streak Lost"
- Message: "Your \(n)-day streak was lost."
- Button "Restore Streak (\(tokens) left)" — only shown if `streakFreezeTokens > 0`;
  calls `restoreStreak(for:)`.
- Button "Dismiss" — calls `dismissStreakBreak(for:)`.

Only pops up when `pendingStreakBreak > 0`, which itself is only set when the
pre-break streak was `>= 2` — satisfies "only if streak was at least 2."
Persisted in the model (not a transient flag), so the prompt survives an app
relaunch if the user closes the app before responding.

**Tests (Swift Testing, matching `GamificationServiceTests.swift`'s existing
style):** `checkForBrokenStreak` (no break / break detected / already-pending
returns same value / streak-of-1 doesn't trigger), `restoreStreak` (consumes
token, restores value, no-op with zero tokens), `dismissStreakBreak`, token
earning at the 7-session boundary, `updateStreak` clearing a stale pending
break.

**Out of scope:** any UI surfacing of `streakFreezeTokens` count outside the
alert itself (e.g. a profile badge/tile showing "2 savers banked") — can be a
follow-up if wanted later.
