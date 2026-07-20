import SwiftUI
import SceneKit

// MARK: - Body Rig
//
// Owns the SceneKit scene graph for the rotatable 3D skin model:
//   sceneRoot
//     ├─ cameraNode        (static — never rotates)
//     ├─ keyLight / fillLight / ambientLight  (static, world-fixed)
//     └─ rigNode           (rotates around Y for the turntable effect)
//          ├─ bodyNode     (the loaded mesh, pre-centred + pre-scaled)
//          └─ marksNode    (marker-dot spheres, normalized-space coords)
//
// The mesh ships at native ZBrush export scale with no material/texture, so
// this also recentres it (pivot = bounding-box centre), uniform-scales it to
// a fixed height, and applies a skin-tone PBR material in code.
//
// Confirmed empirically from the source OBJ (see decimation notes): Y is up,
// the figure's face points toward +Z. Rotation 0 == front, π == back.
// Anatomical left = world +X (the marking system's L/R convention).

/// The 3D model style that renders the body. `skin` is the primary layer; the
/// `muscle` layer (Z-Anatomy anatomy subset) is a second mesh revealed under the
/// skin during the confirm-step disambiguation — see `BodyRig.muscleNode`.
/// Both are exported from the same Z-Anatomy Blender file on one aligned rig.
nonisolated enum BodyModelStyle {
    case skin
    case muscle

    var resourceName: String {
        switch self {
        case .skin: return "BodyMale"
        case .muscle: return "BodyMuscle"
        }
    }

    /// Programmatic PBR material — the meshes ship without textures, so colour
    /// is applied in code. For `muscle` this is the untinted per-piece base tone;
    /// candidate highlights lerp it toward an accent (see `BodyRig.showCandidates`).
    func makeMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.isDoubleSided = true
        m.metalness.contents = 0.0
        switch self {
        case .skin:
            m.diffuse.contents = UIColor(red: 0.89, green: 0.72, blue: 0.62, alpha: 1)
            m.roughness.contents = 0.7
        case .muscle:
            m.diffuse.contents = MuscleHighlight.baseTone
            m.roughness.contents = 0.55
        }
        return m
    }
}

/// Colour + blend constants for the muscle-reveal highlight, shared by the base
/// material and the candidate tint so focused / unfocused / neutral states read
/// as one system. Tints lerp the anatomical `baseTone` toward the candidate's
/// `CandidatePalette` accent — keeping base shading visible so neighbouring
/// heads never dissolve into one flat colour block (mirrors the HTML mockup).
nonisolated enum MuscleHighlight {
    static let baseTone = UIColor(red: 0.63, green: 0.29, blue: 0.27, alpha: 1)
    /// Diffuse lerp toward the accent: subtle for unfocused, stronger for focused.
    static let unfocusedTint: CGFloat = 0.35
    static let focusedTint: CGFloat = 0.62
    /// Emission (glow) alpha applied on top — the focused candidate lifts off.
    static let unfocusedGlow: CGFloat = 0.12
    static let focusedGlow: CGFloat = 0.42
    /// Skin opacity while the muscle layer is revealed (whole-mesh x-ray fade).
    static let skinRevealedOpacity: CGFloat = 0.16
    static let revealDuration: TimeInterval = 0.5

    /// Linear blend of two colours in RGB (t = 0 → a, t = 1 → b).
    static func lerp(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let r: CGFloat = ar + (br - ar) * t
        let g: CGFloat = ag + (bg - ag) * t
        let bl: CGFloat = ab + (bb - ab) * t
        return UIColor(red: r, green: g, blue: bl, alpha: 1)
    }
}

