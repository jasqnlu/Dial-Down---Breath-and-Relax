# Task 2 Report: `export_skin_muscle.py`

## What was done

Created `Tools/blender/export_skin_muscle.py`, a new Blender export script for
the skin-covered Body Map pivot. It selects and emits two layers into one OBJ:
a single welded `BodySkin` shell (from the 296 patches in collection
`9: Regions of human body`) plus the muscle objects from
`4: Muscular system` (classified via `classify_group`/`classify_head`/
`classify_face_zone`). The `3: Joints` collection is untouched — no joint
geometry is exported by this script.

## Adapted verbatim from `export_anatomy.py`

- `blender_to_app` coordinate conversion
- `world_aabb`
- The whole-body normalization block (`mesh_objects` list, `extract_center`,
  `extract_scale`, `extracted_boxes`, `apply_recentre_correction` call)
- `to_app_space`
- `sanitize`
- The OBJ-emission loop structure: decimate-modifier add/remove,
  `evaluated_get`/`to_mesh`, vertex/normal/triangle emission, node-map +
  layer-count bookkeeping, and file writes.
- The `flip = determinant < 0` per-object winding-reversal logic (kept as-is
  for muscle objects).

## Written fresh for this task

- **Skin-prep prologue** (new): un-excludes collection
  `9: Regions of human body` from the view layer via a recursive
  `find_layer_collection` helper (needed because excluded collections' objects
  aren't selectable/joinable), selects and `bpy.ops.object.join()`s its 296
  mesh patches, renames the result to `BodySkin`, then runs
  `bmesh.ops.remove_doubles(dist=0.0015)` → `holes_fill(sides=0)` →
  `recalc_face_normals`, writing the result back via `bm.to_mesh()`. This runs
  *before* the whole-body normalization bounds are computed, so `BodySkin` —
  now a real mesh object in the scene — is included in the `mesh_objects` list
  used for those bounds, per the brief.
- **Collection/selection rewrite**: the original's `COLLECTIONS` list (three
  collections: muscle/joint/headSkin) is replaced with two explicit
  selections — the single `BodySkin` object tagged `{"layer": "skin"}`, and
  `4: Muscular system` members tagged via a new `classify_muscle()` helper
  (inlined from the original's `classify_object` muscle branch; the
  joint/headSkin branches were dropped since this export doesn't touch either).
- **Skin winding exemption**: in the emission loop, `flip` is now
  `tags["layer"] != "skin" and determinant < 0` — `BodySkin`'s post-join
  normals are already consistent from `recalc_face_normals`, so it's exported
  without the per-object flip regardless of its determinant, exactly as the
  brief specifies. Muscle objects keep the original determinant-based flip.
- Output paths changed to `Tools/blender/generated/BodySkinMuscle.obj` and
  `Tools/blender/generated/skinmuscle_node_names.json`.
- Import list trimmed to what's actually used (`classify_group`,
  `classify_head`, `classify_face_zone`, `apply_recentre_correction`,
  `NON_ANATOMICAL`) — `classify_joint` is not imported since joints aren't
  exported here.

## Verification

```
python3 -m py_compile Tools/blender/export_skin_muscle.py
```
→ **clean, no output, exit 0.**

Per the task brief, this is the full acceptance bar for Task 2 — the script
depends on `bpy`/`bmesh` and a loaded Blender scene, so it cannot be executed
standalone outside Blender. Running it against the real 79MB `.blend` file is
a later task in the plan.

## Commit

Only `Tools/blender/export_skin_muscle.py` was staged and committed. This
report file, which previously held stale content from an unrelated earlier
task, was overwritten with this report but is not part of the Task 2 commit
(per the brief's file scope: only the one new script file).

Commit message: `feat(blender): export_skin_muscle preps + exports welded skin + muscle layers`

Commit hash: `71d07ba` (full: `71d07bae74864fc12e953d808ba222087c8439b5`)
