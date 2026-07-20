# Anatomy Rendering & Integration Implementation Plan (Plan 3 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app render the single always-visible anatomy model. Move the Plan 1 staged assets into `Resources/`, load them (node map + 15-joint/face-zone hitboxes), rewrite `BodySceneView.swift` to a single grayscale muscle+joint model with a fading skin head (colorize the adjacency candidates on reveal), fix the slight-rotation-on-select bug, resolve joints to their crossing muscles' exercises, and verify it all in the simulator.

**Architecture:** `BodyModelStyle` collapses to one `.anatomy` resource. `BodyMeshLoader` parses `BodyAnatomy.obj` into per-object `AnatomyPiece`s tagged by layer (`muscle`/`joint`/`headSkin`) from `anatomy_node_names.json`. `BodyRig` holds one always-visible `anatomyNode` (muscle+joint children, grayscale at rest) and a `headSkinNode` (head-skin patches, grayscale, fades to ~0.12 on reveal). Reveal = colorize the adjacency-selected candidates' nodes (tint+emission over the grayscale base) + fade the head skin; dismiss reverses it. Marking taps raycast the always-visible anatomy surface and resolve via the unchanged `MuscleHitResolver`. Plan 2's `RegionAdjacency` is reused both for candidates (already shipped) and to resolve a joint to its crossing muscles' exercises.

**Tech Stack:** Swift, SwiftUI, SceneKit/simd, Swift Testing. Simulator via the repo `verify` skill.

## Global Constraints

- **Test framework:** Swift Testing only (never XCTest). Module `BreathRelaxStretch`.
- **Test command:** `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- **Pre-existing known-failing tests:** the 4 `CuratedContentIntegrityTests` fail on `main` for unrelated reasons — NOT a regression gate. Every other test must stay green.
- **Assets to install (from `Tools/blender/generated/`):** `BodyAnatomy.obj`, `anatomy_node_names.json`, `musclegroup_hitboxes.json`, `musclegroup_head_hitboxes.json`, `joint_hitboxes.json` → `Breath - Relax & Stretch/Resources/` (hitboxes at `Resources/`, the OBJ at `Resources/Models3D/`). **Delete:** `Resources/Models3D/BodyMale.obj`, `Resources/Models3D/BodyMuscle.obj`, `Resources/musclegroup_node_names.json`.
- **Node-map schema** (`anatomy_node_names.json`): `{"nodes": {node: {"layer": "muscle"|"joint"|"headSkin", "group"?, "head"?, "faceZone"?, "joint"?}}}`. A muscle node has `group` (+ optional `head`, `faceZone`); a joint node has `joint`; a headSkin node has only `layer`.
- **Coordinate space unchanged:** the OBJ is pre-normalized (identity load — do NOT recentre/scale it, same as the old `BodyMuscle.obj`). Marks/hitboxes live in the same rigNode-local normalized space.
- **Anatomical L/R = world +x.** Grayscale at rest; color only on highlight. Head skin fades on any reveal (a no-op when the head is out of frame for a body tap).
- **Keep the `MuscleNodeNames` type name** (not renamed to `AnatomyNodeNames`) to avoid churning every call site — it now loads the anatomy map. (Spec's rename is cosmetic; skipped.)
- **Xcode file-system-synced groups:** new `Models/`/`Tests/` files auto-add to the target; asset moves under `Resources/` also auto-sync. Deleting a bundled resource may need it removed from the target — verify the build sees the change.

---

### Task 1: Single-model swap — assets, node map, `BodySceneView` rewrite

This is the large coupled task (see the plan's Architecture note): the asset swap cannot land green without the loader + `BodySceneView` rewrite. Do it as one task; its deliverable is "the single anatomy model loads, renders grayscale with a fading head skin + colorized candidates, and all node/hitbox/parser tests pass."

**Files:**
- Move: `Tools/blender/generated/{BodyAnatomy.obj → Resources/Models3D/, anatomy_node_names.json, musclegroup_hitboxes.json, musclegroup_head_hitboxes.json, joint_hitboxes.json → Resources/}`
- Delete: `Resources/Models3D/BodyMale.obj`, `Resources/Models3D/BodyMuscle.obj`, `Resources/musclegroup_node_names.json`
- Rewrite: `Breath - Relax & Stretch/Models/MuscleNodeNames.swift`
- Rewrite (sections): `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift`
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift` (pass `.anatomy`)
- Update: `Breath - Relax & StretchTests/MuscleNodeNamesTests.swift`, `Breath - Relax & StretchTests/HitboxDataTests.swift`