/// Loads and caches the (multi-MB) body OBJ mesh off the main thread. An
/// actor so concurrent loads — e.g. two `BodySceneView`s mounting at once, or
/// a facing flip re-creating the rig mid-load — serialize on the shared
/// template cache instead of racing.
actor BodyMeshLoader {
    static let shared = BodyMeshLoader()

    private var cache: [String: SCNNode] = [:]
    private var muscleCache: [MusclePiece]?

    /// One parsed muscle object: an addressable piece of the muscle mesh. The
    /// geometry sources/element are immutable and shared across rigs (cheap);
    /// each rig wraps them in fresh nodes + materials so tints don't bleed.
    struct MusclePiece {
        let name: String     // SceneKit node name == musclegroup_node_names.json key
        let group: String    // owning MuscleGroup raw value
        let sources: [SCNGeometrySource]
        let element: SCNGeometryElement
    }

    /// Returns the cached template node for `style`, parsing the bundled OBJ
    /// on first use. Runs on the actor's background executor, never the
    /// main thread — the OBJ parse + triangulation is the most expensive
    /// thing BodySceneView does, so this keeps it off the UI.
    func template(for style: BodyModelStyle) -> SCNNode? {
        if let cached = cache[style.resourceName] { return cached }
        guard let node = Self.makeTemplateBodyNode(for: style) else { return nil }
        cache[style.resourceName] = node
        return node
    }

    /// Parses `BodyMuscle.obj` into one `MusclePiece` per muscle object, cached
    /// after first use. SceneKit's OBJ loader merges multi-object OBJs into a
    /// single geometry (losing per-object names), so this parses the file
    /// directly — the export writes each object's v/vn/f contiguously, so a
    /// single forward scan yields clean per-object geometry. Background-only.
    func muscleParts() -> [MusclePiece]? {
        if let muscleCache { return muscleCache }
        guard let url = Bundle.main.url(forResource: BodyModelStyle.muscle.resourceName,
                                        withExtension: "obj"),
              let parts = Self.parseMuscleOBJ(url: url)
        else { return nil }
        muscleCache = parts
        return parts
    }

    private static func makeTemplateBodyNode(for style: BodyModelStyle) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: style.resourceName, withExtension: "obj"),
              let source = try? SCNScene(url: url, options: [.checkConsistency: true])
        else {
            return nil
        }

        let bodyNode = SCNNode()
        for child in source.rootNode.childNodes {
            bodyNode.addChildNode(child)
        }
        recenterAndScaleToHeight2(bodyNode)
        applyMaterial(style.makeMaterial(), to: bodyNode)
        return bodyNode
    }

    /// Recentres `node` on its bounding-box centre (via pivot, pre-scale) and
    /// uniform-scales it to height 2.0 — the app's normalized model space. Used
    /// for the raw-scale skin OBJ. NOT used for the muscle mesh, which is
    /// pre-normalized to the whole-body space at export (see export_muscle_obj.py);
    /// re-normalizing it here would rescale to the muscle-only bbox and misalign
    /// it from the hitboxes.
    private static func recenterAndScaleToHeight2(_ node: SCNNode) {
        let (bmin, bmax) = node.boundingBox
        let center = SCNVector3((bmin.x + bmax.x) / 2,
                                (bmin.y + bmax.y) / 2,
                                (bmin.z + bmax.z) / 2)
        let height = CGFloat(bmax.y - bmin.y)
        let scale = height > 0 ? Float(2.0 / height) : 1
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        node.scale = SCNVector3(scale, scale, scale)
    }

    private static func applyMaterial(_ material: SCNMaterial, to node: SCNNode) {
        if let geometry = node.geometry {
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applyMaterial(material, to: child)
        }
    }

    /// Minimal OBJ parser for the app-generated `BodyMuscle.obj` only (triangles,
    /// `v`/`vn`/`f a//a` form, one `o` group per object, global vertex indices).
    /// Exploits that each object's vertices are contiguous: `vertBase` records
    /// the running vertex count at each `o`, so a face's global index maps to a
    /// local one by subtraction. Objects absent from the node map (or with no
    /// faces) are skipped.
    private static func parseMuscleOBJ(url: URL) -> [MusclePiece]? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        var parts: [MusclePiece] = []
        var name: String?
        var vertBase = 0
        var globalV = 0
        var positions: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []

        func flush() {
            guard let name, !indices.isEmpty,
                  let group = MuscleNodeNames.groupByNode[name] else { return }
            let sources = [SCNGeometrySource(vertices: positions),
                           SCNGeometrySource(normals: normals)]
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            parts.append(MusclePiece(name: name, group: group, sources: sources, element: element))
        }

        text.enumerateLines { line, _ in
            if line.hasPrefix("v ") {
                let c = line.dropFirst(2).split(separator: " ")
                if c.count == 3, let x = Float(c[0]), let y = Float(c[1]), let z = Float(c[2]) {
                    positions.append(SCNVector3(x, y, z))
                }
                globalV += 1
            } else if line.hasPrefix("vn ") {
                let c = line.dropFirst(3).split(separator: " ")
                if c.count == 3, let x = Float(c[0]), let y = Float(c[1]), let z = Float(c[2]) {
                    normals.append(SCNVector3(x, y, z))
                }
            } else if line.hasPrefix("f ") {
                for tok in line.dropFirst(2).split(separator: " ") {
                    let vStr = tok.prefix { $0 != "/" }
                    if let g = Int(vStr) {
                        indices.append(Int32(g - vertBase - 1))
                    }
                }
            } else if line.hasPrefix("o ") {
                flush()
                name = String(line.dropFirst(2))
                vertBase = globalV
                positions.removeAll(keepingCapacity: true)
                normals.removeAll(keepingCapacity: true)
                indices.removeAll(keepingCapacity: true)
            }
        }
        flush()
        return parts.isEmpty ? nil : parts
    }
}

final class BodyRig {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let rigNode = SCNNode()
    /// Marker dots live under the rig (NOT bodyNode: bodyNode's children
    /// inherit its raw-OBJ pivot/scale; rigNode children take
    /// normalized-space coordinates directly and still rotate with the body).
    let marksNode = SCNNode()
    /// Parent for the real muscle-anatomy mesh, revealed under the skin during
    /// confirm-step disambiguation (replaces the old synthetic highlight boxes).
    /// Under the rig (like marks) so it rotates with the body and stays aligned.
    /// `isHidden` while not focused — hidden nodes are excluded from hit-testing,
    /// so a normal region tap still strikes the skin, not an invisible muscle.
    let muscleNode = SCNNode()
    let style: BodyModelStyle

