# Body Map "Tap to Stretch" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Body Map's five-step marking funnel (Mark → tap → colour → ✓ → pick) with two direct gesture paths: single-tap to face a region and jump to its stretches, double-tap to open the existing muscle picker.

**Architecture:** The SceneKit focus machinery (`rig.focus`, `rig.reveal`, `CandidateRailOverlay`) is untouched — only its *trigger* changes, from a toolbar checkmark to a double tap. `SceneKitContainer` grows a second `UITapGestureRecognizer` with `singleTap.require(toFail: doubleTap)`. Rotate-to-face is a new pure static on `BodyRig` feeding the *existing* `snap(to:)`, which already owns shortest-arc wrapping and the `committedRotationY` write-back. `BodyMapView` sheds its mode machine; `BodyMarkStore` and `Sensations.swift` are deleted outright.

**Tech Stack:** SwiftUI, SceneKit, SwiftData, Swift Testing (`import Testing`, not XCTest), XCUITest.

**Spec:** `docs/superpowers/specs/2026-08-30-bodymap-tap-to-stretch-design.md`
Visual walkthrough: <https://claude.ai/code/artifact/c85b4084-4455-49f9-b654-f9ba2123cd47>

## Global Constraints

- **Test framework is Swift Testing, not XCTest.** Unit tests use `import Testing`, `@Test`, `#expect`. App module is `BreathRelaxStretch`; tests do `@testable import BreathRelaxStretch`. UI tests remain XCTest (`XCTestCase`).
- **Test files must land in `Breath - Relax & StretchTests/`** — the repo root is itself named `Breath - Relax & Stretch`, so a stray sibling path silently fails to compile in and a `-only-testing` run then "succeeds" with zero cases. Verify the case count in the output.
- **A test touching a SceneKit property needs its own `import SceneKit`**, even with `@testable import BreathRelaxStretch`.
- The `.xcodeproj` uses `PBXFileSystemSynchronizedRootGroup` — dropping a `.swift` file into the test folder is enough, **no `project.pbxproj` edit**.
- **Unit test command** (~40s, builds the app first):
  ```
  xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"
  ```
- **The baseline on this branch is FULLY GREEN: 412 tests in 59 suites, 0 failures** (measured on `worktree-bodymap-tap-to-stretch` at 9dbc7f8, before any task ran). Older project notes claim 4 `CuratedContentIntegrityTests` cases fail from curated-content data drift — that is stale; they pass now. **Treat any failing test as a real regression caused by your change.** Supabase `NSURLErrorDomain -1003` / "Connection N: failed to connect" lines in the log are expected offline noise from `AuthManagerTests`, not failures.
- **Never `git checkout` `SeedData.json`** blind — unrelated staged work lives there.
- Colour comes from `LuminaTheme.swift` tokens (`Color.luminaPrimary` etc.), never literal hex.
- Do not touch `Services/SeedMigrator.swift:144` — that block migrates the older, unrelated `bodymap.markedRegions` key and is still live.

---

## File Structure

| File | Responsibility after this plan |
|---|---|
| `Views/BodyMap/BodySceneView.swift` | `BodyRig` (scene, rotation math, marker dot, focus/reveal), `SceneKitContainer` (two tap recognisers), `BodySceneView` (gestures, raycast, callbacks), `CandidateRailOverlay` |
| `Views/BodyMap/BodyMapView.swift` | Screen state and routing only: selection, muscle-picker state, navigation |
| `Views/BodyMap/BodyMapComponents.swift` | `RegionActionBar`, `RegionExerciseResolver`, `BodyPartExercisesView` |
| `Views/BodyMap/Sensations.swift` | **deleted** |
| `Models/BodyMarkStore.swift` | **deleted** |
| `Services/SeedMigrator.swift` | + `removeRetiredBodyMapMarkStorage(defaults:)` |
| `Views/Onboarding/TourCoordinator.swift` | Two body-map steps renamed and recopied |
| `Tests/BodyRigRotationTests.swift` | **new** — rotation math + selection dot + retired-storage cleanup |

`BodySceneView.swift` is already 1042 lines. This plan does not split it: the rig, its host and its view are one tightly-coupled unit that changes together, and splitting it is out of scope for an interaction rework. It comes out roughly net-neutral in size.

---

## Task 1: Rotation math on `BodyRig`

Pure, testable, additive — nothing else depends on it yet, and nothing breaks if it lands alone.

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift` (add to `BodyRig`, refactor `snap(to:)` at `:510`)
- Test: `Breath - Relax & StretchTests/BodyRigRotationTests.swift` (create)

**Interfaces:**
- Consumes: `BodyRig.committedRotationY` (existing `var`, `CGFloat`)
- Produces:
  - `static func BodyRig.shortestDelta(from: CGFloat, to: CGFloat) -> CGFloat`
  - `static func BodyRig.rotationToFace(localPoint: SIMD3<Float>, currentY: CGFloat, threshold: CGFloat = 8 * .pi / 180) -> CGFloat?` — returns the **absolute** target rig Y-rotation, or `nil` when the rig already faces the point (or the point has no bearing).

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/BodyRigRotationTests.swift`:

```swift
import Testing
import Foundation
import simd
@testable import BreathRelaxStretch

/// The rig rotates about Y only, so "turn to face the tap" is one azimuth.
/// `rotationToFace` returns an ABSOLUTE target; the shortest-arc walk to it
/// belongs to the existing `snap(to:)`, which is why the wrapping helper is
/// tested separately here.
struct BodyRigRotationTests {

    private let deg = CGFloat.pi / 180

    // MARK: - shortestDelta

    @Test func shortestDeltaHopsAcrossTheSeamInsteadOfUnwinding() {
        // 170° → −170° is a 20° hop over the ±π seam, not a 340° unwind.
        let delta = BodyRig.shortestDelta(from: 170 * deg, to: -170 * deg)
        #expect(abs(delta - 20 * deg) < 1e-9)
    }

    @Test func shortestDeltaIsSignedTowardTheNearerSide() {
        #expect(BodyRig.shortestDelta(from: 0, to: 150 * deg) > 0)
        #expect(BodyRig.shortestDelta(from: 0, to: -150 * deg) < 0)
    }

    @Test func shortestDeltaNeverExceedsHalfATurn() {
        // 190° away is really 170° the other way.
        let delta = BodyRig.shortestDelta(from: 0, to: 190 * deg)
        #expect(abs(delta - (-170 * deg)) < 1e-9)
        #expect(abs(delta) <= CGFloat.pi + 1e-9)
    }

    // MARK: - rotationToFace

    @Test func aPointOnTheRigsPlusXSwingsRoundToTheCamera() {
        // Camera sits on world +Z. A point at local (1, 0, 0) has bearing
        // +90°, so the rig must land on −90° to bring it to +Z.
        let target = try! #require(BodyRig.rotationToFace(localPoint: [1, 0, 0], currentY: 0))
        #expect(abs(target - (-90 * deg)) < 1e-6)
    }

    @Test func aPointAlreadyFacingTheCameraNeedsNoRotation() {
        // Local (0, 0.4, 1) is dead-on the camera axis with the rig at 0.
        #expect(BodyRig.rotationToFace(localPoint: [0, 0.4, 1], currentY: 0) == nil)
    }

    @Test func aTapJustInsideTheDeadZoneIsANoOp() {
        let threeDeg = Float(3 * Double.pi / 180)
        let point = SIMD3<Float>(sin(threeDeg), 0.4, cos(threeDeg))
        #expect(BodyRig.rotationToFace(localPoint: point, currentY: 0) == nil)
    }

    @Test func aTapJustOutsideTheDeadZoneStillRotates() {
        let twelveDeg = Float(12 * Double.pi / 180)
        let point = SIMD3<Float>(sin(twelveDeg), 0.4, cos(twelveDeg))
        #expect(BodyRig.rotationToFace(localPoint: point, currentY: 0) != nil)
    }

    @Test func theTargetIsIndependentOfCurrentRotation() {
        // localPoint is rigNode-LOCAL, so the rig's rotation is already
        // factored out — the absolute target must not move with currentY.
        let point = SIMD3<Float>(0.5, 0.2, -0.5)
        let fromFront = try! #require(BodyRig.rotationToFace(localPoint: point, currentY: 0))
        let fromBack  = try! #require(BodyRig.rotationToFace(localPoint: point, currentY: .pi))
        #expect(abs(fromFront - fromBack) < 1e-9)
    }

    @Test func heightDoesNotAffectBearing() {
        let low  = try! #require(BodyRig.rotationToFace(localPoint: [0.4, -0.9, 0.3], currentY: 0))
        let high = try! #require(BodyRig.rotationToFace(localPoint: [0.4,  0.9, 0.3], currentY: 0))
        #expect(abs(low - high) < 1e-9)
    }

    @Test func aPointOnTheYAxisHasNoBearing() {
        #expect(BodyRig.rotationToFace(localPoint: [0, 1, 0], currentY: 0) == nil)
    }
}
```

