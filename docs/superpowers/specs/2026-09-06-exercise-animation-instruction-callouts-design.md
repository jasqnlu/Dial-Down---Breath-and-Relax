# Exercise animation instruction callouts

Date: 2026-09-06
Status: Approved, ready for implementation

## Problem

`Exercise.animationIsApproximate` (Exercise.swift) flags 137 of 372 exercises
whose generated 3D animation can't show the real motion because the rig has no
bone for the joint that actually moves (no wrist/hand/ankle/foot bone — see
`Tools/blender/exercises/ANIMATION_HANDOFF.md`). Today the only mitigation is a
single static caption below the video ("This animation may not be 100%
accurate to the exercise."), shown via `AnimationAccuracyNote`
(SafetyComponents.swift). It doesn't say *what* the user should actually be
doing at the moment the animation diverges from the instructions.

## Goal

For exercises where we know the specific mismatch, flash a small arrow +
instruction text over the video, timed to the moment in the loop where the
rig's motion doesn't match the real exercise (e.g. "Rotate your ankle in a
circle" with a circular arrow drawn over the ankle). Exercises without an
authored callout keep today's generic disclaimer — this is an incremental,
opt-in enhancement per exercise, not a redo of all 137 at once.

## Approach

Overlay lives entirely in Swift, drawn on top of the existing baked mp4 loop —
**not** burned into the Blender render. All 307+ already-rendered clips stay
untouched. This keeps the feature localizable, VoiceOver-accessible, and
tunable (retime/reposition without re-rendering Blender).

## Data model

`Exercise.swift` gains an optional struct alongside the existing bool (kept
for backward-compatible fallback):

```swift
struct AnimationCallout: Codable, Equatable {
    enum Shape: String, Codable { case rotate, swingArc, pushPull, pulse }
    var text: String        // "Rotate your ankle in a circle"
    var shape: Shape
    var anchor: CGPoint     // normalized 0-1 position within the video frame
    var angle: Double       // orientation / arc-start angle; meaning depends on `shape`
    var startTime: Double   // seconds into the 4s loop when it should appear
    var duration: Double = 2.0
}

var animationCallout: AnimationCallout? = nil
```

Resolution order for what the media card shows below/over the video:
1. `animationCallout != nil` → flashing overlay (this feature). The generic
   static disclaimer is replaced by the overlay for this exercise — no double
   messaging.
2. `animationCallout == nil && animationIsApproximate == true` → today's
   `AnimationAccuracyNote` (unchanged).
3. Neither → nothing (unchanged).

Seed data: `animationCallout` is optional in `SeedData.json`, decoded the same
way `animationName`/`animationIsApproximate` are. No new migration version is
required for exercises that don't set it (mirrors the existing
`animationName` migration pattern — see `SeedMigrator.swift`).

## Rendering

New `AnimationCalloutOverlay` view (Views/Exercises/):
- Four reusable SwiftUI `Shape` primitives, selected by `AnimationCallout.shape`:
  - `.rotate` — full circular arrow (for joint rotations: ankle circles, wrist
    circles, neck rotation)
  - `.swingArc` — partial arc with arrowhead (for a limb swinging through a
    partial range: flexion/extension)
  - `.pushPull` — straight arrow (for linear direction: push forward, reach up)
  - `.pulse` — expanding ring, no direction (for "focus here" emphasis when no
    directional cue is needed)
- `angle` orients the shape (arrowhead direction / arc start angle);
  interpretation is per-shape, documented on the enum cases.
- Text renders in a small pill/badge near the arrow (not overlapping it),
  using the existing caption styling from `AnimationAccuracyNote` for visual
  consistency.

`ExerciseMediaCard` adds an `.overlay(alignment: .topLeading)` positioned via
`GeometryReader` using `anchor` (fractional position × frame size). Visibility
is driven by an `AVPlayer.addPeriodicTimeObserver` callback: opacity ramps
0→1 over 0.3s starting at `startTime`, holds, ramps 1→0 over 0.3s ending at
`startTime + duration`, and re-arms on each loop restart (the existing
`AVPlayerItemDidPlayToEndTime` observer already resets to `.zero`). Reduce
Motion: since the video itself is paused on Reduce Motion, the callout is
shown statically (opacity 1, no fade) rather than never appearing — the user
still needs the instruction.

The pure "time → opacity" envelope function is extracted as a standalone,
unit-testable function (no view/player dependency), e.g.
`AnimationCallout.opacity(atLoopTime:)`.

## Accessibility

The instruction `text` is exposed via a persistent `accessibilityLabel` on the
overlay container, independent of the fade timing — VoiceOver users get the
instruction regardless of playback position. The arrow shape itself is
`accessibilityHidden(true)`.

## Authoring

For each exercise given a callout: pick `shape`, eyeball `anchor` (normalized
position) and `angle` against the already-rendered clip, pick `startTime`
(typically synced to the pose's peak frame — already known per exercise from
the Blender `PEAK_FRAME`/render pipeline), and write `text`. No Blender
changes. This is authored incrementally, batch by batch, the same way the
animations themselves were built (see `exercise-animation-app-integration`
memory) — not all 137 at once.

## Testing

- Unit tests for `AnimationCallout.opacity(atLoopTime:)` (before fade-in,
  during fade-in, holding, during fade-out, after).
- Unit tests for `Exercise` decode covering: callout present, bool-only
  (fallback), neither.
- A UI test verifying the overlay appears/disappears for one seeded example
  exercise (follows the existing `AnimationDemoUITest` pattern).

## Scope of first implementation pass

Build the full infrastructure above, then author callouts for a small
representative sample (not all 137) covering all four shapes, to prove the
system end-to-end. Remaining exercises are follow-up batch work.
