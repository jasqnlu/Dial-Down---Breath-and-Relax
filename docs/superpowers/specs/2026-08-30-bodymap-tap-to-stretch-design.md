# Body Map — "Tap to Stretch" interaction rework

Replaces the five-step marking funnel on the Body Map with two direct
gesture paths to a stretch list. The 3D focus machinery underneath —
camera dolly, muscle-layer reveal, candidate rail — is untouched; only
what *triggers* it changes.

Visual walkthrough of this design:
<https://claude.ai/code/artifact/c85b4084-4455-49f9-b654-f9ba2123cd47>

---

## 1. Why

Today, every route from "my shoulder hurts" to a stretch runs through
five deliberate actions:

1. Tap **Mark** in the toolbar (enters a mode you can be in wrongly)
2. Tap the body (places a pending dot)
3. Pick a sensation colour — Pain / Tension / Stress / Tightness
4. Tap **✓** in the toolbar (opens the muscle picker)
5. Tap a muscle, twice (focus, then select)

Step 3 is the giveaway. `BodyMarkStore` persists the chosen
`sensationID`, and **nothing downstream ever reads it**. It selects no
exercise, filters no list, feeds no chart. It is ceremony.

Steps 1 and 4 exist only to bracket step 2. Remove the colour and the
mode, and the checkmark has nothing left to confirm.

## 2. What replaces it

Two paths with genuinely different jobs, neither hidden:

**Fast path — 2 taps.** Single-tap the body: it rotates to face the
tapped point, the region highlights, and a bar rises naming it.
Tap the bar → `BodyPartExercisesView(bodyPart:)` for that region.

**Precise path — 3 taps.** Double-tap the body: the existing
muscle-selection overlay opens (camera dollies to the dot, skin fades to
a scrim, ≤4 candidate muscles colourise with a labelled rail).
Pick one → its stretch list.

The bar names a region and delivers that region. It never asks you to
choose again — that is the overlay's job, and the overlay is opt-in.

### 2.1 Full gesture map

| Gesture | Action | Status |
|---|---|---|
| Drag | Rotate the body about Y | unchanged |
| Pinch | Zoom the camera (the only zoom) | unchanged |
| Single tap on body | Rotate to face + highlight region + raise bar | new |
| Tap the bar | That region's stretch list | new |
| Double tap on body | Muscle-selection overlay | new trigger, existing screen |
| Tap off the body | Clear the selection | new |

Explicitly **not** built: triple-tap-to-zoom and double-tap-off-body-to-
zoom-out. See §6.

## 3. Architecture

### 3.1 Gesture layer — `SceneKitContainer`

`SceneKitContainer` (`BodySceneView.swift:535`) hosts the raw `SCNView`
because SwiftUI's `SceneView` hides the view `hitTest` needs. It grows
from one `UITapGestureRecognizer` to two:

```
singleTap.numberOfTapsRequired = 1
doubleTap.numberOfTapsRequired = 2
singleTap.require(toFail: doubleTap)
```

Both share the existing raycast in `handleTap` (`BodySceneView.swift:872`)
— hit-test, skip marker nodes, convert the world hit to rigNode-local,
resolve with `MuscleHitResolver.regionName(at:in:)`. Only the callback
differs.

Drag and pinch stay in SwiftUI exactly as they are
(`BodySceneView.swift:889` and `:901`). The existing behaviour noted at
`BodySceneView.swift:533` — the tap recogniser failing automatically once
a pan starts — continues to hold for both recognisers.

`disambiguationCandidates` being non-empty still freezes both gestures and
routes taps to `handleCandidateHitTest`. Unchanged.

### 3.2 `BodySceneView` interface

`onRegionTap` is replaced by three callbacks:

| Callback | Fired by |
|---|---|
| `onRegionSelected(String, SIMD3<Float>)` | single tap that resolves a region |
| `onRegionDrilled(String, SIMD3<Float>)` | double tap that resolves a region |
| `onBackgroundTap()` | a tap whose raycast resolves nothing |

