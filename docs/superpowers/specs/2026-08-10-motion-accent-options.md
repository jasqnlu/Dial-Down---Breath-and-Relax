# Motion accent placement — options and decision

**Status:** Approved — implement option B alongside the pose-glyph icon system

Companion to the pose-glyph icon system shipped in
[2026-08-10-pose-glyph-icons-design.md](2026-08-10-pose-glyph-icons-design.md).
Some exercises are positions a static stick figure can show (a spinal twist
has a definite shape). Others are repeated circular motions — Shoulder Roll,
Neck Rolls, Wrist Circles, Hip Circles, Ankle Alphabet — where the body
barely changes position; the point is a joint moving in a loop, which a
static figure can't represent on its own. This doc compares three ways to
add a "this is circular motion" accent to the existing badge.

The examples below are static previews of the three options. They are intended
to be judged at the same 60–96pt sizes as the production badge, not as
standalone artwork.

## Shoulder Roll — Shoulders (orange)

| A · Joint swirl | B · Corner badge | C · Motion-only glyph |
|---|---|---|
| ![A](data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2296%22%20height%3D%2296%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22%23fbe6d0%22%2F%3E%3Cpath%20d%3D%22M50%2034%20L50%2052%20M50%2030%20L34%2042%20L28%2058%20M50%2052%20L42%2074%20L40%2092%20M50%2052%20L58%2074%20L60%2092%22%20stroke%3D%22%23d98a34%22%20stroke-width%3D%227%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2216%22%20r%3D%2210%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2226%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2234%22%20cy%3D%2242%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2228%22%20cy%3D%2258%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2252%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2242%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2258%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Cpath%20d%3D%22M62%2034%20a8%208%200%201%201%20-3%206%22%20stroke%3D%22%23d98a34%22%20stroke-width%3D%224.5%22%20stroke-linecap%3D%22round%22%20fill%3D%22none%22%2F%3E%3Cpath%20d%3D%22M58%2039%20l3%204%20l4.5%20-2.5%22%20stroke%3D%22%23d98a34%22%20stroke-width%3D%224.5%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E) | ![B](data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2296%22%20height%3D%2296%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22%23fbe6d0%22%2F%3E%3Cpath%20d%3D%22M50%2034%20L50%2052%20M50%2030%20L34%2042%20L28%2058%20M50%2030%20L66%2042%20L72%2058%20M50%2052%20L42%2074%20L40%2092%20M50%2052%20L58%2074%20L60%2092%22%20stroke%3D%22%23d98a34%22%20stroke-width%3D%227%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2216%22%20r%3D%2210%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2234%22%20cy%3D%2242%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2266%22%20cy%3D%2242%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2228%22%20cy%3D%2258%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2272%22%20cy%3D%2258%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2252%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2242%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2258%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%23d98a34%22%2F%3E%3Ccircle%20cx%3D%2280%22%20cy%3D%2280%22%20r%3D%2216%22%20fill%3D%22%23d98a34%22%2F%3E%3Cpath%20d%3D%22M62%2072%20a18%2018%200%201%201%20-2%2014%22%20stroke%3D%22white%22%20stroke-width%3D%229%22%20stroke-linecap%3D%22round%22%20fill%3D%22none%22%2F%3E%3Cpath%20d%3D%22M54%2082%20l6%2010%20l10%20-6%22%20stroke%3D%22white%22%20stroke-width%3D%229%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E) | ![C](data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2296%22%20height%3D%2296%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22%23fbe6d0%22%2F%3E%3Cpath%20d%3D%22M28%2030%20a22%2022%200%201%201%20-6%2016%22%20stroke%3D%22%23d98a34%22%20stroke-width%3D%228%22%20stroke-linecap%3D%22round%22%20fill%3D%22none%22%2F%3E%3Cpath%20d%3D%22M14%2044%20l7%2012%20l12%20-6%22%20stroke%3D%22%23d98a34%22%20stroke-width%3D%228%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E) |

