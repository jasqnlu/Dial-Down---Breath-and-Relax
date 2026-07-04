# Body Map 3D Marking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One 3D body map (skin only); marking draws on the frozen projection of the user's current rotation, resolving strokes to anatomical muscle groups via an invisible muscle hit-proxy, highlighted with a 3D x-ray glow.

**Architecture:** `BodyRig` gains an invisible, hit-testable muscle proxy (child nodes named per Z-Anatomy) aligned to the skin mesh. A `UIViewRepresentable` `SCNView` replaces SwiftUI `SceneView` so stroke points can be resolved with `scnView.hitTest`. Marks persist as `{group: sensationColorID}` in a `MuscleMarkStore`; highlights are cloned muscle nodes rendered depth-independent. All 2D silhouette/region-grid code is deleted.

**Tech Stack:** SceneKit, SwiftUI, Swift Testing.

## Global Constraints

- Branch: `feature/bodymap-3d-marking`, cut from `feature/exercise-library` (needs `MuscleGroup`).
- Works with the CURRENT merged `BodyMuscle.obj` (single `o AnatomyExport`): name resolution then finds no per-muscle nodes and marking falls back to position-based coarse areas. Dropping in a named re-export enables full accuracy with **no code change**.
- `BodyLayer` enum stays in `Models/BodyPart.swift` (SwiftData schema stability) but all UI use disappears.
- Test command: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`

---

### Task 1: Z-Anatomy muscle-name → MuscleGroup resolver

**Files:**
- Create: `Views/BodyMap/MuscleNameResolver.swift`
- Test: `Breath - Relax & StretchTests/MuscleNameResolverTests.swift`

**Interfaces:**
- Consumes: `MuscleGroup` (exercise-library plan Task 1).
- Produces: `enum MuscleNameResolver { static func group(forNodeName: String, localX: Float) -> MuscleGroup? ; static func fallbackGroup(unitPoint: SIMD3<Float>) -> MuscleGroup }`

Z-Anatomy names muscles in Latin/English like `"Biceps brachii"`, `"Rectus femoris"`, `"Gastrocnemius"`, often with `.l`/`.r` or `_L`/`_R` suffixes, sometimes `.001` counters. The resolver: (1) lowercases and strips suffixes/counters, (2) keyword-matches against a substring table, (3) picks left/right from the suffix when present, else from the sign of `localX` (model +X = screen-left at front facing = anatomical right; verify sign against the skin mesh in Step 4 and encode the verified convention in a comment).

- [ ] **Step 1: Failing test**

```swift
import Testing
@testable import BreathRelaxStretch

struct MuscleNameResolverTests {
    @Test(arguments: [
        ("Biceps brachii.l", Float(0),  MuscleGroup.leftBiceps),
        ("Rectus femoris.r", Float(0),  MuscleGroup.rightQuads),
        ("Vastus lateralis_L", Float(0), MuscleGroup.leftQuads),
        ("Gastrocnemius.001.r", Float(0), MuscleGroup.rightCalves),
        ("Trapezius", Float(0.2),        MuscleGroup.leftTraps),   // side from localX
        ("Rectus abdominis", Float(0),   MuscleGroup.abs),
        ("Gluteus maximus.l", Float(0),  MuscleGroup.leftGlutes),
        ("Erector spinae", Float(0),     MuscleGroup.spinalErectors),
        ("Sternocleidomastoideus.r", Float(0), MuscleGroup.neckFront),
    ]) func resolvesKnownNames(name: String, x: Float, expected: MuscleGroup) {
        #expect(MuscleNameResolver.group(forNodeName: name, localX: x) == expected)
    }

    @Test func unknownNameReturnsNil() {
        #expect(MuscleNameResolver.group(forNodeName: "AnatomyExport", localX: 0) == nil)
    }

    @Test func fallbackByPosition() {
        // Unit-space: y in 0(feet)…1(head), x negative = screen-left.
        #expect(MuscleNameResolver.fallbackGroup(unitPoint: .init(-0.2, 0.97, 0)) == .head)
        #expect(MuscleNameResolver.fallbackGroup(unitPoint: .init(-0.4, 0.45, 0)) == .leftHand)
        #expect(MuscleNameResolver.fallbackGroup(unitPoint: .init(0.2, 0.02, 0)) == .rightFoot)
    }
}
```

- [ ] **Step 2: Run — FAIL (type undefined).**

- [ ] **Step 3: Implement**

```swift
import Foundation
import simd

/// Maps Z-Anatomy node names (and, failing that, positions) to MuscleGroups.
enum MuscleNameResolver {

