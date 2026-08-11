# Pose glyph icons for Home tab exercise cards

**Status:** Approved, ready for implementation planning
**Scope:** `TodayView`'s `ForYouCard` and `RecommendedCarousel`/`RecommendedCard` (Home tab)

## Problem

Every exercise card on the Home tab reuses one of two generic SF Symbols
(`figure.mind.and.body` for stretches, `wind` for breathing exercises) inside
a tinted box. All 217 exercises look identical at a glance — there's no
per-pose visual identity, so the cards read as filler rather than content.
Reference apps in this space (Stretchit-style pose pickers, Apple Fitness+)
solve this with small circle-badged pose icons that are legible at ~60pt and
distinct per exercise.

The app's 3D Blender animation pipeline already solves the *hero* media
moment (detail view, session player) and is out of scope here — this is
about the *browsing* moment, where a full video is too heavy and a single
reused icon says nothing.

## Decision: hand-authored stick-figure glyphs, not generated art

Two art-sourcing options were evaluated and rejected:

- **AI-generated illustration (ComfyUI, local)** — the user's Mac has 16GB
  unified RAM; the available model (Z-Image Turbo, ~20GB combined weights)
  thrashed swap to near-exhaustion on a single test generation and fp8
  quantization isn't supported on Apple's MPS backend. Not viable on this
  hardware without either freeing significant RAM or downloading a smaller
  model — not worth the fragility for an ongoing content pipeline.
- **Licensed/purchased icon pack** — deferred; introduces a licensing and
  asset-pipeline dependency for no clear benefit over the option below.

**Chosen approach:** a minimal line stick-figure glyph, hand-authored as
SwiftUI `Path` data, reusing the shape of the app's existing (currently
unused) `StickJoint`/`ExercisePose` model — a 15-joint, 14-bone skeleton in
normalized 0–1 figure coordinates that was built for an earlier stick-figure
animation feature and never populated with data. This repurposes that
scaffold's *idea* (named joints, normalized coordinates) rather than its
literal types, since a static per-archetype icon needs far fewer keyframes
than a full animation.

Validated in a throwaway HTML/SVG mockup against a filled-silhouette
alternative (see conversation) — the stick glyph stayed legible at 64–96pt
badge size where a filled body silhouette needs real illustration skill to
avoid reading as a blob at that size. Style was iterated to:

- Each limb (both arms, both legs) is a single continuous `Path` per chain
  with `stroke-linejoin: round` so bends don't leave a visible seam.
- A small filled circle at every joint (shoulder, elbow, hip, knee, plus a
  larger one for the head) reinforces connectivity and doubles as an honest
  preview of where real joint coordinates anchor.
- Every archetype has all four limbs present and clearly separated —
  no merged/overlapping limbs reading as a blob.
- Seated archetypes get a flat rounded-rect "seat" bar under the hips,
  drawn behind the figure, in the category color at ~28% opacity.
- Badge: 96pt circle, tinted `ExerciseCategory.accentColor` at ~16% opacity
  background, figure stroked in the full-opacity accent color. This mirrors
  the existing tinted-icon-box language already used in `RecommendedCard`
  and `ForYouCard`, just with a real pose instead of a generic symbol.

## Data model

### `PoseArchetypeID`

A `String`-backed enum (or plain `String` keyed dictionary — decide during
implementation based on how many archetypes end up needed) naming each
distinct pose silhouette. Initial taxonomy, derived from scanning all 217
seed exercise names for position/orientation keywords (Seated / Standing /
Supine / Kneeling / Prone / Side-Lying / quadruped) crossed with the primary
movement (fold, twist, side-bend, lunge, reach, roll):

| Archetype | Example exercises |
|---|---|
| `standingNeutral` | default standing stretches (arm-across-chest, wrist stretches performed standing) |
| `standingForwardFold` | Standing Hamstring Stretch, Standing Forward Fold (Ragdoll) |
| `standingSideBend` | Standing Side Reach/Bend, Crescent Moon Side Stretch |
| `standingTwist` | Standing Reach-Through Twist |
| `standingLunge` | Low Lunge, Kneeling Hip-Flexor Lunge (standing variant), Couch Stretch |
| `standingQuad` | Standing Quad Stretch (foot held behind) |
| `standingArmOverhead` | Overhead Triceps/Lat Stretch with Strap |
| `standingArmAcrossChest` | Cross-Body Rear Delt/Elbow Pull, Doorway stretches |
| `seatedNeutral` | Wrist/forearm stretches performed seated |
| `seatedTwist` | Seated Spinal Twist, Seated Spinal Rotation with Overhead Reach |
| `seatedForwardFold` | Seated Forward Fold, Seated Hamstring Stretch |
| `seatedFigureFour` | Seated Figure-Four, Seated Butterfly Stretch |
| `seatedNeck` | Seated Neck Rolls, Neck Rotation/Flexion/Extension |
| `kneelingNeutral` | Kneeling Chest Stretch on Chair, Kneeling Abdominal Stretch |
| `kneelingLunge` | Kneeling Hip-Flexor Lunge |
| `quadruped` | Cat-Cow Flow, Thread the Needle, Bird-dog-style |
| `supineNeutral` | Legs Up the Wall, Pelvic Tilt |
| `supineKneeToChest` | Knee-to-Chest Release, Happy Baby Pose |
| `supineTwist` | Supine Spinal Twist (Windshield Wipers) |
| `supineFigureFour` | Supine Figure-4 Stretch |
| `bridge` | Bridge Pose |
| `prone` | Cobra Stretch, Sphinx Pose |
| `childsPose` | Child's Pose |
| `pigeon` | Pigeon Pose |
| `downwardDog` | Downward-Facing Dog |
| `headMicro` | Jaw/eye/temple/scalp releases — head-and-shoulders only, no full body |
| `breathSeated` | All `.breath`-type exercises — seated, hands resting on knees |