`marks: [String: BodyMark]` collapses to `selectionPoint: SIMD3<Float>?`
plus `selectedRegion: String?`. The dot-rendering path (`rig.updateMarks`)
survives, reduced to a single neutral accent-coloured dot — no sensation,
no colour choice. The selected region's hit volume takes a soft accent
tint, reusing the box-drawing already built for candidates.

### 3.3 Rotate-to-face — `BodyRig`

The rig only ever rotates about Y (`applyDragRotation(deltaX:)` consumes a
horizontal translation and nothing else), so "turn to face the tap"
reduces to a single azimuth.

```swift
static func rotationToFace(localPoint: SIMD3<Float>,
                           currentY: CGFloat) -> CGFloat?
```

- Bearing of the tapped point is `atan2(x, z)` in rigNode-local space.
- The returned value is the **absolute** target rotation, `-atan2(x, z)`.
  Because `localPoint` is rigNode-local, the rig's current rotation is
  already factored out, so the target does not depend on `currentY`.
- Returns `nil` when the shortest delta from `currentY` is under 8°, so
  tapping the chest while already front-on is a no-op rather than a
  jitter. Also `nil` for a point on the Y axis, which has no bearing.

**The existing `snap(to:)` does the rest.** `BodyRig.snap(to:)`
(`BodySceneView.swift:510`) already normalises to the shortest arc *and*
writes the destination back into `committedRotationY` in its
`SCNTransaction` completion block — which is the bookkeeping drag deltas
compose against (`BodySceneView.swift:158`). So rotate-to-face is
`rig.snap(to: target)` and needs no new animation or commit code, and
inherits `snap`'s 0.35 s ease-in-out.

The shortest-arc wrapping currently lives inline inside `snap`. It is
extracted as `BodyRig.shortestDelta(from:to:)` so both `snap` and the
threshold check in `rotationToFace` use one implementation, and so it can
be unit-tested directly.

### 3.4 `BodyMapView`

State drops from ten `@State` properties to five. Removed: `isMarking`,
`markStore`, `selectedSensation`, `showLegend`, `pendingMark`.

`confirmPendingMark()` (`BodyMapView.swift:237`) survives near-verbatim as
`presentMuscleSelection(at:)` — same `HeadZones` branch for face taps,
same `maxCandidates: 6` → drop parent groups whose heads are present →
`prefix(4)` fan-out. It is called from a double tap instead of a toolbar
button.

`ExercisesRoute` collapses to a single case. `.marked([String])` dies with
`MarkedAreasBanner`, its only caller.

### 3.5 Screen chrome

| Slot | Before | After |
|---|---|---|
| Toolbar `.primaryAction` | Mark / ✓ Confirm | *nothing* — no mode to enter |
| Top bar | Instructional text, ⓘ colour guide, Cancel | Front/Back toggle; Cancel only while the overlay is up |
| Bottom bar | Sensation palette **or** `MarkedAreasBanner` | `RegionActionBar` — "Stretches for Right Shoulder →" |
| Sheet | `LegendSheet` colour guide | *gone* |

The Front/Back toggle stays: it is still the quickest way to spin a full
180°, which tap-to-face cannot do (there is nothing to tap on the far
side).

## 4. Files

| File | State | What happens |
|---|---|---|
| `Views/BodyMap/BodyMapView.swift` | rewritten | mode machine out, two tap handlers in |
| `Views/BodyMap/BodySceneView.swift` | edited | 2nd tap recogniser, split callbacks, `rotationToFace` |
| `Views/BodyMap/BodyMapComponents.swift` | edited | `MarkedAreasBanner` out, `RegionActionBar` in |
| `Views/BodyMap/Sensations.swift` | deleted | 79 lines — holds `SensationColor`, `sensationColors` **and** `LegendSheet`, so all three go with it |
| `Models/BodyMarkStore.swift` | deleted | 61 lines, no other reader |
| `Tests/BodyMarkStoreTests.swift` | deleted | goes with the store |
| `Views/Onboarding/TourCoordinator.swift` | edited | two steps rewritten (§5) |
| `Tests/TourCoordinatorTests.swift` | edited | ID assertions, lines 73–117 |
| `UITests/BodyMapMarking3DUITests.swift` | rewritten | tap → bar → list |
| `UITests/BodyMapConfirmZoomUITests.swift` | rewritten | entered by double tap |
| `Tests/BodyRigRotationTests.swift` | new | `rotationToFace` units |
| `Services/SeedMigrator.swift` | edited | new `removeRetiredBodyMapMarkStorage(defaults:)` drops the orphaned `bodymap.markedSensations` key. It is a plain idempotent defaults call, not a versioned seed migration. **Leave line 144 alone** — that block reads the older, unrelated `bodymap.markedRegions` key |

