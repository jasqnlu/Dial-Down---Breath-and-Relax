# App Launch Preload + Loading Screen

## Problem

`BodySceneView` shows a "Loading 3D model…" spinner the first time the user
opens Body Map, because `BodyRig.loadIfNeeded()` triggers `BodyMeshLoader`
to parse `BodySkinMuscle.obj` — a 12MB text mesh file — off the main thread
(`BodySceneView.swift:241-254`). `BodyMeshLoader` is an actor that caches
the parsed `[AnatomyPiece]` array in memory for the rest of the process
(`BodySceneView.swift:70-91`), so the parse only happens once per app
launch — but today that "once" lands on whatever moment the user first
navigates to Body Map, which reads as the feature stalling.

The user wants that first-time cost hidden behind a dedicated app loading
screen shown at launch, so Body Map never shows its own loading state.

## Non-goals

- Seed data seeding/migration (`seedIfNeeded`, `migrateSeedIfNeeded` in
  `Breath__Relax___StretchApp.swift`) and the best-effort Supabase catalog
  sync (`syncRemoteCatalog`) are **not** part of this gate. Seeding/migration
  are fast local SwiftData writes with no visible loading state today;
  folding sync (a network call) into a blocking splash would make launch
  hang for users on a slow or absent connection, which contradicts the
  app's offline-first design. Both continue to run exactly as they do today.
- `BodySceneView`'s own `isLoading` spinner and `ContentUnavailableView`
  failure state are not removed — they remain as a safety net (e.g. a
  corrupted/missing bundle resource). In normal operation the cache is
  already warm by the time Body Map mounts, so that code path just stops
  being reachable in practice.

## Design

Visual reference: `docs/mockups/app-loading-screen.html` (HTML mockup,
reviewed and approved before implementation).

### 1. `AppLoadingView` (new)

A new SwiftUI view, styled to match the existing `WelcomePage.swift`
onboarding branding rather than inventing a new visual language:

- `Color.luminaSurface` background (already dark-mode aware).
- `Image(systemName: "lungs.fill")` hero icon in `Color.luminaPrimary`,
  in a circular badge (`Color.luminaMintTint` fill, `clipShape(Circle())`)
  — a circle rather than the rounded-square badge `WelcomePage`'s
  `FeatureRow` uses, so it nests concentrically inside the breathing-pulse
  ring animation around it.
- App name in `.luminaDisplay` font.
- An indeterminate `ProgressView()` beneath, per the earlier design
  decision (a determinate progress bar would require threading progress
  callbacks through the OBJ line-parser, which isn't worth the complexity
  for a sub-second, one-time cost).
- A **trivia card**: a tappable rounded-rect area (`Color.luminaMintTint`,
  matching the hero badge tint) showing one random fact from a curated,
  hardcoded `BodyTrivia.facts: [String]` array (~17 short body/stretching/
  breathing facts — see mockup for the exact copy). Tapping the card swaps
  in a different random fact (never immediately repeating the current one)
  with a quick crossfade. This is the same interaction as the approved
  mockup's tap-to-shuffle card.
- A minimum display duration: the splash stays up for **at least 1.5s**
  even if the mesh preload finishes sooner, so there's time to read a
  fact; it never waits *longer* than the real preload takes if that's
  slower. **Tapping the card to see another fact does not extend this
  window** — it's a fixed 1.5s minimum regardless of taps, kept simple
  rather than adding per-tap timer-extension state for a screen that's
  only up for a couple of seconds either way.

No dismiss button — the only interactivity is the tap-for-another-fact
card; dismissal is automatic once both the preload and minimum duration
are satisfied.

### 2. `BodyTrivia` (new)

A small enum or struct in a new `BodyTrivia.swift` (e.g. in `Models/` or
alongside `AppLoadingView`) holding the static fact list and a
`randomFact(excluding:)` helper that picks a random entry different from
the currently-shown one (mirrors the mockup's `showRandomFact()` no-repeat
logic). Pure data + a pure function — no dependencies, trivially testable.

### 3. `BreathRelaxStretchApp` gains a preload gate

