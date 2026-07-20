# Anatomy Logic Layer Implementation Plan (Plan 2 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the decoupled Swift "brain" for the single-anatomy Body Map — the 15-region `JointRegion` vocabulary and an anatomical `RegionAdjacency` map that replaces `MuscleHitResolver.candidates()`' 3D-distance radius (fixing the arm↔torso candidate bleed) — all pure logic, unit-tested with synthetic hit volumes, no assets or rendering touched.

**Architecture:** Two new value-only files (`Models/JointRegion.swift`, `Models/RegionAdjacency.swift`) plus a rewrite of the `candidates(near:in:)` method inside the existing `Models/BodyHitVolumes.swift`. `RegionAdjacency` authors each adjacency edge ONCE and symmetrizes at load, so the map is symmetric by construction. `candidates()` resolves the primary region by containment (unchanged), then draws neighbors from the adjacency map (plus the primary group's own sub-heads), filtered to those whose hit volume is actually near the tap, capped at `maxCandidates`. Because `candidates()` takes its `[HitVolume]` as a parameter, every test builds its own synthetic volumes — zero dependency on bundled assets, `BodySceneView`, or the Plan 1 export.

**Tech Stack:** Swift, simd, Swift Testing (`import Testing`, `@Test`, `#expect`), module `BreathRelaxStretch`.

## Global Constraints

- **Test framework:** Swift Testing only (never XCTest). Module `BreathRelaxStretch`.
- **Test command:** `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- **Pre-existing known-failing tests:** the 4 `CuratedContentIntegrityTests` fail on `main` for unrelated content-drift reasons; they are NOT a regression gate for this work. Every OTHER test must stay green.
- **15 joint regions (JointRegion):** midline `Neck`, `Upper Spine`, `Lower Spine`; bilateral `Left/Right Shoulder Joint`, `Left/Right Elbow`, `Left/Right Wrist`, `Left/Right Hip`, `Left/Right Knee`, `Left/Right Ankle`. These names must NOT collide with any `MuscleGroup` raw value (note `Shoulder Joint`, since `Left/Right Shoulder` is the deltoid group).
- **Anatomical L/R convention:** Left = the figure's own left = world +x. Region names carry the `Left `/`Right ` prefix; midline regions have none.
- **Adjacency is symmetric:** if A is adjacent to B then B is adjacent to A. Authored once as directed edges, symmetrized at build — a test pins symmetry.
- **This plan touches NO assets and NO rendering.** Do not move files into `Resources/`, do not edit `BodySceneView.swift`/`BodyMapView.swift`, do not delete `BodyMale.obj`/`BodyMuscle.obj`. Those are Plan 3.
- **`candidates()` stays pose-independent** and keeps its existing signature shape `candidates(near:in:radiusFactor:maxCandidates:) -> [String]`, primary-first ordering, and `[]` on empty input.

---

### Task 1: `JointRegion` vocabulary

**Files:**
- Create: `Breath - Relax & Stretch/Models/JointRegion.swift`
- Test: `Breath - Relax & StretchTests/JointRegionTests.swift`

**Interfaces:**
- Produces:
  - `enum JointRegion: String, CaseIterable` with 15 cases; raw values are the region names.
  - `static var allNames: Set<String>` — the 15 raw values.
  - `static func isJoint(_ name: String) -> Bool`.

- [ ] **Step 1: Write the failing test** — `JointRegionTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct JointRegionTests {
    @Test func hasExactlyFifteenRegions() {
        #expect(JointRegion.allCases.count == 15)
    }

    @Test func containsTheExpectedNames() {
        let expected: Set<String> = [
            "Neck", "Upper Spine", "Lower Spine",
            "Left Shoulder Joint", "Right Shoulder Joint",
            "Left Elbow", "Right Elbow", "Left Wrist", "Right Wrist",
            "Left Hip", "Right Hip", "Left Knee", "Right Knee",
            "Left Ankle", "Right Ankle",
        ]
        #expect(JointRegion.allNames == expected)
    }

    @Test func doesNotCollideWithMuscleGroups() {
        let groups = Set(MuscleGroup.allCases.map(\.rawValue))
        #expect(JointRegion.allNames.isDisjoint(with: groups))
    }

    @Test func isJointRecognizesMembersAndRejectsOthers() {
        #expect(JointRegion.isJoint("Left Elbow"))
        #expect(JointRegion.isJoint("Neck"))
        #expect(!JointRegion.isJoint("Left Biceps"))
        #expect(!JointRegion.isJoint("Nonsense"))
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run the test command with `-only-testing:"Breath - Relax & StretchTests/JointRegionTests"`.
Expected: FAILS to compile — `cannot find 'JointRegion' in scope`.

- [ ] **Step 3: Create `JointRegion.swift`:**

```swift
import Foundation

/// The kept, stretchable joint regions the Body Map resolves as tappable areas
/// (distinct from `MuscleGroup` — joints carry their own hit volumes and, until
/// dedicated joint-mobility content lands, resolve to their crossing muscles'
/// stretches). Names are chosen NOT to collide with any `MuscleGroup` raw value
/// (hence `Shoulder Joint`, since `Left/Right Shoulder` is the deltoid group).
/// Left = the figure's own left = world +x.
enum JointRegion: String, CaseIterable {
    case neck = "Neck"
    case upperSpine = "Upper Spine"
    case lowerSpine = "Lower Spine"
    case leftShoulder = "Left Shoulder Joint",   rightShoulder = "Right Shoulder Joint"
    case leftElbow = "Left Elbow",               rightElbow = "Right Elbow"
    case leftWrist = "Left Wrist",               rightWrist = "Right Wrist"
    case leftHip = "Left Hip",                   rightHip = "Right Hip"
    case leftKnee = "Left Knee",                 rightKnee = "Right Knee"
    case leftAnkle = "Left Ankle",               rightAnkle = "Right Ankle"

    /// The 15 region names.
    static let allNames: Set<String> = Set(allCases.map(\.rawValue))

    /// Whether `name` is one of the joint regions.
    static func isJoint(_ name: String) -> Bool { allNames.contains(name) }
}
```

- [ ] **Step 4: Run to verify it passes**

Run the test command with `-only-testing:"Breath - Relax & StretchTests/JointRegionTests"`.
Expected: 4/4 pass.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/JointRegion.swift" "Breath - Relax & StretchTests/JointRegionTests.swift"
git commit -m "feat(bodymap): add JointRegion vocabulary (15 stretchable joint regions)"
```

---

### Task 2: `RegionAdjacency` map

**Files:**
- Create: `Breath - Relax & Stretch/Models/RegionAdjacency.swift`
- Test: `Breath - Relax & StretchTests/RegionAdjacencyTests.swift`

**Interfaces:**
- Consumes: `JointRegion` (Task 1), `MuscleGroup` (existing).
- Produces:
  - `enum RegionAdjacency` with `static func adjacent(to region: String) -> Set<String>`.
  - `static let neighbors: [String: Set<String>]` — the built, symmetric adjacency (exposed for tests).

**Design:** author each edge ONCE as a directed list; `neighbors` is built by symmetrizing (for every `a → b`, add `b → a`). This makes the map symmetric by construction — impossible to author an asymmetric map. Adjacency lists cross-region neighbors (other muscle groups + joints); a group's own sub-heads are NOT listed here (Task 3's `candidates()` derives those from `MuscleGroup.muscleHeads`). Face zones (`Head`) are handled by `HeadZones`, not adjacency, so `Head` is intentionally absent.

- [ ] **Step 1: Write the failing test** — `RegionAdjacencyTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct RegionAdjacencyTests {
    @Test func adjacencyIsSymmetric() {
        for (region, neighbors) in RegionAdjacency.neighbors {
            for n in neighbors {
                #expect(RegionAdjacency.adjacent(to: n).contains(region),
                        "\(region)→\(n) not mirrored by \(n)→\(region)")
            }
        }
    }

    @Test func everyMuscleGroupAndJointHasNeighbors() {
        // Head is handled by HeadZones, not adjacency — exclude it.
        for g in MuscleGroup.allCases where g != .head {
            #expect(!RegionAdjacency.adjacent(to: g.rawValue).isEmpty, "\(g.rawValue) has no neighbors")
        }
        for name in JointRegion.allNames {
            #expect(!RegionAdjacency.adjacent(to: name).isEmpty, "\(name) has no neighbors")
        }
    }

    @Test func everyNeighborNameIsARealRegion() {
        let valid = Set(MuscleGroup.allCases.map(\.rawValue)).union(JointRegion.allNames)
        for (region, neighbors) in RegionAdjacency.neighbors {
            #expect(valid.contains(region), "unknown key \(region)")
            for n in neighbors { #expect(valid.contains(n), "\(region)→ unknown \(n)") }
        }
    }

    @Test func chestIsNotAdjacentToForearmOrHand() {
        let chest = RegionAdjacency.adjacent(to: "Left Chest")
        #expect(!chest.contains("Left Forearm"))
        #expect(!chest.contains("Left Hand"))
    }

    @Test func elbowCrossesBicepsTricepsForearm() {
        let elbow = RegionAdjacency.adjacent(to: "Left Elbow")
        #expect(elbow.isSuperset(of: ["Left Biceps", "Left Triceps", "Left Forearm"]))
    }

    @Test func adjacencyStaysOnOneSide() {
        // A left-arm region should not list a right-arm region.
        #expect(!RegionAdjacency.adjacent(to: "Left Biceps").contains { $0.hasPrefix("Right ") && $0.contains("Biceps") })
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run with `-only-testing:"Breath - Relax & StretchTests/RegionAdjacencyTests"`.
Expected: FAILS to compile — `cannot find 'RegionAdjacency' in scope`.

- [ ] **Step 3: Create `RegionAdjacency.swift`:**

```swift
import Foundation

/// Hand-authored anatomical adjacency: which regions may legitimately appear
/// together as disambiguation candidates. Replaces the old 3D-distance radius,
/// which surfaced arm muscles for a chest/leg tap because the arms hang close
/// to the torso in the anatomical pose. Authored as directed edges and
/// symmetrized at build, so the relation is symmetric by construction.
///
/// Lists cross-region neighbors only (muscle groups + joints). A muscle group's
/// own sub-heads are added separately by `MuscleHitResolver.candidates()` (from
/// `MuscleGroup.muscleHeads`), so they are intentionally absent here. `Head`
/// disambiguation is owned by `HeadZones`, so `Head` is absent too.
enum RegionAdjacency {
    /// Directed edges, authored once per pair. Bilateral limbs list `L`; the
    /// build mirrors each to the matching `R` region automatically.
    private static let authored: [String: [String]] = {
        var e: [String: [String]] = [
            // ── Axial / torso (midline + both-sides) ──
            "Front Neck": ["Back Neck", "Neck"],
            "Back Neck": ["Spinal Erectors", "Neck"],
            "Spinal Erectors": ["Lower Back", "Upper Spine", "Lower Spine", "Neck"],
            "Lower Back": ["Lower Spine"],
            "Abs": ["Left Obliques", "Right Obliques", "Left Chest", "Right Chest",
                    "Left Hip Flexors", "Right Hip Flexors"],
            "Neck": ["Upper Spine", "Left Trapezius", "Right Trapezius"],
            "Upper Spine": ["Lower Spine", "Left Trapezius", "Right Trapezius",
                            "Left Lats", "Right Lats"],
            "Lower Spine": ["Left Glutes", "Right Glutes"],
        ]
        // ── Per-side chains (authored for Left; mirrored to Right at build) ──
        let leftEdges: [String: [String]] = [
            "Left Trapezius": ["Left Shoulder", "Back Neck", "Front Neck", "Spinal Erectors", "Neck"],
            "Left Shoulder": ["Left Trapezius", "Left Chest", "Left Biceps", "Left Triceps",
                              "Left Lats", "Left Shoulder Joint"],
            "Left Chest": ["Left Obliques", "Left Shoulder", "Left Shoulder Joint"],
            "Left Obliques": ["Left Chest", "Left Lats", "Lower Back", "Left Hip Flexors"],
            "Left Lats": ["Left Obliques", "Spinal Erectors", "Left Shoulder", "Left Trapezius", "Lower Back"],
            "Left Biceps": ["Left Triceps", "Left Shoulder", "Left Forearm", "Left Elbow", "Left Shoulder Joint"],
            "Left Triceps": ["Left Biceps", "Left Shoulder", "Left Forearm", "Left Elbow", "Left Shoulder Joint"],
            "Left Forearm": ["Left Hand", "Left Elbow", "Left Wrist"],
            "Left Hand": ["Left Wrist"],
            "Left Glutes": ["Lower Back", "Left Hip Flexors", "Left Hamstrings", "Left Adductors", "Left Hip"],
            "Left Hip Flexors": ["Left Adductors", "Left Quadriceps", "Left Glutes", "Left Hip", "Lower Back"],
            "Left Adductors": ["Left Quadriceps", "Left Hamstrings", "Left Glutes", "Left Hip"],
            "Left Quadriceps": ["Left Adductors", "Left Hamstrings", "Left Knee", "Left Hip"],
            "Left Hamstrings": ["Left Glutes", "Left Adductors", "Left Quadriceps", "Left Calves", "Left Knee", "Left Hip"],
            "Left Calves": ["Left Tibialis", "Left Foot", "Left Knee", "Left Ankle"],
            "Left Tibialis": ["Left Foot", "Left Knee", "Left Ankle"],
            "Left Foot": ["Left Ankle"],
            // joints → their crossing muscles
            "Left Shoulder Joint": ["Left Shoulder", "Left Chest", "Left Trapezius"],
            "Left Elbow": ["Left Biceps", "Left Triceps", "Left Forearm"],
            "Left Wrist": ["Left Forearm", "Left Hand"],
            "Left Hip": ["Left Glutes", "Left Hip Flexors", "Left Adductors", "Left Quadriceps", "Left Hamstrings", "Lower Back"],
            "Left Knee": ["Left Quadriceps", "Left Hamstrings", "Left Calves", "Left Tibialis"],
            "Left Ankle": ["Left Calves", "Left Tibialis", "Left Foot"],
        ]
        for (k, v) in leftEdges {
            e[k] = v
            // Mirror Left → Right by swapping the side prefix on the key and each
            // neighbor that carries a side. Midline neighbors (Abs, Lower Back,
            // Spinal Erectors, Neck, Upper/Lower Spine) pass through unchanged.
            e[mirror(k)] = v.map(mirror)
        }
        return e
    }()

    /// Swap a `Left `/`Right ` prefix; leave midline names unchanged.
    private static func mirror(_ name: String) -> String {
        if name.hasPrefix("Left ")  { return "Right " + name.dropFirst(5) }
        if name.hasPrefix("Right ") { return "Left "  + name.dropFirst(6) }
        return name
    }

    /// Symmetric adjacency: every authored edge plus its reverse.
    static let neighbors: [String: Set<String>] = {
        var m: [String: Set<String>] = [:]
        for (region, list) in authored {
            for n in list {
                m[region, default: []].insert(n)
                m[n, default: []].insert(region)   // symmetrize
            }
        }
        return m
    }()

    /// The regions anatomically adjacent to `region` (empty if none authored).
    static func adjacent(to region: String) -> Set<String> { neighbors[region] ?? [] }
}
```

- [ ] **Step 4: Run to verify it passes**

Run with `-only-testing:"Breath - Relax & StretchTests/RegionAdjacencyTests"`.
Expected: 6/6 pass. (If `everyMuscleGroupAndJointHasNeighbors` fails for a region, add an edge for it in `authored`/`leftEdges` and re-run — every non-`Head` group and every joint must appear.)

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/RegionAdjacency.swift" "Breath - Relax & StretchTests/RegionAdjacencyTests.swift"
git commit -m "feat(bodymap): add symmetric anatomical RegionAdjacency map"
```

---

### Task 3: rewrite `MuscleHitResolver.candidates()` to use adjacency

**Files:**
- Modify: `Breath - Relax & Stretch/Models/BodyHitVolumes.swift` (`candidates(near:in:radiusFactor:maxCandidates:)` only — leave `regionName`/`primaryVolume`/`HitVolume` unchanged)
- Modify: `Breath - Relax & StretchTests/MuscleHitResolverTests.swift` (replace the 3 distance-radius candidate tests with adjacency tests; keep the `regionName` tests and `candidatesOnEmptyVolumesReturnsEmpty`)

**Interfaces:**
- Consumes: `RegionAdjacency.adjacent(to:)` (Task 2), `MuscleGroup.muscleHeads` / `parentOfHead` (existing), `primaryVolume(at:in:)` (existing).
- Produces: same signature `candidates(near:in:radiusFactor:maxCandidates:) -> [String]`, primary-first.

**Behavior:** resolve `primary` (unchanged `primaryVolume`). Compute `primaryKey = MuscleGroup.parentOfHead(primary.name) ?? primary.name` (a head's group, else the region itself). Candidate name pool = the primary's sub-heads (from `MuscleGroup.muscleHeads` where value == `primaryKey`) ∪ `RegionAdjacency.adjacent(to: primaryKey)`. Keep only pool names that (a) have a volume in `volumes` and (b) whose volume center is within `radius = primaryDiagonal * radiusFactor` of the tap (the light sanity check). Order the survivors by distance to the tap, prepend `primary.name`, dedup, cap at `maxCandidates`.

- [ ] **Step 1: Replace the candidate tests** in `MuscleHitResolverTests.swift` — delete `candidatesReturnsOnlyPrimaryWhenNoNeighborsNearby`, `candidatesIncludesNeighborsWithinRadiusOfPrimary`, and `candidatesCapsToMaxCandidatesClosestFirst`; keep everything else (the `regionName` tests, `bundledMuscleVolumesLoad`, `candidatesOnEmptyVolumesReturnsEmpty`). Add:

```swift
    // MARK: - candidates(near:in:) — anatomical adjacency

    /// Boxes laid out so a chest tap sits with a forearm box nearby (the pose
    /// bleed the old radius suffered) — adjacency must still exclude the forearm.
    @Test func chestTapExcludesNonAdjacentForearm() {
        let chest = vol("Left Chest",   min: [0.05, 0.3, 0.0], max: [0.35, 0.6, 0.25])
        let abs   = vol("Abs",          min: [-0.1, 0.1, 0.0], max: [0.1, 0.35, 0.2])   // adjacent
        let fore  = vol("Left Forearm", min: [0.30, 0.2, 0.0], max: [0.45, 0.5, 0.2])   // near but NOT adjacent
        let tapCenter = chest.center
        let result = MuscleHitResolver.candidates(near: tapCenter, in: [chest, abs, fore], maxCandidates: 4)
        #expect(result.first == "Left Chest")
        #expect(result.contains("Abs"))
        #expect(!result.contains("Left Forearm"))
    }

    @Test func elbowTapReturnsJointPlusCrossingMuscles() {
        // Elbow box is smallest, so it wins the primary tiebreak; its adjacency
        // is biceps/triceps/forearm.
        let biceps = vol("Left Biceps",  min: [0.1, 0.3, -0.1], max: [0.3, 0.6, 0.1])
        let triceps = vol("Left Triceps", min: [0.1, 0.3, -0.1], max: [0.3, 0.6, 0.1])
        let forearm = vol("Left Forearm", min: [0.1, 0.0, -0.1], max: [0.3, 0.3, 0.1])
        let elbow = vol("Left Elbow", min: [0.17, 0.28, -0.03], max: [0.23, 0.34, 0.03])
        let result = MuscleHitResolver.candidates(near: elbow.center,
                                                  in: [biceps, triceps, forearm, elbow], maxCandidates: 4)
        #expect(result.first == "Left Elbow")
        #expect(Set(result) == ["Left Elbow", "Left Biceps", "Left Triceps", "Left Forearm"])
    }

    @Test func primaryGroupSurfacesItsOwnSubHeads() {
        // A tap resolving to the Left Biceps group should offer its heads.
        let biceps = vol("Left Biceps", min: [0.1, 0.2, -0.1], max: [0.35, 0.6, 0.1])
        let longHead  = vol("Left Biceps Long Head",  min: [0.1, 0.2, -0.1], max: [0.22, 0.6, 0.1])
        let shortHead = vol("Left Biceps Short Head", min: [0.22, 0.2, -0.1], max: [0.35, 0.6, 0.1])
        let result = MuscleHitResolver.candidates(near: biceps.center,
                                                  in: [biceps, longHead, shortHead], maxCandidates: 4)
        #expect(result.contains("Left Biceps Long Head") || result.contains("Left Biceps Short Head"))
    }

    @Test func candidatesCapAtMaxClosestFirst() {
        let chest = vol("Left Chest", min: [0.05, 0.3, 0.0], max: [0.35, 0.6, 0.25])
        let abs   = vol("Abs",           min: [0.0, 0.28, 0.0], max: [0.1, 0.4, 0.2])   // closest neighbor
        let obl   = vol("Left Obliques", min: [0.0, 0.1, 0.0], max: [0.2, 0.3, 0.2])
        let sh    = vol("Left Shoulder", min: [0.2, 0.55, 0.0], max: [0.4, 0.75, 0.2])
        let result = MuscleHitResolver.candidates(near: chest.center,
                                                  in: [chest, abs, obl, sh], maxCandidates: 2)
        #expect(result.count == 2)
        #expect(result.first == "Left Chest")
    }
```

- [ ] **Step 2: Run to verify the new tests fail** (old `candidates()` still distance-based)

Run with `-only-testing:"Breath - Relax & StretchTests/MuscleHitResolverTests"`.
Expected: `elbowTapReturnsJointPlusCrossingMuscles` and `chestTapExcludesNonAdjacentForearm` FAIL (old radius surfaces the near forearm / doesn't scope to adjacency).

- [ ] **Step 3: Rewrite `candidates()`** in `BodyHitVolumes.swift`. Replace the body of `candidates(near:in:radiusFactor:maxCandidates:)` with:

```swift
    static func candidates(near point: SIMD3<Float>,
                            in volumes: [HitVolume],
                            radiusFactor: Float = 1.5,
                            maxCandidates: Int = 4) -> [String] {
        guard let primary = primaryVolume(at: point, in: volumes) else { return [] }
        // The group/joint key for the primary: a head resolves via its parent
        // group, everything else is its own key.
        let primaryKey = MuscleGroup.parentOfHead(primary.name) ?? primary.name

        // Candidate pool: the primary group's own sub-heads (so a group tap
        // offers its heads) plus its anatomical neighbors (groups + joints).
        var pool = Set(RegionAdjacency.adjacent(to: primaryKey))
        for (head, group) in MuscleGroup.muscleHeads where group == primaryKey {
            pool.insert(head)
        }
        pool.remove(primary.name)

        // Light sanity check: keep only pooled regions with a loaded volume whose
        // center is near the tap — adjacency is the selector, distance just
        // guards against an anatomically-listed but implausibly-far box.
        let byName = Dictionary(volumes.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        let radius = simd_length(primary.maxBound - primary.minBound) * radiusFactor
        // Explicitly-typed steps: the equivalent single chained expression trips
        // Swift's "unable to type-check in reasonable time".
        let pooledVolumes: [HitVolume] = pool.compactMap { byName[$0] }
        let nearby: [HitVolume] = pooledVolumes.filter { simd_length(point - $0.center) <= radius }
        let sortedNearby: [HitVolume] = nearby.sorted {
            simd_length_squared(point - $0.center) < simd_length_squared(point - $1.center)
        }
        let neighbors: [String] = sortedNearby.map(\.name)

        var result = [primary.name]
        for name in neighbors where result.count < maxCandidates {
            result.append(name)
        }
        return result
    }
```

- [ ] **Step 4: Run to verify all pass**

Run with `-only-testing:"Breath - Relax & StretchTests/MuscleHitResolverTests"`.
Expected: all pass (the retained `regionName` tests + the 4 new adjacency tests + `candidatesOnEmptyVolumesReturnsEmpty`).

- [ ] **Step 5: Run the full test suite** to confirm no regression (`BodyMapView` still compiles against the same `candidates()` signature).

Run the full test command. Expected: green except the 4 pre-existing `CuratedContentIntegrityTests`.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Models/BodyHitVolumes.swift" "Breath - Relax & StretchTests/MuscleHitResolverTests.swift"
git commit -m "feat(bodymap): candidates() uses RegionAdjacency instead of distance radius"
```

---

## Self-Review

**Spec coverage (Plan 2 scope = Component 3 joints vocab + Component 4 adjacency):**
- `JointRegion` set of 15 → Task 1. ✓
- `RegionAdjacency` symmetric, hand-authored, groups+joints → Task 2. ✓
- `candidates()` draws from adjacency filtered to near hitboxes, capped, heads drop redundant parent (parent-drop stays in `BodyMapView`, unchanged) → Task 3. ✓
- Adjacency verification (chest tap never returns forearm; elbow returns joint + biceps/triceps/forearm; symmetry) → Tasks 2–3 tests. ✓
- **Deferred to Plan 3:** moving assets into `Resources/`, `AnatomyNodeNames` node-map loader, `BodyHitVolumes` loading the 15-joint set + face zones, `jointCentersResolveToJoints` tiebreak on real geometry, `BodySceneView` single-model/grayscale/head-skin-fade/colorize rendering, rotation-bug fix, `RegionExerciseResolver` (joint→crossing-muscle stretches), `BodyMapView` joint wiring, deleting old assets, simulator verification.

**Placeholder scan:** none — every step has runnable code/commands.

**Type consistency:** `RegionAdjacency.adjacent(to:) -> Set<String>` and `neighbors: [String: Set<String>]` are used consistently in Tasks 2–3; `candidates()` keeps its exact existing signature so `BodyMapView`'s call site (`candidates(near:in:maxCandidates:)`) still compiles unchanged; `JointRegion.allNames` used in both Task 1 and Task 2 tests.

**Note (carried to Plan 3):** shipping the adjacency `candidates()` now changes candidate selection on the CURRENT (skin+muscle) Body Map too — an intended incremental improvement. It is safe against the current hitbox set: adjacency names not yet present as hit volumes (the new joints/face zones) are simply skipped by the `byName[$0]` lookup, so nothing breaks before Plan 3 adds their boxes.
