# Coach-Mark App Tour — Design

Status: Approved for planning
Date: 2026-08-22

## Problem

The current "app guide" (`AppGuideView` + `AppGuideContent`) is a static,
full-screen slide carousel: a big SF Symbol, a title, and a description per
tab. It never touches the live UI, so it can't show a user where the
recommended-routine card actually sits, how to select a body region, or
where the create-routine button lives. It reads as marketing copy, not a
walkthrough.

We want a walkthrough that behaves like the reference (FinX-style)
screenshots: dimmed background, a spotlight cutout around a real, live UI
element, and a tooltip anchored next to it, stepping the user through the
actual app as they use it.

## Goals

- Replace `AppGuideView`/`AppGuideContent` entirely — one tutorial mechanism,
  not two.
- Auto-navigate: the tour drives tab switching itself; the user just taps
  Next (or interacts, for the one interactive step).
- Cover all 6 tab-bar icons, the Today hero card, the "Recommended for You"
  carousel, body-map region selection (as a real user tap), the exercises
  search/browse, the breathing pattern picker, the routines list and
  create-routine button, and profile stats/restart entry point.
- A "Skip" control that jumps to the next tab's section, distinct from a
  small "X" that exits the tour entirely.
- Visual style matches the existing Lumina theme (light surface, mint
  accents, `LuminaPillButtonStyle`) — not the dark card from the reference
  image.
- Same two trigger points as today: auto-shown once after onboarding, and
  replayable from Profile → Settings → Help.

## Non-goals

- No new persistence beyond the existing one-time auto-show gate.
- No pixel-accurate 3D→2D projection tracking for the body map; the
  interactive step points generally at the body silhouette rather than a
  specific muscle group's exact screen-space vertex.
- No automated UI test asserting exact spotlight-frame pixel positions —
  covered by unit tests on the state machine plus one manual simulator pass.

## Architecture

### Components

**`TourStep`** (new file `Views/Onboarding/TourCoordinator.swift`)

```swift
struct TourStep: Identifiable, Equatable {
    let id: String            // matches a .tourAnchor(id:) tag
    let tabIndex: Int?        // which HomeView tab to switch to; nil = stay
    let title: String
    let message: String
    let isInteractive: Bool   // true only for the body-map tap step
}
```

**`TourCoordinator`** — `ObservableObject`, injected as an `environmentObject`
at the app root (alongside `AuthManager`, `DeepLinkRouter`). Owns:

- `steps: [TourStep]` grouped into sections by `tabIndex`
- `isActive: Bool`, `currentStepIndex: Int`
- `currentStep: TourStep? { steps[safe: currentStepIndex] }`
- `advance()` — moves to the next step, or calls `finish()` on the last step
- `back()` — moves to the previous step (disabled on the first step of a
  section, to avoid re-triggering a tab switch backwards awkwardly — back
  only steps within the current section)
- `skipToNextSection()` — jumps to the first step whose `tabIndex` differs
  from the current step's, or `finish()` if already in the last section
- `restart()` — resets to step 0 and sets `isActive = true`
- `finish()` — sets `isActive = false`
- `notifyInteraction(id: String)` — called by a real view (only
  `BodyMapView`'s region-tap handler uses this); if `id` matches the current
  interactive step's id, calls `advance()`

**`.tourAnchor(id:)`** (new file `Views/Onboarding/TourAnchorPreference.swift`)

A view modifier that publishes the view's frame (in a shared named
coordinate space, `.named("tourSpace")`) into a `PreferenceKey`-backed
dictionary (`[String: Anchor<CGRect>]`). Applied directly to the real
elements being called out — no wrapper views, no duplicated layout.

**`TourSpotlightOverlay`** (new file `Views/Onboarding/TourSpotlightOverlay.swift`)

Mounted once, inside `HomeView`'s existing `ZStack`, above `CustomTabBar`.
Reads the anchor dictionary via `.overlayPreferenceValue`, and for the
current step:

- Builds a `Path` covering the full screen, filled with a dimmed scrim
  color, with the current step's target rect (rounded corners) subtracted
  using an even-odd fill rule. Because the cutout is excluded from the
  path's own hit-testable region, taps inside it reach the real view
  underneath automatically — no extra hit-testing plumbing needed. This is
  what makes the interactive body-map step work: the dim layer visually
  covers the app, but the user's tap still lands on `BodyMapView`.
- Renders a Lumina-styled tooltip card (title, message, progress dots,
  Back/Next/Skip, small X) positioned above or below the cutout, flipping
  side automatically to stay on-screen.
- The interactive step shows no Next button — only Skip and X — until
  `TourCoordinator.notifyInteraction` fires.

### Tab-driving

`HomeView` already owns `@State selectedTab`. It gains:

