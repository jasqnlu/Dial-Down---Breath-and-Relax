# Node-Graph Exercises Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat, filterable Exercises tab list with a pinch-zoom category → exercise node graph, matching the interaction already built for Body Map, while keeping search and the create/filter toolbar.

**Architecture:** A pure data layer (`ExerciseCategory`, mapping 40 `MuscleGroup` values into 8 coarse categories) feeds a `Canvas`-free SwiftUI node graph (`ExerciseGraphView`) that reuses Body Map's `MagnifyGesture`/`DragGesture` pinch-zoom pattern. `ExerciseListView` becomes the tab's root shell: it swaps between the graph (no search text) and the existing flat filtered list (search text present), and keeps the create/+ and type-filter toolbar.

**Tech Stack:** SwiftUI, SwiftData (`@Query`), Swift Testing (`@Test`/`#expect`, not XCTest), Xcode's `PBXFileSystemSynchronizedRootGroup` (new `.swift` files under `Breath - Relax & Stretch/` or `Breath - Relax & StretchTests/` are auto-added to their targets — no `.pbxproj` edits needed).

## Global Constraints

- Module name for tests is `BreathRelaxStretch`; tests use `@testable import BreathRelaxStretch`.
- Use the existing Lumina design tokens (`Color.lumina*`, `Font.lumina*`, `LuminaPillButtonStyle`, `.luminaCard()`) — don't invent new ones.
- Build/verify with: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`.
- Unit tests: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`.
- Spec: `docs/superpowers/specs/2026-07-08-node-graph-exercises-tab-design.md`.

---

### Task 1: `ExerciseCategory` model + category-mapping tests

**Files:**
- Create: `Breath - Relax & Stretch/Models/ExerciseCategory.swift`
- Test: `Breath - Relax & StretchTests/ExerciseCategoryTests.swift`

**Interfaces:**
- Consumes: `MuscleGroup` (`Breath - Relax & Stretch/Models/MuscleGroups.swift`) — `enum MuscleGroup: String, CaseIterable, Codable` with cases `neckFront, neckBack, leftTraps, rightTraps, leftDelts, rightDelts, leftChest, rightChest, abs, leftObliques, rightObliques, leftLats, rightLats, spinalErectors, lowerBack, leftBiceps, rightBiceps, leftTriceps, rightTriceps, leftForearm, rightForearm, leftGlutes, rightGlutes, leftHipFlexors, rightHipFlexors, leftAdductors, rightAdductors, leftQuads, rightQuads, leftHamstrings, rightHamstrings, leftCalves, rightCalves, leftTibialis, rightTibialis, head, leftHand, rightHand, leftFoot, rightFoot` (40 cases).
- Produces: `enum ExerciseCategory: String, CaseIterable, Identifiable` with `accentColor: Color` and `static func categories(for targetBodyParts: [String]) -> Set<ExerciseCategory>` — used by Task 3 (`ExerciseGraphView`) and Task 4 (`ExerciseListView`).

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import BreathRelaxStretch

struct ExerciseCategoryTests {
    @Test func everyMuscleGroupMapsToExactlyOneCategory() {
        for group in MuscleGroup.allCases {
            let categories = ExerciseCategory.categories(for: [group.rawValue])
            #expect(categories.count == 1, "MuscleGroup \(group.rawValue) should map to exactly one category")
        }
    }

    @Test func singlePartMapsToExpectedCategory() {
        #expect(ExerciseCategory.categories(for: ["Left Quadriceps"]) == [.legs])
        #expect(ExerciseCategory.categories(for: ["Abs"]) == [.core])
        #expect(ExerciseCategory.categories(for: ["Head"]) == [.neck])
    }

    @Test func exerciseSpanningCategoriesMapsToBoth() {
        let categories = ExerciseCategory.categories(for: ["Left Chest", "Left Shoulder"])
        #expect(categories == [.chest, .shoulders])
    }

    @Test func unknownPartNameIsIgnored() {
        #expect(ExerciseCategory.categories(for: ["Not A Real Part"]).isEmpty)
    }