**Interfaces:**
- Consumes: `anatomy_node_names.json`, `BodyAnatomy.obj`, the regenerated hitbox JSONs; `RegionAdjacency`, `JointRegion` (Plan 2); `MuscleGroup`, `HeadZones` (existing).
- Produces:
  - `MuscleNodeNames` with `groupByNode/headByNode/faceZoneByNode/jointByNode/layerByNode: [String:String]`, `nodesByGroup/nodesByHead/nodesByFaceZone/nodesByJoint: [String:[String]]`, `nodeNames(forRegion:) -> [String]` (covers group/head/faceZone/joint), `matchingCandidate(forNode:among:) -> String?`.
  - `BodyMeshLoader.anatomyParts() -> [AnatomyPiece]?` where `AnatomyPiece { name, layer, group?, head?, faceZone?, joint?, sources, element }`.
  - `BodyRig` with `fadeHeadSkin(reveal:)`, `showCandidates(_:focused:)`, `clearCandidates()`, and a single `.anatomy` style.

#### Step 1: Install the assets (git move + delete)

- [ ] Run:

```bash
cd "Breath - Relax & Stretch"   # repo subdir with the app
git mv "../Tools/blender/generated/BodyAnatomy.obj" "Resources/Models3D/BodyAnatomy.obj"
git mv "../Tools/blender/generated/anatomy_node_names.json" "Resources/anatomy_node_names.json"
git mv "../Tools/blender/generated/musclegroup_hitboxes.json" "Resources/musclegroup_hitboxes.json"
git mv "../Tools/blender/generated/musclegroup_head_hitboxes.json" "Resources/musclegroup_head_hitboxes.json"
git mv "../Tools/blender/generated/joint_hitboxes.json" "Resources/joint_hitboxes.json"
git rm "Resources/Models3D/BodyMale.obj" "Resources/Models3D/BodyMuscle.obj" "Resources/musclegroup_node_names.json"
cd ..
```
Expected: `git mv`/`git rm` succeed. (The old `musclegroup_hitboxes.json`/`musclegroup_head_hitboxes.json` are overwritten by the moves — that's intended, the regenerated ones replace them.)

#### Step 2: Rewrite `MuscleNodeNames.swift` (write the failing test first)

- [ ] **Update `MuscleNodeNamesTests.swift`** to the anatomy schema — replace the whole file with:

```swift
import Testing
import Foundation
import SceneKit
@testable import BreathRelaxStretch

/// Coverage + consistency for the anatomy node map (anatomy_node_names.json) and
/// the OBJ parser behind the single-model Body Map. Every group/head/faceZone/
/// joint must be highlightable, and the parser must produce exactly the mapped nodes.
struct MuscleNodeNamesTests {
    private var muscleHeads: [String] { MuscleGroup.muscleHeads.filter { $0.value != "Head" }.map(\.key) }
    private var faceZones: [String] { MuscleGroup.muscleHeads.filter { $0.value == "Head" }.map(\.key) }

    @Test func everyMuscleGroupHasNodes() {
        for g in MuscleGroup.allCases {
            #expect(!(MuscleNodeNames.nodesByGroup[g.rawValue] ?? []).isEmpty, "\(g.rawValue) has no nodes")
        }
    }
    @Test func everyMuscleHeadHasNodes() {
        for h in muscleHeads { #expect(!(MuscleNodeNames.nodesByHead[h] ?? []).isEmpty, "\(h) has no nodes") }
    }
    @Test func everyFaceZoneHasNodes() {
        for z in faceZones { #expect(!(MuscleNodeNames.nodesByFaceZone[z] ?? []).isEmpty, "\(z) has no nodes") }
    }
    @Test func everyJointRegionHasNodes() {
        for j in JointRegion.allNames { #expect(!(MuscleNodeNames.nodesByJoint[j] ?? []).isEmpty, "\(j) has no nodes") }
    }
    @Test func nodeNamesResolvesAllRegionKinds() {
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Biceps").isEmpty)              // group
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Triceps Long Head").isEmpty)   // head
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Eye").isEmpty)                 // face zone (now real)
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Elbow").isEmpty)               // joint (now real)
        #expect(MuscleNodeNames.nodeNames(forRegion: "Nonsense Region").isEmpty)
    }
    @Test func parserBuildsExactlyTheMappedNodes() async {
        guard let parts = await BodyMeshLoader.shared.anatomyParts() else {
            Issue.record("BodyAnatomy.obj failed to parse"); return
        }
        #expect(Set(parts.map(\.name)) == Set(MuscleNodeNames.layerByNode.keys), "parsed nodes differ from map keys")
        for part in parts {
            #expect(part.layer == MuscleNodeNames.layerByNode[part.name])
            #expect(part.element.primitiveCount > 0, "\(part.name) has no triangles")
        }
    }
}
```

- [ ] **Replace `MuscleNodeNames.swift`** with:

```swift
import Foundation

/// Bidirectional map between the anatomy mesh's SceneKit node names and the app
/// vocabulary, loaded from `anatomy_node_names.json` (generated by
/// `Tools/blender/export_anatomy.py` alongside `BodyAnatomy.obj`). Each exported
/// object is one addressable node. Resolves a tapped node to its group / sub-head
/// / face zone / joint, and enumerates the nodes of a candidate region so a
/// highlight can light it. head-skin nodes carry only a layer (no region).
nonisolated enum MuscleNodeNames {
    static var groupByNode: [String: String] { loaded.groupByNode }
    static var headByNode: [String: String] { loaded.headByNode }
    static var faceZoneByNode: [String: String] { loaded.faceZoneByNode }
    static var jointByNode: [String: String] { loaded.jointByNode }
    static var layerByNode: [String: String] { loaded.layerByNode }
    static var nodesByGroup: [String: [String]] { loaded.nodesByGroup }
    static var nodesByHead: [String: [String]] { loaded.nodesByHead }
    static var nodesByFaceZone: [String: [String]] { loaded.nodesByFaceZone }
    static var nodesByJoint: [String: [String]] { loaded.nodesByJoint }

    /// Node names to light for a candidate region (group / head / face zone /
    /// joint). Finer-grained wins: head, then face zone, then joint, then group.
    static func nodeNames(forRegion region: String) -> [String] {
        if let h = nodesByHead[region] { return h }
        if let f = nodesByFaceZone[region] { return f }
        if let j = nodesByJoint[region] { return j }
        if let g = nodesByGroup[region] { return g }
        return []
    }

    /// Which candidate a tapped node belongs to, finest-first (head > faceZone >
    /// joint > group), so a tap resolves to the most specific offered region.
    static func matchingCandidate(forNode node: String, among candidates: Set<String>) -> String? {
        if let h = headByNode[node], candidates.contains(h) { return h }
        if let f = faceZoneByNode[node], candidates.contains(f) { return f }
        if let j = jointByNode[node], candidates.contains(j) { return j }
        if let g = groupByNode[node], candidates.contains(g) { return g }
        return nil
    }

    private struct Entry: Decodable {
        let layer: String
        let group: String?
        let head: String?
        let faceZone: String?
        let joint: String?
    }
    private struct FileShape: Decodable { let nodes: [String: Entry] }

    struct Maps {
        var groupByNode: [String: String] = [:]
        var headByNode: [String: String] = [:]
        var faceZoneByNode: [String: String] = [:]
        var jointByNode: [String: String] = [:]
        var layerByNode: [String: String] = [:]
        var nodesByGroup: [String: [String]] = [:]
        var nodesByHead: [String: [String]] = [:]
        var nodesByFaceZone: [String: [String]] = [:]
        var nodesByJoint: [String: [String]] = [:]
    }

    private static let loaded: Maps = load()

    static func load(bundle: Bundle = .main) -> Maps {
        guard let url = bundle.url(forResource: "anatomy_node_names", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FileShape.self, from: data)
        else { return Maps() }
        var m = Maps()
        for (node, e) in file.nodes {
            m.layerByNode[node] = e.layer
            if let g = e.group { m.groupByNode[node] = g; m.nodesByGroup[g, default: []].append(node) }
            if let h = e.head { m.headByNode[node] = h; m.nodesByHead[h, default: []].append(node) }
            if let f = e.faceZone { m.faceZoneByNode[node] = f; m.nodesByFaceZone[f, default: []].append(node) }
            if let j = e.joint { m.jointByNode[node] = j; m.nodesByJoint[j, default: []].append(node) }
        }
        return m
    }
}
```

- [ ] Run the focused test — it will still FAIL (`anatomyParts`/`.anatomy` don't exist yet, `BodySceneView` unchanged). Expected: compile errors referencing `anatomyParts`. Proceed to Step 3 (the rewrite makes it compile + pass).

#### Step 3: Rewrite the `BodySceneView.swift` model/rig sections

Apply these edits (the rest of the file — `SceneKitContainer`, `CandidateRailOverlay`, `MarkCandidate`, `CandidatePalette`, gestures, marks, camera, lights, `snap`, `resetCamera`, `updateMarks`, `addDebugHitboxesIfEnabled` — is UNCHANGED):

- [ ] **`BodyModelStyle`** → collapse to a single case:

```swift
nonisolated enum BodyModelStyle {
    case anatomy
    var resourceName: String { "BodyAnatomy" }
}
```

- [ ] **`MuscleHighlight`** → add the grayscale base tone and drop the skin-fade constant's old meaning (reuse for head skin):

```swift
nonisolated enum MuscleHighlight {
    /// Neutral grayscale the whole model wears at rest — colour is reserved for highlight.
    static let baseTone = UIColor(white: 0.62, alpha: 1)
    static let unfocusedTint: CGFloat = 0.5
    static let focusedTint: CGFloat = 0.8
    static let unfocusedGlow: CGFloat = 0.12
    static let focusedGlow: CGFloat = 0.42
    /// Head-skin opacity while a reveal is active (fades to expose facial muscles).
    static let headSkinRevealedOpacity: CGFloat = 0.12
    static let revealDuration: TimeInterval = 0.5
    static func lerp(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor { /* unchanged body */ }
}
```
(Keep the existing `lerp` body verbatim.)

- [ ] **`BodyMeshLoader`** → replace `MusclePiece`/`muscleParts`/`muscleCache`/`parseMuscleOBJ` with the anatomy equivalents; keep `template(for:)`/`makeTemplateBodyNode`/`recenterAndScaleToHeight2`/`applyMaterial` ONLY if still used (they are not — the anatomy model is parsed into pieces, not loaded as a template; delete `template`, `makeTemplateBodyNode`, `recenterAndScaleToHeight2`, `applyMaterial`, and the `cache` dict). New:

```swift
actor BodyMeshLoader {
    static let shared = BodyMeshLoader()
    private var partsCache: [AnatomyPiece]?

    struct AnatomyPiece {
        let name: String
        let layer: String            // "muscle" | "joint" | "headSkin"
        let group: String?
        let head: String?
        let faceZone: String?
        let joint: String?
        let sources: [SCNGeometrySource]
        let element: SCNGeometryElement
    }

    func anatomyParts() -> [AnatomyPiece]? {
        if let partsCache { return partsCache }
        guard let url = Bundle.main.url(forResource: BodyModelStyle.anatomy.resourceName, withExtension: "obj"),
              let parts = Self.parseAnatomyOBJ(url: url) else { return nil }
        partsCache = parts
        return parts
    }

    /// Same contiguous-OBJ parser as before, but keeps EVERY mapped node (muscle,
    /// joint, headSkin) and tags it from the node map. Objects absent from the map
    /// or with no faces are skipped.
    private static func parseAnatomyOBJ(url: URL) -> [AnatomyPiece]? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        var parts: [AnatomyPiece] = []
        var name: String?
        var vertBase = 0, globalV = 0
        var positions: [SCNVector3] = [], normals: [SCNVector3] = []
        var indices: [Int32] = []
        func flush() {
            guard let name, !indices.isEmpty, let layer = MuscleNodeNames.layerByNode[name] else { return }
            let sources = [SCNGeometrySource(vertices: positions), SCNGeometrySource(normals: normals)]
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            parts.append(AnatomyPiece(name: name, layer: layer,
                                      group: MuscleNodeNames.groupByNode[name],
                                      head: MuscleNodeNames.headByNode[name],
                                      faceZone: MuscleNodeNames.faceZoneByNode[name],
                                      joint: MuscleNodeNames.jointByNode[name],
                                      sources: sources, element: element))
        }
        text.enumerateLines { line, _ in
            if line.hasPrefix("v ") {
                let c = line.dropFirst(2).split(separator: " ")
                if c.count == 3, let x = Float(c[0]), let y = Float(c[1]), let z = Float(c[2]) { positions.append(SCNVector3(x, y, z)) }
                globalV += 1
            } else if line.hasPrefix("vn ") {
                let c = line.dropFirst(3).split(separator: " ")
                if c.count == 3, let x = Float(c[0]), let y = Float(c[1]), let z = Float(c[2]) { normals.append(SCNVector3(x, y, z)) }
            } else if line.hasPrefix("f ") {
                for tok in line.dropFirst(2).split(separator: " ") {
                    let vStr = tok.prefix { $0 != "/" }
                    if let g = Int(vStr) { indices.append(Int32(g - vertBase - 1)) }
                }
            } else if line.hasPrefix("o ") {
                flush(); name = String(line.dropFirst(2)); vertBase = globalV
                positions.removeAll(keepingCapacity: true); normals.removeAll(keepingCapacity: true); indices.removeAll(keepingCapacity: true)
            }
        }
        flush()
        return parts.isEmpty ? nil : parts
    }
}
```

- [ ] **`BodyRig`** → replace the layer nodes + load + reveal + highlight logic. `bodyNode`/`skinNode`/`muscleNode`/`muscleNodesByName`/`muscleLoaded`/`loadMuscleLayerIfNeeded`/`revealMuscleLayer`/`hideMuscleLayer` are replaced by:

```swift
    let anatomyNode = SCNNode()   // muscle + joint children, always visible
    let headSkinNode = SCNNode()  // head-skin patches, always visible, fades on reveal
    private var nodesByName: [String: SCNNode] = [:]   // every mapped piece, for highlight + hit-test

    // in init(): after adding marksNode —
    rigNode.addChildNode(anatomyNode)
    rigNode.addChildNode(headSkinNode)

    /// Parses the anatomy mesh (background) and attaches one node per piece with a
    /// grayscale base material; muscle+joint pieces go under `anatomyNode`, head-
    /// skin pieces under `headSkinNode`. Idempotent.
    @MainActor
    func loadIfNeeded() async {
        guard !isLoaded, !loadFailed else { return }
        guard let parts = await BodyMeshLoader.shared.anatomyParts() else { loadFailed = true; return }
        for part in parts {
            let geometry = SCNGeometry(sources: part.sources, elements: [part.element])
            geometry.materials = [Self.makeBaseMaterial()]
            let node = SCNNode(geometry: geometry)
            node.name = part.name
            (part.layer == "headSkin" ? headSkinNode : anatomyNode).addChildNode(node)
            nodesByName[part.name] = node
        }
        isLoaded = true
    }

    private static func makeBaseMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.isDoubleSided = true
        m.metalness.contents = 0.0
        m.roughness.contents = 0.6
        m.diffuse.contents = MuscleHighlight.baseTone
        return m
    }

    /// Fades the head skin to expose the facial muscles (reveal) or back to opaque
    /// (dismiss). A no-op-looking fade when the head is out of frame (body taps).
    func fadeHeadSkin(reveal: Bool) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = MuscleHighlight.revealDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        headSkinNode.opacity = reveal ? MuscleHighlight.headSkinRevealedOpacity : 1
        SCNTransaction.commit()
    }
```

- [ ] **`showCandidates` / `clearCandidates` / `resetTints` / `applyTint` / `addCandidateDot`** → retarget from `muscleNodesByName` to `nodesByName`, and dots live under `anatomyNode`. Keep the same tint/emission logic; `nodeNames(forRegion:)` now resolves joints + face zones too, so the `cand-dot` fallback only fires for a region with zero geometry:

```swift
    func showCandidates(_ candidates: [MarkCandidate], focused: String?) {
        resetTints()
        for (i, c) in candidates.enumerated() {
            let isFocused = c.name == focused
            let accent = CandidatePalette.uiColor(i)
            let names = MuscleNodeNames.nodeNames(forRegion: c.name)
            if names.isEmpty {
                addCandidateDot(for: c, accent: accent, focused: isFocused)
            } else {
                for n in names { if let node = nodesByName[n] { applyTint(accent, focused: isFocused, to: node) } }
            }
        }
    }
    func clearCandidates() { resetTints() }
    private func resetTints() {
        for node in nodesByName.values {
            guard let m = node.geometry?.firstMaterial else { continue }
            m.diffuse.contents = MuscleHighlight.baseTone
            m.emission.intensity = 0
        }
        anatomyNode.childNodes.filter { $0.name?.hasPrefix("cand-dot:") == true }.forEach { $0.removeFromParentNode() }
    }
    // applyTint: unchanged body. addCandidateDot: change `muscleNode.addChildNode(node)` → `anatomyNode.addChildNode(node)`.
```

- [ ] **`BodySceneView`** view struct: `style` default `.anatomy`; delete `loadMuscleLayerIfNeeded` warm-up call in `handleTap` (the model is already loaded); `applyFocus` becomes colorize + fade head skin (no separate muscle reveal):

```swift
    private func applyFocus(for candidates: [MarkCandidate]) {
        guard let primary = candidates.first else { return }
        rig.focus(on: focusPoint ?? primary.point) { projectPinPositions(for: candidates) }
        rig.showCandidates(candidates, focused: focusedRegion ?? primary.name)
        rig.fadeHeadSkin(reveal: true)
    }
```
And in the `disambiguationCandidates` empty branch, replace `rig.hideMuscleLayer()` with `rig.clearCandidates(); rig.fadeHeadSkin(reveal: false)`. In `handleTap`, delete the `Task { await rig.loadMuscleLayerIfNeeded() }` warm-up block. In `handleCandidateHitTest`, `MuscleNodeNames.matchingCandidate` already covers joints/faceZones — unchanged. The `#Preview` uses `style: .anatomy`.

- [ ] **`BodyMapView.swift`**: change the `BodySceneView(... style: .skin ...)` argument to `.anatomy`.

#### Step 4: Update `HitboxDataTests.swift` for the 15-joint set

- [ ] Replace `jointBoxesExistWithAnatomicalSides` and keep the tiebreak test:

```swift
    @Test func jointBoxesMatchJointRegionSet() throws {
        let joints = try loadBoxes("joint_hitboxes")
        #expect(Set(joints.keys) == JointRegion.allNames)
        for (name, box) in joints {
            let cx = (box.min[0] + box.max[0]) / 2
            if name.hasPrefix("Left ")  { #expect(cx > 0, "\(name)") }
            if name.hasPrefix("Right ") { #expect(cx < 0, "\(name)") }
        }
    }
```
(Keep `muscleBoxCountMatchesMuscleGroupCases`, `leftBoxesArePositiveX_rightBoxesNegativeX`, `jointCentersResolveToJoints`, `boxUnionFitsNormalizedBody` unchanged. `jointCentersResolveToJoints` is the KNOWN-RISK test — see Step 6.)

#### Step 5: Build + run the node/hitbox/parser tests

- [ ] Run `-only-testing:"Breath - Relax & StretchTests/MuscleNodeNamesTests"` and `-only-testing:"Breath - Relax & StretchTests/HitboxDataTests"`. Expected: green.

#### Step 6: Resolve the joint-tiebreak risk if `jointCentersResolveToJoints` fails

- [ ] If `jointCentersResolveToJoints` fails (a joint center resolves to a smaller overlapping muscle/head box), the real-geometry joint box lost the smallest-volume tiebreak. Fix by tightening the joint boxes: in `Tools/blender/classify_joint_hitboxes.py`, shrink each region's unioned box toward its center by a factor (e.g. scale extents to 0.7) before writing, OR bucket only the capsule (drop ligaments) for the offending region; then re-run `python3 classify_joint_hitboxes.py`, copy the new `joint_hitboxes.json` into `Resources/`, and re-run the test. Repeat until green. Document which regions needed tightening.

#### Step 7: Full suite + commit

- [ ] Run the full test command. Expected: green except the 4 known `CuratedContentIntegrityTests`.
- [ ] Commit:

```bash
git add -A "Breath - Relax & Stretch/Resources" "Breath - Relax & Stretch/Models/MuscleNodeNames.swift" "Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift" "Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift" "Breath - Relax & StretchTests/MuscleNodeNamesTests.swift" "Breath - Relax & StretchTests/HitboxDataTests.swift"
git commit -m "feat(bodymap): single always-visible anatomy model (grayscale + head-skin fade)"
```

---

### Task 2: Rotation-bug fix + invariance test

**Files:** Modify `BodySceneView.swift` (`BodyRig.focus`); Test `Breath - Relax & StretchTests/BodyRigFocusTests.swift` (new).

**Interfaces:** Consumes `BodyRig`. Produces a `focus` that never changes `rigNode.eulerAngles` and keeps the camera up-vector world-up.

- [ ] **Step 1: Write the failing/guard test** — `BodyRigFocusTests.swift`:

```swift
import Testing
import SceneKit
import simd
@testable import BreathRelaxStretch

@MainActor struct BodyRigFocusTests {
    @Test func focusLeavesRigRotationUnchanged() {
        let rig = BodyRig(style: .anatomy)
        rig.rigNode.eulerAngles = SCNVector3(0, 0.7, 0)   // a committed turntable rotation
        let before = rig.rigNode.eulerAngles
        rig.focus(on: SIMD3<Float>(0.2, 0.3, 0.1))
        let after = rig.rigNode.eulerAngles
        #expect(before.x == after.x && before.y == after.y && before.z == after.z,
                "focus() must be a pure camera dolly — rig rotation changed")
    }

    @Test func focusKeepsCameraUpright() {
        let rig = BodyRig(style: .anatomy)
        rig.focus(on: SIMD3<Float>(0.3, -0.2, 0.0))
        // Camera transform's up (column 1) must stay world-up: no roll.
        let up = rig.cameraNode.simdTransform.columns.1
        #expect(abs(up.x) < 0.02 && abs(up.z) < 0.02, "camera rolled during focus (up=\(up))")
    }
}
```

- [ ] **Step 2: Run** `-only-testing:"...BodyRigFocusTests"`. If `focusLeavesRigRotationUnchanged` passes but `focusKeepsCameraUpright` fails, the roll is from `look(at:)` combined with the y-lift; if both pass, the visible "rotation" is expected dolly parallax and the bug is elsewhere — capture it in the simulator (Task 4) before changing code. Expected (pre-fix): identify which assertion fails.

- [ ] **Step 3: Fix `focus`** — pass an explicit world-up to the look so the lifted camera never rolls, and dolly without touching the rig:

```swift
        cameraNode.position = SCNVector3(camPos.x, camPos.y, camPos.z)
        cameraNode.look(at: SCNVector3(world.x, world.y, world.z),
                        up: SCNVector3(0, 1, 0),
                        localFront: SCNVector3(0, 0, -1))
```
(Replace the bare `cameraNode.look(at:)`. `rigNode` is never mutated by `focus`, satisfying the invariance test.)

- [ ] **Step 4: Run** the focused test → green. **Step 5: Commit** `git commit -m "fix(bodymap): focus() is a pure upright dolly, never rotates the rig"`.

---

### Task 3: Resolve joints to their crossing muscles' exercises

**Files:** Modify `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift` (`RegionExerciseResolver.init`); Test `Breath - Relax & StretchTests/RegionExerciseResolverTests.swift` (new).

**Interfaces:** Consumes `RegionAdjacency`, `JointRegion`, `MuscleGroup`. Produces a resolver that, for a joint region, targets its crossing muscle groups (from `RegionAdjacency`).

- [ ] **Step 1: Write the failing test** — `RegionExerciseResolverTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct RegionExerciseResolverTests {
    private func ex(_ name: String, targets: [String]) -> Exercise {
        Exercise(name: name, targetBodyParts: targets)   // adjust to the real Exercise initializer
    }
    @Test func jointResolvesToCrossingMuscles() {
        let biceps = ex("Biceps Curl", targets: ["Left Biceps"])
        let forearm = ex("Wrist Curl", targets: ["Left Forearm"])
        let unrelated = ex("Calf Raise", targets: ["Left Calves"])
        let r = RegionExerciseResolver(regions: ["Left Elbow"], exercises: [biceps, forearm, unrelated])
        let names = Set(r.direct.map(\.name))
        #expect(names.contains("Biceps Curl"))
        #expect(names.contains("Wrist Curl"))
        #expect(!names.contains("Calf Raise"))
    }
}
```
(Adjust `ex(...)` to the real `Exercise` initializer — inspect `Models/Exercise.swift`; the test needs an exercise with `targetBodyParts`.)

- [ ] **Step 2: Run** → fails (`Left Elbow` isn't in `oldRegionMap` as biceps/forearm? it IS for Elbow — but `Left Shoulder Joint`/`Left Hip`/`Upper Spine` are NOT; the test uses Elbow which may already pass via `oldRegionMap`). If Elbow already passes, switch the test region to `"Left Shoulder Joint"` (targets `["Left Shoulder"]`) which has no `oldRegionMap` entry, so it fails pre-fix. Confirm RED.

- [ ] **Step 3: Extend `RegionExerciseResolver.init`** — in the region loop, add a joint branch before the `else`:

```swift
            } else if JointRegion.isJoint(region) {
                // A joint targets its crossing muscle groups (from the adjacency map).
                let crossing = RegionAdjacency.adjacent(to: region).filter { MuscleGroup(rawValue: $0) != nil }
                directNames.append(contentsOf: crossing)
            } else {
```

- [ ] **Step 4: Run** → green. **Step 5: Commit** `git commit -m "feat(bodymap): resolve joint regions to their crossing muscles' exercises"`.

---

### Task 4: Simulator verification + HeadZones anchor retune

**Files:** possibly tune `Breath - Relax & Stretch/Views/BodyMap/HeadZones.swift` anchors and `BodyRig.defaultCameraDistance`.

Use the repo `verify` skill (XCUITest driver + screenshots). Verify against the mockup `docs/mockups/bodymap-anatomy-reveal.html`:

- [ ] Resting figure reads **grayscale** with a normal (skinned) face; body is bare muscle+joints.
- [ ] Tap the **chest** → confirm → only chest/abs/oblique/shoulder candidates colorize (NO arm).
- [ ] Tap near the **elbow** → the joint capsule highlights + biceps/triceps/forearm.
- [ ] Tap the **face** → the skin head fades and a facial muscle (e.g. temporalis) highlights; retune `HeadZones` anchors so each face-zone dot sits on its feature against the new head-skin model.
- [ ] Confirm **no slight-rotation on select** (the Task 2 fix); if a rotation is still visible, capture the screenshot sequence and diagnose the reveal/refocus path.
- [ ] Camera still frames the height-2 model (retune `defaultCameraDistance` only if proportions shifted).
- [ ] Screenshot each state. Commit any tuning: `git commit -m "chore(bodymap): tune head-zone anchors + framing against the anatomy model"`.

---

## Self-Review

**Spec coverage (Plan 3 = Components 1 render swap, 2 hitbox load, 5 rendering/reveal, 6 rotation + exercise resolution + simulator):**
- Single `.anatomy` model, grayscale base, `anatomyNode`+`headSkinNode`, head-skin fade, colorize-on-reveal, joint/face highlight, `cand-dot` only for zero-geometry regions → Task 1. ✓
- Assets into `Resources/`, old deleted, node map + 15-joint/face-zone hitboxes loaded → Task 1 + Step 1/4. ✓
- Joint-tiebreak known risk → Task 1 Step 6. ✓
- Rotation-bug fix + invariance test → Task 2. ✓
- `RegionExerciseResolver` joint→crossing-muscles (reusing `RegionAdjacency`) → Task 3. ✓
- Simulator verification + HeadZones/framing retune → Task 4. ✓

**Placeholder scan:** the test helper `ex(...)` in Task 3 and the `MuscleHighlight.lerp`/`applyTint` bodies say "adjust to real initializer"/"unchanged body" — these point at existing code the implementer must copy verbatim, not invent; every genuinely-new unit has complete code. Flag for the implementer: inspect `Models/Exercise.swift` for the real initializer before writing the Task 3 test.

**Consistency:** `AnatomyPiece`/`anatomyParts`/`nodesByName` names are used consistently across Task 1's loader, rig, and tests; `MuscleNodeNames` keeps its type name so `BodySceneView`/tests call sites are stable; `fadeHeadSkin(reveal:)` replaces `revealMuscleLayer`/`hideMuscleLayer` at both call sites.

**Risk callouts:** (1) Task 1 is large due to `BodySceneView`'s coupling — review it as one unit. (2) The joint-tiebreak (Step 6) may require Blender re-runs. (3) The rotation "bug" may be dolly parallax rather than a real defect — Task 2's tests distinguish the cases; don't invent a fix if both pass, use the simulator (Task 4).