    /// The attached skin mesh clone — kept so its opacity can fade to an x-ray
    /// wash when the muscle layer is revealed. Set by `loadIfNeeded`.
    private var skinNode: SCNNode?
    /// muscle node name → its SCNNode, for O(1) candidate-highlight + hit-test
    /// reverse lookup. Built by `loadMuscleLayerIfNeeded`.
    private var muscleNodesByName: [String: SCNNode] = [:]
    private(set) var muscleLoaded = false

    private(set) var loadFailed = false
    /// True once the (possibly cached) body mesh has been attached to
    /// `rigNode`. `BodySceneView` shows a placeholder until this flips.
    private(set) var isLoaded = false

    /// Current committed rotation (radians) — updated as the user drags / the
    /// facing picker snaps. Kept here (not just on the node) so gesture deltas
    /// can be applied relative to the last committed value.
    var committedRotationY: CGFloat = 0

    init(style: BodyModelStyle = .skin) {
        self.style = style
        setUpCamera()
        setUpLights()
        scene.rootNode.addChildNode(rigNode)
        rigNode.addChildNode(marksNode)
        muscleNode.isHidden = true
        muscleNode.opacity = 0
        rigNode.addChildNode(muscleNode)
        // Mesh loading is kicked off asynchronously by BodySceneView (see
        // `loadIfNeeded`) instead of here — parsing the OBJ is too heavy to
        // do synchronously on the main thread during View init.
    }

    /// Base camera distance for the (height-normalised-to-2.0) body.
    static let defaultCameraDistance: CGFloat = 2.28

    /// Default framing — pulled ~18% back from the base distance so the
    /// model doesn't crowd the frame / floating tab bar.
    static let freeExploreCameraDistance: CGFloat = defaultCameraDistance * 1.18

