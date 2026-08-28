# Today Pin Generalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Wake-Up-only pin with a single "Today" pin that overrides `TodayView`'s session at any time of day, saved as a `Routine` literally named "Today."

**Architecture:** `TodayView.sessionExercises` currently checks the pinned routine only inside its `.wakeUp` switch branch. This plan hoists that check above the switch so it applies unconditionally, renames the backing `AppStorage` key (with a one-time migration from the old key), fixes the saved routine's name to the literal string `"Today"` instead of the time-of-day-dependent `heroTitle`, and adds a small "Pinned as Today" tag to the hero card so the state is visible without opening Customize. `CustomizeRoutineView`'s toggle label becomes a fixed string for the same reason. This is Phase 2 of 4 from the routines-tab-redesign spec; Phase 1 (public-routine/content-pack cleanup) is already implemented and merged.

**Tech Stack:** SwiftUI, `@AppStorage`, SwiftData (`Routine` model — already reduced to `uuid/name/exerciseIDs/borrowedFromID/createdAt` by Phase 1). No new tests exist for this behavior today (`CustomizeRoutineViewRenderingTests` only checks that the view renders without crashing, regardless of the toggle's label text) — verification is build + a manual rendering check.

**Spec:** `docs/superpowers/specs/2026-08-16-routines-tab-redesign-design.md` (section "TodayView — hero + pin")

## Global Constraints

- `AppStorage` key: `pinnedWakeUpRoutineID` → `pinnedTodayRoutineID`. Existing users' pins must survive: migrate the old key's value into the new one, once, without deleting the old key.
- The pinned routine now overrides `sessionExercises` in **all** `timeOfDayFocus` cases (`.wakeUp`, `.unwind`, `.none`), not just `.wakeUp`.
- The saved/updated pinned `Routine`'s `name` is always the literal string `"Today"` — never `timeOfDayFocus.heroTitle`.
- `CustomizeRoutineView`'s "Keep as my ... routine" toggle row reads exactly **"Keep as my Today routine"**, unconditionally — not templated on `title` anymore.
- Do not change `CustomizeRoutineView`'s `title` parameter or `navigationTitle` — that stays the dynamic "Wake Up"/"Unwind"/"Today's session" hero title; only the toggle row's label is fixed.

---

### Task 1: Generalize the pin in TodayView and CustomizeRoutineView

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift`
- Modify: `Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift`

**Interfaces:**
- Consumes: `Routine` (uuid/name/exerciseIDs/borrowedFromID/createdAt — Phase 1's shape), `RoutineIDMerge` (unrelated, not touched).
- Produces: `TodayView.isPinnedActive: Bool` — a new computed property later phases (or a future Home redesign) can read if they need to know "is the hero showing the pinned routine."

- [ ] **Step 1: Rename the AppStorage key and add a one-time migration**

```swift
    @AppStorage("pinnedWakeUpRoutineID") private var pinnedWakeUpRoutineIDString = ""
```

becomes:

```swift
    @AppStorage("pinnedTodayRoutineID") private var pinnedTodayRoutineIDString = ""
```

In `.onAppear` (the existing one near the bottom of `body`), add the migration as its first statement:

```swift
        .onAppear {
            if !reduceMotion { isBreathingIn = true }
            if let profile {
```

becomes:

```swift
        .onAppear {
            // One-time migration: the pin used to be scoped to Wake Up hours
            // only, under this key. Carry an existing pin forward under the
            // new key rather than silently dropping it for upgrading users.
            // The old key is left in place (unused) rather than deleted —
            // there's no reader left for it either way.
            if pinnedTodayRoutineIDString.isEmpty,
               let legacy = UserDefaults.standard.string(forKey: "pinnedWakeUpRoutineID"),
               !legacy.isEmpty {
                pinnedTodayRoutineIDString = legacy
            }
            if !reduceMotion { isBreathingIn = true }
            if let profile {
```

- [ ] **Step 2: Rename and generalize `pinnedSessionExercises`' doc comment (behavior is unchanged — it already returns `nil` if nothing usable is pinned)**

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

becomes:

```swift
    /// The saved "Today" routine the user pinned via Customize ("Keep as my
    /// Today routine"), if any is set and it still resolves to at least one
    /// real exercise. Checked before any time-of-day-based recommendation.
    private var pinnedSessionExercises: [Exercise]? {
        guard let pinnedID = UUID(uuidString: pinnedTodayRoutineIDString),
              let routine = routines.first(where: { $0.uuid == pinnedID }) else {
            return nil
        }
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        let resolved = routine.exerciseIDs.compactMap { byID[$0] }
        return resolved.isEmpty ? nil : resolved
    }

    /// Whether the hero card is currently showing the pinned "Today"
    /// routine rather than a time-of-day/goal-based recommendation — drives
    /// the "Pinned as Today" tag next to the hero title.
    private var isPinnedActive: Bool {
        pinnedSessionExercises != nil
    }
```

- [ ] **Step 3: Hoist the pin check above the time-of-day switch in `sessionExercises`**

```swift
    /// Today's session: goal-based recommendations, falling back to the first
    /// few catalog exercises when no goals were picked during onboarding.
    ///
    /// The pinned routine only activates during Wake Up hours — it's named
    /// after the AppStorage key (`pinnedWakeUpRoutineID`) and the hero's
    /// literal "Wake Up" wording. Pinning from Unwind or the midday
    /// fallback state must not leak into the other time-of-day sessions.
    private var sessionExercises: [Exercise] {
        switch timeOfDayFocus {
        case .wakeUp:
            if let pinnedSessionExercises {
                return pinnedSessionExercises
            }
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["wake_up"], limit: 4)
            if !pool.isEmpty { return pool }
        case .unwind:
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["unwind"], limit: 4)
            if !pool.isEmpty { return pool }
        case .none:
            break
        }
        let recommended = GoalMeta.recommend(from: exercises, activeGoalIDs: activeGoalIDs, limit: 4)
        return recommended.isEmpty ? Array(exercises.prefix(4)) : recommended
    }
```

becomes:

```swift
    /// Today's session: the pinned "Today" routine if one is set, else
    /// goal-based recommendations, falling back to the first few catalog
    /// exercises when no goals were picked during onboarding.
    ///
    /// The pin now applies regardless of time of day — a single "Today"
    /// routine, not one scoped to Wake Up hours.
    private var sessionExercises: [Exercise] {
        if let pinnedSessionExercises {
            return pinnedSessionExercises
        }
        switch timeOfDayFocus {
        case .wakeUp:
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["wake_up"], limit: 4)
            if !pool.isEmpty { return pool }
        case .unwind:
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["unwind"], limit: 4)
            if !pool.isEmpty { return pool }
        case .none:
            break
        }
        let recommended = GoalMeta.recommend(from: exercises, activeGoalIDs: activeGoalIDs, limit: 4)
        return recommended.isEmpty ? Array(exercises.prefix(4)) : recommended
    }
```

- [ ] **Step 4: Fix the `isPinned:` argument passed to `CustomizeRoutineView` and the save/unpin logic in its `onDone`**

```swift
            CustomizeRoutineView(
                title: customizeOverride?.title ?? timeOfDayFocus.heroTitle,
                exercises: customizeOverride?.exercises ?? sessionExercises,
                isPinned: customizeOverride?.isPinned ?? (timeOfDayFocus == .wakeUp && pinnedSessionExercises != nil),
                onDone: { exercises, pinned in
                    customizeOverride = nil
                    if pinned {
                        if let existingID = UUID(uuidString: pinnedWakeUpRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            // Update the already-pinned routine in place rather
                            // than inserting a duplicate every time the user
                            // re-pins from Customize.
                            existing.exerciseIDs = exercises.map(\.uuid)
                            existing.name = timeOfDayFocus.heroTitle
                        } else {
                            let routine = Routine(name: timeOfDayFocus.heroTitle, exerciseIDs: exercises.map(\.uuid))
                            modelContext.insert(routine)
                            pinnedWakeUpRoutineIDString = routine.uuid.uuidString
                        }
                        try? modelContext.save()
                    } else {
                        // Delete the underlying Routine on unpin, not just the
                        // AppStorage pointer to it — otherwise it survives as
                        // an orphan in the CloudKit-synced store, and the next
                        // re-pin (with the ID already cleared) would insert a
                        // brand-new duplicate instead of ever finding it again.
                        if let existingID = UUID(uuidString: pinnedWakeUpRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            modelContext.delete(existing)
                            try? modelContext.save()
                        }
                        pinnedWakeUpRoutineIDString = ""
                    }
                    pendingShowSessionAfterCustomize = true
                }
            )
```

becomes:

```swift
            CustomizeRoutineView(
                title: customizeOverride?.title ?? timeOfDayFocus.heroTitle,
                exercises: customizeOverride?.exercises ?? sessionExercises,
                isPinned: customizeOverride?.isPinned ?? isPinnedActive,
                onDone: { exercises, pinned in
                    customizeOverride = nil
                    if pinned {
                        if let existingID = UUID(uuidString: pinnedTodayRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            // Update the already-pinned routine in place rather
                            // than inserting a duplicate every time the user
                            // re-pins from Customize.
                            existing.exerciseIDs = exercises.map(\.uuid)
                            existing.name = "Today"
                        } else {
                            let routine = Routine(name: "Today", exerciseIDs: exercises.map(\.uuid))
                            modelContext.insert(routine)
                            pinnedTodayRoutineIDString = routine.uuid.uuidString
                        }
                        try? modelContext.save()
                    } else {
                        // Delete the underlying Routine on unpin, not just the
                        // AppStorage pointer to it — otherwise it survives as
                        // an orphan in the CloudKit-synced store, and the next
                        // re-pin (with the ID already cleared) would insert a
                        // brand-new duplicate instead of ever finding it again.
                        if let existingID = UUID(uuidString: pinnedTodayRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            modelContext.delete(existing)
                            try? modelContext.save()
                        }
                        pinnedTodayRoutineIDString = ""
                    }
                    pendingShowSessionAfterCustomize = true
                }
            )
```

- [ ] **Step 5: Add the "Pinned as Today" tag to the hero card**

```swift
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayFocus.heroTitle)
                        .font(.luminaTitle)
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.luminaSubheadline)
                        .opacity(0.85)
                }
