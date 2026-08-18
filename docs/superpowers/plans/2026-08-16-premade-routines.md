# Premade Routines Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a curated set of premade, single-session routine templates (Office Stretch, Athletic Recovery, etc.), browsable from both Home and the Routines tab, where tapping one opens the normal routine builder pre-filled with the template's name and exercises — not a bespoke "preview" screen, and nothing is saved until the user hits Save there.

**Architecture:** A new `PremadeRoutine` model (same shape the deleted `ContentPack` had: id/title/summary/icon/exerciseNames, resolved against the live `Exercise` catalog by name at render time) backs two new UI surfaces — a `PremadeRoutinesView` list reachable from the Routines tab's top entry row (the `entryRow` helper Phase 1 deliberately left in place for this), and a horizontal card row on `TodayView` between "Recommended for You" and "For You." Both surfaces do the same thing on tap: resolve the template's exercise names to `Exercise` IDs and open `RoutineBuilderView(initialExerciseIDs:initialName:)` — a new `initialName` parameter this plan adds, since `RoutineBuilderView` currently has no way to pre-fill the name field without treating the sheet as editing an existing `Routine`. This is Phase 3 of 4 from the routines-tab-redesign spec; Phases 1 (cleanup) and 2 (Today pin) are separate plans.

**Tech Stack:** SwiftUI, SwiftData (`Exercise` query only — `PremadeRoutine` is a plain struct, not a `@Model`, matching `GoalMeta`'s and the deleted `ContentPack`'s pattern). Swift Testing for the exercise-name integrity check.

**Spec:** `docs/superpowers/specs/2026-08-16-routines-tab-redesign-design.md` (sections "PremadeRoutine (new...)", "PremadeRoutinesView (new...)", "Home — new section")

## Global Constraints

- `PremadeRoutine` fields: `id: String, title: String, summary: String, icon: String, exerciseNames: [String]` — identical shape to the deleted `ContentPack`.
- Starting set (5 routines, IDs kept from the deleted `ContentPack` where they carry over): **Office Stretch** (`pack_deskworker`), **Athletic Recovery** (`pack_athlete_recovery`), **Better Sleep & Breathing** (`pack_bettersleep`), **Runner's Warm-Up & Cooldown** (`pack_runner`), **Full Body Reset** (new — built from `GoalMeta.all`, not hand-typed, so its exercise names are guaranteed valid without needing to read `SeedData.json`).
- Tapping a premade routine **never** creates a `Routine` directly — it only supplies `initialExerciseIDs` + a suggested name to `RoutineBuilderView`. Saving only happens if the user hits Save there.
- `RoutineBuilderView`'s existing `initialExerciseIDs`/`onSaved` parameters and its `RoutineIDMerge`-based merge-on-appear behavior are untouched — this plan only adds one new optional parameter alongside them.
- `RoutineListView`'s `entryRow(title:systemImage:)` helper (left in place by Phase 1 specifically for this) gets exactly one new call site; no other change to that file's structure.
- Every `PremadeRoutine.exerciseNames` entry must exist in `SeedData.json` — covered by a new integrity test in `CuratedContentIntegrityTests.swift`, the same safety net the deleted `everyContentPackExerciseNameExistsInSeedCatalog` provided.

---

### Task 1: Add the PremadeRoutine model and its integrity test

**Files:**
- Create: `Breath - Relax & Stretch/Models/PremadeRoutine.swift`
- Modify: `Breath - Relax & StretchTests/CuratedContentIntegrityTests.swift`

**Interfaces:**
- Produces: `PremadeRoutine` (`Identifiable`, `id/title/summary/icon/exerciseNames`), `PremadeRoutine.all: [PremadeRoutine]`, and `func resolvedExercises(in exercises: [Exercise]) -> [Exercise]` — an instance method both later tasks' views call to resolve a template against the live catalog, so the name-matching logic (`Dictionary(grouping:by:).compactMapValues(\.first)`, same pattern `GoalMeta.recommend` and the deleted `GuidedProgramDetailView` used) lives in exactly one place.
- Consumes: `Exercise` (`.name`, `.uuid` — unchanged).

- [ ] **Step 1: Write the model**