- [ ] **Step 2: Run the tests and verify they fail**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BodyRigRotationTests"
```

Expected: **compile failure** — `type 'BodyRig' has no member 'shortestDelta'` / `'rotationToFace'`.

- [ ] **Step 3: Add the two statics to `BodyRig`**

In `BodySceneView.swift`, inside `final class BodyRig`, directly above the existing `// MARK: - Rotation` section's `applyDragRotation`:

```swift
    // MARK: - Rotation math

    /// Signed shortest angular distance from `from` to `to`, wrapped to ±π —
    /// so a turn never takes the long way round the seam.
    static func shortestDelta(from: CGFloat, to: CGFloat) -> CGFloat {
        let twoPi = 2 * CGFloat.pi
        var delta = (to - from.truncatingRemainder(dividingBy: twoPi))
            .truncatingRemainder(dividingBy: twoPi)
        if delta >  .pi { delta -= twoPi }
        if delta < -.pi { delta += twoPi }
        return delta
    }

    /// The absolute rig Y-rotation that brings `localPoint` round to face the
    /// camera (which sits on world +Z).
    ///
    /// `localPoint` is rigNode-LOCAL, so the rig's current rotation is already
    /// factored out and the target is simply the negated bearing —
    /// independent of `currentY`. `currentY` is used only to decide whether
    /// the move is worth making.
    ///
    /// Returns `nil` when the point has no bearing (it sits on the Y axis) or
    /// when the rig already faces it to within `threshold`, so a tap near
    /// dead-centre is a no-op rather than a jitter.
    static func rotationToFace(localPoint: SIMD3<Float>,
                               currentY: CGFloat,
                               threshold: CGFloat = 8 * .pi / 180) -> CGFloat? {
        let planar = SIMD2<Float>(localPoint.x, localPoint.z)
        guard simd_length(planar) > 1e-4 else { return nil }
        let target = -CGFloat(atan2(localPoint.x, localPoint.z))
        guard abs(shortestDelta(from: currentY, to: target)) >= threshold else { return nil }
        return target
    }
```

- [ ] **Step 4: Refactor `snap(to:)` onto the shared helper**

`snap(to:)` at `BodySceneView.swift:510` currently inlines the same wrapping. Replace its first five lines so there is one implementation. Find:

```swift
        let twoPi = 2 * CGFloat.pi
        let current = committedRotationY
        let normalizedCurrent = current.truncatingRemainder(dividingBy: twoPi)
        var delta = (target - normalizedCurrent).truncatingRemainder(dividingBy: twoPi)
        if delta > .pi  { delta -= twoPi }
        if delta < -.pi { delta += twoPi }
        let destination = current + delta
```

Replace with:

```swift
        let current = committedRotationY
        let destination = current + BodyRig.shortestDelta(from: current, to: target)
```

Leave the rest of `snap` — the `SCNTransaction` block and the `committedRotationY` write-back in its completion — exactly as it is. That write-back is what makes rotate-to-face compose with the next drag, and it already works.

- [ ] **Step 5: Run the tests and verify they pass**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BodyRigRotationTests"
```

Expected: **10 tests, all passing.** If the count is 0, the file landed outside `Breath - Relax & StretchTests/` — move it.

- [ ] **Step 6: Run the full unit suite to confirm `snap` didn't regress**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"
```

Expected: **all 412+ tests passing, 0 failures.** The baseline is green, so any failure is yours.

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift" "Breath - Relax & StretchTests/BodyRigRotationTests.swift"
git commit -m "feat(bodymap): add BodyRig.rotationToFace and share shortest-arc math with snap"
```

---

## Task 2: Neutral selection dot on `BodyRig`

Adds `updateSelection(point:)` alongside the existing `updateMarks`. Additive — `updateMarks` stays until Task 4 deletes its dependencies, so this commit builds on its own.

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift` (`BodyRig`, near `updateMarks` at `:312`)
- Test: `Breath - Relax & StretchTests/BodyRigRotationTests.swift` (append)

**Interfaces:**
- Consumes: `BodyRig.marksNode` (existing `let`, `SCNNode`)
- Produces: `func BodyRig.updateSelection(point: SIMD3<Float>?)` — renders exactly one dot named `"selection-dot"`, or clears when `nil`.

- [ ] **Step 1: Write the failing tests**

Append to `BodyRigRotationTests.swift`. Note the extra `import SceneKit` — reading `.childNodes` needs it even with `@testable`. Add it to the file's imports at the top:

```swift
import SceneKit
```

Then append this suite to the end of the file:

```swift
/// The "you tapped here" dot. One at a time, no sensation colour — the
/// palette that used to drive it is deleted in this rework.
struct BodyRigSelectionDotTests {

    @Test @MainActor func aSelectionAddsExactlyOneNamedDot() {
        let rig = BodyRig()
        rig.updateSelection(point: [0.1, 0.3, 0.05])
        #expect(rig.marksNode.childNodes.count == 1)
        #expect(rig.marksNode.childNodes.first?.name == "selection-dot")
    }

    @Test @MainActor func aNewSelectionReplacesRatherThanAccumulates() {
        let rig = BodyRig()
        rig.updateSelection(point: [0.1, 0.3, 0.05])
        rig.updateSelection(point: [-0.2, 0.1, 0.4])
        #expect(rig.marksNode.childNodes.count == 1)
    }

    @Test @MainActor func theDotSitsAtTheTappedPoint() {
        let rig = BodyRig()
        rig.updateSelection(point: [-0.2, 0.1, 0.4])
        let dot = try! #require(rig.marksNode.childNodes.first)
        #expect(abs(dot.position.x - (-0.2)) < 1e-6)
        #expect(abs(dot.position.y - 0.1) < 1e-6)
        #expect(abs(dot.position.z - 0.4) < 1e-6)
    }

    @Test @MainActor func passingNilClearsTheDot() {
        let rig = BodyRig()
        rig.updateSelection(point: [0.1, 0.3, 0.05])
        rig.updateSelection(point: nil)
        #expect(rig.marksNode.childNodes.isEmpty)
    }
}
```

