import SwiftUI
import SceneKit
import UIKit

// MARK: - Facing

/// Which way the figure faces in the non-mark browsing UI. Marking ignores this
/// (it freezes whatever rotation the user left the model at).
enum BodyFacing: String, CaseIterable, Identifiable {
    case front = "Front"
    case back  = "Back"
    var id: String { rawValue }
}

// MARK: - Body Rig
//
// Owns the SceneKit scene graph for the single rotatable 3D skin model plus an
// invisible, hit-testable muscle proxy used to resolve marking strokes:
//   scene.rootNode
//     ├─ cameraNode                 (static — never rotates)
//     ├─ key/fill/rim/ambient lights (static, world-fixed)
//     └─ rigNode                    (rotates around Y for the turntable effect)
//          ├─ skinNode              (visible skin mesh, pre-centred + pre-scaled)
//          └─ proxyRoot             (invisible muscle mesh, same normalisation)
//               └─ highlightRoot    (x-ray glow clones of marked muscle nodes)
//
// Both meshes are Z-Anatomy exports normalised to height 2.0 with a bbox-centre
// pivot, so they share a footprint and the proxy's muscle nodes sit exactly
// under the skin. The proxy is fully transparent and depth-independent but still
// hit-testable via `muscleProxyCategory`.
//
// Confirmed empirically from the source OBJ: Y is up, the figure's face points
// toward +Z. Rotation 0 == front, π == back.

final class BodyRig {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let rigNode = SCNNode()

    private(set) var loadFailed = false

    /// Resolved `MuscleGroup` rawValue for each hit-testable proxy child node.
    /// Empty when the muscle OBJ is a single merged object (no per-muscle names) —
    /// marking then falls back to skin position heuristics (see plan Global
    /// Constraints). A named per-muscle re-export enables full accuracy with no
    /// code change.
    private(set) var proxyGroups: [SCNNode: String] = [:]

    /// Category bit isolating the invisible muscle proxy for stroke hit-testing.
    static let muscleProxyCategory: Int = 1 << 4

    /// When true the drag gesture won't rotate the rig (Mark mode freezes the
    /// visible projection so it becomes the drawing surface).
    var rotationLocked = false

    /// Current committed rotation (radians) — updated as the user drags / the
    /// facing picker snaps. Kept here so gesture deltas apply relative to the
    /// last committed value.
    var committedRotationY: CGFloat = 0

    /// Parents the x-ray highlight clones. Lives UNDER `proxyRoot` so clones can
    /// reuse each muscle node's local transform verbatim and stay aligned at
    /// every rotation.
    private let highlightRoot = SCNNode()
    private weak var proxyRoot: SCNNode?
    private var shownHighlights: [String: UIColor] = [:]

    private static let skinResourceName   = "BodyMale"
    private static let muscleResourceName = "BodyMuscle"

    init() {
        setUpCamera()
        setUpLights()
        scene.rootNode.addChildNode(rigNode)
        loadBody()
        loadMuscleProxy()
    }

    /// Framing distance for the height-2.0 body: sits a touch back from the frame
    /// so the model doesn't crowd the floating tab bar. Pinch adjusts from here.
    static let defaultCameraDistance: CGFloat = 2.28
    static let freeExploreCameraDistance: CGFloat = defaultCameraDistance * 1.18