```swift
import Foundation

// MARK: - PremadeRoutine
// Curated, single-session routine templates — free, like everything else in
// the app. Tapping one (in PremadeRoutinesView or TodayView's horizontal
// row) never creates a Routine by itself: it opens RoutineBuilderView
// pre-seeded with these exercises and this title, exactly like every other
// path into that screen (a picking session, editing an existing routine).
// Nothing is persisted until the user hits Save there.
//
// Exercise names are resolved against the live Exercise table at render
// time, same pattern GoalMeta and the deleted ContentPack used — see
// CuratedContentIntegrityTests for the safety net that keeps these names
// honest against SeedData.json.

struct PremadeRoutine: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let exerciseNames: [String]

    /// Resolves `exerciseNames` against the live catalog, in order,
    /// skipping any name that doesn't currently exist.
    func resolvedExercises(in exercises: [Exercise]) -> [Exercise] {
        let byName = Dictionary(grouping: exercises, by: \.name).compactMapValues(\.first)
        return exerciseNames.compactMap { byName[$0] }
    }

    static let all: [PremadeRoutine] = [
        PremadeRoutine(
            id: "pack_deskworker",
            title: "Office Stretch",
            summary: "Targeted relief for neck, shoulders, wrists, and lower back from sitting all day.",
            icon: "desktopcomputer",
            exerciseNames: [
                "Chin Tuck (Forward Head Reset)",
                "Seated Neck Rolls",
                "Shoulder Roll",
                "Reverse Prayer Stretch",
                "Wrist Circles",
                "Wrist & Forearm Release",
                "Left Wrist Flexor Stretch",
                "Right Wrist Flexor Stretch",
                "Left Cross-Body Rear Delt Stretch",
                "Right Cross-Body Rear Delt Stretch",
                "Left Overhead Triceps Stretch",
                "Right Overhead Triceps Stretch",
                "Left Seated Spinal Twist",
                "Right Seated Spinal Twist",
                "Left Standing Reach-Through Twist",
                "Right Standing Reach-Through Twist",
                "Doorway Shoulder & Chest Opener",
            ]
        ),
        PremadeRoutine(
            id: "pack_athlete_recovery",
            title: "Athletic Recovery",
            summary: "Deeper lower-body stretches and breathing for active recovery days.",
            icon: "figure.run",
            exerciseNames: [
                "Standing Hamstring Stretch",
                "Left Seated Hamstring Stretch",
                "Right Seated Hamstring Stretch",
                "Left Seated Figure-Four Stretch",
                "Right Seated Figure-Four Stretch",
                "Bridge Pose",
                "Pelvic Tilt",
                "Cat-Cow Flow",
                "4-7-8 Breathing",
                "Left Standing Quad Stretch",
                "Right Standing Quad Stretch",
                "Left Standing Figure-4 Stretch",
                "Right Standing Figure-4 Stretch",
                "Left Standing Hip-Flexor Stretch (Foot Elevated)",
                "Right Standing Hip-Flexor Stretch (Foot Elevated)",
                "Calf Stretch at Wall (Straight-Knee)",
                "Bent-Knee Wall Calf Stretch (Soleus)",
            ]
        ),
        PremadeRoutine(
            id: "pack_bettersleep",
            title: "Better Sleep & Breathing",
            summary: "Wind-down breathing techniques and gentle stretches to help you fall asleep faster.",
            icon: "moon.stars.fill",
            exerciseNames: [
                "Extended Exhale Breathing",
                "Counting Down Sleep Breath",
                "Cooling Sitali Breath",
                "Three-Part Breath (Dirga Pranayama)",
                "Body Scan Breathing",
                "Segmented Exhale Breathing (Viloma)",
                "Progressive Relaxation Breath",
                "Left-Nostril Calming Breath (Chandra Bhedana)",
                "Legs Up the Wall",
                "Child's Pose",
                "Cat-Cow Flow",
            ]
        ),
        PremadeRoutine(
            id: "pack_runner",
            title: "Runner's Warm-Up & Cooldown",
            summary: "Dynamic mobility to open up before a run, plus targeted stretches to cool down after.",
            icon: "figure.run.circle.fill",
            exerciseNames: [
                "Standing IT Band Side Stretch (Left)",
                "Standing IT Band Side Stretch (Right)",
                "Dynamic Standing Leg Swings",
                "Standing Hip Circles",
                "Runner's Lunge with Rotation (Left)",
                "Runner's Lunge with Rotation (Right)",
                "Standing Ankle Dorsiflexion Stretch (Left)",
                "Standing Ankle Dorsiflexion Stretch (Right)",
                "Runner's Calf Stretch (Staggered Stance)",
                "Ankle Alphabet",
                "Standing Hamstring Stretch",
                "Left Standing Quad Stretch",
                "Right Standing Quad Stretch",
            ]
        ),
        // Unlike the other four (hand-curated, verified against SeedData.json
        // when they were ContentPack entries), this one is built from
        // GoalMeta's pools at definition time rather than hand-typed — every
        // name it can produce is already covered by
        // everyGoalMetaExerciseNameExistsInSeedCatalog, so there's no new
        // hand-typed-name drift risk to introduce.
        {
            let pool = Array(Set(GoalMeta.all.flatMap(\.exerciseNames))).sorted()
            return PremadeRoutine(
                id: "premade_full_body_reset",
                title: "Full Body Reset",
                summary: "No particular theme — a balanced sweep across flexibility, breathing, and posture.",
                icon: "sparkles",
                exerciseNames: Array(pool.prefix(6))
            )
        }(),
    ]
}
```