- [ ] **Step 2: Run the tests and verify they fail**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BodyRigSelectionDotTests"
```

Expected: **compile failure** — `value of type 'BodyRig' has no member 'updateSelection'`.

- [ ] **Step 3: Add `updateSelection` to `BodyRig`**

In `BodySceneView.swift`, immediately after the existing `updateMarks(_:)` (`:312`–`:326`):

```swift
    /// Renders the single "you tapped here" dot, or clears it when `nil`.
    /// Replaces `updateMarks` — one neutral accent dot, no sensation colour,
    /// and never more than one at a time.
    func updateSelection(point: SIMD3<Float>?) {
        marksNode.childNodes.forEach { $0.removeFromParentNode() }
        guard let point else { return }
        let sphere = SCNSphere(radius: 0.028)
        let color = UIColor(Color.luminaPrimary)
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.name = "selection-dot"
        node.position = SCNVector3(point.x, point.y, point.z)
        marksNode.addChildNode(node)
    }
```

- [ ] **Step 4: Run the tests and verify they pass**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/BodyRigSelectionDotTests"
```

Expected: **4 tests, all passing.**

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift" "Breath - Relax & StretchTests/BodyRigRotationTests.swift"
git commit -m "feat(bodymap): add single neutral selection dot to BodyRig"
```

---

## Task 3: The interaction swap

The behavioural change, in one commit: the second tap recogniser, the split callbacks, the new action bar, and the `BodyMapView` rewrite. These are not separable — a half-swapped gesture layer is not something a reviewer could sensibly accept on its own.

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift` (`SceneKitContainer` `:535`, `BodySceneView` properties/gestures/tap handling)
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift` (add `RegionActionBar`)
- Rewrite: `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift`

**Interfaces:**
- Consumes: `BodyRig.rotationToFace(localPoint:currentY:threshold:)`, `BodyRig.updateSelection(point:)`, `BodyRig.snap(to:)`, `BodyRig.committedRotationY` (Tasks 1–2 and existing)
- Produces:
  - `RegionActionBar(regionName: String, onFind: () -> Void)` with accessibility identifier `"bodymap.regionActionBar"`
  - `BodySceneView(facing:style:selectionPoint:onRegionSelected:onRegionDrilled:onBackgroundTap:disambiguationCandidates:focusPoint:focusedRegion:onCandidateFocused:onCandidateSelected:refocusToken:)`

**Scope note — no at-rest region tint.** The spec's §3.2 said the selected
region's hit volume would take "a soft accent tint, reusing the box-drawing
already built for candidates." That reuse does not exist: `showCandidates`
and the candidate boxes colourise nodes on the **muscle layer**, which is
`isHidden = true` / `opacity = 0` at rest (set in `BodyRig.init`) and only
revealed by `rig.reveal` during the muscle picker. Tinting a region at rest
would be new work, not reuse, so it is cut from scope — and with it the
`selectedRegion` property, which would otherwise be declared and never read.
The neutral selection dot plus the action bar naming the region are the
selection affordance. Do not add a region highlight in this task.

- [ ] **Step 1: Add `RegionActionBar`**

In `BodyMapComponents.swift`, replace the whole `MarkedAreasBanner` struct (lines 4–56, from the `// MARK: - Marked-areas banner` comment through its closing brace) with:

```swift
// MARK: - Region action bar
//
// Rises when a single tap selects a region. One tap from here to that
// region's stretches — the visible counterpart to the double-tap shortcut
// into the muscle picker, so the exercise path is never hidden behind a
// gesture a user has to guess.

struct RegionActionBar: View {
    let regionName: String
    let onFind: () -> Void

    var body: some View {
        Button(action: onFind) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stretches for")
                        .font(.luminaCaption)
                        .foregroundStyle(.secondary)
                    Text(regionName)
                        .font(.luminaTitle)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.luminaPrimary)
            }
            .luminaCard(padding: 16)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bodymap.regionActionBar")
        .accessibilityLabel("Find stretches for \(regionName)")
    }
}
```

- [ ] **Step 2: Give `SceneKitContainer` two recognisers**

In `BodySceneView.swift`, replace the whole `private struct SceneKitContainer` (`:535` through its closing brace, including its `Coordinator`) with:

```swift
private struct SceneKitContainer: UIViewRepresentable {
    let scene: SCNScene
    let pointOfView: SCNNode
    var onSingleTap: ((CGPoint, SCNView) -> Void)?
    var onDoubleTap: ((CGPoint, SCNView) -> Void)?
    /// Disabled while the muscle picker is up, so candidate taps there don't
    /// pay the double-tap fail interval for a gesture that does nothing.
    var doubleTapEnabled: Bool = true
    /// Fired once after the SCNView is created — lets BodySceneView hold a
    /// reference for `projectPoint` (candidate-pin placement), since
    /// SwiftUI's SceneView hides the underlying SCNView entirely.
    var onViewReady: ((SCNView) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.pointOfView = pointOfView
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .clear

        let double = UITapGestureRecognizer(target: context.coordinator,
                                            action: #selector(Coordinator.handleDoubleTap(_:)))
        double.numberOfTapsRequired = 2
        view.addGestureRecognizer(double)
        context.coordinator.doubleTapRecognizer = double

        let single = UITapGestureRecognizer(target: context.coordinator,
                                            action: #selector(Coordinator.handleSingleTap(_:)))
        single.numberOfTapsRequired = 1
        // Without this the single tap also fires on the FIRST tap of every
        // double tap — rotating the body out from under the muscle picker
        // just as it opens. The cost is that a single tap resolves one
        // double-tap interval (~300 ms) after the finger lifts; the 0.35 s
        // rotate that starts then is what makes it read as lead-in.
        single.require(toFail: double)
        view.addGestureRecognizer(single)

        DispatchQueue.main.async { onViewReady?(view) }
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.onSingleTap = onSingleTap
        context.coordinator.onDoubleTap = onDoubleTap
        context.coordinator.doubleTapRecognizer?.isEnabled = doubleTapEnabled
        // A covered SCNView pauses its display link; re-assert continuous
        // rendering so it resumes drawing when revealed (e.g. after popping the
        // exercise list) instead of showing a stale/blank frame.
        view.rendersContinuously = true
        view.isPlaying = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSingleTap: onSingleTap, onDoubleTap: onDoubleTap)
    }

    final class Coordinator: NSObject {
        var onSingleTap: ((CGPoint, SCNView) -> Void)?
        var onDoubleTap: ((CGPoint, SCNView) -> Void)?
        weak var doubleTapRecognizer: UITapGestureRecognizer?

        init(onSingleTap: ((CGPoint, SCNView) -> Void)?,
             onDoubleTap: ((CGPoint, SCNView) -> Void)?) {
            self.onSingleTap = onSingleTap
            self.onDoubleTap = onDoubleTap
        }

        @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? SCNView else { return }
            onSingleTap?(recognizer.location(in: view), view)
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? SCNView else { return }
            onDoubleTap?(recognizer.location(in: view), view)
        }
    }
}
```

- [ ] **Step 3: Swap `BodySceneView`'s inputs**

