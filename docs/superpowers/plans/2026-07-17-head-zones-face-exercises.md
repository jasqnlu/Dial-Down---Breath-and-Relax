# Head Zones + Face Exercises Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the body map's single `Head` region into four evidence-based, tappable face zones (Eyes, Temples, Jaw/TMJ, Forehead) that fan out as accurately-placed pins and open their own exercises.

**Architecture:** A tap on the head still resolves to the coarse `Head` hit-box; the confirm step then injects a fixed four-pin set from a hand-tuned anchor table (`HeadZones`) instead of geometric hit-box candidates, reusing the existing `MarkCandidate` → `showCandidates` → `CandidateRailOverlay` disambiguation pipeline. The four zone names are registered as sub-heads of `Head` (parent = `Head`) so exercises resolve directly and fall back to the shared head list. No new 3D hit-boxes.

**Tech Stack:** Swift, SwiftUI, SwiftData, SceneKit/simd, Swift Testing.

## Global Constraints

- **Evidence-based only.** No anti-wrinkle / "facial fitness" / anti-aging language in any name, instruction, caution, or copy. Frame as eye-strain, TMJ, and tension relief. (Cheeks and Mouth zones were deliberately excluded.)
- **Test framework:** Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`) — never XCTest. App module is `BreathRelaxStretch`; tests use `@testable import BreathRelaxStretch`.
- **Test target auto-syncs:** any `.swift` file dropped in `Breath - Relax & StretchTests/` joins the target automatically (no `.pbxproj` edits).
- **Test command:** `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- **Region names must be registered** in `MuscleGroup.muscleHeads` (parent `Head`) or the resolver/tests reject them.
- **Seed `id`s** are any unique valid UUID string; uniqueness is enforced by tests, derivation scheme is not.
- **Convention:** person's Left = world **+X** at front view (matches the app). So a tap with normalized `x >= 0` offers Left zones.

---

### Task 1: Register the four face zones in `muscleHeads` (with midline support)

**Files:**
- Modify: `Breath - Relax & Stretch/Models/MuscleGroups.swift:70-92`
- Test: `Breath - Relax & StretchTests/MuscleHeadTests.swift` (append tests)

**Interfaces:**
- Produces: `MuscleGroup.headZones: [(base: String, bilateral: Bool)]`; entries added to `MuscleGroup.muscleHeads` mapping `"Left Eye"|"Right Eye"|"Left Temple"|"Right Temple"|"Left Jaw"|"Right Jaw"|"Forehead"` → `"Head"`. `MuscleGroup.parentOfHead(_:)` returns `"Head"` for each.

- [ ] **Step 1: Write the failing tests** — append to `MuscleHeadTests.swift`:

```swift
    @Test func faceZonesResolveToHeadParent() {
        for zone in ["Left Eye", "Right Eye", "Left Temple", "Right Temple",
                     "Left Jaw", "Right Jaw", "Forehead"] {
            #expect(MuscleGroup.parentOfHead(zone) == "Head",
                    "\(zone) should parent to Head")
        }
    }

    @Test func foreheadIsMidlineWithNoSide() {
        #expect(MuscleGroup.muscleHeads["Forehead"] == "Head")
        #expect(MuscleGroup.muscleHeads["Left Forehead"] == nil)
        #expect(MuscleGroup.muscleHeads["Right Forehead"] == nil)
    }

    @Test func bilateralFaceZonesComeInPairs() {
        for base in ["Eye", "Temple", "Jaw"] {
            #expect(MuscleGroup.muscleHeads["Left \(base)"] == "Head")
            #expect(MuscleGroup.muscleHeads["Right \(base)"] == "Head")
        }
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/MuscleHeadTests"`
Expected: FAIL — `parentOfHead("Left Eye")` returns `nil`.

- [ ] **Step 3: Add the head-zone table + expansion.** In `MuscleGroups.swift`, immediately **before** the `static let muscleHeads` declaration (around line 70), insert:

