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

### 1. `AppLoadingView` (new)

A new SwiftUI view, styled to match the existing `WelcomePage.swift`
onboarding branding rather than inventing a new visual language:

- `Color.luminaSurface` background (already dark-mode aware).
- `Image(systemName: "lungs.fill")` hero icon in `Color.luminaPrimary`,
  same treatment as `WelcomePage`.
- App name in `.luminaDisplay` font.
- An indeterminate `ProgressView()` beneath, per the earlier design
  decision (a determinate progress bar would require threading progress
  callbacks through the OBJ line-parser, which isn't worth the complexity
  for a sub-second, one-time cost).

No interactivity, no dismiss button — it's purely a launch-time gate.

### 2. `BreathRelaxStretchApp` gains a preload gate

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
            await BodyMeshLoader.shared.anatomyParts()
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

### 3. Data flow

1. Cold launch → `WindowGroup` renders the `Group` → `AppLoadingView`
   appears immediately.
2. In parallel, the `.task` on `Group` awaits
   `BodyMeshLoader.shared.anatomyParts()` (off-main-thread parse of the
   bundled OBJ).
3. On completion (success *or* nil failure — the task doesn't branch on
   the result), `isPreloading` flips to `false` inside `withAnimation`,
   crossfading into `OnboardingGate { RootView() }`.
4. Later, when the user navigates to Body Map, `BodySceneView`'s own
   `.task(id:)` still calls `rig.loadIfNeeded()` →
   `BodyMeshLoader.shared.anatomyParts()`, which now hits the warm
   `partsCache` and returns near-instantly — `isLoading` flips `false`
   before the spinner gets a visible frame.

### 4. Error handling

If the OBJ fails to parse (missing/corrupt bundle resource),
`anatomyParts()` returns `nil`. The splash `.task` doesn't inspect the
result — it dismisses either way, so a failure never hangs launch. The
user only discovers the failure later, on-demand, via `BodySceneView`'s
existing `ContentUnavailableView("3D Model Unavailable")` — unchanged
behavior, just now reachable only in a genuine failure case rather than
also covering the common "still parsing" case.

No artificial timeout is added: parsing a bundled local file has no
external I/O to hang on, and real-device parse time is expected to be a
fraction of a second to low seconds, well within what a launch splash can
absorb.

### 5. Testing

This is a UI sequencing change, not new business logic, so no new unit
tests are needed. Verification is a simulator check (per the repo's
`verify` skill):

- Cold launch → confirm `AppLoadingView` appears and crossfades into
  onboarding/home.
- Navigate to Body Map immediately after launch → confirm no
  "Loading 3D model…" spinner is visible.
- Confirm existing `BodySceneView` fallback UI (spinner / unavailable
  state) still compiles and is reachable in principle, even though it's
  not expected to trigger in normal use.
