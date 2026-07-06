# Lumina Mobility UI Restyle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the 9 designed screens (Today, tab bar, Body Map, Exercises, Breathe, Routines, Profile, Exercise Detail, Session Complete, Program Library) to the "Lumina Mobility" design system — style-only, no behavior/navigation changes.

**Architecture:** One new theme layer (`Views/Theme/`) provides dynamic Lumina colors, runtime-registered Manrope fonts with Dynamic Type scaling, and three shared components (pill button style, card modifier, chip). The global `AccentColor` asset switches to Lumina teal so all `Color.accentColor` call sites retint for free. Screens are then re-tokened in place.

**Tech Stack:** SwiftUI, CoreText (font registration), Swift Testing (`@testable import BreathRelaxStretch`), XCUITest via the repo `verify` skill.

**Spec:** `docs/superpowers/specs/2026-07-06-lumina-mobility-restyle-design.md`
**Mocks:** `~/Downloads/stitch_stretching_app_ui_redesign/<screen>/screen.png` — the implementing agent for each screen task MUST view the mock PNG first.

## Global Constraints

- Style-only: no changes to models, services, navigation, view hierarchy, or accessibility labels/identifiers (XCUITests depend on them).
- Every new color must be dynamic (light + dark variant) via the `UIColor` dynamic provider in `LuminaTheme.swift`.
- Every Manrope font use must go through the `Font.lumina*` helpers (all built with `relativeTo:` so Dynamic Type works).
- Watch/Widget targets keep system fonts and are untouched.
- Project uses `PBXFileSystemSynchronizedRootGroup`: files dropped under `Breath - Relax & Stretch/` or `Breath - Relax & StretchTests/` join the right target automatically — never edit `project.pbxproj`.
- `GENERATE_INFOPLIST_FILE = YES`: there is no `UIAppFonts` build setting, which is why fonts are registered at runtime with CoreText, not via Info.plist.
- Build command (use after every task):
  `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet`
- Unit-test command:
  `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- Codebase exploration: run `graphify query "<question>"` before reading unfamiliar files; run `graphify update .` after code changes.
- Commit after every task with a `feat:`/`style:` message ending in the Claude co-author trailer.

## Design tokens (single source of truth for all tasks)

| Token | Light | Dark |
|---|---|---|
| `luminaPrimary` | `#00685B` | `#6ED8C5` |
| `luminaOnPrimary` | `#FFFFFF` | `#00382F` |
| `luminaPrimaryContainer` | `#008374` | `#005046` |
| `luminaMintTint` (pill/ghost fills) | `#D7F2EA` | `#17332E` |
| `luminaOrange` (selected chips) | `#FF9651` | `#994701` |
| `luminaOnOrange` | `#6F3200` | `#FFDBC8` |
| `luminaBlue` | `#4C6DDD` | `#B6C4FF` |
| `luminaSurface` (page bg) | `#F8FAFB` | `#0E1413` |
| `luminaCardFill` | `#FFFFFF` | `#1A2120` |
| `luminaContainer` (inset fills) | `#ECEEEF` | `#242B2A` |
| `luminaOnSurface` | `#191C1D` | `#EFF1F2` |
| `luminaOnSurfaceVariant` | `#3D4946` | `#BCC9C5` |
| `luminaOutline` | `#E1E3E4` | `#2E3835` |
| `luminaGradientStart` | `#4AC4C4` | `#2E7D7D` |
| `luminaGradientEnd` | `#7663F1` | `#4A3D99` |

Font helpers (defined once in Task 2, used everywhere):

| Helper | Font | Size | relativeTo |
|---|---|---|---|
| `.luminaDisplay` | Manrope-ExtraBold | 34 | `.largeTitle` |
| `.luminaHeadline` | Manrope-ExtraBold | 26 | `.title` |
| `.luminaTitle` | Manrope-Bold | 20 | `.title3` |
| `.luminaCardTitle` | Manrope-SemiBold | 17 | `.headline` |
| `.luminaBody` | Manrope-Regular | 16 | `.body` |
| `.luminaSubheadline` | Manrope-Regular | 15 | `.subheadline` |
| `.luminaLabel` | Manrope-SemiBold | 13 | `.footnote` |
| `.luminaCaption` | Manrope-Medium | 12 | `.caption` |