    @Test func allCategoriesHaveEightCases() {
        #expect(ExerciseCategory.allCases.count == 8)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseCategoryTests"`
Expected: FAIL to build — `ExerciseCategory` does not exist yet.

- [ ] **Step 3: Implement `ExerciseCategory`**

```swift
import SwiftUI

/// Eight coarse groupings over MuscleGroup's ~40 fine-grained values, used
/// as the top-level nodes in the Exercises tab's pinch-zoom node graph.
enum ExerciseCategory: String, CaseIterable, Identifiable {
    case neck = "Neck"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case back = "Back"
    case core = "Core"
    case arms = "Arms"
    case hipsGlutes = "Hips & Glutes"
    case legs = "Legs"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .neck:       return .teal
        case .shoulders:  return .orange
        case .chest:      return .pink
        case .back:       return .indigo
        case .core:       return .yellow
        case .arms:       return .blue
        case .hipsGlutes: return .purple
        case .legs:       return .green
        }
    }

    /// MuscleGroup raw value -> the one category it belongs to.
    private static let membership: [String: ExerciseCategory] = {
        var map: [String: ExerciseCategory] = [:]
        func assign(_ category: ExerciseCategory, _ groups: [MuscleGroup]) {
            for group in groups { map[group.rawValue] = category }
        }
        assign(.neck, [.neckFront, .neckBack, .head])
        assign(.shoulders, [.leftDelts, .rightDelts, .leftTraps, .rightTraps])
        assign(.chest, [.leftChest, .rightChest])
        assign(.back, [.leftLats, .rightLats, .spinalErectors, .lowerBack])
        assign(.core, [.abs, .leftObliques, .rightObliques])
        assign(.arms, [.leftBiceps, .rightBiceps, .leftTriceps, .rightTriceps,
                       .leftForearm, .rightForearm, .leftHand, .rightHand])
        assign(.hipsGlutes, [.leftGlutes, .rightGlutes, .leftHipFlexors, .rightHipFlexors,
                              .leftAdductors, .rightAdductors])
        assign(.legs, [.leftQuads, .rightQuads, .leftHamstrings, .rightHamstrings,
                       .leftCalves, .rightCalves, .leftTibialis, .rightTibialis,
                       .leftFoot, .rightFoot])
        return map
    }()

    /// Categories an exercise belongs to, derived from its target body
    /// parts. Names that aren't a known MuscleGroup raw value are ignored.
    static func categories(for targetBodyParts: [String]) -> Set<ExerciseCategory> {
        Set(targetBodyParts.compactMap { membership[$0] })
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseCategoryTests"`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/ExerciseCategory.swift" "Breath - Relax & StretchTests/ExerciseCategoryTests.swift"
git commit -m "feat: add ExerciseCategory taxonomy for node-graph Exercises tab"
```

---

### Task 2: `GraphLayout` node-position math + tests

**Files:**
- Create: `Breath - Relax & Stretch/Views/Exercises/GraphLayout.swift`
- Test: `Breath - Relax & StretchTests/GraphLayoutTests.swift`

**Interfaces:**
- Consumes: nothing (pure geometry).
- Produces: `enum GraphLayout` with `static func categoryPosition(index: Int, count: Int) -> CGPoint` and `static func exercisePosition(index: Int, count: Int, around center: CGPoint, radius: CGFloat) -> CGPoint`, both returning points in a normalised `-1...1` space — used by Task 3 (`ExerciseGraphView`).

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
import CoreGraphics
@testable import BreathRelaxStretch

struct GraphLayoutTests {
    @Test func categoryPositionsAreEvenlySpacedOnUnitRing() {
        let count = 8
        for index in 0..<count {
            let point = GraphLayout.categoryPosition(index: index, count: count)
            let distance = (point.x * point.x + point.y * point.y).squareRoot()
            #expect(abs(distance - 1) < 0.0001)
        }
    }

    @Test func firstCategorySitsAtTwelveOClock() {
        let point = GraphLayout.categoryPosition(index: 0, count: 8)
        #expect(abs(point.x) < 0.0001)
        #expect(abs(point.y - (-1)) < 0.0001)
    }

    @Test func categoryPositionsAreAllDistinct() {
        let count = 8
        let points = (0..<count).map { GraphLayout.categoryPosition(index: $0, count: count) }
        for i in 0..<points.count {
            for j in (i+1)..<points.count {
                let dx = points[i].x - points[j].x
                let dy = points[i].y - points[j].y
                #expect((dx*dx + dy*dy).squareRoot() > 0.01)
            }
        }
    }

    @Test func exercisePositionsSitAtGivenRadiusFromCenter() {
        let center = CGPoint(x: 0.3, y: -0.2)
        let radius: CGFloat = 0.25
        for index in 0..<5 {
            let point = GraphLayout.exercisePosition(index: index, count: 5, around: center, radius: radius)
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = (dx*dx + dy*dy).squareRoot()
            #expect(abs(distance - radius) < 0.0001)
        }
    }

    @Test func zeroCountReturnsCenterOrZeroWithoutCrashing() {
        #expect(GraphLayout.categoryPosition(index: 0, count: 0) == .zero)
        let center = CGPoint(x: 1, y: 1)
        #expect(GraphLayout.exercisePosition(index: 0, count: 0, around: center, radius: 0.3) == center)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/GraphLayoutTests"`
Expected: FAIL to build — `GraphLayout` does not exist yet.

- [ ] **Step 3: Implement `GraphLayout`**

```swift
import CoreGraphics

/// Pure node-position math for the Exercises tab's node graph, in a
/// normalised -1...1 space independent of screen size. Deterministic
/// (no physics simulation) so the layout is calm and reproducible.
enum GraphLayout {
    /// Evenly spaced position on a unit ring for one of `count` categories.
    /// Index 0 sits at 12 o'clock; indices proceed clockwise.
    static func categoryPosition(index: Int, count: Int) -> CGPoint {
        guard count > 0 else { return .zero }
        let angle = (CGFloat(index) / CGFloat(count)) * 2 * .pi - .pi / 2
        return CGPoint(x: cos(angle), y: sin(angle))
    }

    /// Position for the nth of `count` exercise nodes on a ring of `radius`
    /// around `center`, in the same normalised space.
    static func exercisePosition(index: Int, count: Int, around center: CGPoint, radius: CGFloat) -> CGPoint {
        guard count > 0 else { return center }
        let angle = (CGFloat(index) / CGFloat(count)) * 2 * .pi
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/GraphLayoutTests"`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/GraphLayout.swift" "Breath - Relax & StretchTests/GraphLayoutTests.swift"
git commit -m "feat: add pure node-position math for the exercise node graph"
```

---

### Task 3: `ExerciseGraphView` — node rendering + pinch-zoom focus

**Files:**
- Create: `Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift`

**Interfaces:**
- Consumes: `ExerciseCategory` (Task 1) — `.allCases`, `.accentColor`, `.categories(for:)`. `GraphLayout` (Task 2) — `.categoryPosition(index:count:)`, `.exercisePosition(index:count:around:radius:)`. `Exercise` (`Models/Exercise.swift`) — `uuid: UUID`, `name: String`, `type: ExerciseType`, `targetBodyParts: [String]`.
- Produces: `struct ExerciseGraphView: View` with `init(exercises: [Exercise], typeFilter: ExerciseType?, onSelect: @escaping (Exercise) -> Void)` — used by Task 4 (`ExerciseListView`).

This task has no isolated unit test (it's gesture/rendering code); it's verified by building successfully and by the manual simulator screenshots in Task 5. Write it directly, then verify with a build.

- [ ] **Step 1: Write `ExerciseGraphView.swift`**

```swift
import SwiftUI

// MARK: - Exercise Graph View
//
// Pinch-zoom node graph: 8 category circles arranged on a ring; pinching in
// near one focuses it, fading in its exercises on a smaller ring around it.
// Mirrors the zoom/pan gesture pattern already used by BodyMapView.

struct ExerciseGraphView: View {
    let exercises: [Exercise]
    let typeFilter: ExerciseType?
    let onSelect: (Exercise) -> Void

    @State private var zoomScale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var focusedCategory: ExerciseCategory?

    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 3
    private let focusThreshold: CGFloat = 1.8
    private let categoryRadius: CGFloat = 0.62      // normalised distance from canvas center
    private let exerciseRingRadius: CGFloat = 0.30  // normalised distance from a focused category

    private var filteredExercises: [Exercise] {
        guard let typeFilter else { return exercises }
        return exercises.filter { $0.type == typeFilter }
    }

    private func exercises(in category: ExerciseCategory) -> [Exercise] {
        filteredExercises.filter { ExerciseCategory.categories(for: $0.targetBodyParts).contains(category) }
    }

    private var visibleCategories: [ExerciseCategory] {
        ExerciseCategory.allCases.filter { !exercises(in: $0).isEmpty }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let scale = min(size.width, size.height) / 2
            let categories = visibleCategories

            ZStack {
                ForEach(Array(categories.enumerated()), id: \.element) { pair in
                    categoryLayer(pair: pair, categories: categories, center: center, scale: scale)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .scaleEffect(zoomScale, anchor: .center)
            .offset(panOffset)
            .gesture(magnifyGesture(center: center, scale: scale))
            .simultaneousGesture(panGesture)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: focusedCategory)
        }
    }

    @ViewBuilder
    private func categoryLayer(pair: (offset: Int, element: ExerciseCategory),
                                categories: [ExerciseCategory],
                                center: CGPoint, scale: CGFloat) -> some View {
        let index = pair.offset
        let category = pair.element
        let normalized = GraphLayout.categoryPosition(index: index, count: categories.count)
        let isFocused = focusedCategory == category
        let isDimmed = focusedCategory != nil && !isFocused
        let categoryExercises = exercises(in: category)

        CategoryNode(category: category, count: categoryExercises.count, isFocused: isFocused)
            .position(x: center.x + normalized.x * scale * categoryRadius,
                      y: center.y + normalized.y * scale * categoryRadius)
            .opacity(isDimmed ? 0 : 1)
            .allowsHitTesting(!isDimmed)
            .onTapGesture { focus(on: category, index: index, categories: categories, center: center, scale: scale) }

        if isFocused {
            let categoryCenter = CGPoint(x: normalized.x * categoryRadius, y: normalized.y * categoryRadius)
            ForEach(Array(categoryExercises.enumerated()), id: \.element.uuid) { exPair in
                let exIndex = exPair.offset
                let exercise = exPair.element
                let exNormalized = GraphLayout.exercisePosition(
                    index: exIndex, count: categoryExercises.count,
                    around: categoryCenter, radius: exerciseRingRadius)
                ExerciseNode(exercise: exercise, color: category.accentColor)
                    .position(x: center.x + exNormalized.x * scale,
                              y: center.y + exNormalized.y * scale)
                    .transition(.opacity.combined(with: .scale(scale: 0.5)))
                    .onTapGesture { onSelect(exercise) }
            }
        }
    }

    // MARK: - Focus state

    private func focus(on category: ExerciseCategory, index: Int, categories: [ExerciseCategory],
                        center: CGPoint, scale: CGFloat) {
        let normalized = GraphLayout.categoryPosition(index: index, count: categories.count)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            focusedCategory = category
            zoomScale = focusThreshold
            lastScale = focusThreshold
            panOffset = CGSize(width: -normalized.x * scale * categoryRadius * (focusThreshold - 1),
                                height: -normalized.y * scale * categoryRadius * (focusThreshold - 1))
            lastPan = panOffset
        }
    }

    private func unfocus() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            focusedCategory = nil
            zoomScale = minZoom
            lastScale = minZoom
            panOffset = .zero
            lastPan = .zero
        }
    }

    // MARK: - Gestures

    private func magnifyGesture(center: CGPoint, scale: CGFloat) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(lastScale * value.magnification, minZoom), maxZoom)
                if zoomScale < focusThreshold, focusedCategory != nil {
                    focusedCategory = nil
                }
            }
            .onEnded { _ in
                lastScale = zoomScale
                let categories = visibleCategories
                if zoomScale < focusThreshold {
                    unfocus()
                } else if focusedCategory == nil,
                          let nearestIndex = nearestCategoryIndex(categories: categories, center: center, scale: scale) {
                    focus(on: categories[nearestIndex], index: nearestIndex, categories: categories,
                          center: center, scale: scale)
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                panOffset = CGSize(width: lastPan.width + value.translation.width,
                                    height: lastPan.height + value.translation.height)
            }
            .onEnded { _ in lastPan = panOffset }
    }

    /// Index of whichever visible category's node sits nearest the canvas
    /// center under the current pan/zoom — the category a pinch-in focuses.
    private func nearestCategoryIndex(categories: [ExerciseCategory], center: CGPoint, scale: CGFloat) -> Int? {
        guard !categories.isEmpty else { return nil }
        var bestIndex = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in categories.indices {
            let normalized = GraphLayout.categoryPosition(index: index, count: categories.count)
            let screenX = normalized.x * scale * categoryRadius * zoomScale + panOffset.width
            let screenY = normalized.y * scale * categoryRadius * zoomScale + panOffset.height
            let distance = (screenX * screenX + screenY * screenY).squareRoot()
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }
}