- [ ] **Step 2: Add the integrity test**

In `Breath - Relax & StretchTests/CuratedContentIntegrityTests.swift`, add a new `@Test` method to the existing `CuratedContentIntegrityTests` struct (after `everyGoalMetaExerciseNameExistsInSeedCatalog`):

```swift
    @Test func everyPremadeRoutineExerciseNameExistsInSeedCatalog() throws {
        let seedNames = try seedExerciseNames()
        for routine in PremadeRoutine.all {
            for name in routine.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in \(routine.title) doesn't match any seed exercise")
            }
        }
    }
```

- [ ] **Step 3: Run the new test**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/CuratedContentIntegrityTests"`
Expected: both tests pass — `everyGoalMetaExerciseNameExistsInSeedCatalog` (unchanged) and the new `everyPremadeRoutineExerciseNameExistsInSeedCatalog`. If the new test fails, it names the exact exercise name and pack that doesn't match `SeedData.json` — fix the name in `PremadeRoutine.all` to match the catalog exactly (this exact failure mode is why the test exists; see the repo's prior `fix(content): repair 15+ broken exercise-name references in packs and goals` commit).

- [ ] **Step 4: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/PremadeRoutine.swift" "Breath - Relax & StretchTests/CuratedContentIntegrityTests.swift"
git commit -m "feat(routines): add PremadeRoutine model with integrity coverage"
```

---

### Task 2: Let RoutineBuilderView pre-fill a name without editing an existing routine

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `RoutineBuilderView.initialName: String?` (new optional init parameter, default `nil`) — Task 3 and Task 4's call sites both pass a `PremadeRoutine.title` here.

- [ ] **Step 1: Add the parameter**

```swift
    var routineToEdit: Routine? = nil
    /// Exercise IDs to fold in on appear — e.g. a set just picked in the
    /// Exercises tab's standalone picking mode (see
    /// `MiniRoutineReviewView`). Appended after `routineToEdit`'s existing
    /// exercises (or seeded fresh when creating), de-duped via
    /// `RoutineIDMerge` so a pick that's already in the routine isn't
    /// doubled.
    var initialExerciseIDs: [UUID] = []
```

becomes:

```swift
    var routineToEdit: Routine? = nil
    /// Exercise IDs to fold in on appear — e.g. a set just picked in the
    /// Exercises tab's standalone picking mode (see
    /// `MiniRoutineReviewView`). Appended after `routineToEdit`'s existing
    /// exercises (or seeded fresh when creating), de-duped via
    /// `RoutineIDMerge` so a pick that's already in the routine isn't
    /// doubled.
    var initialExerciseIDs: [UUID] = []
    /// Suggested name to pre-fill when creating a brand-new routine from a
    /// template (e.g. a tapped PremadeRoutine card) — nil for the normal
    /// create/edit flows, which leave the name field blank or pull it from
    /// `routineToEdit`. Never applied when `routineToEdit` is set — editing
    /// an existing routine always keeps its own name.
    var initialName: String? = nil