## Neck Rolls — Neck (teal)

| A · Joint swirl | B · Corner badge | C · Motion-only glyph |
|---|---|---|
| ![A](data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2296%22%20height%3D%2296%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22%23d3ece9%22%2F%3E%3Cpath%20d%3D%22M50%2034%20L50%2058%20M50%2058%20L38%2074%20L34%2090%20M50%2058%20L62%2074%20L66%2090%22%20stroke%3D%22%232aa39a%22%20stroke-width%3D%227%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2234%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2258%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2238%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2262%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2222%22%20r%3D%2210%22%20fill%3D%22%232aa39a%22%20opacity%3D%220.28%22%2F%3E%3Cpath%20d%3D%22M58%2018%20a10%2010%200%201%201%20-4%208%22%20stroke%3D%22%232aa39a%22%20stroke-width%3D%224.5%22%20stroke-linecap%3D%22round%22%20fill%3D%22none%22%2F%3E%3Cpath%20d%3D%22M53%2024%20l3.5%205%20l5.5%20-3%22%20stroke%3D%22%232aa39a%22%20stroke-width%3D%224.5%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E) | ![B](data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2296%22%20height%3D%2296%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22%23d3ece9%22%2F%3E%3Cpath%20d%3D%22M50%2034%20L50%2058%20M50%2040%20L26%2046%20L14%2040%20M50%2040%20L74%2046%20L86%2040%20M50%2058%20L38%2074%20L34%2090%20M50%2058%20L62%2074%20L66%2090%22%20stroke%3D%22%232aa39a%22%20stroke-width%3D%227%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2222%22%20r%3D%2210%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2234%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2240%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2226%22%20cy%3D%2246%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2274%22%20cy%3D%2246%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2258%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2238%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2262%22%20cy%3D%2274%22%20r%3D%223.4%22%20fill%3D%22%232aa39a%22%2F%3E%3Ccircle%20cx%3D%2280%22%20cy%3D%2280%22%20r%3D%2216%22%20fill%3D%22%232aa39a%22%2F%3E%3Cpath%20d%3D%22M62%2072%20a18%2018%200%201%201%20-2%2014%22%20stroke%3D%22white%22%20stroke-width%3D%229%22%20stroke-linecap%3D%22round%22%20fill%3D%22none%22%2F%3E%3Cpath%20d%3D%22M54%2082%20l6%2010%20l10%20-6%22%20stroke%3D%22white%22%20stroke-width%3D%229%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E) | ![C](data:image/svg+xml;utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2296%22%20height%3D%2296%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2250%22%20fill%3D%22%23d3ece9%22%2F%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2258%22%20r%3D%2210%22%20fill%3D%22%232aa39a%22%20opacity%3D%220.85%22%2F%3E%3Cpath%20d%3D%22M50%2040%20a18%2018%200%201%201%20-5%2014%22%20stroke%3D%22%232aa39a%22%20stroke-width%3D%226.5%22%20stroke-linecap%3D%22round%22%20fill%3D%22none%22%2F%3E%3Cpath%20d%3D%22M40%2051%20l5.5%209%20l9%20-5%22%20stroke%3D%22%232aa39a%22%20stroke-width%3D%226.5%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E) |

## Assessment

- **A · Joint swirl** — a small loop-arrow replaces the joint dot right where
  the motion happens. Keeps every icon in the same visual family as the
  positional exercises ("one system"), but is fiddly to author per-archetype
  and can look busy at 96pt.
- **B · Corner badge** — full body figure stays intact; a separate
  rotation-arrow badge is layered at the corner, like a notification dot.
  Least invasive to build: a fixed decoration on top of whatever archetype
  the exercise already resolves to, reusable across every circular exercise
  with **zero new archetype coordinates**. Doesn't discard the body-position
  information the rest of the system already encodes.
