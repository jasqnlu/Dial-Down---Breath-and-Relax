# Head Zones + Face Exercises — Design

**Date:** 2026-07-17
**Branch context:** `feature/lumina-restyle`
**Status:** Design approved (interaction + catalog); spec pending user review
**Interactive mockup:** https://claude.ai/code/artifact/053b17fe-6371-46e4-b9d5-2144246dce63

## Goal

Split the body map's single coarse `Head` region into distinct, tappable face
zones so users can find exercises for eye strain, jaw/TMJ tension, temple
tension, and forehead tension. Today `Head` is one blob with ~6 loosely-attached
exercises.

## Positioning (hard constraint)

**Evidence-based only.** Every zone and exercise must map to a recognised,
low-risk technique (digital-eye-strain breaks, TMJ physiotherapy, tension-relief
release work). **No anti-wrinkle / "facial fitness" claims** in any copy, exercise
name, or store text — the evidence for facial exercise reducing wrinkles is thin
and creates App Store health-claim risk. Cheeks and Mouth zones were considered
and **deliberately cut** for this reason.

## Zone set

Four zones, registered as sub-heads of the parent `Head` group:

| Zone | Laterality | Region name(s) | Pin colour |
|---|---|---|---|
| Eyes | bilateral | `Left Eye`, `Right Eye` | cyan |
| Temples | bilateral | `Left Temple`, `Right Temple` | indigo |
| Jaw / TMJ | bilateral | `Left Jaw`, `Right Jaw` | blue |
| Forehead | **midline** | `Forehead` | teal |

Seven named regions total (3 bilateral × 2 + 1 midline), but only **four pins**
ever appear on screen — see interaction.

## Interaction

Reuses the existing disambiguation pipeline unchanged (`MarkCandidate` →
`BodyRig.showCandidates` → `projectPinPositions` → `CandidateRailOverlay`).

1. User taps anywhere on the head. `MuscleHitResolver` resolves it to `Head`
   via the existing single Head hit-box (no new hit-boxes).
2. `confirmPendingMark()` (in `BodyMapView.swift`) detects the region is `Head`
   and, instead of building geometric candidates via
   `MuscleHitResolver.candidates(near:)`, injects a **fixed four-pin head set**
   from a new static `headZones` anchor table.
3. **Side is inferred from the tapped x-position.** Tap x ≥ midline → person's
   Left; tap x < midline → person's Right. Bilateral zones use that side;
   `Forehead` is always midline (x ≈ 0). Result: four pins, never seven.
4. Camera focus-dollies onto the head so the four pins have room to fan out.
5. Each pin's anchor `point` is a hand-tuned `SIMD3<Float>` placed accurately
   over the feature (eyes, temples, jaw, mid-forehead), verified tap-by-tap in
   the simulator.
6. Picking a zone resolves to that zone's own exercises, falling back to the
   shared `Head` list when a zone has none — so a tap never dead-ends.

### Known tweaks this forces

- **Candidate cap:** today `confirmPendingMark` uses `prefix(4)` and
  `CandidatePalette` has 4 colours. Four head zones fit the existing cap and
  palette exactly — no extension needed after cutting Cheeks/Mouth. (Had we kept
  six zones, the cap and palette would have needed raising.)
- **Midline handling:** `Forehead` has no side, so it slots into the fan with a
  midline anchor and no Left/Right prefix.

## Data model changes

No SwiftData schema change. `Exercise` already has `targetBodyParts`, `caution`,
`isBilateral`.

1. **`MuscleGroup.muscleHeads` — support midline heads.** Today the builder
   auto-expands every sub-head into `Left`/`Right`. Introduce a small declarative
   head table with a per-entry laterality flag: bilateral entries expand to
   `Left`/`Right` (Eyes, Temples, Jaw); midline entries register as-is
   (`Forehead`). Merge into `muscleHeads` so `parentOfHead(_:)` and
   fall-back-to-parent keep working unchanged.
2. **New static `headZones` anchor table** (name → `SIMD3<Float>` anchor +
   laterality), consumed only by the confirm-step injection. Not a hit-box; a
   display/selection anchor.
