# 3D Muscle-Tap Marking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 2D region-rect + freehand-ink marking system with tap-based 3D marking: skin-mesh raycast → pure-Swift box resolution → marker dots, per `docs/superpowers/specs/2026-07-15-3d-muscle-tap-marking-design.md`.

**Architecture:** A two-stage tap pipeline — `SCNView.hitTest` finds the surface point on the skin mesh; `MuscleHitResolver` (pure Swift, SIMD) resolves it to a region via point-in-box containment with smallest-volume tiebreak and nearest-center fallback. Marks persist as `[String: BodyMark]` in UserDefaults and render as emissive spheres under the rig. All the old 2D/ink machinery is deleted.

**Tech Stack:** SwiftUI, SceneKit (`UIViewRepresentable`-hosted `SCNView`), simd, Swift Testing (NOT XCTest).

## Global Constraints

- Swift Testing only: `import Testing`, `@Test`, `#expect`, `@testable import BreathRelaxStretch`. Tests dropped into `Breath - Relax & StretchTests/` auto-join the target (file-system-synchronized project — never edit `project.pbxproj`).
- New app source files dropped under `Breath - Relax & Stretch/` auto-join the app target the same way.
- **Anatomical L/R convention** (spec decision): "Left *" = the figure's anatomical left = **positive-x** in normalized model space. The model faces +Z; rotation 0 = front.
- **Coordinate space** for all hit volumes, marks, markers: normalized model space = `rigNode`-local space (pivot = whole-body bbox center, scale = 2.0/height). Never `bodyNode`-local (raw OBJ units).
- Test command: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"` (verify scheme/device once at Task 1; adjust if the scheme list differs).
- Run `graphify update .` after code changes (AST-only, free).
- Commit after every task. Working dir already has unrelated staged-for-nothing changes (StoreKit/Supabase files) — `git add` only the paths each task touches.

---

### Task 1: Anatomical L/R data fix (JSON key swap + pipeline convention flip + bundled resources + convention tests)

**Files:**
- Create: `Tools/blender/swap_lr_keys.py` (one-off, kept for provenance)
- Modify: `Tools/blender/musclegroup_hitboxes.json` (keys swapped in place)
- Modify: `Tools/blender/classify_hitboxes.py` (`app_side_swap` → identity, comment rewritten)
- Create: `Breath - Relax & Stretch/Resources/musclegroup_hitboxes.json` (copy of swapped file)
- Test: `Breath - Relax & StretchTests/HitboxDataTests.swift`

**Interfaces:**
- Produces: bundled resource `musclegroup_hitboxes.json` — dict keyed by `MuscleGroup` raw value → `{min: [x,y,z], max: [x,y,z], source_object_count: n}` with Left = positive-x.

- [ ] **Step 1: Write the failing convention test**

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

struct HitboxDataTests {
    private struct Box: Decodable { let min: [Double]; let max: [Double] }

    private func loadBoxes(_ resource: String) throws -> [String: Box] {
        let url = try #require(Bundle.main.url(forResource: resource, withExtension: "json"))
        return try JSONDecoder().decode([String: Box].self, from: Data(contentsOf: url))
    }

    @Test func muscleBoxCountMatchesMuscleGroupCases() throws {
        let boxes = try loadBoxes("musclegroup_hitboxes")
        #expect(Set(boxes.keys) == Set(MuscleGroup.allCases.map(\.rawValue)))
    }