Global re-token mapping for screen tasks (apply wherever the element is page background / content card / inset fill on the screens in scope):

| Existing pattern | Replace with |
|---|---|
| `Color(.systemGroupedBackground)` / full-screen `Color(.systemBackground)` | `Color.luminaSurface` |
| `Color(.secondarySystemGroupedBackground), in: RoundedRectangle(...)` on content cards | `.luminaCard()` modifier (drop the manual background) |
| `Color(.secondarySystemFill)` inset fills | `Color.luminaContainer` |
| `.font(.system(.title2, design: .rounded, weight: .bold))` | `.font(.luminaHeadline)` |
| `.font(.system(.title3, design: .rounded, weight: .bold))` | `.font(.luminaTitle)` |
| `.font(.subheadline.weight(.semibold))` / `.headline` | `.font(.luminaCardTitle)` |
| `.font(.subheadline)` | `.font(.luminaSubheadline)` |
| `.font(.caption)` | `.font(.luminaCaption)` |
| Primary CTA capsules (`Color.accentColor` bg + white text) | `LuminaPillButtonStyle()` where it's a `Button`; otherwise `Color.luminaPrimary` bg + `Color.luminaOnPrimary` text |

Do NOT touch: `.foregroundStyle(.secondary)` on plain text (fine as-is), alert/sheet internals, `SessionPlayerView`, auth/onboarding views, small input radii.

---

### Task 1: Bundle Manrope + runtime registration

**Files:**
- Create: `Breath - Relax & Stretch/Resources/Fonts/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` + `OFL.txt`
- Create: `Breath - Relax & Stretch/Views/Theme/LuminaFonts.swift`
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift` (call registration in `init`)
- Test: `Breath - Relax & StretchTests/LuminaFontsTests.swift`

**Interfaces:**
- Produces: `LuminaFonts.registerAll()` (idempotent, `@discardableResult`-free static func) and the five PostScript font names `Manrope-Regular/Medium/SemiBold/Bold/ExtraBold` loadable via `UIFont(name:size:)`.

- [ ] **Step 1: Download static Manrope TTFs (latin, weights 400–800)**

```bash
cd "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
mkdir -p "Breath - Relax & Stretch/Resources/Fonts"
cd /tmp && curl -sL -o manrope.zip "https://gwfh.mranftl.com/api/fonts/manrope?download=zip&subsets=latin&variants=regular,500,600,700,800&formats=ttf" && unzip -o manrope.zip -d manrope-ttf && ls manrope-ttf
```

Expected: five `manrope-v*-latin-{regular,500,600,700,800}.ttf` files. Then rename into the project:

```bash
cd /tmp/manrope-ttf
DEST="/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch/Breath - Relax & Stretch/Resources/Fonts"
cp *regular.ttf "$DEST/Manrope-Regular.ttf"
cp *-500.ttf "$DEST/Manrope-Medium.ttf"
cp *-600.ttf "$DEST/Manrope-SemiBold.ttf"
cp *-700.ttf "$DEST/Manrope-Bold.ttf"
cp *-800.ttf "$DEST/Manrope-ExtraBold.ttf"
```

Also fetch the license: `curl -sL -o "$DEST/OFL.txt" "https://raw.githubusercontent.com/google/fonts/main/ofl/manrope/OFL.txt"`
If the gwfh API is unreachable, fall back to `https://github.com/google/fonts/raw/main/ofl/manrope/Manrope%5Bwght%5D.ttf` is variable-only — in that case STOP and report; do not ship the variable font.

**Verify the internal PostScript names** (they must match what `LuminaFonts.swift` registers):

