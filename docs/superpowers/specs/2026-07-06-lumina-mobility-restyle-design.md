# Lumina Mobility UI Restyle — Design

**Date:** 2026-07-06
**Source:** Stitch export at `~/Downloads/stitch_stretching_app_ui_redesign` (9 screens + `lumina_mobility/DESIGN.md`)
**Decisions (user-approved):** restyle the 9 designed screens only; bundle Manrope; adapt the palette for dark mode; keep all 6 tabs.

## Goal

Adopt the "Lumina Mobility" visual language across the app's main screens without changing any navigation, data flow, or behavior. Style-only changes, backed by one shared theme file so future screens can adopt the same tokens.

## Design language (from DESIGN.md + mock HTML)

- **Primary teal** `#00685B`, container `#008374`; **mint** `#8BF5E1` (fixed) / `#6ED8C5` (dim) for tinted fills and dark-mode accents.
- **Orange accent** `#FF9651` (container) / `#994701` (on-container) — used sparingly: selected chips, "biological" markers, points.
- **Calm blue** `#4C6DDD` — technical indicators, secondary data.
- **Surfaces:** background `#F8FAFB`, cards pure white, outline `#E1E3E4` / `#BCC9C5`, on-surface `#191C1D`.
- **Hero gradient:** `linear-gradient(135°, #4AC4C4 → #7663F1)` with a soft radial white halo.
- **Type:** Manrope. Headlines bold/extrabold with tight tracking; body regular with generous line height; labels semibold 12–14pt.
- **Shape:** cards 24pt radius; buttons/chips full pills; inputs 8pt.
- **Elevation:** soft diffused shadows (`0 4 20 rgba(15,23,42,0.05)` on cards; teal-tinted `0 8 30 rgba(39,156,139,0.12)` on floating elements). No harsh borders.

## Architecture

### New: `Breath - Relax & Stretch/Views/Theme/LuminaTheme.swift`

One file, three sections:

1. **Colors** — `extension Color` with `lumina`-prefixed statics (`luminaPrimary`, `luminaPrimaryContainer`, `luminaMint`, `luminaMintDim`, `luminaOrange`, `luminaOrangeText`, `luminaBlue`, `luminaSurface`, `luminaCard`, `luminaOnSurface`, `luminaOnSurfaceVariant`, `luminaOutline`, `luminaGradientStart`, `luminaGradientEnd`). Each built from a dynamic `UIColor { traits in ... }` so dark mode resolves automatically:
   - Dark surfaces: near-black with a teal cast (background ≈ `#0E1413`, card ≈ `#1A2120`).
   - Dark accents: shift to the "dim/fixed" mint (`#6ED8C5`) for legibility; on-surface ≈ `#EFF1F2`.
2. **Typography** — `Font.lumina(_ style:)` helpers wrapping `Font.custom("Manrope-…", size:, relativeTo:)` so Dynamic Type scaling is preserved. Styles: `displayLG(34/ExtraBold)`, `headline(28/Bold)`, `title(22/Bold)`, `cardTitle(17/SemiBold)`, `body(16/Regular)`, `label(13/SemiBold)`, `caption(12/Medium)`.
3. **Components**
   - `LuminaPillButtonStyle` — teal pill, white text, teal-tinted soft shadow; `prominent` and `ghost` (mint-tinted background, teal text) variants.
   - `.luminaCard(padding:)` — white card, 24pt radius, soft diffused shadow.
   - `LuminaChip` — pill filter chip; selected = orange container with dark-orange text, unselected = neutral container.

### Fonts

- `Resources/Fonts/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` (static weights from the Manrope repo, OFL license — include `OFL.txt`).
- Register in the app target and `UIAppFonts` (or confirm auto-inclusion if the target uses `GENERATE_INFOPLIST_FILE` with a file-system-synchronized group; verify by rendering).
- Watch/Widget targets are out of scope and keep system fonts.

## Screen changes (style-only; no layout/navigation/behavior changes)

| Screen | File | Changes |
|---|---|---|
| Today | `Views/Home/TodayView.swift` | Hero gradient → `#4AC4C4→#7663F1`, keep breathing halo; "Begin" = white pill with `luminaBlue` text; greeting in Manrope ExtraBold; stat tiles / program card / For You cards → `.luminaCard()`; background `luminaSurface`. |
| Tab bar | `Views/Home/CustomTabBar.swift` | Keep 6 tabs + expand-on-active pill; active pill fill → mint tint, active icon/text → `luminaPrimary`; bar keeps blur material with teal-tinted shadow. |
| Body Map | `Views/BodyMap/BodyMapView.swift` | Layer chips (Skin/Muscle/Skeleton) → `LuminaChip` with orange selected state; surface + card tokens; "Find Exercises" → teal pill. |
| Exercises | `Views/Exercises/ExerciseListView.swift` | Surface background, `.luminaCard()` rows, teal pill primary actions ("Refresh List" per mock), Manrope headers. |
| Breathe | `Views/Breathing/BreathingView.swift` | Pattern selector cards (selected = solid teal, white text); breathing circle rings → layered teal/mint opacities; rounds stepper card; "Start" → full-width teal pill. |
| Routines | `Views/Routines/RoutineListView.swift` | Header + rows re-tokened; mint icon squircles on Guided Programs / Content Packs cards; empty state per mock. |
| Profile | `Views/Profile/ProfileView.swift` (+ its Account/Settings/Appearance tab styling as needed) | Mint segmented control for the existing Account/Settings/Appearance tabs; white cards; teal toggles. |
| Exercise Detail | `Views/Exercises/ExerciseDetailView.swift` | Category chips (blue/orange); numbered step cards with teal circled numbers in white cards; timer button → teal pill. |
| Session Complete | `Views/Session/SessionSummaryView.swift` | Mint-tinted celebratory gradient background, white check circle, stat cards (`.luminaCard()`), orange points accent, "Done" teal pill. |
| Program Library | `Views/Monetization/GuidedProgramsView.swift` | Image/gradient cards with overlay titles and duration chips; orange selected filter chip. |

Where a mock invents UI that doesn't exist (e.g., notification bell, "Upgrade to Breath Pro" card variants), we restyle what exists and do not add features.

## Constraints & risks

- **Behavior freeze:** no changes to models, services, navigation, or view hierarchy beyond styling modifiers. `SessionPlayerView` internals, auth, and onboarding are out of scope.
- **Dark mode:** every new color is dynamic; verify each screen in both appearances.
- **Dynamic Type:** all Manrope fonts use `relativeTo:`; verify at XL size on Today.
- **Font registration:** if Manrope fails to load (registration issue), fall back is automatic (SwiftUI renders system font) but must be caught during verification, not shipped.
- **Existing tests:** UI is covered by XCUITests that tap by accessibility label — labels are unchanged, so tests should stay green.

## Testing & verification

1. `xcodebuild` build after the theme phase and after each screen batch.
2. Unit/UI test suite run (Swift Testing + XCUITests) — no behavior changes expected.
3. `verify` skill: screenshot each of the 6 tabs plus Exercise Detail and Session Complete, light and dark, and compare against the mock PNGs.
4. `graphify update .` after the work.