~26 archetypes. Expect small additions/merges once all 217 names are
actually run through the classifier during implementation — this table is
the starting taxonomy, not a hard final count.

Each archetype defines:
- an ordered set of named joint points in **0–1 normalized figure space**
  (head, neck, shoulders ×2, elbows ×2, hands ×2, hip, knees ×2, feet ×2 —
  a subset of `StickJoint.all` is fine; not every archetype needs every
  named joint, e.g. `headMicro` only needs head/neck/shoulders),
- the bone chains connecting them (drawn as joined `Path` per limb, per the
  validated style above),
- a `hasSeat: Bool` flag,
- a canonical left/right orientation (see mirroring below).

### Mirroring for lateralized exercises

130 of the 217 exercises are lateralized ("Left Seated Spinal Twist" /
"Right Seated Spinal Twist"). Rather than authoring two archetypes per pose,
each archetype is authored once in a canonical orientation; the renderer
mirrors it horizontally (`x' = 1 - x`, applied as a `.scaleEffect(x: -1)` or
equivalent path transform) when the exercise name's laterality doesn't match
the archetype's canonical side. This halves the authoring burden.

### Exercise → archetype mapping

A pure function, `PoseArchetypeID.resolve(for exercise: Exercise) -> (id: PoseArchetypeID, mirrored: Bool)`,
implemented as:

1. A keyword classifier over `exercise.name` (position words × movement
   words, per the taxonomy table) covering the large majority of names
   mechanically.
2. A manual override dictionary (keyed by `exercise.seedID`, the stable seed
   identifier already used by `SeedMigrator`) for names that don't parse
   cleanly — compound/unusual poses like "World's Greatest Stretch",
   "Cossack Squat Stretch", "Couch Stretch".
3. A fallback to `standingNeutral` (or `breathSeated` for `.breath` type)
   for anything unmatched, so no exercise ever renders without an icon —
   mirrors the existing pattern of `ExerciseMediaCard` rendering nothing
   rather than a broken placeholder when data is missing, but here we
   always have *something* to show since the category tint alone still
   differentiates cards.

A test (`PoseArchetypeMappingTests` or similar) asserts every exercise in
`SeedData.json` resolves to a defined archetype ID, catching typos/regressions
as new exercises get added.

## Component

`PoseGlyphIcon: View` — takes an `Exercise` (or directly an archetype ID +
category, for previewing), resolves via the mapping function, and renders:

```
ZStack {
    Circle().fill(category.accentColor.opacity(0.16))
    if archetype.hasSeat {
        RoundedRectangle(...).fill(category.accentColor.opacity(0.28))
    }
    PoseGlyphPath(archetype: archetype, mirrored: mirrored)
        .stroke(category.accentColor, style: StrokeStyle(lineWidth: ..., lineCap: .round, lineJoin: .round))
    ForEach(archetype.joints) { joint in
        Circle().fill(category.accentColor).frame(...)  // joint dots, including the larger head dot
    }
}
.frame(width: 96, height: 96)  // or whatever size the call site needs, badge scales proportionally
```

Sized to fit its call site (the mockup used 96pt; `ForYouCard`'s existing
110pt-tall media slot and `RecommendedCard`'s 60×60pt icon box are both
smaller/different aspect ratios, so the component takes an explicit size
rather than hardcoding 96pt).

## Integration points

- **`ForYouCard`** (`ForYouSection.swift`): replace the generic
  `Image(systemName:)` block with `PoseGlyphIcon(exercise: exercise, category: ...)`.
  `ForYouCard` doesn't currently carry a category — needs
  `ExerciseCategory.categories(for: exercise.targetBodyParts).first` (or a
  similar single-category resolution) added alongside.
- **`RecommendedCard`** (`ForYouSection.swift`): already carries
  `item.category` — swap the `Image(systemName: icon)` block for
  `PoseGlyphIcon(exercise: item.exercise, category: item.category)`,
  keeping the existing 60×60pt circle sizing.
- **`.breath`-type exercises**: still resolve through the same component
  (via the `breathSeated` archetype) rather than keeping the separate
  `"wind"` SF Symbol special-case, so the two card types don't have two
  different icon systems to maintain.

Out of scope for this spec (explicitly deferred, not forgotten):
`ExerciseListView`'s node-graph browser, the session player, and the
`heroCard`/`programCard` on `TodayView` — those either have a different
interaction model (graph) or already show real media (session player).
Revisit once this lands and reads well.

## Testing

- `PoseArchetypeMappingTests`: every seed exercise resolves to a known
  archetype ID (no silent `nil`/crash); spot-check a handful of known
  lateralized pairs mirror correctly.
- A rendering smoke test (or `#Preview`) enumerating all archetype IDs, to
  catch a malformed `Path` (e.g. an unclosed/mismatched joint reference)
  before it ships.
- Existing `ExerciseMediaTests`/`CuratedContentIntegrityTests` are unaffected
  — this doesn't touch `animationName`/`localVideoName` media resolution.

## Explicitly out of scope

- Populating the real `ExercisePose`/`posesData` animation model — that
  scaffold stays unused; this spec only borrows its conceptual shape.
- Any new asset pipeline (ComfyUI, purchased icon packs) — ruled out above.
- Body Map (`HumanFigureView`/`SilhouetteShape`) — unrelated, single fixed
  pose, not touched.