```bash
for f in "$DEST"/Manrope-*.ttf; do fc-scan --format "%{postscriptname}\n" "$f" 2>/dev/null || mdls -name kMDItemFonts "$f"; done
```

If PostScript names differ from `Manrope-Regular` etc., adjust the `names` array in Step 2 and the test in Step 3 to the actual names.

- [ ] **Step 2: Write `LuminaFonts.swift`**

```swift
import SwiftUI
import CoreText

// MARK: - Manrope registration
//
// The target generates its Info.plist (GENERATE_INFOPLIST_FILE), which has
// no UIAppFonts build setting, so fonts are registered at runtime instead.

enum LuminaFonts {
    private static var didRegister = false

    /// Idempotent. Called from the App initializer (and from unit tests).
    static func registerAll() {
        guard !didRegister else { return }
        didRegister = true

        let names = ["Manrope-Regular", "Manrope-Medium", "Manrope-SemiBold",
                     "Manrope-Bold", "Manrope-ExtraBold"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Semantic type scale (Lumina Mobility)

extension Font {
    static let luminaDisplay     = Font.custom("Manrope-ExtraBold", size: 34, relativeTo: .largeTitle)
    static let luminaHeadline    = Font.custom("Manrope-ExtraBold", size: 26, relativeTo: .title)
    static let luminaTitle       = Font.custom("Manrope-Bold",      size: 20, relativeTo: .title3)
    static let luminaCardTitle   = Font.custom("Manrope-SemiBold",  size: 17, relativeTo: .headline)
    static let luminaBody        = Font.custom("Manrope-Regular",   size: 16, relativeTo: .body)
    static let luminaSubheadline = Font.custom("Manrope-Regular",   size: 15, relativeTo: .subheadline)
    static let luminaLabel       = Font.custom("Manrope-SemiBold",  size: 13, relativeTo: .footnote)
    static let luminaCaption     = Font.custom("Manrope-Medium",    size: 12, relativeTo: .caption)
}
```

- [ ] **Step 3: Write the failing test**

`Breath - Relax & StretchTests/LuminaFontsTests.swift`:

```swift
import Testing
import UIKit
@testable import BreathRelaxStretch

@Suite("Lumina font registration")
struct LuminaFontsTests {
    @Test("all five Manrope weights load after registration")
    func manropeLoads() {
        LuminaFonts.registerAll()
        let names = ["Manrope-Regular", "Manrope-Medium", "Manrope-SemiBold",
                     "Manrope-Bold", "Manrope-ExtraBold"]
        for name in names {
            #expect(UIFont(name: name, size: 14) != nil, "\(name) failed to load")
        }
    }
}
```

- [ ] **Step 4: Hook registration into the App init**

In `Breath__Relax___StretchApp.swift`, add as the FIRST line of the existing `init()` (create `init()` if none exists):

```swift
LuminaFonts.registerAll()
```

- [ ] **Step 5: Run the test — expect PASS** (it would fail with "failed to load" if fonts/names were wrong)

Run: unit-test command from Global Constraints, then confirm `LuminaFontsTests` passed in the output.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Resources/Fonts" "Breath - Relax & Stretch/Views/Theme/LuminaFonts.swift" "Breath - Relax & StretchTests/LuminaFontsTests.swift" "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift"
git commit -m "feat: bundle Manrope with runtime CoreText registration"
```

---

### Task 2: LuminaTheme — colors, components, global accent

**Files:**
- Create: `Breath - Relax & Stretch/Views/Theme/LuminaTheme.swift`
- Modify: `Breath - Relax & Stretch/Assets.xcassets/AccentColor.colorset/Contents.json`
- Test: `Breath - Relax & StretchTests/LuminaThemeTests.swift`

**Interfaces:**
- Produces (used by every later task):
  - `Color.lumina*` statics exactly per the token table above.
  - `LuminaPillButtonStyle(kind: .prominent | .ghost)` — `ButtonStyle`; prominent = teal pill/white text/teal-tinted shadow; ghost = mint-tinted pill/teal text.
  - `View.luminaCard(padding: CGFloat = 16)` — white 24pt-radius card with `.black.opacity(0.05)`-class soft shadow (`radius: 10, y: 4`), dark-aware fill.
  - `LuminaChip(title: String, isSelected: Bool, action: () -> Void)` — pill chip, selected = orange container + `luminaOnOrange` text, unselected = `luminaContainer` + `luminaOnSurfaceVariant`.

- [ ] **Step 1: Write `LuminaTheme.swift`**

```swift
import SwiftUI