In `BodySceneView`, replace the `marks` property and the `onRegionTap` property with the new selection inputs and three callbacks. Find:

```swift
    /// Current marks, rendered as marker-dot spheres on the body.
    var marks: [String: BodyMark] = [:]
```

...through the end of the `onRegionTap` doc comment and declaration, and replace with:

```swift
    /// The point the user last single-tapped, rendered as one neutral dot.
    var selectionPoint: SIMD3<Float>? = nil

    /// Single tap that resolved a region: the body has already been rotated
    /// to face it by the time this fires. Rotation stays free — hit-testing
    /// works at any camera angle.
    var onRegionSelected: ((String, SIMD3<Float>) -> Void)? = nil
    /// Double tap that resolved a region — the muscle-picker trigger.
    var onRegionDrilled: ((String, SIMD3<Float>) -> Void)? = nil
    /// A tap whose raycast resolved nothing (off the mesh, or on a spot no
    /// hit volume covers). Clears the selection.
    var onBackgroundTap: (() -> Void)? = nil
```

Then replace `BodySceneView`'s memberwise `init` in full. It currently reads
`marks:` / `onRegionTap:`; the new one reads:

```swift
    init(facing: BodyFacing,
         style: BodyModelStyle = .anatomy,
         selectionPoint: SIMD3<Float>? = nil,
         onRegionSelected: ((String, SIMD3<Float>) -> Void)? = nil,
         onRegionDrilled: ((String, SIMD3<Float>) -> Void)? = nil,
         onBackgroundTap: (() -> Void)? = nil,
         disambiguationCandidates: [MarkCandidate] = [],
         focusPoint: SIMD3<Float>? = nil,
         focusedRegion: String? = nil,
         onCandidateFocused: ((String) -> Void)? = nil,
         onCandidateSelected: ((String) -> Void)? = nil,
         refocusToken: Int = 0) {
        self.facing = facing
        self.style = style
        self.selectionPoint = selectionPoint
        self.onRegionSelected = onRegionSelected
        self.onRegionDrilled = onRegionDrilled
        self.onBackgroundTap = onBackgroundTap
        self.disambiguationCandidates = disambiguationCandidates
        self.focusPoint = focusPoint
        self.focusedRegion = focusedRegion
        self.onCandidateFocused = onCandidateFocused
        self.onCandidateSelected = onCandidateSelected
        self.refocusToken = refocusToken
        _rig = State(initialValue: BodyRig(style: style))
        _cameraZ = State(initialValue: BodyRig.freeExploreCameraDistance)
        _committedCameraZ = State(initialValue: BodyRig.freeExploreCameraDistance)
    }
```

The three `_rig` / `_cameraZ` / `_committedCameraZ` lines at the end are
unchanged from the existing init — keep them exactly as they are.

- [ ] **Step 4: Rewrite the tap routing and gestures in `BodySceneView`**

Replace the `tapHandler` computed property and `handleTap(at:in:)` with:

```swift
    /// While focused (the muscle picker), taps hit-test the revealed muscle
    /// mesh so tapping a highlighted muscle selects it directly, and the
    /// double-tap recogniser is switched off entirely. Otherwise a single tap
    /// selects and a double tap drills.
    private var singleTapHandler: ((CGPoint, SCNView) -> Void)? {
        if isFocused {
            return { point, view in handleCandidateHitTest(at: point, in: view) }
        }
        guard onRegionSelected != nil || onBackgroundTap != nil else { return nil }
        return { point, view in handleSingleTap(at: point, in: view) }
    }

    private var doubleTapHandler: ((CGPoint, SCNView) -> Void)? {
        guard !isFocused, onRegionDrilled != nil else { return nil }
        return { point, view in handleDoubleTap(at: point, in: view) }
    }

    /// Single tap: turn the body to face the tapped point, then report the
    /// region. `rotationToFace` returns nil when the rig already faces it,
    /// which is the common case for a tap on the side already showing.
    private func handleSingleTap(at point: CGPoint, in view: SCNView) {
        guard let (region, local) = resolveRegion(at: point, in: view) else {
            onBackgroundTap?()
            return
        }
        if let target = BodyRig.rotationToFace(localPoint: local,
                                               currentY: rig.committedRotationY) {
            rig.snap(to: target)
        }
        onRegionSelected?(region, local)
    }

    /// Double tap: straight into the muscle picker. A miss is ignored rather
    /// than clearing, so a fumbled double tap doesn't also wipe the selection.
    private func handleDoubleTap(at point: CGPoint, in view: SCNView) {
        guard let (region, local) = resolveRegion(at: point, in: view) else { return }
        onRegionDrilled?(region, local)
    }

    /// Stage 1: raycast the visible skin surface — the only unhidden geometry
    /// at rest (the selection dot is excluded explicitly, so the first
    /// non-marker hit is the skin surface point). Stage 2: convert the world
    /// hit point to rigNode-local (normalized model space, rotation factored
    /// out) and resolve it with pure math.
    private func resolveRegion(at point: CGPoint, in view: SCNView) -> (String, SIMD3<Float>)? {
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue as NSNumber])
        guard let hit = hits.first(where: { !isMarkerNode($0.node) }) else { return nil }
        let local = rig.rigNode.convertPosition(hit.worldCoordinates, from: nil)
        let normalized = SIMD3(Float(local.x), Float(local.y), Float(local.z))
        guard let region = MuscleHitResolver.regionName(at: normalized, in: BodyHitVolumes.all) else {
            return nil
        }
        return (region, normalized)
    }
```

Update the `SceneKitContainer` call site in `body` from `onTap: tapHandler` to:

```swift
                SceneKitContainer(scene: rig.scene, pointOfView: rig.cameraNode,
                                  onSingleTap: singleTapHandler,
                                  onDoubleTap: doubleTapHandler,
                                  doubleTapEnabled: !isFocused,
                                  onViewReady: { scnView = $0 })
```

Update the drag hint overlay text from `"Drag to rotate"` to `"Tap a sore spot · drag to rotate"`.

- [ ] **Step 5: Point the dot at the new selection**

Replace the two `marks` wiring points. In `.task(id:)`, change `rig.updateMarks(marks)` to `rig.updateSelection(point: selectionPoint)`. Replace the `.onChange(of: marks)` modifier with:

```swift
        .onChange(of: selectionPoint) { _, newPoint in
            rig.updateSelection(point: newPoint)
        }
```

- [ ] **Step 6: Rewrite `BodyMapView`**

Replace the entire contents of `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift` with:

```swift
import SwiftUI
import SwiftData

// MARK: - BodyMapView
//
// One freely-rotatable 3D body, two ways in. A single tap turns the body to
// face the tapped point, marks it, and raises a bar straight to that
// region's stretches. A double tap opens the muscle picker — camera to the
// dot, skin fades, ≤4 candidate muscles. No modes, no sensation colours, no
// checkmark; see
// docs/superpowers/specs/2026-08-30-bodymap-tap-to-stretch-design.md
//
// Hit-testing raycasts the skin mesh and resolves the point in pure Swift
// (MuscleHitResolver), so rotation stays free at all times.

struct BodyMapView: View {
    @EnvironmentObject private var tourCoordinator: TourCoordinator
    @State private var facing: BodyFacing = .front

    /// The current single-tap selection. Drives the dot, the region
    /// highlight and the action bar. Nil means nothing is selected.
    @State private var selection: RegionSelection?

    // MARK: - Muscle-picker state
    @State private var disambiguationCandidates: [MarkCandidate] = []
    /// The tapped dot the camera zooms onto — kept alive across navigation so
    /// Back returns to the same zoomed framing.
    @State private var focusPoint: SIMD3<Float>?
    /// The currently highlighted candidate (its region box brightened).
    @State private var focusedRegion: String?
    /// One `item`-driven destination for every push, rather than several
    /// `isPresented:` modifiers racing over the same stack.
    @State private var exercisesRoute: ExercisesRoute?
    /// Bumped when the exercise list is popped, to nudge BodySceneView to
    /// re-apply the zoom and re-project labels (the covered SCNView goes stale).
    @State private var refocusToken = 0

    private struct RegionSelection: Equatable {
        let region: String
        let point: SIMD3<Float>
    }

    private struct ExercisesRoute: Identifiable, Hashable {
        let region: String
        var id: String { region }
    }

    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────────────────
                HStack(spacing: 8) {
                    if isDisambiguating {
                        Text("Which area did you mean?")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button("Cancel", role: .cancel) { cancelDisambiguation() }
                            .font(.caption.weight(.medium))
                    } else {
                        Spacer(minLength: 0)
                        facingToggleButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // ── The body ─────────────────────────────────────────────────
                BodySceneView(facing: facing,
                              style: .anatomy,
                              selectionPoint: selection?.point,
                              onRegionSelected: handleRegionSelected,
                              onRegionDrilled: handleRegionDrilled,
                              onBackgroundTap: clearSelection,
                              disambiguationCandidates: disambiguationCandidates,
                              focusPoint: focusPoint,
                              focusedRegion: focusedRegion,
                              onCandidateFocused: handleCandidateFocused,
                              onCandidateSelected: handleCandidateSelected,
                              refocusToken: refocusToken)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tourAnchor("bodymap.tapRegion")

                // ── Bottom bar ───────────────────────────────────────────────
                if let selection, !isDisambiguating {
                    RegionActionBar(regionName: selection.region) {
                        exercisesRoute = ExercisesRoute(region: selection.region)
                        tourCoordinator.notifyInteraction(id: "bodymap.findStretches")
                    }
                    .tourAnchor("bodymap.findStretches")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .floatingTabBarClearance()
            .navigationTitle("Body Map")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.2), value: selection)
            .navigationDestination(item: $exercisesRoute) { route in
                BodyPartExercisesView(bodyPart: route.region)
            }
            .onChange(of: exercisesRoute) { oldValue, newValue in
                // Popped back to the zoom — re-drive the scene so the body
                // re-renders and the labels re-project.
                if oldValue != nil, newValue == nil, !disambiguationCandidates.isEmpty {
                    refocusToken += 1
                }
            }
            .onAppear { impact.prepare() }
        }
    }

    private var isDisambiguating: Bool { !disambiguationCandidates.isEmpty }

    // MARK: - Fast path (single tap)

    /// The body has already rotated to face the point by the time this fires
    /// — BodySceneView owns the rig, so it does the turn itself.
    private func handleRegionSelected(region: String, point: SIMD3<Float>) {
        withAnimation(.easeInOut(duration: 0.18)) {
            selection = RegionSelection(region: region, point: point)
        }
        impact.impactOccurred()
        tourCoordinator.notifyInteraction(id: "bodymap.tapRegion")
    }

    private func clearSelection() {
        withAnimation(.easeInOut(duration: 0.18)) { selection = nil }
    }

    // MARK: - Precise path (double tap)

    /// Surfaces the muscle groups plausibly meant by the tap
    /// (`MuscleHitResolver.candidates`) as labeled pins — the point is to let
    /// the user disambiguate *which* muscle they mean before seeing
    /// exercises. Only if no hit volume resolves at all do we fall back to
    /// navigating straight to the tapped region.
    private func handleRegionDrilled(region: String, point: SIMD3<Float>) {
        // The head fans out into fixed, evidence-based face zones with
        // hand-tuned anchors instead of geometric hit-box candidates. Side is
        // inferred from the tapped x (see HeadZones).
        if region == "Head" {
            let pins = HeadZones.candidates(forTapAt: point)
            focusPoint = point
            focusedRegion = pins.first?.name
            disambiguationCandidates = pins
            return
        }
        // Pull a few extra candidates so that, after dropping any parent group
        // whose heads are already present, we still have a full set of ≤4.
        let raw = MuscleHitResolver.candidates(near: point,
                                               in: BodyHitVolumes.all, maxCandidates: 6)
        let presentParents = Set(raw.compactMap { MuscleGroup.parentOfHead($0) })
        let candidates = raw.filter { !presentParents.contains($0) }.prefix(4)
        let volumesByName = Dictionary(uniqueKeysWithValues: BodyHitVolumes.all.map { ($0.name, $0) })
        let pins = candidates.compactMap { name in
            volumesByName[name].map {
                MarkCandidate(name: name, point: $0.center,
                              minBound: $0.minBound, maxBound: $0.maxBound)
            }
        }
        if pins.isEmpty {
            exercisesRoute = ExercisesRoute(region: region)
        } else {
            // Zoom onto the actual tapped dot (not a candidate centre) and
            // auto-highlight the primary candidate.
            focusPoint = point
            focusedRegion = pins.first?.name
            disambiguationCandidates = pins
        }
    }

    /// First tap on a candidate (region box or side label) highlights it.
    private func handleCandidateFocused(_ region: String) {
        withAnimation(.easeInOut(duration: 0.15)) { focusedRegion = region }
        impact.impactOccurred()
    }

    /// Second tap on the focused candidate → drill into its exercises. The
    /// zoom/candidate/focus state is deliberately KEPT alive so pressing Back
    /// returns to the zoomed dot; it's torn down only by Cancel.
    private func handleCandidateSelected(_ region: String) {
        exercisesRoute = ExercisesRoute(region: region)
        tourCoordinator.notifyInteraction(id: "bodymap.findStretches")
    }

    private func cancelDisambiguation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            disambiguationCandidates = []
            focusPoint = nil
            focusedRegion = nil
        }
    }

    // MARK: - Facing control

    // Not a multi-option picker — a single toggle between Front/Back — so it
    // keeps its directional icon, restyled with the same chip tokens
    // (unselected LuminaChip look) rather than wrapped in LuminaChip itself
    // (which is text-only). Still worth keeping alongside tap-to-face: there
    // is nothing to tap on the side you can't see.
    private var facingToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.28)) {
                facing = facing == .front ? .back : .front
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .medium))
                Text(facing.rawValue)
                    .font(.luminaLabel)
            }
            .foregroundStyle(Color.luminaOnSurfaceVariant)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.luminaContainer, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle body facing — currently \(facing.rawValue)")
    }
}

// MARK: - Preview

#Preview {
    BodyMapView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
```

- [ ] **Step 7: Build and fix the fallout**