### 4.1 Untouched, and load-bearing

None of this changes, and it is the majority of the hard code in the
feature:

- `rig.focus(on:)` — off-axis dolly along the tapped point's outward normal
- `rig.reveal(_:focused:)` — skin-to-scrim fade, muscle layer, colourisation
- `CandidateRailOverlay` — edge-hugging labels, leader lines, matched dots
- `MuscleHitResolver`, `BodyHitVolumes`, `MuscleNodeNames`, `HeadZones`
- `projectPinPositions` and the `refocusToken` re-drive after a pop
- `BodyPartExercisesView`, `RegionExerciseResolver`
- Drag rotation, pinch zoom, the `minCameraZ`/`maxCameraZ` clamp

## 5. Onboarding tour

Two steps teach Mark and ✓ and cannot survive. They are rewritten in
place rather than dropped, keeping the body map in the tour:

| Old ID | New ID | New copy |
|---|---|---|
| `bodymap.tapMarkAndRegion` | `bodymap.tapRegion` | "Tap where you feel tense. The body turns to face it." |
| `bodymap.confirmMark` | `bodymap.findStretches` | "Tap here for stretches." (anchored to the action bar) |

`bodymap.regionResults` is unchanged. `bodymap.findStretches` drops the
`fixedFrame: toolbarPrimaryActionFrame` its predecessor needed, since it
anchors to a real in-content view. `TourCoordinatorTests` follows the
renames.

## 6. Rejected: the three-deep tap chain

The original proposal had triple-tap to zoom in and double-tap-off-body to
zoom out. Both are cut, for two reasons.

**Latency lands in the wrong place.** UIKit resolves ambiguous tap counts
with `require(toFail:)`, and each rung costs roughly one double-tap
interval (~300 ms):

| Chain | triple | double | single |
|---|---|---|---|
| Rejected (3 deep) | 0 ms | ~300 ms | ~600 ms |
| Chosen (2 deep) | — | 0 ms | ~300 ms |

In the rejected version the rarest gesture is instant and the commonest
waits longest.

**"Outside the body" is not a reliable target.** The scene is full-bleed,
so "outside" can only mean *the raycast missed the mesh*. Zooming in makes
the body fill the screen — precisely when the zoom-out gesture has no
target left. It also collides with double-tap-on-body at the silhouette
edge, where one pixel decides between "show me exercises" and "throw away
my zoom."

Pinch already zooms both directions from any state, so nothing is lost.

## 7. Accepted cost

The single tap resolves ~300 ms after the finger lifts, because it waits
on the double tap. The highlight and bar cannot appear sooner without also
firing on every double tap. The 0.28 s rotate animation starting at that
same instant is what makes it read as lead-in rather than lag.

## 8. Verification

**Swift Testing — `BodyRigRotationTests`** (the real bug risk, and it
needs no scene):

- A point at +150° rotates −150°, not +210°
- Points at ±170° both take the arc under 180°
- A point within 8° of centre returns `nil`
- `shortestDelta` hops 20° across the ±π seam rather than unwinding 340°
- The target is independent of `currentY`, since the point is rig-local

**XCUITest — both paths end to end:**

- Tap the body → bar appears naming a region → tap it → that region's list
- Double tap the body → rail labels appear → tap one → its list
- Tap off the body → the bar goes away

Driven through the project's `verify` skill so simulator screenshots land
as test attachments.
