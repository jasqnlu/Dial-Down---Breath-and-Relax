# Pose Glyph Icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic reused SF Symbol icon on Home-tab exercise cards (`ForYouCard`, `RecommendedCard`) with a per-pose stick-figure glyph, so each exercise reads as visually distinct at a glance.

**Architecture:** A small, self-contained icon system: (1) a static library of hand-authored "pose archetypes" — normalized-coordinate stick-figure geometry, one per distinct body position/movement — (2) a pure keyword classifier that maps any `Exercise` to one archetype + a mirror flag, and (3) a `PoseGlyphIcon` SwiftUI view that renders an archetype as a joined-path stick figure inside a category-tinted circle badge. No new persisted data, no asset pipeline — everything is Swift source.

**Tech Stack:** SwiftUI (`Path`, `Shape`, `ImageRenderer` for the rendering smoke test), Swift Testing (`@Test`/`#expect`), existing `ExerciseCategory`/`Exercise` models.

## Global Constraints

- Style is locked from `docs/superpowers/specs/2026-08-10-pose-glyph-icons-design.md`: 96pt default badge, category-tinted circle background (16% opacity), figure stroked in the full-opacity category accent color, joint dots at every bend, larger dot for the head, flat seat bar (28% opacity) behind seated archetypes.
- Every limb (both arms, both legs, where applicable) is drawn as one continuous `Path` per chain — no separate disconnected segments, so bends never show a seam.
- Coordinates are normalized 0–1 figure space (same convention as the app's existing, currently-unused `ExercisePose`/`StickJoint` model), scaled to the view's `size` at render time.
- Every `Exercise` must resolve to *some* valid, defined archetype — never nil, never a crash. `standingNeutral` is the universal fallback.
- Follow existing test conventions: Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest. Test files live in `Breath - Relax & StretchTests/`.
- This plan only touches `ForYouCard` and `RecommendedCard` on `TodayView`. `ExerciseListView`'s node graph, the session player, and `heroCard`/`programCard` are explicitly out of scope (per spec).

---

## File Structure

**Create:**
- `Breath - Relax & Stretch/Models/PoseArchetype.swift` — `PoseArchetypeID` enum, `PoseArchetype` data struct, and the `PoseArchetypeLibrary.all` static dictionary of 16 hand-authored archetypes.
- `Breath - Relax & Stretch/Models/PoseArchetypeMapping.swift` — the pure `resolve(name:type:)` classifier + manual override table + mirror-flag logic.
- `Breath - Relax & Stretch/Views/Exercises/PoseGlyphIcon.swift` — the SwiftUI rendering view.
- `Breath - Relax & StretchTests/PoseArchetypeTests.swift` — library completeness + geometry sanity tests.
- `Breath - Relax & StretchTests/PoseArchetypeMappingTests.swift` — classifier spot-checks.
- `Breath - Relax & StretchTests/PoseGlyphIconRenderingTests.swift` — renders every archetype through `ImageRenderer`, asserts no archetype fails to produce an image.

**Modify:**
- `Breath - Relax & Stretch/Models/ExerciseCategory.swift` — add `ExerciseCategory.primary(for:)`.
- `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift` — swap the icon block in `RecommendedCard` and `ForYouCard`.
- `Breath - Relax & StretchTests/ExerciseCategoryTests.swift` — add tests for `primary(for:)`.

---

### Task 1: `ExerciseCategory.primary(for:)`

**Files:**
- Modify: `Breath - Relax & Stretch/Models/ExerciseCategory.swift`
- Test: `Breath - Relax & StretchTests/ExerciseCategoryTests.swift`

**Interfaces:**
- Produces: `static func ExerciseCategory.primary(for targetBodyParts: [String]) -> ExerciseCategory` — a single deterministic category (declaration order of `allCases`, i.e. neck > shoulders > chest > back > core > arms > hipsGlutes > legs), falling back to `.core` when nothing matches. `ForYouCard` (Task 6) needs this since it doesn't currently carry a category.

- [ ] **Step 1: Write the failing tests**

Append to `Breath - Relax & StretchTests/ExerciseCategoryTests.swift`, inside the `ExerciseCategoryTests` struct:

```swift
    @Test func primaryPicksFirstCategoryInDeclarationOrder() {
        // categories(for:) returns {.chest, .shoulders}; shoulders is declared
        // before chest in ExerciseCategory, so it wins deterministically.
        #expect(ExerciseCategory.primary(for: ["Left Chest", "Left Shoulder"]) == .shoulders)
    }

    @Test func primaryFallsBackToCoreWhenNoPartsMatch() {
        #expect(ExerciseCategory.primary(for: ["Not A Real Part"]) == .core)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/ExerciseCategoryTests`
Expected: FAIL — `primary(for:)` doesn't exist yet (compile error).

- [ ] **Step 3: Implement `primary(for:)`**

In `Breath - Relax & Stretch/Models/ExerciseCategory.swift`, add after the existing `static func categories(for:)`:

```swift
    /// A single deterministic category for contexts that need one badge
    /// color rather than the full set `categories(for:)` returns — picks
    /// the first match in `allCases` declaration order. Falls back to
    /// `.core` when no target body part resolves to any category.
    static func primary(for targetBodyParts: [String]) -> ExerciseCategory {
        let matched = categories(for: targetBodyParts)
        return allCases.first(where: matched.contains) ?? .core
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/ExerciseCategoryTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/ExerciseCategory.swift" "Breath - Relax & StretchTests/ExerciseCategoryTests.swift"
git commit -m "feat(exercise-category): add primary(for:) single-category resolver

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: `PoseArchetype` type + the 16-archetype library

**Files:**
- Create: `Breath - Relax & Stretch/Models/PoseArchetype.swift`
- Test: `Breath - Relax & StretchTests/PoseArchetypeTests.swift`

**Interfaces:**
- Produces:
  - `enum PoseArchetypeID: String, CaseIterable` with cases: `seatedTwist, seatedNeck, seatedForwardFold, seatedFigureFour, seatedNeutral, standingNeutral, standingForwardFold, standingTwist, standingSideBend, supineNeutral, supineKneeToChest, bridge, quadruped, prone, childsPose, breathSeated`.
  - `struct PoseArchetype { let headCenter: CGPoint; let headRadius: CGFloat; let limbs: [[CGPoint]]; let jointDots: [CGPoint]; let seatRect: CGRect? }` — all coordinates normalized 0–1.
  - `enum PoseArchetypeLibrary { static let all: [PoseArchetypeID: PoseArchetype] }`
- Consumed by: Task 3 (mapping falls back to `.standingNeutral`, needs the ID list), Task 4 (`PoseGlyphIcon` renders a `PoseArchetype`).

- [ ] **Step 1: Write the failing completeness test**

Create `Breath - Relax & StretchTests/PoseArchetypeTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct PoseArchetypeTests {
    @Test func everyArchetypeIDHasALibraryEntry() {
        for id in PoseArchetypeID.allCases {
            #expect(PoseArchetypeLibrary.all[id] != nil, "\(id) is missing from PoseArchetypeLibrary.all")
        }
    }

    @Test func everyArchetypeHasBothArmsAndBothLegsWhereApplicable() {
        // Every archetype except headMicro-style ones has 4 limb chains
        // (left arm, right arm, left leg, right leg) plus the spine —
        // 5 chains total. None of our 16 initial archetypes are head-only.
        for (id, archetype) in PoseArchetypeLibrary.all {
            #expect(archetype.limbs.count == 5, "\(id) should have 5 path chains (spine + 2 arms + 2 legs), has \(archetype.limbs.count)")
            for limb in archetype.limbs {
                #expect(limb.count >= 2, "\(id) has a limb chain with fewer than 2 points")
            }
        }
    }

    @Test func everyCoordinateIsWithinNormalizedBounds() {
        for (id, archetype) in PoseArchetypeLibrary.all {
            let allPoints = archetype.limbs.flatMap { $0 } + archetype.jointDots + [archetype.headCenter]
            for point in allPoints {
                #expect((0.0...1.0).contains(point.x), "\(id) has an out-of-bounds x: \(point.x)")
                #expect((0.0...1.0).contains(point.y), "\(id) has an out-of-bounds y: \(point.y)")
            }
            #expect(archetype.headRadius > 0, "\(id) has a non-positive headRadius")
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/PoseArchetypeTests`
Expected: FAIL — `PoseArchetypeID`/`PoseArchetype`/`PoseArchetypeLibrary` don't exist yet (compile error).

- [ ] **Step 3: Implement the type and the full library**

Create `Breath - Relax & Stretch/Models/PoseArchetype.swift`:

```swift
import CoreGraphics

/// Names one distinct stick-figure body position/movement. The classifier
/// in PoseArchetypeMapping.swift routes every Exercise to exactly one of
/// these. Grow this list by adding a case here + an entry in
/// PoseArchetypeLibrary.all + a classifier rule — everything else (the
/// renderer, the completeness tests) picks new cases up automatically.
enum PoseArchetypeID: String, CaseIterable {
    case seatedTwist, seatedNeck, seatedForwardFold, seatedFigureFour, seatedNeutral
    case standingNeutral, standingForwardFold, standingTwist, standingSideBend
    case supineNeutral, supineKneeToChest, bridge
    case quadruped, prone, childsPose, breathSeated
}

/// Hand-authored stick-figure geometry for one archetype, in normalized
/// 0–1 figure space (same convention as the app's ExercisePose/StickJoint
/// model). `PoseGlyphIcon` scales every coordinate by its rendered size.
///
/// `limbs` is a list of continuous path chains — each inner array is drawn
/// as ONE joined stroke (spine, left arm, right arm, left leg, right leg)
/// so bends never show a seam. `jointDots` are the small filled circles
/// drawn at every bend (elbows, knees, shoulders, hips); the head is drawn
/// separately, larger, at `headCenter`/`headRadius`. `seatRect` is nil for
/// standing/supine/prone/quadruped archetypes; seated ones get a flat bar
/// drawn behind the figure.
struct PoseArchetype {
    let headCenter: CGPoint
    let headRadius: CGFloat
    let limbs: [[CGPoint]]
    let jointDots: [CGPoint]
    let seatRect: CGRect?
}

enum PoseArchetypeLibrary {
    static let all: [PoseArchetypeID: PoseArchetype] = [
        .seatedTwist: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.22), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.50, y: 0.62)],
                [CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.74, y: 0.44)],
                [CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.18, y: 0.56)],
                [CGPoint(x: 0.74, y: 0.44), CGPoint(x: 0.88, y: 0.60)],
                [CGPoint(x: 0.50, y: 0.62), CGPoint(x: 0.30, y: 0.82), CGPoint(x: 0.18, y: 0.90)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.74, y: 0.44),
                CGPoint(x: 0.18, y: 0.56), CGPoint(x: 0.88, y: 0.60), CGPoint(x: 0.50, y: 0.62),
                CGPoint(x: 0.30, y: 0.82), CGPoint(x: 0.72, y: 0.80),
            ],
            seatRect: CGRect(x: 0.14, y: 0.64, width: 0.72, height: 0.09)
        ),
        .seatedNeck: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.22), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.50, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.26, y: 0.46), CGPoint(x: 0.14, y: 0.40)],
                [CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.74, y: 0.46), CGPoint(x: 0.86, y: 0.40)],
                [CGPoint(x: 0.50, y: 0.58), CGPoint(x: 0.38, y: 0.74), CGPoint(x: 0.34, y: 0.90)],
                [CGPoint(x: 0.50, y: 0.58), CGPoint(x: 0.62, y: 0.74), CGPoint(x: 0.66, y: 0.90)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.34), CGPoint(x: 0.50, y: 0.40), CGPoint(x: 0.26, y: 0.46),
                CGPoint(x: 0.74, y: 0.46), CGPoint(x: 0.50, y: 0.58), CGPoint(x: 0.38, y: 0.74),
                CGPoint(x: 0.62, y: 0.74),
            ],
            seatRect: CGRect(x: 0.14, y: 0.60, width: 0.72, height: 0.09)
        ),
        .seatedForwardFold: PoseArchetype(
            headCenter: CGPoint(x: 0.28, y: 0.44), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.50, y: 0.60)],
                [CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.40, y: 0.66), CGPoint(x: 0.46, y: 0.78)],
                [CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.46, y: 0.68), CGPoint(x: 0.54, y: 0.80)],
                [CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.70, y: 0.62), CGPoint(x: 0.90, y: 0.62)],
                [CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.72, y: 0.66), CGPoint(x: 0.92, y: 0.68)],
            ],
            jointDots: [
                CGPoint(x: 0.36, y: 0.52), CGPoint(x: 0.40, y: 0.66), CGPoint(x: 0.46, y: 0.68),
                CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.70, y: 0.62), CGPoint(x: 0.72, y: 0.66),
            ],
            seatRect: CGRect(x: 0.14, y: 0.58, width: 0.40, height: 0.08)
        ),
        .seatedFigureFour: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42), CGPoint(x: 0.34, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.66, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.68, y: 0.58), CGPoint(x: 0.82, y: 0.52)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.36, y: 0.68), CGPoint(x: 0.30, y: 0.82)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42),
                CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.68, y: 0.58),
                CGPoint(x: 0.36, y: 0.68),
            ],
            seatRect: CGRect(x: 0.14, y: 0.58, width: 0.72, height: 0.09)
        ),
        .seatedNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42), CGPoint(x: 0.34, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.66, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.34, y: 0.60), CGPoint(x: 0.20, y: 0.62)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.66, y: 0.60), CGPoint(x: 0.80, y: 0.62)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.36, y: 0.42),
                CGPoint(x: 0.64, y: 0.42), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.34, y: 0.60),
                CGPoint(x: 0.66, y: 0.60),
            ],
            seatRect: CGRect(x: 0.14, y: 0.58, width: 0.72, height: 0.09)
        ),
        .standingNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.52)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.34, y: 0.42), CGPoint(x: 0.28, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.66, y: 0.42), CGPoint(x: 0.72, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.42, y: 0.74), CGPoint(x: 0.40, y: 0.92)],
                [CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.58, y: 0.74), CGPoint(x: 0.60, y: 0.92)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.34, y: 0.42),
                CGPoint(x: 0.66, y: 0.42), CGPoint(x: 0.50, y: 0.52), CGPoint(x: 0.42, y: 0.74),
                CGPoint(x: 0.58, y: 0.74),
            ],
            seatRect: nil
        ),
        .standingForwardFold: PoseArchetype(
            headCenter: CGPoint(x: 0.32, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.56, y: 0.46)],
                [CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.30, y: 0.52), CGPoint(x: 0.34, y: 0.78)],
                [CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.38, y: 0.56), CGPoint(x: 0.42, y: 0.82)],
                [CGPoint(x: 0.56, y: 0.46), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.18, y: 0.70)],
                [CGPoint(x: 0.56, y: 0.46), CGPoint(x: 0.78, y: 0.66), CGPoint(x: 0.94, y: 0.70)],
            ],
            jointDots: [
                CGPoint(x: 0.32, y: 0.26), CGPoint(x: 0.30, y: 0.52), CGPoint(x: 0.38, y: 0.56),
                CGPoint(x: 0.56, y: 0.46), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.78, y: 0.66),
            ],
            seatRect: nil
        ),
        .standingTwist: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.68, y: 0.36), CGPoint(x: 0.84, y: 0.30)],
                [CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.16, y: 0.48)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76), CGPoint(x: 0.40, y: 0.94)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.58, y: 0.76), CGPoint(x: 0.60, y: 0.94)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.26), CGPoint(x: 0.50, y: 0.30), CGPoint(x: 0.68, y: 0.36),
                CGPoint(x: 0.30, y: 0.40), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76),
                CGPoint(x: 0.58, y: 0.76),
            ],
            seatRect: nil
        ),
        .standingSideBend: PoseArchetype(
            headCenter: CGPoint(x: 0.62, y: 0.16), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.58, y: 0.26), CGPoint(x: 0.50, y: 0.54)],
                [CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.76, y: 0.20), CGPoint(x: 0.92, y: 0.14)],
                [CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.46, y: 0.42), CGPoint(x: 0.40, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76), CGPoint(x: 0.40, y: 0.94)],
                [CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.58, y: 0.76), CGPoint(x: 0.60, y: 0.94)],
            ],
            jointDots: [
                CGPoint(x: 0.58, y: 0.26), CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.76, y: 0.20),
                CGPoint(x: 0.46, y: 0.42), CGPoint(x: 0.50, y: 0.54), CGPoint(x: 0.42, y: 0.76),
                CGPoint(x: 0.58, y: 0.76),
            ],
            seatRect: nil
        ),
        .supineNeutral: PoseArchetype(
            headCenter: CGPoint(x: 0.18, y: 0.50), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.62, y: 0.50)],
                [CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.34, y: 0.68), CGPoint(x: 0.34, y: 0.82)],
                [CGPoint(x: 0.40, y: 0.54), CGPoint(x: 0.40, y: 0.70), CGPoint(x: 0.40, y: 0.84)],
                [CGPoint(x: 0.62, y: 0.50), CGPoint(x: 0.80, y: 0.52), CGPoint(x: 0.96, y: 0.52)],
                [CGPoint(x: 0.62, y: 0.50), CGPoint(x: 0.80, y: 0.58), CGPoint(x: 0.96, y: 0.60)],
            ],
            jointDots: [
                CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.40, y: 0.54),
                CGPoint(x: 0.62, y: 0.50), CGPoint(x: 0.80, y: 0.52), CGPoint(x: 0.80, y: 0.58),
            ],
            seatRect: nil
        ),
        .supineKneeToChest: PoseArchetype(
            headCenter: CGPoint(x: 0.18, y: 0.50), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.56, y: 0.50)],
                [CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.44, y: 0.44), CGPoint(x: 0.52, y: 0.36)],
                [CGPoint(x: 0.40, y: 0.54), CGPoint(x: 0.48, y: 0.46), CGPoint(x: 0.56, y: 0.40)],
                [CGPoint(x: 0.56, y: 0.50), CGPoint(x: 0.52, y: 0.32), CGPoint(x: 0.44, y: 0.20)],
                [CGPoint(x: 0.56, y: 0.50), CGPoint(x: 0.76, y: 0.52), CGPoint(x: 0.94, y: 0.52)],
            ],
            jointDots: [
                CGPoint(x: 0.30, y: 0.50), CGPoint(x: 0.34, y: 0.54), CGPoint(x: 0.40, y: 0.54),
                CGPoint(x: 0.56, y: 0.50), CGPoint(x: 0.52, y: 0.32), CGPoint(x: 0.76, y: 0.52),
            ],
            seatRect: nil
        ),
        .bridge: PoseArchetype(
            headCenter: CGPoint(x: 0.18, y: 0.62), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.30, y: 0.62), CGPoint(x: 0.56, y: 0.44)],
                [CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.34, y: 0.78), CGPoint(x: 0.34, y: 0.90)],
                [CGPoint(x: 0.40, y: 0.66), CGPoint(x: 0.40, y: 0.80), CGPoint(x: 0.40, y: 0.92)],
                [CGPoint(x: 0.56, y: 0.44), CGPoint(x: 0.60, y: 0.64), CGPoint(x: 0.60, y: 0.82)],
                [CGPoint(x: 0.56, y: 0.44), CGPoint(x: 0.68, y: 0.62), CGPoint(x: 0.72, y: 0.80)],
            ],
            jointDots: [
                CGPoint(x: 0.30, y: 0.62), CGPoint(x: 0.34, y: 0.66), CGPoint(x: 0.40, y: 0.66),
                CGPoint(x: 0.56, y: 0.44), CGPoint(x: 0.60, y: 0.64), CGPoint(x: 0.68, y: 0.62),
            ],
            seatRect: nil
        ),
        .quadruped: PoseArchetype(
            headCenter: CGPoint(x: 0.82, y: 0.30), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.30, y: 0.44)],
                [CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.74, y: 0.56), CGPoint(x: 0.76, y: 0.76)],
                [CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.66, y: 0.58), CGPoint(x: 0.64, y: 0.78)],
                [CGPoint(x: 0.30, y: 0.44), CGPoint(x: 0.28, y: 0.64), CGPoint(x: 0.26, y: 0.82)],
                [CGPoint(x: 0.30, y: 0.44), CGPoint(x: 0.20, y: 0.62), CGPoint(x: 0.14, y: 0.80)],
            ],
            jointDots: [
                CGPoint(x: 0.72, y: 0.36), CGPoint(x: 0.74, y: 0.56), CGPoint(x: 0.66, y: 0.58),
                CGPoint(x: 0.30, y: 0.44), CGPoint(x: 0.28, y: 0.64), CGPoint(x: 0.20, y: 0.62),
            ],
            seatRect: nil
        ),
        .prone: PoseArchetype(
            headCenter: CGPoint(x: 0.86, y: 0.34), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.30, y: 0.56)],
                [CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.78, y: 0.58), CGPoint(x: 0.70, y: 0.70)],
                [CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.66, y: 0.56), CGPoint(x: 0.72, y: 0.68)],
                [CGPoint(x: 0.30, y: 0.56), CGPoint(x: 0.16, y: 0.58), CGPoint(x: 0.04, y: 0.58)],
                [CGPoint(x: 0.30, y: 0.56), CGPoint(x: 0.16, y: 0.62), CGPoint(x: 0.04, y: 0.64)],
            ],
            jointDots: [
                CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.78, y: 0.58), CGPoint(x: 0.66, y: 0.56),
                CGPoint(x: 0.30, y: 0.56), CGPoint(x: 0.16, y: 0.58), CGPoint(x: 0.16, y: 0.62),
            ],
            seatRect: nil
        ),
        .childsPose: PoseArchetype(
            headCenter: CGPoint(x: 0.82, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.28, y: 0.58)],
                [CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.86, y: 0.20), CGPoint(x: 0.96, y: 0.12)],
                [CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.92, y: 0.32), CGPoint(x: 0.98, y: 0.24)],
                [CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.18, y: 0.72), CGPoint(x: 0.28, y: 0.86)],
                [CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.36, y: 0.76), CGPoint(x: 0.44, y: 0.88)],
            ],
            jointDots: [
                CGPoint(x: 0.74, y: 0.30), CGPoint(x: 0.86, y: 0.20), CGPoint(x: 0.92, y: 0.32),
                CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.18, y: 0.72), CGPoint(x: 0.36, y: 0.76),
            ],
            seatRect: nil
        ),
        .breathSeated: PoseArchetype(
            headCenter: CGPoint(x: 0.50, y: 0.18), headRadius: 0.10,
            limbs: [
                [CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.56)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.38, y: 0.44), CGPoint(x: 0.36, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.64, y: 0.58)],
                [CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.30, y: 0.60), CGPoint(x: 0.62, y: 0.66)],
                [CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.70, y: 0.60), CGPoint(x: 0.38, y: 0.68)],
            ],
            jointDots: [
                CGPoint(x: 0.50, y: 0.28), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.38, y: 0.44),
                CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.50, y: 0.56), CGPoint(x: 0.30, y: 0.60),
                CGPoint(x: 0.70, y: 0.60),
            ],
            seatRect: CGRect(x: 0.14, y: 0.60, width: 0.72, height: 0.09)
        ),
    ]
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/PoseArchetypeTests`
Expected: PASS — all three tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/PoseArchetype.swift" "Breath - Relax & StretchTests/PoseArchetypeTests.swift"
git commit -m "feat(pose-glyph): add PoseArchetype model and 16-archetype library

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: `PoseArchetypeMapping` classifier

**Files:**
- Create: `Breath - Relax & Stretch/Models/PoseArchetypeMapping.swift`
- Test: `Breath - Relax & StretchTests/PoseArchetypeMappingTests.swift`

**Interfaces:**
- Consumes: `PoseArchetypeID` (Task 2), `Exercise.name`/`Exercise.type` (existing).
- Produces: `enum PoseArchetypeMapping { static func resolve(name: String, type: ExerciseType) -> (id: PoseArchetypeID, mirrored: Bool); static func resolve(for exercise: Exercise) -> (id: PoseArchetypeID, mirrored: Bool) }`. Consumed by Task 4 (`PoseGlyphIcon`'s exercise-based initializer).

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/PoseArchetypeMappingTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct PoseArchetypeMappingTests {
    @Test func breathTypeAlwaysResolvesToBreathSeated() {
        let result = PoseArchetypeMapping.resolve(name: "Box Breathing", type: .breath)
        #expect(result.id == .breathSeated)
    }

    @Test func seatedTwistKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Spinal Twist", type: .stretch).id == .seatedTwist)
        #expect(PoseArchetypeMapping.resolve(name: "Right Seated Spinal Twist", type: .stretch).id == .seatedTwist)
    }

    @Test func standingTwistKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Standing Reach-Through Twist", type: .stretch).id == .standingTwist)
    }

    @Test func childsPoseResolvesExactly() {
        #expect(PoseArchetypeMapping.resolve(name: "Child's Pose", type: .stretch).id == .childsPose)
    }

    @Test func standingForwardFoldKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Standing Hamstring Stretch", type: .stretch).id == .standingForwardFold)
        #expect(PoseArchetypeMapping.resolve(name: "Standing Forward Fold (Ragdoll)", type: .stretch).id == .standingForwardFold)
    }

    @Test func seatedForwardFoldKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Hamstring Stretch", type: .stretch).id == .seatedForwardFold)
        #expect(PoseArchetypeMapping.resolve(name: "Seated Forward Fold", type: .stretch).id == .seatedForwardFold)
    }

    @Test func neckAndHeadMicroExercisesResolveToSeatedNeck() {
        #expect(PoseArchetypeMapping.resolve(name: "Seated Neck Rolls", type: .stretch).id == .seatedNeck)
        #expect(PoseArchetypeMapping.resolve(name: "Jaw-Open Temporalis Stretch", type: .stretch).id == .seatedNeck)
        #expect(PoseArchetypeMapping.resolve(name: "20-20-20 Focus Shift", type: .stretch).id == .seatedNeck)
    }

    @Test func manualOverridesResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Downward-Facing Dog", type: .stretch).id == .quadruped)
        #expect(PoseArchetypeMapping.resolve(name: "Pigeon Pose (Left Leg Forward)", type: .stretch).id == .seatedFigureFour)
        #expect(PoseArchetypeMapping.resolve(name: "World's Greatest Stretch (Right Lead Leg)", type: .stretch).id == .standingTwist)
    }

    @Test func unmatchedNameFallsBackToStandingNeutral() {
        #expect(PoseArchetypeMapping.resolve(name: "Completely Made-Up Exercise Name", type: .stretch).id == .standingNeutral)
    }

    @Test func mirrorFlagTracksRightInName() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Spinal Twist", type: .stretch).mirrored == false)
        #expect(PoseArchetypeMapping.resolve(name: "Right Seated Spinal Twist", type: .stretch).mirrored == true)
        #expect(PoseArchetypeMapping.resolve(name: "Cat-Cow Flow", type: .stretch).mirrored == false)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/PoseArchetypeMappingTests`