// MARK: - Category node

private struct CategoryNode: View {
    let category: ExerciseCategory
    let count: Int
    let isFocused: Bool

    private var diameter: CGFloat { isFocused ? 90 : 64 }

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(category.accentColor.opacity(0.85))
                .frame(width: diameter, height: diameter)
                .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1.5))
            Text(category.rawValue)
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurface)
            Text("\(count)")
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        .contentShape(Circle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(count) exercise\(count == 1 ? "" : "s")")
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Exercise node

private struct ExerciseNode: View {
    let exercise: Exercise
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.75))
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
            Text(exercise.name)
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurface)
                .lineLimit(1)
                .frame(maxWidth: 76)
        }
        .contentShape(Circle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(exercise.name)
    }
}

// MARK: - Preview

#Preview {
    ExerciseGraphView(exercises: [], typeFilter: nil, onSelect: { _ in })
        .background(Color.luminaSurface)
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `** BUILD SUCCEEDED **`. `ExerciseGraphView` isn't referenced from any tab yet, so this only confirms it compiles standalone — Task 4 wires it in.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseGraphView.swift"
git commit -m "feat: add pinch-zoom node graph view for browsing exercises"
```

---

### Task 4: Rewrite `ExerciseListView` as the tab root; retire the old banners

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift` (full rewrite)
- Delete: `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift`