    /// Anatomical convention: the figure faces +Z, so its anatomical LEFT is
    /// world +x. This shipped inverted once (mirror convention) — pin it.
    @Test func leftBoxesArePositiveX_rightBoxesNegativeX() throws {
        let boxes = try loadBoxes("musclegroup_hitboxes")
        for (name, box) in boxes {
            let centerX = (box.min[0] + box.max[0]) / 2
            if name.hasPrefix("Left ")  { #expect(centerX > 0, "\(name) center x=\(centerX)") }
            if name.hasPrefix("Right ") { #expect(centerX < 0, "\(name) center x=\(centerX)") }
        }
    }

    /// Guards against the whole-body-vs-skin bbox normalization mismatch:
    /// every box must live inside the normalized body envelope.
    @Test func boxUnionFitsNormalizedBody() throws {
        let boxes = try loadBoxes("musclegroup_hitboxes")
        for (name, box) in boxes {
            #expect(box.min[1] >= -1.05 && box.max[1] <= 1.05, "\(name) y out of range")
            #expect(box.min[0] >= -0.9 && box.max[0] <= 0.9, "\(name) x out of range")
            for i in 0..<3 { #expect(box.min[i] < box.max[i], "\(name) degenerate axis \(i)") }
        }
    }
}
```

- [ ] **Step 2: Run the test — expect FAIL** (resource not in bundle yet → `#require` fails; after Step 4's copy but before the swap, the L/R test fails).

- [ ] **Step 3: Write and run the swap script**

`Tools/blender/swap_lr_keys.py`:
```python
#!/usr/bin/env python3
"""One-off: swap 'Left *' <-> 'Right *' keys in musclegroup_hitboxes.json.

The committed JSON followed the app's OLD screen-side ('mirror') convention
(Left = negative-x = viewer's left at front view). The 3D marking redesign
uses anatomical naming: Left = the figure's own left = positive-x.
"""
import json, pathlib

path = pathlib.Path(__file__).parent / "musclegroup_hitboxes.json"
src = json.loads(path.read_text())

def swap(name):
    if name.startswith("Left "):  return "Right " + name[5:]
    if name.startswith("Right "): return "Left " + name[6:]
    return name

out = {swap(k): v for k, v in src.items()}
assert len(out) == len(src)
# sanity: every "Left *" entry must now sit on positive-x
for k, v in out.items():
    cx = (v["min"][0] + v["max"][0]) / 2
    if k.startswith("Left "):  assert cx > 0, (k, cx)
    if k.startswith("Right "): assert cx < 0, (k, cx)
path.write_text(json.dumps(out, indent=2))
print(f"Swapped L/R keys for {len(out)} entries.")
```
Run: `python3 Tools/blender/swap_lr_keys.py` → expect `Swapped L/R keys for 40 entries.`

- [ ] **Step 4: Neutralize `app_side_swap` in `classify_hitboxes.py`** so a future regeneration reproduces the committed convention. Replace the function body and its lead-in comment (lines ~185–203):

```python
# LEFT/RIGHT CONVENTION: Z-Anatomy's ".l"/".r" suffixes are anatomical (the
# model's own left/right) — and since the 3D marking redesign
# (2026-07-15-3d-muscle-tap-marking-design.md) the app uses the SAME
# anatomical convention: "Left Biceps" is the figure's own left arm at every
# camera angle. The old 2D body map used screen-side ("mirror") naming and
# this function used to swap sides to match it; that swap is deliberately
# gone. Do not reintroduce it.
def app_side_swap(group_name: str) -> str:
    return group_name
```

- [ ] **Step 5: Copy the swapped JSON into app resources**

Run: `cp Tools/blender/musclegroup_hitboxes.json "Breath - Relax & Stretch/Resources/musclegroup_hitboxes.json"`

- [ ] **Step 6: Run the tests — expect PASS** (full command in Global Constraints; add `-only-testing:"Breath - Relax & StretchTests/HitboxDataTests"` for speed).

- [ ] **Step 7: Commit** — `git add Tools/blender "Breath - Relax & Stretch/Resources/musclegroup_hitboxes.json" "Breath - Relax & StretchTests/HitboxDataTests.swift"` ; message `feat(bodymap): anatomical L/R hitbox convention + bundled hitbox data`.

---

### Task 2: `HitVolume`, `BodyHitVolumes` loader, `MuscleHitResolver`

**Files:**
- Create: `Breath - Relax & Stretch/Models/BodyHitVolumes.swift`
- Test: `Breath - Relax & StretchTests/MuscleHitResolverTests.swift`

**Interfaces:**
- Produces:
  - `struct HitVolume { let name: String; let minBound: SIMD3<Float>; let maxBound: SIMD3<Float>; var center: SIMD3<Float>; var volume: Float; func contains(_ p: SIMD3<Float>) -> Bool }`
  - `enum BodyHitVolumes { static let all: [HitVolume]; static func load(resource: String, bundle: Bundle = .main) -> [HitVolume] }` — `all` = muscle + joint files (joint file added in Task 3; `load` returns `[]` for a missing resource so Task 2 builds standalone).
  - `enum MuscleHitResolver { static func regionName(at point: SIMD3<Float>, in volumes: [HitVolume]) -> String? }`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
import simd
@testable import BreathRelaxStretch

struct MuscleHitResolverTests {
    private func vol(_ name: String, min: SIMD3<Float>, max: SIMD3<Float>) -> HitVolume {
        HitVolume(name: name, minBound: min, maxBound: max)
    }

    @Test func containmentResolvesToContainingBox() {
        let a = vol("A", min: [0, 0, 0], max: [1, 1, 1])
        let b = vol("B", min: [2, 0, 0], max: [3, 1, 1])
        #expect(MuscleHitResolver.regionName(at: [0.5, 0.5, 0.5], in: [a, b]) == "A")
    }

    @Test func smallestVolumeWinsWhenNested() {
        let muscle = vol("Left Forearm", min: [0, 0, 0], max: [1, 3, 1])
        let joint  = vol("Left Wrist",   min: [0.2, 1.4, 0.2], max: [0.8, 1.6, 0.8])
        #expect(MuscleHitResolver.regionName(at: [0.5, 1.5, 0.5], in: [muscle, joint]) == "Left Wrist")
    }

    @Test func nearestCenterFallbackWhenOutsideEveryBox() {
        let a = vol("A", min: [0, 0, 0], max: [1, 1, 1])       // center (0.5,0.5,0.5)
        let b = vol("B", min: [10, 0, 0], max: [11, 1, 1])     // center (10.5,…)
        #expect(MuscleHitResolver.regionName(at: [2, 0.5, 0.5], in: [a, b]) == "A")
    }

    @Test func emptyVolumesReturnsNil() {
        #expect(MuscleHitResolver.regionName(at: [0, 0, 0], in: []) == nil)
    }

    @Test func bundledMuscleVolumesLoad() {
        let volumes = BodyHitVolumes.load(resource: "musclegroup_hitboxes")
        #expect(volumes.count == 40)
        #expect(volumes.allSatisfy { $0.volume > 0 })
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (`HitVolume` not defined).

- [ ] **Step 3: Implement `Models/BodyHitVolumes.swift`**

```swift
import Foundation
import simd

/// An axis-aligned hit volume in normalized model space (rigNode-local:
/// pivot = whole-body bbox center, scale = 2.0/height — see BodySceneView).
struct HitVolume: Equatable {
    let name: String
    let minBound: SIMD3<Float>
    let maxBound: SIMD3<Float>

    var center: SIMD3<Float> { (minBound + maxBound) / 2 }
    var volume: Float {
        let d = maxBound - minBound
        return d.x * d.y * d.z
    }

    func contains(_ p: SIMD3<Float>) -> Bool {
        p.x >= minBound.x && p.x <= maxBound.x &&
        p.y >= minBound.y && p.y <= maxBound.y &&
        p.z >= minBound.z && p.z <= maxBound.z
    }
}

enum BodyHitVolumes {
    /// All marking hit volumes: 40 muscle groups + hand-placed joints.
    static let all: [HitVolume] =
        load(resource: "musclegroup_hitboxes") + load(resource: "joint_hitboxes")

    private struct BoxEntry: Decodable {
        let min: [Float]
        let max: [Float]
    }

    static func load(resource: String, bundle: Bundle = .main) -> [HitVolume] {
        guard let url = bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([String: BoxEntry].self, from: data)
        else { return [] }
        return entries
            .compactMap { name, box -> HitVolume? in
                guard box.min.count == 3, box.max.count == 3 else { return nil }
                return HitVolume(name: name,
                                 minBound: SIMD3(box.min[0], box.min[1], box.min[2]),
                                 maxBound: SIMD3(box.max[0], box.max[1], box.max[2]))
            }
            .sorted { $0.name < $1.name }
    }
}

/// Resolves a surface point to a region: containment with smallest-volume
/// tiebreak (joint boxes are small, so they beat enclosing muscle boxes),
/// nearest-center fallback for points the muscle layer doesn't reach.
enum MuscleHitResolver {
    static func regionName(at point: SIMD3<Float>, in volumes: [HitVolume]) -> String? {
        let containing = volumes.filter { $0.contains(point) }
        if let best = containing.min(by: { $0.volume < $1.volume }) {
            return best.name
        }
        return volumes.min {
            simd_length_squared(point - $0.center) < simd_length_squared(point - $1.center)
        }?.name
    }
}
```

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit** — `feat(bodymap): hit-volume model + MuscleHitResolver`.

---

### Task 3: Generate `joint_hitboxes.json` + data tests

**Files:**
- Create: `Tools/blender/make_joint_hitboxes.py`
- Create: `Tools/blender/joint_hitboxes.json` + copy to `Breath - Relax & Stretch/Resources/joint_hitboxes.json`
- Test: extend `Breath - Relax & StretchTests/HitboxDataTests.swift`

**Interfaces:**
- Produces: bundled `joint_hitboxes.json` — 8 entries keyed `"Left Elbow"`, `"Right Elbow"`, `"Left Wrist"`, `"Right Wrist"`, `"Left Knee"`, `"Right Knee"`, `"Left Ankle"`, `"Right Ankle"`, same `{min,max}` format/space.

- [ ] **Step 1: Write failing tests** (append to `HitboxDataTests`)

```swift
    @Test func jointBoxesExistWithAnatomicalSides() throws {
        let joints = try loadBoxes("joint_hitboxes")
        let expected = ["Elbow", "Wrist", "Knee", "Ankle"].flatMap { ["Left \($0)", "Right \($0)"] }
        #expect(Set(joints.keys) == Set(expected))
        for (name, box) in joints {
            let centerX = (box.min[0] + box.max[0]) / 2
            if name.hasPrefix("Left ")  { #expect(centerX > 0, "\(name)") }
            if name.hasPrefix("Right ") { #expect(centerX < 0, "\(name)") }
        }
    }

    /// A point at a joint-box center must resolve to the joint, not the
    /// bigger overlapping muscle boxes (smallest-volume tiebreak, real data).
    @Test func jointCentersResolveToJoints() {
        let volumes = BodyHitVolumes.all
        for joint in BodyHitVolumes.load(resource: "joint_hitboxes") {
            #expect(MuscleHitResolver.regionName(at: joint.center, in: volumes) == joint.name)
        }
    }
```

- [ ] **Step 2: Run — expect FAIL** (no joint_hitboxes resource).

- [ ] **Step 3: Write and run the generator**

`Tools/blender/make_joint_hitboxes.py`:
```python
#!/usr/bin/env python3
"""Derive joint hit boxes from adjacent muscle-group boxes.

Each joint straddles the y-gap between its upper and lower neighbor groups;
x/z cover the neighbors' union. Same normalized model space as
musclegroup_hitboxes.json. Verify visually with -debugHitboxes YES.
"""
import json, pathlib

here = pathlib.Path(__file__).parent
src = json.loads((here / "musclegroup_hitboxes.json").read_text())

def joint(uppers, lowers, half_h):
    boxes = [src[n] for n in uppers + lowers]
    u_bottom = min(src[n]["min"][1] for n in uppers)
    l_top    = max(src[n]["max"][1] for n in lowers)
    yc = (u_bottom + l_top) / 2
    return {
        "min": [min(b["min"][0] for b in boxes), yc - half_h, min(b["min"][2] for b in boxes)],
        "max": [max(b["max"][0] for b in boxes), yc + half_h, max(b["max"][2] for b in boxes)],
    }

out = {}
for side in ("Left", "Right"):
    out[f"{side} Elbow"] = joint([f"{side} Biceps", f"{side} Triceps"], [f"{side} Forearm"], 0.035)
    out[f"{side} Wrist"] = joint([f"{side} Forearm"], [f"{side} Hand"], 0.025)
    out[f"{side} Knee"]  = joint([f"{side} Quadriceps", f"{side} Hamstrings"],
                                 [f"{side} Calves", f"{side} Tibialis"], 0.045)
    out[f"{side} Ankle"] = joint([f"{side} Calves", f"{side} Tibialis"], [f"{side} Foot"], 0.030)

(here / "joint_hitboxes.json").write_text(json.dumps(out, indent=2))
print(f"Wrote {len(out)} joint boxes.")
```
Run: `python3 Tools/blender/make_joint_hitboxes.py` then `cp Tools/blender/joint_hitboxes.json "Breath - Relax & Stretch/Resources/joint_hitboxes.json"`.

- [ ] **Step 4: Run tests — expect PASS.** If `jointCentersResolveToJoints` fails because a joint box isn't the smallest at its own center (possible if a muscle box is unexpectedly thin), shrink that joint's x/z to the *lower* neighbor's x/z range in the generator and regenerate — do not special-case the resolver.
- [ ] **Step 5: Commit** — `feat(bodymap): derived joint hit boxes (elbow/wrist/knee/ankle)`.

---

### Task 4: Joint → muscle-group exercise mapping (`oldRegionMap`)

**Files:**
- Modify: `Breath - Relax & Stretch/Models/MuscleGroups.swift` (the `oldRegionMap` literal)
- Test: `Breath - Relax & StretchTests/MuscleGroupJointMappingTests.swift`

**Interfaces:**
- Consumes/Produces: `MuscleGroup.migrate(_:)` (unchanged signature) now expands the 8 joint names.

- [ ] **Step 1: Failing test**

```swift
import Testing
@testable import BreathRelaxStretch

struct MuscleGroupJointMappingTests {
    @Test func jointNamesExpandToAdjacentMuscleGroups() {
        #expect(MuscleGroup.migrate(["Left Elbow"]) == ["Left Biceps", "Left Triceps", "Left Forearm"])
        #expect(MuscleGroup.migrate(["Right Knee"]) == ["Right Quadriceps", "Right Hamstrings", "Right Calves"])
        #expect(MuscleGroup.migrate(["Left Wrist"]) == ["Left Forearm"])
        #expect(MuscleGroup.migrate(["Right Ankle"]) == ["Right Calves", "Right Tibialis", "Right Foot"])
    }

    @Test func everyJointHitboxNameIsMapped() {
        for volume in BodyHitVolumes.load(resource: "joint_hitboxes") {
            #expect(MuscleGroup.oldRegionMap[volume.name] != nil, volume.name)
        }
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (elbow currently maps to `["Left Forearm"]` only; wrist/ankle missing).

- [ ] **Step 3: Edit `oldRegionMap`** — replace the elbow/knee lines and add wrist/ankle:

```swift
        "Left Elbow": ["Left Biceps", "Left Triceps", "Left Forearm"],
        "Right Elbow": ["Right Biceps", "Right Triceps", "Right Forearm"],
        "Left Wrist": ["Left Forearm"], "Right Wrist": ["Right Forearm"],
        "Left Knee": ["Left Quadriceps", "Left Hamstrings", "Left Calves"],
        "Right Knee": ["Right Quadriceps", "Right Hamstrings", "Right Calves"],
        "Left Ankle": ["Left Calves", "Left Tibialis", "Left Foot"],
        "Right Ankle": ["Right Calves", "Right Tibialis", "Right Foot"],
```

- [ ] **Step 4: Run — expect PASS** (also re-run the full suite: `SeedMigratorTests` exercise `migrate` too).
- [ ] **Step 5: Commit** — `feat(bodymap): route joint marks to adjacent muscle groups`.

---

### Task 5: `BodyMark` + `BodyMarkStore`

**Files:**
- Create: `Breath - Relax & Stretch/Models/BodyMarkStore.swift`
- Test: `Breath - Relax & StretchTests/BodyMarkStoreTests.swift`

**Interfaces:**
- Produces:
  - `struct BodyMark: Codable, Equatable { let sensationID: String; let point: SIMD3<Float> }`
  - `final class BodyMarkStore: ObservableObject { @Published private(set) var marks: [String: BodyMark]; init(defaults: UserDefaults = .standard); func toggle(region: String, sensationID: String, point: SIMD3<Float>); func clear(); var markedRegions: Set<String> }`
  - Storage: JSON-encoded under UserDefaults key `bodymap.markedSensations` (net-new key; no migration — old marks were never persisted/displayed).

- [ ] **Step 1: Failing tests**

```swift
import Testing
import simd
@testable import BreathRelaxStretch

struct BodyMarkStoreTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func toggleMarksUpdatesAndUnmarks() {
        let store = BodyMarkStore(defaults: freshDefaults())
        store.toggle(region: "Left Biceps", sensationID: "pain", point: [0.1, 0.3, 0.05])
        #expect(store.marks["Left Biceps"]?.sensationID == "pain")

        // Different sensation selected → recolor, not unmark.
        store.toggle(region: "Left Biceps", sensationID: "tension", point: [0.1, 0.3, 0.05])
        #expect(store.marks["Left Biceps"]?.sensationID == "tension")

        // Same sensation again → unmark.
        store.toggle(region: "Left Biceps", sensationID: "tension", point: [0.1, 0.3, 0.05])
        #expect(store.marks["Left Biceps"] == nil)
    }

    @Test func persistsAcrossInstances() {
        let defaults = freshDefaults()
        BodyMarkStore(defaults: defaults)
            .toggle(region: "Right Knee", sensationID: "pain", point: [-0.1, -0.35, 0.02])
        let reloaded = BodyMarkStore(defaults: defaults)
        #expect(reloaded.marks["Right Knee"]?.point == SIMD3<Float>(-0.1, -0.35, 0.02))
        #expect(reloaded.markedRegions == ["Right Knee"])
    }

    @Test func clearEmptiesStoreAndDisk() {
        let defaults = freshDefaults()
        let store = BodyMarkStore(defaults: defaults)
        store.toggle(region: "Abs", sensationID: "stress", point: [0, 0.1, 0.12])
        store.clear()
        #expect(store.marks.isEmpty)
        #expect(BodyMarkStore(defaults: defaults).marks.isEmpty)
    }
}
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement `Models/BodyMarkStore.swift`**

```swift
import Foundation
import simd

/// One mark per region, facing-independent. `point` is the tapped surface
/// point in normalized model space — where the marker dot renders.
struct BodyMark: Codable, Equatable {
    let sensationID: String
    let point: SIMD3<Float>
}

/// Replaces AnnotationStore. Persists region → mark as JSON in UserDefaults.
/// No migration from the old "bodymap.markedRegions" key: marks were
/// transient before this feature (nothing ever wrote-then-displayed them).
final class BodyMarkStore: ObservableObject {
    static let storageKey = "bodymap.markedSensations"

    @Published private(set) var marks: [String: BodyMark] = [:]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([String: BodyMark].self, from: data) {
            marks = decoded
        }
    }

    var markedRegions: Set<String> { Set(marks.keys) }

    /// Tap semantics: unmarked → mark; marked with another sensation →
    /// recolor; marked with the same sensation → unmark.
    func toggle(region: String, sensationID: String, point: SIMD3<Float>) {
        if marks[region]?.sensationID == sensationID {
            marks[region] = nil
        } else {
            marks[region] = BodyMark(sensationID: sensationID, point: point)
        }
        save()
    }

    func clear() {
        marks = [:]
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(marks) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
```

- [ ] **Step 4: Run — expect PASS.**
- [ ] **Step 5: Commit** — `feat(bodymap): BodyMarkStore with sensation-per-region persistence`.

---

### Task 6: SCNView migration — tap raycast, marker dots, free rotation, debug boxes

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift`

**Interfaces:**
- Consumes: `BodyHitVolumes.all`, `MuscleHitResolver.regionName(at:in:)`, `BodyMark`, `sensationColors`.
- Produces: `BodySceneView(facing:style:marks:onRegionTap:)` where `marks: [String: BodyMark] = [:]`, `onRegionTap: ((String, SIMD3<Float>) -> Void)? = nil`. The `interactive:` parameter, rotation lock, and `resetCamera` calibration path are **deleted** (rotation is always free; `defaultCameraDistance` stays only as the camera's base distance). `BodyRig` gains `marksNode` and `updateMarks(_:)`.

No unit test cycle here (SceneKit view plumbing); verified by Task 8's debug visualization + the `verify` skill. Keep the build green.

- [ ] **Step 1: `BodyRig` additions** — in `init`, after `scene.rootNode.addChildNode(rigNode)`, add `rigNode.addChildNode(marksNode)`; add:

```swift
    /// Marker dots live under the rig (NOT bodyNode: bodyNode's children
    /// inherit its raw-OBJ pivot/scale; rigNode children take normalized-space
    /// coordinates directly and still rotate with the body).
    let marksNode = SCNNode()

    func updateMarks(_ marks: [String: BodyMark]) {
        marksNode.childNodes.forEach { $0.removeFromParentNode() }
        for (region, mark) in marks {
            let sphere = SCNSphere(radius: 0.028)
            let color = UIColor(sensationColors.first { $0.id == mark.sensationID }?.color ?? .red)
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.emission.contents = color
            sphere.materials = [material]
            let node = SCNNode(geometry: sphere)
            node.name = region
            node.position = SCNVector3(mark.point.x, mark.point.y, mark.point.z)
            marksNode.addChildNode(node)
        }
    }

    /// Debug: launch with `-debugHitboxes YES` to render every hit volume as
    /// a translucent box over the skin — verifies box↔mesh alignment and the
    /// anatomical L/R relabel (at front view, "Left Biceps" must sit on the
    /// VIEWER'S RIGHT).
    func addDebugHitboxesIfEnabled() {
        guard UserDefaults.standard.bool(forKey: "debugHitboxes") else { return }
        for volume in BodyHitVolumes.all {
            let size = volume.maxBound - volume.minBound
            let box = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y),
                             length: CGFloat(size.z), chamferRadius: 0)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.18)
            material.isDoubleSided = true
            box.materials = [material]
            let node = SCNNode(geometry: box)
            node.name = volume.name
            node.position = SCNVector3(volume.center.x, volume.center.y, volume.center.z)
            rigNode.addChildNode(node)
        }
    }
```

Call `rig.addDebugHitboxesIfEnabled()` from `BodySceneView`'s `.task` after `loadIfNeeded()`.

- [ ] **Step 2: Replace `SceneView` with a representable.** Add to the file:

```swift
/// SwiftUI's SceneView hides its SCNView, which we need for hitTest — so the
/// scene is hosted directly. SwiftUI drag/magnify gestures still attach on
/// top; the tap recognizer fails automatically once a pan starts.
private struct SceneKitContainer: UIViewRepresentable {
    let scene: SCNScene
    let pointOfView: SCNNode
    var onTap: ((CGPoint, SCNView) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.pointOfView = pointOfView
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    final class Coordinator: NSObject {
        var onTap: ((CGPoint, SCNView) -> Void)?
        init(onTap: ((CGPoint, SCNView) -> Void)?) { self.onTap = onTap }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? SCNView else { return }
            onTap?(recognizer.location(in: view), view)
        }
    }
}
```

- [ ] **Step 3: Rework `BodySceneView`:**
  - New stored properties: `var marks: [String: BodyMark] = [:]`, `var onRegionTap: ((String, SIMD3<Float>) -> Void)? = nil`. Delete `interactive` (and its init param, the `guard interactive` lines in both gestures, the `onChange(of: interactive)` block, `resetCamera()`, and the marking-related doc comments). Camera starts at `BodyRig.freeExploreCameraDistance` unconditionally; the "Drag to rotate" overlay shows unconditionally.
  - Replace the `SceneView(...)` line with:

```swift
                SceneKitContainer(scene: rig.scene, pointOfView: rig.cameraNode,
                                  onTap: onRegionTap == nil ? nil : handleTap)
                    .gesture(rotationGesture)
                    .simultaneousGesture(zoomGesture)
```

  - Add the tap handler + mark syncing:

```swift
    /// Stage 1: raycast the skin mesh (only body geometry in the scene —
    /// marker dots are excluded explicitly). Stage 2: convert the world hit
    /// point to rigNode-local (normalized model space, rotation factored
    /// out) and resolve it with pure math.
    private func handleTap(at point: CGPoint, in view: SCNView) {
        guard let onRegionTap else { return }
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue as NSNumber])
        guard let hit = hits.first(where: { !isMarkerNode($0.node) }) else { return }
        let local = rig.rigNode.convertPosition(hit.worldCoordinates, from: nil)
        let normalized = SIMD3(Float(local.x), Float(local.y), Float(local.z))
        if let region = MuscleHitResolver.regionName(at: normalized, in: BodyHitVolumes.all) {
            onRegionTap(region, normalized)
        }
    }

    private func isMarkerNode(_ node: SCNNode) -> Bool {
        sequence(first: node, next: \.parent).contains(rig.marksNode)
    }