```

- [ ] **Step 2: Apply it in `onAppear`**

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                } else if !initialExerciseIDs.isEmpty {
                    selectedIDs = RoutineIDMerge.appending(initialExerciseIDs, to: selectedIDs)
                }
            }
```

becomes:

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                } else if !initialExerciseIDs.isEmpty || initialName != nil {
                    selectedIDs = RoutineIDMerge.appending(initialExerciseIDs, to: selectedIDs)
                    if let initialName {
                        routineName = initialName
                    }
                }
            }
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED` — the new parameter has a default, so every existing call site (`RoutineListView`, `MiniRoutineReviewView`) still compiles unchanged.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift"
git commit -m "feat(routines): let RoutineBuilderView pre-fill a name for new routines"
```

---

### Task 3: Add PremadeRoutinesView and its Routines-tab entry point

**Files:**
- Create: `Breath - Relax & Stretch/Views/Monetization/PremadeRoutinesView.swift`
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`

**Interfaces:**
- Consumes: `PremadeRoutine.all`, `PremadeRoutine.resolvedExercises(in:)` (Task 1), `RoutineBuilderView(initialExerciseIDs:initialName:)` (Task 2).
- Produces: `PremadeRoutinesView` — a plain `View`, no external state consumed beyond a `SwiftData` `Exercise` query.

- [ ] **Step 1: Write PremadeRoutinesView**

```swift
import SwiftUI
import SwiftData

// MARK: - PremadeRoutinesView
// Curated single-session routine templates. Tapping one opens
// RoutineBuilderView pre-seeded with the template's name and exercises —
// see PremadeRoutine's doc comment. Nothing is saved until the user hits
// Save there.

struct PremadeRoutinesView: View {
    @Query private var exercises: [Exercise]
    @State private var selectedRoutine: PremadeRoutine?

    var body: some View {
        List(PremadeRoutine.all) { routine in
            Button {
                selectedRoutine = routine
            } label: {
                PremadeRoutineRow(routine: routine, meta: meta(for: routine))
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .navigationTitle("Premade Routines")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
        .sheet(item: $selectedRoutine) { routine in
            RoutineBuilderView(
                initialExerciseIDs: routine.resolvedExercises(in: exercises).map(\.uuid),
                initialName: routine.title
            )
        }
    }

    private func meta(for routine: PremadeRoutine) -> String {
        let resolved = routine.resolvedExercises(in: exercises)
        guard !resolved.isEmpty else { return "Unavailable" }
        let totalSecs = resolved.reduce(0) { $0 + $1.durationSeconds }
        let mins = max(1, Int((Double(totalSecs) / 60).rounded()))
        return "\(resolved.count) exercise\(resolved.count == 1 ? "" : "s") · \(mins) min"
    }
}

private struct PremadeRoutineRow: View {
    let routine: PremadeRoutine
    let meta: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: routine.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 44, height: 44)
                .background(Color.luminaMintTint, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(routine.title)
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                Text(routine.summary)
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .lineLimit(2)
                Text(meta)
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }

            Spacer(minLength: 0)
        }
        .luminaCard(padding: 14)
    }
}