```

becomes:

```swift
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(timeOfDayFocus.heroTitle)
                            .font(.luminaTitle)
                        if isPinnedActive {
                            Label("Pinned as Today", systemImage: "bookmark.fill")
                                .font(.luminaCaption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.22), in: Capsule())
                        }
                    }
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.luminaSubheadline)
                        .opacity(0.85)
                }
```

- [ ] **Step 6: Fix the toggle row label in `CustomizeRoutineView.swift`**

```swift
            VStack(alignment: .leading, spacing: 1) {
                Text("Keep as my \(title) routine")
                    .font(.luminaCardTitle)
                Text("Starts your day automatically · off = just for today")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
```

becomes:

```swift
            VStack(alignment: .leading, spacing: 1) {
                Text("Keep as my Today routine")
                    .font(.luminaCardTitle)
                Text("Starts your day automatically · off = just for today")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
```

- [ ] **Step 7: Build**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 8: Run the existing CustomizeRoutineView rendering tests**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/CustomizeRoutineViewRenderingTests"`
Expected: all 3 cases (`rendersWithExercises`, `rendersWithPinnedStateOn`, `rendersWithNoExercises`) pass — they only assert the view renders to an image without crashing, not the toggle's label text, so the fixed string change doesn't need a test update.

- [ ] **Step 9: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: `** TEST SUCCEEDED **`, no failures — nothing in the existing suite references `pinnedWakeUpRoutineID`, `sessionExercises`, or `timeOfDayFocus` directly (confirmed via repo-wide grep during planning), so no other test should be affected.

- [ ] **Step 10: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Home/TodayView.swift" "Breath - Relax & Stretch/Views/Home/CustomizeRoutineView.swift"
git commit -m "feat(home): generalize the Wake-Up pin into a universal Today pin"
```

---

## Plan complete

At this point: pinning from Customize works and persists identically regardless of time of day, the saved routine is always named "Today" and shows up as a normal row in the Routines tab, the hero card visibly indicates when it's showing the pinned routine, and existing users' Wake-Up-hours pins carry forward under the new key on first launch after upgrade. This is Phase 2 of 4; Phase 3 (Premade Routines) has its own plan.