```

  - Sync dots: on the outer `ZStack` add `.onChange(of: marks) { _, new in rig.updateMarks(new) }`, and call `rig.updateMarks(marks)` right after `await rig.loadIfNeeded()` in the `.task` (so persisted marks appear on first load), followed by `rig.addDebugHitboxesIfEnabled()`.
  - Fix the `#Preview` (drop `interactive`), and fix the one call site in `BodyMapView` temporarily (`BodySceneView(facing: facing, style: .skin)` still compiles — the `interactive: false` call site disappears in Task 7; if the build breaks in between, adjust the call site minimally).

- [ ] **Step 4: Build** — `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'` → expect BUILD SUCCEEDED. Run full unit suite → PASS.
- [ ] **Step 5: Commit** — `feat(bodymap): SCNView tap raycast, marker dots, free rotation while marking`.

---### Task 7: BodyMapView rewrite — tap-first marking UI

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift` (full rewrite of the view internals)
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyAnnotationOverlay.swift` → shrink to sensations + legend (Task 8 renames it)

**Interfaces:**
- Consumes: `BodyMarkStore`, `BodySceneView(facing:style:marks:onRegionTap:)`, `MarkedAreasBanner`, `sensationColors`, `LegendSheet`.
- Produces: the user flow — Mark button toggles marking; sensation palette shows while marking; taps mark/recolor/unmark; banner + Find Exercises reads `markStore.markedRegions`.