**Interfaces:**
- Consumes: `ExerciseGraphView` (Task 3) — `init(exercises:typeFilter:onSelect:)`. `ExerciseRow`, `ExerciseDetailView`, `CreateExerciseView` (all already exist in this file/folder, unchanged). `ExerciseType.allCases` (`Models/Exercise.swift`).
- Produces: `struct ExerciseListView: View` (same public shape as before — `HomeView.tabContent(_:)` case 2 keeps calling `ExerciseListView()` unchanged).

**Note:** `ForYouSection`, the sleep-suggestion banner, and the calendar free-slot banner are dropped per the design spec's "keep toolbar, drop banners" decision. `ForYouSection` is defined in its own file and used nowhere else (confirmed by grep during design) — delete the file. The sleep/calendar banner structs and their `HealthKitService`/`CalendarService` calls were private to `ExerciseListView.swift` — they're removed by this rewrite, not left dangling.

- [ ] **Step 1: Confirm `ForYouSection` has no other callers**

Run: `grep -rln "ForYouSection" --include="*.swift" . | grep -v worktrees`
Expected: only `Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift` and `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift`. If anything else appears, stop and re-scope this step instead of deleting.

- [ ] **Step 2: Rewrite `ExerciseListView.swift`**

```swift
import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedType: ExerciseType? = nil
    @State private var showingCreate = false
    @State private var selectedExercise: Exercise?

    private var searchFiltered: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || ex.type == selectedType
            return matchesSearch && matchesType
        }
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(get: { selectedExercise != nil }, set: { if !$0 { selectedExercise = nil } })
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ExerciseGraphView(exercises: exercises, typeFilter: selectedType) { exercise in
                        selectedExercise = exercise
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchFiltered, id: \.uuid) { exercise in
                                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                    ExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                                .luminaCard()
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .overlay {
                        if searchFiltered.isEmpty {
                            ContentUnavailableView(
                                "No Exercises",
                                systemImage: "figure.mind.and.body",
                                description: Text("No results for your search.")
                            )
                        }
                    }
                }
            }
            .background(Color.luminaSurface)
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .floatingTabBarClearance()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("All Types") { selectedType = nil }
                        Divider()
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Button(type.rawValue) { selectedType = type }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedType == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create exercise")
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateExerciseView()
            }
            .navigationDestination(isPresented: isShowingDetail) {
                if let selectedExercise {
                    ExerciseDetailView(exercise: selectedExercise)
                }
            }
            .overlay {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "figure.mind.and.body",
                        description: Text("Seed exercises will load on first launch.")
                    )
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var difficultyLabel: String {
        switch exercise.difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return ""
        }
    }

    private var hasVideo: Bool {
        exercise.localVideoURL != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(exercise.name)
                    .font(.luminaCardTitle)
                if hasVideo {
                    Image(systemName: "film.fill")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            HStack(spacing: 12) {
                Label(exercise.durationFormatted, systemImage: "clock")
                Label(exercise.type.rawValue, systemImage: "figure.mind.and.body")
                Label(difficultyLabel, systemImage: "chart.bar")
            }
            .font(.luminaCaption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.type.rawValue), \(exercise.durationFormatted), \(difficultyLabel)\(hasVideo ? ", has video" : "")")
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
```