```
xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: **BUILD SUCCEEDED.** This task is deliberately sequenced so the
app still compiles: `BodyRig.updateMarks` survives untouched and its
`sensationColors` / `BodyMark` dependencies still exist (Task 4 deletes all
three together). `updateMarks` is simply dead code for the length of this
one commit.

Two failures are expected only if something was missed:
- `cannot find 'MarkedAreasBanner' in scope` → a call site survived Step 1
- `extra argument 'marks'` / `'onRegionTap'` → a `BodySceneView(...)` call
  site still uses the old parameter names from Step 3

Anything else is a genuine mistake in Steps 1–6 — fix it before moving on.

- [ ] **Step 8: Verify both paths in the simulator**

Use the project's `verify` skill to launch the app, open the Body tab, and confirm by screenshot:
1. A single tap on the shoulder turns the body toward it and raises a bar reading "Stretches for …".
2. Tapping the bar pushes the stretch list for that region.
3. A double tap opens the muscle picker with rail labels.
4. A tap off the body clears the bar.

- [ ] **Step 9: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift" "Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift" "Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift"
git commit -m "feat(bodymap): single tap faces a region, double tap opens the muscle picker"
```

---

## Task 4: Remove the marking flow

**Files:**
- Delete: `Breath - Relax & Stretch/Views/BodyMap/Sensations.swift`
- Delete: `Breath - Relax & Stretch/Models/BodyMarkStore.swift`
- Delete: `Breath - Relax & StretchTests/BodyMarkStoreTests.swift`
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift` (remove `updateMarks`)
- Modify: `Breath - Relax & Stretch/Services/SeedMigrator.swift`
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`
- Test: `Breath - Relax & StretchTests/BodyRigRotationTests.swift` (append)

**Interfaces:**
- Consumes: nothing new
- Produces: `static func SeedMigrator.removeRetiredBodyMapMarkStorage(defaults: UserDefaults = .standard)`

- [ ] **Step 1: Write the failing test for the defaults cleanup**

Append to `BodyRigRotationTests.swift`:

```swift
/// The marking feature's persisted state outlives the feature itself, so it
/// gets cleaned up on launch. Idempotent by construction — `removeObject` on
/// an absent key is a no-op — so it is safe to run every time.
struct RetiredBodyMapStorageTests {

    private func freshDefaults() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func theRetiredMarkKeyIsRemoved() {
        let defaults = freshDefaults()
        defaults.set(Data([0x7b, 0x7d]), forKey: "bodymap.markedSensations")
        SeedMigrator.removeRetiredBodyMapMarkStorage(defaults: defaults)
        #expect(defaults.object(forKey: "bodymap.markedSensations") == nil)
    }

    @Test func runningItTwiceIsHarmless() {
        let defaults = freshDefaults()
        SeedMigrator.removeRetiredBodyMapMarkStorage(defaults: defaults)
        SeedMigrator.removeRetiredBodyMapMarkStorage(defaults: defaults)
        #expect(defaults.object(forKey: "bodymap.markedSensations") == nil)
    }

    @Test func itLeavesTheOlderRegionMigrationKeyAlone() {
        // `bodymap.markedRegions` is a DIFFERENT key with a live migration in
        // migrateV4. This cleanup must not touch it.
        let defaults = freshDefaults()
        defaults.set(["Left Biceps"], forKey: "bodymap.markedRegions")
        SeedMigrator.removeRetiredBodyMapMarkStorage(defaults: defaults)
        #expect(defaults.stringArray(forKey: "bodymap.markedRegions") == ["Left Biceps"])
    }
}
```

- [ ] **Step 2: Run and verify it fails**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RetiredBodyMapStorageTests"
```

Expected: **compile failure** — no member `removeRetiredBodyMapMarkStorage`.

- [ ] **Step 3: Add the cleanup to `SeedMigrator`**

At the end of `SeedMigrator` (after `migrateV11`, before the type's closing brace), add:

```swift
    /// Drops the storage behind the retired body-map marking flow (sensation
    /// colours + marked regions with dots), removed in the "Tap to Stretch"
    /// rework. Not a versioned seed migration — it touches no SwiftData and
    /// carries no `seedDataVersion` gate; `removeObject` on an absent key is
    /// a no-op, so running it on every launch costs nothing.
    ///
    /// Deliberately does NOT touch `bodymap.markedRegions`, which is a
    /// different, still-live key migrated by `migrateV4`.
    static func removeRetiredBodyMapMarkStorage(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: "bodymap.markedSensations")
    }
```

- [ ] **Step 4: Call it on launch**

In `Breath__Relax___StretchApp.swift`, immediately after the `migrateSeedToV11IfNeeded()` function definition, add:

```swift
    /// One-line cleanup of retired body-map marking storage. Unlike the
    /// `migrateSeedToVNIfNeeded` family this has no version gate — it is
    /// idempotent and touches only UserDefaults.
    private func removeRetiredBodyMapStorage() {
        SeedMigrator.removeRetiredBodyMapMarkStorage()
    }
```

Then call `removeRetiredBodyMapStorage()` from the same place `migrateSeedToV11IfNeeded()` is called, immediately after it.

- [ ] **Step 5: Run and verify the tests pass**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RetiredBodyMapStorageTests"
```

Expected: **3 tests, all passing.**

- [ ] **Step 6: Delete `updateMarks` from `BodyRig`**

In `BodySceneView.swift`, delete the whole `updateMarks(_:)` function (`:312`–`:326`, from its `/// Rebuilds the marker-dot spheres…` doc comment through its closing brace). `updateSelection` replaced it in Task 2 and is already wired up.

- [ ] **Step 6b: Clear the two loose ends the Task 3 review found**

Both are dead remnants of the removed flow, verified unreferenced.

First, `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift` around
line 714 still documents `disambiguationCandidates` as *"the post-confirm
disambiguation popup"*. There is no Confirm step any more — the trigger is a
double tap. Reword that doc comment to describe the double-tap trigger.

Second, `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift`
around line 125 declares two initializers:

```swift
    init(bodyPart: String)        { self.bodyParts = [bodyPart] }
    init(bodyParts: [String])     { self.bodyParts = bodyParts }
```

`init(bodyParts:)` was reached only by the deleted `.marked([String])` route.
Verified unreferenced app-wide: the sole construction site is
`BodyMapView.swift:103`, using `init(bodyPart:)`. Delete the
`init(bodyParts:)` line only.

**Leave the internal `bodyParts` array plumbing alone** — the `navTitle` /
`emptyDescription` multi-region branches and `RegionExerciseResolver(regions:)`
all still take a collection, and collapsing that is a larger refactor with no
behavioural benefit and no bearing on this rework.

- [ ] **Step 7: Delete the three files**

```bash
git rm "Breath - Relax & Stretch/Views/BodyMap/Sensations.swift"
git rm "Breath - Relax & Stretch/Models/BodyMarkStore.swift"
git rm "Breath - Relax & StretchTests/BodyMarkStoreTests.swift"
```

`Sensations.swift` holds `SensationColor`, `sensationColors` **and** `LegendSheet` — all three go together, so there is no separate `LegendSheet` edit.

- [ ] **Step 8: Confirm nothing references the deleted symbols**

```bash
grep -rn "BodyMarkStore\|SensationColor\|sensationColors\|LegendSheet\|MarkedAreasBanner\|BodyMark\b\|updateMarks" --include='*.swift' .
```

Expected: **no output.** Any hit is a reference the earlier tasks missed — fix it before building.

Then confirm the multi-region initializer is gone but its property survives:

```bash
grep -rn "init(bodyParts:" --include='*.swift' .   # expect: no output
grep -rn "let bodyParts" --include='*.swift' .     # expect: the property declaration only
```