Expected: FAIL — `PoseArchetypeMapping` doesn't exist yet.

- [ ] **Step 3: Implement the classifier**

Create `Breath - Relax & Stretch/Models/PoseArchetypeMapping.swift`:

```swift
import Foundation

/// Routes any Exercise to exactly one PoseArchetypeID + a mirror flag, for
/// PoseGlyphIcon to render. Pure functions of name/type — no persisted
/// state, so growing the seed catalog never needs a migration here.
///
/// Resolution order: exact manual overrides (for names whose pose doesn't
/// parse cleanly from keywords) > keyword classifier > standingNeutral
/// fallback. Every exercise always resolves to something real.
enum PoseArchetypeMapping {
    static func resolve(for exercise: Exercise) -> (id: PoseArchetypeID, mirrored: Bool) {
        resolve(name: exercise.name, type: exercise.type)
    }

    static func resolve(name: String, type: ExerciseType) -> (id: PoseArchetypeID, mirrored: Bool) {
        let mirrored = name.contains("Right")
        if type == .breath {
            return (.breathSeated, mirrored)
        }
        if let overrideID = manualOverrides[name] {
            return (overrideID, mirrored)
        }
        return (classify(name.lowercased()), mirrored)
    }

    /// Names whose pose doesn't parse cleanly from keywords — routed
    /// directly to the closest-fitting archetype in the initial 16.
    private static let manualOverrides: [String: PoseArchetypeID] = [
        "World's Greatest Stretch (Left Lead Leg)": .standingTwist,
        "World's Greatest Stretch (Right Lead Leg)": .standingTwist,
        "Pigeon Pose (Left Leg Forward)": .seatedFigureFour,
        "Pigeon Pose (Right Leg Forward)": .seatedFigureFour,
        "Left Pigeon Pose Hip Stretch": .seatedFigureFour,
        "Right Pigeon Pose Hip Stretch": .seatedFigureFour,
        "Downward-Facing Dog": .quadruped,
        "Left Cossack Squat Stretch": .standingSideBend,
        "Right Cossack Squat Stretch": .standingSideBend,
        "Left Couch Stretch": .standingNeutral,
        "Right Couch Stretch": .standingNeutral,
        "Sun Salutation Warm-Up": .standingNeutral,
        "Dynamic Standing Leg Swings": .standingNeutral,
        "Standing Hip Circles": .standingNeutral,
        "Runner's Lunge with Rotation (Left)": .standingTwist,
        "Runner's Lunge with Rotation (Right)": .standingTwist,
    ]

    private static func classify(_ n: String) -> PoseArchetypeID {
        if n.contains("child's pose") { return .childsPose }
        if n.contains("twist") {
            return (n.contains("standing") || n.contains("lunge")) ? .standingTwist : .seatedTwist
        }
        if n.contains("neck") || n.contains("jaw") || n.contains("eye") || n.contains("temple")
            || n.contains("temporalis") || n.contains("brow") || n.contains("forehead")
            || n.contains("frontalis") || n.contains("tongue") || n.contains("20-20-20")
            || n.contains("suboccipital") {
            return .seatedNeck
        }
        if n.contains("figure-four") || n.contains("figure four") || n.contains("butterfly") {
            return .seatedFigureFour
        }
        if n.contains("side bend") || n.contains("side reach") || n.contains("crescent moon")
            || n.contains("side stretch") {
            return .standingSideBend
        }
        if n.contains("cat-cow") || n.contains("thread the needle") { return .quadruped }
        if n.contains("cobra") || n.contains("sphinx") || n.contains("prone") { return .prone }
        if n.contains("bridge") { return .bridge }
        if n.contains("knee-to-chest") || n.contains("happy baby") { return .supineKneeToChest }
        if n.contains("forward fold") || n.contains("hamstring") || n.contains("ragdoll") {
            return n.contains("standing") ? .standingForwardFold : .seatedForwardFold
        }
        if n.contains("supine") { return .supineNeutral }
        if n.contains("seated") { return .seatedNeutral }
        return .standingNeutral
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/PoseArchetypeMappingTests`
Expected: PASS — all nine tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/PoseArchetypeMapping.swift" "Breath - Relax & StretchTests/PoseArchetypeMappingTests.swift"
git commit -m "feat(pose-glyph): add exercise-to-archetype keyword classifier

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: `PoseGlyphIcon` SwiftUI view

