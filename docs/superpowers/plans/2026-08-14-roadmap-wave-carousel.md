# Roadmap Wave Carousel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `RoadmapWave` from a free-scrolling strip showing every exercise node at once into a paging carousel that zooms into one exercise at a time — the centered node and the curve segment under it read as magnified; neighbors recede.

**Architecture:** `RoadmapWaveGeometry` gains pure, testable falloff math (scale/opacity/blur as a function of pixel distance from a focus point, plus viewport-dependent padding). `RoadmapWave` tracks continuous horizontal scroll offset via `.onScrollGeometryChange`, snaps via a custom `ScrollTargetBehavior`, and drives per-node `.scaleEffect`/`.opacity`/`.blur` and a per-segment `Canvas`-drawn curve from that offset. A fixed (non-scrolling) vignette + focus-glow overlay sits on top.

**Tech Stack:** SwiftUI (iOS 26.5 deployment target — `.onScrollGeometryChange`, custom `ScrollTargetBehavior`, `Canvas`/`GraphicsContext.drawLayer` are all available), Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-14-roadmap-carousel-exercise-picking-design.md` (Carousel-related sections: "Carousel style", "Zoom mechanism", "Applies to both call sites", and the RoadmapWave carousel subsection under Architecture).

## Global Constraints

- Deployment target is iOS 26.5 — do not add availability shims for `.onScrollGeometryChange`, custom `ScrollTargetBehavior`, or `Canvas`/`GraphicsContext.drawLayer`; they're unconditionally available.
- `RoadmapWaveGeometry.nodeSpacing`, `.amplitude`, `.minNodeSize`, `.maxNodeSize` are unchanged — only padding becomes viewport-dependent (spacing stays fixed, per the file's existing "never fit everything to available width" invariant, which is about spacing, not padding).
- Both `RoadmapWave` call sites (`CustomizeRoutineView`'s `numbered: true` and `TodayView`'s hero `numbered: false`) get the carousel automatically — no new bool parameter to opt one out.
- Node transform pivots near the bottom of the node (by its duration label), not dead-center, so scale-up grows the glyph upward into headroom rather than the label downward into the container edge.

---

### Task 1: Focus-falloff math in `RoadmapWaveGeometry`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift:10-47` (the `RoadmapWaveGeometry` enum)
- Test: `Breath - Relax & StretchTests/RoadmapWaveGeometryTests.swift`

**Interfaces:**
- Produces: `RoadmapWaveGeometry.viewportPadding(visibleWidth:)`, `.focusScale(distance:)`, `.focusOpacity(distance:)`, `.focusBlur(distance:)`, `.segmentStrokeWidth(distance:)`, `.segmentOpacity(distance:)`, `.segmentBlur(distance:)` — all `(CGFloat) -> CGFloat`, pure, used by Task 2/3.

- [ ] **Step 1: Write the failing tests**

Add to `RoadmapWaveGeometryTests.swift`:

```swift
    @Test func viewportPaddingIsHalfTheVisibleWidth() {
        #expect(RoadmapWaveGeometry.viewportPadding(visibleWidth: 300) == 150)
    }

    @Test func viewportPaddingFallsBackToLeadingPaddingForTinyOrZeroWidth() {
        #expect(RoadmapWaveGeometry.viewportPadding(visibleWidth: 0) == RoadmapWaveGeometry.leadingPadding)
        #expect(RoadmapWaveGeometry.viewportPadding(visibleWidth: 20) == RoadmapWaveGeometry.leadingPadding)
    }

    @Test func focusScaleIsMaximalAtZeroDistanceAndClampedAtFloor() {
        #expect(RoadmapWaveGeometry.focusScale(distance: 0) == 1.62)
        #expect(RoadmapWaveGeometry.focusScale(distance: 10_000) == 0.48)
    }

    @Test func focusScaleDecreasesMonotonicallyWithDistance() {
        let near = RoadmapWaveGeometry.focusScale(distance: RoadmapWaveGeometry.nodeSpacing * 0.5)
        let far = RoadmapWaveGeometry.focusScale(distance: RoadmapWaveGeometry.nodeSpacing * 1.5)
        #expect(near > far)
    }

    @Test func focusOpacityIsMaximalAtZeroDistanceAndClampedAtFloor() {
        #expect(RoadmapWaveGeometry.focusOpacity(distance: 0) == 1.0)
        #expect(RoadmapWaveGeometry.focusOpacity(distance: 10_000) == 0.26)
    }

    @Test func focusBlurIsZeroNearCenterAndClampedAtCeiling() {
        #expect(RoadmapWaveGeometry.focusBlur(distance: 0) == 0)
        #expect(RoadmapWaveGeometry.focusBlur(distance: 10_000) == 2.1)
    }

    @Test func segmentStrokeWidthIsWidestAtZeroDistanceAndClampedAtFloor() {
        #expect(RoadmapWaveGeometry.segmentStrokeWidth(distance: 0) == 5.8)
        #expect(RoadmapWaveGeometry.segmentStrokeWidth(distance: 10_000) == 0.8)
    }

    @Test func segmentOpacityAndBlurFollowTheSameFalloffShape() {
        #expect(RoadmapWaveGeometry.segmentOpacity(distance: 0) == 1.0)
        #expect(RoadmapWaveGeometry.segmentOpacity(distance: 10_000) == 0.24)
        #expect(RoadmapWaveGeometry.segmentBlur(distance: 0) == 0)
        #expect(RoadmapWaveGeometry.segmentBlur(distance: 10_000) == 1.8)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveGeometryTests"`
