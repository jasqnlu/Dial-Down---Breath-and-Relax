# Home + Exercises Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full redesign from `docs/superpowers/specs/2026-08-11-home-exercises-redesign-design.md`:
a horizontally-scrollable "roadmap" view of a session's exercises (Home hero + a new Customize screen),
touch-glyph icons on the Exercises tab's category circles, one unified exercise grid tile used everywhere an
exercise list currently renders (search results, category groups, Body Map), the animation-vs-glyph size
rule governing that tile, an add-mode for building/editing a routine, and Body Map's dual-mode
(quick-start-by-tapping vs. build-a-mini-routine-by-tapping-`+`).

**Architecture:** Six self-contained pieces, ordered so each later piece can depend on an earlier one but
never the reverse: (1) `RoadmapWaveGeometry`/`RoadmapWave` — pure layout math + the SwiftUI view; (2)
`TouchGlyphLibrary`/`CategoryTouchGlyph` — a second, separate glyph family for the 8 category circles; (3)
`ExerciseArt`/`ExerciseGridTile` — the shared tile applying the size rule (real `LoopingVideoThumbnail` at
≥52pt when available, `PoseGlyphIcon` otherwise), replacing `ExerciseRow` at its three call sites; (4)
`pinnedWakeUpRoutineID` + `CustomizeRoutineView` — the new screen, wired to `TodayView`; (5) `MiniRoutineState`
+ add-mode selection UI, layered onto the grid tile from (3); (6) Body Map's dual-mode, reusing (3) and (5).

**Tech Stack:** SwiftUI (`Shape`, `ScrollView`, `LazyVGrid`, `ImageRenderer`, `NavigationStack`), Swift Testing
(`@Test`/`#expect`), SwiftData (`@Query`, `Routine`), `@AppStorage`, the existing `PoseGlyphIcon`/
`PoseArchetypeMapping`/`ExerciseCategory`/`LoopingVideoThumbnail`/`Exercise` models.

## Global Constraints

- Design source: `docs/superpowers/specs/2026-08-11-home-exercises-redesign-design.md`. Every decision below
  that isn't obvious from that doc is called out inline as a **Decision** — these resolve the spec's "Open
  Questions" section concretely so no task carries a TBD:
  - **Decision (spec Q1):** roadmap nodes stay `PoseGlyphIcon` at any size — confirmed permanent exception to
    the size rule, not just a mockup simplification.
  - **Decision (spec Q2):** Add Exercises → Done **appends** newly-picked exercises to the routine's existing
    list; it does not replace it.
  - **Decision (spec Q3):** Body Map keeps tile-tap = start immediately, distinct from every other grid
    context (search results, category groups) where tile-tap = go to detail. Modeled as a third
    `ExerciseGridTile` interaction mode rather than a fork of the component.
  - **Decision (spec Q4):** Customize's duration steppers stay in the list at any routine length — no
    reorder-only fallback for long routines. The mockup's read-only labels were a shortcut for a static
    HTML file, not a real constraint.
  - **Decision:** `Exercise` is a SwiftData `@Model` class — a shared, persisted reference type. Customize's
    duration steppers must **never** mutate `exercise.durationSeconds` directly (that would silently rewrite
    the catalog for every other place that exercise appears). Overrides live in local `@State` keyed by
    `exercise.uuid` and are explicitly **not** threaded into `SessionPlayerView` by this plan — Begin starts
    the session with each exercise's real stored duration. Persisting a per-session duration override is
    called out as deferred at the end of this plan, not silently dropped.
- Node spacing in `RoadmapWave` is fixed, never fit-to-width (see Task 1).
- The animation-vs-glyph size rule (Task 6): `ExerciseArt` renders `LoopingVideoThumbnail` when
  `size >= 52` **and** `exercise.demoVideoURL != nil`; otherwise `PoseGlyphIcon`. This one threshold constant
  is the single source of truth — no call site hardcodes its own cutoff.
- Follow existing test conventions: Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest. Test
  files live in `Breath - Relax & StretchTests/`.
- Every new `Exercise` value used in a test must go through `Exercise.init` as it's actually declared in
  `Breath - Relax & Stretch/Models/Exercise.swift` — check parameter names/order there before writing test
  fixtures; do not assume the signature shown in this plan's own fixture helpers is authoritative if it drifts
  from the real file.

---

## File Structure

**Create:**
- `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift` — `RoadmapWaveGeometry`, `RoadmapWaveShape`, `RoadmapWave`.
- `Breath - Relax & Stretch/Models/TouchGlyphArchetype.swift` — `TouchGlyphArchetype`, `TouchGlyphLibrary`.
- `Breath - Relax & Stretch/Views/Exercises/CategoryTouchGlyph.swift` — the rendering view.
- `Breath - Relax & Stretch/Views/Exercises/ExerciseArt.swift` — the size-rule-aware art view.
- `Breath - Relax & Stretch/Views/Exercises/ExerciseGridTile.swift` — the shared tile (replaces `ExerciseRow` call sites).
- `Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift` — the new Customize screen.
- `Breath - Relax & Stretch/Services/MiniRoutineState.swift` — add-mode / Body Map mini-routine selection state.
- Tests: `RoadmapWaveGeometryTests.swift`, `RoadmapWaveRenderingTests.swift`, `TouchGlyphLibraryTests.swift`,
  `CategoryTouchGlyphRenderingTests.swift`, `ExerciseArtTests.swift`, `ExerciseGridTileRenderingTests.swift`,
  `MiniRoutineStateTests.swift`, `CustomizeRoutineViewRenderingTests.swift`.

**Modify:**
- `Breath - Relax & Stretch/Views/Home/TodayView.swift` — roadmap in the hero, Customize button/sheet, pinned-routine lookup.
- `Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift` — `CategoryNode` gains the touch-glyph; `ExerciseGroupCorpusSheet` becomes a push destination and renders the grid.
- `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift` — search results render the grid; add-mode banner.
- `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift` — `BodyPartExercisesView` renders the grid in dual-mode.

---

### Task 1: `RoadmapWaveGeometry` (pure geometry)

**Files:**
- Create: `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift`
- Test: `Breath - Relax & StretchTests/RoadmapWaveGeometryTests.swift`