    private func setUpCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zNear = 0.1
        camera.zFar = 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, Float(BodyRig.defaultCameraDistance))
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setUpLights() {
        let key = SCNLight()
        key.type = .directional
        key.intensity = 1000
        key.color = UIColor.white
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(3, 4, 5)
        keyNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(keyNode)

        let fill = SCNLight()
        fill.type = .directional
        fill.intensity = 380
        fill.color = UIColor.white
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.position = SCNVector3(-3, 1, 4)
        fillNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillNode)

        let rim = SCNLight()
        rim.type = .directional
        rim.intensity = 260
        rim.color = UIColor.white
        let rimNode = SCNNode()
        rimNode.light = rim
        rimNode.position = SCNVector3(0, 2, -5)
        rimNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(rimNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 180
        ambient.color = UIColor.white
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }

    /// Parses/fetches the cached mesh on `BodyMeshLoader`'s background actor,
    /// then attaches a clone (geometry is shared copy-on-write) to `rigNode`
    /// on the main actor. Idempotent — safe to call every time
    /// `BodySceneView` appears; only the first call per rig instance does
    /// anything since `isLoaded`/`loadFailed` short-circuit the rest.
    @MainActor
    func loadIfNeeded() async {
        guard !isLoaded, !loadFailed else { return }
        guard let template = await BodyMeshLoader.shared.template(for: style) else {
            loadFailed = true
            return
        }
        // A node lives in one parent at a time, so each rig adds its own clone
        // of the shared template (geometry is shared, transforms are fresh).
        let clone = template.clone()
        rigNode.addChildNode(clone)
        skinNode = clone
        isLoaded = true
    }

    /// Lazily parses + attaches the muscle mesh the first time a tap needs it
    /// (confirm-step reveal). Builds one node per muscle piece with its own base
    /// material — candidate tints mutate these per-node, so heads within one
    /// group can highlight independently. Idempotent.
    @MainActor
    func loadMuscleLayerIfNeeded() async {
        guard !muscleLoaded else { return }
        guard let parts = await BodyMeshLoader.shared.muscleParts() else {
            muscleLoaded = true   // absent asset — degrade gracefully (no reveal)
            return
        }
        for part in parts {
            let geometry = SCNGeometry(sources: part.sources, elements: [part.element])
            geometry.materials = [BodyModelStyle.muscle.makeMaterial()]
            let node = SCNNode(geometry: geometry)
            node.name = part.name
            muscleNode.addChildNode(node)
            muscleNodesByName[part.name] = node
        }
        muscleLoaded = true
    }

    /// Fades the skin to an x-ray wash and fades the muscle layer in (same ease
    /// as the focus dolly). `showCandidates` should run first so tints are set
    /// before the layer becomes visible.
    func revealMuscleLayer() {
        guard muscleLoaded, !muscleNodesByName.isEmpty else { return }
        muscleNode.isHidden = false
        SCNTransaction.begin()
        SCNTransaction.animationDuration = MuscleHighlight.revealDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        muscleNode.opacity = 1
        skinNode?.opacity = MuscleHighlight.skinRevealedOpacity
        SCNTransaction.commit()
    }

    /// Reverses the reveal: restores the skin and fades the muscle layer out,
    /// then hides it (so it leaves normal region hit-testing again) and clears
    /// any candidate tints.
    func hideMuscleLayer() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = MuscleHighlight.revealDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        muscleNode.opacity = 0
        skinNode?.opacity = 1
        SCNTransaction.completionBlock = { [weak self] in
            self?.muscleNode.isHidden = true
            self?.resetMuscleTints()
        }
        SCNTransaction.commit()
    }

    // MARK: - Marker dots

    /// Rebuilds the marker-dot spheres from the mark set. Cheap for the
    /// handful of marks a body carries; called on every mark change.
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

    // MARK: - Rotation

    func applyDragRotation(deltaX: CGFloat) {
        let radiansPerPoint: CGFloat = 0.012
        rigNode.eulerAngles.y = Float(committedRotationY + deltaX * radiansPerPoint)
    }

    func commitDragRotation(deltaX: CGFloat) {
        let radiansPerPoint: CGFloat = 0.012
        committedRotationY += deltaX * radiansPerPoint
        rigNode.eulerAngles.y = Float(committedRotationY)
    }

    // MARK: - Disambiguation focus

    /// Dollies the camera to frame `localPoint` (rigNode-local, normalized
    /// model space) close-up and centered — the confirm-step zoom onto the
    /// actual tapped dot. The camera approaches along the dot's **outward
    /// radial-horizontal normal** (the direction from the body's central Y
    /// axis out through the dot) rather than a fixed world-Z, so a dot on the
    /// side/back of a rotated limb is framed head-on instead of edge-on or
    /// occluded. The rig isn't rotated — callers freeze the rotation gesture
    /// while focused, since this camera pose is computed for the rig
    /// orientation at the moment of the call.
    func focus(on localPoint: SIMD3<Float>, duration: TimeInterval = 0.5, completion: @escaping () -> Void = {}) {
        let worldV = rigNode.convertPosition(SCNVector3(localPoint.x, localPoint.y, localPoint.z), to: nil)
        let world = SIMD3<Float>(Float(worldV.x), Float(worldV.y), Float(worldV.z))
        let distance = Float(BodyRig.defaultCameraDistance) * 0.55

        // Outward horizontal direction from the central axis (x=0,z=0) to the
        // dot. Degenerate only if the dot sits exactly on the axis — fall back
        // to a front-on view then.
        let horizontal = SIMD3<Float>(world.x, 0, world.z)
        let outward = simd_length(horizontal) > 1e-4
            ? simd_normalize(horizontal)
            : SIMD3<Float>(0, 0, 1)

        // Camera sits out along the normal, lifted slightly so it looks a touch
        // down onto the point rather than dead level.
        let camPos = world + outward * distance + SIMD3<Float>(0, 0.06, 0)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = SCNVector3(camPos.x, camPos.y, camPos.z)
        cameraNode.look(at: SCNVector3(world.x, world.y, world.z))
        SCNTransaction.completionBlock = completion
        SCNTransaction.commit()
    }

    // MARK: - Candidate region highlights

    /// Highlights each disambiguation candidate on the real muscle mesh, colour-
    /// coded by index (matching the side-rail labels). Each candidate's muscle
    /// node(s) get a **light tint** (base anatomical shading lerped toward the
    /// accent — subtle for unfocused, stronger for focused) plus an **emission
    /// glow** that lifts the focused candidate, so adjacent heads stay distinct.
    /// Candidates with no muscle geometry (face zones, joints) fall back to a
    /// small accent dot at their anchor. Idempotent — resets prior tints first.
    func showCandidates(_ candidates: [MarkCandidate], focused: String?) {
        resetMuscleTints()
        for (i, c) in candidates.enumerated() {
            let isFocused = c.name == focused
            let accent = CandidatePalette.uiColor(i)
            let nodeNames = MuscleNodeNames.nodeNames(forRegion: c.name)
            if nodeNames.isEmpty {
                addCandidateDot(for: c, accent: accent, focused: isFocused)
            } else {
                for name in nodeNames {
                    if let node = muscleNodesByName[name] {
                        applyTint(accent, focused: isFocused, to: node)
                    }
                }
            }
        }
    }

    func clearCandidates() {
        resetMuscleTints()
    }

    /// Restores every muscle piece to its neutral base tone and removes any
    /// transient candidate dots (face-zone / joint fallbacks).
    private func resetMuscleTints() {
        for node in muscleNodesByName.values {
            guard let m = node.geometry?.firstMaterial else { continue }
            m.diffuse.contents = MuscleHighlight.baseTone
            m.emission.intensity = 0
        }
        muscleNode.childNodes
            .filter { $0.name?.hasPrefix("cand-dot:") == true }
            .forEach { $0.removeFromParentNode() }
    }

    /// Tints one muscle node toward `accent`; `focused` deepens the tint and glow.
    private func applyTint(_ accent: UIColor, focused: Bool, to node: SCNNode) {
        guard let m = node.geometry?.firstMaterial else { return }
        let tint = focused ? MuscleHighlight.focusedTint : MuscleHighlight.unfocusedTint
        m.diffuse.contents = MuscleHighlight.lerp(MuscleHighlight.baseTone, accent, tint)
        m.emission.contents = accent
        m.emission.intensity = focused ? MuscleHighlight.focusedGlow : MuscleHighlight.unfocusedGlow
    }

    /// On-body accent dot for a candidate with no muscle mesh (face zone / joint).
    /// Lives under `muscleNode` so it reveals + hides with the muscle layer.
    private func addCandidateDot(for c: MarkCandidate, accent: UIColor, focused: Bool) {
        let sphere = SCNSphere(radius: CGFloat(focused ? 0.028 : 0.022))
        let m = SCNMaterial()
        m.diffuse.contents = accent
        m.emission.contents = accent
        m.emission.intensity = focused ? 0.6 : 0.35
        m.readsFromDepthBuffer = false
        m.writesToDepthBuffer = false
        sphere.materials = [m]
        let node = SCNNode(geometry: sphere)
        node.name = "cand-dot:\(c.name)"
        node.position = SCNVector3(c.point.x, c.point.y, c.point.z)
        node.renderingOrder = focused ? 21 : 20
        muscleNode.addChildNode(node)
    }

    /// Restores the camera to a plain forward-facing shot at `distance` —
    /// used when disambiguation is cancelled or resolved.
    func resetCamera(distance: CGFloat, duration: TimeInterval = 0.4) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = SCNVector3(0, 0, Float(distance))
        cameraNode.look(at: SCNVector3(0, 0, 0))
        SCNTransaction.commit()
    }

    /// Snap to the nearest equivalent of `target` (0 = front, π = back) via the
    /// shortest angular path, so flipping Front/Back never spins the long way round.
    func snap(to target: CGFloat) {
        let twoPi = 2 * CGFloat.pi
        let current = committedRotationY
        let normalizedCurrent = current.truncatingRemainder(dividingBy: twoPi)
        var delta = (target - normalizedCurrent).truncatingRemainder(dividingBy: twoPi)
        if delta > .pi  { delta -= twoPi }
        if delta < -.pi { delta += twoPi }
        let destination = current + delta

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.35
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        rigNode.eulerAngles.y = Float(destination)
        SCNTransaction.completionBlock = { [weak self] in
            self?.committedRotationY = destination
        }
        SCNTransaction.commit()
    }
}