Expected: FAIL — `viewportPadding`, `focusScale`, `focusOpacity`, `focusBlur`, `segmentStrokeWidth`, `segmentOpacity`, `segmentBlur` are not members of `RoadmapWaveGeometry`.

- [ ] **Step 3: Implement the falloff math**

Add to `RoadmapWaveGeometry` in `RoadmapWave.swift`, after the existing `nodeSize(forDuration:in:)`:

```swift
    // MARK: - Carousel focus falloff
    //
    // Pure functions of pixel distance from the viewport's horizontal
    // center to whichever node/curve-segment is being styled. Ported 1:1
    // from the interactive HTML mockup reviewed before this shipped (see
    // docs/superpowers/specs/2026-08-14-roadmap-carousel-exercise-picking-design.md)
    // so the tuning here is deliberate, not arbitrary: the node's transform
    // pivots near its duration label (RoadmapWave applies the scale with a
    // bottom-weighted anchor), so distance-based growth pushes the glyph
    // upward into headroom instead of the label into the container edge.

    /// Leading/trailing padding needed so node 0 and the last node can each
    /// reach the *center* of the viewport, not just its leading edge —
    /// unlike `nodeSpacing`, this is legitimately viewport-dependent (the
    /// "never fit to available width" invariant above is about spacing,
    /// not padding). Falls back to the fixed `leadingPadding` for a
    /// zero/near-zero width (e.g. a first layout pass before geometry is
    /// known), so a node is never pushed off both edges at once.
    static func viewportPadding(visibleWidth: CGFloat) -> CGFloat {
        let half = visibleWidth / 2
        return half > leadingPadding ? half : leadingPadding
    }

    static func focusScale(distance: CGFloat) -> CGFloat {
        max(0.48, 1.62 - (distance / nodeSpacing) * 0.85)
    }

    static func focusOpacity(distance: CGFloat) -> CGFloat {
        max(0.26, 1 - (distance / nodeSpacing) * 0.62)
    }

    static func focusBlur(distance: CGFloat) -> CGFloat {
        min(2.1, max(0, (distance / nodeSpacing - 0.3) * 1.7))
    }

    static func segmentStrokeWidth(distance: CGFloat) -> CGFloat {
        max(0.8, 5.8 - (distance / nodeSpacing) * 3.1)
    }

    static func segmentOpacity(distance: CGFloat) -> CGFloat {
        max(0.24, 1 - (distance / nodeSpacing) * 0.58)
    }

    static func segmentBlur(distance: CGFloat) -> CGFloat {
        min(1.8, max(0, (distance / nodeSpacing - 0.4) * 1.5))
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveGeometryTests"`
Expected: PASS, all cases including the pre-existing ones.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/RoadmapWave.swift" "Breath - Relax & StretchTests/RoadmapWaveGeometryTests.swift"
git commit -m "feat(roadmap): add carousel focus-falloff math to RoadmapWaveGeometry

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: Per-segment zoomed curve via `Canvas`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift:49-70` (replace `RoadmapWaveShape`)
- Test: `Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift`

**Interfaces:**
- Consumes: `RoadmapWaveGeometry.x(atContinuous:)`, `.y(atContinuous:midY:)`, `.segmentStrokeWidth(distance:)`, `.segmentOpacity(distance:)`, `.segmentBlur(distance:)`, `.nodeSpacing` (Task 1).
- Produces: `RoadmapWaveCurve: View` — a `Canvas`-based replacement for the old `RoadmapWaveShape`, taking `count`, `midY`, and `focusCenterX` (the x-coordinate, in the curve's own coordinate space, currently at the viewport's horizontal center) and drawing one independently-styled path segment per inter-node span.

- [ ] **Step 1: Write the failing test**

Add to `RoadmapWaveRenderingTests.swift`:

```swift
    @Test func curveRendersAtAnOffCenterFocusWithoutCrashing() {
        let renderer = ImageRenderer(content:
            RoadmapWaveCurve(count: 5, midY: 100, focusCenterX: 340)
                .frame(width: 600, height: 200)
        )
        #expect(renderer.cgImage != nil)
    }

    @Test func curveRendersWithASingleNodeWithoutCrashing() {
        let renderer = ImageRenderer(content:
            RoadmapWaveCurve(count: 1, midY: 100, focusCenterX: 24)
                .frame(width: 200, height: 200)
        )
        #expect(renderer.cgImage != nil)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveRenderingTests"`
Expected: FAIL — `RoadmapWaveCurve` does not exist (build error).

- [ ] **Step 3: Replace `RoadmapWaveShape` with `RoadmapWaveCurve`**

Replace the `RoadmapWaveShape` struct (lines 49-70) with:

```swift
// MARK: - RoadmapWaveCurve
//
// One Canvas-drawn path segment per inter-node span (not one continuous
// Path for the whole timeline) so each span's stroke-width/opacity/blur can
// be pushed toward `focusCenterX` independently — this, paired with the
// node-level falloff in RoadmapWave's ForEach below, is what reads as the
// camera zooming into a specific point on the curve rather than just that
// point's icon growing while a flat, uniformly-styled line sits under it.
private struct RoadmapWaveCurve: View {
    let count: Int
    let midY: CGFloat
    /// The x-coordinate, in this curve's own (unscrolled content)
    /// coordinate space, currently centered in the viewport.
    let focusCenterX: CGFloat

    var body: some View {
        Canvas { context, _ in
            guard count > 1 else { return }
            let stepsPerSegment = 16
            let gradient = Gradient(colors: [Color.luminaGradientStart, Color.luminaGradientEnd])

            for segment in 0..<(count - 1) {
                var path = Path()
                for step in 0...stepsPerSegment {
                    let t = CGFloat(segment) + CGFloat(step) / CGFloat(stepsPerSegment)
                    let point = CGPoint(
                        x: RoadmapWaveGeometry.x(atContinuous: t),
                        y: RoadmapWaveGeometry.y(atContinuous: t, midY: midY)
                    )
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }

                let midX = RoadmapWaveGeometry.x(atContinuous: CGFloat(segment) + 0.5)
                let distance = abs(midX - focusCenterX)
                let width = RoadmapWaveGeometry.segmentStrokeWidth(distance: distance)
                let opacity = RoadmapWaveGeometry.segmentOpacity(distance: distance)
                let blur = RoadmapWaveGeometry.segmentBlur(distance: distance)

                context.drawLayer { layer in
                    if blur > 0.01 { layer.addFilter(.blur(radius: blur)) }
                    layer.opacity = opacity
                    layer.stroke(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: RoadmapWaveGeometry.x(at: 0), y: midY),
                            endPoint: CGPoint(x: RoadmapWaveGeometry.x(at: count - 1), y: midY)
                        ),
                        style: StrokeStyle(lineWidth: width, lineCap: .round)
                    )
                }
            }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveRenderingTests"`
Expected: PASS for the two new tests. The existing `RoadmapWave`-level tests will still reference the old `RoadmapWaveShape` call site inside `RoadmapWave.body` until Task 3 rewires it — that's expected; don't fix `RoadmapWave.body` in this task.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/RoadmapWave.swift" "Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift"
git commit -m "feat(roadmap): replace flat curve Shape with per-segment zoomed Canvas

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: Continuous scroll tracking, snapping, and node falloff in `RoadmapWave`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/RoadmapWave.swift:72-141` (the `RoadmapWave` struct body)
- Test: `Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift`

**Interfaces:**
- Consumes: `RoadmapWaveGeometry.viewportPadding(visibleWidth:)`, `.focusScale/.focusOpacity/.focusBlur(distance:)`, `.nodeSpacing`, `.x(at:)`, `.y(at:midY:)`, `.nodeSize(forDuration:in:)` (Task 1); `RoadmapWaveCurve` (Task 2).
- Produces: `RoadmapWave: View` retains its existing public signature (`exercises: [Exercise]`, `numbered: Bool = false`) — no call-site changes needed in `TodayView`/`CustomizeRoutineView`.

- [ ] **Step 1: Write the failing test**

Add to `RoadmapWaveRenderingTests.swift`:

```swift
    @Test func rendersWithManyExercisesAtCarouselWidthWithoutCrashing() {
        // A width narrower than the full content forces the carousel's
        // scroll/snap/focus machinery to actually engage, unlike the
        // existing 360pt-wide tests which happen to fit everything.
        let exercises = (0..<8).map { makeExercise(name: "Exercise \($0)", duration: 30 + $0 * 15) }
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises, numbered: true).frame(width: 320, height: 260))
        #expect(renderer.cgImage != nil)
    }