- [ ] **Step 3: Delete the now-unused `ForYouSection.swift`**

```bash
rm "Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift"
```

- [ ] **Step 4: Build to verify everything compiles together**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Run the full unit test suite to confirm nothing else broke**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: all tests PASS, including the new `ExerciseCategoryTests` and `GraphLayoutTests` from Tasks 1–2.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Exercises/ExerciseListView.swift"
git rm "Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift"
git commit -m "feat: wire node graph into Exercises tab, drop ForYou/sleep/calendar banners"
```

---

### Task 5: Manual simulator verification

**Files:** none (verification only).

**Interfaces:** none — this task drives the app built in Tasks 1–4 via XCUITest, per `.claude/skills/verify/SKILL.md`.

- [ ] **Step 1: Write a throwaway UI test**

Create `Breath - Relax & StretchUITests/ExerciseGraphVerifyTests.swift`:

```swift
import XCTest

final class ExerciseGraphVerifyTests: XCTestCase {
    func testGraphOverviewFocusAndSearch() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES",
            "-auth.provider", "guest",
            "-debugInitialTab", "2",
        ]
        app.launch()

        let overview = XCTAttachment(screenshot: app.screenshot())
        overview.lifetime = .keepAlways
        overview.name = "01-graph-overview"
        add(overview)

        // Tap the first category node's approximate position (top of the ring).
        let canvas = app.windows.firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        sleep(1)

        let focused = XCTAttachment(screenshot: app.screenshot())
        focused.lifetime = .keepAlways
        focused.name = "02-graph-focused-category"
        add(focused)

        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 5) {
            searchField.tap()
            searchField.typeText("stretch")
        }
        let searched = XCTAttachment(screenshot: app.screenshot())
        searched.lifetime = .keepAlways
        searched.name = "03-search-swapped-list"
        add(searched)
    }
}
```

- [ ] **Step 2: Uninstall any stale app state, then run the test**

```bash
xcrun simctl uninstall "iPhone 17" com.jasonlu.Breath--Relax---Stretch
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/ExerciseGraphVerifyTests" -resultBundlePath /tmp/exercise-graph-verify.xcresult
```

Expected: test runs to completion (pass or fail — either way, screenshots are attached as long as `add(...)` executed before any failure).

- [ ] **Step 3: Export and view the screenshots**

```bash
xcrun xcresulttool export attachments --path /tmp/exercise-graph-verify.xcresult --output-path /tmp/exercise-graph-verify-out
```

Read each exported `.png` (via the manifest's `suggestedHumanReadableName`) and confirm:
- `01-graph-overview`: 8 tinted category circles with labels and counts, no layer picker or list.
- `02-graph-focused-category`: one category enlarged with smaller exercise nodes fanned around it.
- `03-search-swapped-list`: a flat scrollable list of matching `ExerciseRow`s, not the graph.

If any screenshot looks wrong (nodes overlapping, off-screen, unreadable text), fix the relevant view in `ExerciseGraphView.swift` (Task 3) or `GraphLayout.swift` (Task 2) and re-run this task's Steps 2–3 — don't move on until the three screenshots look right.

- [ ] **Step 4: Delete the throwaway UI test**

```bash
rm "Breath - Relax & Stretch/Views/Exercises/../../../Breath - Relax & StretchUITests/ExerciseGraphVerifyTests.swift" 2>/dev/null || rm "Breath - Relax & StretchUITests/ExerciseGraphVerifyTests.swift"
```

- [ ] **Step 5: Update the graphify knowledge graph**

```bash
graphify update .
```

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "chore: verify node-graph Exercises tab in simulator"
```