// MARK: - Lumina Mobility design tokens
// Palette from the Stitch redesign (docs/superpowers/specs/
// 2026-07-06-lumina-mobility-restyle-design.md). All colors are dynamic.

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }

    static func lumina(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension Color {
    static let luminaPrimary          = Color(UIColor.lumina(light: 0x00685B, dark: 0x6ED8C5))
    static let luminaOnPrimary        = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x00382F))
    static let luminaPrimaryContainer = Color(UIColor.lumina(light: 0x008374, dark: 0x005046))
    static let luminaMintTint         = Color(UIColor.lumina(light: 0xD7F2EA, dark: 0x17332E))
    static let luminaOrange           = Color(UIColor.lumina(light: 0xFF9651, dark: 0x994701))
    static let luminaOnOrange         = Color(UIColor.lumina(light: 0x6F3200, dark: 0xFFDBC8))
    static let luminaBlue             = Color(UIColor.lumina(light: 0x4C6DDD, dark: 0xB6C4FF))
    static let luminaSurface          = Color(UIColor.lumina(light: 0xF8FAFB, dark: 0x0E1413))
    static let luminaCardFill         = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x1A2120))
    static let luminaContainer        = Color(UIColor.lumina(light: 0xECEEEF, dark: 0x242B2A))
    static let luminaOnSurface        = Color(UIColor.lumina(light: 0x191C1D, dark: 0xEFF1F2))
    static let luminaOnSurfaceVariant = Color(UIColor.lumina(light: 0x3D4946, dark: 0xBCC9C5))
    static let luminaOutline          = Color(UIColor.lumina(light: 0xE1E3E4, dark: 0x2E3835))
    static let luminaGradientStart    = Color(UIColor.lumina(light: 0x4AC4C4, dark: 0x2E7D7D))
    static let luminaGradientEnd      = Color(UIColor.lumina(light: 0x7663F1, dark: 0x4A3D99))
}

// MARK: - Pill button

struct LuminaPillButtonStyle: ButtonStyle {
    enum Kind { case prominent, ghost }
    var kind: Kind = .prominent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.luminaCardTitle)
            .foregroundStyle(kind == .prominent ? Color.luminaOnPrimary : Color.luminaPrimary)
            .padding(.horizontal, 24)
            .frame(minHeight: 48)
            .background(
                kind == .prominent ? Color.luminaPrimary : Color.luminaMintTint,
                in: Capsule()
            )
            .shadow(color: kind == .prominent ? Color.luminaPrimary.opacity(0.25) : .clear,
                    radius: 10, y: 5)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Card

private struct LuminaCard: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.luminaCardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color(UIColor.lumina(light: 0x0F172A, dark: 0x000000)).opacity(0.05),
                    radius: 10, y: 4)
    }
}

extension View {
    func luminaCard(padding: CGFloat = 16) -> some View {
        modifier(LuminaCard(padding: padding))
    }
}

// MARK: - Filter chip

struct LuminaChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.luminaLabel)
                .foregroundStyle(isSelected ? Color.luminaOnOrange : Color.luminaOnSurfaceVariant)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.luminaOrange : Color.luminaContainer, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

- [ ] **Step 2: Point the global accent at Lumina teal**

