# Home + Exercises Redesign — Design Spec

**Status:** design agreed via mockup iteration, not yet implemented in Swift.
**Mockups:** `docs/mockups/homepage-redesign-*.html`, `docs/mockups/exercises-graph-to-group-screen.html`,
`docs/mockups/animation-vs-glyph-size-rule.html`, `docs/mockups/category-touch-glyphs-and-customize-roadmap.html`,
`docs/mockups/full-restructure-overview.html`, `docs/mockups/exercise-list-everywhere-and-mini-routine.html`
(chronological — later files supersede earlier ones where they conflict; this doc is the reconciled source of truth).

## Why

Home and the Exercises tab both under-use two things the app already has: a real per-exercise pose icon
system (`PoseGlyphIcon`/`PoseArchetypeLibrary`, shipped on `feature/muscle-layer-reveal`) and a growing
library of real exercise animations (`Exercise.animationName` → `LoopingVideoThumbnail`, ~40/217 exercises
today, target full coverage). Neither is used to its potential: `CategoryNode` in the Exercises graph has no
icon at all, `ExerciseRow`/`BodyPartExercisesView` fall back to a generic gray icon for any exercise without
an animation, and `TodayView`'s hero is a static progress button with no view into what's actually in the
session. This redesign closes those three gaps and adds one new capability (editing today's session before
starting it) without inventing a new visual language — every new piece reuses colors, type, and components
that already exist in `LuminaTheme`/`LuminaFonts`.

## Design system additions

### 1. The animation-vs-glyph size rule

Governs every place an exercise is represented visually, app-wide. Decided by rendered size, not by screen,
not by exercise coverage:

- **≥ ~52px** (list rows, grid tiles, detail/session screens): real `LoopingVideoThumbnail`, once that
  exercise has one. `LoopingVideoThumbnail` is already built for this — bare `AVPlayerLayer`, muted,
  gap-free-looped via `AVPlayerLooper`, torn down on scroll-off, and already honors Reduce Motion by holding
  frame one. No new engineering needed to support this at grid scale.
- **< ~52px** (tab bar icons, chip glyphs, compact wayfinding like the roadmap wave — see below): `PoseGlyphIcon`,
  permanently. Video is illegible at this scale regardless of how complete animation coverage gets.
- **Rollout fallback:** while an exercise has no animation yet, `PoseGlyphIcon` fills the ≥52px slot too —
  this is the *only* place glyph coverage matters, and it shrinks toward zero as animation coverage
  completes. `ExerciseRow`'s current fallback (generic gray box + `figure.mind.and.body` SF Symbol) should
  become `PoseGlyphIcon` instead.

Real numbers behind this, from a one-off audit of `SeedData.json` against `PoseArchetypeMapping.classify`:
**101 of 217 exercises (47%)** resolve to the generic `standingNeutral` archetype and are visually identical
to each other — Shoulder Roll, Doorway Shoulder & Chest Opener, and Standing Back Extension render as the
same glyph today. This is why full animation coverage is the real fix for exercise-level recognition; the
glyph's honest job is category + orientation, not "which exercise is this." Growing `PoseArchetypeLibrary`
past its current 16 archetypes (cheap, no rendering pipeline) is worth tracking separately as a way to
shrink that 47% independent of animation production.

### 2. Category touch-glyphs (new, 8 archetypes)

`CategoryNode` (the 8 top-level circles in `ExerciseGraphView`) currently renders text only — name + count,
no figure. Add one new glyph per `ExerciseCategory` case: a simple standing figure with one arm bent to
touch the body region that category represents (Neck touches its own neck, Back reaches behind to the lower
back, Legs touches the thigh, Arms grips the opposite bicep, etc.), category-tinted like every other glyph
in the system, with a small white-ringed contact dot at the touch point.

This is a **separate glyph family** from `PoseArchetypeLibrary` — those 16 archetypes encode whole-body
stretch positions for one exercise; a category node represents an entire body region, which no single stretch
pose can communicate cleanly. New model: `TouchGlyphArchetype` (shared base skeleton: head, spine, both legs,
one resting arm; per-category: one pointing arm + one contact-point coordinate), 8 entries, one per
`ExerciseCategory` case.

### 3. The roadmap wave

A visual device reused in two places: the Home hero (`TodayView.heroCard`, replacing the current gradient +
breathing-halo + button) and the Customize screen (below). One continuous SVG-equivalent curve
(`Path`/`Shape` in SwiftUI) through `y(t) = mid − amp·cos(t·π·(n−1))`, with each exercise sitting exactly on
the curve at an alternating crest/trough, sized proportional to its real `durationSeconds`. Walking the curve
left to right *is* the session order — it's load-bearing, not decorative.