- [ ] **Step 1: Rewrite `BodyMapView`** (replacing zoom/pan state, annotation state, and the two-mode figure block):

```swift
import SwiftUI
import SwiftData

struct BodyMapView: View {
    @State private var facing: BodyFacing = .front
    @State private var isMarking = UserDefaults.standard.bool(forKey: "debugMarkMode")
    @StateObject private var markStore = BodyMarkStore()
    @State private var selectedSensation: SensationColor = sensationColors[0]
    @State private var showMarkedExercises = false
    @State private var showLegend = false

    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Top bar ──
                HStack(spacing: 8) {
                    if isMarking {
                        Text("Tap a muscle to mark it — tap again to remove.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button { showLegend = true } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("Colour guide")
                        Button(role: .destructive) {
                            withAnimation { markStore.clear() }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 36)
                        }
                        .disabled(markStore.marks.isEmpty)
                        .accessibilityLabel("Clear all marks")
                    } else {
                        Spacer(minLength: 0)
                        facingToggleButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // ── The body — one freely-rotatable 3D view in both modes ──
                BodySceneView(facing: facing,
                              style: .skin,
                              marks: markStore.marks,
                              onRegionTap: isMarking ? handleRegionTap : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Bottom bar ──
                if isMarking {
                    sensationPalette
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                } else if !markStore.marks.isEmpty {
                    MarkedAreasBanner(
                        regionNames: markStore.markedRegions.sorted(),
                        onFind:  { showMarkedExercises = true },
                        onClear: { withAnimation { markStore.clear() } }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .floatingTabBarClearance()
            .navigationTitle(isMarking ? "Mark Areas" : "Body Map")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.2), value: markStore.marks.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: isMarking)
            .navigationDestination(isPresented: $showMarkedExercises) {
                BodyPartExercisesView(bodyParts: markStore.markedRegions.sorted())
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isMarking.toggle() }
                    } label: {
                        Label(isMarking ? "Done" : "Mark",
                              systemImage: isMarking ? "checkmark.circle.fill" : "hand.point.up.left.fill")
                    }
                    .accessibilityLabel(isMarking ? "Finish marking" : "Mark areas by tapping")
                }
            }
            .sheet(isPresented: $showLegend) { LegendSheet() }
            .onAppear { impact.prepare() }
        }
    }

    private func handleRegionTap(region: String, point: SIMD3<Float>) {
        withAnimation(.easeInOut(duration: 0.18)) {
            markStore.toggle(region: region, sensationID: selectedSensation.id, point: point)
        }
        impact.impactOccurred()
    }

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

    private var sensationPalette: some View {
        HStack(spacing: 0) {
            ForEach(sensationColors) { sc in
                Button { selectedSensation = sc } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(sc.color).frame(width: 30, height: 30)
                            if selectedSensation.id == sc.id {
                                Circle().strokeBorder(.white, lineWidth: 2.5)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        Text(sc.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(selectedSensation.id == sc.id ? sc.color : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("\(sc.label) colour")
            }
        }
    }
}

#Preview {
    BodyMapView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
```

