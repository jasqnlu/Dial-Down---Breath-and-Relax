# Liquid Glass Redesign — Today Tab & Navigation

**Branch:** `liquid-glass-redesign` (created off `main`/`tap-anywhere-to-skip` HEAD, both in sync at time of writing). Per explicit instruction, nothing in this pass is committed — this document and the implementation both land as uncommitted working-tree changes for the user to review and commit themselves.

## Problem

The app's core accent (`luminaPrimary`) and its hero gradient (`luminaGradientStart`/`End`) are cyan/teal, plus two call sites hardcode a literal `Color.cyan`. Separately, `TodayView`'s hero card (a bold two-hue gradient banner) and its embedded `RoadmapWave` component (a flat, uncolored background) read as two different visual languages on the same screen, even though `RoadmapWave` is rendered *inside* the hero's content area.

Deployment target is iOS 26.5, so the real SwiftUI Liquid Glass API (`.glassEffect()`, `GlassEffectContainer`) is available — this is not an emulation.

## Goals

1. Force the app into its dark/black palette regardless of the system appearance setting.
2. Remove every cyan/teal color from the app (the shared `luminaPrimary`/`luminaGradientStart` tokens and two literal `Color.cyan` uses), replacing them with light, dark-mode-tuned colors in a warm family plus the app's existing per-category palette.
3. Apply real Liquid Glass material to three targets — the `TodayView` hero card, `RoadmapWave`, and `CustomTabBar` — so the hero and the roadmap read as one continuous surface instead of two textures, and the tab bar matches.
4. Fold the roadmap's per-node coloring into the app's **existing** `ExerciseCategory.accentColor` system (8 categories, one color each) rather than inventing a second, competing color scheme — fixing that system's one cyan-adjacent entry (`.teal` for neck) in the process.

## Non-goals (explicitly out of scope)

- No other screen's card material changes (Routines, Profile, Exercises list, Onboarding, Auth, Breathing, etc. keep their current flat `luminaCardFill`/`luminaSurface` look).
- These screens *do* inherit the new amber accent color automatically, because it's a shared token — only the glass *material* is scoped to the three targets above.
- No new persisted state, no data model changes, no changes to `RoadmapWaveGeometry`'s layout math (node positions/sizes/focus scaling are untouched — only color).

## Color token changes (`Views/Theme/LuminaTheme.swift`)

| Token | Current (light / dark) | New (light / dark) | Why |
|---|---|---|---|
| `luminaPrimary` | `0x00685B` / `0x6ED8C5` (teal / mint-cyan) | `0xB5540A` / `0xFFB454` (deep amber / light amber) | The core accent; this is the cyan removal. |
| `luminaOnPrimary` | `0xFFFFFF` / `0x00382F` | `0xFFFFFF` / `0x2B1400` (dark brown) | Contrast partner for text/icons drawn on an opaque `luminaPrimary` fill (still used by every out-of-scope screen). Dark value flips from a dark teal to a dark brown so it still reads against the new light-amber dark-mode primary. |
| `luminaGradientStart` | `0x4AC4C4` / `0x2E7D7D` (cyan) | `0xFFCB84` / `0xC97A2E` (light amber) | Feeds the hero-style gradients still used elsewhere (Auth, AppLock, GenderPicker, SessionPlayerView glow) — those screens are out of scope for material changes but not for color, since it's a shared token. |
| `luminaGradientEnd` | `0x7663F1` / `0x4A3D99` (indigo) | `0xD9701A` / `0x8A4008` (copper) | Paired with the above so the remaining gradient uses read as one warm family, not amber-start/indigo-end. |
| `luminaMintTint` | `0xD7F2EA` / `0x17332E` (pale mint/cyan-adjacent) | `0xFFE9D2` / `0x33230F` (pale peach / dark amber-brown) | This is the light "container" background every `luminaPrimary`-colored label/icon sits on (chips, circular icon backgrounds, the streak badge, etc.). Left as mint it would pair a green container with amber text — this keeps container and content in the same family. |

`luminaOrange`, `luminaOnOrange`, `luminaFlameLit`, `luminaBlue`, `luminaSurface`, `luminaCardFill`, `luminaContainer`, `luminaOnSurface(Variant)`, `luminaOutline` are unchanged — none are cyan.

## Forced dark theme

Apply `.preferredColorScheme(.dark)` to the app's root view in `Breath__Relax___StretchApp.swift`. The dynamic light/dark pairs in `LuminaTheme.swift` stay as-is (harmless — only the dark values will ever resolve), so this is a one-line, low-risk change rather than a token rewrite.

## Literal `Color.cyan` removal

- `Views/Exercises/ExerciseListView.swift` (~L179, 208, 210, 218): the picking-session active-state glow → `Color.luminaPrimary`.
- `Views/BodyMap/BodySceneView.swift` (~L650, currently commented `// cyan`): the marking-candidate dot color → `Color.luminaPrimary`. Update the stale comment too.

Both are generic "active/selected" indicators, not tied to exercise category, so the single primary accent is the right replacement for both.

## Category color fix (`Models/ExerciseCategory.swift`)