    private func setUpCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zNear = 0.1
        camera.zFar = 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, Float(BodyRig.freeExploreCameraDistance))
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setUpLights() {
        func directional(_ intensity: CGFloat, _ pos: SCNVector3) -> SCNNode {
            let light = SCNLight()
            light.type = .directional
            light.intensity = intensity
            light.color = UIColor.white
            let node = SCNNode()
            node.light = light
            node.position = pos
            node.look(at: SCNVector3(0, 0, 0))
            return node
        }
        scene.rootNode.addChildNode(directional(1000, SCNVector3(3, 4, 5)))
        scene.rootNode.addChildNode(directional(380, SCNVector3(-3, 1, 4)))
        scene.rootNode.addChildNode(directional(260, SCNVector3(0, 2, -5)))

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 180
        ambient.color = UIColor.white
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }

    // MARK: - Mesh loading + caching
    //
    // Each processed mesh is built ONCE per process and cached by name. SwiftUI
    // may reconstruct `BodyRig` on view re-init, and the OBJ read + triangulation
    // is by far the most expensive thing here; caching the finished node and
    // cloning per rig (clones share copy-on-write geometry) keeps that parse off
    // the hot path.
    private static var templateCache: [String: SCNNode] = [:]

    private static func skinMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.isDoubleSided = true
        m.metalness.contents = 0.0
        m.diffuse.contents = UIColor(red: 0.89, green: 0.72, blue: 0.62, alpha: 1)
        m.roughness.contents = 0.7
        return m
    }

    /// Recentre in LOCAL space via pivot (applied before scale), then uniform-
    /// scale to height 2.0 — avoids the order-of-operations trap of combining
    /// position + scale directly. Shared by skin and proxy so they align.
    private static func normalize(_ node: SCNNode) {
        let (bmin, bmax) = node.boundingBox
        let center = SCNVector3((bmin.x + bmax.x) / 2,
                                (bmin.y + bmax.y) / 2,
                                (bmin.z + bmax.z) / 2)
        let height = CGFloat(bmax.y - bmin.y)
        let scale = height > 0 ? Float(2.0 / height) : 1
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        node.scale = SCNVector3(scale, scale, scale)
    }

    private static func loadOBJ(_ resource: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "obj"),
              let source = try? SCNScene(url: url, options: [.checkConsistency: true])
        else { return nil }
        let wrapper = SCNNode()
        for child in source.rootNode.childNodes { wrapper.addChildNode(child) }
        normalize(wrapper)
        return wrapper
    }

    private static func applyMaterial(_ material: SCNMaterial, to node: SCNNode) {
        node.geometry?.materials = [material]
        for child in node.childNodes { applyMaterial(material, to: child) }
    }

    /// Make every geometry-bearing node transparent, depth-independent, and
    /// hit-testable via `muscleProxyCategory`.
    private static func applyProxyMaterial(to node: SCNNode) {
        if let geometry = node.geometry {
            let m = SCNMaterial()
            m.transparency = 0
            m.writesToDepthBuffer = false
            m.readsFromDepthBuffer = false
            geometry.materials = [m]
            node.categoryBitMask = muscleProxyCategory
        }
        for child in node.childNodes { applyProxyMaterial(to: child) }
    }

    private static func skinTemplate() -> SCNNode? {
        if let cached = templateCache[skinResourceName] { return cached }
        guard let node = loadOBJ(skinResourceName) else { return nil }
        applyMaterial(skinMaterial(), to: node)
        templateCache[skinResourceName] = node
        return node
    }

    private static func proxyTemplate() -> SCNNode? {
        let key = muscleResourceName + "+proxy"
        if let cached = templateCache[key] { return cached }
        guard let node = loadOBJ(muscleResourceName) else { return nil }
        applyProxyMaterial(to: node)
        templateCache[key] = node
        return node
    }

    private func loadBody() {
        guard let template = BodyRig.skinTemplate() else {
            loadFailed = true
            return
        }
        rigNode.addChildNode(template.clone())
    }

    private func loadMuscleProxy() {
        guard let template = BodyRig.proxyTemplate() else {
            // No proxy: marking still works via the skin fallback path.
            #if DEBUG
            print("[BodyMap] muscle proxy unavailable — marking uses coarse fallback only")
            #endif
            return
        }
        let root = template.clone()
        rigNode.addChildNode(root)
        root.addChildNode(highlightRoot)
        proxyRoot = root
        buildProxyGroups(root)
        #if DEBUG
        if proxyGroups.isEmpty {
            print("[BodyMap] muscle proxy is a merged mesh (no per-muscle names) — marking uses coarse fallback only")
        }
        #endif
    }

    /// Resolve each proxy child (by Z-Anatomy name + local X) to a `MuscleGroup`.
    /// Merged single-object exports resolve to nothing → coarse fallback.
    private func buildProxyGroups(_ root: SCNNode) {
        root.enumerateChildNodes { node, _ in
            guard node.geometry != nil, let name = node.name else { return }
            let (bmin, bmax) = node.boundingBox
            let localX = (bmin.x + bmax.x) / 2
            if let group = MuscleNameResolver.group(forNodeName: name, localX: localX) {
                proxyGroups[node] = group.rawValue
            }
        }
    }

    // MARK: - X-ray highlights

    /// Rebuild the glow layer to exactly `groups` (rawValue → colour). Diffed so
    /// unchanged marks don't churn the scene graph.
    func setHighlights(_ groups: [String: UIColor], resolver: (SCNNode) -> String?) {
        if groups.count == shownHighlights.count,
           groups.allSatisfy({ shownHighlights[$0.key]?.isEqual($0.value) == true }) {
            return
        }
        shownHighlights = groups
        highlightRoot.childNodes.forEach { $0.removeFromParentNode() }
        guard !groups.isEmpty else { return }

        for (node, _) in proxyGroups {
            guard let group = resolver(node), let color = groups[group] else { continue }
            let clone = node.clone()
            clone.geometry = node.geometry?.copy() as? SCNGeometry
            let m = SCNMaterial()
            m.lightingModel = .constant
            m.diffuse.contents = color
            m.emission.contents = color
            m.transparency = 0.55
            m.isDoubleSided = true
            m.writesToDepthBuffer = false
            m.readsFromDepthBuffer = false
            clone.geometry?.materials = [m]
            clone.categoryBitMask = 0
            clone.renderingOrder = 100
            highlightRoot.addChildNode(clone)
        }
    }

    // MARK: - Rotation

    func applyDragRotation(deltaX: CGFloat) {
        guard !rotationLocked else { return }
        let radiansPerPoint: CGFloat = 0.012
        rigNode.eulerAngles.y = Float(committedRotationY + deltaX * radiansPerPoint)
    }

    func commitDragRotation(deltaX: CGFloat) {
        guard !rotationLocked else { return }
        let radiansPerPoint: CGFloat = 0.012
        committedRotationY += deltaX * radiansPerPoint
        rigNode.eulerAngles.y = Float(committedRotationY)
    }

    /// Snap to the nearest equivalent of `target` (0 = front, π = back) via the
    /// shortest angular path.
    func snap(to target: CGFloat) {
        guard !rotationLocked else { return }
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

// MARK: - Markable Body View
//
// A UIViewRepresentable SCNView (SwiftUI's SceneView exposes no hitTest). It
// handles BOTH free rotation/zoom (browse) and draw-to-mark, switched by
// `markMode`. While marking, each touch-moved point is unprojected through the
// invisible muscle proxy into a MuscleGroup (or a coarse skin fallback), and a
// transient CAShapeLayer shows the live ink in the selected sensation colour.

struct MarkableBodyView: UIViewRepresentable {
    let rig: BodyRig
    var markMode: Bool
    /// Colour of the live-ink preview while drawing.
    var inkColor: UIColor
    /// Called per sampled point while marking, with the resolved group (or nil).
    var onStrokePoint: (MuscleGroup?) -> Void
    var onStrokeEnded: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = rig.scene
        view.pointOfView = rig.cameraNode
        view.rendersContinuously = true
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling2X

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePinch(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        context.coordinator.scnView = view
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.parent = self
        rig.rotationLocked = markMode
        context.coordinator.inkLayer.strokeColor = inkColor.withAlphaComponent(0.55).cgColor
        if !markMode { context.coordinator.clearInk() }
    }

    final class Coordinator: NSObject {
        var parent: MarkableBodyView
        weak var scnView: SCNView?

        private var committedCameraZ: CGFloat = BodyRig.freeExploreCameraDistance
        private let minCameraZ = BodyRig.defaultCameraDistance * 0.62
        private let maxCameraZ = BodyRig.freeExploreCameraDistance * 1.25

        private var inkPoints: [CGPoint] = []
        lazy var inkLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 22
            layer.lineCap = .round
            layer.lineJoin = .round
            layer.strokeColor = parent.inkColor.withAlphaComponent(0.55).cgColor
            return layer
        }()

        init(_ parent: MarkableBodyView) { self.parent = parent }

        // MARK: Pan — rotate (browse) or draw (mark)

        @objc func handlePan(_ gr: UIPanGestureRecognizer) {
            guard let view = scnView else { return }
            if parent.markMode {
                let point = gr.location(in: view)
                switch gr.state {
                case .began:
                    inkPoints = [point]
                    if inkLayer.superlayer == nil { view.layer.addSublayer(inkLayer) }
                    resolve(point, in: view)
                case .changed:
                    inkPoints.append(point)
                    updateInk()
                    resolve(point, in: view)
                case .ended, .cancelled, .failed:
                    clearInk()
                    parent.onStrokeEnded()
                default:
                    break
                }
            } else {
                let dx = gr.translation(in: view).x
                switch gr.state {
                case .changed: parent.rig.applyDragRotation(deltaX: dx)
                case .ended, .cancelled: parent.rig.commitDragRotation(deltaX: dx)
                default: break
                }
            }
        }

        // MARK: Pinch — camera zoom (both modes)

        @objc func handlePinch(_ gr: UIPinchGestureRecognizer) {
            switch gr.state {
            case .changed:
                let proposed = committedCameraZ / gr.scale
                let z = min(max(proposed, minCameraZ), maxCameraZ)
                parent.rig.cameraNode.position.z = Float(z)
            case .ended, .cancelled:
                committedCameraZ = CGFloat(parent.rig.cameraNode.position.z)
            default:
                break
            }
        }

        // MARK: Stroke resolution

        private func resolve(_ point: CGPoint, in view: SCNView) {
            // 1) Prefer a named muscle proxy hit.
            let proxyHits = view.hitTest(point, options: [
                .categoryBitMask: BodyRig.muscleProxyCategory,
                .searchMode: SCNHitTestSearchMode.all.rawValue,
                .ignoreHiddenNodes: false,
            ])
            if let raw = proxyHits.lazy.compactMap({ self.parent.rig.proxyGroups[$0.node] }).first {
                parent.onStrokePoint(MuscleGroup(rawValue: raw))
                return
            }
            // 2) Fall back to a coarse group from where the stroke hit the skin.
            let skinHits = view.hitTest(point, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue,
            ])
            guard let hit = skinHits.first else {
                parent.onStrokePoint(nil)
                return
            }
            // World → rig-local removes the turntable rotation; the mesh is
            // height-2 centred so y ∈ [-1, 1] → unit y ∈ [0, 1].
            let local = parent.rig.rigNode.presentation.convertPosition(hit.worldCoordinates, from: nil)
            let unit = SIMD3<Float>(local.x, (local.y + 1) / 2, local.z)
            parent.onStrokePoint(MuscleNameResolver.fallbackGroup(unitPoint: unit))
        }

        // MARK: Live ink

        private func updateInk() {
            let path = UIBezierPath()
            guard let first = inkPoints.first else { return }
            path.move(to: first)
            for p in inkPoints.dropFirst() { path.addLine(to: p) }
            inkLayer.path = path.cgPath
        }

        func clearInk() {
            inkPoints = []
            inkLayer.path = nil
        }
    }
}
