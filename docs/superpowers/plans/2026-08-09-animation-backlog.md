# Exercise animation backlog (as of 2026-08-09)

36 of 217 exercises are animated. This file is the actionable remainder —
what's blocked, what's just not gotten to yet, and what's not worth doing.
Full narrative/derivation for everything already tried lives in
`Tools/blender/exercises/ANIMATION_HANDOFF.md`; the rotation-specific audit
(where most of the items below originate) is
`docs/superpowers/plans/2026-08-05-rotation-animation-audit.md`.

---

## 1. Untried — worth a probe, no known blocker

Nobody has attempted these yet, as distinct from "attempted and failed."

### `hips`/arm-bone local-Y twist (2 conventions, ~5 exercises)

| Exercise | What's needed |
|---|---|
| Left/Right Sleeper Stretch (Internal Rotation) | `upperarm` local-Y twist (shoulder internal rotation) |
| Left/Right Doorway External Rotation Stretch | same axis, opposite direction |
| Shoulder Roll | `upperarm` circular path combining X+Z+Y — medium confidence, the rig has no scapula bone so this is at best an approximation of the real shoulder-blade motion |

Local-Y twist is proven on the *vertical* bones (spine/chest/head — see the
seated-twist and reach-through-twist work). It has never been tried on an
*arm* bone. Needs its own numeric probe before trusting sign/degree — don't
assume the vertical-bone convention transfers, the way the arm-bone local-X
sign (`+X = swing back`) turned out to be the *opposite* of the vertical
bones' local-X (`+X = forward pitch`).

`hips` local-Y twist (independent of the windshield-wipers `thigh`-swing
workaround already shipped for Supine Spinal Twist) also remains untried —
no exercise currently needs it, but it's a listed gap from the original
audit worth closing if a future exercise calls for it.

### Tier C — dynamic hip/thigh motion (blocked on one shared research question)

None of these can be authored until someone probes `hips`/`thigh.{L,R}`/
`shin.{L,R}` for *dynamic* (mid-clip-moving) motion. The *static* seated/
kneeling leg pose is proven and shipped (Seated Spinal Twist, the supine
family, Thread the Needle) — what's unproven is anything that swings,
circles, or lunges the legs *while the clip plays*.

| Exercise | What's needed | Instructions summary |
|---|---|---|
| Standing Hip Circles | `hips` circular motion, upper body relatively still | "Shift your hips in a slow, wide circle... keep your upper body relatively still" |
| Left/Right Runner's Lunge with Rotation | `thigh` lunge pitch (dynamic) + `spine`/`chest` twist+reach (already proven, static) | Deep lunge, back leg straight, torso rotates and one arm reaches up |
| World's Greatest Stretch (Left/Right Lead Leg) | Same split as Runner's Lunge, plus a hamstring-straighten/re-bend cycle mid-hold | Lunge → torso rotation/reach → straighten front leg → re-bend, repeating |
| Dynamic Standing Leg Swings | `thigh` pendulum swing (sagittal, not twist — different motion shape than anything tried) | Forward/backward pendulum swing of one leg, holding a wall for balance |
| Left/Right Cossack Squat Stretch | `thigh` lateral shift/weight transfer between a bent and straight leg | Wide stance, weight shifts side to side between bent/straight legs |

**Cheap partial option, doesn't need the Tier C research**: for the two
torso+lunge exercises (Runner's Lunge with Rotation, World's Greatest
Stretch), ship a simplified first pass that animates ONLY the torso
twist/reach and leaves the legs in the rig's static rest stance — the same
trick `standing_forward_fold_ragdoll.py` already uses (never touches
`hips`/`thigh`, reads entirely through spine+chest+upperarm). Less
anatomically exact (no visible lunge), but unblocks the torso-twist half
immediately and doesn't wait on Tier C.

---

## 2. Not representable with the current rig — recommend leaving text-only

No bone exists for the joint doing the actual moving. An approximation
would be actively misleading (e.g. a wrist stretch that doesn't move a
wrist), not just imperfect. Extending the rig with wrist/finger/eye bones
is a much bigger, separate project — not recommended unless a lot more of
the catalog turns out to need it.

| Exercise | Blocked by |
|---|---|
| Wrist Circles | no wrist bone |
| Wrist & Forearm Release | no wrist bone |
| Left/Right Extended-Fingers Bicep Stretch | wrist-extension is the actual motion; no wrist bone |
| Gentle Eye Rolls | no eye bone/blend-shape — skeletal rig, not a facial rig |
| Temporalis Release | finger self-massage circles; no per-finger articulation |

---

## 3. The other ~176 exercises

Everything not listed above and not yet animated. Most of these were never
individually audited — the rotation-audit plan only combed through
exercises whose *primary* motion is a twist/rotation. A lot of the
remaining catalog (static holds, simple flexion/extension, breathing
exercises with no meaningful body motion) likely needs no new axis
convention at all — just someone going through the per-exercise authoring
process (`ANIMATION_HANDOFF.md` §5) with the axes already proven:
local-X flexion (vertical bones and arm bones), local-Z side-bend, local-Y
twist (vertical bones only), the static seated/kneeling leg pose, the
supine base pose (+ side-roll), and the quadruped base pose.

Breathing-only exercises (no visible body motion — "Box Breathing," "4-7-8
Breathing," etc.) are a separate question entirely: whether they're worth
animating at all given there's no motion to show, versus a simple looping
breath-cue animation, hasn't been discussed and isn't scoped here.

---

## Priority suggestion, if picking this back up

1. **Cheapest, no research needed**: the Runner's Lunge/World's Greatest
   Stretch torso-only simplification (§1, "cheap partial option") — reuses
   entirely proven axes.
2. **One probe, moderate payoff**: arm-bone local-Y twist — unblocks 5
   exercises (Sleeper Stretch L/R, Doorway External Rotation L/R, and
   informs Shoulder Roll).
3. **Bigger research spike**: Tier C dynamic hip/thigh motion — unblocks 5
   more exercises but is explicitly flagged as "a bigger, standalone
   research task, not a per-exercise tweak" in the original audit.
4. **Skip**: Tier D (§2) — not worth a rig extension for 5 exercises.
5. **Ongoing, unglamorous**: work through the ~176 un-audited exercises
   with already-proven axes. Highest total volume, lowest risk per
   exercise, no new research required.
