# 3D Anatomy Import: Muscle & Skeleton Layers

## Context

Body Map (`Views/BodyMap/`) is a hybrid 2D/3D system. The **Skin** layer is a real
rotatable SceneKit 3D model (`Resources/Models3D/BodyMale.obj`, decimated to
~15,000 triangles, single programmatic PBR material, no texture). **Muscle** and
**Skeleton** are hand-drawn 2D vector art (`MuscleAnatomyCanvas.swift`,
`SkeletonAnatomyCanvas.swift`), stylized to ~15-20 shapes per facing, clipped to
the existing silhouette outline.

The user has two Z-Anatomy Blender source files to replace the 2D art with real
3D models, matching how Skin already works:
- `~/Blender/Z-AnatomyMuscle.blend`
- `~/Blender/Z-AnatomySkeleton.blend`

Z-Anatomy is a full-body anatomical atlas (CC BY-SA 4.0), not a simple pair of
isolated exports. Both files share one master scene graph (7184 objects, ~4.1M
triangles, 188 materials across dozens of named systems — skeletal, muscular,
cardiovascular, nervous, etc.) and differ only in which collections are toggled
visible in that file's view layer:

- `Z-AnatomySkeleton.blend`: only "Skeletal system" visible — 278 mesh objects,
  ~300K vertices. Clean.
- `Z-AnatomyMuscle.blend`: "Muscular system" + "Muscular insertions" visible,
  but **"Skeletal system" and "Joints" are also visible** — 2079 mesh objects,
  ~1.5M vertices. The extra skeleton/joint geometry is judged to be a leftover
  editing state, not intentional.

The app's tap/mark system (`BodyRegion`, ~22 coarse named rects like "Chest",
"Left Hamstring", used to link marked areas to exercise recommendations) is
completely decoupled from the visual layer — it's an invisible overlay grid
already shared across Skin/Muscle/Skeleton via `BodySceneView(interactive:
false)`. This work is a visual/asset swap, not a rebuild of marking.

## Decisions

1. **Fidelity**: match Skin's existing treatment. Decimate each layer down to a
   single merged low-poly mesh (~15-20K triangles), one flat PBR material per
   layer. Individual muscle/bone names in the source data are discarded — the
   app only needs coarse region tapping, not per-part identification.
2. **Muscle layer scope**: muscles only. Export "Muscular system" +
   "Muscular insertions" collections; exclude the skeleton/joints that are
   also visible in `Z-AnatomyMuscle.blend`.
3. **Skeleton layer scope**: "Skeletal system" collection only (already clean
   in the source file).
4. **Licensing**: add an in-app Credits/Acknowledgments entry crediting the
   Z-Anatomy project, noting CC BY-SA 4.0, alongside the model files.

## 1. Content pipeline (Blender → app bundle)

A one-time Python script run headlessly through Blender
(`/Applications/Blender.app/Contents/MacOS/Blender --background --python ...`),
one pass per source file:

- **Skeleton**: from `Z-AnatomySkeleton.blend`, select the "Skeletal system"
  collection's mesh objects, join into a single mesh object.
- **Muscle**: from `Z-AnatomyMuscle.blend`, select "Muscular system" +
  "Muscular insertions" mesh objects only, join into a single mesh object.
- Apply a Decimate modifier targeting ~15-20K triangles (matching
  `BodyMale.obj`'s existing budget), triangulate, export as OBJ.
- Verify axis convention empirically before trusting it — same
  "find a landmark, confirm orientation" check used for the Skin model.
  `BodySceneView.swift` documents the required convention: Y-up, face toward
  +Z, head at max Y, feet at min Y.
- Output: `Resources/Models3D/BodyMuscle.obj` and `BodySkeleton.obj`, alongside
  the existing `BodyMale.obj`.
- Check the export script into the repo (e.g.
  `Scripts/bodymap-import/export_anatomy.py`) so the pipeline is reproducible
  if the source `.blend` files change. It's a content-authoring tool, not part
  of the app target.

## 2. App integration (SwiftUI/SceneKit)

`BodySceneView.swift`'s `BodyRig` currently hardcodes `"BodyMale"` and a fixed
skin-tone material.

- Generalize `BodyRig` to take the layer as a parameter (`BodyRig(layer:
  BodyLayer)`), picking the OBJ filename (`BodyMale` / `BodyMuscle` /
  `BodySkeleton`) and caching a template node per layer — extending the
  existing "parse once, clone per rig" pattern so switching layers doesn't
  re-parse geometry each time.
- Material becomes layer-driven: reuse the RGB values already defined in
  `BodyLayer.highlightColor`/`accentColor` (muscle red, skeleton off-white/
  grey) as the `physicallyBased` diffuse color, keeping Skin's roughness/
  metalness style as a starting point, adjusted per layer only if a visual
  check calls for it.
- `BodyMapView.swift`: the `if currentLayer == .skin` branches that choose
  between `BodySceneView` and the 2D `BodyFigureCanvas` collapse to always use
  `BodySceneView` for all three layers — free-rotate when not marking, locked
  + tap-region-grid overlay when marking, exactly like Skin already does.
  `showSilhouette` on `BodyFigureCanvas` goes away for the anatomy-art case
  (the tap-region-grid + ink canvas itself is still needed; the old vector art
  it used to render is not).
- No camera-distance recalibration needed in principle: `BodyRig` height-
  normalizes each mesh to 2.0 units regardless of source layer, so
  `BodyRig.defaultCameraDistance` keeps working. Still do a visual alignment
  check per layer/facing (the `debugRegions` flag from the Skin build) since
  Z-Anatomy's proportions could differ slightly from `BodyMale.obj`'s.

## 3. Cleanup + Attribution

- Delete the now-dead 2D vector art: `MuscleAnatomyCanvas.swift`,
  `SkeletonAnatomyCanvas.swift`, and whatever in `AnatomyDrawingHelpers.swift`
  only served them (check for shared helpers `BodyFigureCanvas` still needs
  before deleting).
- Add a small Credits/Acknowledgments entry (in Settings, or an About screen —
  check what exists) crediting the Z-Anatomy project and CC BY-SA 4.0,
  alongside the three model files.

## Out of scope

- Per-muscle/per-bone tap targets or naming (would require preserving
  per-part mesh structure — explicitly declined in favor of matching Skin's
  merged-mesh treatment).
- A female-specific 3D model variant. The existing 2D Muscle/Skeleton canvases
  don't vary by `sex` today (only the silhouette outline and facial features
  do), and Skin already uses one model regardless of the male/female toggle —
  this work keeps that precedent.
- Per-part material coloring using the source file's 188 materials (single
  flat material per layer, matching Skin).
