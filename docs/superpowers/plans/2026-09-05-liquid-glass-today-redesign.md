# Liquid Glass Today Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Force the app into a permanent black/dark theme, remove every cyan/teal color, replace the primary accent with a light amber and the roadmap's per-node coloring with the app's existing 8-color `ExerciseCategory.accentColor` system, and apply real SwiftUI Liquid Glass material (`.glassEffect()`, `GlassEffectContainer`) to `TodayView`'s hero card, `RoadmapWave`, and `CustomTabBar` so they read as one continuous surface.

**Architecture:** This is a token-and-material pass, not a structural rewrite. Color changes flow from three files (`LuminaTheme.swift`, `ExerciseCategory.swift`, and two literal-`Color.cyan` call sites) that already act as the app's shared palette — repointing them cascades correctly to every screen with no per-screen edits needed for color. Material changes are scoped narrowly to the three named views; every other screen keeps its current flat `luminaCardFill`/`luminaSurface` look.

**Tech Stack:** SwiftUI (iOS 26.5 deployment target — real `.glassEffect()`/`GlassEffectContainer` API, not an emulation), Swift Testing (`@Test`/`#expect`, not XCTest) for unit tests, existing XCUITest screenshot harness for visual review.

**Spec:** `docs/superpowers/specs/2026-09-05-liquid-glass-today-redesign-design.md`

## Global Constraints

- Branch: `liquid-glass-redesign` (already created off `main`, in sync at branch time). Per explicit instruction: **do not commit** — every task below still ends with a "Commit" step for the record, but the executor should stage and leave the work uncommitted, or the human will handle committing. If your execution mode insists on running the commit step, that's fine to skip/no-op here — leaving changes uncommitted on this branch is the actual requirement.
- No new persisted state, no data model changes, no changes to `RoadmapWaveGeometry`'s layout math (positions/sizes/focus-scaling untouched — color only).
- No other screen's card *material* changes (Routines, Profile, Exercises list, Onboarding, Auth, Breathing, etc.) — they inherit the new color tokens automatically but keep their current flat surfaces.
- Swift Testing syntax throughout (`import Testing`, `@Test`, `#expect`) — this codebase does not use XCTest for unit tests (XCTest is reserved for the UI test target).
- Module name for `@testable import` is `BreathRelaxStretch`.

---

## Task 1: Force dark theme app-wide, retire the now-dead Appearance picker

**Files:**
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift:48-58`
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileAppearanceTab.swift:1-77`
- Modify: `Breath - Relax & StretchUITests/LuminaRestyleScreenshotTests.swift:32-39,60-68`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing other tasks depend on — this task only removes the light/system code paths.