Notes: facing toggle is hidden while marking (rotation is free — drag instead), matching the spec's "marking unlocks free rotation". The `debugMarkMode` launch arg now seeds `isMarking` (keeps the XCUITest state-injection recipe working).

- [ ] **Step 2: Build + full unit suite** → expect BUILD SUCCEEDED / tests PASS.
- [ ] **Step 3: Commit** — `feat(bodymap): tap-first 3D marking UI replaces draw mode`.

---

### Task 8: Delete the old system

**Files:**
- Delete: `Breath - Relax & Stretch/Views/BodyMap/BodyFigureCanvas.swift`
- Delete: `Breath - Relax & Stretch/Views/BodyMap/BodyMapLaunchState.swift`
- Delete: `Breath - Relax & StretchTests/BodyMapLaunchStateTests.swift`
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyAnnotationOverlay.swift` → rename to `Sensations.swift`: keep `SensationColor`, `sensationColors`, `LegendSheet` (drop its "Tools" section and `DrawingTool` descriptions; reword the footer to "Your marks are saved automatically…"); delete `DrawingTool`, `AnnotationStroke`, `AnnotationStore`, `Path.smooth`, `BodyAnnotationOverlay` view + preview.
- Modify: `Breath - Relax & Stretch/Views/BodyMap/HumanFigureView.swift`: delete `BodyRegion`, `frontRegions`, `backRegions`, `handFingerRegions`, `toeRegions`, `faceFrontFineRegions`, `bodyRegions(for:detail:)`, `allRegions(for:)`, `BodyDetail`. Keep `BodyFacing` and the silhouette shapes (`GenderPickerPage` uses `MaleSilhouetteShape`/`FemaleSilhouetteShape`). Delete `FacialFeaturesCanvas`/`BodyDetailCanvas` and `AnatomyDrawingHelpers.swift` ONLY if `grep -rn` shows no remaining references outside the deleted files.
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift`: delete `fingerNames` + `exerciseSearchTerms` (finger granularity is dropped); in `RegionExerciseResolver.init`, replace `let expanded = regions.flatMap { exerciseSearchTerms(for: $0) }` with `MuscleGroup.migrate(regions)` directly.