```swift
    /// Face zones that subdivide the coarse `Head` group. Bilateral zones
    /// expand to Left/Right; midline zones (Forehead) register as-is. All
    /// resolve to the `Head` parent, so a zone with no curated exercise falls
    /// back to the shared head list (see RegionExerciseResolver). Kept strictly
    /// evidence-based — eyes (strain), temples & forehead (tension), jaw (TMJ).
    /// No cheeks/mouth: anti-wrinkle claims are unsupported.
    static let headZones: [(base: String, bilateral: Bool)] = [
        ("Eye", true), ("Temple", true), ("Jaw", true), ("Forehead", false),
    ]
```

Then inside the `muscleHeads` initializer, **after** the existing `for entry in byGroup { … }` loop and **before** `return map`, insert:

```swift
        // Face zones: parent is always the coarse "Head" group (no side-specific
        // parent, unlike muscle sub-heads).
        for zone in headZones {
            if zone.bilateral {
                map["Left \(zone.base)"] = "Head"
                map["Right \(zone.base)"] = "Head"
            } else {
                map[zone.base] = "Head"
            }
        }
```

- [ ] **Step 4: Run tests to verify they pass**

Run the same command as Step 2, plus the existing suite:
`xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/MuscleHeadTests"`
Expected: PASS — including the pre-existing `everyHeadMapsToAValidParentGroup`, `headsComeInLeftRightPairs` (Forehead is not `Left `-prefixed, so it is unaffected).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/MuscleGroups.swift" "Breath - Relax & StretchTests/MuscleHeadTests.swift"
git commit -m "feat(bodymap): register four face zones as Head sub-heads with midline support"
```

---

### Task 2: `HeadZones` — anchor table + candidate builder

**Files:**
- Create: `Breath - Relax & Stretch/Views/BodyMap/HeadZones.swift`
- Test: `Breath - Relax & StretchTests/HeadZonesTests.swift`

**Interfaces:**
- Consumes: `MarkCandidate` (from `BodySceneView.swift`: `init(name:point:minBound:maxBound:)`, bounds default `.zero`).
- Produces: `enum HeadZones { static func candidates(forTapAt point: SIMD3<Float>) -> [MarkCandidate] }` returning exactly 4 candidates — `Forehead` (midline) plus the three bilateral zones for the inferred side, each with a hand-tuned anchor `point` and `.zero` bounds (point-marker, no box).

- [ ] **Step 1: Write the failing tests** — create `HeadZonesTests.swift`:

```swift
import Testing
import simd
@testable import BreathRelaxStretch