// MARK: - SceneKit host

/// SwiftUI's SceneView hides its SCNView, which we need for hitTest — so the
/// scene is hosted directly. SwiftUI drag/magnify gestures still attach on
/// top; the tap recognizer fails automatically once a pan starts.
private struct SceneKitContainer: UIViewRepresentable {
    let scene: SCNScene
    let pointOfView: SCNNode
    var onTap: ((CGPoint, SCNView) -> Void)?
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
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        DispatchQueue.main.async { onViewReady?(view) }
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.onTap = onTap
        // A covered SCNView pauses its display link; re-assert continuous
        // rendering so it resumes drawing when revealed (e.g. after popping the
        // exercise list) instead of showing a stale/blank frame.
        view.rendersContinuously = true
        view.isPlaying = true
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

// MARK: - Body Scene View

private extension BodyFacing {
    /// Rig Y-rotation for this facing (0 = front, π = back).
    var rotationY: CGFloat { self == .front ? 0 : .pi }
}

/// A muscle region offered by the confirm-step disambiguation popup, with
/// the rigNode-local point its label/leader anchors to (its hitbox center)
/// and the box bounds used to draw the "rough" on-body region highlight.
struct MarkCandidate: Equatable, Identifiable {
    var id: String { name }
    let name: String
    let point: SIMD3<Float>
    var minBound: SIMD3<Float> = .zero
    var maxBound: SIMD3<Float> = .zero
}

/// Deterministic colour per candidate index — cool hues group the heads of one
/// muscle as "one muscle, subdivided"; used identically by the on-body
/// highlight boxes (SceneKit) and the side-rail labels (SwiftUI) so a colour
/// dot on a label matches its region on the body.
enum CandidatePalette {
    static let colors: [Color] = [
        Color(red: 0.23, green: 0.51, blue: 0.84),   // blue
        Color(red: 0.17, green: 0.71, blue: 0.79),   // cyan
        Color(red: 0.48, green: 0.42, blue: 0.94),   // indigo
        Color(red: 0.88, green: 0.54, blue: 0.29),   // amber (neighbour muscle)
    ]
    static func color(_ i: Int) -> Color { colors[((i % colors.count) + colors.count) % colors.count] }
    static func uiColor(_ i: Int) -> UIColor { UIColor(color(i)) }
}

struct BodySceneView: View {
    let facing: BodyFacing

    /// Which anatomy layer to render. Skin is the only layer.
    var style: BodyModelStyle = .skin

    /// Current marks, rendered as marker-dot spheres on the body.
    var marks: [String: BodyMark] = [:]

    /// When set, tapping the body resolves the tapped surface point to a
    /// region name (see `MuscleHitResolver`) and calls back with the name and
    /// the point in normalized model space. Rotation stays free — hit-testing
    /// works at any camera angle.
    var onRegionTap: ((String, SIMD3<Float>) -> Void)? = nil

