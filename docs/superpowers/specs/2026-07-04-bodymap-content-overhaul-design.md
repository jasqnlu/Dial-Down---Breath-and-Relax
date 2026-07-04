# Body Map 2.0 + Content & UX Overhaul — Design

**Date:** 2026-07-04
**Status:** Approved by Jason (all sections)

## Goals

1. Remove the Muscle and Skeleton body-map layers entirely; one body map remains (3D skin model).
2. Marking works on the *current rotation* of the 3D model: the frozen projection at whatever
   angle the user rotated to is the drawing surface. Hitboxes are real anatomical muscles.
3. ~40 major muscle groups, each markable and each backed by exercises.
4. Bend-style onboarding: mini survey interleaved with stretching-facts cards, new users only.
5. Expand exercise library so every muscle group has ≥3 exercises (~120+ new seed exercises).
6. Remove stick-figure animations and YouTube embeds; placeholder slot for Jason's self-filmed
   local videos.
7. Breathing circle plays a one-cycle preview of the selected pattern when tapped before a
   session starts.
8. Fix page titles that truncate or sit oddly (audited via simulator screenshots, SE width).
9. Each feature on its own branch.

## 1. Body map rework (`feature/bodymap-3d-marking`)

### Removals
- `BodyLayer` picker UI in `BodyMapView`; `BodyLayer` enum shrinks to internal styling helper or
  is deleted where possible (kept in `BodyPart` @Model only for SwiftData schema stability).
- `SkeletonAnatomyCanvas.swift`, `MuscleAnatomyCanvas.swift`, skeleton/muscle branches of
  `BodyModelStyle`, `BodySkeleton.obj` from the rendered-layers path.
- The normalized-rect region grid: `frontRegions`, `backRegions`, `handFingerRegions`,
  `toeRegions`, `faceFrontFineRegions` in `HumanFigureView.swift`, and `BodyFigureCanvas`'s
  rect-based marking. The 2D silhouettes (`MaleSilhouetteShape` etc.) and their detail
  canvases are deleted (onboarding uses chips, not a body figure — see §2).
- `AnnotationStore` 2D stroke persistence (strokes were front/back-aligned ink; obsolete).

### New marking architecture
- **Mark mode freezes the current rotation.** Entering Mark disables the rotation gesture and
  keeps the camera where the user left it (no snap to front/back). The visible render *is* the
  2D projection being drawn on.
- **Invisible muscle hit-proxy.** The muscle mesh loads into the same rig as the skin, scaled
  and centred identically (both Z-Anatomy exports normalise to height 2.0 with bbox-centre
  pivot, so they align). Its material is fully transparent and it does not write color, but it
  IS hit-testable. Muscle sub-nodes carry their Z-Anatomy object names.
- **Stroke → muscle resolution.** Each stroke point (screen coords) goes through
  `SCNView.hitTest` (category mask = muscle proxy). Hit node name → lookup in a
  `muscleName → MuscleGroup` mapping table → that group is marked with the selected sensation
  color. Points that miss muscle but hit skin fall back to a position-based coarse region
  (Head / Left Hand / Right Hand / Left Foot / Right Foot) computed from the hit's local-space
  coordinates on the skin mesh.
- **X-ray highlight.** A marked group's muscle nodes are cloned into a highlight layer:
  `readsFromDepthBuffer = false`, higher `renderingOrder`, translucent sensation color.
  Highlights are 3D, so they remain correct at every rotation — no per-facing ink to persist.
- **Persistence.** `markedMuscles: [String: String]` (group id → sensation color id) stored in
  UserDefaults (same key style as `bodymap.markedRegions`, with a one-time migration from the
  old region names via the mapping in §3).
- **Toolbar.** Pen/eraser stay (eraser removes groups its stroke crosses). Undo removes the
  most recently added group-mark. Legend sheet stays.
- **Find Exercises.** Marked group names feed `BodyPartExercisesView` unchanged; exercises use
  the new muscle-group vocabulary (§3).

### Muscle groups (~40)
Neck (front/back), Trapezius L/R, Deltoid front/side/rear L/R (grouped as Shoulder L/R with
three sub-heads mapped in), Chest L/R, Biceps L/R, Triceps L/R, Forearm flexors L/R, Forearm
extensors L/R, Abs, Obliques L/R, Lats L/R, Spinal erectors, Lower back, Glutes L/R, Hip
flexors L/R, Adductors L/R, Quads L/R, Hamstrings L/R, Calves L/R, Tibialis L/R, plus coarse
fallbacks Head, Hand L/R, Foot L/R. Exact list finalised in the mapping table during
implementation, driven by what the Z-Anatomy export names provide.