- [ ] **Step 9: Run the full unit suite**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"
```

Expected: **all tests passing, 0 failures.** The baseline is green, so any failure is yours.

- [ ] **Step 10: Commit**

```bash
git add -A "Breath - Relax & Stretch" "Breath - Relax & StretchTests"
git commit -m "refactor(bodymap): delete the marking flow, its store and its colour palette"
```

---

## Task 5: Onboarding tour

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Onboarding/TourCoordinator.swift` (`:30`–`:32` doc comment, `:102`–`:107` steps)
- Modify: `Breath - Relax & StretchTests/TourCoordinatorTests.swift` (lines 73–117)

**Interfaces:**
- Consumes: `.tourAnchor("bodymap.tapRegion")` and `.tourAnchor("bodymap.findStretches")` placed by Task 3
- Produces: tour step IDs `bodymap.tapRegion`, `bodymap.findStretches`

- [ ] **Step 1: Update the failing test expectations first**

In `TourCoordinatorTests.swift`, replace every `"bodymap.tapMarkAndRegion"` with `"bodymap.tapRegion"` and every `"bodymap.confirmMark"` with `"bodymap.findStretches"` (lines 73–117). Then update the `fixedFrame` assertion at line 117: `bodymap.findStretches` anchors to a real in-content view, so it no longer needs a fixed frame. Change:

```swift
        #expect(fixedFrameIDs == ["bodymap.confirmMark", "routines.createButton"])
```

to:

```swift
        #expect(fixedFrameIDs == ["routines.createButton"])
```

- [ ] **Step 2: Run and verify it fails**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/TourCoordinatorTests"
```

Expected: **FAIL** — the coordinator still emits the old IDs.

- [ ] **Step 3: Rewrite the two steps**

In `TourCoordinator.swift`, replace the two body-map steps at `:102`–`:107`:

```swift
        TourStep(id: "bodymap.tapMarkAndRegion",
                 title: "Mark a Spot", message: "Tap Mark up top, then tap a spot on the body that feels tense or sore.",
                 isInteractive: true, blocksBackgroundTaps: false),
        TourStep(id: "bodymap.confirmMark",
                 title: "Confirm It", message: "Tap the checkmark to confirm — if it asks you to pick between a couple of spots, tap the one you meant.",
                 isInteractive: true, fixedFrame: toolbarPrimaryActionFrame, blocksBackgroundTaps: false),
```

with:

```swift
        TourStep(id: "bodymap.tapRegion",
                 title: "Tap a Sore Spot", message: "Tap anywhere that feels tense or sore — the body turns to face it.",
                 isInteractive: true, blocksBackgroundTaps: false),
        TourStep(id: "bodymap.findStretches",
                 title: "Find Stretches", message: "Tap here for stretches that target it. Double-tap the body instead to pick an exact muscle.",
                 isInteractive: true, blocksBackgroundTaps: false),
```

- [ ] **Step 4: Update the coordinator's doc comment**

At `TourCoordinator.swift:30`–`:32`, replace:

```swift
    /// - `bodymap.tapMarkAndRegion` needs the toolbar Mark button tapped
```

...and the `bodymap.confirmMark` line beneath it, with:

```swift
    /// - `bodymap.tapRegion` advances when the user taps the body
    /// - `bodymap.findStretches` anchors to the action bar, which only
    ///   exists once a region is selected — so it follows `bodymap.tapRegion`
```

- [ ] **Step 5: Run and verify it passes**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/TourCoordinatorTests"
```

Expected: PASS.

- [ ] **Step 6: Confirm no stale IDs remain**

```bash
grep -rn "bodymap.tapMarkAndRegion\|bodymap.confirmMark" --include='*.swift' .
```

Expected: **no output.**

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/TourCoordinator.swift" "Breath - Relax & StretchTests/TourCoordinatorTests.swift"
git commit -m "feat(onboarding): retarget the body-map tour steps at tap-to-stretch"
```

---

## Task 6: UI tests for both paths

**Files:**
- Rewrite: `Breath - Relax & StretchUITests/BodyMapMarking3DUITests.swift`
- Rewrite: `Breath - Relax & StretchUITests/BodyMapConfirmZoomUITests.swift`

**Interfaces:**
- Consumes: accessibility identifier `"bodymap.regionActionBar"` from Task 3

**Carried forward from Task 3 — use `press(forDuration:)` for single taps on
the body, not `.tap()`.** The single-tap recogniser is wired
`singleTap.require(toFail: doubleTap)`, and XCUITest's bare
`XCUICoordinate.tap()` does not reliably satisfy that dependency — the tap
can be consumed while the double-tap recogniser is still deciding, so the
selection never appears and the test flakes. `press(forDuration: 0.05)` on
the same coordinate does satisfy it. Task 3 confirmed this against the real
app (a reverted diagnostic showed the app behaving correctly under a manual
tap), so this is an XCUITest harness artifact, not a bug in the gesture
wiring — do NOT "fix" the app to make `.tap()` work.

This applies only to taps landing on the SceneKit surface, which go through
the gesture-recogniser pair. `bar.tap()` and `app.buttons["Cancel"].tap()`
are ordinary SwiftUI buttons and are unaffected. `.doubleTap()` is likewise
unaffected — it drives the double-tap recogniser directly, with nothing to
wait on.

- [ ] **Step 1: Rewrite the fast-path test**

Replace the body of `BodyMapMarking3DUITests.swift` — keep its existing `setUpWithError`, `launchBodyTab(extraArgs:)` and `attach(_:_:)` helpers verbatim (they handle the 30s seed/migration wait and the 6s OBJ parse, both still needed) and replace the `@Test`-bearing methods with:

```swift
    /// Fast path: one tap names a region, one more reaches its stretches.
    @MainActor
    func testSingleTapRaisesActionBarAndReachesStretches() throws {
        let app = launchBodyTab(extraArgs: [])
        attach(app, "01-body-at-rest")

        // Tap upper-left of the torso — reliably a shoulder/arm hit volume.
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.34)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5),
                      "A single tap on the body should raise the region action bar")
        attach(app, "02-bar-raised")

        let barLabel = bar.label
        XCTAssertTrue(barLabel.hasPrefix("Find stretches for "),
                      "Bar should name the region it will search; got '\(barLabel)'")

        bar.tap()
        // The pushed list is titled with the region name.
        let region = String(barLabel.dropFirst("Find stretches for ".count))
        XCTAssertTrue(app.navigationBars[region].waitForExistence(timeout: 5),
                      "Tapping the bar should push the stretch list for '\(region)'")
        attach(app, "03-stretch-list")
    }

    /// A tap that resolves no region clears the selection rather than leaving
    /// a stale bar pointing at the wrong body part.
    @MainActor
    func testTappingOffTheBodyClearsTheBar() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.34)).press(forDuration: 0.05)

        let bar = app.buttons["bodymap.regionActionBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))

        // Far left edge, clear of the silhouette.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.5)).press(forDuration: 0.05)
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: bar)
        waitForExpectations(timeout: 5)
        attach(app, "04-bar-cleared")
    }

    /// Drag must still rotate — tap-to-face shares the same surface and the
    /// single-tap recogniser must not swallow a pan.
    @MainActor
    func testDragStillRotatesTheBody() throws {
        let app = launchBodyTab(extraArgs: [])
        attach(app, "05-before-drag")
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: scene.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        sleep(1)
        attach(app, "06-after-drag")
        // No bar: a drag is not a tap.
        XCTAssertFalse(app.buttons["bodymap.regionActionBar"].exists,
                       "A drag should rotate without selecting a region")
    }
