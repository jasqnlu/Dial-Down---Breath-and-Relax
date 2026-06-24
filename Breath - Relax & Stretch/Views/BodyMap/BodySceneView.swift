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

final class BodyRig {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let rigNode = SCNNode()

    private(set) var loadFailed = false

    /// Current committed rotation (radians) — updated as the user drags / the
    /// facing picker snaps. Kept here (not just on the node) so gesture deltas
    /// can be applied relative to the last committed value.
    var committedRotationY: CGFloat = 0

    init() {
        setUpCamera()
        setUpLights()
        scene.rootNode.addChildNode(rigNode)
        loadBody()
    }

    /// Distance that makes the (height-normalised-to-2.0) body fill ~94% of
    /// the vertical frame — matching SilhouetteShape's own near-edge-to-edge
    /// fill, so BodyRegion's normalised rects (tuned for the 2D silhouette)
    /// land in roughly the right place when overlaid on this 3D render.
    static let defaultCameraDistance: CGFloat = 2.28

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

    /// The processed body mesh, built exactly ONCE per process. SwiftUI
    /// reconstructs `BodyRig` on every `BodySceneView` re-init (facing flips,
    /// entering/leaving Mark mode, every frame of a pinch while marking), and
    /// the OBJ read + triangulation is by far the most expensive thing here.
    /// Caching the finished node and cloning it per rig — clones share the
    /// underlying geometry copy-on-write — keeps that parse off the main thread
    /// on every re-init instead of re-reading the ~950KB mesh each time.
    private static let templateBodyNode: SCNNode? = makeTemplateBodyNode()

    private static func makeTemplateBodyNode() -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "BodyMale", withExtension: "obj"),
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

        applySkinMaterial(to: bodyNode)
        return bodyNode
    }

    private func loadBody() {
        guard let template = BodyRig.templateBodyNode else {
            loadFailed = true
            return
        }
        // A node lives in one parent at a time, so each rig adds its own clone
        // of the shared template (geometry is shared, transforms are fresh).
        rigNode.addChildNode(template.clone())
    }

    private static func applySkinMaterial(to node: SCNNode) {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents  = UIColor(red: 0.89, green: 0.72, blue: 0.62, alpha: 1)
        material.roughness.contents = 0.7
        material.metalness.contents = 0.0
        material.isDoubleSided = true

        if let geometry = node.geometry {
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applySkinMaterial(to: child)
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

    /// False while marking on the Skin layer: rotation locks to the current
    /// facing (front/back) so the overlaid tap-region grid stays aligned,
    /// and the outer 2D pinch/pan system takes over zoom instead.
    var interactive: Bool = true

    @State private var rig = BodyRig()
    @State private var dragActive = false
    @State private var cameraZ: CGFloat = BodyRig.defaultCameraDistance
    @State private var committedCameraZ: CGFloat = BodyRig.defaultCameraDistance

    private let minCameraZ: CGFloat = BodyRig.defaultCameraDistance * 0.62   // closer  = zoomed in
    private let maxCameraZ: CGFloat = BodyRig.defaultCameraDistance * 1.4    // farther = zoomed out

    var body: some View {
        ZStack {
            if rig.loadFailed {
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
            if !interactive { resetCamera() }
        }
        .onChange(of: facing) { _, newFacing in
            rig.snap(to: newFacing == .front ? 0 : .pi)
        }
        .onChange(of: interactive) { _, isInteractive in
            if !isInteractive { resetCamera() }
        }
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

#Preview {
    BodySceneView(facing: .front)
        .frame(height: 520)
}