    /// Substring (lowercased) → the left/right pair (or single) group.
    /// Order matters: first match wins, so more specific entries go first.
    private static let table: [(key: String, left: MuscleGroup, right: MuscleGroup)] = [
        ("sternocleido", .neckFront, .neckFront),
        ("scalen",       .neckFront, .neckFront),
        ("splenius",     .neckBack,  .neckBack),
        ("levator scapul", .neckBack, .neckBack),
        ("trapezius",    .leftTraps, .rightTraps),
        ("deltoid",      .leftDelts, .rightDelts),
        ("pectoralis",   .leftChest, .rightChest),
        ("rectus abdominis", .abs, .abs),
        ("obliqu",       .leftObliques, .rightObliques),
        ("latissimus",   .leftLats, .rightLats),
        ("rhomboid",     .leftTraps, .rightTraps),
        ("erector",      .spinalErectors, .spinalErectors),
        ("iliocostalis", .spinalErectors, .spinalErectors),
        ("longissimus",  .spinalErectors, .spinalErectors),
        ("multifidus",   .lowerBack, .lowerBack),
        ("quadratus lumborum", .lowerBack, .lowerBack),
        ("biceps brachii", .leftBiceps, .rightBiceps),
        ("brachialis",   .leftBiceps, .rightBiceps),
        ("triceps",      .leftTriceps, .rightTriceps),
        ("brachioradialis", .leftForearm, .rightForearm),
        ("carpi",        .leftForearm, .rightForearm),
        ("digitorum",    .leftForearm, .rightForearm),   // superficialis/profundus etc.
        ("pronator",     .leftForearm, .rightForearm),
        ("supinator",    .leftForearm, .rightForearm),
        ("gluteus",      .leftGlutes, .rightGlutes),
        ("piriformis",   .leftGlutes, .rightGlutes),
        ("iliopsoas",    .leftHipFlexors, .rightHipFlexors),
        ("psoas",        .leftHipFlexors, .rightHipFlexors),
        ("iliacus",      .leftHipFlexors, .rightHipFlexors),
        ("sartorius",    .leftHipFlexors, .rightHipFlexors),
        ("tensor fascia", .leftHipFlexors, .rightHipFlexors),
        ("adductor",     .leftAdductors, .rightAdductors),
        ("gracilis",     .leftAdductors, .rightAdductors),
        ("pectineus",    .leftAdductors, .rightAdductors),
        ("rectus femoris", .leftQuads, .rightQuads),
        ("vastus",       .leftQuads, .rightQuads),
        ("biceps femoris", .leftHamstrings, .rightHamstrings),
        ("semitendinosus", .leftHamstrings, .rightHamstrings),
        ("semimembranosus", .leftHamstrings, .rightHamstrings),
        ("gastrocnemius", .leftCalves, .rightCalves),
        ("soleus",       .leftCalves, .rightCalves),
        ("tibialis anterior", .leftTibialis, .rightTibialis),
        ("peroneus",     .leftTibialis, .rightTibialis),
        ("fibularis",    .leftTibialis, .rightTibialis),
        ("tibialis",     .leftCalves, .rightCalves),      // posterior — after anterior
    ]

    static func group(forNodeName raw: String, localX: Float) -> MuscleGroup? {
        let name = raw.lowercased()
        // Suffix side markers: ".l"/"_l"/" l" (and .r variants), tolerant of ".001" counters.
        let cleaned = name.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        let side: Character? = {
            if cleaned.hasSuffix(".l") || cleaned.hasSuffix("_l") || cleaned.hasSuffix(" l") { return "l" }
            if cleaned.hasSuffix(".r") || cleaned.hasSuffix("_r") || cleaned.hasSuffix(" r") { return "r" }
            return nil
        }()
        guard let entry = table.first(where: { cleaned.contains($0.key) }) else { return nil }
        if entry.left == entry.right { return entry.left }
        // NOTE: Z-Anatomy "l" = anatomical left = screen-RIGHT at front facing,
        // but our vocabulary is screen-relative (matches old region names).
        // Verified in Task 3 Step 4 against the mesh; adjust here if flipped.
        switch side {
        case "l": return entry.right   // anatomical left → screen right
        case "r": return entry.left
        default:  return localX < 0 ? entry.left : entry.right
        }
    }