**Scaling rule for many exercises:** node spacing is fixed (not "fit the whole wave to the card width").
A long routine's wave gets wider and scrolls horizontally (same pattern `ForYouCard`'s row already uses)
rather than compressing — compression would make the wave least legible exactly when a routine has the most
exercises to track. Node size still scales by duration; spacing does not.

**Exception to the size rule:** roadmap nodes stay `PoseGlyphIcon` regardless of size (the Home hero's
crossed 68px in early drafts). Rationale: the roadmap is compact wayfinding/preview, not the primary
browsing surface — the same category tab bar icons get regardless of their pixel size. **This exception was
never explicitly confirmed with the product owner and should be signed off before implementation** (see Open
Questions).

## Screen-by-screen

### TodayView — hero card

Replace the current `heroCard` (gradient background, breathing-halo circles, white pill "Begin" button) with:
eyebrow ("Today's session"), title (`timeOfDayFocus.heroTitle`, unchanged), `sessionExercises.count` +
computed minutes (unchanged), the roadmap wave rendered from `sessionExercises`, and an action row with two
buttons: **Customize** (new, ghost-pill style — mint-tint background, primary-teal text, matches
`LuminaPillButtonStyle.ghost`) and **Begin** (existing, now `LuminaPillButtonStyle.prominent` solid capsule
instead of the current white-pill-on-gradient, since the gradient background goes away — background is now
a quiet `luminaCardFill` with a soft radial gradient wash, not a full saturated fill).

Customize navigates to the new Customize screen (below) with `sessionExercises` as the starting state.

### Customize screen (new)

Presented from the hero's Customize button. Structure, top to bottom:
- Nav bar: X (dismiss) / title (`timeOfDayFocus.heroTitle`, e.g. "Wake Up") / overflow menu (unspecified,
  parity with existing screens that have one).
- Meta line: "N EXERCISES · M MIN".
- **Roadmap** (numbered 1…N, matching the numbered rows below — this is the one place the wave carries
  numeric labels, since here the order is something being actively edited, not just glanced at).
- **Save toggle** ("Keep as my Wake Up routine" / "Starts your day automatically · off = just for today").
  See Data model below for what this actually persists.
