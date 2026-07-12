import SwiftUI
import SceneKit

// MARK: - Body Rig
//
// Owns the SceneKit scene graph for the rotatable 3D skin model:
//   sceneRoot
//     ├─ cameraNode        (static — never rotates)
//     ├─ keyLight / fillLight / ambientLight  (static, world-fixed)
//     └─ rigNode           (rotates around Y for the turntable effect)
//          └─ bodyNode     (the loaded mesh, pre-centred + pre-scaled)
//
// The mesh ships at native ZBrush export scale with no material/texture, so
// this also recentres it (pivot = bounding-box centre), uniform-scales it to
// a fixed height, and applies a skin-tone PBR material in code.
//
// Confirmed empirically from the source OBJ (see decimation notes): Y is up,
// the figure's face points toward +Z. Rotation 0 == front, π == back.

/// The 3D model style that renders the body. Skin is the only layer now —
/// the mesh is exported from the Z-Anatomy Blender file's ZBrush OBJ.
enum BodyModelStyle {
    case skin

    var resourceName: String {
        switch self {
        case .skin: return "BodyMale"
        }
    }

    /// Programmatic PBR material — the mesh ships without textures, so colour
    /// (skin tone) is applied in code.
    func makeMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.isDoubleSided = true
        m.metalness.contents = 0.0
        switch self {
        case .skin:
            m.diffuse.contents = UIColor(red: 0.89, green: 0.72, blue: 0.62, alpha: 1)
            m.roughness.contents = 0.7
        }
        return m
    }
}

/// Loads and caches the (multi-MB) body OBJ mesh off the main thread. An
/// actor so concurrent loads — e.g. two `BodySceneView`s mounting at once, or
/// a facing flip re-creating the rig mid-load — serialize on the shared
/// template cache instead of racing.
actor BodyMeshLoader {
    static let shared = BodyMeshLoader()

    private var cache: [String: SCNNode] = [:]

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

        let (bmin, bmax) = bodyNode.boundingBox
        let center = SCNVector3((bmin.x + bmax.x) / 2,
                                 (bmin.y + bmax.y) / 2,
                                 (bmin.z + bmax.z) / 2)
        let height = CGFloat(bmax.y - bmin.y)
        let scale = height > 0 ? Float(2.0 / height) : 1

        // Recentre in LOCAL space via pivot (applied before scale), then scale —
        // this avoids the order-of-operations trap of combining position+scale directly.
        bodyNode.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        bodyNode.scale = SCNVector3(scale, scale, scale)

        applyMaterial(style.makeMaterial(), to: bodyNode)
        return bodyNode
    }

    private static func applyMaterial(_ material: SCNMaterial, to node: SCNNode) {
        if let geometry = node.geometry {
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applyMaterial(material, to: child)
        }
    }
}

final class BodyRig {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let rigNode = SCNNode()
    let style: BodyModelStyle

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
        // Mesh loading is kicked off asynchronously by BodySceneView (see
        // `loadIfNeeded`) instead of here — parsing the OBJ is too heavy to
        // do synchronously on the main thread during View init.
    }

    /// Distance that makes the (height-normalised-to-2.0) body fill ~94% of
    /// the vertical frame — matching SilhouetteShape's own near-edge-to-edge
    /// fill, so BodyRegion's normalised rects (tuned for the 2D silhouette)
    /// land in roughly the right place when overlaid on this 3D render.
    /// **Load-bearing** for tap-region alignment: only used while marking
    /// (rotation locked, overlay shown). Free-rotate uses the larger distance
    /// below so the figure sits a little smaller in the frame.
    static let defaultCameraDistance: CGFloat = 2.28

    /// Default framing when freely rotating (no tap-region overlay). Pulled
    /// ~18% further back than the aligned distance so the model doesn't crowd
    /// the frame / floating tab bar. Safe to change — no overlay depends on it.
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
        rigNode.addChildNode(template.clone())
        isLoaded = true
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

// MARK: - Body Scene View

struct BodySceneView: View {
    let facing: BodyFacing

    /// Which anatomy layer to render. Skin, muscle, and skeleton are all real
    /// rotatable 3D models now; only the loaded mesh + material differ.
    var style: BodyModelStyle = .skin