### Jason's Blender export (prerequisite for full accuracy)
Re-export the muscular system from the Z-Anatomy .blend **without joining objects**:
select the muscular-system collection → File ▸ Export ▸ Wavefront (.obj) → check
"Selection Only", **uncheck any "join/merge objects" option**, keep "Object Groups" /
"OBJ Objects" enabled so each muscle exports as its own named `o` block; same scale/transform
settings as the previous export (the code re-normalises anyway). Replace
`Resources/Models3D/BodyMuscle.obj`. **Until then**, the app builds and runs against the
current merged OBJ using the skin-fallback path only (head/hands/feet + nearest-group-by-
position heuristic disabled); the named export switches full accuracy on with no code change.

## 2. Onboarding survey + facts (`feature/onboarding-survey`)

- Extends the existing `OnboardingView` pager, new users only (existing completed-onboarding
  flag untouched).
- Flow: Welcome → Q1 goal (flexibility / pain relief / stress / posture / sleep) → fact card →
  Q2 problem areas (multi-select chips grouped by body area) → fact card → Q3 current
  flexibility self-rating → fact card → Q4 stretch frequency today → Q5 preferred time of day →
  existing gender / goals / notifications pages merge in where redundant (goal page replaces
  `GoalPickerPage`).
- Fact cards: full-screen, one stat + one-line source citation, consistent visual treatment.
  5–6 facts written into a static array; no network.
- Answers persist to `UserProfile`; problem areas pre-mark body-map muscle groups; preferred
  time pre-fills the notification-permission page's suggested reminder.

## 3. Exercise library expansion (`feature/exercise-library`)

- `SeedData.json` grows from 64 to ~190 exercises: every muscle group in §1 gets ≥3 stretches
  (mix of difficulties; breathing exercises unchanged). Each has name, type, targetBodyParts
  (new vocabulary), duration, difficulty, instructions (4–7 steps), caution where warranted.
- Old→new name migration table (e.g. "Left Hamstring" → "Hamstrings L", "Upper Back" →
  "Trapezius"/"Lats" as appropriate) applied to: seed re-import, saved
  `bodymap.markedRegions`, user-created exercises (left untouched — old names remain valid
  search keys via the table).
- **Removals:** `StickFigureView.swift`, `VideoSource.swift`, `VideoPreviewCard.swift`, pose
  editing in `CreateExerciseView`, `ExercisePose` usage (model file + `posesData` field stay
  for schema stability, unused).
- **Placeholder slot:** `ExerciseDetailView` hero becomes a "Video coming soon" card driven by
  a new optional `localVideoName` on `Exercise` (bundle-relative file name; when non-nil and
  the file exists, an `AVPlayer` loop plays in the hero).

## 4. Breathing preview (`feature/breathing-preview`)

- In `BreathingView`, when `!isRunning`: tapping the circle runs ONE demo cycle of the selected
  pattern (scale up over inhale duration, hold, scale down over exhale, phase label text),
  then returns to idle. No session recording, no haptics/voice cues. Tapping mid-preview
  cancels. A small "Tap circle to preview" caption shows when idle.
- Implementation: a lightweight `previewPhase` state machine reusing the existing
  phase-duration data; guarded so Start during preview cancels the preview cleanly.

## 5. Page title fixes (`fix/page-titles`)

- Screenshot audit of every page at iPhone SE and 15 Pro widths using the documented
  simulator/launch-arg workflow.
- Fixes applied per page, favouring: shorter titles ("Export My Data" → "Export Data"),
  `.navigationBarTitleDisplayMode` consistency (top-level tabs `.large`, pushed pages
  `.inline`), and `minimumScaleFactor`/layout tweaks for headers that still collide with
  toolbar items.

## 6. Branch & merge order

1. `feature/exercise-library` (vocabulary everything else depends on)
2. `feature/bodymap-3d-marking`
3. `feature/onboarding-survey`
4. `feature/breathing-preview` (independent)
5. `fix/page-titles` (independent)

Each branch: build + Swift Testing suite green + simulator screenshot verification before
merge to main.

## Error handling

- Muscle OBJ missing / merged (no named nodes): marking still works via skin fallback; a
  debug-only console note records reduced accuracy. No user-facing error.
- Local video name set but file missing: placeholder card shows (never a broken player).
- Seed migration runs once, guarded by a version key; unknown old names pass through
  unchanged.

## Testing

- Unit (Swift Testing): muscle name→group mapping totality (every expected Z-Anatomy name
  resolves), old→new exercise-name migration, seed JSON decodes + every muscle group has ≥3
  exercises, breathing preview state machine transitions.
- Simulator verification: launch-arg-driven screenshots of body map (mark mode at an oblique
  rotation), exercise detail placeholder, onboarding survey pages, breathing preview mid-cycle,
  and every audited title page.