    /// Position fallback in unit space (x −0.5…0.5 screen-left→right at front,
    /// y 0 feet … 1 head). Used when a stroke hits skin but no named muscle.
    static func fallbackGroup(unitPoint p: SIMD3<Float>) -> MuscleGroup {
        if p.y > 0.87 { return .head }
        if p.y < 0.08 { return p.x < 0 ? .leftFoot : .rightFoot }
        if abs(p.x) > 0.28 && (0.30...0.55).contains(p.y) {
            return p.x < 0 ? .leftHand : .rightHand
        }
        // Torso/limb miss with a merged OBJ: nearest coarse group by height.
        switch p.y {
        case ..<0.30:  return p.x < 0 ? .leftCalves : .rightCalves
        case ..<0.50:  return p.x < 0 ? .leftQuads : .rightQuads
        case ..<0.62:  return .abs
        case ..<0.80:  return p.x < 0 ? .leftChest : .rightChest
        default:       return p.x < 0 ? .leftDelts : .rightDelts
        }
    }
}
```

- [ ] **Step 4: Run — PASS. Commit** `git commit -m "feat: Z-Anatomy muscle name resolver"`

---

### Task 2: MuscleMarkStore (persistence + legacy migration)

**Files:**
- Create: `Views/BodyMap/MuscleMarkStore.swift`
- Test: `Breath - Relax & StretchTests/MuscleMarkStoreTests.swift`

**Interfaces:**
- Produces: `@MainActor final class MuscleMarkStore: ObservableObject` with `@Published private(set) var marks: [String: String]` (group rawValue → sensation color id), `func mark(_ group: MuscleGroup, colorID: String)`, `func unmark(_ group: MuscleGroup)`, `func undo()`, `func clear()`, `var markedNames: [String]`. Persists to UserDefaults key `bodymap.muscleMarks.v1`; on first load migrates `bodymap.markedRegions` (array of legacy names) through `MuscleGroup.migrate` with default color id `"tension"`.
- Consumes: `MuscleGroup.migrate` and `sensationColors` (ids like `"tension"`, `"pain"` — reuse existing `SensationColor` from `BodyAnnotationOverlay.swift`).

- [ ] **Step 1: Failing tests** — cover: mark/unmark round-trip; undo removes last-added group only; legacy migration (seed UserDefaults `bodymap.markedRegions = ["Left Hamstring", "Core"]`, expect marks contain `"Left Hamstrings"` and `"Abs"`, and legacy key removed); persistence round-trip via a fresh store instance reading the same `UserDefaults(suiteName: "test")`.

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

@MainActor struct MuscleMarkStoreTests {
    private func freshDefaults() -> UserDefaults {
        let d = UserDefaults(suiteName: "MuscleMarkStoreTests")!
        d.removePersistentDomain(forName: "MuscleMarkStoreTests")
        return d
    }

    @Test func markUnmarkRoundTrip() {
        let store = MuscleMarkStore(defaults: freshDefaults())
        store.mark(.leftQuads, colorID: "pain")
        #expect(store.marks["Left Quadriceps"] == "pain")
        store.unmark(.leftQuads)
        #expect(store.marks.isEmpty)
    }

    @Test func undoRemovesMostRecent() {
        let store = MuscleMarkStore(defaults: freshDefaults())
        store.mark(.abs, colorID: "tension")
        store.mark(.leftLats, colorID: "tension")
        store.undo()
        #expect(store.marks.keys.contains("Abs"))
        #expect(!store.marks.keys.contains("Left Lats"))
    }

    @Test func migratesLegacyRegionNames() {
        let d = freshDefaults()
        d.set(["Left Hamstring", "Core"], forKey: "bodymap.markedRegions")
        let store = MuscleMarkStore(defaults: d)
        #expect(store.marks["Left Hamstrings"] == "tension")
        #expect(store.marks["Abs"] == "tension")
        #expect(d.stringArray(forKey: "bodymap.markedRegions") == nil)
    }

    @Test func persistsAcrossInstances() {
        let d = freshDefaults()
        MuscleMarkStore(defaults: d).mark(.rightCalves, colorID: "stress")
        #expect(MuscleMarkStore(defaults: d).marks["Right Calves"] == "stress")
    }
}
```

- [ ] **Step 2: Run — FAIL.**
- [ ] **Step 3: Implement** (init takes `defaults: UserDefaults = .standard`; store `[String: String]` dict + parallel `orderAdded: [String]` array for undo, both in one Codable envelope under `bodymap.muscleMarks.v1`).
- [ ] **Step 4: Run — PASS. Commit** `git commit -m "feat: MuscleMarkStore with legacy region migration"`

---

### Task 3: BodyRig — skin-only + invisible muscle proxy + highlight layer

**Files:**
- Modify: `Views/BodyMap/BodySceneView.swift` (BodyRig section)
- Delete usage: `BodyModelStyle.muscle/.skeleton` render paths; remove `BodySkeleton.obj` from the app bundle (delete file; the OBJ stays deleted since nothing loads it)