Overwrite `Breath - Relax & Stretch/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0x5B", "green" : "0x68", "red" : "0x00" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0xC5", "green" : "0xD8", "red" : "0x6E" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

- [ ] **Step 3: Write the test**

`Breath - Relax & StretchTests/LuminaThemeTests.swift`:

```swift
import Testing
import SwiftUI
import UIKit
@testable import BreathRelaxStretch

@Suite("Lumina theme colors")
struct LuminaThemeTests {
    @Test("primary resolves differently in light and dark")
    func primaryIsDynamic() {
        let ui = UIColor(Color.luminaPrimary)
        let light = ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light != dark)
    }

    @Test("surface resolves differently in light and dark")
    func surfaceIsDynamic() {
        let ui = UIColor(Color.luminaSurface)
        #expect(ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
             != ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
    }
}
```

- [ ] **Step 4: Run unit tests — expect PASS** (unit-test command from Global Constraints)

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Theme/LuminaTheme.swift" "Breath - Relax & Stretch/Assets.xcassets/AccentColor.colorset/Contents.json" "Breath - Relax & StretchTests/LuminaThemeTests.swift"
git commit -m "feat: Lumina theme tokens, pill/card/chip components, teal accent"
```

---

### Task 3: Today tab + floating tab bar

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/CustomTabBar.swift`

**Interfaces:**
- Consumes: `Color.lumina*`, `Font.lumina*`, `.luminaCard()` from Tasks 1–2.
- Produces: nothing consumed later.

- [ ] **Step 1: View the mock** `~/Downloads/stitch_stretching_app_ui_redesign/today/screen.png`

- [ ] **Step 2: TodayView edits** (exact old → new)

1. Hero gradient (line ~181):
```swift
// old
colors: [Color(.systemTeal).opacity(0.75), Color(.systemIndigo).opacity(0.9)],
// new
colors: [Color.luminaGradientStart, Color.luminaGradientEnd],
```
2. Begin button text color (line ~222): `.foregroundStyle(Color(.systemIndigo))` → `.foregroundStyle(Color.luminaBlue)`
3. Page background (line ~89): `Color(.systemGroupedBackground)` → `Color.luminaSurface`
4. Greeting (line ~152): `.font(.system(.title2, design: .rounded, weight: .bold))` → `.font(.luminaHeadline)`; date line `.font(.subheadline)` → `.font(.luminaSubheadline)`
5. Streak capsule background: `Color(.secondarySystemGroupedBackground)` → `Color.luminaCardFill`; its number font `.system(.subheadline, design: .rounded, weight: .bold)` → `.custom("Manrope-Bold", size: 15, relativeTo: .subheadline)`
6. Hero title/subtitle fonts: `.font(.system(.title3, design: .rounded, weight: .bold))` → `.font(.luminaTitle)`; `.font(.subheadline)` → `.font(.luminaSubheadline)`; Begin label font `.system(.body, design: .rounded, weight: .semibold)` → `.font(.luminaCardTitle)`
7. Hero corner radius: `RoundedRectangle(cornerRadius: 22)` → `RoundedRectangle(cornerRadius: 24, style: .continuous)`
8. `statTile`: replace `.padding(.vertical, 12).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))` with `.padding(.vertical, 14)` + `.luminaCard(padding: 0)`; value font → `.font(.luminaTitle)`, label font → `.font(.luminaCaption)`
9. `programCard`: replace `.padding(14).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))` with `.luminaCard(padding: 14)`; icon tile keeps `Color.accentColor` (now teal) but change its background to `Color.luminaMintTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous)`; title font → `.font(.luminaCardTitle)`, subtitle → `.font(.luminaCaption)`
10. "For You" section header font → `.font(.luminaTitle)`

- [ ] **Step 3: CustomTabBar edits**

1. Active pill fill (line ~83): `Capsule().fill(Color.accentColor.opacity(0.12))` → `Capsule().fill(Color.luminaMintTint)`
2. Active foreground (line ~74): `Color.accentColor` → `Color.luminaPrimary`; inactive stays `Color(.systemGray)`
3. Bar shadow (line ~48): `.shadow(color: .black.opacity(0.14), radius: 22, x: 0, y: 6)` → `.shadow(color: Color.luminaPrimary.opacity(0.14), radius: 22, x: 0, y: 6)`
4. Active label font (line ~68): `.font(.system(size: 12, weight: .semibold))` → `.font(.custom("Manrope-SemiBold", size: 12, relativeTo: .caption))`

- [ ] **Step 4: Build** (build command from Global Constraints). Expected: succeeds, no warnings about missing symbols.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift" "Breath - Relax & Stretch/Views/Home/CustomTabBar.swift"
git commit -m "style: Lumina restyle for Today tab and floating tab bar"
```