- **Numbered exercise list**, each row: index badge, `PoseGlyphIcon` (46–52px, glyph-zone, list context doesn't
  need video here — worth confirming this is intentional, see Open Questions), name, a `−`/`+` duration
  stepper (edits today's timing only, does not persist unless the save toggle is on).
- **Add Exercises**: a small centered dashed pill below the list (not a full-width row — it's an action, not
  a sixth list item), opens the Exercises tab in add-mode (below).
- Bottom: full-width **Begin** pill, same treatment as the hero's.

### Exercises tab — top level (`ExerciseGraphView`)

No structural change to the pinch-zoom mechanics. `CategoryNode` gains the touch-glyph (see above). The
existing persistent search bar (`ExerciseListView.header`/`searchBar`) is unchanged and already does what
"constant search bar" was asking for — the actual gap was downstream (next section).

### Exercises tab — search results and group screen (unify)

Two real screens today render different things for conceptually the same job ("here are some exercises, pick
one"):
- **Search results** (`ExerciseListView.content`, non-empty search): `LazyVStack` of `ExerciseRow`.
- **Group screen** (tap a satellite node → `ExerciseGroupCorpusSheet`, a `.medium/.large` sheet): also a
  `LazyVStack` of `ExerciseRow`.

Replace both with **one grid component**: 2-column tiles, `PoseGlyphIcon`/`LoopingVideoThumbnail` per the
size rule (≥52px art → real animation), name, duration + type. `ExerciseGroupCorpusSheet` should stop being
a `.sheet` and become a real `NavigationStack` push — this fixes two problems at once: the search bar
disappears today when you drill into a group (a sheet has its own `NavigationStack`, doesn't inherit the
parent's header), and a `.medium` sheet doesn't comfortably fit a 19-tile grid (real "Lower Back" count from
`SeedData.json`).

### Add-mode (Customize → Add Exercises)

The *same* grid screen described above, with two additions active only when reached via Add Exercises:
- A mint context banner replacing the normal header ("Adding to [routine name]" + X to cancel).
- Each tile's normal behavior (tap → `ExerciseDetailView`) is replaced by a quick-add `+`/✓ corner button.
- A shopping-list bar pinned above the tab bar: added-count, running total duration, a horizontally
  scrollable chip row (small `PoseGlyphIcon` + duration per added exercise), and a **Done** button that
  returns to Customize with the new exercises folded into the list.

Implementation-wise this is one `selectionMode: .browse | .add` on the shared grid component, not a second
screen — the two modes should never drift apart in layout.

**Unresolved:** does Done *append* the newly-added exercises to the existing list, or *replace* it? Assumed
append when this was mocked; not confirmed.

### Body Map — region exercise list (`BodyPartExercisesView`)

Same grid component again (currently renders `ExerciseRow`, same fallback-icon problem as search results —
fix is identical). New here: **a third tap mode**, distinct from both `.browse` and `.add`:
- Tapping a tile's **`+`** corner adds it to an ad hoc **mini routine** building at the bottom of the screen
  — same visual pattern as the Customize shopping bar, but no name/save step, since nothing named is being
  edited (a lighter bottom bar: count + running time + a **Start** button that jumps straight into
  `SessionPlayerView` with the selected exercises).
- Tapping the **tile itself** (not the `+`) is meant to jump straight into performing *that one exercise* —
  read literally from "click on an exercise directly to do it," interpreted as immediate action, not a detour
  through `ExerciseDetailView` first. **This makes tile-tap behavior inconsistent with every other grid
  context in this spec** (search results and the group screen both keep tap → detail). Needs an explicit
  yes/no before implementation: is "tap = do it now" specific to Body Map's more spontaneous context, or
  should the direct-start behavior (and a smaller secondary "ⓘ" for detail) apply everywhere the grid appears?

## Data model implications

- **`@AppStorage("pinnedWakeUpRoutineID")`** (new, same lightweight pattern as the existing
  `onboardingGoals`/`showStreakEmoji` flags) — when set, points at a `Routine.uuid`. `TodayView.sessionExercises`
  checks this before falling back to `GoalMeta.recommend`. The save toggle on Customize is what sets/clears it;
  ON persists the current list as a real `Routine` (existing model — `name` + `exerciseIDs` already support
  this, no schema change needed there) and sets the pointer; OFF only mutates in-memory state for today's
  `SessionPlayerView`, writes nothing to SwiftData.
- **`ExerciseGroupCorpusSheet`** stops being presented via `.sheet` — becomes a `NavigationDestination` push,
  sharing the parent `NavigationStack` (and therefore its search bar).
- **New shared grid tile view** (name TBD — e.g. `ExerciseGridTile`) replacing `ExerciseRow` at three call
  sites: `ExerciseListView`'s search results, the (now-pushed) group screen, `BodyPartExercisesView`. Needs a
  `selectionMode` (or three-way mode covering `.browse` / `.add` / `.bodyMapMiniRoutine`) to support the
  differing tap behaviors above.
- **`TouchGlyphArchetype`** (new, 8 entries) + rendering, parallel to but separate from
  `PoseArchetypeLibrary`/`PoseGlyphIcon`.
- **`ExerciseRow`'s fallback icon** (`figure.mind.and.body` gray box) → `PoseGlyphIcon`, wherever `ExerciseRow`
  survives (if anywhere, once the grid tile replaces its main call sites).

## Open questions (unresolved, flag before/while implementing)

1. **Roadmap glyph exception.** Nodes on the wave stay `PoseGlyphIcon` regardless of pixel size, breaking the
   general size rule on purpose. Reasoned as acceptable (compact wayfinding, like a tab icon) but never
   explicitly signed off.
2. **Add-mode Done: append or replace** the routine's existing exercise list?
3. **Body Map tile-tap = start immediately** vs. every other grid context's tile-tap = go to detail. Same
   component, different behavior by screen — confirm this is intentional before it ships, and if so, decide
   how the "just show me the info" path still works on Body Map (secondary affordance vs. removed entirely).
4. **Customize's per-row steppers at long-routine length** (10+ exercises) — mocked as read-only duration
   labels with no stepper once a routine gets long; not decided whether that's the real behavior or an
   oversight of the mockup.
5. **Touch-glyph arm angles**, especially `back` (reaching behind the body is an awkward 3-point limb chain to
   draw cleanly) — flagged as possibly needing redraws once seen at real size, not yet reviewed against that
   concern.

## Explicitly out of scope for this spec

- Full animation coverage itself (Blender pipeline work, tracked separately — this spec assumes it's
  happening and designs for the end state).
- Growing `PoseArchetypeLibrary` beyond 16 archetypes to reduce the 47% `standingNeutral` collision — flagged
  as valuable, not scoped here.
- Any change to `SessionPlayerView`'s in-session UI (progress-through-the-wave during an active session was
  discussed as a *possible* future extension of the roadmap concept, never designed).
- Dark mode for any of the above (mockups explored both; TodayView's real default is light, per `LuminaTheme`).