    /// Non-empty while showing the post-confirm disambiguation popup: the
    /// camera zooms to the first candidate and a labeled pin is placed for
    /// each. Rotation/zoom gestures freeze while this is non-empty, since the
    /// camera is under programmatic control and pin positions aren't
    /// recomputed per-frame.
    var disambiguationCandidates: [MarkCandidate] = []
    /// The tapped dot to zoom onto (rigNode-local). When nil, falls back to the
    /// primary candidate's anchor for backward compatibility.
    var focusPoint: SIMD3<Float>? = nil
    /// Which candidate is currently highlighted (its box brightened). Owned by
    /// the parent so it survives navigation (Back returns to the same focus).
    var focusedRegion: String? = nil
    /// A tap on an unfocused candidate (region box or side label) → focus it.
    var onCandidateFocused: ((String) -> Void)? = nil
    /// A tap on the already-focused candidate → drill into its exercises.
    var onCandidateSelected: ((String) -> Void)? = nil
    /// Bumped by the parent when returning from the pushed exercise list, to
    /// re-apply the zoom + re-project the labels: a covered SCNView pauses
    /// rendering and its projected anchors go stale, so the scene must be
    /// re-driven when it becomes visible again (Phase C back-restores-zoom).
    var refocusToken: Int = 0

    @State private var rig: BodyRig
    @State private var dragActive = false
    @State private var cameraZ: CGFloat
    @State private var committedCameraZ: CGFloat
    /// Mirrors `rig.isLoaded`/`rig.loadFailed` in @State so SwiftUI actually
    /// re-renders once the background OBJ parse finishes — `rig` is a class,
    /// so mutating its stored properties alone wouldn't invalidate the view.
    @State private var isLoading = true
    @State private var scnView: SCNView?
    @State private var pinPositions: [String: CGPoint] = [:]
    @Environment(\.colorScheme) private var colorScheme

    private let minCameraZ: CGFloat = BodyRig.defaultCameraDistance * 0.62         // closer  = zoomed in
    private let maxCameraZ: CGFloat = BodyRig.freeExploreCameraDistance * 1.25      // farther = zoomed out

    private var isFocused: Bool { !disambiguationCandidates.isEmpty }