```

- [ ] **Step 2: Run test to verify it fails or crashes**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveRenderingTests/rendersWithManyExercisesAtCarouselWidthWithoutCrashing"`
Expected: PASS today (the old free-scroll implementation doesn't crash either) — this test's job is to keep passing *after* Task 3's rewrite, not to fail first. Confirm it passes now, then proceed; re-run after Step 3 as the real regression check.

- [ ] **Step 3: Rewrite `RoadmapWave.body` to drive the carousel**

Replace the whole `RoadmapWave` struct (everything from `struct RoadmapWave: View {` to its closing brace, currently lines 81-140) with:

```swift
struct RoadmapWave: View {
    let exercises: [Exercise]
    var numbered: Bool = false

    /// Continuous horizontal content-offset, read every scroll frame via
    /// `.onScrollGeometryChange` — not just the settled post-snap position
    /// — because the "glide" the carousel needs (nodes/curve scaling
    /// *during* the drag, not only once it stops) needs per-frame position.
    @State private var contentOffsetX: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0

    private var midY: CGFloat {
        RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + (numbered ? 14 : 4)
    }

    private var contentHeight: CGFloat {
        midY + RoadmapWaveGeometry.amplitude + RoadmapWaveGeometry.maxNodeSize / 2 + 22
    }

    private var durations: [Int] { exercises.map(\.durationSeconds) }

    private var padding: CGFloat {
        RoadmapWaveGeometry.viewportPadding(visibleWidth: viewportWidth)
    }

    private var totalWidth: CGFloat {
        let base = padding * 2
        guard exercises.count > 1 else { return base }
        return base + RoadmapWaveGeometry.nodeSpacing * CGFloat(exercises.count - 1)
    }

    /// The x-coordinate (in content space) currently centered in the
    /// viewport — what every node/curve-segment measures its distance from.
    private var focusCenterX: CGFloat {
        contentOffsetX + viewportWidth / 2
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                RoadmapWaveCurve(count: exercises.count, midY: midY, focusCenterX: focusCenterX)

                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    nodeView(index: index, exercise: exercise)
                }
            }
            .frame(width: totalWidth, height: contentHeight)
        }
        .frame(height: contentHeight)
        .scrollTargetBehavior(RoadmapPagingBehavior(padding: padding))
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.x }) { _, newOffset in
            contentOffsetX = newOffset
        }
        .background {
            GeometryReader { geo in
                Color.clear.onAppear { viewportWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in viewportWidth = newWidth }
            }
        }
        .overlay { carouselVignette }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func nodeView(index: Int, exercise: Exercise) -> some View {
        let category = ExerciseCategory.primary(for: exercise.targetBodyParts)
        let size = RoadmapWaveGeometry.nodeSize(forDuration: exercise.durationSeconds, in: durations)
        let x = padding + RoadmapWaveGeometry.nodeSpacing * CGFloat(index)
        let y = RoadmapWaveGeometry.y(at: index, midY: midY)
        let distance = abs(x - focusCenterX)
        let scale = RoadmapWaveGeometry.focusScale(distance: distance)
        let opacity = RoadmapWaveGeometry.focusOpacity(distance: distance)
        let blur = RoadmapWaveGeometry.focusBlur(distance: distance)

        VStack(spacing: 8) {
            if numbered {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 15, height: 15)
                    .background(Color.luminaPrimary, in: Circle())
                    .opacity(scale > 1.05 ? 1 : 0)
            }
            PoseGlyphIcon(exercise: exercise, category: category, size: size)
            Text(exercise.durationFormatted)
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        // Pivoting near the bottom of the stack (by the duration label)
        // rather than dead-center means scaling up pushes the glyph
        // further UP into open headroom above the curve, and leaves the
        // duration label roughly anchored — nodes on the low side of the
        // curve (odd indices, per RoadmapWaveGeometry.y) no longer grow
        // downward into the container edge as they scale up.
        .scaleEffect(scale, anchor: UnitPoint(x: 0.5, y: 0.84))
        .opacity(opacity)
        .blur(radius: blur)
        .position(x: x, y: y)
        .zIndex(Double(scale))
    }

    private var carouselVignette: some View {
        // Fixed over the viewport (this overlay does not scroll with the
        // content) — stays clear near center, dims toward the edges, like
        // looking through a lens centered on whichever node is focused.
        RadialGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.clear,
                Color.luminaSurface.opacity(0.55),
            ]),
            center: .center,
            startRadius: 10,
            endRadius: max(viewportWidth, 1) * 0.62
        )
        .allowsHitTesting(false)
    }

    private var accessibilityLabel: String {
        guard !exercises.isEmpty else { return "No exercises" }
        let items = exercises.map { "\($0.name), \($0.durationFormatted)" }.joined(separator: "; ")
        return "\(exercises.count) exercise\(exercises.count == 1 ? "" : "s"): \(items)"
    }
}

// MARK: - RoadmapPagingBehavior
//
// `.scrollTargetBehavior(.paging)` snaps to multiples of the *container*
// width — the wrong fit here, since RoadmapWaveGeometry.nodeSpacing is a
// fixed constant independent of container width. This snaps to the
// nearest node-spacing multiple instead, so a node always lands centered
// in the viewport regardless of how wide that viewport is.
private struct RoadmapPagingBehavior: ScrollTargetBehavior {
    let padding: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let raw = target.rect.minX
        let stepsFromStart = ((raw - padding) / RoadmapWaveGeometry.nodeSpacing).rounded()
        let snapped = padding + stepsFromStart * RoadmapWaveGeometry.nodeSpacing
        target.rect.origin.x = max(0, snapped)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/RoadmapWaveRenderingTests" -only-testing:"Breath - Relax & StretchTests/RoadmapWaveGeometryTests"`
Expected: PASS — all `RoadmapWaveRenderingTests` (including the pre-existing `rendersWithNoExercisesWithoutCrashing`, `rendersWithASingleExercise`, `rendersNumberedVariant`, `rendersWithMultipleExercises`, and the new `rendersWithManyExercisesAtCarouselWidthWithoutCrashing`) and all `RoadmapWaveGeometryTests`.

- [ ] **Step 5: Update the file's header doc comment**

`RoadmapWave.swift`'s top-of-file comment (lines 3-9 and 72-80) describes the old free-scroll, "spacing never fits to width" behavior. Update the `RoadmapWave` struct's doc comment (currently lines 72-80) to:

```swift
// MARK: - RoadmapWave
//
// A session's exercises as duration-sized PoseGlyphIcon nodes on a
// continuous curve, paging one exercise at a time in a horizontal
// ScrollView: the centered node and the curve segment under it read as
// zoomed in (larger, sharper, brighter), while neighbors recede (smaller,
// blurred, dimmed toward a vignette). Node 0 always renders first (an
// un-scrolled ScrollView shows its content's leading edge first in LTR
// layouts), and the user pages right to bring each subsequent exercise
// into focus. Spacing between nodes is fixed regardless of exercise count
// (RoadmapWaveGeometry.nodeSpacing) — only the leading/trailing padding is
// viewport-dependent, so node 0 and the last node can each reach dead
// center. Stays PoseGlyphIcon-only by design: this is compact wayfinding,
// not the primary browsing surface, so it's exempt from the general
// animation-vs-glyph size rule (see ExerciseArt, Task 6).
```

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/RoadmapWave.swift" "Breath - Relax & StretchTests/RoadmapWaveRenderingTests.swift"
git commit -m "feat(roadmap): drive RoadmapWave as a zoomed-wave paging carousel

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Manual verification in the simulator

**Files:** none (verification only — no code changes)

- [ ] **Step 1: Build and launch**

Use the project's `verify` skill (`.claude/skills/verify/SKILL.md`) to build and launch the app in the iOS Simulator.

- [ ] **Step 2: Verify the Home hero roadmap**

On the Home tab, confirm the hero card's roadmap (non-numbered) shows one exercise centered/enlarged with neighbors peeking at the edges, and that dragging horizontally glides the curve and pages between exercises with a snap-to-center settle.

- [ ] **Step 3: Verify the Customize roadmap**

Tap "Customize" from the Home hero. Confirm the numbered roadmap shows the same zoomed-carousel behavior, with number badges visible on the focused node and faded on receded neighbors, and that no node's icon or duration label clips against the container edges while dragging through all exercises (pay particular attention to exercises on the low side of the curve — odd indices).

- [ ] **Step 4: Screenshot and confirm no regressions**

Take a screenshot at rest (node 0 focused) and mid-drag (a middle node focused). Confirm neither shows visual artifacts (clipped text, missing curve segments, a fully-opaque vignette hiding content it shouldn't).