---

### Task 4: Breathe tab

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Breathing/BreathingView.swift`

**Interfaces:**
- Consumes: `Color.lumina*`, `Font.lumina*`, `LuminaPillButtonStyle`.

- [ ] **Step 1: View the mock** `~/Downloads/stitch_stretching_app_ui_redesign/breathing/screen.png` and read `BreathingView.swift` in full.

- [ ] **Step 2: Apply the global re-token mapping** (see table at top). Screen-specific requirements:

1. Page background `Color(.systemBackground)` (line ~326) → `Color.luminaSurface`.
2. Pattern selector cards (lines ~137–156): selected card = `Color.luminaPrimary` fill with `Color.luminaOnPrimary` icon/text (replace the `Color.accentColor` fill and `.white` foregrounds); unselected = `Color.luminaContainer` fill with `Color.luminaPrimary` icon and `.luminaOnSurface` text; radius stays; selected shadow → `Color.luminaPrimary.opacity(0.3)`.
3. Rounds stepper container (line ~264): `Color(.secondarySystemFill)` → `Color.luminaContainer`, radius 12 stays (input-like element).
4. Start button (lines ~296–299): keep the `Button`, replace the manual `.background(Color.accentColor)/.foregroundStyle(.white)/.clipShape(Capsule())/.shadow(...)` stack with `.buttonStyle(LuminaPillButtonStyle())` and `.frame(maxWidth: .infinity)` preserved on the label.
5. Completion screen (lines ~326–397): stat container fills → `Color.luminaContainer`; done/next capsules → same `LuminaPillButtonStyle()` treatment as Start; leave the `.green` check color.
6. Headline fonts per mapping table (screen title → `.luminaHeadline` if it uses a rounded bold system font; otherwise leave navigation-title styling alone).
7. Breathing circle: the animated rings keep their existing color logic (`circleColor` follows the accent, already teal via Task 2) — no structural change.

- [ ] **Step 3: Build.** Expected: success.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Breathing/BreathingView.swift"
git commit -m "style: Lumina restyle for Breathe tab"
```

---

### Task 5: Body Map tab

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift`

**Interfaces:**
- Consumes: `Color.lumina*`, `Font.lumina*`, `LuminaChip`, `LuminaPillButtonStyle`.

- [ ] **Step 1: View the mock** `~/Downloads/stitch_stretching_app_ui_redesign/body_map/screen.png`; run `graphify query "BodyMapView layer picker chips find exercises summary bar"`; read `BodyMapView.swift`.

- [ ] **Step 2: Restyle**

1. Layer picker (Skin/Muscle/Skeleton) and Front/Back toggle: replace the existing segmented/chip control's styling with `LuminaChip(title:isSelected:action:)` per layer — selected = orange per mock. Keep the exact same selection state variables and actions. If the control is a `Picker(.segmented)`, wrap the options in an `HStack` of `LuminaChip`s bound to the same state instead.
2. Page background → `Color.luminaSurface`; the 3D canvas container card (if any card frame exists around the SceneKit view) → `.luminaCard(padding: 0)`.
3. Bottom summary bar ("N areas marked" + Find Exercises): container → `.luminaCard(padding: 16)`; count text → `.font(.luminaTitle)`; the Find Exercises button → `.buttonStyle(LuminaPillButtonStyle())`.
4. Fonts per global mapping table.
5. Do NOT touch `BodyFigureCanvas`, `MuscleAnatomyCanvas`, `SkeletonAnatomyCanvas`, annotation overlay logic, or camera/marking code.

- [ ] **Step 3: Build.** Expected: success.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodyMapView.swift"
git commit -m "style: Lumina restyle for Body Map tab"
```

