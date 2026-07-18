# Remaining Workstreams — Rough Discussion Draft

**Date:** 2026-07-17
**Status:** Rough draft for discussion. Not specs. Workstream 1 (Head Zones + Face
Exercises) is already fully designed/planned separately and is out of scope here.

These are the four remaining items from the original request, captured at a
"roughly what the issue is" level so we can prioritise and then design each one
properly (its own brainstorm → spec → plan cycle).

---

## 2. Body rotation after selecting exercises (bug)

**Roughly:** After you tap a region and go into the exercise list, then come back
to the body map, the body sits *slightly* rotated off-true instead of dead
front/back.

**Likely cause (unconfirmed):** Rotation is stored in `committedRotationY` and
applied to `rigNode.eulerAngles.y` (`BodySceneView.swift`). A tap that registers a
tiny drag can leave `committedRotationY` a few hundredths of a radian off, and
nothing re-normalises it to exactly `0` (front) or `π` (back) when you return.
`snap(to:)` and `resetCamera(...)` exist but may not be firing on the return path.

**Type of work:** Debugging, not feature design — needs reproduction in the
simulator first (systematic-debugging), *then* a targeted fix. Smallest and most
standalone of the four.

**Open questions:** Does it happen only after a micro-drag, or every time? Front
and back both, or one facing? Is it the rig or the camera that's off?

---

## 3. Older-people (senior) content pack

**Roughly:** A curated pack aimed at older adults — gentle mobility, joint comfort,
and tension/relaxation, including the new eye/jaw/temple/forehead tension work.
Uses the existing `ContentPack` model.

**Positioning (carry over from Workstream 1):** mobility, comfort, relaxation, and
staying limber — **not** anti-aging. Fall-safety matters: favour seated and
supported-standing options over anything balance-dependent.

**Rough contents:** pull the gentlest existing stretches (neck, shoulders, wrists,
ankles, gentle back, seated hips) + the new face/eye/jaw tension set; all
difficulty 1; seated variants where possible.

**Open questions:** Free or paid pack? Seated-only track vs. mixed? A stronger
medical/consult-your-doctor disclaimer for this audience? How many exercises make
a pack feel complete (~15–20)?

---

## 4. Exercise safety audit + vetted expansion

**Roughly:** Two jobs. (a) **Audit** the current 200 exercises to confirm each is a
real, universally-accepted stretch, correctly and safely described, with a
`caution` wherever there's genuine injury risk. (b) **Expand** with more vetted,
evidence-based stretches to fill gaps.

**Why it matters:** A made-up or badly-cued stretch can injure someone. This is the
credibility backbone of the whole app.

**Type of work:** Content verification against reputable sources, not primarily
code. Deliverable = an audit report (flagged/edited entries) + a curated list of
additions, then a seed-data change.

**Open questions:** Which sources count as authoritative for us (e.g. major PT /
sports-medicine references)? Do we want a per-exercise "source" note in the data?
Any current exercises you already suspect? Target count for additions?

---

## 5. Streak / points / leaderboard evolution

**Roughly:** Today `GamificationService` gives points = duration × difficulty ×
completion, tracks a daily streak with freeze tokens, awards milestone badges, and
there's a single global leaderboard sorted by all-time points. The all-time global
board is the weak part — first movers win forever and newcomers see an unreachable
#1.

**Rough direction (my recommendation, in priority order):**
1. **Weekly-resetting leaderboard** (points earned this week) — biggest motivation
   lever; everyone starts Monday at zero. Keep all-time as a secondary tab.
2. **Streak leaderboards** — current streak + longest streak, but scoped to
   **friends / small leagues**, not one giant global list.
3. **Split lifetime XP/level from spendable/leaderboard points** — they're the same
   number today, which makes milestones and ranking fight each other.
4. **Leagues (Duolingo-style promotion/relegation)** — the proven end-state, but a
   bigger build; stage toward it.
5. **Protect the wellness intent** — keep freeze tokens; add an optional weekly
   "rest day" that doesn't break the streak; don't reward marathon sessions or
   create streak anxiety.

**Explicitly not now (YAGNI):** real-time head-to-head, ranked seasons/tiers,
cosmetic reward shops.

**Open questions:** Friends system — does one exist / do we need one before league
boards? Weekly reset cadence and timezone handling? How hard do we lean into
competition vs. the calm/wellness tone?

---

## Suggested order

1. **Rotation bug** — small, standalone, clears a visible annoyance.
2. **Streak/points** — independent of the body map; high engagement payoff.
3. **Exercise audit** — must precede/accompany any big content push.
4. **Senior pack** — builds on the audit + the new face zones, so it goes last.