#Preview {
    NavigationStack {
        PremadeRoutinesView()
    }
    .modelContainer(for: [Exercise.self, Routine.self], inMemory: true)
}
```

- [ ] **Step 2: Wire the entry row back into RoutineListView**

```swift
    var body: some View {
        NavigationStack {
            List {
                ForEach(routines) { routine in
```

becomes:

```swift
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: PremadeRoutinesView()) {
                        entryRow(title: "Premade Routines", systemImage: "sparkles")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(routines) { routine in
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Monetization/PremadeRoutinesView.swift" "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift"
git commit -m "feat(routines): add PremadeRoutinesView and its Routines-tab entry point"
```

---

### Task 4: Add the Premade Routines row to Home

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`
- Modify: `Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift` (this file already holds every other Home card component — `ForYouCard`, `RecommendedCarousel`, `RecommendedCard` — despite its name; `PremadeRoutineCard` follows the same precedent rather than starting a new file)

**Interfaces:**
- Consumes: `PremadeRoutine.all`, `PremadeRoutine.resolvedExercises(in:)` (Task 1), `RoutineBuilderView(initialExerciseIDs:initialName:)` (Task 2).
- Produces: `PremadeRoutineCard` (a `View`, `ForYouSection.swift`-local like its siblings — not otherwise referenced).

- [ ] **Step 1: Add PremadeRoutineCard to ForYouSection.swift**

Insert after `ForYouCard`'s closing brace (i.e. right before the `// MARK: - Recommended carousel` comment):

```swift
// MARK: - Premade routine card

struct PremadeRoutineCard: View {
    let routine: PremadeRoutine
    let meta: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: routine.icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 40, height: 40)
                .background(Color.luminaMintTint, in: Circle())

            Text(routine.title)
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaOnSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(meta)
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        .padding(12)
        .frame(width: 132, alignment: .leading)
        .luminaCard(padding: 0)
    }
}
```

- [ ] **Step 2: Add the section to TodayView's body, between Recommended for You and For You**

```swift
                VStack(alignment: .leading, spacing: 24) {
                    greetingHeader
                    heroCard
                    recommendedSection
                    forYouSection
                }
```

becomes:

```swift
                VStack(alignment: .leading, spacing: 24) {
                    greetingHeader
                    heroCard
                    recommendedSection
                    premadeRoutinesSection
                    forYouSection
                }
```

- [ ] **Step 3: Add the state, the section body, and the sheet**

Add a new `@State` near the view's other sheet-related state (next to `showingCustomize`):

```swift
    @State private var showingCustomize = false
    @State private var pendingShowSessionAfterCustomize = false
```

becomes:

```swift
    @State private var showingCustomize = false
    @State private var pendingShowSessionAfterCustomize = false
    @State private var selectedPremadeRoutine: PremadeRoutine?
```

Add the section implementation right after `recommendedSection`'s closing brace (before `// MARK: - For You`):

```swift
    // MARK: - Premade Routines

    @ViewBuilder
    private var premadeRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premade Routines")
                .font(.luminaTitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(PremadeRoutine.all) { routine in
                        Button {
                            selectedPremadeRoutine = routine
                        } label: {
                            PremadeRoutineCard(routine: routine, meta: premadeMeta(for: routine))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func premadeMeta(for routine: PremadeRoutine) -> String {
        let resolved = routine.resolvedExercises(in: exercises)
        guard !resolved.isEmpty else { return "Unavailable" }
        let totalSecs = resolved.reduce(0) { $0 + $1.durationSeconds }
        let mins = max(1, Int((Double(totalSecs) / 60).rounded()))
        return "\(resolved.count) exercise\(resolved.count == 1 ? "" : "s") · \(mins) min"
    }
```

Add the sheet modifier alongside `TodayView`'s other `.sheet` modifiers:

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.consumeFinished() else { return }
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
        .alert(
            "Streak Lost",
```

becomes:

```swift
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.consumeFinished() else { return }
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
        .sheet(item: $selectedPremadeRoutine) { routine in
            RoutineBuilderView(
                initialExerciseIDs: routine.resolvedExercises(in: exercises).map(\.uuid),
                initialName: routine.title
            )
        }
        .alert(
            "Streak Lost",
```

- [ ] **Step 4: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: `** TEST SUCCEEDED **`, no failures.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift" "Breath - Relax & Stretch/Views/Exercises/ForYouSection.swift"
git commit -m "feat(home): add Premade Routines row between Recommended and For You"
```

---

## Plan complete

At this point: `PremadeRoutinesView` is reachable from the Routines tab's top entry row, a matching horizontal card row sits on Home between "Recommended for You" and "For You," and tapping any premade routine in either place opens the normal routine builder pre-filled with that template's name and exercises — editable, and unsaved until the user hits Save. This is Phase 3 of 4; Phase 4 (RoutineBuilder's cross-tab "Add Exercise" + the per-exercise duration stepper) has its own plan.