**Interfaces:**
- Produces: `enum RoadmapWaveGeometry` — `static let nodeSpacing/amplitude/leadingPadding/trailingPadding/minNodeSize/maxNodeSize: CGFloat`; `static func totalWidth(count: Int) -> CGFloat`; `static func x(at index: Int) -> CGFloat`; `static func x(atContinuous t: CGFloat) -> CGFloat`; `static func y(at index: Int, midY: CGFloat) -> CGFloat`; `static func y(atContinuous t: CGFloat, midY: CGFloat) -> CGFloat`; `static func nodeSize(forDuration duration: Int, in durations: [Int]) -> CGFloat`.
- Consumed by: Task 2.

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/RoadmapWaveGeometryTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct RoadmapWaveGeometryTests {
    @Test func firstNodeSitsAtLeadingPadding() {
        #expect(RoadmapWaveGeometry.x(at: 0) == RoadmapWaveGeometry.leadingPadding)
    }

    @Test func nodesAreEvenlySpacedByTheFixedConstant() {
        let x0 = RoadmapWaveGeometry.x(at: 0)
        let x1 = RoadmapWaveGeometry.x(at: 1)
        let x2 = RoadmapWaveGeometry.x(at: 2)
        #expect(x1 - x0 == RoadmapWaveGeometry.nodeSpacing)
        #expect(x2 - x1 == RoadmapWaveGeometry.nodeSpacing)
    }

    @Test func totalWidthGrowsLinearlyWithCount() {
        let w4 = RoadmapWaveGeometry.totalWidth(count: 4)
        let w10 = RoadmapWaveGeometry.totalWidth(count: 10)
        #expect(w10 - w4 == RoadmapWaveGeometry.nodeSpacing * 6)
    }

    @Test func totalWidthForZeroOrOneStillIncludesPadding() {
        let base = RoadmapWaveGeometry.leadingPadding + RoadmapWaveGeometry.trailingPadding
        #expect(RoadmapWaveGeometry.totalWidth(count: 0) == base)
        #expect(RoadmapWaveGeometry.totalWidth(count: 1) == base)
    }

    @Test func yAlternatesCrestAndTroughAtIntegerIndices() {
        let mid: CGFloat = 50
        #expect(RoadmapWaveGeometry.y(at: 0, midY: mid) == mid - RoadmapWaveGeometry.amplitude)
        #expect(RoadmapWaveGeometry.y(at: 1, midY: mid) == mid + RoadmapWaveGeometry.amplitude)
        #expect(RoadmapWaveGeometry.y(at: 2, midY: mid) == mid - RoadmapWaveGeometry.amplitude)
    }

    @Test func continuousYMatchesDiscreteYAtIntegerT() {
        let mid: CGFloat = 50
        for i in 0..<4 {
            #expect(abs(RoadmapWaveGeometry.y(at: i, midY: mid) - RoadmapWaveGeometry.y(atContinuous: CGFloat(i), midY: mid)) < 0.0001)
        }
    }

    @Test func nodeSizeScalesBetweenMinAndMaxByRelativeDuration() {
        let durations = [30, 90, 180]
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 30, in: durations) == RoadmapWaveGeometry.minNodeSize)
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 180, in: durations) == RoadmapWaveGeometry.maxNodeSize)
        let mid = RoadmapWaveGeometry.nodeSize(forDuration: 90, in: durations)
        #expect(mid > RoadmapWaveGeometry.minNodeSize && mid < RoadmapWaveGeometry.maxNodeSize)
    }

    @Test func nodeSizeFallsBackToMidpointWhenAllDurationsMatch() {
        let expected = (RoadmapWaveGeometry.minNodeSize + RoadmapWaveGeometry.maxNodeSize) / 2
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 45, in: [45, 45, 45]) == expected)
    }

    @Test func nodeSizeFallsBackToMidpointForEmptyDurations() {
        let expected = (RoadmapWaveGeometry.minNodeSize + RoadmapWaveGeometry.maxNodeSize) / 2
        #expect(RoadmapWaveGeometry.nodeSize(forDuration: 60, in: []) == expected)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveGeometryTests"`
Expected: FAIL — `RoadmapWaveGeometry` doesn't exist.

- [ ] **Step 3: Implement `RoadmapWaveGeometry`**

Create `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift`:

```swift
import SwiftUI

// MARK: - RoadmapWaveGeometry
//
// Pure math — a session's exercises laid out as evenly-spaced nodes on a
// cosine curve. Spacing is fixed (never "fit everything to the available
// width"): this is what makes exercise 1 land at the same leading-edge
// position whether the session has 4 exercises or 40, and lets a long
// routine scroll instead of compressing into illegible, overlapping nodes.
enum RoadmapWaveGeometry {
    static let nodeSpacing: CGFloat = 62
    static let amplitude: CGFloat = 24
    static let leadingPadding: CGFloat = 24
    static let trailingPadding: CGFloat = 24
    static let minNodeSize: CGFloat = 36
    static let maxNodeSize: CGFloat = 58

    static func totalWidth(count: Int) -> CGFloat {
        let base = leadingPadding + trailingPadding
        guard count > 1 else { return base }
        return base + nodeSpacing * CGFloat(count - 1)
    }

    static func x(at index: Int) -> CGFloat {
        leadingPadding + nodeSpacing * CGFloat(index)
    }

    static func x(atContinuous t: CGFloat) -> CGFloat {
        leadingPadding + nodeSpacing * t
    }

    static func y(at index: Int, midY: CGFloat) -> CGFloat {
        midY - amplitude * cos(CGFloat(index) * .pi)
    }

    static func y(atContinuous t: CGFloat, midY: CGFloat) -> CGFloat {
        midY - amplitude * cos(t * .pi)
    }

    static func nodeSize(forDuration duration: Int, in durations: [Int]) -> CGFloat {
        guard let minD = durations.min(), let maxD = durations.max(), maxD > minD else {
            return (minNodeSize + maxNodeSize) / 2
        }
        let fraction = CGFloat(duration - minD) / CGFloat(maxD - minD)
        return minNodeSize + fraction * (maxNodeSize - minNodeSize)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: same command as Step 2.
Expected: PASS — all nine tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/RoadmapWave.swift" "Breath - Relax & StretchTests/RoadmapWaveGeometryTests.swift"
git commit -m "feat(roadmap): add RoadmapWaveGeometry pure layout math

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: `RoadmapWaveShape` + `RoadmapWave` view

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift` (append)
- Test: `Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift`

**Interfaces:**
- Consumes: `RoadmapWaveGeometry` (Task 1), `PoseGlyphIcon(exercise:category:size:)`, `ExerciseCategory.primary(for:)`, `Exercise.durationSeconds/.durationFormatted/.name/.targetBodyParts`.
- Produces: `struct RoadmapWave: View { let exercises: [Exercise]; var numbered: Bool = false }`. `numbered` (default `false`) draws a small index badge above each node — used by `CustomizeRoutineView` (Task 12); the Home hero uses the default.
- Consumed by: Task 5 (`TodayView.heroCard`), Task 12 (`CustomizeRoutineView`).

- [ ] **Step 1: Write the failing rendering test**

Create `Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct RoadmapWaveRenderingTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name,
            type: .stretch,
            cueStyle: .hold,
            targetBodyParts: ["Lower Back"],
            durationSeconds: duration,
            difficulty: 1,
            instructions: []
        )
    }

    @Test func rendersWithMultipleExercises() {
        let exercises = [
            makeExercise(name: "Box Breathing", duration: 180),
            makeExercise(name: "Cat-Cow Flow", duration: 90),
            makeExercise(name: "Shoulder Roll", duration: 30),
        ]
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersNumberedVariant() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180), makeExercise(name: "Cat-Cow Flow", duration: 90)]
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises, numbered: true).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithASingleExercise() {
        let renderer = ImageRenderer(content: RoadmapWave(exercises: [makeExercise(name: "Box Breathing", duration: 180)]).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithNoExercisesWithoutCrashing() {
        let renderer = ImageRenderer(content: RoadmapWave(exercises: []).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }
}
```

Check `Exercise.init` in `Breath - Relax & Stretch/Models/Exercise.swift` first — match this fixture helper to
the real signature if it's drifted.

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveRenderingTests"`
Expected: FAIL — `RoadmapWave` doesn't exist.

- [ ] **Step 3: Implement `RoadmapWaveShape` and `RoadmapWave`**

Append to `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift`:

```swift
// MARK: - RoadmapWaveShape

private struct RoadmapWaveShape: Shape {
    let count: Int
    let midY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 1 else { return path }
        let stepsPerSegment = 16
        let totalSteps = (count - 1) * stepsPerSegment
        for step in 0...totalSteps {
            let t = CGFloat(step) / CGFloat(stepsPerSegment)
            let point = CGPoint(
                x: RoadmapWaveGeometry.x(atContinuous: t),
                y: RoadmapWaveGeometry.y(atContinuous: t, midY: midY)
            )
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - RoadmapWave
//
// A session's exercises as duration-sized PoseGlyphIcon nodes on a
// continuous curve, in a horizontal ScrollView. Node 0 always renders at
// the leading edge (an un-scrolled ScrollView shows its content's leading
// edge first in LTR layouts) — the user scrolls right to reveal the rest,
// at any exercise count. Stays PoseGlyphIcon-only by design: this is
// compact wayfinding, not the primary browsing surface, so it's exempt
// from the general animation-vs-glyph size rule (see ExerciseArt, Task 6).
struct RoadmapWave: View {
    let exercises: [Exercise]
    var numbered: Bool = false

    private var midY: CGFloat {
        RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + (numbered ? 14 : 4)
    }

    private var contentHeight: CGFloat {
        midY + RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + 22
    }

    private var durations: [Int] { exercises.map(\.durationSeconds) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                RoadmapWaveShape(count: exercises.count, midY: midY)
                    .stroke(
                        LinearGradient(colors: [Color.luminaGradientStart, Color.luminaGradientEnd], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )

                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
                    let size = RoadmapWaveGeometry.nodeSize(forDuration: exercise.durationSeconds, in: durations)
                    let x = RoadmapWaveGeometry.x(at: index)
                    let y = RoadmapWaveGeometry.y(at: index, midY: midY)

                    PoseGlyphIcon(exercise: exercise, category: category, size: size)
                        .position(x: x, y: y)

                    if numbered {
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 15, height: 15)
                            .background(Color.luminaPrimary, in: Circle())
                            .position(x: x, y: y - size / 2 - 8)
                    }

                    Text(exercise.durationFormatted)
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                        .position(x: x, y: y + size / 2 + 12)
                }
            }
            .frame(width: RoadmapWaveGeometry.totalWidth(count: exercises.count), height: contentHeight)
        }
        .frame(height: contentHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard !exercises.isEmpty else { return "No exercises" }
        let items = exercises.map { "\($0.name), \($0.durationFormatted)" }.joined(separator: "; ")
        return "\(exercises.count) exercise\(exercises.count == 1 ? "" : "s"): \(items)"
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: same command as Step 2.
Expected: PASS — all four tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/RoadmapWave.swift" "Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift"
git commit -m "feat(roadmap): add RoadmapWaveShape + RoadmapWave view

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: `TouchGlyphArchetype` + `TouchGlyphLibrary` (8 category glyphs)

**Files:**
- Create: `Breath - Relax & Stretch/Models/TouchGlyphArchetype.swift`
- Test: `Breath - Relax & StretchTests/TouchGlyphLibraryTests.swift`

**Interfaces:**
- Produces: `struct TouchGlyphArchetype { let headCenter: CGPoint; let headRadius: CGFloat; let spine: [CGPoint]; let legLeft: [CGPoint]; let legRight: [CGPoint]; let restingArm: [CGPoint]; let pointingArm: [CGPoint]; let contactPoint: CGPoint }` and `enum TouchGlyphLibrary { static let all: [ExerciseCategory: TouchGlyphArchetype] }`.
- Consumed by: Task 4 (`CategoryTouchGlyph`).

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/TouchGlyphLibraryTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct TouchGlyphLibraryTests {
    @Test func everyExerciseCategoryHasATouchGlyph() {
        for category in ExerciseCategory.allCases {
            #expect(TouchGlyphLibrary.all[category] != nil, "\(category) is missing a TouchGlyphArchetype")
        }
    }

    @Test func everyCoordinateIsWithinNormalizedBounds() {
        for (category, archetype) in TouchGlyphLibrary.all {
            let points = archetype.spine + archetype.legLeft + archetype.legRight
                + archetype.restingArm + archetype.pointingArm
                + [archetype.headCenter, archetype.contactPoint]
            for point in points {
                #expect((0.0...1.0).contains(point.x), "\(category) has an out-of-bounds x: \(point.x)")
                #expect((0.0...1.0).contains(point.y), "\(category) has an out-of-bounds y: \(point.y)")
            }
            #expect(archetype.headRadius > 0, "\(category) has a non-positive headRadius")
        }
    }

    @Test func everyLimbChainHasAtLeastTwoPoints() {
        for (category, archetype) in TouchGlyphLibrary.all {
            for chain in [archetype.spine, archetype.legLeft, archetype.legRight, archetype.restingArm, archetype.pointingArm] {
                #expect(chain.count >= 2, "\(category) has a limb chain with fewer than 2 points")
            }
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/TouchGlyphLibraryTests"`
Expected: FAIL — types don't exist.

- [ ] **Step 3: Implement `TouchGlyphArchetype` and the 8-entry library**

Create `Breath - Relax & Stretch/Models/TouchGlyphArchetype.swift`:

```swift
import CoreGraphics

/// Geometry for one ExerciseCategory's "touch glyph" — a standing figure
/// with one arm bent to touch the body region that category represents.
/// Separate from PoseArchetype (Models/PoseArchetype.swift): that library
/// encodes whole-body stretch positions for one exercise; a category node
/// represents an entire body region, which no single stretch pose
/// communicates cleanly. Shared base skeleton (head/spine/legs/resting
/// arm) is identical across all 8; only the pointing arm and contact point
/// differ per category.
struct TouchGlyphArchetype {
    let headCenter: CGPoint
    let headRadius: CGFloat
    let spine: [CGPoint]
    let legLeft: [CGPoint]
    let legRight: [CGPoint]
    let restingArm: [CGPoint]
    let pointingArm: [CGPoint]
    let contactPoint: CGPoint
}

enum TouchGlyphLibrary {
    private static let headCenter = CGPoint(x: 0.50, y: 0.16)
    private static let headRadius: CGFloat = 0.09
    private static let spine = [CGPoint(x: 0.50, y: 0.25), CGPoint(x: 0.50, y: 0.55)]
    private static let legLeft = [CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.42, y: 0.78), CGPoint(x: 0.40, y: 0.95)]
    private static let legRight = [CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.58, y: 0.78), CGPoint(x: 0.60, y: 0.95)]
    private static let restingArm = [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.36, y: 0.42), CGPoint(x: 0.32, y: 0.58)]

    private static func archetype(pointingArm: [CGPoint], contactPoint: CGPoint) -> TouchGlyphArchetype {
        TouchGlyphArchetype(
            headCenter: headCenter, headRadius: headRadius, spine: spine,
            legLeft: legLeft, legRight: legRight, restingArm: restingArm,
            pointingArm: pointingArm, contactPoint: contactPoint
        )
    }

    static let all: [ExerciseCategory: TouchGlyphArchetype] = [
        .neck: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.62, y: 0.30), CGPoint(x: 0.56, y: 0.22)],
            contactPoint: CGPoint(x: 0.56, y: 0.225)
        ),
        .shoulders: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.60, y: 0.36), CGPoint(x: 0.42, y: 0.28)],
            contactPoint: CGPoint(x: 0.42, y: 0.28)
        ),
        .chest: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.58, y: 0.34), CGPoint(x: 0.46, y: 0.37)],
            contactPoint: CGPoint(x: 0.48, y: 0.37)
        ),
        .back: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.62, y: 0.40), CGPoint(x: 0.46, y: 0.51)],
            contactPoint: CGPoint(x: 0.49, y: 0.52)
        ),
        .core: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.58, y: 0.36), CGPoint(x: 0.47, y: 0.45)],
            contactPoint: CGPoint(x: 0.49, y: 0.46)
        ),
        .arms: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.42, y: 0.34), CGPoint(x: 0.34, y: 0.42)],
            contactPoint: CGPoint(x: 0.32, y: 0.44)
        ),
        .hipsGlutes: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.60, y: 0.42), CGPoint(x: 0.58, y: 0.53)],
            contactPoint: CGPoint(x: 0.58, y: 0.54)
        ),
        .legs: archetype(
            pointingArm: [CGPoint(x: 0.50, y: 0.27), CGPoint(x: 0.58, y: 0.46), CGPoint(x: 0.50, y: 0.63)],
            contactPoint: CGPoint(x: 0.50, y: 0.64)
        ),
    ]
}
```

Confirm `ExerciseCategory`'s case names (`Models/ExerciseCategory.swift`) match the dictionary keys above
exactly — `.hipsGlutes` in particular, since the raw value string is `"Hips & Glutes"` but the Swift case name
is what matters here.

- [ ] **Step 4: Run the tests to verify they pass**

Run: same command as Step 2.
Expected: PASS — all three tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/TouchGlyphArchetype.swift" "Breath - Relax & StretchTests/TouchGlyphLibraryTests.swift"
git commit -m "feat(touch-glyph): add TouchGlyphArchetype model and 8-category library

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: `CategoryTouchGlyph` view + wire into `CategoryNode`

**Files:**
- Create: `Breath - Relax & Stretch/Views/Exercises/CategoryTouchGlyph.swift`
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift` (the `CategoryNode` struct)
- Test: `Breath - Relax & StretchTests/CategoryTouchGlyphRenderingTests.swift`

**Interfaces:**
- Consumes: `TouchGlyphArchetype`, `TouchGlyphLibrary.all` (Task 3), `ExerciseCategory.accentColor` (existing).
- Produces: `struct CategoryTouchGlyph: View { let category: ExerciseCategory; var size: CGFloat = 84 }`.

- [ ] **Step 1: Write the failing rendering test**

Create `Breath - Relax & StretchTests/CategoryTouchGlyphRenderingTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct CategoryTouchGlyphRenderingTests {
    @Test func everyCategoryRendersAnImage() {
        for category in ExerciseCategory.allCases {
            let renderer = ImageRenderer(content: CategoryTouchGlyph(category: category, size: 84))
            #expect(renderer.cgImage != nil, "\(category) failed to render")
        }
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/CategoryTouchGlyphRenderingTests"`
Expected: FAIL — `CategoryTouchGlyph` doesn't exist.

- [ ] **Step 3: Implement `CategoryTouchGlyph`**

Create `Breath - Relax & Stretch/Views/Exercises/CategoryTouchGlyph.swift`:

```swift
import SwiftUI

/// One ExerciseCategory drawn as a standing figure touching its own body
/// region — the Exercises tab's category-circle icon. See
/// TouchGlyphArchetype (Models/TouchGlyphArchetype.swift) for why this is a
/// separate glyph family from PoseGlyphIcon.
struct CategoryTouchGlyph: View {
    let category: ExerciseCategory
    var size: CGFloat = 84

    private var archetype: TouchGlyphArchetype {
        TouchGlyphLibrary.all[category] ?? TouchGlyphLibrary.all[.core]!
    }

    var body: some View {
        ZStack {
            Circle().fill(category.accentColor.opacity(0.16))

            TouchGlyphPath(chains: [
                archetype.spine, archetype.legLeft, archetype.legRight,
                archetype.restingArm, archetype.pointingArm,
            ])
            .stroke(category.accentColor, style: StrokeStyle(lineWidth: size * 0.066, lineCap: .round, lineJoin: .round))

            Circle()
                .fill(category.accentColor)
                .frame(width: archetype.headRadius * 2 * size, height: archetype.headRadius * 2 * size)
                .position(x: archetype.headCenter.x * size, y: archetype.headCenter.y * size)

            Circle()
                .fill(category.accentColor)
                .frame(width: size * 0.092, height: size * 0.092)
                .overlay(Circle().strokeBorder(.white, lineWidth: size * 0.017))
                .position(x: archetype.contactPoint.x * size, y: archetype.contactPoint.y * size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct TouchGlyphPath: Shape {
    let chains: [[CGPoint]]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for chain in chains {
            guard let first = chain.first else { continue }
            path.move(to: scaled(first, in: rect))
            for point in chain.dropFirst() {
                path.addLine(to: scaled(point, in: rect))
            }
        }
        return path
    }

    private func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: point.x * rect.width, y: point.y * rect.height)
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: same command as Step 2.
Expected: PASS.

- [ ] **Step 5: Wire into `CategoryNode`**

In `Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift`, find `CategoryNode`'s `body`:

```swift
    var body: some View {
        ZStack {
            Circle()
                .fill(category.accentColor.opacity(isFocused ? 0.74 : 0.60))
                .frame(width: diameter, height: diameter)
                .overlay(Circle().strokeBorder(.white.opacity(0.50), lineWidth: 1.5))
                .shadow(color: category.accentColor.opacity(isFocused ? 0.28 : 0.14), radius: isFocused ? 14 : 8)
            VStack(spacing: 3) {
```

Insert the glyph above the existing `VStack`, sized to leave room for the two lines of text below it:

```swift
    var body: some View {
        ZStack {
            Circle()
                .fill(category.accentColor.opacity(isFocused ? 0.74 : 0.60))
                .frame(width: diameter, height: diameter)
                .overlay(Circle().strokeBorder(.white.opacity(0.50), lineWidth: 1.5))
                .shadow(color: category.accentColor.opacity(isFocused ? 0.28 : 0.14), radius: isFocused ? 14 : 8)
            VStack(spacing: 3) {
                CategoryTouchGlyph(category: category, size: diameter * 0.5)
                Text(category.rawValue)
```

(`Text(category.rawValue)` is the first line already in the existing `VStack` — everything else in that
`VStack` stays as-is; only the new `CategoryTouchGlyph` line is added above it.)

- [ ] **Step 6: Build and screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED. Then follow `.claude/skills/verify/SKILL.md` to launch on the Exercises tab
(`-debugInitialTab 2`) and screenshot the category ring — confirm all 8 circles show a distinct touch gesture
and the existing count/name text still fits without visual crowding.

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/CategoryTouchGlyph.swift" "Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift" "Breath - Relax & StretchTests/CategoryTouchGlyphRenderingTests.swift"
git commit -m "feat(touch-glyph): render CategoryTouchGlyph inside CategoryNode

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: Wire `RoadmapWave` into `TodayView.heroCard`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift:186-249` (`heroCard`)

**Interfaces:**
- Consumes: `RoadmapWave(exercises:)` (Task 2), `sessionExercises: [Exercise]` (existing).

This task only inserts the roadmap between the subtitle and the Begin button — it does not remove the
gradient, the halo, or change the button. Those are deferred (see end of plan).

- [ ] **Step 1: Insert the roadmap**

In `heroCard`, find:

```swift
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayFocus.heroTitle)
                        .font(.luminaTitle)
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.luminaSubheadline)
                        .opacity(0.85)
                }

                Button {
```

Replace with:

```swift
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayFocus.heroTitle)
                        .font(.luminaTitle)
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.luminaSubheadline)
                        .opacity(0.85)
                }

                RoadmapWave(exercises: sessionExercises)

                Button {
```

- [ ] **Step 2: Build, test, screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: full suite passes.

Follow `.claude/skills/verify/SKILL.md`, launch on Home (`-debugInitialTab 0`), screenshot the hero. Confirm
exercise 1 renders at the roadmap's left edge on first appearance and swiping reveals the rest.

- [ ] **Step 3: `graphify update .`**

Run from repo root per this repo's `CLAUDE.md`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat(home): render today's session as a RoadmapWave in the hero card

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: `ExerciseArt` (the animation-vs-glyph size rule)

**Files:**
- Create: `Breath - Relax & Stretch/Views/Exercises/ExerciseArt.swift`
- Test: `Breath - Relax & StretchTests/ExerciseArtTests.swift`

**Interfaces:**
- Consumes: `PoseGlyphIcon(exercise:category:size:)`, `LoopingVideoThumbnail(url:reduceMotion:)`, `Exercise.demoVideoURL` (existing).
- Produces: `struct ExerciseArt: View { let exercise: Exercise; let category: ExerciseCategory; var size: CGFloat = 112 }` and `ExerciseArt.animationThreshold: CGFloat` (the single source of truth for the 52pt cutoff).
- Consumed by: Task 7 (`ExerciseGridTile`).

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/ExerciseArtTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct ExerciseArtTests {
    private func makeExercise(name: String = "Test", animationName: String? = nil) -> Exercise {
        let exercise = Exercise(
            name: name, type: .stretch, cueStyle: .hold,
            targetBodyParts: ["Lower Back"], durationSeconds: 45,
            difficulty: 1, instructions: []
        )
        exercise.animationName = animationName
        return exercise
    }

    @Test func thresholdIsFiftyTwoPoints() {
        #expect(ExerciseArt.animationThreshold == 52)
    }

    @Test func rendersAtGlyphSizeWithoutAnimation() {
        let exercise = makeExercise()
        let renderer = ImageRenderer(content: ExerciseArt(exercise: exercise, category: .back, size: 30))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersAtTileSizeWithoutAnimation() {
        // No demoVideoURL resolves -> falls back to PoseGlyphIcon even
        // though the size is above the animation threshold.
        let exercise = makeExercise()
        let renderer = ImageRenderer(content: ExerciseArt(exercise: exercise, category: .back, size: 112))
        #expect(renderer.cgImage != nil)
    }
}
```

Check `Exercise.animationName`/`.demoVideoURL` in `Breath - Relax & Stretch/Models/Exercise.swift` before
writing this — match the property names/types exactly as they exist there.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseArtTests"`
Expected: FAIL — `ExerciseArt` doesn't exist.

- [ ] **Step 3: Implement `ExerciseArt`**

Create `Breath - Relax & Stretch/Views/Exercises/ExerciseArt.swift`:

```swift
import SwiftUI

/// The single place that decides "real animation, or the glyph" for an
/// exercise. Rule: real LoopingVideoThumbnail when the rendered size is at
/// least `animationThreshold` points AND the exercise has a resolved
/// demoVideoURL; PoseGlyphIcon otherwise. Every call site (search results,
/// category groups, Body Map, ForYouCard/RecommendedCard) goes through
/// this one view so the threshold only ever needs to change in one place.
struct ExerciseArt: View {
    let exercise: Exercise
    let category: ExerciseCategory
    var size: CGFloat = 112

    static let animationThreshold: CGFloat = 52

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if size >= Self.animationThreshold, let url = exercise.demoVideoURL {
                LoopingVideoThumbnail(url: url, reduceMotion: reduceMotion)
                    .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel, style: .continuous))
            } else {
                PoseGlyphIcon(exercise: exercise, category: category, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: same command as Step 2.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseArt.swift" "Breath - Relax & StretchTests/ExerciseArtTests.swift"
git commit -m "feat(exercise-art): add ExerciseArt, the size-rule-aware art view

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: `ExerciseGridTile` (replaces `ExerciseRow`)

**Files:**
- Create: `Breath - Relax & Stretch/Views/Exercises/ExerciseGridTile.swift`
- Test: `Breath - Relax & StretchTests/ExerciseGridTileRenderingTests.swift`

**Interfaces:**
- Consumes: `ExerciseArt` (Task 6), `ExerciseCategory.primary(for:)`.
- Produces:
  ```swift
  enum ExerciseGridBadge {
      case none
      case add(isSelected: Bool)   // dashed-fallback + or filled check, bottom-trailing corner
  }
  struct ExerciseGridTile: View {
      let exercise: Exercise
      var badge: ExerciseGridBadge = .none
      var onTap: () -> Void
      var onBadgeTap: (() -> Void)? = nil
  }
  ```
- Consumed by: Task 8 (`ExerciseListView` search results), Task 9 (`ExerciseGroupCorpusSheet`), Task 10
  (`BodyPartExercisesView`), Task 14 (add-mode), Task 16 (Body Map dual-mode).

- [ ] **Step 1: Write the failing rendering test**

Create `Breath - Relax & StretchTests/ExerciseGridTileRenderingTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct ExerciseGridTileRenderingTests {
    private func makeExercise() -> Exercise {
        Exercise(
            name: "Cat-Cow Flow", type: .stretch, cueStyle: .hold,
            targetBodyParts: ["Lower Back"], durationSeconds: 90,
            difficulty: 1, instructions: []
        )
    }

    @Test func rendersWithNoBadge() {
        let renderer = ImageRenderer(content: ExerciseGridTile(exercise: makeExercise(), onTap: {}).frame(width: 160, height: 200))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithUnselectedAddBadge() {
        let tile = ExerciseGridTile(exercise: makeExercise(), badge: .add(isSelected: false), onTap: {}, onBadgeTap: {})
        let renderer = ImageRenderer(content: tile.frame(width: 160, height: 200))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithSelectedAddBadge() {
        let tile = ExerciseGridTile(exercise: makeExercise(), badge: .add(isSelected: true), onTap: {}, onBadgeTap: {})
        let renderer = ImageRenderer(content: tile.frame(width: 160, height: 200))
        #expect(renderer.cgImage != nil)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseGridTileRenderingTests"`
Expected: FAIL — types don't exist.

- [ ] **Step 3: Implement `ExerciseGridTile`**

Create `Breath - Relax & Stretch/Views/Exercises/ExerciseGridTile.swift`:

```swift
import SwiftUI

/// What (if anything) sits in a tile's bottom-trailing corner. `.none` is
/// plain browsing (search results, category groups) — the whole tile is
/// one tap target going to `onTap`. `.add` is used by both the Customize
/// add-mode flow and Body Map's mini-routine builder: the corner circle is
/// its own tap target (`onBadgeTap`), independent of the tile's main
/// `onTap` (which, per call site, is either "go to detail" or "start this
/// exercise now" — ExerciseGridTile itself doesn't know or care which).
enum ExerciseGridBadge: Equatable {
    case none
    case add(isSelected: Bool)
}

/// The one exercise-list visual used everywhere an exercise list renders:
/// Exercises tab search results, a category group screen, and Body Map's
/// region list. Replaces the old ExerciseRow (text + a video-or-gray-icon
/// thumbnail) at all three call sites.
struct ExerciseGridTile: View {
    let exercise: Exercise
    var badge: ExerciseGridBadge = .none
    var onTap: () -> Void
    var onBadgeTap: (() -> Void)? = nil

    private var category: ExerciseCategory {
        ExerciseCategory.primary(for: exercise.targetBodyParts)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    ExerciseArt(exercise: exercise, category: category, size: 112)
                        .frame(maxWidth: .infinity)

                    badgeView
                }

                Text(exercise.name)
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(exercise.durationFormatted) · \(exercise.type.rawValue)")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .luminaCard(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.durationFormatted), \(exercise.type.rawValue)")
    }

    @ViewBuilder
    private var badgeView: some View {
        switch badge {
        case .none:
            EmptyView()
        case .add(let isSelected):
            Button {
                onBadgeTap?()
            } label: {
                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.luminaOnSurfaceVariant)
                    .frame(width: 26, height: 26)
                    .background(isSelected ? Color.luminaPrimary : Color.luminaContainer, in: Circle())
            }
            .padding(8)
            .accessibilityLabel(isSelected ? "Remove \(exercise.name)" : "Add \(exercise.name)")
        }
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: same command as Step 2.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseGridTile.swift" "Breath - Relax & StretchTests/ExerciseGridTileRenderingTests.swift"
git commit -m "feat(exercise-grid): add ExerciseGridTile, replacing ExerciseRow

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 8: Replace `ExerciseRow` in `ExerciseListView`'s search results

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift:62-104` (the `content` computed property's search-results branch)

**Interfaces:**
- Consumes: `ExerciseGridTile` (Task 7), existing `searchResults.visible`/`selectedExercise` state.

- [ ] **Step 1: Swap the `LazyVStack` of `ExerciseRow` for a `LazyVGrid` of `ExerciseGridTile`**

Find:

```swift
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.visible, id: \.uuid) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .luminaCard()
                            .padding(.horizontal)
                        }

                        if searchResults.canLoadMore {
                            ProgressView()
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    visibleSearchCount = searchResults.nextVisibleCount
                                }
                        }
                    }
                    .padding(.top, 8)
                }
```

Replace with:

```swift
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(searchResults.visible, id: \.uuid) { exercise in
                            ExerciseGridTile(exercise: exercise) {
                                selectedExercise = exercise
                            }
                        }

                        if searchResults.canLoadMore {
                            ProgressView()
                                .gridCellColumns(2)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    visibleSearchCount = searchResults.nextVisibleCount
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
```

`selectedExercise` and `isShowingDetail` already exist on `ExerciseListView` and already drive a
`.navigationDestination(isPresented:)` to `ExerciseDetailView` — no changes needed there, this just points
the tile's `onTap` at the same state instead of wrapping a `NavigationLink`.

- [ ] **Step 2: Build, test, screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Follow `.claude/skills/verify/SKILL.md`, launch on Exercises (`-debugInitialTab 2`), type a search query,
screenshot the results grid. Confirm tapping a tile opens `ExerciseDetailView`.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift"
git commit -m "feat(exercise-list): render search results as ExerciseGridTile grid

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 9: `ExerciseGroupCorpusSheet` → push destination, grid tiles

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift` (`ExerciseGroupCorpusSheet` struct and its presentation call site)

**Interfaces:**
- Consumes: `ExerciseGridTile` (Task 7).

- [ ] **Step 1: Find the current presentation**

`ExerciseGroupCorpusSheet` is presented as a `.sheet` today — find the `.sheet(item: $selectedGroup)` (or
equivalent) call site in `ExerciseGraphView.body` and note it for Step 3. It currently has
`.presentationDetents([.medium, .large])` inside the sheet's own body.

- [ ] **Step 2: Convert the sheet body into a pushed screen with a grid**

Replace `ExerciseGroupCorpusSheet`'s body (the `NavigationStack { ScrollView { LazyVStack ... ExerciseRow ... } }`
block) with:

```swift
private struct ExerciseGroupCorpusSheet: View {
    let selected: SelectedExerciseGraphGroup
    let onSelect: (Exercise) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(selected.group.exercises, id: \.uuid) { exercise in
                    ExerciseGridTile(exercise: exercise) {
                        onSelect(exercise)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.luminaSurface)
        .navigationTitle(selected.group.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 8) {
                Circle()
                    .fill(selected.category.accentColor.opacity(0.66))
                    .frame(width: 10, height: 10)
                Text("\(selected.group.exercises.count) exercise\(selected.group.exercises.count == 1 ? "" : "s")")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
    }
}
```

The `dismiss()`/`Button("Done")` machinery from the old `.sheet` version goes away — a pushed screen dismisses
via the standard back button, which `ExerciseListView`'s parent `NavigationStack` already provides.

- [ ] **Step 3: Change the presentation from `.sheet` to `.navigationDestination`**

In `ExerciseGraphView.body`, replace the `.sheet(item: $selectedGroup) { ... ExerciseGroupCorpusSheet(...) ... }`
modifier with:

```swift
.navigationDestination(item: $selectedGroup) { selected in
    ExerciseGroupCorpusSheet(selected: selected) { exercise in
        selectedGroup = nil
        onSelect(exercise)
    }
}
```

This requires `ExerciseGraphView` to be hosted inside a `NavigationStack` that owns `.navigationDestination` —
confirm `ExerciseListView.body` already wraps its `content` in `NavigationStack` (it does, per its `var body`).
Since `ExerciseGraphView` no longer opens its own nested `NavigationStack` for this destination, it now shares
`ExerciseListView`'s stack — which is what makes the persistent search bar (in `ExerciseListView.header`) stay
visible when a group screen is pushed, fixing the gap described in the design spec.

- [ ] **Step 4: Build, test, screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Follow `.claude/skills/verify/SKILL.md`, launch on Exercises, zoom into a category, tap a satellite group node.
Confirm: the screen pushes (not a sheet), the search bar from the parent screen is still visible, and the grid
renders correctly for a group with many exercises (e.g. Back → Lower Back, ~19 real exercises — confirm it
scrolls smoothly, no layout break).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift"
git commit -m "feat(exercise-graph): push ExerciseGroupCorpusSheet as a grid, not a sheet

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 10: Replace `ExerciseRow` in `BodyPartExercisesView`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift` (`BodyPartExercisesView`)

**Interfaces:**
- Consumes: `ExerciseGridTile` (Task 7).

This task only swaps the tile — Body Map's dual-mode (tap = start now, `+` = mini routine) is Task 16, layered
on afterward. For now, tapping a tile still goes to `ExerciseDetailView`, matching current behavior, so this
task is safe to ship on its own.

- [ ] **Step 1: Replace `exerciseRows`' `List`/`ExerciseRow` with a grid**

Find:

```swift
                List {
                    if bodyParts.count > 1 {
                        Section {
                            Text(bodyParts.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } header: {
                            Text("Targeting")
                        }
                    }
                    if !resolver.direct.isEmpty {
                        Section {
                            exerciseRows(resolver.direct)
                        } header: {
                            Text("\(resolver.direct.count) exercise\(resolver.direct.count == 1 ? "" : "s")")
                        }
                    }
                    if !resolver.related.isEmpty {
                        Section {
                            exerciseRows(resolver.related)
                        } header: {
                            Text(relatedSectionTitle)
                        } footer: {
                            Text(relatedFooterText)
                        }
                    }
                }
```

Replace with:

```swift
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if bodyParts.count > 1 {
                            Text(bodyParts.joined(separator: ", "))
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                        if !resolver.direct.isEmpty {
                            exerciseSection(title: "\(resolver.direct.count) exercise\(resolver.direct.count == 1 ? "" : "s")", exercises: resolver.direct)
                        }
                        if !resolver.related.isEmpty {
                            exerciseSection(title: relatedSectionTitle, footer: relatedFooterText, exercises: resolver.related)
                        }
                    }
                    .padding()
                }
```

- [ ] **Step 2: Replace `exerciseRows(_:)` with a grid-section helper**

Find:

```swift
    @ViewBuilder
    private func exerciseRows(_ exercises: [Exercise]) -> some View {
        ForEach(exercises, id: \.uuid) { exercise in
            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                ExerciseRow(exercise: exercise)
            }
        }
    }
```

Replace with:

```swift
    @ViewBuilder
    private func exerciseSection(title: String, footer: String? = nil, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurfaceVariant)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(exercises, id: \.uuid) { exercise in
                    ExerciseGridTile(exercise: exercise) {
                        selectedExercise = exercise
                    }
                }
            }

            if let footer {
                Text(footer)
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
        }
    }
```

- [ ] **Step 3: Add navigation state**

`BodyPartExercisesView` needs somewhere to route a tapped tile now that it's not a `NavigationLink`. Add, near
the top of the struct (alongside the existing `@Query private var allExercises: [Exercise]`):

```swift
    @State private var selectedExercise: Exercise?
```

And add a `.navigationDestination` to the view's modifier chain (alongside the existing `.navigationTitle`/
`.navigationBarTitleDisplayMode`/`.floatingTabBarClearance`):

```swift
        .navigationDestination(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
```

- [ ] **Step 4: Build, test, screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Follow `.claude/skills/verify/SKILL.md`, tap a body region on the 3D model, tap "Find Exercises," screenshot
the resulting grid. Confirm both the "direct" and "related" sections render as grids and tapping a tile opens
`ExerciseDetailView`.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift"
git commit -m "feat(body-map): render BodyPartExercisesView as an ExerciseGridTile grid

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 11: `pinnedWakeUpRoutineID` + `TodayView` lookup

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`

**Interfaces:**
- Produces: a new `@AppStorage("pinnedWakeUpRoutineID")` string flag on `TodayView`, and
  `pinnedSessionExercises: [Exercise]?` (private computed property) that `sessionExercises` checks first.
- Consumed by: Task 12 (`CustomizeRoutineView`'s save toggle sets/clears this key).

- [ ] **Step 1: Add the query and the AppStorage flag**

Near the existing `@Query private var exercises: [Exercise]` and `@Query private var profiles: [UserProfile]`
in `TodayView`, add:

```swift
    @Query private var routines: [Routine]
    @AppStorage("pinnedWakeUpRoutineID") private var pinnedWakeUpRoutineIDString = ""
```

- [ ] **Step 2: Add the pinned-routine lookup**

Near the existing `sessionExercises` computed property, add:

```swift
    /// The saved routine the user pinned via Customize ("Keep as my Wake Up
    /// routine"), if any is set and it still resolves to at least one real
    /// exercise. Checked before the goal-based fallback below.
    private var pinnedSessionExercises: [Exercise]? {
        guard let pinnedID = UUID(uuidString: pinnedWakeUpRoutineIDString),
              let routine = routines.first(where: { $0.uuid == pinnedID }) else {
            return nil
        }
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        let resolved = routine.exerciseIDs.compactMap { byID[$0] }
        return resolved.isEmpty ? nil : resolved
    }
```

- [ ] **Step 3: Check the pinned routine first in `sessionExercises`**

Find `sessionExercises`:

```swift
    private var sessionExercises: [Exercise] {
        switch timeOfDayFocus {
        case .wakeUp:
```

Replace with:

```swift
    private var sessionExercises: [Exercise] {
        if let pinnedSessionExercises {
            return pinnedSessionExercises
        }
        switch timeOfDayFocus {
        case .wakeUp:
```

(Everything after `case .wakeUp:` in the existing `switch` is unchanged.)

- [ ] **Step 4: Build and test**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED — `Routine` is already an existing `@Model` type imported via SwiftData in this
file's `import SwiftData`, no new import needed.

Run the full test suite:
Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: passes — with `pinnedWakeUpRoutineID` empty by default (fresh installs / existing tests), the new
`if let pinnedSessionExercises` branch is always `nil` and every existing `sessionExercises`/hero test keeps
its prior behavior unchanged.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat(home): check pinnedWakeUpRoutineID before goal-based session fallback

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 12: `CustomizeRoutineView`

**Files:**
- Create: `Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift`
- Test: `Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests.swift`

**Interfaces:**
- Consumes: `RoadmapWave(exercises:numbered:)` (Task 2), `Routine` (existing SwiftData model).
- Produces:
  ```swift
  struct CustomizeRoutineView: View {
      let title: String
      let exercises: [Exercise]
      let isPinned: Bool
      let onAddExercisesRequested: () -> Void
      let onDone: (_ exercises: [Exercise], _ pinned: Bool) -> Void
  }
  ```
- Consumed by: Task 13 (`TodayView`'s Customize button/sheet).

Per this plan's Global Constraints decision, the duration steppers below adjust local `@State` only — they do
not mutate `exercise.durationSeconds` (a shared SwiftData object) and are not threaded into the session start
flow by this task (see "Explicitly deferred" at the end of this plan).

- [ ] **Step 1: Write the failing rendering test**

Create `Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct CustomizeRoutineViewRenderingTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name, type: .stretch, cueStyle: .hold,
            targetBodyParts: ["Lower Back"], durationSeconds: duration,
            difficulty: 1, instructions: []
        )
    }

    @Test func rendersWithExercises() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180), makeExercise(name: "Cat-Cow Flow", duration: 90)]
        let view = CustomizeRoutineView(title: "Wake Up", exercises: exercises, isPinned: false, onAddExercisesRequested: {}, onDone: { _, _ in })
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithPinnedStateOn() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180)]
        let view = CustomizeRoutineView(title: "Wake Up", exercises: exercises, isPinned: true, onAddExercisesRequested: {}, onDone: { _, _ in })
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithNoExercises() {
        let view = CustomizeRoutineView(title: "Wake Up", exercises: [], isPinned: false, onAddExercisesRequested: {}, onDone: { _, _ in })
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests"`
Expected: FAIL — `CustomizeRoutineView` doesn't exist.

- [ ] **Step 3: Implement `CustomizeRoutineView`**

Create `Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift`:

```swift
import SwiftUI

/// Presented from the Home hero's Customize button. Lets the user preview
/// today's session as a numbered roadmap, nudge each exercise's duration
/// for today only, decide whether to pin this list as their permanent
/// morning routine, and jump into the Exercises tab to add more.
///
/// Duration edits are local-only (`durationOverrides`) — Exercise is a
/// shared SwiftData object, so this view must never write back to
/// `exercise.durationSeconds` directly. See the "Explicitly deferred"
/// section of docs/superpowers/plans/2026-08-11-home-exercises-redesign.md
/// for why overrides aren't (yet) threaded into the session player.
struct CustomizeRoutineView: View {
    let title: String
    let exercises: [Exercise]
    let isPinned: Bool
    let onAddExercisesRequested: () -> Void
    let onDone: (_ exercises: [Exercise], _ pinned: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pinnedToggle: Bool
    @State private var durationOverrides: [UUID: Int] = [:]

    init(title: String, exercises: [Exercise], isPinned: Bool,
         onAddExercisesRequested: @escaping () -> Void,
         onDone: @escaping (_ exercises: [Exercise], _ pinned: Bool) -> Void) {
        self.title = title
        self.exercises = exercises
        self.isPinned = isPinned
        self.onAddExercisesRequested = onAddExercisesRequested
        self.onDone = onDone
        self._pinnedToggle = State(initialValue: isPinned)
    }

    private var totalSeconds: Int { exercises.reduce(0) { $0 + duration(for: $1) } }
    private var totalMinutes: Int { max(1, Int((Double(totalSeconds) / 60).rounded())) }

    private func duration(for exercise: Exercise) -> Int {
        durationOverrides[exercise.uuid] ?? exercise.durationSeconds
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }

    private func adjust(_ exercise: Exercise, by delta: Int) {
        let current = duration(for: exercise)
        durationOverrides[exercise.uuid] = max(15, current + delta)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(exercises.count) EXERCISES · \(totalMinutes) MIN")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)

                    RoadmapWave(exercises: exercises, numbered: true)

                    saveToggleRow

                    VStack(spacing: 10) {
                        ForEach(Array(exercises.enumerated()), id: \.element.uuid) { index, exercise in
                            exerciseRow(index: index, exercise: exercise)
                        }

                        HStack {
                            Spacer()
                            Button(action: onAddExercisesRequested) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 8, weight: .bold))
                                        .frame(width: 18, height: 18)
                                        .background(Color.luminaMintTint, in: Circle())
                                    Text("Add Exercises")
                                }
                                .font(.luminaLabel)
                                .foregroundStyle(Color.luminaPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .overlay(Capsule().strokeBorder(Color.luminaOutline, style: StrokeStyle(lineWidth: 1.3, dash: [4, 3])))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.top, 6)
                    }
                }
                .padding()
            }
            .background(Color.luminaSurface)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onDone(exercises, pinnedToggle)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Begin")
                    }
                }
                .buttonStyle(LuminaPillButtonStyle(kind: .prominent))
                .frame(maxWidth: .infinity)
                .padding()
                .background(.regularMaterial)
            }
        }
    }

    private var saveToggleRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 34, height: 34)
                .background(Color.luminaMintTint, in: RoundedRectangle(cornerRadius: LuminaRadius.chip, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text("Keep as my \(title) routine")
                    .font(.luminaCardTitle)
                Text("Starts your day automatically · off = just for today")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $pinnedToggle)
                .labelsHidden()
                .tint(Color.luminaPrimary)
        }
        .luminaCard(padding: 14)
    }

    private func exerciseRow(index: Int, exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .frame(width: 22, height: 22)
                .background(Color.luminaContainer, in: Circle())

            let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
            PoseGlyphIcon(exercise: exercise, category: category, size: 46)

            Text(exercise.name)
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaOnSurface)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button { adjust(exercise, by: -15) } label: {
                    Image(systemName: "minus").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Color.luminaContainer, in: Circle())

                Text(formatted(duration(for: exercise)))
                    .font(.luminaLabel)
                    .monospacedDigit()
                    .frame(minWidth: 44)

                Button { adjust(exercise, by: 15) } label: {
                    Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Color.luminaContainer, in: Circle())
            }
        }
        .luminaCard(padding: 12)
    }
}
```

`PoseGlyphIcon` is drawn directly here (rather than through `ExerciseArt`) because these rows sit well below
the 52pt animation threshold at 46pt — this is a deliberate, permanent glyph-only context per the size rule,
not a shortcut.

- [ ] **Step 4: Run the test to verify it passes**

Run: same command as Step 2.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift" "Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests.swift"
git commit -m "feat(customize): add CustomizeRoutineView

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 13: Wire Customize into `TodayView`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`

**Interfaces:**
- Consumes: `CustomizeRoutineView` (Task 12), `pinnedWakeUpRoutineIDString`/`pinnedSessionExercises` (Task 11), `Routine` (existing).

- [ ] **Step 1: Add the Customize button to `heroCard`**

Find the Begin `Button` inside `heroCard` (the one wrapping `HStack { Image(systemName: "play.fill"); Text("Begin") }`).
Wrap it and a new Customize button in an `HStack`:

```swift
                HStack(spacing: 10) {
                    Button {
                        showingCustomize = true
                    } label: {
                        Text("Customize")
                            .font(.luminaLabel)
                    }
                    .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))

                    Button {
                        showingSession = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Begin")
                        }
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaBlue)
                        .padding(.horizontal, 28)
                        .frame(height: 44)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Begin today's session: \(sessionExercises.count) exercises, \(mins) minutes")
                }
```

(The existing Begin `Button`'s body/styling is preserved verbatim inside the `HStack` — only a sibling
Customize button and the wrapping `HStack` are new.)

- [ ] **Step 2: Add state and the sheet**

Near the existing `@State private var showingSession = false` in `TodayView`, add:

```swift
    @State private var showingCustomize = false
```

Near the existing `.sheet(isPresented: $showingSession) { SessionPlayerView(exercises: sessionExercises) }`
modifier on `TodayView.body`, add a sibling sheet:

```swift
        .sheet(isPresented: $showingCustomize) {
            CustomizeRoutineView(
                title: timeOfDayFocus.heroTitle,
                exercises: sessionExercises,
                isPinned: pinnedSessionExercises != nil,
                onAddExercisesRequested: {
                    showingCustomize = false
                    NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                },
                onDone: { exercises, pinned in
                    if pinned {
                        let routine = Routine(name: timeOfDayFocus.heroTitle, exerciseIDs: exercises.map(\.uuid))
                        modelContext.insert(routine)
                        try? modelContext.save()
                        pinnedWakeUpRoutineIDString = routine.uuid.uuidString
                    } else {
                        pinnedWakeUpRoutineIDString = ""
                    }
                    showingSession = true
                }
            )
        }
```

- [ ] **Step 3: Build, test, screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: full suite passes.

Follow `.claude/skills/verify/SKILL.md`: launch on Home, tap Customize, confirm the sheet opens with today's
real session, toggle the save switch on, tap Begin, confirm a session starts; relaunch the app and confirm
the hero now shows the pinned routine instead of the goal-based one.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat(home): wire Customize button + sheet into TodayView

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 14: `MiniRoutineState`

**Files:**
- Create: `Breath - Relax & Stretch/Services/MiniRoutineState.swift`
- Test: `Breath - Relax & StretchTests/MiniRoutineStateTests.swift`

**Interfaces:**
- Produces:
  ```swift
  final class MiniRoutineState: ObservableObject {
      @Published private(set) var exercises: [Exercise] = []
      func toggle(_ exercise: Exercise)
      func contains(_ exercise: Exercise) -> Bool
      var totalSeconds: Int { get }
  }
  ```
- Consumed by: Task 15 (Body Map's mini-routine bottom bar), Task 16.

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/MiniRoutineStateTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct MiniRoutineStateTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name, type: .stretch, cueStyle: .hold,
            targetBodyParts: ["Lower Back"], durationSeconds: duration,
            difficulty: 1, instructions: []
        )
    }

    @Test func startsEmpty() {
        #expect(MiniRoutineState().exercises.isEmpty)
    }

    @Test func toggleAddsThenRemoves() {
        let state = MiniRoutineState()
        let exercise = makeExercise(name: "Shoulder Roll", duration: 30)
        state.toggle(exercise)
        #expect(state.contains(exercise) == true)
        #expect(state.exercises.count == 1)
        state.toggle(exercise)
        #expect(state.contains(exercise) == false)
        #expect(state.exercises.isEmpty)
    }

    @Test func totalSecondsSumsAddedExercises() {
        let state = MiniRoutineState()
        state.toggle(makeExercise(name: "A", duration: 30))
        state.toggle(makeExercise(name: "B", duration: 45))
        #expect(state.totalSeconds == 75)
    }

    @Test func containsIsFalseForAnUnaddedExercise() {
        let state = MiniRoutineState()
        state.toggle(makeExercise(name: "A", duration: 30))
        #expect(state.contains(makeExercise(name: "B", duration: 45)) == false)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/MiniRoutineStateTests"`
Expected: FAIL — `MiniRoutineState` doesn't exist.

- [ ] **Step 3: Implement `MiniRoutineState`**

Create `Breath - Relax & Stretch/Services/MiniRoutineState.swift`:

```swift
import Foundation

/// Ad hoc exercise selection for Body Map's "build a mini routine" flow —
/// no name, no save step, just a running list you can Start once you're
/// happy with it. Distinct from Routine (SwiftData, named, persisted):
/// this never touches the database, it only exists for the lifetime of one
/// Body Map screen.
final class MiniRoutineState: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []

    func toggle(_ exercise: Exercise) {
        if let index = exercises.firstIndex(where: { $0.uuid == exercise.uuid }) {
            exercises.remove(at: index)
        } else {
            exercises.append(exercise)
        }
    }

    func contains(_ exercise: Exercise) -> Bool {
        exercises.contains { $0.uuid == exercise.uuid }
    }

    var totalSeconds: Int {
        exercises.reduce(0) { $0 + $1.durationSeconds }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: same command as Step 2.
Expected: PASS — all four tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/MiniRoutineState.swift" "Breath - Relax & StretchTests/MiniRoutineStateTests.swift"
git commit -m "feat(body-map): add MiniRoutineState

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 15: Body Map dual-mode — mini routine bar + "tap tile = start now"

**Files:**
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift` (`BodyPartExercisesView`)

**Interfaces:**
- Consumes: `MiniRoutineState` (Task 14), `ExerciseGridTile`'s `.add` badge (Task 7), `SessionPlayerView(exercises:)` (existing).

Per this plan's Global Constraints decision (spec Q3), Body Map's tile-tap behavior is intentionally
different from every other `ExerciseGridTile` call site: tapping the tile starts that one exercise
immediately; tapping the badge builds the mini routine. This is scoped to `BodyPartExercisesView` only.

- [ ] **Step 1: Add mini-routine state and a quick-start sheet**

In `BodyPartExercisesView`, add alongside the existing `@State private var selectedExercise: Exercise?`
(from Task 10):

```swift
    @StateObject private var miniRoutine = MiniRoutineState()
    @State private var quickStartExercise: Exercise?
```

- [ ] **Step 2: Change tile wiring — tap starts now, badge builds the mini routine**

In `exerciseSection(title:footer:exercises:)` (Task 10), change the `ExerciseGridTile` call:

```swift
                ForEach(exercises, id: \.uuid) { exercise in
                    ExerciseGridTile(
                        exercise: exercise,
                        badge: .add(isSelected: miniRoutine.contains(exercise))
                    ) {
                        quickStartExercise = exercise
                    } onBadgeTap: {
                        miniRoutine.toggle(exercise)
                    }
                }
```

`selectedExercise`/the Task 10 `.navigationDestination(item: $selectedExercise)` are no longer reachable from
a tile tap on this screen (tile tap now sets `quickStartExercise` instead) — remove that now-unused
`@State private var selectedExercise: Exercise?` and its `.navigationDestination` added in Task 10, since
Body Map no longer routes to `ExerciseDetailView` from a tile tap at all.

- [ ] **Step 3: Present the quick-start session and the mini-routine bottom bar**

Add to `BodyPartExercisesView.body`'s modifier chain (alongside `.navigationTitle`/`.floatingTabBarClearance`):

```swift
        .fullScreenCover(item: $quickStartExercise) { exercise in
            SessionPlayerView(exercises: [exercise])
        }
        .fullScreenCover(isPresented: $showingMiniRoutineSession) {
            SessionPlayerView(exercises: miniRoutine.exercises)
        }
        .safeAreaInset(edge: .bottom) {
            if !miniRoutine.exercises.isEmpty {
                miniRoutineBar
            }
        }
```

Add the new `@State` this references and the bar itself:

```swift
    @State private var showingMiniRoutineSession = false

    private var miniRoutineBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(miniRoutine.exercises.count) selected")
                    .font(.luminaCardTitle)
                let m = miniRoutine.totalSeconds / 60, s = miniRoutine.totalSeconds % 60
                Text("\(m):\(String(format: "%02d", s)) mini routine")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            Spacer(minLength: 8)
            Button {
                showingMiniRoutineSession = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
            }
            .buttonStyle(LuminaPillButtonStyle(kind: .prominent, compact: true))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
```

Check `SessionPlayerView`'s exact presentation convention elsewhere in the codebase (`TodayView` uses
`.sheet`, not `.fullScreenCover`) before finalizing — match whichever the app already uses consistently for
starting a session, rather than introducing a second presentation style.

- [ ] **Step 4: Build, test, screenshot**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

Follow `.claude/skills/verify/SKILL.md`: tap a body region, confirm tapping a tile's body starts that single
exercise immediately; confirm tapping a tile's `+` badge instead adds it to the bottom bar without navigating
anywhere; add 2–3 exercises, confirm the bar's count/time updates live, tap Start, confirm a session begins
with exactly the selected exercises.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/BodyMap/BodyMapComponents.swift"
git commit -m "feat(body-map): dual-mode exercise selection (tap = start now, + = mini routine)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Explicitly deferred (not part of this plan)

- **Persisting Customize's duration overrides into the session player.** `CustomizeRoutineView`'s steppers
  edit local `@State` only (Global Constraints decision); `SessionPlayerView(exercises:)` still reads each
  `Exercise`'s real stored `durationSeconds`. Threading a per-session override through requires either a
  `SessionPlayerView` API change (a parallel `[UUID: Int]` override map) or a lightweight `SessionExercise`
  wrapper type — a real design decision, not scoped here.
- **The hero's gradient background and breathing-halo circles.** Task 5 only inserts the roadmap; replacing
  the background wash and adding the Customize button's final visual treatment (ghost pill vs. the sketch in
  Task 13, which is a reasonable first pass but not verified against the rest of the hero's post-redesign
  look) is unfinished per the design spec.
- **Add-mode's shopping-list bar for the Exercises-tab flow** (Customize → Add Exercises → search/browse with
  a running "added" bar → Done returns to Customize with the additions appended). Task 13 wires the
  notification that switches tabs, but the receiving side — `ExerciseGridTile`'s `.add` badge is only wired up
  on Body Map (Task 15) — needs its own task turning on add-mode across `ExerciseListView`'s search results
  and the pushed group screen, plus the actual "append back into `CustomizeRoutineView`'s `exercises`" return
  path (`CustomizeRoutineView` currently has no mechanism to receive exercises picked after it dismissed
  itself for `onAddExercisesRequested`).
- **Growing `PoseArchetypeLibrary` past 16 archetypes** to reduce the 47% `standingNeutral` collision — noted
  in the design spec as valuable, independent of this plan.
- **Dark mode** for any new view in this plan.