```swift
.onChange(of: tourCoordinator.currentStep?.tabIndex) { _, tab in
    if let tab { selectedTab = tab }
}
```

This reuses HomeView's existing tab state rather than introducing a second
source of truth — the tour's "auto-navigate" behavior is just the
coordinator writing into the same state a manual tab tap would.

## Step list

Six sections, one per tab. "Skip" jumps to the next section's first step.

| # | Section | Anchor id | tabIndex | Interactive |
|---|---------|-----------|----------|--------------|
| 1 | Today | `tabbar.today` | 0 | no |
| 2 | Today | `today.heroCard` | nil | no |
| 3 | Today | `today.recommended` | nil | no |
| 4 | Body | `tabbar.body` | 1 | no |
| 5 | Body | `bodymap.tapRegion` | nil | **yes** |
| 6 | Body | `bodymap.regionResults` | nil | no |
| 7 | Exercises | `tabbar.exercises` | 2 | no |
| 8 | Exercises | `exercises.search` | nil | no |
| 9 | Exercises | `exercises.browseByArea` | nil | no |
| 10 | Breathe | `tabbar.breathe` | 3 | no |
| 11 | Breathe | `breathe.patternPicker` | nil | no |
| 12 | Breathe | `breathe.previewCircle` | nil | no |
| 13 | Routines | `tabbar.routines` | 4 | no |
| 14 | Routines | `routines.sharedList` | nil | no |
| 15 | Routines | `routines.createButton` | nil | no |
| 16 | Profile | `tabbar.profile` | 5 | no |
| 17 | Profile | `profile.stats` | nil | no |
| 18 | Profile | `profile.restartTour` | nil | no → Done |

Step 5 (interactive): tooltip reads "Tap a muscle area to see exercises for
it" and points generally at the body silhouette (no per-region targeting).
`BodyMapView.handleRegionTap` gains one line calling
`tourCoordinator.notifyInteraction(id: "bodymap.tapRegion")` alongside its
existing logic, guarded so it's a no-op when the tour isn't active on that
step. Step 6 then highlights the resulting exercises-for-region view.

## Trigger & replay

Unchanged entry points, new mechanism underneath:

- `OnboardingGate` (in `OnboardingView.swift`) currently presents
  `AppGuideView` once after onboarding completes. It now calls
  `tourCoordinator.restart()` instead.
- The "restart tutorial" row in `ProfileSettingsTab.swift` calls
  `tourCoordinator.restart()` instead of presenting `AppGuideView`.

No new persistence: the same flag that gates the current one-time auto-show
keeps gating the new one.

## Files

**New:**
- `Views/Onboarding/TourCoordinator.swift`
- `Views/Onboarding/TourAnchorPreference.swift`
- `Views/Onboarding/TourSpotlightOverlay.swift`

**Removed:**
- `Views/Onboarding/AppGuideView.swift`
- `Views/Onboarding/AppGuideContent.swift`

**Edited:**
- `Breath__Relax___StretchApp.swift` — inject `TourCoordinator` as an
  `environmentObject`
- `Views/Onboarding/OnboardingView.swift` — `OnboardingGate` starts the
  coordinator instead of presenting `AppGuideView`
- `Views/Home/HomeView.swift` — host `TourSpotlightOverlay`; drive
  `selectedTab` from `coordinator.currentStep?.tabIndex`
- `Views/Home/CustomTabBar.swift` — tag each of the 6 tab buttons
- `Views/Home/TodayView.swift` — tag hero card + recommended carousel
- `Views/BodyMap/BodyMapView.swift` — tag the body region; call
  `notifyInteraction` from `handleRegionTap`
- `Views/Exercises/ExerciseListView.swift` — tag search bar + browse-by-area
  section
- `Views/Breathing/BreathingView.swift` — tag pattern picker + preview
  circle
- `Views/Routines/RoutineListView.swift` — tag shared-routines row +
  create-routine button
- `Views/Profile/ProfileView.swift` / `ProfileSettingsTab.swift` — tag
  streaks/badges; point "restart tutorial" at `coordinator.restart()`

## Testing

- Swift Testing unit tests on `TourCoordinator`: step sequencing across
  sections, `skipToNextSection()` boundary behavior (including from the
  last section), `back()` staying within a section, `restart()`, and
  `notifyInteraction` only advancing when the id matches the current
  interactive step (and being a no-op otherwise).
- One manual simulator pass via the `verify` skill: confirm the overlay
  cutout aligns with real elements (including at larger Dynamic Type
  sizes, since `CustomTabBar` already scales with `.caption`), the
  interactive body-map step actually accepts a real tap, and Skip/X/Restart
  all behave as designed. Spotlight-frame pixel alignment isn't something a
  unit test can catch.