```swift
@State private var isPreloading = true

var body: some Scene {
    WindowGroup {
        Group {
            if isPreloading {
                AppLoadingView()
                    .transition(.opacity)
            } else {
                OnboardingGate { RootView() }
                    .preferredColorScheme(resolvedColorScheme)
                    .environmentObject(auth)
                    .environmentObject(deepLinkRouter)
                    .onAppear { /* existing seed/migrate/alert logic, unchanged */ }
                    .alert(...) { ... }   // unchanged
                    .task { await syncRemoteCatalog() }  // unchanged
                    .onOpenURL { ... }     // unchanged
            }
        }
        .task {
            async let preload: () = BodyMeshLoader.shared.anatomyParts()
            async let minimumDelay: () = Task.sleep(nanoseconds: 1_500_000_000)
            _ = await (preload, try? minimumDelay)
            withAnimation(.easeInOut(duration: 0.3)) {
                isPreloading = false
            }
        }
    }
    .modelContainer(sharedModelContainer)
}
```

Everything currently attached to the `OnboardingGate { RootView() }` chain
(color scheme, environment objects, seed/migration `.onAppear`, the two
`.alert`s, `syncRemoteCatalog` `.task`, `.onOpenURL`) moves onto that same
view unchanged — only its mount time shifts, from "immediately" to "after
the splash task finishes." Since seeding/migration are synchronous local
writes and the remote sync is already async/best-effort, this has no
observable behavior change beyond the splash itself.

`BodyMeshLoader` is already internal-visibility (`actor BodyMeshLoader` in
`BodySceneView.swift`), so no access-level changes are needed to call it
from the app target's launch code.

### 4. Data flow

1. Cold launch → `WindowGroup` renders the `Group` → `AppLoadingView`
   appears immediately, showing one random fact.
2. In parallel, the `.task` on `Group` races two things: the mesh preload
   (`BodyMeshLoader.shared.anatomyParts()`) and a 1.5s minimum-duration
   timer. Both must finish before the splash dismisses.
3. While waiting, the user may tap the trivia card any number of times to
   see other facts — purely a local `@State` swap inside `AppLoadingView`,
   independent of the preload/timer race above.
4. Once both the preload and the minimum duration are satisfied,
   `isPreloading` flips to `false` inside `withAnimation`, crossfading
   into `OnboardingGate { RootView() }`.
5. Later, when the user navigates to Body Map, `BodySceneView`'s own
   `.task(id:)` still calls `rig.loadIfNeeded()` →
   `BodyMeshLoader.shared.anatomyParts()`, which now hits the warm
   `partsCache` and returns near-instantly — `isLoading` flips `false`
   before the spinner gets a visible frame.

### 5. Error handling

If the OBJ fails to parse (missing/corrupt bundle resource),
`anatomyParts()` returns `nil`. The splash `.task` doesn't inspect the
result — it dismisses either way, so a failure never hangs launch. The
user only discovers the failure later, on-demand, via `BodySceneView`'s
existing `ContentUnavailableView("3D Model Unavailable")` — unchanged
behavior, just now reachable only in a genuine failure case rather than
also covering the common "still parsing" case.

No artificial timeout is added beyond the fixed 1.5s minimum-duration
timer above: parsing a bundled local file has no external I/O to hang on,
and real-device parse time is expected to be a fraction of a second to
low seconds, well within what a launch splash can absorb.

### 6. Testing

`BodyTrivia.randomFact(excluding:)` gets a small unit test (deterministic
enough to assert: never returns the excluded fact when more than one
fact exists, always returns a fact from the static list). Everything else
here is UI sequencing, not business logic, so no further unit tests are
needed. Verification is a simulator check (per the repo's `verify`
skill):

- Cold launch → confirm `AppLoadingView` appears, shows a fact, and
  crossfades into onboarding/home no sooner than ~1.5s.
- Tap the trivia card during the splash → confirm the fact changes and
  the splash doesn't dismiss early or late because of the tap.
- Navigate to Body Map immediately after launch → confirm no
  "Loading 3D model…" spinner is visible.
- Confirm existing `BodySceneView` fallback UI (spinner / unavailable
  state) still compiles and is reachable in principle, even though it's
  not expected to trigger in normal use.