3. **`musclegroup_head_hitboxes.json` stays `{}`.** The Blender
   `classify_head_hitboxes.py` script and JSON are **not used** for face zones —
   the anchor-table approach replaces them here.

## Exercise catalog

7 new exercises + 3 re-tags. All graded evidence-backed; `caution` populated
where clinically relevant (jaw group especially).

**Eyes** (`Left Eye` / `Right Eye`, bilateral)
- **20-20-20 Focus Shift** — every 20 min, 20 ft away for 20 s (AOA digital-eye-strain guidance).
- **Eye Palming** *(re-tag existing from `Head`)* — warmed palms over closed eyes; eye rest.
- **Gentle Eye Rolls** — slow full-range eye movement. Caution: stop if dizzy.

**Temples** (`Left Temple` / `Right Temple`, bilateral)
- **Temporalis Release** *(split from existing "Temple & Jaw Release")* — fingertip circles on the temple.
- **Jaw-Open Temporalis Stretch** — slow wide mouth-open lengthens the temporalis (a jaw-closer). Cross-links to Jaw.

**Jaw / TMJ** (`Left Jaw` / `Right Jaw`, bilateral)
- **Resisted Jaw Opening (TMJ)** — light finger resistance under the chin while opening. Standard TMJ PT.
- **Side-to-Side Jaw Glide** — controlled lateral jaw movement.
- **Tongue-Up Controlled Open/Close** — Rocabado-style; tongue on palate, open in pain-free range.
- Caution (all): gentle range only; stop if clicking/pain worsens; see a dentist for diagnosed TMD.

**Forehead** (`Forehead`, midline)
- **Brow & Forehead Smoother** *(from existing "Forehead & Scalp Press Release")* — press-and-glide across the brow.
- **Frontalis Release** — gentle brow-lift-and-hold to relax the forehead.

**Stays general on `Head`** (fall-back list): Lion's Breath, Humming Bee Breath,
Suboccipital Release (shared with `Back Neck`).

## Migration & persistence

- `BodyMarkStore` keys sensations by region name; adding new region names is
  additive and does not invalidate existing `Head` marks (`Head` remains a valid
  region).
- Re-tagged exercises change `targetBodyParts` from `Head` to a specific zone;
  seed migration keys off `seedID`, so renaming/re-tagging is safe.
- New exercises are added to `SeedData.json` with fresh `seedID`s.

## Localization

Add to `Localizable.xcstrings`: the four zone display names (`Left Eye`,
`Right Eye`, `Left Temple`, `Right Temple`, `Left Jaw`, `Right Jaw`, `Forehead`)
and all new exercise names + instruction strings + caution strings.

## Testing

- **Unit — `MuscleHeadTests`** (already scaffolded, untracked): assert the four
  zones are registered in `muscleHeads` with correct parents; bilateral zones
  expand to Left/Right; `Forehead` is midline (no side); `parentOfHead` returns
  `Head` for each.
- **Unit — resolver/injection:** tapping `Head` yields exactly four candidates;
  side inference picks Left vs Right by tap x; back-of-head/scalp taps still
  resolve to plain `Head`.
- **Unit — `SeedDataTests`:** new exercises decode; catalog IDs unique;
  re-tagged exercises point at valid zone names.
- **UI — `verify` skill (XCUITest + screenshots):** tap the head, confirm four
  accurately-placed pins fan out, tap each, confirm the correct zone's exercises
  open. This is also how the anchor constants get tuned.

## Edge cases

- Back-of-head / scalp / crown taps → resolve to `Head`, show the general
  fall-back list (no face pins). Only front/near-front head taps fan out zones.
- Tap exactly on the midline (x ≈ 0) for a bilateral intent → default to one
  side deterministically (e.g. Left); the user can re-tap. `Forehead` is always
  available regardless.
- `prefers-reduced-motion` / focus framing handled by the existing candidate UI.

## Out of scope (separate workstreams, sequenced after this)

1. Body-rotation-after-selection bug.
2. Older-people content pack.
3. Broader exercise safety audit + expansion.
4. Streak / points / leaderboard evolution.