    /// False while marking: rotation locks to the current facing (front/back)
    /// so the overlaid tap-region grid stays aligned, and the outer 2D
    /// pinch/pan system takes over zoom instead.
    var interactive: Bool = true

    @State private var rig: BodyRig
    @State private var dragActive = false
    @State private var cameraZ: CGFloat
    @State private var committedCameraZ: CGFloat
    /// Mirrors `rig.isLoaded`/`rig.loadFailed` in @State so SwiftUI actually
    /// re-renders once the background OBJ parse finishes — `rig` is a class,
    /// so mutating its stored properties alone wouldn't invalidate the view.
    @State private var isLoading = true
    @Environment(\.colorScheme) private var colorScheme

    private let minCameraZ: CGFloat = BodyRig.defaultCameraDistance * 0.62         // closer  = zoomed in
    private let maxCameraZ: CGFloat = BodyRig.freeExploreCameraDistance * 1.25      // farther = zoomed out

    init(facing: BodyFacing, style: BodyModelStyle = .skin, interactive: Bool = true) {
        self.facing = facing
        self.style = style
        self.interactive = interactive
        _rig = State(initialValue: BodyRig(style: style))
        // Marking starts at the alignment-calibrated distance; free-rotate
        // starts pulled back so the figure sits a touch smaller in frame.
        let start = interactive ? BodyRig.freeExploreCameraDistance : BodyRig.defaultCameraDistance
        _cameraZ = State(initialValue: start)
        _committedCameraZ = State(initialValue: start)
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
                SceneView(scene: rig.scene, pointOfView: rig.cameraNode, options: [.rendersContinuously])
                    .gesture(rotationGesture)
                    .simultaneousGesture(zoomGesture)
                    .overlay(alignment: .top) {
                        if interactive {
                            Text("Drag to rotate")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(.regularMaterial, in: Capsule())
                                .padding(.top, 6)
                                .opacity(dragActive ? 0 : 0.85)
                                .animation(.easeInOut(duration: 0.2), value: dragActive)
                        }
                    }
            }
        }
        .onAppear {
            rig.snap(to: facing == .front ? 0 : .pi)
            // Push the starting distance onto the camera node: the rig builds
            // its camera at the aligned distance, so free-rotate must move it.
            if interactive {
                rig.cameraNode.position.z = Float(cameraZ)
            } else {
                resetCamera()
            }
        }
        .task(id: ObjectIdentifier(rig)) {
            // Off the main thread inside BodyMeshLoader; hops back to the
            // main actor only to attach the finished node. `id:` re-runs this
            // if `rig` itself is ever replaced (it currently isn't post-init,
            // but keeps this correct if that changes).
            await rig.loadIfNeeded()
            isLoading = false
        }
        .onChange(of: facing) { _, newFacing in
            rig.snap(to: newFacing == .front ? 0 : .pi)
        }
        .onChange(of: interactive) { _, isInteractive in
            if !isInteractive { resetCamera() }
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

    /// Restores the calibrated default framing — used whenever the locked
    /// (non-interactive, tap-region-overlay) mode engages, so the body's
    /// on-screen footprint always matches what BodyRegion's rects expect,
    /// regardless of how far the user had pinch-zoomed beforehand.
    private func resetCamera() {
        cameraZ = BodyRig.defaultCameraDistance
        committedCameraZ = BodyRig.defaultCameraDistance
        rig.cameraNode.position.z = Float(BodyRig.defaultCameraDistance)
    }

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard interactive else { return }
                dragActive = true
                rig.applyDragRotation(deltaX: value.translation.width)
            }
            .onEnded { value in
                guard interactive else { return }
                dragActive = false
                rig.commitDragRotation(deltaX: value.translation.width)
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard interactive else { return }
                // magnification > 1 = pinch out (zoom in) -> move camera closer.
                let proposed = committedCameraZ / value.magnification
                cameraZ = min(max(proposed, minCameraZ), maxCameraZ)
                rig.cameraNode.position.z = Float(cameraZ)
            }
            .onEnded { _ in
                guard interactive else { return }
                committedCameraZ = cameraZ
            }
    }
}

// MARK: - Preview

#Preview("Skin") {
    BodySceneView(facing: .front, style: .skin)
        .frame(height: 520)
}