- [ ] **Step 1: Delete/trim per the list.** After each file, `grep -rn "<deleted symbol>" "Breath - Relax & Stretch" "Breath - Relax & StretchTests"` to catch stragglers (expected referrers were all inside the deleted files; `SeedMigrator` uses `MuscleGroup.migrate`, which stays).
- [ ] **Step 2: Build + full unit suite** → PASS (fix any missed references — e.g. tests that imported deleted types).
- [ ] **Step 3: Run `graphify update .`**
- [ ] **Step 4: Commit** — `refactor(bodymap): remove 2D region overlay + freehand drawing system`.

---

### Task 9: Verification — debug boxes, simulator pass, full suite

- [ ] **Step 1: Debug visualization (spec's one-time alignment check).** Per the `verify` skill (`.claude/skills/verify/SKILL.md`), build & launch in the simulator with launch args `-debugHitboxes YES`, screenshot front view and back view (rotate via drag or facing toggle). Confirm: boxes hug the figure (no gross vertical offset — watch the feet: JSON bottoms at y≈−0.913 vs mesh −1.0), and at **front view the box labeled "Left Biceps" is on the viewer's RIGHT**. If a material vertical offset shows, fix `Tools/blender/extract_hitboxes.py` to normalize against the skin mesh's bbox and regenerate — never a runtime fudge factor.
- [ ] **Step 2: Manual marking pass (verify skill).** Launch with `-debugMarkMode YES`: tap the figure's left bicep → chip/banner shows "Left Biceps"; rotate ~90° and tap a thigh → correct side quad marks; flip to back and tap between the shoulder blades → a back muscle (traps/spinal erectors), not "Chest"; tap a marked region with the same sensation → dot disappears; drag-rotate does NOT drop a mark. Screenshot each.
- [ ] **Step 3: Full unit suite one last time** → all PASS.
- [ ] **Step 4: `graphify update .`; commit any fixes** — `test(bodymap): simulator verification fixes`.