---

### Task 6: Exercises tab + Exercise Detail

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift`
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseDetailView.swift`

**Interfaces:**
- Consumes: `Color.lumina*`, `Font.lumina*`, `.luminaCard()`, `LuminaChip`, `LuminaPillButtonStyle`.

- [ ] **Step 1: View the mocks** `exercises/screen.png` and `exercise_detail/screen.png`; read both Swift files.

- [ ] **Step 2: ExerciseListView** — apply global mapping: page background → `luminaSurface`; row/card fills → `.luminaCard()` (radius 24 only on standalone cards; if rows live in a `List`, set `.scrollContentBackground(.hidden)` + `.background(Color.luminaSurface)` and give rows `.listRowBackground(Color.luminaCardFill)` instead of forcing cards); big page title → `.font(.luminaDisplay)` per mock; empty-state "Refresh List" (or equivalent primary CTA) → `LuminaPillButtonStyle()`; filter chips (if present) → `LuminaChip`.

- [ ] **Step 3: ExerciseDetailView** — per mock: category/muscle chips at top → static chip look (`.font(.luminaLabel)`, blue chip = `Color.luminaBlue.opacity(0.15)` bg + `luminaBlue` text; body-area chip = `Color.luminaOrange` bg + `luminaOnOrange` text); title → `.font(.luminaHeadline)`; description → `.font(.luminaBody)` with `.luminaOnSurfaceVariant`; instruction steps → each step in `.luminaCard()` with a leading 28pt circle `Color.luminaPrimary` containing the step number in `Color.luminaOnPrimary` + `.font(.luminaLabel)` (only if the view already renders numbered steps — do not invent steps data); timer/start button → `LuminaPillButtonStyle()`; page background → `luminaSurface`.

- [ ] **Step 4: Build.** Expected: success.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift" "Breath - Relax & Stretch/Views/Exercises/ExerciseDetailView.swift"
git commit -m "style: Lumina restyle for Exercises tab and Exercise Detail"
```

---

### Task 7: Routines tab + Program Library

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`
- Modify: `Breath - Relax & Stretch/Views/Monetization/GuidedProgramsView.swift`

**Interfaces:**
- Consumes: `Color.lumina*`, `Font.lumina*`, `.luminaCard()`, `LuminaChip`.

- [ ] **Step 1: View the mocks** `routines/screen.png` and `program_library/screen.png`; read both Swift files.

- [ ] **Step 2: RoutineListView** — global mapping, plus: the Guided Programs / Content Packs entry rows → `.luminaCard(padding: 14)` with leading icon in a `Color.luminaMintTint` circle (`Color.luminaPrimary` icon, 44pt); screen title styling per mock (teal `.font(.luminaTitle)` if inline nav title is custom; otherwise leave system nav title); empty state: icon in a `Color.luminaContainer` circle, "No Routines Yet" → `.font(.luminaHeadline)`, subtitle → `.font(.luminaBody)` + `.luminaOnSurfaceVariant`.

- [ ] **Step 3: GuidedProgramsView** — program cards per mock: full-width cards with 24pt continuous radius; if the current cards have no imagery, use a `LinearGradient(colors: [.luminaGradientStart, .luminaGradientEnd] ...)` fill with the title in white `.font(.luminaTitle)` bottom-left and a duration chip (`.font(.luminaLabel)`, `Color.black.opacity(0.35)` capsule, white text) top/bottom-left per mock; filter chips row (if any) → `LuminaChip` with orange selected. Do not add bookmark buttons or FEATURED badges — style what exists.

