# 2026-07-12 — Exercise Video & Animation: A Copyright-Clean Content Plan

How to give the 152 seed exercises visual demonstrations (video or animation) without
infringing anyone's copyright, likeness, or license terms. The app already models a
per-exercise `Exercise.localVideoURL` and renders it through `ExerciseMediaCard`
(looping, muted `AVKit.VideoPlayer`) — this plan is about legally *filling* that slot
and, longer term, adding a 3D-animation slot alongside it.

> **Not legal advice.** This is product planning by a developer, not an attorney. Before
> shipping any third-party or licensed asset, have a real IP/media lawyer review the
> specific licenses and releases. Treat everything below as "how the mechanics work,"
> not "you are cleared to ship."

---

## 1. The legal problem, stated plainly

You cannot drop a YouTube clip, an Instagram reel, or a random "free fitness stock"
video into the app. Doing so exposes you to a DMCA takedown, App Store removal, and a
copyright/likeness claim. Here's the actual line between what's protected and what isn't.

### What IS protected (do not copy)
- **The specific video recording** — the fixed audiovisual work. This is the big one.
  A recording of a hamstring stretch is copyrighted *as a recording* even though the
  stretch itself is not.
- **Music / audio** — background tracks, even a few seconds, are separately licensed
  (composition + master recording). This is where most "I found a free clip" claims land.
- **Choreography fixed in a recording** — a *creatively arranged sequence* (think a
  branded yoga flow or a named routine) can be protected as a choreographic work. A
  single functional stretch is not choreography; a distinctive multi-move sequence can be.
- **A specific instructor's likeness / persona** — right of publicity. You need a
  signed release from anyone recognizable on camera, even if you own the footage.
- **Incidental protected material in frame** — branded logos on clothing, wall art,
  posters, a TV playing in the background, a recognizable song audible in the room.

### What is NOT protected (free to use)
- **The idea of a stretch or breathing pattern** — ideas and methods aren't copyrightable.
- **The physical movement itself** — a functional body movement (bend, reach, inhale-hold)
  is not a protected work.
- **Exercise names & functional instructions** — "Standing Quad Stretch," "hold 30s,
  keep your back straight." Short functional phrases and facts aren't protected. (Don't
  copy someone's *expressive* prose verbatim, but the functional cues are yours to write.)
- **Facts about anatomy / target body parts.**

**Bottom line:** you can freely reproduce *the movement and the instruction*. You cannot
reproduce *someone else's recording, music, choreography, or face* without a license/release.

### Accessibility & medical framing (brief but required)
- **ADA / accessibility:** visual demos must not become the *only* way to understand an
  exercise. Keep the text instructions authoritative; video/animation is an aid. Provide
  captions/alt text, respect Reduce Motion (`UIAccessibility.isReduceMotionEnabled`), and
  don't autoplay motion for users who disabled it.
- **Medical disclaimer:** you already ship a `LegalDocumentView`. Any demo implies "do
  this movement" — keep a visible "not medical advice, stop if it hurts, consult a
  professional" disclaimer near exercise content and in the legal docs.

---

## 2. Ranked options for sourcing content

Ranked by copyright-safety **and** fit for a solo dev. Rating scale: 🟢 clean / 🟡 clean
if terms verified / 🔴 legally risky-uncertain.

| # | Option | Safety | Solo-dev cost/effort | You own it? |
|---|--------|--------|----------------------|-------------|
| a | Film original demos yourself / hired model + release | 🟢🟢 | Med time, low $ | Yes |
| d | 3D-animated avatars (rig once, animate many) | 🟢 | Med upfront, low marginal | Yes (with licensed assets) |
| f | Commission animator/illustrator (work-for-hire) | 🟢 | $$ | Yes (if contract says so) |
| e | Procedural / 2D vector / Lottie figures | 🟢 | Low–med | Yes |
| c | Creative Commons / public domain | 🟡 | Low $ | No (must comply w/ license) |
| b | Licensed stock video | 🟡 | Low–med $ | No (license only) |
| g | AI-generated video/animation | 🔴 | Low $, high legal uncertainty | Probably not enforceably |