    init(facing: BodyFacing,
         style: BodyModelStyle = .skin,
         marks: [String: BodyMark] = [:],
         onRegionTap: ((String, SIMD3<Float>) -> Void)? = nil,
         disambiguationCandidates: [MarkCandidate] = [],
         focusPoint: SIMD3<Float>? = nil,
         focusedRegion: String? = nil,
         onCandidateFocused: ((String) -> Void)? = nil,
         onCandidateSelected: ((String) -> Void)? = nil,
         refocusToken: Int = 0) {
        self.facing = facing
        self.style = style
        self.marks = marks
        self.onRegionTap = onRegionTap
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

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading 3D model…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if rig.loadFailed {
                ContentUnavailableView(
                    "3D Model Unavailable",
                    systemImage: "figure.stand",
                    description: Text("The body model couldn't be loaded.")
                )
            } else {
                SceneKitContainer(scene: rig.scene, pointOfView: rig.cameraNode,
                                  onTap: tapHandler,
                                  onViewReady: { scnView = $0 })
                    .gesture(rotationGesture, including: isFocused ? .none : .all)
                    .simultaneousGesture(zoomGesture, including: isFocused ? .none : .all)
                    .overlay(alignment: .top) {
                        Text("Drag to rotate")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.top, 6)
                            .opacity(dragActive || isFocused ? 0 : 0.85)
                            .animation(.easeInOut(duration: 0.2), value: dragActive)
                    }
                    .overlay {
                        if isFocused {
                            CandidateRailOverlay(
                                candidates: disambiguationCandidates,
                                anchors: pinPositions,
                                focusedRegion: focusedRegion,
                                onTap: handleCandidateTap
                            )
                            .transition(.opacity)
                        }
                    }
            }
        }
        .onAppear {
            rig.snap(to: facing.rotationY)
            rig.cameraNode.position.z = Float(cameraZ)
        }
        .task(id: ObjectIdentifier(rig)) {
            // Off the main thread inside BodyMeshLoader; hops back to the
            // main actor only to attach the finished node. `id:` re-runs this
            // if `rig` itself is ever replaced (it currently isn't post-init,
            // but keeps this correct if that changes).
            await rig.loadIfNeeded()
            rig.updateMarks(marks)          // persisted marks show on first load
            rig.addDebugHitboxesIfEnabled()
            isLoading = false
        }
        .onChange(of: facing) { _, newFacing in
            rig.snap(to: newFacing.rotationY)
        }
        .onChange(of: disambiguationCandidates) { _, newCandidates in
            guard !newCandidates.isEmpty else {
                pinPositions = [:]
                rig.clearCandidates()
                rig.hideMuscleLayer()       // restore skin, fade the muscle layer out
                rig.resetCamera(distance: cameraZ)
                return
            }
            applyFocus(for: newCandidates)
        }
        .onChange(of: focusedRegion) { _, newFocus in
            // Re-tint the muscle highlight when the focused candidate changes;
            // camera stays put (the dot is still the frame subject).
            guard !disambiguationCandidates.isEmpty else { return }
            rig.showCandidates(disambiguationCandidates,
                               focused: newFocus ?? disambiguationCandidates.first?.name)
        }
        .onChange(of: refocusToken) { _, _ in
            // Returned from the exercise list — re-drive the paused SCNView and
            // recompute the (now-stale) projected label anchors.
            guard !disambiguationCandidates.isEmpty else { return }
            applyFocus(for: disambiguationCandidates)
        }
        .onChange(of: marks) { _, newMarks in
            rig.updateMarks(newMarks)
        }
        .onAppear { applyBackground() }
        .onChange(of: colorScheme) { _, _ in applyBackground() }
    }

    /// SCNScene renders opaque white behind the mesh by default, which reads
    /// as a jarring flash of light content in dark mode — so this keys the
    /// scene background to the same dynamic surface colour as the rest of
    /// the screen and re-applies it whenever the app's colour scheme flips.
    private func applyBackground() {
        let trait = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        rig.scene.background.contents = UIColor(Color.luminaSurface).resolvedColor(with: trait)
    }

    // MARK: - Tap → region resolution

    /// While focused (disambiguation), taps hit-test the revealed muscle mesh so
    /// tapping a highlighted muscle on the body selects it directly. Otherwise,
    /// taps mark — but only when a region-tap callback is installed, so plain
    /// viewing never pays for hit-testing.
    private var tapHandler: ((CGPoint, SCNView) -> Void)? {
        if isFocused {
            return { point, view in handleCandidateHitTest(at: point, in: view) }
        }
        guard onRegionTap != nil else { return nil }
        return { point, view in handleTap(at: point, in: view) }
    }

    /// Raycasts the revealed muscle geometry; the nearest hit whose muscle node
    /// (or face-zone fallback dot) maps to one of the CURRENT candidates routes
    /// to the focus/select decision. Skin hits are skipped (they map to nothing),
    /// so tapping the translucent skin over a candidate still selects the muscle.
    private func handleCandidateHitTest(at point: CGPoint, in view: SCNView) {
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue as NSNumber])
        let candidateNames = Set(disambiguationCandidates.map(\.name))
        for hit in hits {
            guard let nodeName = hit.node.name else { continue }
            if nodeName.hasPrefix("cand-dot:") {
                let name = String(nodeName.dropFirst("cand-dot:".count))
                if candidateNames.contains(name) { handleCandidateTap(name); return }
            } else if let match = MuscleNodeNames.matchingCandidate(forNode: nodeName,
                                                                    among: candidateNames) {
                handleCandidateTap(match)
                return
            }
        }
    }

    /// First tap on a candidate focuses/highlights it; a second tap on the
    /// already-focused candidate drills into its exercises. Shared by the
    /// on-body region boxes and the side-rail labels.
    private func handleCandidateTap(_ name: String) {
        if focusedRegion == name {
            onCandidateSelected?(name)
        } else {
            onCandidateFocused?(name)
        }
    }

    /// Zooms onto the tapped dot, reveals the muscle layer with each candidate
    /// highlighted, and projects the label anchors once the dolly settles. Shared
    /// by the initial confirm and the return-from-navigation re-focus. The camera
    /// dolly starts immediately; the muscle layer (lazily parsed on first use)
    /// fades in once loaded, under the same ease.
    private func applyFocus(for candidates: [MarkCandidate]) {
        guard let primary = candidates.first else { return }
        rig.focus(on: focusPoint ?? primary.point) {
            projectPinPositions(for: candidates)
        }
        Task {
            await rig.loadMuscleLayerIfNeeded()
            rig.showCandidates(candidates, focused: focusedRegion ?? primary.name)
            rig.revealMuscleLayer()
        }
    }

    /// Re-projects each candidate's rigNode-local anchor to on-screen points
    /// via `SCNView.projectPoint`, once the focus dolly animation completes
    /// (camera + rig are static then, so a single projection stays correct
    /// for as long as the popup is showing).
    private func projectPinPositions(for candidates: [MarkCandidate]) {
        guard let scnView else { return }
        var positions: [String: CGPoint] = [:]
        for candidate in candidates {
            let world = rig.rigNode.convertPosition(
                SCNVector3(candidate.point.x, candidate.point.y, candidate.point.z), to: nil)
            let projected = scnView.projectPoint(world)
            positions[candidate.name] = CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
        }
        withAnimation(.easeIn(duration: 0.2)) {
            pinPositions = positions
        }
    }

    /// Stage 1: raycast the skin mesh (marker dots are excluded explicitly,
    /// so the first non-marker hit is the occlusion-correct surface point).
    /// Stage 2: convert the world hit point to rigNode-local (normalized
    /// model space, rotation factored out) and resolve it with pure math.
    private func handleTap(at point: CGPoint, in view: SCNView) {
        guard let onRegionTap else { return }
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue as NSNumber])
        guard let hit = hits.first(where: { !isMarkerNode($0.node) }) else { return }
        let local = rig.rigNode.convertPosition(hit.worldCoordinates, from: nil)
        let normalized = SIMD3(Float(local.x), Float(local.y), Float(local.z))
        if let region = MuscleHitResolver.regionName(at: normalized, in: BodyHitVolumes.all) {
            onRegionTap(region, normalized)
            // Warm the muscle layer now: a successful region tap means a Confirm
            // (→ reveal) is likely next, and parsing the 13MB mesh takes ~2.7s.
            // Preloading during the read-and-confirm gap makes the reveal feel
            // instant instead of popping in seconds after the camera dolly.
            // Idempotent — the actual reveal's loadMuscleLayerIfNeeded no-ops.
            Task { await rig.loadMuscleLayerIfNeeded() }
        }
    }

    private func isMarkerNode(_ node: SCNNode) -> Bool {
        sequence(first: node, next: \.parent).contains(rig.marksNode)
    }

    // MARK: - Gestures

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                dragActive = true
                rig.applyDragRotation(deltaX: value.translation.width)
            }
            .onEnded { value in
                dragActive = false
                rig.commitDragRotation(deltaX: value.translation.width)
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                // magnification > 1 = pinch out (zoom in) -> move camera closer.
                let proposed = committedCameraZ / value.magnification
                cameraZ = min(max(proposed, minCameraZ), maxCameraZ)
                rig.cameraNode.position.z = Float(cameraZ)
            }
            .onEnded { _ in
                committedCameraZ = cameraZ
            }
    }
}

