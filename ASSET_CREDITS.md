# Asset Credits & Third-Party Licenses

This file records the third-party assets bundled in **Breath: Relax & Stretch**
and the license terms they carry. It exists because the app's 3D anatomy model —
and every animation rendered from it — is a derivative of a copyleft-licensed
work whose terms require attribution and share-alike.

> **Not legal advice.** This is a developer's good-faith record of asset
> provenance, not an attorney's opinion.

---

## 1. Z-Anatomy (3D anatomy atlas)

[![CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)

**"Z-Anatomy — The libre 3D atlas of anatomy — CC-BY-SA 4.0"**
https://creativecommons.org/licenses/by-sa/4.0/

Built on **"BodyParts3D — The Database Center for Life Science —
CC-BY-SA 2.1 Japan"**, © Kousaku Okubo / DBCLS.
https://dbarchive.biosciencedbc.jp/en/bodyparts3d/download.html

Note both layers of the chain are **ShareAlike**. (An earlier revision of this
repo's export scripts recorded BodyParts3D as plain CC-BY 4.0; that was wrong
and has been corrected in `Tools/blender/export_*.py` and in the generated
`.obj` headers.)

### Authors credited by Z-Anatomy

| | |
|---|---|
| Kousaku OKUBO | Original model (BodyParts3D) |
| Gauthier KERVYN | Design, 3D, anatomy |
| Marcin ZIELINSKI | Blender add-on |
| Lluis VINENT | Unity development |
| Ana Teresa BIGIO | Portuguese translation of anatomical structures |
| Carlos TORRES VILLAR | Spanish translation of anatomical structures |
| Paola Perin, Daniele Cossellu, Elisa Vivado | Italian translation |
| Jadwiga Palosz | Polish translation |
| Shariar Ahmadpour | Parsi translation |

### What this app does NOT use

Z-Anatomy's attribution file lists reference models under more restrictive
terms — notably *"Anatomy of the Inner Ear"* (CC-BY-NC-SA 4.0) and *"Kidney"*
by Lissie Cowley (CC-BY-NC 4.0), both **NonCommercial** — plus Brainder /
White matter (Univ. of Washington) and Cranial Nerves and Foramina
(Univ. of Dundee, CC-BY 4.0).

**None of that geometry is in this app.** The export pipeline extracts only the
skin shell and skeletal muscles: `skinmuscle_node_names.json` contains 269
nodes across exactly two layers (`skin`, `muscle`), with no inner-ear,
kidney, brain, or nerve structures. This matters beyond tidiness — the
NonCommercial terms would be incompatible with the app's paid tiers.

Z-Anatomy's textual definitions (Wikipedia, CC-BY-SA 3.0) are also unused;
this app ships its own exercise copy.

### What in this repo derives from Z-Anatomy

All of the following are **derivative works** distributed under **CC BY-SA 4.0**:

| Path | What it is |
|---|---|
| `Breath - Relax & Stretch/Resources/Models3D/BodySkinMuscle.obj` | Welded skin shell + 268 named muscle objects, re-exported and normalized to app model space |
| `Breath - Relax & Stretch/Resources/Models3D/*.obj` | Other exported anatomy meshes |
| `Breath - Relax & Stretch/Resources/skinmuscle_node_names.json` | Muscle node → group/layer tag map, keyed on Z-Anatomy object names |
| `Breath - Relax & Stretch/Resources/musclegroup_hitboxes.json` | Hit-box bounds derived from Z-Anatomy object AABBs |
| **`Breath - Relax & Stretch/Resources/Animations/*.mp4`** | **Baked exercise demonstration loops — rendered frame-by-frame from the anatomy mesh above** |
| `Tools/blender/generated/exercises/**` | Intermediate `.glb` / `.blend` / PNG frame sequences behind those mp4s |

The `.mp4` loops are the easiest case to overlook: they contain no mesh data,
but they are *renderings of* the CC BY-SA mesh, which makes each one a
derivative work in its own right.

### Modifications made

ShareAlike requires indicating changes. The anatomy source was modified by:

- Welding the scattered skin patches into a single closed shell
- Decimating muscle geometry for real-time mobile rendering
- Discarding non-anatomical scene-organisation helpers (label anchors, pin
  markers, reference planes) — see `Tools/blender/muscle_classification.py`
- Re-normalizing to app model space (Y-up, +Z-forward, height 2)
- Bucketing anatomical objects into the app's 40 `MuscleGroup` categories
- Building a 12-bone humanoid armature, skinning the meshes to it, and posing
  and rendering it to produce the exercise animation loops

The full, reproducible transformation pipeline is committed under
`Tools/blender/` — see `export_skin_muscle.py`, `export_anatomy.py`,
`export_muscle_obj.py`, and `exercises/_lib.py`.

---

## 2. Manrope (typeface)

The Lumina design system (`Views/Theme/LuminaFonts.swift`) uses **Manrope**,
licensed under the **SIL Open Font License 1.1** — https://openfontlicense.org

---

## 3. Everything else

The application source code, exercise text content, breathing patterns, and the
Lumina design system are original to this project. No third-party runtime
dependencies are vendored; Supabase is spoken over raw `URLSession`.

---

## Attribution requirements when redistributing

If you fork or redistribute anything built from the anatomy assets or
animations above, CC BY-SA 4.0 obliges you to:

1. **Credit** Z-Anatomy and upstream BodyParts3D / DBCLS (§1)
2. **Link** to the CC BY-SA 4.0 license text
3. **State that changes were made** (§ "Modifications made")
4. **License your derivative under CC BY-SA 4.0** as well

### On open-sourcing the application

CC BY-SA 4.0 **permits commercial use**, so a paid app is compatible with it
provided attribution and share-alike are honored on the assets.

The Z-Anatomy maintainers additionally ask that applications released using
their models be open source. Note the distinction: ShareAlike binds
*adaptations of the licensed work* — the meshes, and renderings of them such
as this app's `.mp4` loops — and has no linking or "derivative program" clause
of the kind GPL uses, so it does not automatically relicense application source
code that merely bundles the assets. Creative Commons itself
[recommends against using CC licenses for software](https://creativecommons.org/faq/#can-i-apply-a-creative-commons-license-to-software)
for exactly this reason.

**This project is open source regardless**, which satisfies both the license's
requirements and the maintainers' stated wish. The distinction is recorded here
only so it is understood rather than re-derived if the project is ever
relicensed.