struct HeadZonesTests {
    @Test func returnsFourCandidatesIncludingForehead() {
        let c = HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08))
        #expect(c.count == 4)
        #expect(c.contains { $0.name == "Forehead" })
    }

    @Test func infersLeftSideForPositiveX() {
        let names = Set(HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)).map(\.name))
        #expect(names == ["Forehead", "Left Eye", "Left Temple", "Left Jaw"])
    }

    @Test func infersRightSideForNegativeX() {
        let names = Set(HeadZones.candidates(forTapAt: SIMD3(-0.05, 0.85, 0.08)).map(\.name))
        #expect(names == ["Forehead", "Right Eye", "Right Temple", "Right Jaw"])
    }

    @Test func bilateralAnchorsMirrorAcrossX() {
        let l = HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)).first { $0.name == "Left Eye" }!
        let r = HeadZones.candidates(forTapAt: SIMD3(-0.05, 0.85, 0.08)).first { $0.name == "Right Eye" }!
        #expect(l.point.x == -r.point.x)
        #expect(l.point.y == r.point.y)
    }

    @Test func foreheadIsMidline() {
        let f = HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)).first { $0.name == "Forehead" }!
        #expect(f.point.x == 0)
    }

    @Test func candidatesHaveNoBoxBounds() {
        for c in HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)) {
            #expect(c.minBound == .zero && c.maxBound == .zero)
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/HeadZonesTests"`
Expected: FAIL — `HeadZones` is not defined.

- [ ] **Step 3: Create `HeadZones.swift`:**

```swift
import Foundation
import simd

/// Turns a tap on the coarse `Head` region into the four evidence-based face
/// zone candidates, fanned out as accurately-placed pins. Unlike muscle
/// disambiguation (geometric, from hit volumes), the head uses a fixed set with
/// hand-tuned anchor points — no per-feature hit boxes. Side is inferred from
/// the tap: person's Left is +X at front view (the app convention), so a tap
/// with `x >= 0` offers Left zones, `x < 0` offers Right.
enum HeadZones {

    /// Anchor points in rigNode-local normalized model space (height-2, centred
    /// on the whole-body bbox). Stored for the +X (person's Left) side; the
    /// Right side mirrors x. Forehead is midline (x = 0).
    ///
    /// NOTE: these are initial estimates. They MUST be tuned against the skin
    /// model in the simulator in Task 5 until each dot sits on its feature.
    private static let leftAnchors: [String: SIMD3<Float>] = [
        "Eye":    SIMD3(0.045, 0.86, 0.085),
        "Temple": SIMD3(0.075, 0.89, 0.050),
        "Jaw":    SIMD3(0.055, 0.79, 0.060),
    ]
    private static let foreheadAnchor = SIMD3<Float>(0.0, 0.93, 0.090)

    static func candidates(forTapAt point: SIMD3<Float>) -> [MarkCandidate] {
        let personLeft = point.x >= 0
        let side = personLeft ? "Left" : "Right"
        var out: [MarkCandidate] = [MarkCandidate(name: "Forehead", point: foreheadAnchor)]
        for base in ["Eye", "Temple", "Jaw"] {
            guard let a = leftAnchors[base] else { continue }
            let anchor = personLeft ? a : SIMD3(-a.x, a.y, a.z)
            out.append(MarkCandidate(name: "\(side) \(base)", point: anchor))
        }
        return out
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Step 2 command. Expected: PASS (all 6 tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/HeadZones.swift" "Breath - Relax & StretchTests/HeadZonesTests.swift"
git commit -m "feat(bodymap): HeadZones fixed face-zone candidate set with side inference"
```

---

### Task 3: Wire the head fan-out into the confirm step + render point pins

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift:216-217` (top of `confirmPendingMark`)
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift:318-340` (`showCandidates` loop)

**Interfaces:**
- Consumes: `HeadZones.candidates(forTapAt:)` (Task 2); existing `@State` `focusPoint`, `focusedRegion`, `disambiguationCandidates`; `MarkCandidate.point`.
- Produces: no new symbols. Behavioural: tapping `Head` shows the four zone pins; zero-bounds candidates render as small solid spheres at their `point`.

This task is UI glue over already-tested logic (`HeadZones` in Task 2). Its acceptance is: the full unit suite still passes (no regressions) and it builds; the on-device behaviour is verified in Task 5.

- [ ] **Step 1: Inject the head set in `confirmPendingMark`.** In `BodyMapView.swift`, the method currently begins:

```swift
    private func confirmPendingMark() {
        guard let pendingMark else { return }
        // Pull a few extra candidates so that, after dropping any parent group
```

Insert, immediately after the `guard let pendingMark else { return }` line:

```swift

        // The head fans out into fixed, evidence-based face zones with
        // hand-tuned anchors instead of geometric hit-box candidates. Side is
        // inferred from the tapped x (see HeadZones).
        if pendingMark.region == "Head" {
            let pins = HeadZones.candidates(forTapAt: pendingMark.point)
            focusPoint = pendingMark.point
            focusedRegion = pins.first?.name
            disambiguationCandidates = pins
            return
        }
```

- [ ] **Step 2: Render point candidates as spheres in `showCandidates`.** In `BodySceneView.swift`, replace the loop body that currently starts at `let size = c.maxBound - c.minBound` and builds only an `SCNBox` (lines ~321-339). Replace from `let size = c.maxBound - c.minBound` through the `overlayNode.addChildNode(node)` line with:

```swift
            let size = c.maxBound - c.minBound
            let isPoint = !(size.x > 0 && size.y > 0 && size.z > 0)
            let isFocused = c.name == focused
            let color = CandidatePalette.uiColor(i)

            let m = SCNMaterial()
            m.isDoubleSided = true
            m.readsFromDepthBuffer = false     // always draw over the skin (x-ray)
            m.writesToDepthBuffer = false

            let geometry: SCNGeometry
            if isPoint {
                // Face zones carry no box — draw a solid dot at the anchor.
                geometry = SCNSphere(radius: CGFloat(isFocused ? 0.028 : 0.022))
                m.diffuse.contents = color
                m.emission.contents = color.withAlphaComponent(isFocused ? 0.6 : 0.35)
            } else {
                geometry = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y),
                                  length: CGFloat(size.z), chamferRadius: 0.01)
                m.diffuse.contents = color.withAlphaComponent(isFocused ? 0.5 : 0.16)
                m.emission.contents = color.withAlphaComponent(isFocused ? 0.4 : 0.1)
            }
            geometry.materials = [m]

            let node = SCNNode(geometry: geometry)
            node.name = "candidate:\(c.name)"
            let center = isPoint ? c.point : (c.minBound + c.maxBound) / 2
            node.position = SCNVector3(center.x, center.y, center.z)
            node.renderingOrder = isFocused ? 21 : 20
            overlayNode.addChildNode(node)
```

Note: the original `guard size.x > 0 … else { continue }` line is removed — point candidates are now rendered, not skipped.

- [ ] **Step 3: Build + run the full unit suite to confirm no regressions**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: PASS (build succeeds; all suites green, including `MuscleHitResolverTests`).

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift" "Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift"
git commit -m "feat(bodymap): fan head tap into four face-zone pins, render point candidates as dots"
```

---

### Task 4: Face-zone exercises in the seed catalog + test updates

**Files:**
- Modify: `Breath - Relax & Stretch/Resources/SeedData.json` (add 7 entries, re-tag 3)
- Modify: `Breath - Relax & StretchTests/SeedDataTests.swift` (accept head targets; add coverage test)

**Interfaces:**
- Consumes: zone names registered in Task 1.
- Produces: seed exercises tagged with `Left Eye`/`Right Eye`/`Left Temple`/`Right Temple`/`Left Jaw`/`Right Jaw`/`Forehead`.

- [ ] **Step 1: Update the failing invariant test + add coverage test.** In `SeedDataTests.swift`, change `allTargetsAreValidGroups` to accept sub-head/zone names:

```swift
    @Test func allTargetsAreValidGroups() throws {
        for raw in try Self.loadExercises() {
            for part in (raw["targetBodyParts"] as? [String] ?? []) {
                let isGroup = MuscleGroup(rawValue: part) != nil
                let isHead = MuscleGroup.parentOfHead(part) != nil
                #expect(isGroup || isHead,
                        "\(raw["name"] ?? "?") targets unknown '\(part)'")
            }
        }
    }