- [ ] **Step 4: Build.** Expected: success.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift" "Breath - Relax & Stretch/Views/Monetization/GuidedProgramsView.swift"
git commit -m "style: Lumina restyle for Routines tab and Program Library"
```

---

### Task 8: Profile tab + Session Complete

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileView.swift`
- Modify: `Breath - Relax & Stretch/Views/Session/SessionSummaryView.swift`

**Interfaces:**
- Consumes: `Color.lumina*`, `Font.lumina*`, `.luminaCard()`, `LuminaPillButtonStyle`.

- [ ] **Step 1: View the mocks** `profile/screen.png` and `session_complete/screen.png`; read both Swift files.

- [ ] **Step 2: ProfileView** — global mapping, plus: the Account/Settings/Appearance segment control → container `Color.luminaContainer` capsule/rounded-16; selected segment = `Color.luminaCardFill` rounded-12 with `Color.luminaPrimary` icon+label, unselected = `.luminaOnSurfaceVariant` (keep the existing selection state and tab views untouched); section header text (SECURITY/ACCOUNT-style) → `.font(.luminaLabel)` + `.luminaOnSurfaceVariant`; rows/cards → `.luminaCard()` or `.listRowBackground(Color.luminaCardFill)` per the List rule from Task 6; toggles → `.tint(Color.luminaPrimary)`; page title → `.font(.luminaDisplay)` only if it's already a custom text title.

- [ ] **Step 3: SessionSummaryView** (67 lines — small) — per mock: background = `LinearGradient(colors: [Color.luminaMintTint, Color.luminaSurface], startPoint: .top, endPoint: .bottom).ignoresSafeArea()`; check icon in a white circle (88pt, `.luminaCardFill`, soft shadow) with `Color.luminaPrimary` checkmark; "Session Complete" → `.font(.luminaHeadline)` + `Color.luminaPrimary`; each stat (minutes/exercises/points) → `.luminaCard()` with value `.font(.luminaHeadline)` and uppercase label `.font(.luminaLabel)` + `.luminaOnSurfaceVariant`; points accent → `Color.luminaOrange` icon + `Color.luminaPrimary` value per mock; Done button → `LuminaPillButtonStyle()` full width.

- [ ] **Step 4: Build.** Expected: success.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Profile/ProfileView.swift" "Breath - Relax & Stretch/Views/Session/SessionSummaryView.swift"
git commit -m "style: Lumina restyle for Profile tab and Session Complete"
```

---

### Task 9: Full verification + graph update

**Files:**
- Modify: none expected (fix-ups only if verification finds regressions)

- [ ] **Step 1: Run the full unit test suite** (unit-test command). Expected: all suites pass, including `LuminaFontsTests` and `LuminaThemeTests`.

- [ ] **Step 2: Screenshot verification** — invoke the repo `verify` skill (`.claude/skills/verify/SKILL.md`) to launch the app in the iPhone 17 simulator and capture: each of the 6 tabs, one Exercise Detail, and Session Complete (finish a 1-exercise session or use the skill's launch-arg state injection). Capture light mode first, then dark (`xcrun simctl ui booted appearance dark`), re-shooting the 6 tabs.

- [ ] **Step 3: Compare against mocks** — read each screenshot next to its mock PNG. Checklist per screen: Manrope actually rendering (if text looks like SF, font registration is broken — stop and fix); page background is off-white `#F8FAFB` not gray; cards are white with 24pt radii; primary buttons are teal pills; chips orange when selected; dark mode legible (no dark-text-on-dark-card).

- [ ] **Step 4: Dynamic Type spot check** — relaunch Today with `xcrun simctl ui booted content_size accessibility-extra-large`; confirm the hero card text scales and nothing truncates to invisibility. Reset with `xcrun simctl ui booted content_size medium`.

- [ ] **Step 5: Update the knowledge graph**

```bash
graphify update .
```

- [ ] **Step 6: Commit any fix-ups**

```bash
git add -A && git commit -m "style: Lumina restyle verification fix-ups" || echo "nothing to fix"
```