The app already has a user-facing Appearance picker (`Profile > Appearance > Theme`, backed by `@AppStorage("colorSchemeOverride")`, 0=System/1=Light/2=Dark, defaulting to Dark). Forcing black means this picker no longer does anything meaningful, so it should come out rather than stay as dead UI, and the two UI tests that exercise the light-mode path via `-colorSchemeOverride 1` need to go with it (they're screenshot-only, not assertions, so removing them isn't "deleting a failing test to get green" — it's removing tests for a code path that no longer exists).

- [ ] **Step 1: Change `resolvedColorScheme` to unconditionally return `.dark`**

In `Breath__Relax___StretchApp.swift`, replace:

```swift
    // 0 = System, 1 = Light, 2 = Dark (set in Profile > Appearance). New
    // installs default to Dark for a sleeker first impression; the picker
    // there lets users opt back to System or Light.
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = 2
    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemeOverride {
        case 1:  return .light
        case 2:  return .dark
        default: return nil
        }
    }
```

with:

```swift
    // The app is dark-only (Liquid Glass redesign, 2026-09-05) — there is no
    // user-facing light mode or system-follow option anymore. This used to
    // read a Profile > Appearance picker; that picker is gone (see
    // ProfileAppearanceTab.swift), so this always resolves to dark.
    private var resolvedColorScheme: ColorScheme? { .dark }
```

- [ ] **Step 2: Remove the dead "Theme" section from `ProfileAppearanceTab.swift`**

Delete the `colorSchemeOverride` property and the whole `Section("Theme") { ... }` block:

```swift
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = 2
```

```swift
            // Theme
            Section("Theme") {
                Picker(selection: $colorSchemeOverride) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                } label: {
                    Label("Color Scheme", systemImage: "circle.lefthalf.filled")
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }

```

Also delete the now-inaccurate comment above `accentColorName` referencing the removed default-sync concern:

```swift
    // Keep this default in sync with BreathRelaxStretchApp's colorSchemeOverride
    // default (2 = Dark) so the picker's initial selection always matches what
    // the app is actually rendering for a fresh install.
```

- [ ] **Step 3: Remove the two light-mode-only screenshot tests**

In `LuminaRestyleScreenshotTests.swift`, delete `testAuthScreenLight()` (lines 32-39) and `testOnboardingWelcomeLight()` (lines 60-68) in full — both exist solely to force light mode via `-colorSchemeOverride 1`, which no longer has any effect now that `resolvedColorScheme` is hardcoded.

- [ ] **Step 4: Build to confirm no dangling references**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -quiet`
Expected: build succeeds (confirms no remaining `colorSchemeOverride` reference anywhere in the app target, and the deleted test methods compile cleanly out).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift" \
        "Breath - Relax & Stretch/Views/Profile/ProfileAppearanceTab.swift" \
        "Breath - Relax & StretchUITests/LuminaRestyleScreenshotTests.swift"
git commit -m "Force dark theme app-wide, retire light/system appearance option"
```

---

## Task 2: Retire cyan/teal in the shared color tokens

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Theme/LuminaTheme.swift:22-43`
- Modify: `Breath - Relax & StretchTests/LuminaThemeTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `Color.luminaPrimary`, `Color.luminaOnPrimary`, `Color.luminaGradientStart`, `Color.luminaGradientEnd`, `Color.luminaMintTint` — same names, new hex values. Every later task that references these tokens (Tasks 4, 5, 6) relies on this task landing first so the amber values are in place when they build.

- [ ] **Step 1: Write the failing tests**

Add to `LuminaThemeTests.swift` (append inside the existing `LuminaThemeTests` struct, after `surfaceIsDynamic`):

```swift
    /// Amber (new) has red > blue; the old teal/mint-cyan had blue >= red.
    /// This is a real regression test, not just an existence check — it
    /// would fail if `luminaPrimary`'s dark value were ever reverted to
    /// its old cyan hex (0x6ED8C5: R=110, G=216, B=197).
    @Test("primary dark value is warm (red > blue), not cyan")
    func primaryDarkIsWarm() {
        let resolved = UIColor(Color.luminaPrimary)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r > b)
    }

    @Test("gradient start dark value is warm (red > blue), not cyan")
    func gradientStartDarkIsWarm() {
        let resolved = UIColor(Color.luminaGradientStart)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r > b)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/LuminaThemeTests`
Expected: FAIL on both new tests (current dark values have blue >= red — `luminaPrimary` dark is `0x6ED8C5`, `luminaGradientStart` dark is `0x2E7D7D`).

- [ ] **Step 3: Repoint the tokens in `LuminaTheme.swift`**

Replace:

```swift
    static let luminaPrimary          = Color(UIColor.lumina(light: 0x00685B, dark: 0x6ED8C5))
    static let luminaOnPrimary        = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x00382F))
    static let luminaPrimaryContainer = Color(UIColor.lumina(light: 0x008374, dark: 0x005046))
    static let luminaMintTint         = Color(UIColor.lumina(light: 0xD7F2EA, dark: 0x17332E))
```

with:

```swift
    static let luminaPrimary          = Color(UIColor.lumina(light: 0xB5540A, dark: 0xFFB454))
    static let luminaOnPrimary        = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x2B1400))
    static let luminaPrimaryContainer = Color(UIColor.lumina(light: 0x008374, dark: 0x005046))
    static let luminaMintTint         = Color(UIColor.lumina(light: 0xFFE9D2, dark: 0x33230F))
```

(`luminaPrimaryContainer` is unused dead code already — leave it; it isn't referenced anywhere in the app and touching it is out of scope for this pass.)

And replace:

```swift
    static let luminaGradientStart    = Color(UIColor.lumina(light: 0x4AC4C4, dark: 0x2E7D7D))
    static let luminaGradientEnd      = Color(UIColor.lumina(light: 0x7663F1, dark: 0x4A3D99))
```

with:

```swift
    static let luminaGradientStart    = Color(UIColor.lumina(light: 0xFFCB84, dark: 0xC97A2E))
    static let luminaGradientEnd      = Color(UIColor.lumina(light: 0xD9701A, dark: 0x8A4008))
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/LuminaThemeTests`
Expected: PASS on all four tests (the two pre-existing dynamic-ness tests still pass unchanged — light and dark are still distinct values — plus the two new warm-color tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Theme/LuminaTheme.swift" \
        "Breath - Relax & StretchTests/LuminaThemeTests.swift"
git commit -m "Repoint luminaPrimary/gradient/mintTint tokens from cyan/teal to amber"
```

---

## Task 3: Fix the one cyan-adjacent exercise category color

**Files:**
- Modify: `Breath - Relax & Stretch/Models/ExerciseCategory.swift` (the `accentColor` switch)
- Modify: `Breath - Relax & StretchTests/ExerciseCategoryTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `ExerciseCategory.neck.accentColor == Color.red` — Task 5 (RoadmapWave) reads `category.accentColor` for every category including `.neck`, so it picks this up automatically once this task lands.

`ExerciseCategory.accentColor` already assigns one color per category and is already used by `PoseGlyphIcon` (the Exercises tab's category graph and every roadmap node glyph already tint through it). Only `.neck` is cyan-adjacent (`.teal`); every other category color is fine as-is.

- [ ] **Step 1: Write the failing test**

Add to `ExerciseCategoryTests.swift` (append inside the `ExerciseCategoryTests` struct):

```swift
    @Test func neckAccentColorIsNotCyanAdjacent() {
        #expect(ExerciseCategory.neck.accentColor != Color.teal)
        #expect(ExerciseCategory.neck.accentColor == Color.red)
    }
```

This needs `import SwiftUI` at the top of the file alongside the existing `import Testing` / `@testable import BreathRelaxStretch` — add it if not already present.

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/ExerciseCategoryTests/neckAccentColorIsNotCyanAdjacent`
Expected: FAIL — `ExerciseCategory.neck.accentColor` is currently `.teal`, so both `#expect`s fail (the inequality check fails first).

- [ ] **Step 3: Change the neck case**

In `ExerciseCategory.swift`, inside `accentColor`, replace:

```swift
                        case .neck:       return .teal
```

with:

```swift
                        case .neck:       return .red
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/ExerciseCategoryTests`
Expected: PASS on the new test and every pre-existing `ExerciseCategoryTests` test (none of them assert on `accentColor`, so they're unaffected).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/ExerciseCategory.swift" \
        "Breath - Relax & StretchTests/ExerciseCategoryTests.swift"
git commit -m "Replace ExerciseCategory.neck's cyan-adjacent accent color with red"
```

---

## Task 4: Remove the two literal `Color.cyan` call sites

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift:176-221`
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift:647-656`
- Test: `Breath - Relax & StretchTests/CandidatePaletteTests.swift` (new file)

**Interfaces:**
- Consumes: `Color.luminaPrimary`, `Color.luminaOrange` (already amber-family after Task 2 — `luminaOrange` was never cyan and is untouched).
- Produces: nothing later tasks depend on.

These two spots are structurally different, so they get different fixes:

- `ExerciseListView`'s `searchBar` uses `Color.cyan` three times as a deliberate shimmer effect (icon tint, a 3-stop border gradient, two shadows) — replace the whole cyan/mint shimmer with an amber-family one using tokens that already exist.
- `BodySceneView`'s `CandidatePalette` is a 4-color deterministic palette for simultaneous body-map markers (`blue`, `cyan`, `indigo`, `amber`) — only the `cyan` entry needs replacing, with a hue that stays visually distinct from the other three.

- [ ] **Step 1: Replace the search bar's cyan/mint shimmer**

In `ExerciseListView.swift`, replace:

```swift
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.cyan.opacity(0.95))
```

with:

```swift
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.luminaPrimary.opacity(0.95))
```

and replace:

```swift
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.58),
                            Color.mint.opacity(0.34),
                            Color.cyan.opacity(0.50)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .shadow(color: Color.cyan.opacity(0.18), radius: 7, x: 0, y: 0)
        .shadow(color: Color.mint.opacity(0.10), radius: 11, x: 0, y: 0)
```

with:

```swift
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.luminaPrimary.opacity(0.58),
                            Color.luminaOrange.opacity(0.34),
                            Color.luminaPrimary.opacity(0.50)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .shadow(color: Color.luminaPrimary.opacity(0.18), radius: 7, x: 0, y: 0)
        .shadow(color: Color.luminaOrange.opacity(0.10), radius: 11, x: 0, y: 0)
```

- [ ] **Step 2: Write the failing test for `CandidatePalette`**

Create `Breath - Relax & StretchTests/CandidatePaletteTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@Suite("Body map candidate palette")
struct CandidatePaletteTests {
    @Test("palette has no cyan entry")
    func noCyanEntry() {
        // The old index-1 entry was Color(red: 0.17, green: 0.71, blue: 0.79)
        // — cyan (blue and green both far exceed red). Every entry should
        // now have red as its largest or a close, non-cyan-shaped component.
        for color in CandidatePalette.colors {
            let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
            let isCyanShaped = b > 0.6 && g > 0.6 && r < 0.3
            #expect(!isCyanShaped, "Found a cyan-shaped color in CandidatePalette: r=\(r) g=\(g) b=\(b)")
        }
    }

    @Test("palette still has four distinct colors")
    func fourDistinctColors() {
        #expect(CandidatePalette.colors.count == 4)
        #expect(Set(CandidatePalette.colors.map { $0.description }).count == 4)
    }
}
```

- [ ] **Step 3: Run the tests to verify `noCyanEntry` fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/CandidatePaletteTests`
Expected: `noCyanEntry` FAILS (index 1 is currently the cyan `Color(red: 0.17, green: 0.71, blue: 0.79)`); `fourDistinctColors` PASSES already.

- [ ] **Step 4: Replace the cyan entry**

In `BodySceneView.swift`, replace:

```swift
enum CandidatePalette {
    static let colors: [Color] = [
        Color(red: 0.23, green: 0.51, blue: 0.84),   // blue
        Color(red: 0.17, green: 0.71, blue: 0.79),   // cyan
        Color(red: 0.48, green: 0.42, blue: 0.94),   // indigo
        Color(red: 0.88, green: 0.54, blue: 0.29),   // amber (neighbour muscle)
    ]
```

with:

```swift
enum CandidatePalette {
    static let colors: [Color] = [
        Color(red: 0.23, green: 0.51, blue: 0.84),   // blue
        Color(red: 0.36, green: 0.68, blue: 0.44),   // green (was cyan)
        Color(red: 0.48, green: 0.42, blue: 0.94),   // indigo
        Color(red: 0.88, green: 0.54, blue: 0.29),   // amber (neighbour muscle)
    ]
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/CandidatePaletteTests`
Expected: PASS on both tests.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift" \
        "Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift" \
        "Breath - Relax & StretchTests/CandidatePaletteTests.swift"
git commit -m "Remove literal Color.cyan from search bar shimmer and body map palette"
```

---

## Task 5: RoadmapWave — neutral wave line, per-category node colors, category-tracking focus glow

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift`
- Modify: `Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift`

**Interfaces:**
- Consumes: `ExerciseCategory.primary(for:) -> ExerciseCategory` (existing), `ExerciseCategory.accentColor -> Color` (existing, fixed by Task 3), `RoadmapWaveGeometry.x(at:padding:) -> CGFloat` (existing).
- Produces: nothing later tasks depend on (Task 6 uses the same `.glassEffect` pattern but on a different file/view).

- [ ] **Step 1: Write the failing smoke test**

Add to `RoadmapWaveRenderingTests.swift` (append inside the struct; needs `ExerciseCategory.primary` to actually diverge across nodes, so this uses varied `targetBodyParts` instead of the shared helper's fixed `["Lower Back"]`):

```swift
    @Test func rendersWithMixedCategoryExercisesWithoutCrashing() {
        let exercises = [
            Exercise(name: "Seated Neck Rolls", type: .stretch, targetBodyParts: ["Head"],
                     durationSeconds: 35, difficulty: 1, instructions: [], cueStyle: .hold),
            Exercise(name: "Shoulder Roll", type: .stretch, targetBodyParts: ["Left Shoulder"],
                     durationSeconds: 60, difficulty: 1, instructions: [], cueStyle: .hold),
            Exercise(name: "Cobra Stretch", type: .stretch, targetBodyParts: ["Left Chest"],
                     durationSeconds: 45, difficulty: 1, instructions: [], cueStyle: .hold),
        ]
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises, numbered: true).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }
```

This will actually compile and pass even before the implementation change below (it's exercising a code path, not asserting a specific color) — that's fine here: its job is to catch a *crash* in the new per-node category lookup, and Step 2 confirms it currently passes on the old flat-color code so Step 4 has to still pass after the real change lands, not regress.

- [ ] **Step 2: Run the test to confirm it passes on the current code (baseline)**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/RoadmapWaveRenderingTests/rendersWithMixedCategoryExercisesWithoutCrashing`
Expected: PASS (this is the pre-change baseline the next steps must not break).

- [ ] **Step 3: Make the wave path stroke neutral**

In `RoadmapWave.swift`, inside `RoadmapWaveCurve.body`, replace:

```swift
            let gradient = Gradient(colors: [Color.luminaGradientStart, Color.luminaGradientEnd])
```

with:

```swift
            // Color now lives on the nodes (see nodeView), not the
            // connecting line — a neutral gradient here keeps the curve
            // from competing with each node's category color.
            let gradient = Gradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.2)])
```

- [ ] **Step 4: Color the order badge per node's category**

In `nodeView(index:exercise:)`, replace:

```swift
            if numbered {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: RoadmapWaveGeometry.orderBadgeSize, height: RoadmapWaveGeometry.orderBadgeSize)
                    .background(Color.luminaPrimary, in: Circle())
```

with:

```swift
            if numbered {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: RoadmapWaveGeometry.orderBadgeSize, height: RoadmapWaveGeometry.orderBadgeSize)
                    .background(category.accentColor, in: Circle())
```

(`category` is already computed at the top of `nodeView` via `ExerciseCategory.primary(for: exercise.targetBodyParts)` — this reuses it rather than adding a second lookup.)

- [ ] **Step 5: Make `focusGlow` track the centered exercise's category color**

Add a new computed property right above `focusGlow` (it needs `exercises`, `padding`, and `focusCenterX`, all already properties on `RoadmapWave`):

```swift
    /// The category color of whichever exercise is nearest the viewport
    /// center right now — feeds `focusGlow` so the ambient glow always
    /// matches the category color of the node it's actually glowing
    /// behind, instead of a fixed color regardless of which node is
    /// focused.
    private var focusedCategoryColor: Color {
        guard !exercises.isEmpty else { return .luminaPrimary }
        let nearestIndex = exercises.indices.min { lhs, rhs in
            let lhsDistance = abs(RoadmapWaveGeometry.x(at: lhs, padding: padding) - focusCenterX)
            let rhsDistance = abs(RoadmapWaveGeometry.x(at: rhs, padding: padding) - focusCenterX)
            return lhsDistance < rhsDistance
        }!
        return ExerciseCategory.primary(for: exercises[nearestIndex].targetBodyParts).accentColor
    }
```

Then replace `focusGlow`'s body:

```swift
    private var focusGlow: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.luminaPrimary.opacity(0.28),
                Color.luminaPrimary.opacity(0.12),
                Color.clear,
            ]),
            center: .center,
            startRadius: 0,
            endRadius: RoadmapWaveGeometry.maxNodeSize * 1.1
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
```

with:

```swift
    private var focusGlow: some View {
        let color = focusedCategoryColor
        return RadialGradient(
            gradient: Gradient(colors: [
                color.opacity(0.28),
                color.opacity(0.12),
                Color.clear,
            ]),
            center: .center,
            startRadius: 0,
            endRadius: RoadmapWaveGeometry.maxNodeSize * 1.1
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
```

- [ ] **Step 6: Confirm `RoadmapWave` has no separate background to reconcile**

`RoadmapWave` itself has no opaque/flat background layer today — its only `.background` is the `focusGlow` `GeometryReader` block, and it renders transparently everywhere it's embedded (inside `TodayView.heroCard`'s `ZStack`, and directly on `CustomizeRoutineView`/`MiniRoutineReviewView`'s own screens). Concretely, that means once Task 6 gives `heroCard` its glass fill, `RoadmapWave` inherits that same glass automatically — for free — because it's transparent content sitting inside it, not a separate surface next to it. **Do not add a background to `RoadmapWave` here.** Adding one (e.g. a second nested `.glassEffect`) would draw a second glass panel *around just the wave*, inside the hero's glass panel — reintroducing exactly the "two surfaces" seam this task exists to remove. This step is a verification checkpoint, not a code change: re-read `RoadmapWave.body` after Steps 3-5 and confirm no new `.background` was added.

- [ ] **Step 7: Run the tests to verify everything still renders without crashing**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:BreathRelaxStretchTests/RoadmapWaveRenderingTests`
Expected: PASS on every test in the file, including the new `rendersWithMixedCategoryExercisesWithoutCrashing` and all pre-existing ones (`RoadmapWaveGeometryTests` is untouched and unaffected — no layout math changed).

- [ ] **Step 8: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/RoadmapWave.swift" \
        "Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift"
git commit -m "RoadmapWave: neutral wave line, per-category node badge and focus-glow colors"
```

---

## Task 6: TodayView hero card — glass background, tinted-glass Begin, ghost-glass Customize

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift:445-556`

**Interfaces:**
- Consumes: `Color.luminaPrimary` (amber, from Task 2).
- Produces: nothing later tasks depend on.

This task has no dedicated new unit test: `heroCard` is a private view builder inside `TodayView` with no existing render-smoke-test infrastructure the way `RoadmapWave` has (`RoadmapWaveRenderingTests` targets `RoadmapWave` directly because it's a standalone, reusable type — `TodayView` is not). Verification for this task is the build (Step 1 below) plus the full screenshot pass in Task 8, which is exactly the pattern `LuminaRestyleScreenshotTests.swift` already uses for this kind of visual-only change ("Not assertions of behavior — screenshot for visual review").

- [ ] **Step 1: Replace the hero's gradient background with tinted glass**

In `TodayView.swift`, inside `heroCard`, replace:

```swift
        return ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color.luminaGradientStart, Color.luminaGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
```

with:

```swift
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(Color.luminaPrimary.opacity(0.16)),
                             in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
```

- [ ] **Step 2: Convert the Begin button to tinted glass**

Replace:

```swift
                    Button {
                        showingSession = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Begin")
                            if mins > 0 {
                                Text("\(mins) min")
                                    .font(.luminaCaption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.luminaOnPrimary.opacity(0.18), in: Capsule())
                            }
                        }
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaOnPrimary)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(Color.luminaPrimary, in: Capsule())
                        .shadow(color: Color.luminaPrimary.opacity(0.35), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Begin today's session: \(sessionExercises.count) exercises, \(mins) minutes")
```

with:

```swift
                    Button {
                        showingSession = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Begin")
                            if mins > 0 {
                                Text("\(mins) min")
                                    .font(.luminaCaption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.white.opacity(0.14), in: Capsule())
                            }
                        }
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaPrimary)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .glassEffect(.regular.tint(Color.luminaPrimary), in: Capsule())
                        .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Begin today's session: \(sessionExercises.count) exercises, \(mins) minutes")
```

(Foreground moves from `luminaOnPrimary`, which was designed for text on an *opaque* fill, to `luminaPrimary` itself — the surface is translucent now, so bright-amber-on-dark-glass is the pairing that needs to read.)

- [ ] **Step 3: Convert the Customize button to ghost glass**

Replace:

```swift
                    Button {
                        showingCustomize = true
                    } label: {
                        Text("Customize")
                            .font(.luminaLabel)
                            .foregroundStyle(.white.opacity(0.8))
                            .underline()
                    }
                    .buttonStyle(.plain)
```

with:

```swift
                    Button {
                        showingCustomize = true
                    } label: {
                        Text("Customize")
                            .font(.luminaLabel)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .glassEffect(.regular, in: Capsule())
                    }
                    .buttonStyle(.plain)
```

- [ ] **Step 4: Build to confirm it compiles and run the app once to eyeball it**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -quiet`
Expected: build succeeds. Full visual confirmation happens in Task 8's screenshot pass.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "TodayView hero: tinted-glass background, glass Begin/Customize buttons"
```

---

## Task 7: CustomTabBar — real Liquid Glass, neutral indicator, amber active state

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/CustomTabBar.swift:39-104`

**Interfaces:**
- Consumes: `Color.luminaPrimary` (amber, from Task 2), `Color.luminaMintTint` (now pale-peach, from Task 2).
- Produces: nothing later tasks depend on.

Like Task 6, this is visual-only with no dedicated unit test — verified by build + Task 8's screenshot pass.

- [ ] **Step 1: Replace `.regularMaterial` with a real `GlassEffectContainer`**

Replace:

```swift
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(Color(.systemGray5).opacity(0.8), lineWidth: 0.5)
                }
                .shadow(color: Color.luminaPrimary.opacity(0.14), radius: 22, x: 0, y: 6)
        }
```

with:

```swift
        .background {
            GlassEffectContainer {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30))
            }
            .shadow(color: Color.luminaPrimary.opacity(0.14), radius: 22, x: 0, y: 6)
        }