**Files:**
- Create: `Breath - Relax & Stretch/Views/Exercises/PoseGlyphIcon.swift`
- Test: `Breath - Relax & StretchTests/PoseGlyphIconRenderingTests.swift`

**Interfaces:**
- Consumes: `PoseArchetype`, `PoseArchetypeID`, `PoseArchetypeLibrary.all` (Task 2), `PoseArchetypeMapping.resolve(for:)` (Task 3), `Exercise`, `ExerciseCategory.accentColor` (existing).
- Produces: `struct PoseGlyphIcon: View` with two initializers — `init(archetype: PoseArchetype, mirrored: Bool, color: Color, size: CGFloat = 96)` (used directly by the rendering test and previews) and `init(exercise: Exercise, category: ExerciseCategory, size: CGFloat = 96)` (used by call sites in Task 5/6).

- [ ] **Step 1: Write the failing rendering test**

Create `Breath - Relax & StretchTests/PoseGlyphIconRenderingTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct PoseGlyphIconRenderingTests {
    @Test func everyArchetypeRendersAnImage() {
        for id in PoseArchetypeID.allCases {
            let archetype = PoseArchetypeLibrary.all[id]!
            let icon = PoseGlyphIcon(archetype: archetype, mirrored: false, color: .teal, size: 96)
            let renderer = ImageRenderer(content: icon)
            #expect(renderer.cgImage != nil, "\(id) failed to render to an image")
        }
    }

    @Test func mirroredVariantAlsoRenders() {
        let archetype = PoseArchetypeLibrary.all[.seatedTwist]!
        let icon = PoseGlyphIcon(archetype: archetype, mirrored: true, color: .indigo, size: 96)
        let renderer = ImageRenderer(content: icon)
        #expect(renderer.cgImage != nil)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/PoseGlyphIconRenderingTests`