- **C · Motion-only glyph** — boldest/clearest, but throws away body-position
  info and needs its own archetype type built from scratch.

**Decision: B.** Cheapest to build, composes cleanly with the existing
archetype system, and reads clearly at badge size without redesigning
anything already shipped.

## Implementation decision

Option B is a compositional overlay on `PoseGlyphIcon`; it is not a new pose
archetype and it does not replace the body figure. The renderer should add a
small circular-arrow badge only when the exercise's motion is explicitly
cyclic.

### Motion classification

Add a pure, derived classification next to the existing pose-archetype
resolution. The initial mapping is intentionally small and explicit:

| Motion group | Exercises | Accent |
|---|---|---|
| `circular` | Shoulder Roll, Neck Rolls, Wrist Circles, Hip Circles, Ankle Alphabet | Corner badge |
| `static` | Holds, stretches, twists, folds, reaches, and breathing exercises | None |

Use stable `seedID` overrides for the circular group rather than relying only
on name matching. If a future exercise has circular motion, add it to the
override table and the classification test in the same change. Do not infer
cyclic motion from the broad `.repeatMotion` session cue: repeated side
switches, alternating stretches, and dynamic non-circular movements do not
use this accent.

### Component behavior

Keep the overlay inside `PoseGlyphIcon`, after the pose figure has been drawn:

```swift
ZStack(alignment: .bottomTrailing) {
    PoseGlyphBody(...)

    if motion == .circular {
        MotionAccentBadge(color: category.accentColor)
            .padding(badgeSize * 0.04)
    }
}
```

`MotionAccentBadge` should:

- use the existing category accent color for its filled circle;
- use a white, clockwise rotation arrow with a clear arrowhead;
- size to roughly 22–26% of the parent badge diameter (about 16–20pt at
  72pt, and 21–25pt at 96pt);
- remain fully inside the parent circle, including its stroke and arrowhead;
- have no animation in the browsing cards; the static arrow communicates the
  motion type without adding visual noise or battery cost.

The corner location is part of the decision. Do not move the accent onto the
joint, because that would require archetype-specific placement and would
compete with joint dots at small sizes.

### Accessibility and rendering rules

- The overlay is decorative when the parent icon has an accessibility label.
  Apply `.accessibilityHidden(true)` to the accent so VoiceOver does not read
  an extra, ambiguous element.
- The parent label should include the motion meaning for circular exercises,
  for example, “Shoulder Roll, circular motion.” This preserves the meaning
  for users who cannot see the accent.
- The badge must use the category accent already chosen by the pose glyph;
  do not introduce a separate motion color or depend on color alone.
- At compact sizes, preserve the arrowhead and circle before increasing
  stroke width. If the accent cannot render legibly below 48pt, hide the
  decorative overlay and keep the accessible motion label.
- Respect the app's reduced-motion setting if a future animated treatment is
  added. This decision intentionally ships with no animation.

## Acceptance criteria

- Shoulder Roll, Neck Rolls, Wrist Circles, Hip Circles, and Ankle Alphabet
  show the corner badge in both `ForYouCard` and `RecommendedCard`.
- Static stretches and breathing exercises do not show the corner badge.
- The underlying pose archetype, category tint, mirroring, and layout are
  unchanged for every exercise.
- The overlay remains inside the circular icon at the smallest production
  size and does not cover the head or the primary pose joints.
- A classification test asserts the five initial circular exercises and at
  least three representative static exercises.
- A preview or UI test renders the accent at 48pt, 60pt, 72pt, and 96pt and
  confirms that it remains recognizable without clipping.
- VoiceOver exposes one exercise label, with “circular motion” included for
  the five circular exercises and no duplicate label for the decorative
  overlay.

## Deferred alternatives

Option A remains a possible future refinement if user testing shows that a
corner overlay feels detached from the moving joint. Option C is deferred
indefinitely: it removes useful pose information and would create a second
icon taxonomy to maintain. Neither alternative should block implementation
of option B.