```

- [ ] **Step 2: Rewrite the precise-path test**

In `BodyMapConfirmZoomUITests.swift`, keep the existing launch/attach helpers and replace the test methods with:

```swift
    /// Precise path: a double tap opens the muscle picker directly — no Mark
    /// mode, no colour, no checkmark.
    @MainActor
    func testDoubleTapOpensTheMusclePicker() throws {
        let app = launchBodyTab(extraArgs: [])
        attach(app, "01-body-at-rest")

        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.34)).doubleTap()

        // The picker replaces the facing toggle with a Cancel affordance and
        // the "Which area did you mean?" prompt.
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 8),
                      "A double tap should open the muscle-selection overlay")
        attach(app, "02-muscle-picker")

        XCTAssertTrue(app.buttons["Cancel"].exists,
                      "The picker should offer a way out")
    }

    /// Cancelling the picker returns to the plain body without navigating.
    @MainActor
    func testCancellingThePickerReturnsToTheBody() throws {
        let app = launchBodyTab(extraArgs: [])
        let scene = app.otherElements.firstMatch
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.34)).doubleTap()
        XCTAssertTrue(app.staticTexts["Which area did you mean?"].waitForExistence(timeout: 8))

        app.buttons["Cancel"].tap()
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["Which area did you mean?"])
        waitForExpectations(timeout: 5)
        attach(app, "03-back-to-body")
    }
```

- [ ] **Step 3: Run the two UI suites**

```
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/BodyMapMarking3DUITests" -only-testing:"Breath - Relax & StretchUITests/BodyMapConfirmZoomUITests"
```

After Step 3b, re-run including whichever of the four you repointed, e.g.
`-only-testing:"Breath - Relax & StretchUITests/MuscleRevealUITest"`.


Expected: all cases pass. If a tap lands on empty space rather than the body, adjust the normalized offsets — the model is height-normalized and centred, so `dx` between 0.35 and 0.65 and `dy` between 0.3 and 0.6 is the reliable band. Attachments are kept, so open the screenshots to see where the tap landed rather than guessing.

- [ ] **Step 3b: Deal with the four OTHER UI test files that drive the removed UI**

Found by the Task 3 review — a gap in this plan, not something the earlier
tasks missed. Four suites beyond the two you just rewrote still query
`"Mark areas by tapping"`, `"Confirm marked area"` or
`"Find exercises for marked areas"`:

- `Breath - Relax & StretchUITests/MuscleRevealUITest.swift:25`
- `Breath - Relax & StretchUITests/AnatomyRevealUITest.swift:29`
- `Breath - Relax & StretchUITests/AnatomyJointRevealUITest.swift:23`
- `Breath - Relax & StretchUITests/HeadZoneVerificationUITests.swift:51`

They still **compile** — XCUITest addresses elements by string, not by app
symbol — so nothing went red and the unit suite never noticed. They will
**time out at runtime**, because the UI they drive no longer exists.

For each, read what the suite actually verifies, then take whichever route
fits:

- If its real subject is the muscle/anatomy reveal or the head zones — i.e.
  the muscle-selection overlay, which still exists — **repoint it at the
  double-tap trigger**. Replace the Mark → tap → ✓ preamble with a single
  `scene.coordinate(withNormalizedOffset:).doubleTap()`, keeping every
  assertion about what the reveal shows. The overlay itself is unchanged, so
  these assertions should still hold.
- If the suite exists only to exercise the marking flow itself, **delete it**
  — that behaviour is gone and Tasks 1–3 replaced its coverage.

State in your report which route you took for each of the four, and why.
Deleting a suite that still tests live behaviour is worse than repointing it,
so prefer repointing when the subject survives.

Use `press(forDuration: 0.05)` rather than `.tap()` for any single tap on the
body, per the note above.

- [ ] **Step 4: Rename the files to match what they now test**

```bash
git mv "Breath - Relax & StretchUITests/BodyMapMarking3DUITests.swift" "Breath - Relax & StretchUITests/BodyMapFastPathUITests.swift"
git mv "Breath - Relax & StretchUITests/BodyMapConfirmZoomUITests.swift" "Breath - Relax & StretchUITests/BodyMapMusclePickerUITests.swift"
```

Rename the classes inside to `BodyMapFastPathUITests` and `BodyMapMusclePickerUITests` to match. Re-run Step 3's command with the new suite names to confirm.

- [ ] **Step 5: Commit**

```bash
git add -A "Breath - Relax & StretchUITests"
git commit -m "test(bodymap): cover the tap-to-stretch fast path and the double-tap picker"
```

---

## Task 7: Refresh the knowledge graph

**Files:** `graphify-out/` (generated)

- [ ] **Step 1: Update the graph**

Per `CLAUDE.md`, the graph must be kept current after code changes. AST-only, no API cost:

```bash
graphify update .
```

- [ ] **Step 2: Do NOT commit it**

`graphify-out/` is deliberately git-ignored — see `.gitignore:40`, whose own
comment says "regenerate with `graphify update .`". It is generated AST cache
(~651 files, ~124k lines), derived entirely from the source, and committing it
would bloat the repo and conflict on every branch.

There is nothing to commit for this task. The refreshed graph lives on disk
for this checkout, which is the whole point.

**If you find yourself reaching for `git add -f` here, stop** — the force flag
is the signal that the ignore rule is doing its job, not an obstacle to route
around.

---

## Self-Review

**Spec coverage.** Every spec section maps to a task: §2.1 gesture map → Task 3; §3.1 gesture layer → Task 3 Steps 2 and 4; §3.2 interface → Task 3 Step 3; §3.3 rotate-to-face → Tasks 1 and 3 Step 4; §3.4 `BodyMapView` → Task 3 Step 6; §3.5 chrome → Task 3 Steps 1 and 6; §4 files → Tasks 3 and 4; §5 tour → Task 5; §7 accepted cost → documented in the `require(toFail:)` comment in Task 3 Step 2; §8 verification → Tasks 1, 2, 4 (units) and 6 (UI).

**Two things the spec named that this plan resolves differently, deliberately:**
1. The spec's `.marked([String])` removal is folded into Task 3's `BodyMapView` rewrite rather than getting its own step — the new file simply has no such case.
2. The spec lists `LegendSheet` as a `BodyMapComponents.swift` edit; it actually lives in `Sensations.swift`, so it is deleted with that file in Task 4 Step 7. The spec has been corrected to match.

**Type consistency check.** `rotationToFace` and `shortestDelta` are defined in Task 1 and used in Task 3 Step 4 with the same signatures. `updateSelection(point:)` is defined in Task 2 and called in Task 3 Step 5. `RegionActionBar(regionName:onFind:)` is defined in Task 3 Step 1 and constructed in Step 6 with the same labels. `removeRetiredBodyMapMarkStorage(defaults:)` is defined in Task 4 Step 3 and called in Step 4. The accessibility identifier `"bodymap.regionActionBar"` is set in Task 3 Step 1 and queried in Task 6 Step 1. Tour IDs `bodymap.tapRegion` / `bodymap.findStretches` are placed as anchors in Task 3 Step 6 and declared in Task 5 Step 3.

**Ordering constraint.** Task 4 must follow Task 3: `updateMarks` cannot be deleted until nothing calls it, and `Sensations.swift` cannot be deleted until `updateMarks` is gone. Tasks 5, 6 and 7 can be done in any order after Task 4.