`ExerciseCategory.accentColor` already assigns one color per of the 8 categories (neck/shoulders/chest/back/core/arms/hips&glutes/legs) and is already used elsewhere (the Exercises tab's category graph). Only `.neck` is cyan-adjacent (`.teal`). Change:

```swift
case .neck: return .teal   // → .red
```

Every other category (`.orange` shoulders, `.pink` chest, `.indigo` back, `.yellow` core, `.blue` arms, `.purple` hips/glutes, `.green` legs) is unchanged. This is also what fixes the Exercises tab graph, which currently shows the same cyan `.teal` node.

## Liquid Glass: the three targets

### 1. `TodayView` hero card (`heroCard`)

- Replace the full-bleed `LinearGradient(colors: [luminaGradientStart, luminaGradientEnd])` background with `.glassEffect(.regular.tint(Color.luminaPrimary.opacity(0.16)), in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))`. Real Liquid Glass samples what's behind it (the app's forced-black `luminaSurface`), so no new "elevated charcoal" background token is needed — the system material supplies that lift on its own.
- **Begin button**: currently an opaque `.background(Color.luminaPrimary, in: Capsule())` with `Color.luminaOnPrimary` text. Change to *tinted glass*: `.glassEffect(.regular.tint(Color.luminaPrimary), in: Capsule())`, with the label foreground switched from `luminaOnPrimary` to `luminaPrimary` itself (the surface is translucent now, not opaque, so the bright-amber-on-dark-glass pairing is what needs to read, not the opaque-fill pairing). The inline `time-chip` background moves from `Color.luminaOnPrimary.opacity(0.18)` to a neutral `.white.opacity(0.14)`.
- **Customize button**: currently a bare underlined text `Button`. Change to *ghost glass*: `.glassEffect(.regular, in: Capsule())` (no tint), same padding/height as Begin so the pair reads as two buttons in the same family, not a link next to a button.
- Breathing halo circles are unchanged (already white/opacity — never were cyan).

### 2. `RoadmapWave`

- Background: `RoadmapWave` itself has no opaque background layer today (the flat `Color.luminaSurface` is `TodayView`'s own outer `ScrollView` background, not `RoadmapWave`'s) — it renders transparently, directly inside `TodayView.heroCard`'s `ZStack`. That means it inherits the hero card's new glass fill automatically once the hero card gets one (below); it does **not** need — and must not get — a second, separate glass panel of its own, which would nest one glass surface inside another and reintroduce the exact "two textures" seam this pass removes.
- Wave path stroke (currently `Gradient(colors: [luminaGradientStart, luminaGradientEnd])`, L193): becomes a neutral gradient (`Color.white.opacity(0.45)` → `Color.white.opacity(0.2)`) — the connecting line stops carrying color now that color lives on the nodes.
- Node order badges (currently flat `Color.luminaPrimary` circle, L352): recolor per node to `ExerciseCategory.primary(for: exercise.targetBodyParts)?.accentColor ?? .luminaPrimary` (the node already computes this category for its glyph, so this reuses that value rather than adding a new computation).
- Node glyph container (`PoseGlyphIcon`'s background): gets a soft category-tinted wash (that category's `accentColor` at low opacity) instead of one flat surface, so the color reads as a fill, not just the badge.
- `focusGlow` (currently a fixed `Color.luminaPrimary` radial gradient, L394-407): becomes the *centered* node's own category color rather than always amber — it should track whichever exercise is currently focused, using the same category lookup as that node's badge/glyph.

### 3. `CustomTabBar`

- Replace the `.regularMaterial` fill + `strokeBorder(Color(.systemGray5)...)` with `GlassEffectContainer { … .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30)) }` wrapping the whole bar, so the sliding active-tab capsule (already built with `matchedGeometryEffect`) visually merges with the surrounding glass per Apple's intended interaction, instead of sitting on top of an opaque material.
- The active-tab capsule indicator itself stays *neutral* glass (no tint) — only the active tab's icon and label switch to `Color.luminaPrimary`, so the bar doesn't compete with the amber accent living on the actual content above it.
- The shadow at L54 (`Color.luminaPrimary.opacity(0.14)`) needs no code change — it inherits the new amber automatically once the token is repointed.

## Verification plan

No commits this pass — all changes land as uncommitted working-tree edits on `liquid-glass-redesign` for review.

1. Build for the simulator and use the `verify` skill to screenshot:
   - `TodayView` (full scroll — hero + roadmap together, confirming they now read as one surface, and the Begin/Customize glass buttons).
   - `CustomTabBar` across a couple of tab switches (confirming the glass merge + amber active state).
   - The Exercises tab's category graph (confirming neck now reads red instead of teal, no other category regressed).
   - `ExerciseListView` and `BodyMapView` (confirming the two former-`Color.cyan` spots still read correctly as amber).
   - `AuthView`/`AppLockView`/`GenderPickerPage` (confirming the retired cyan→indigo gradient now reads as an intentional warm amber→copper gradient, not broken).
2. Run the existing test suite (`xcodebuild test`, per the project's documented command) and grep test files for any hardcoded expectations against the old hex values or `.teal` before assuming a pass is clean.
3. Manually confirm text contrast on the repointed `luminaOnPrimary`/`luminaMintTint` pairs — flipping a token's hex is exactly the kind of change that can silently break contrast on a screen this pass doesn't otherwise touch.