// MARK: - Candidate rail overlay

/// The disambiguation labels, pushed to whichever screen edge has more room
/// (away from the dot's cluster), each larger than the old on-body capsules and
/// connected to its muscle region by a thin leader line. The label's colour dot
/// matches its on-body highlight box. Tapping a label focuses that region;
/// tapping the focused one again drills into its exercises.
private struct CandidateRailOverlay: View {
    let candidates: [MarkCandidate]
    let anchors: [String: CGPoint]
    let focusedRegion: String?
    let onTap: (String) -> Void

    private let labelWidth: CGFloat = 156
    private let rowGap: CGFloat = 54
    private let edgeInset: CGFloat = 86

    private struct Placement: Identifiable {
        var id: String { name }
        let name: String
        let index: Int
        var center: CGPoint
        var leaderStart: CGPoint
    }

    var body: some View {
        GeometryReader { geo in
            let placements = layout(in: geo.size)
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    for p in placements {
                        guard let anchor = anchors[p.name] else { continue }
                        let focused = p.name == focusedRegion
                        var path = Path()
                        path.move(to: p.leaderStart)
                        path.addLine(to: anchor)
                        ctx.stroke(path,
                                   with: .color(CandidatePalette.color(p.index).opacity(focused ? 0.95 : 0.5)),
                                   style: StrokeStyle(lineWidth: focused ? 1.7 : 1.2,
                                                      dash: focused ? [] : [2, 3]))
                        let r: CGFloat = focused ? 5 : 3.5
                        ctx.fill(Path(ellipseIn: CGRect(x: anchor.x - r, y: anchor.y - r,
                                                        width: r * 2, height: r * 2)),
                                 with: .color(CandidatePalette.color(p.index)))
                    }
                }
                .allowsHitTesting(false)   // let taps fall through to the 3D boxes

                ForEach(placements) { p in
                    label(for: p).position(p.center)
                }
            }
        }
    }

    private func label(for p: Placement) -> some View {
        let focused = p.name == focusedRegion
        let color = CandidatePalette.color(p.index)
        return Button { onTap(p.name) } label: {
            HStack(spacing: 7) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(p.name)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(width: labelWidth, alignment: .leading)
            .background(focused ? AnyShapeStyle(color.opacity(0.18))
                                : AnyShapeStyle(.regularMaterial),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(focused ? color : Color.clear, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(focused ? "\(p.name) — view exercises"
                                    : "\(p.name) — highlight region")
    }

    /// Places labels in a column on the emptier side and spaces them so they
    /// don't overlap, each sitting at (roughly) its anchor's height.
    private func layout(in size: CGSize) -> [Placement] {
        let present = candidates.enumerated().compactMap { i, c -> (Int, MarkCandidate, CGPoint)? in
            anchors[c.name].map { (i, c, $0) }
        }
        guard !present.isEmpty else { return [] }

        let avgX = present.map(\.2.x).reduce(0, +) / CGFloat(present.count)
        let railRight = avgX < size.width / 2
        let centerX = railRight ? size.width - edgeInset : edgeInset

        // Desired Y = anchor Y, then de-overlap top→bottom and clamp to frame.
        let ordered = present.sorted { $0.2.y < $1.2.y }
        var ys: [CGFloat] = []
        var lastY = -CGFloat.greatestFiniteMagnitude
        let topLimit = rowGap / 2 + 8
        for item in ordered {
            var y = max(item.2.y, lastY + rowGap)
            y = max(y, topLimit)
            lastY = y
            ys.append(y)
        }
        // Pull the stack up if it overran the bottom.
        let bottomLimit = size.height - rowGap / 2 - 8
        if let last = ys.last, last > bottomLimit {
            let shift = last - bottomLimit
            ys = ys.map { max(topLimit, $0 - shift) }
        }

        return ordered.enumerated().map { row, item in
            let (index, cand, _) = item
            let cy = ys[row]
            let leaderX = railRight ? centerX - labelWidth / 2 : centerX + labelWidth / 2
            return Placement(name: cand.name, index: index,
                             center: CGPoint(x: centerX, y: cy),
                             leaderStart: CGPoint(x: leaderX, y: cy))
        }
    }
}

// MARK: - Preview

#Preview("Skin") {
    BodySceneView(facing: .front, style: .skin)
        .frame(height: 520)
}