Expected: FAIL — `PoseGlyphIcon` doesn't exist yet.

- [ ] **Step 3: Implement `PoseGlyphIcon`**

Create `Breath - Relax & Stretch/Views/Exercises/PoseGlyphIcon.swift`:

```swift
import SwiftUI

/// Renders one PoseArchetype as a joined-path stick figure inside a
/// category-tinted circle badge — the Home tab's per-exercise pose icon.
/// See docs/superpowers/specs/2026-08-10-pose-glyph-icons-design.md for
/// the visual rationale (why a stick glyph over a filled illustration).
struct PoseGlyphIcon: View {
    let archetype: PoseArchetype
    let mirrored: Bool
    let color: Color
    var size: CGFloat = 96

    init(archetype: PoseArchetype, mirrored: Bool, color: Color, size: CGFloat = 96) {
        self.archetype = archetype
        self.mirrored = mirrored
        self.color = color
        self.size = size
    }

    /// Resolves the archetype + mirror flag from the exercise itself —
    /// the call site only needs to know the exercise and its category.
    init(exercise: Exercise, category: ExerciseCategory, size: CGFloat = 96) {
        let (id, mirrored) = PoseArchetypeMapping.resolve(for: exercise)
        self.init(
            archetype: PoseArchetypeLibrary.all[id] ?? PoseArchetypeLibrary.all[.standingNeutral]!,
            mirrored: mirrored,
            color: category.accentColor,
            size: size
        )
    }

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.16))

            if let seatRect = archetype.seatRect {
                let midX = mirroredX(seatRect.midX)
                RoundedRectangle(cornerRadius: seatRect.height * size / 2, style: .continuous)
                    .fill(color.opacity(0.28))
                    .frame(width: seatRect.width * size, height: seatRect.height * size)
                    .position(x: midX * size, y: seatRect.midY * size)
            }

            PoseGlyphPath(limbs: archetype.limbs, mirrored: mirrored)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.073, lineCap: .round, lineJoin: .round))

            ForEach(Array(archetype.jointDots.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(color)
                    .frame(width: size * 0.068, height: size * 0.068)
                    .position(x: mirroredX(point.x) * size, y: point.y * size)
            }

            Circle()
                .fill(color)
                .frame(width: archetype.headRadius * 2 * size, height: archetype.headRadius * 2 * size)
                .position(x: mirroredX(archetype.headCenter.x) * size, y: archetype.headCenter.y * size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func mirroredX(_ x: CGFloat) -> CGFloat {
        mirrored ? 1 - x : x
    }
}

/// Draws every limb chain (spine, both arms, both legs) as one continuous
/// joined stroke each — this is what keeps bends from showing a seam.
private struct PoseGlyphPath: Shape {
    let limbs: [[CGPoint]]
    let mirrored: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for limb in limbs {
            guard let first = limb.first else { continue }
            path.move(to: scaled(first, in: rect))
            for point in limb.dropFirst() {
                path.addLine(to: scaled(point, in: rect))
            }
        }
        return path
    }

    private func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        let x = mirrored ? 1 - point.x : point.x
        return CGPoint(x: x * rect.width, y: point.y * rect.height)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96))]) {
        ForEach(PoseArchetypeID.allCases, id: \.self) { id in
            PoseGlyphIcon(archetype: PoseArchetypeLibrary.all[id]!, mirrored: false, color: .teal, size: 96)
        }
    }
    .padding()
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Breath_-_Relax_-_StretchTests/PoseGlyphIconRenderingTests`
Expected: PASS — both tests green.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/PoseGlyphIcon.swift" "Breath - Relax & StretchTests/PoseGlyphIconRenderingTests.swift"
git commit -m "feat(pose-glyph): add PoseGlyphIcon rendering view

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: Wire into `RecommendedCard`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift:87-137` (the `RecommendedCard` struct)

**Interfaces:**
- Consumes: `PoseGlyphIcon(exercise:category:size:)` (Task 4). `RecommendedCard` already has `item.category: ExerciseCategory` and `item.exercise: Exercise` (from `RecommendedExercise`, defined in `ExerciseCategory.swift`).

`RecommendedCard` is presentational only — no new logic to unit test here (it's driven entirely by Task 3/4's already-tested classifier/renderer). Verified visually in Task 8. No new automated test in this task; existing UI tests that reference the Home tab (see `Breath__Relax___StretchUITests.swift`) continue to exercise the card without needing updates since we're not changing hit-testable structure, only the icon subview.

- [ ] **Step 1: Swap the icon block**

In `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift`, replace the `RecommendedCard`'s icon `Image`:

```swift
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(item.category.accentColor)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: LuminaRadius.chip, style: .continuous)
                        .fill(item.category.accentColor.opacity(0.16))
                )