**Interfaces:**
- Produces on `BodyRig`: `static let muscleProxyCategory: Int = 1 << 4`; `func loadMuscleProxy()` — loads `BodyMuscle.obj` with the SAME normalisation as the skin (bbox-centre pivot, height→2.0), sets on every geometry-bearing child: `categoryBitMask = muscleProxyCategory`, transparent material (`transparency = 0`, `writesToDepthBuffer = false`, `readsFromDepthBuffer = false`); `func setHighlights(_ groups: [String: UIColor], resolver: (SCNNode) -> String?)` — maintains a `highlightRoot` node containing clones of proxy nodes whose resolved group is highlighted (clone material: emissive sensation color, `transparency 0.55`, `readsFromDepthBuffer = false`, `renderingOrder = 100`); `var rotationLocked: Bool` honoured by the drag gesture.
- Consumes: `MuscleNameResolver` for grouping proxy child nodes (via each node's world-bbox-centre `localX`).

- [ ] **Step 1:** Delete `.muscle`/`.skeleton` from `BodyModelStyle` (keep the enum with the single `.skin` case removed entirely — replace `BodyModelStyle` with direct constants; `BodyLayer.modelStyle` extension deleted). `BodyRig.init` loses the `style` parameter; template cache keys stay name-based.

- [ ] **Step 2:** Implement `loadMuscleProxy()`; call from `init` AFTER skin loads. Template-cache the processed proxy exactly like the skin (`templateCache["BodyMuscle+proxy"]`). Per-child, precompute + store resolved group name in `node.value(forKey:)`-free way: keep a `var proxyGroups: [SCNNode: String]` map on the rig built once at load: `MuscleNameResolver.group(forNodeName: child.name ?? "", localX: bboxCentre.x)` — children with nil resolution are left in the map as absent (merged-OBJ case: the single `AnatomyExport` node resolves nil → hitTest on proxy yields no group → skin fallback path, per Global Constraints).

- [ ] **Step 3:** Implement `setHighlights`. Diff against currently shown groups; rebuild only on change. Clone geometry (`node.clone()` then `geometry = geometry?.copy()`) so materials don't leak into the invisible proxy.

- [ ] **Step 4: Empirically verify left/right convention.** Temporarily set proxy `transparency = 0.4`, run in simulator, screenshot front view, confirm which screen side `.l`-suffixed nodes land on (only meaningful once the named OBJ arrives — with the merged OBJ, note it and move on). Correct `MuscleNameResolver`'s side-swap comment/logic if wrong. Revert transparency.

- [ ] **Step 5: Build green; commit** `git commit -m "feat: BodyRig skin-only with invisible muscle hit proxy + x-ray highlights"`

---

### Task 4: MarkableBodyView — SCNView representable with stroke capture

**Files:**
- Create: `Views/BodyMap/MarkableBodyView.swift`
- Modify: `Views/BodyMap/BodySceneView.swift` (replace `SceneView` with the representable; keep the SwiftUI wrapper API)

**Interfaces:**
- Produces: `struct MarkableBodyView: UIViewRepresentable` wrapping `SCNView` with: `rig: BodyRig`, `markMode: Bool`, `onStrokePoint: (MuscleGroup?) -> Void` (called per touch-moved point while `markMode`, with the resolved group for that screen point or nil), `onStrokeEnded: () -> Void`. Internally: `hitTest(point, options: [.categoryBitMask: BodyRig.muscleProxyCategory, .searchMode: SCNHitTestSearchMode.all.rawValue, .ignoreHiddenNodes: false])`; first hit whose node is in `rig.proxyGroups` wins; if none, hitTest against the skin (default mask) and convert the hit's local coordinates to unit space (`(local + 1) / 2` on y after height-2 normalisation; x unchanged sign) for `MuscleNameResolver.fallbackGroup`. Rotation drag/zoom gestures live here too and are disabled while `markMode`.
- Consumes: `BodyRig` (Task 3), `MuscleNameResolver` (Task 1).

Implementation notes (these replace SwiftUI `SceneView`, which exposes no hitTest):
- `makeUIView`: `SCNView(frame: .zero)`; `scene = rig.scene`, `pointOfView = rig.cameraNode`, `rendersContinuously = true`, `backgroundColor = .clear`.
- A `UIPanGestureRecognizer` on the coordinator handles BOTH rotate (markMode false → `rig.applyDragRotation`) and draw (markMode true → per `.changed` sample, resolve + `onStrokePoint`). Pinch recognizer drives camera z exactly as today's `zoomGesture`.
- A transient `CAShapeLayer` on the SCNView shows the live ink (stroke path in the selected sensation color, 55% alpha, 22pt round cap) and is cleared on stroke end — the persistent visual is the 3D highlight, not ink.

- [ ] **Step 1:** Write the representable + coordinator (full gesture + hitTest code as specified above).
- [ ] **Step 2:** Rewrite `BodySceneView` to compose `MarkableBodyView` (keeps `facing:` snap-to-front/back API for the non-mark browsing UI; `interactive:` parameter becomes `markMode`).
- [ ] **Step 3:** Build + run in simulator; with `-debugMarkMode YES` launch arg, drag across the chest, verify console log of resolved groups (add a temporary `#if DEBUG print` — remove before commit) and that highlight nodes appear.
- [ ] **Step 4: Commit** `git commit -m "feat: MarkableBodyView — draw-to-mark on the frozen 3D projection"`

---

### Task 5: BodyMapView rewrite + dead-code deletion

**Files:**
- Modify: `Views/BodyMap/BodyMapView.swift`, `Views/BodyMap/BodyMapComponents.swift` (MarkedAreasBanner consumes `store.markedNames`)
- Delete: `Views/BodyMap/HumanFigureView.swift`, `Views/BodyMap/BodyFigureCanvas.swift`, `Views/BodyMap/MuscleAnatomyCanvas.swift`, `Views/BodyMap/SkeletonAnatomyCanvas.swift`, `Views/BodyMap/AnatomyDrawingHelpers.swift`, `Resources/Models3D/BodySkeleton.obj`; from `Views/BodyMap/BodyAnnotationOverlay.swift` delete `AnnotationStroke`/`AnnotationStore`/stroke helpers, KEEP `DrawingTool`, `SensationColor`, `sensationColors`, `LegendSheet`.

**BodyMapView behavior:**
- Top bar: facing toggle only (no layer picker). Toolbar: Mark/Done (unchanged look).
- Mark mode: `rig.rotationLocked = true` at whatever rotation the user set (NO snap), palette + tool rows as today, eraser strokes call `store.unmark` for resolved groups, pen strokes `store.mark(group, colorID: selectedSensation.id)`. Undo → `store.undo()`. Trash → `store.clear()`.
- Highlights: `.onChange(of: store.marks)` → `rig.setHighlights(marksAsUIColor, resolver:)`.
- Marked banner: `MarkedAreasBanner(regionNames: store.markedNames.sorted(), …)` → `BodyPartExercisesView(bodyParts:)` unchanged (names are the new vocabulary — matches seed v4).
- Old zoom/pan state, `detailLevel`, `fingerZoomThreshold`, `bodyMapSex` silhouette logic: deleted (camera pinch in `MarkableBodyView` covers zoom).
- `debugBodyLayer` launch arg handling: deleted; `-debugMarkMode` kept.

- [ ] **Step 1:** Rewrite `BodyMapView` per above.
- [ ] **Step 2:** Delete listed files + purge every compile error the deletions surface (`GenderPickerPage` may reference silhouettes — check `grep -rn "SilhouetteShape\|FacialFeaturesCanvas\|BodyDetailCanvas\|AnnotationStore\|BodyFigureCanvas" "Breath - Relax & Stretch"` and fix each hit; GenderPickerPage switches to SF-symbol figures if it drew silhouettes).
- [ ] **Step 3:** Full test suite + build — green.
- [ ] **Step 4:** Simulator verification: screenshot (a) free rotation at oblique angle, (b) mark mode with two groups highlighted at that same oblique angle, (c) Find Exercises list showing results for a marked group.
- [ ] **Step 5: Commit** `git commit -m "feat: single 3D body map with rotation-frozen marking"`

---

### Task 6: Blender re-export guide

**Files:**
- Create: `docs/BLENDER_MUSCLE_EXPORT.md`

Write the step-by-step guide (select muscular-system collection in the Z-Anatomy .blend → File ▸ Export ▸ Wavefront OBJ → Limit to Selected Only ON, "Objects as OBJ Objects" ON, Triangulated Mesh ON, Apply Modifiers ON, forward −Z / up Y to match the previous export, no join) plus: how to verify (`grep -c "^o " BodyMuscle.obj` should print hundreds, not 1), where to put the file, and that no code change is needed afterward. Include the decimation note (target < 8 MB, Decimate modifier ratio ≈ 0.1 per object or Blender's batch decimation, applied before export).

- [ ] **Step 1:** Write the doc.
- [ ] **Step 2: Commit** `git commit -m "docs: Blender per-muscle OBJ export guide"`