```

(The shadow already reads `Color.luminaPrimary`, so it picks up the new amber automatically once Task 2 lands — no separate edit needed there, only the material swap.)

- [ ] **Step 2: Keep the active-tab pill neutral, amber lives only on the icon/label**

The active-tab foreground is already `Color.luminaPrimary` (line 86 — `isActive ? Color.luminaPrimary : Color(.systemGray)`), which is correct as-is once Task 2 repoints the token — no change needed there. Only the pill *fill* changes, from the mint tint to a neutral glass capsule so the amber accent doesn't also saturate the container behind it:

Replace:

```swift
            .background {
                if isActive {
                    Capsule()
                        .fill(Color.luminaMintTint)
                        .matchedGeometryEffect(id: "activePill", in: ns)
                }
            }
```

with:

```swift
            .background {
                if isActive {
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular, in: Capsule())
                        .matchedGeometryEffect(id: "activePill", in: ns)
                }
            }
```

- [ ] **Step 3: Build and confirm the tab bar still compiles and animates**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -quiet`
Expected: build succeeds. Full visual/interaction confirmation (does the glass pill still slide smoothly between tabs) happens in Task 8.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/CustomTabBar.swift"
git commit -m "CustomTabBar: real Liquid Glass container, neutral active pill"
```

---

## Task 8: Full verification pass

**Files:** none modified — this task only runs things and reports back.

**Interfaces:** consumes everything from Tasks 1-7.

- [ ] **Step 1: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: PASS across the board. Per this project's own documented testing notes, a small, pre-existing set of `CuratedContentIntegrityTests` and UI-test-runner failures are known-not-regressions from unrelated prior work — don't treat those as caused by this change, but do treat any *new* failure (especially anything in `LuminaThemeTests`, `ExerciseCategoryTests`, `CandidatePaletteTests`, or `RoadmapWave*Tests`) as this plan's responsibility to fix before moving on.

- [ ] **Step 2: Build and launch in the simulator via the `verify` skill**

Follow this project's `verify` skill (`.claude/skills/verify/SKILL.md`) to build, launch, and screenshot:
- `TodayView` at rest (hero + roadmap together — confirm they now read as one glass surface, not two textures; confirm the Begin/Customize buttons read as glass, not a flat fill/bare text link).
- `CustomTabBar` across at least two tab switches (confirm the glass pill slides and merges rather than sitting on an opaque material).
- The Exercises tab's category graph (confirm the neck node is red, not teal, and no other category regressed).
- `ExerciseListView`'s search bar (confirm the amber shimmer reads cleanly, no leftover cyan).
- `BodyMapView` with multiple simultaneous markers active (confirm all four `CandidatePalette` colors are visually distinct, none reads as cyan).
- `AuthView` / `AppLockView` / the onboarding `GenderPickerPage` (confirm the retired cyan→indigo gradient now reads as an intentional warm amber→copper gradient).

- [ ] **Step 3: Manually confirm text contrast on the repointed pairs**

Specifically check: `luminaOnPrimary` dark (`0x2B1400`) against any *opaque* `luminaPrimary` fill still used on out-of-scope screens (e.g. `RoutineListView`, `BreathingView`'s selected-state fills), and `luminaMintTint`'s new pale-peach against whatever text sits on it (streak badge, chips). These are exactly the kind of pairing a hex-only token swap can silently break on a screen this pass never opens.

- [ ] **Step 4: Report status**

Summarize: tests passing (with any pre-existing-and-known failures named explicitly), screenshots captured, and any contrast or visual issue found in Step 3 — fix inline and re-verify before considering this plan done. No commit step here since nothing changed; if Step 3 turns up a fix, that fix gets its own small commit on top of Task 2/6/7 as appropriate.

---

## Plan self-review notes

- **Spec coverage:** every numbered goal in the spec has a task — forced dark (Task 1), token/literal cyan removal (Tasks 2-4), category color fix (Task 3), the three glass targets (Tasks 5-7), verification (Task 8). The spec's `luminaMintTint` fix (not in the original ask, found during spec-writing) is folded into Task 2 alongside the other token changes.
- **Placeholder scan:** no TBD/"handle appropriately"/uncoded steps — every step above has literal before/after code or an exact command.
- **Type consistency:** `category.accentColor` (Task 5) matches the existing `ExerciseCategory.accentColor -> Color` signature confirmed in `Models/ExerciseCategory.swift`; `RoadmapWaveGeometry.x(at:padding:)` matches its existing call site in `nodeView`; `Color.luminaPrimary`/`luminaOnPrimary`/`luminaGradientStart`/`luminaGradientEnd`/`luminaMintTint` are used with the exact names Task 2 defines, nowhere renamed.
- **Correction found during planning:** the spec originally attributed a flat `Color.luminaSurface` background at "RoadmapWave.swift L192" to `RoadmapWave` itself. That line is actually `TodayView.body`'s own outer `ScrollView` background — `RoadmapWave` has no background of its own at all. Both the spec and Task 5 (Step 6) have been corrected: `RoadmapWave` gets no new background, since it already inherits the hero card's glass fill for free by being transparent content inside it.