```

with:

```swift
            PoseGlyphIcon(exercise: item.exercise, category: item.category, size: 60)
```

Then delete the now-unused `private var icon: String` computed property above it (the `Image(systemName: icon)` line was its only caller).

- [ ] **Step 2: Build to confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift"
git commit -m "feat(home): render RecommendedCard's icon with PoseGlyphIcon

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: Wire into `ForYouCard`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift:6-34` (the `ForYouCard` struct)

**Interfaces:**
- Consumes: `PoseGlyphIcon(exercise:category:size:)` (Task 4), `ExerciseCategory.primary(for:)` (Task 1).

`ForYouCard` doesn't currently carry a category, only `let exercise: Exercise`. Resolve one from `exercise.targetBodyParts` at render time.

- [ ] **Step 1: Swap the icon block**

In `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift`, replace `ForYouCard`'s icon block:

```swift
            Image(systemName: exercise.type == .breath ? "wind" : "figure.mind.and.body")
                .font(.system(size: 40))
                .foregroundStyle(Color.luminaPrimary.opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(Color.luminaMintTint)
                .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel, style: .continuous))
```

with:

```swift
            let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
            PoseGlyphIcon(exercise: exercise, category: category, size: 96)
                .frame(maxWidth: .infinity)
                .frame(height: 110)
```