### (a) Film it yourself / hire a model — the gold standard 🟢🟢
**How it works:** you (or a paid model) perform each movement on camera; you own the
recording outright.
**Cost/effort (solo):** a phone on a tripod, neutral wall, decent daylight, plain
clothing. A model costs a session fee. Batch-shoot 20–40 exercises in a day.
**Paperwork to have on file:**
- **Model release** (perpetual, worldwide, all-media, right to use likeness in the app +
  marketing) from anyone on camera — *including yourself if a co-founder/partner appears.*
- **Work-for-hire / assignment** if you hire a videographer or editor, so *you* own the
  edit, not them. "Work made for hire" language + an explicit copyright assignment as backup.
**Pros:** total ownership, no attribution, no share-alike, reusable in ads. Perfect
loop-friendly control (matches `ExerciseMediaCard`'s muted 16:9 loop).
**Cons:** production time; you must control the frame (no logos/art/music); reshoots.
**Rating:** 🟢🟢 The only route where the film is unambiguously yours.

### (b) Licensed stock video 🟡
**How it works:** buy a license per clip from a reputable library.
**License types to look for / traps:**
- **Royalty-free (RF):** pay once, use many times within license scope. This is what you
  want — but read the scope.
- **Rights-managed (RM):** licensed for a specific use/time/territory; easy to breach in
  an evergreen app. Avoid unless the use exactly matches.
- **"Editorial use only" trap:** cheaper clips are often editorial (news/commentary) and
  **forbidden in a commercial product**. Disqualifying for a paid app.
- **Model-release requirement:** the *library* must warrant a model release exists for any
  recognizable person; confirm it's included, not "buyer's responsibility."
- **Redistribution / "standalone value" clause — the killer:** most stock licenses
  **prohibit use where the clip is the primary value of a product being sold**, or any use
  that lets the end user extract/redistribute the file. A stretching app where the video
  *is* the feature can trip this. You need a license that explicitly permits "use in
  software/apps" and treats the video as a component, not the product. An **Enhanced /
  Extended license** is often required; verify in writing.
**Pros:** fast, cheap per clip, no shoot.
**Cons:** you never own it; evergreen-use + standalone-value clauses are landmines; hard
to get a matched visual set across 152 exercises; files can be extracted from an app bundle.
**Rating:** 🟡 Usable for a *few* hero clips if (and only if) the license explicitly
allows app use as a component and includes model releases. Get the clause reviewed.

### (c) Creative Commons / public domain 🟡
**How it works:** use assets others released under CC or that are public domain.
**License flavors:**
- **CC0 / public domain:** no rights reserved. Cleanest CC option; treat like your own.
- **CC-BY:** free to use commercially **if you attribute** per the license (author, title,
  source, license link). Requires an in-app "Credits" screen and keeping the attribution
  accurate.
- **CC-BY-SA (share-alike) — a trap:** share-alike can require you to license *your
  derivative* under the same terms. **Incompatible with a proprietary, paid app.** Avoid.
- **NC (non-commercial):** your app is monetized → **disqualified.**
- **ND (no-derivatives):** you can't edit/crop/re-encode meaningfully → usually
  impractical.
**The uploader-doesn't-hold-rights risk:** anyone can slap CC0 on a clip they don't own.
CC gives you *no warranty and no indemnity*. If the uploader lied, you're liable. Prefer
reputable sources, verify provenance, keep a screenshot of the license at download time.
**Pros:** free, sometimes CC0-clean.
**Cons:** attribution plumbing; share-alike/NC traps; zero warranty; hard to build a
consistent set.
**Rating:** 🟡 CC0 from a trusted source is fine for filler; anything BY-SA/NC/ND is out.

### (d) 3D-animated avatars — most scalable + copyright-clean 🟢
**How it works:** license/build one (or a few) **rigged generic human model(s)**, then
animate each exercise. Key legal insight: **motion data of a generic functional movement
is not a protected film and depicts no real person's likeness.** You author the motion; you
own the render. This reuses skills the app already has (SceneKit + OBJ body-map pipeline).
**Asset sources & the licensing to check:**
- **Rigged human model:** from a 3D asset marketplace or a free rigged-character/auto-rig
  service. Verify the license permits: commercial use, use in a shipped app, and
  redistribution *as a rendered/baked asset* (most allow renders/animations; some forbid
  redistributing the *raw model file* — you're shipping baked `.usdz`/`.scn`, not the
  source, so confirm that's covered).
- **Motion / animation data:** either (i) hand-key or physics-pose the movements yourself
  (cleanest — you own it), (ii) use a motion-capture library with a commercial license, or
  (iii) markerless mocap from your own reference footage. Verify mocap-library licenses
  allow embedding baked animation in a commercial app.
- **Avoid** models/animations that are recognizable likenesses of real celebrities or
  ripped from games/films.
**Pipeline reuse:** you already load OBJ meshes in SceneKit and have a TODO to convert to
`.usdz/.scn` for bundle size. Same toolchain: author in Blender → export baked skeletal
animation → `.usdz` or `.scn` → play in a `SceneKit`/`RealityKit` view (a sibling to
`ExerciseMediaCard`, driven by a new `animationIdentifier` rather than a video URL).
**Pros:** rig-once/animate-many scales across 152 exercises; consistent art style; tiny,
loop-perfect, no lighting/wardrobe/model-release problems; no real-person likeness; you own
the output; reuses existing 3D competency.
**Cons:** upfront rigging/animation learning curve; "generic avatar" fidelity is lower than
real video for nuanced form; still must vet the base-model + mocap licenses.
**Rating:** 🟢 Best long-term route. Cleanest scalable content you actually own.

### (e) Procedural / 2D vector / Lottie-style figures 🟢
**How it works:** simplified stick-figure or vector figures animated procedurally or via
Lottie/After-Effects JSON, or even SwiftUI-drawn `Canvas`/`TimelineView` loops.
**Pros:** lowest legal risk (you draw it), tiny file size, vector-crisp, Reduce-Motion
friendly, no likeness at all.
**Cons:** lowest fidelity; hard to convey subtle form; still real design work per exercise.
**Rating:** 🟢 Great fallback / accessibility layer / Phase-1 filler. Low risk, low fidelity.

### (f) Commission an animator/illustrator (work-for-hire) 🟢
**How it works:** pay a freelancer to produce the 2D/3D animations.
**Must-haves in the contract:** explicit **work-for-hire + copyright assignment** to you,
warranty that the work is original and clears third-party rights, and that any stock/base
assets *they* used are licensed for your commercial app use (get their license receipts).
**Pros:** professional quality, you own it (if contract is right), offloads the labor.
**Cons:** $$; you inherit *their* sourcing risk unless the warranty/indemnity is solid.
**Rating:** 🟢 Clean if the contract is airtight; it's option (d)/(e) with money instead of time.

### (g) AI-generated video/animation — legally risky/uncertain 🔴
**How it works:** text-to-video / text-to-animation generators produce clips.
**Why it's *not* a clean win (balanced, current as of my knowledge):**
- **Copyrightability:** the U.S. Copyright Office's position is that purely
  AI-generated output **lacks human authorship and is not protectable**. Practical effect:
  you likely **cannot stop competitors from copying** AI clips you ship. Only meaningful
  human-authored contribution (substantial editing, arrangement) may earn thin protection.
- **Training-data infringement risk:** models trained on scraped copyrighted footage are
  the subject of active, unsettled litigation. Output can inadvertently reproduce protected
  elements (a recognizable face, a watermark, a distinctive style). This risk is *yours* if
  you ship it.
- **Provider ToS:** commercial-use rights vary by provider and tier; some grant output
  rights, some don't, some require attribution or forbid certain uses. You must read the
  specific provider's terms and keep a record.
- **Likeness / deepfake risk:** generators can emit realistic faces resembling real people.
**Pros:** fast, cheap, infinite variations.
**Cons:** you probably can't own/enforce it; upstream infringement exposure; ToS
variability; App Store/regulatory scrutiny of AI content is tightening.
**Rating:** 🔴 Treat as experimental only. If used at all, restrict to *reference for a
human-authored redraw*, not shipped output — and get counsel's sign-off.

---

## 3. Recommended path for a solo dev (phased)

Ship value early, keep risk near zero, scale the clean route.

### Phase 1 — Text + static figure (now, zero legal risk)
- Keep the authoritative **text instructions** as the source of truth (accessibility win).
- Add a simple **static illustrated figure or 2D vector pose** per exercise (option e) or
  reuse an `ExercisePose` where one exists. No `localVideoURL` needed yet;
  `ExerciseMediaCard` already renders *nothing* when media is absent, so no blank box.
- **Goal:** every exercise looks complete without any risky content.

### Phase 2 — 3D-avatar animations for the top ~20 exercises (option d, the scalable core)
- License one rigged generic avatar + author looping animations for the ~20 most-used
  stretches/breathing exercises. Export baked `.usdz`/`.scn`.
- **Integration:** rather than overloading `localVideoURL` (which `ExerciseMediaCard` treats
  as an AVKit video), add a parallel optional field, e.g. `Exercise.animationIdentifier:
  String?`, resolved to a bundled/downloaded `.usdz`/`.scn`. `ExerciseMediaCard` (or a new
  `ExerciseAnimationCard` sibling) branches: animation identifier → SceneKit/RealityKit
  player; else video URL → existing AVKit path; else nothing.
- **Why here:** clean ownership, tiny files, consistent style, reuses the SceneKit pipeline.

### Phase 3 — Original filmed video for hero content (option a)
- Film yourself/a released model for a handful of **flagship/marketing** exercises where
  real human form matters most. Populate `localVideoURL` for those — the existing
  `ExerciseMediaCard` loop path lights up with **zero code change**.
- Use these clips in the paywall/App Store screenshots too (you own them → allowed).

> Sequencing rationale: Phase 1 removes the "empty" feeling risk-free; Phase 2 delivers
> scalable owned content across the library; Phase 3 adds premium polish only where real
> video earns its production cost.

---

## 4. Technical integration notes (this codebase)

- **Offline-first constraint → bundle vs. stream.** The app is offline-first over
  URLSession. Two supported patterns:
  - **Bundle** small assets (2D/vector, `.usdz` animations, short compressed loops) in the
    app for guaranteed offline playback.
  - **Download-on-demand + cache** larger filmed video from Supabase storage, cached to
    `Application Support`, with `localVideoURL` pointed at the cached file once present.
    Falls back to text/animation when offline and not yet cached.
- **Bundle-size implications.** You already flag OBJ mesh size (TODO: "usdz/scn bundle-size
  conversion"). Real video is heavy — do **not** bundle 152 clips. Prefer: (1) `.usdz`/`.scn`
  baked animations (kilobytes–low MB, vector-like scaling) bundled; (2) filmed video
  streamed/cached, not bundled; (3) H.265/HEVC, muted, short 3–6s loops, modest resolution
  (the card is 16:9, phone-sized). Consider **On-Demand Resources / asset packs** to keep
  the base install small.
- **Playback layers.**
  - Video: existing `AVKit.VideoPlayer` in `ExerciseMediaCard` (muted, looped via
    `AVPlayerItemDidPlayToEndTime`). Reuse as-is.
  - Animation: `SceneKit` (`SCNView`) or `RealityKit` for `.usdz`; loop the animation
    player. Respect `UIAccessibility.isReduceMotionEnabled` → show a static frame instead.
- **Storage decision — `.usdz`/`.scn` vs video files.** Prefer baked 3D animation for the
  scalable library tier (own it, tiny, offline, consistent). Reserve video files for hero
  content. This mirrors the existing SceneKit/OBJ→usdz direction.
- **Seed / migration flow.** Assets thread through the existing seed system:
  - `SeedData.json` already carries optional `localVideoURL`. Add optional
    `animationIdentifier` to the `Exercise` model + the `Codable` seed decode.
  - The `SeedMigrator` (see `SeedMigratorTests`) must **deduplicate/upsert** so adding media
    to existing exercises updates them without wiping user data — a migration that back-fills
    `animationIdentifier`/`localVideoURL` on matching seed exercises. Keep the "nil when
    unset" behavior (`localVideoURLNilWhenUnset`) so absent media stays absent.
  - `ExerciseRow`'s film-icon indicator should also reflect the presence of an animation,
    not only a video URL.

---

## 5. Safe-content checklist (per asset)

Run this for **every** asset before it ships. Keep a `content-provenance/` folder (one
record per asset).

- [ ] **License documented** — exact license name/tier saved (PDF/screenshot), with date,
      source URL, and a note that it permits *commercial use in a shipped app as a component*.
- [ ] **Standalone-value clause checked** (stock) — license does **not** forbid use where
      the media is the product's primary value; app/software use explicitly allowed.
- [ ] **No share-alike / NC / ND / editorial-only** terms attached (CC/stock).
- [ ] **Model release on file** for every recognizable person on camera (incl. yourself),
      perpetual/worldwide/all-media, covers app + marketing.
- [ ] **Work-for-hire + copyright assignment** signed for any hired videographer/animator/editor.
- [ ] **No incidental protected material in frame** — no brand logos, no wall art/posters,
      no third-party music/audio, no TV/screens, plain wardrobe.
- [ ] **Audio cleared** — either no audio, or separately licensed music with proof (usually:
      no audio, since the card plays muted).
- [ ] **Provenance written down** — who made it, when, from what base assets, and the license
      for each base asset used.
- [ ] **AI check** — asset is not shipped AI-generated output (or, if any AI was used as
      reference, the shipped asset is human-authored and this is noted).
- [ ] **Accessibility** — text instructions remain authoritative; Reduce Motion honored;
      caption/alt text present.

---

## 6. Cross-checks / open questions before committing

- **Model choice for Phase 2:** which rigged-avatar source, and does its license clearly
  permit shipping *baked renders/animations* in a commercial app (vs. redistributing the
  raw model)? Get it in writing.
- **Mocap vs. hand-key:** buy a commercially-licensed motion library, or author motion
  ourselves for guaranteed ownership? (Ownership favors authoring; time favors licensing.)
- **Field design:** add `animationIdentifier` as a new field vs. overloading `localVideoURL`
  with a scheme (e.g. `usdz://`)? A separate field is cleaner for `ExerciseMediaCard` branching.
- **Bundle vs. On-Demand Resources:** what's the acceptable base install size given existing
  OBJ/usdz assets? Decide the streaming/caching boundary before authoring 20+ animations.
- **Supabase storage:** if streaming filmed hero video, confirm storage cost, CDN behavior,
  and the offline cache/fallback UX.
- **Disclaimer placement:** does the current `LegalDocumentView` medical-disclaimer language
  cover "follow this demonstrated movement"? Update if needed.
- **Attorney review (required before ship):** have an IP/media lawyer review (1) any stock
  license's app/standalone-value clauses, (2) the model-release and work-for-hire templates,
  (3) any 3D-asset/mocap license, and (4) the AI stance if option (g) is ever used.

---

### One-line summary
Own your content: write your own instructions (already legal), animate a licensed generic
3D avatar for the library (scalable + clean), and film released originals for hero clips —
route everything through the existing `localVideoURL` / a new `animationIdentifier` slot,
document every license, and have a lawyer read the licenses before shipping.