```

Then append a coverage test:

```swift
    @Test func faceZoneExercisesTargetRegisteredZones() throws {
        let zones: Set<String> = ["Left Eye", "Right Eye", "Left Temple",
                                  "Right Temple", "Left Jaw", "Right Jaw", "Forehead"]
        let all = try Self.loadExercises()
        for zone in zones {
            let hit = all.contains { raw in
                (raw["targetBodyParts"] as? [String] ?? []).contains(zone)
            }
            #expect(hit, "No seed exercise targets the '\(zone)' zone")
        }
    }
```

- [ ] **Step 2: Run tests to verify the coverage test fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedDataTests"`
Expected: FAIL — `faceZoneExercisesTargetRegisteredZones` (no zone-tagged exercises exist yet).

- [ ] **Step 3a: Re-tag 3 existing entries in `SeedData.json`.** Find each entry by `"name"` and change the listed fields (keep each entry's existing `"id"`):

- **`Eye Palming`** → set `"targetBodyParts": ["Left Eye", "Right Eye"]` (was `["Head"]`). Leave `type` and instructions as-is.
- **`Temple & Jaw Release`** → set `"name": "Temporalis Release"`, `"targetBodyParts": ["Left Temple", "Right Temple"]`, and replace `"instructions"` with:

```json
      "instructions": [
        "Place two fingers on the soft spot at each temple.",
        "Make slow, small circles with light, comfortable pressure.",
        "Let your jaw relax and your teeth part slightly as you work.",
        "Keep breathing slowly and evenly throughout.",
        "Continue gently for the full duration, then rest."
      ],
      "caution": "Use gentle pressure only. Skip if you have a headache disorder that worsens with touch or any scalp or skin condition."
```

- **`Forehead & Scalp Press Release`** → set `"name": "Brow & Forehead Smoother"`, `"targetBodyParts": ["Forehead"]`, and replace `"instructions"` with:

```json
      "instructions": [
        "Rest the pads of your fingers flat across your forehead.",
        "Glide them slowly outward from the centre toward the temples.",
        "Use light, even pressure — smoothing, not pressing hard.",
        "Let your brow relax down as you breathe out.",
        "Repeat the slow glide for the full duration."
      ],
      "caution": "Use light pressure only. Avoid if you have a skin condition or injury on the forehead."
```

- [ ] **Step 3b: Add 7 new entries to the `"exercises"` array in `SeedData.json`** (each is evidence-based; keep the exact UUIDs):

```json
    {
      "name": "20-20-20 Focus Shift",
      "type": "stretch",
      "targetBodyParts": ["Left Eye", "Right Eye"],
      "durationSeconds": 60,
      "difficulty": 1,
      "instructions": [
        "Sit comfortably and look at something roughly 20 feet (6 metres) away.",
        "Let your eyes settle on it without straining to focus.",
        "Hold your gaze there for about 20 seconds, breathing slowly.",
        "Blink softly a few times to refresh your eyes.",
        "Return to your near task; repeat whenever your eyes feel tired."
      ],
      "caution": "This is a rest break, not a treatment. See an eye professional for persistent eye pain or changes in vision.",
      "id": "a03bd3b3-38db-4f17-a7a3-9b740e3bc5f8"
    },
    {
      "name": "Gentle Eye Rolls",
      "type": "stretch",
      "targetBodyParts": ["Left Eye", "Right Eye"],
      "durationSeconds": 45,
      "difficulty": 1,
      "instructions": [
        "Sit tall and keep your head still, looking straight ahead.",
        "Slowly move your gaze up, then trace a smooth circle: up, right, down, left.",
        "Keep the movement slow and comfortable — never forced.",
        "Complete 3 to 4 slow circles, then reverse direction.",
        "Blink and let your eyes rest for a moment when finished."
      ],
      "caution": "Stop if you feel dizzy or any eye strain. Skip if you have a recent eye injury or eye condition.",
      "id": "fa1c4ac8-4db9-4cb1-b3c8-5214d72160ca"
    },
    {
      "name": "Jaw-Open Temporalis Stretch",
      "type": "stretch",
      "targetBodyParts": ["Left Temple", "Right Temple"],
      "durationSeconds": 45,
      "difficulty": 1,
      "instructions": [
        "Sit or stand tall with relaxed shoulders.",
        "Slowly open your mouth as wide as is comfortable and pain-free.",
        "Feel a gentle stretch through the temples and jaw.",
        "Hold for about 5 seconds, then slowly close.",
        "Repeat gently and slowly for the full duration."
      ],
      "caution": "Keep within a comfortable, pain-free range. Stop if your jaw clicks, locks, or hurts, and see a dentist for diagnosed TMJ problems.",
      "id": "7f61b11d-dddd-40df-bd92-7374482d9381"
    },
    {
      "name": "Resisted Jaw Opening",
      "type": "stretch",
      "targetBodyParts": ["Left Jaw", "Right Jaw"],
      "durationSeconds": 45,
      "difficulty": 1,
      "instructions": [
        "Place your thumb or two fingers gently under your chin.",
        "Slowly open your mouth against light resistance from your fingers.",
        "Use only a small, gentle amount of pressure — this is not a strength test.",
        "Open a short way, hold for 3 seconds, then slowly close.",
        "Repeat calmly for the full duration."
      ],
      "caution": "Use very light resistance and stay pain-free. Stop if you feel clicking, locking, or pain, and see a dentist for diagnosed TMJ problems.",
      "id": "1d0178e8-3356-49b3-b4bd-7453b01923bc"
    },
    {
      "name": "Side-to-Side Jaw Glide",
      "type": "stretch",
      "targetBodyParts": ["Left Jaw", "Right Jaw"],
      "durationSeconds": 45,
      "difficulty": 1,
      "instructions": [
        "Relax your jaw with your teeth slightly apart.",
        "Slowly glide your lower jaw to one side as far as is comfortable.",
        "Return to centre, then glide gently to the other side.",
        "Keep the movement small, smooth, and pain-free.",
        "Continue slowly for the full duration."
      ],
      "caution": "Move gently within a comfortable range. Stop if the jaw clicks, locks, or hurts, and see a dentist for diagnosed TMJ problems.",
      "id": "71106fcf-922a-4728-a8cb-694fe636bd84"
    },
    {
      "name": "Tongue-Up Controlled Open/Close",
      "type": "stretch",
      "targetBodyParts": ["Left Jaw", "Right Jaw"],
      "durationSeconds": 45,
      "difficulty": 1,
      "instructions": [
        "Rest the tip of your tongue lightly on the roof of your mouth, behind your front teeth.",
        "Keeping the tongue there, slowly open your mouth only as far as it stays in contact.",
        "This keeps the jaw opening controlled and centred.",
        "Hold briefly, then slowly close.",
        "Repeat calmly for the full duration."
      ],
      "caution": "Keep it slow and pain-free. Stop if you feel clicking, locking, or pain, and see a dentist for diagnosed TMJ problems.",
      "id": "eaed664d-55e8-4e86-8dee-e038209e43dc"
    },
    {
      "name": "Frontalis Release",
      "type": "stretch",
      "targetBodyParts": ["Forehead"],
      "durationSeconds": 45,
      "difficulty": 1,
      "instructions": [
        "Rest the pads of your fingers gently across your forehead.",
        "Let your eyebrows relax downward as you breathe out slowly.",
        "Apply light, still pressure — no rubbing or pulling on the skin.",
        "Hold and breathe slowly, letting the forehead soften.",
        "Release gently after the hold and repeat."
      ],
      "caution": "Use light pressure only. Avoid if you have a skin condition or injury on the forehead.",
      "id": "aa6fd1ad-4d6e-4850-9ef5-1adcd1e3a3fb"
    }
```

- [ ] **Step 4: Validate JSON, then run tests**

Run: `python3 -c "import json; json.load(open('Breath - Relax & Stretch/Resources/SeedData.json')); print('valid json')"`
Expected: `valid json`

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedDataTests"`
Expected: PASS — `faceZoneExercisesTargetRegisteredZones`, `allTargetsAreValidGroups`, `exerciseNamesAreUnique`, and the catalog-ID uniqueness test all green.

- [ ] **Step 5: Localization check.** Determine whether body-map region names are surfaced through the string catalog:

Run: `python3 -c "import json,sys; d=json.load(open('Breath - Relax & Stretch/Resources/Localizable.xcstrings')); print('Left Trapezius' in d.get('strings',{}))"`

- If it prints `True`, add string-catalog keys for `Left Eye`, `Right Eye`, `Left Temple`, `Right Temple`, `Left Jaw`, `Right Jaw`, `Forehead` and each new/renamed exercise name, mirroring an existing region entry's structure.
- If it prints `False`, region/exercise names render from raw data — no `xcstrings` change needed; note this in the commit body.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Resources/SeedData.json" "Breath - Relax & StretchTests/SeedDataTests.swift" "Breath - Relax & Stretch/Resources/Localizable.xcstrings"
git commit -m "feat(exercises): add 7 evidence-based face-zone exercises, re-tag 3 head exercises"
```

---

### Task 5: Simulator verification + anchor tuning

**Files:**
- Modify (tuning only): `Breath - Relax & Stretch/Views/BodyMap/HeadZones.swift` (`leftAnchors`, `foreheadAnchor`)
- Reference: `.claude/skills/verify/SKILL.md` (the `verify` skill: build, launch, XCUITest taps + screenshots)

No new unit test — this task tunes the anchor constants against the real model and confirms the end-to-end flow visually.

- [ ] **Step 1: Invoke the `verify` skill** to build, launch the app in the simulator, and drive the UI. Navigate to the body map marking flow.

- [ ] **Step 2: Tap the head and screenshot.** Confirm four labelled pins fan out (Forehead, Eye, Temple, Jaw) with leader-lined labels, and that only one side's bilateral zones appear for the tapped side.

- [ ] **Step 3: Tune anchors.** Compare each dot's position to its facial feature in the screenshot. Adjust `leftAnchors`/`foreheadAnchor` in `HeadZones.swift` (x = distance from midline, y = height, z = forward) and re-run until each dot sits on its feature. Tap the head on the left and right halves to confirm mirroring.

- [ ] **Step 4: Verify selection → exercises.** Tap each zone pin/label twice (focus, then drill in) and confirm the correct exercises open — e.g. `Left Jaw` shows the three jaw/TMJ exercises; a zone with none falls back to the shared Head list (Lion's Breath, Humming Bee, Suboccipital Release).

- [ ] **Step 5: Regression pass.** Re-run the full unit suite:
`xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: PASS.

- [ ] **Step 6: Commit the tuned anchors**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/HeadZones.swift"
git commit -m "fix(bodymap): tune face-zone anchor positions to the head model"
```

- [ ] **Step 7: Update the knowledge graph**

```bash
graphify update .
```

---

## Self-Review

**Spec coverage:**
- Evidence-only positioning → Global Constraints + Task 4 content (all clinical/tension framing; cheeks/mouth excluded). ✔
- Four zones, laterality → Task 1 (`headZones` table, midline Forehead). ✔
- Tap-head → infer-side → four pins → exercises → Task 2 (`HeadZones`) + Task 3 (injection + rendering). ✔
- `muscleHeads` midline change → Task 1. ✔
- `headZones` anchor table, no new hit-boxes → Task 2 (anchors only; `musclegroup_head_hitboxes.json` untouched). ✔
- 7 new + 3 re-tag exercises with cautions → Task 4. ✔
- Migration/persistence (seedID-keyed, additive marks) → preserved by keeping ids on re-tags (Task 4 Step 3a). ✔
- Localization → Task 4 Step 5. ✔
- Testing (MuscleHeadTests, resolver/injection, SeedDataTests, verify) → Tasks 1,2,4,5. ✔
- Edge case: back-of-head resolves to Head → only `region == "Head"` triggers the fan; scalp taps still land on Head and show the general list (no face pins). Covered by Task 3 branch + Task 5 Step 4. ✔

**Placeholder scan:** No TBD/TODO. Anchor constants are concrete initial values with an explicit Task 5 tuning step (calibration, not a placeholder). ✔

**Type consistency:** `HeadZones.candidates(forTapAt:)` signature identical across Tasks 2 and 3. `MarkCandidate(name:point:)` matches its definition (`BodySceneView.swift:440`). `parentOfHead(_:)`/`muscleHeads` names consistent across Tasks 1 and 4. `showCandidates` still consumes `[MarkCandidate]` + `focused`. ✔