- [ ] **Step 2: Build to confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift"
git commit -m "feat(home): render ForYouCard's icon with PoseGlyphIcon

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: Full test suite + simulator verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: all tests pass, including the pre-existing `CuratedContentIntegrityTests` (unaffected — this feature doesn't touch `ContentPack`/`GoalMeta`/media resolution).

- [ ] **Step 2: Launch and screenshot the Home tab**

Follow this project's `.claude/skills/verify/SKILL.md` recipe to build, launch the app in the simulator on the Home tab (`-debugInitialTab 0`), and capture a screenshot of the "For You" and "Recommended" sections.

- [ ] **Step 3: Visually confirm against the locked design**

Check against `docs/superpowers/specs/2026-08-10-pose-glyph-icons-design.md`: badges are circular and category-tinted, every pose shows two full arms and two full legs with no merged/overlapping limbs, seated poses show the seat bar, no icon is blank/missing. If anything reads wrong for a specific exercise, note which `PoseArchetypeID` it resolved to (add a temporary `print` in `PoseArchetypeMapping.resolve` if needed) and fix that one entry in `PoseArchetypeLibrary.all` or the classifier — this is a tuning pass, not a new task.

- [ ] **Step 4: `graphify update .`**

Per this repo's `CLAUDE.md`, run `graphify update .` from the repo root to refresh the knowledge graph now that new files exist (AST-only, no API cost).

---

## Explicitly deferred (not part of this plan)

- The remaining archetypes implied by the design spec's full ~26-entry taxonomy (`standingLunge`, `standingQuad`, `standingArmReach`, `kneelingNeutral`, `kneelingLunge`, `pigeon`, `downwardDog`, `headMicro`) — everything not yet archetyped falls back to `standingNeutral`/`seatedNeck` via the classifier, which is correct but less pose-specific. Adding one is mechanical: a new `PoseArchetypeID` case, a `PoseArchetypeLibrary.all` entry (5 limb chains + joint dots, following the pattern above), and a classifier rule — the completeness tests in Task 2 catch any missing entry immediately.
- `ExerciseListView`'s node-graph browser, the session player, `heroCard`/`programCard` — per spec, different interaction models or already show real media.