(If Step 4 leaves nothing staged beyond the graphify output, `git status` first — only commit if there's something to commit; graphify's `graph.json`/`GRAPH_REPORT.md` are typically gitignored, check before assuming this step produces a commit.)

---

## Self-Review

**Spec coverage:**
- Category taxonomy (8 categories, all `MuscleGroup` cases mapped) → Task 1. ✓
- Deterministic node layout, no physics → Task 2. ✓
- Continuous pinch-zoom focus/unfocus mechanic, tap-to-select-exercise → Task 3. ✓
- Search swaps to flat filtered list → Task 4. ✓
- Toolbar (+/filter) kept, banners dropped → Task 4. ✓
- `BodyPartExercisesView` unchanged → not touched by any task. ✓
- Manual verification screenshots → Task 5. ✓

**Placeholder scan:** no TBD/TODO; every step has complete code or exact commands.

**Type consistency:** `ExerciseGraphView.init(exercises:typeFilter:onSelect:)` (Task 3) matches its call site in `ExerciseListView` (Task 4) exactly. `ExerciseCategory.categories(for:)` (Task 1) is used with the same signature in both `ExerciseGraphView` (Task 3) and its own tests (Task 1). `GraphLayout.categoryPosition`/`exercisePosition` (Task 2) signatures match their use in `ExerciseGraphView` (Task 3).
