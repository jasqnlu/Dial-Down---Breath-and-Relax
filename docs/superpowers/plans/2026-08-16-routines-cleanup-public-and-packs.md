# Routines Cleanup: Public Routines + Content Packs/Guided Programs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete the public/community routine feature (publish, browse, borrow) and the Content Packs / multi-day Guided Programs feature, with nothing left referencing the removed `Routine` fields or the deleted views/models.

**Architecture:** Pure deletion/refactor — no new behavior, no new screens. This is Phase 1 of 4 from the routines-tab-redesign spec (see below); it unblocks the later phases by clearing the `Routine` model and `RoutineListView` of the code the community feature and the old programs screens occupied. Because there's no new logic to drive with a failing test first, each task's verification step is: make the edit, then build (or run the relevant test target) to confirm the project still compiles and existing tests still pass. Tasks are ordered so every commit leaves the project in a compiling state — consumers of a soon-to-be-removed field are cleared out before the field itself is removed.

**Tech Stack:** Swift 6, SwiftUI, SwiftData (no `VersionedSchema`/`SchemaMigrationPlan` exists in this project — a single `Schema([...])` + `ModelConfiguration` in `Breath__Relax___StretchApp.swift`, relying on SwiftData's automatic lightweight migration). Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest.

**Spec:** `docs/superpowers/specs/2026-08-16-routines-tab-redesign-design.md` (sections: "Data model changes" → `Routine`; "Remove: public/community routines"; `PremadeRoutine` intro in the same section as the deleted `GuidedProgram`/`ContentPack`)

## Global Constraints

- Remove from `Routine`: `isPublic`, `borrowCount`, `authorID`, `authorName`. **Keep** `borrowedFromID` — it marks a routine imported via the private share link (`RoutineSharePayload`/`ImportRoutineView`), which is unrelated to the public library and stays untouched.
- Delete entirely: `BorrowRoutineView.swift`, `ContentPacksView.swift`, `GuidedProgramsView.swift`, `GuidedProgramDetailView.swift`, `ContentPack.swift`, `GuidedProgram.swift`.
- Do not touch `RoutineSharePayload.swift`, `ImportRoutineView.swift`, or the `ShareLink` row action in `RoutineListView` — private sharing is explicitly out of scope for removal.
- No `SchemaMigrationPlan`/`VersionedSchema` code is needed for the `Routine` field removal — SwiftData's lightweight migration handles it automatically given the existing inline-default pattern (`var isPublic: Bool = false`, etc.) already used for CloudKit compatibility.
- Test command: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"` (≈40s, builds the whole app first).

---

### Task 1: Delete BorrowRoutineView and its entry point

**Files:**
- Delete: `Breath - Relax & Stretch/Views/Routines/BorrowRoutineView.swift`
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `RoutineListView` with no Browse entry point and no "Public"/borrow-count row labels. Later tasks (2, 5) still reference `RoutineListView`'s `RoutineRow`/`entryRow` helpers, unaffected by this task.

- [ ] **Step 1: Delete the file**

```bash
rm "Breath - Relax & Stretch/Views/Routines/BorrowRoutineView.swift"
```

- [ ] **Step 2: Remove the Browse state, toolbar button, and sheet from `RoutineListView.swift`**

Remove the `showingBrowser` state:

```swift
    @State private var showingBuilder  = false
    @State private var showingBrowser  = false
    @State private var routineToPlay: Routine?
```

becomes:

```swift
    @State private var showingBuilder  = false
    @State private var routineToPlay: Routine?
```

Remove the Browse toolbar item (the whole conditional block, including its comment):

```swift
                // Community browsing needs the backend; hide the entry point
                // rather than showing a screen that can't load.
                if SupabaseService.isConfigured {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showingBrowser = true } label: {
                            Label("Browse", systemImage: "globe")
                        }
                    }
                }
            }
```

becomes:

```swift
            }
```

(i.e. delete everything from the `// Community browsing` comment through the closing `}` of the `if SupabaseService.isConfigured` block, leaving the `.toolbar { ... }` modifier's own closing brace as the next line.)

Remove the Browse sheet:

```swift
            .sheet(isPresented: $showingBrowser) {
                BorrowRoutineView()
                    .environmentObject(AuthManager.shared)
            }
```

Simplify the empty-state description (it no longer needs to branch on backend availability, since there's nothing left to browse either way):

```swift
                    } description: {
                        Text(SupabaseService.isConfigured
                            ? "Create your own or borrow one from the library."
                            : "Create your own routine from your favorite exercises.")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
```

becomes:

```swift
                    } description: {
                        Text("Create your own routine from your favorite exercises.")
                            .font(.luminaBody)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
```

- [ ] **Step 3: Remove the "Public" and borrow-count labels from `RoutineRow`**

```swift
                HStack(spacing: 12) {
                    Label("\(resolvedCount) exercise\(resolvedCount == 1 ? "" : "s")",
                          systemImage: "list.number")
                    if routine.isPublic {
                        Label("Public", systemImage: "globe")
                            .foregroundStyle(.blue)
                    }
                    if routine.borrowCount > 0 {
                        Label("\(routine.borrowCount)", systemImage: "arrow.triangle.branch")
                            .foregroundStyle(.secondary)
                    }
                }
```

becomes:

```swift
                HStack(spacing: 12) {
                    Label("\(resolvedCount) exercise\(resolvedCount == 1 ? "" : "s")",
                          systemImage: "list.number")
                }
```

- [ ] **Step 4: Build and confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`. (`Routine.isPublic`/`borrowCount` still exist on the model at this point — Task 5 removes them — so this compiles even though nothing reads them from `RoutineListView` anymore.)

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift"
git rm "Breath - Relax & Stretch/Views/Routines/BorrowRoutineView.swift"
git commit -m "refactor(routines): delete BorrowRoutineView and its entry point"
```

---

### Task 2: Remove publish-to-community UI from RoutineBuilderView

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `RoutineBuilderView.saveRoutine()` that no longer passes `authorID`/`authorName`/`isPublic` to `Routine.init` — relies on the model's own defaults until Task 5 removes those parameters from the initializer entirely.

- [ ] **Step 1: Remove the now-unused `@Query`/`@EnvironmentObject` and publish-limit state**

```swift
    @Query private var exercises: [Exercise]
    @Query private var allRoutines: [Routine]

    var routineToEdit: Routine? = nil
```

becomes:

```swift
    @Query private var exercises: [Exercise]

    var routineToEdit: Routine? = nil
```

```swift
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var auth: AuthManager

    @Query private var exercises: [Exercise]
```

becomes:

```swift
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var exercises: [Exercise]
```

```swift
    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var isPublic = false
    @State private var showingExercisePicker = false
    @State private var indexPendingRemoval: Int?

    private let maxPublicRoutines = 3

    private var isEditing: Bool { routineToEdit != nil }

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + $1.durationSeconds }
    }

    private var myPublicCount: Int {
        allRoutines.filter { $0.isPublic && $0.authorID == auth.backendID && $0.uuid != routineToEdit?.uuid }.count
    }

    private var publishLimitReached: Bool {
        myPublicCount >= maxPublicRoutines
    }
```

becomes:

```swift
    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var showingExercisePicker = false
    @State private var indexPendingRemoval: Int?

    private var isEditing: Bool { routineToEdit != nil }

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + $1.durationSeconds }
    }
```

- [ ] **Step 2: Remove the "Publish to Community" `Section`**

```swift
                Section {
                    Toggle("Publish to Community", isOn: $isPublic)
                        .font(.luminaBody)
                        .tint(Color.luminaPrimary)
                        .disabled(!isPublic && publishLimitReached)
                } footer: {
                    if isPublic {
                        Text("Your routine will appear in the community library. You've used \(myPublicCount) of \(maxPublicRoutines) publish slots.")
                            .font(.luminaCaption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    } else if publishLimitReached {
                        Text("You've reached the \(maxPublicRoutines)-routine publish limit. Un-publish an existing routine to free a slot.")
                            .font(.luminaCaption)
                            .foregroundStyle(.red)
                    } else {
                        let remaining = maxPublicRoutines - myPublicCount
                        Text("Share this routine with the community (\(remaining) publish slot\(remaining == 1 ? "" : "s") remaining).")
                            .font(.luminaCaption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
                }
            }
            .scrollContentBackground(.hidden)
```

becomes:

```swift
            }
            .scrollContentBackground(.hidden)
```

(i.e. the `Form`'s last `Section` is now the "Exercises" section — delete the whole "Publish to Community" `Section` block that followed it.)

- [ ] **Step 3: Stop reading `isPublic` in `onAppear`**

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                    isPublic     = r.isPublic
                } else if !initialExerciseIDs.isEmpty {
```

becomes:

```swift
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = RoutineIDMerge.appending(initialExerciseIDs, to: r.exerciseIDs)
                } else if !initialExerciseIDs.isEmpty {
```

- [ ] **Step 4: Stop writing `isPublic`/`authorID`/`authorName` in `saveRoutine()`**

```swift
    private func saveRoutine() {
        if let r = routineToEdit {
            r.name        = routineName
            r.exerciseIDs = selectedIDs
            r.isPublic    = isPublic
            r.authorName  = isPublic ? auth.displayName : nil
        } else {
            let routine = Routine(
                name: routineName,
                exerciseIDs: selectedIDs,
                authorID: auth.backendID,
                authorName: isPublic ? auth.displayName : nil,
                isPublic: isPublic
            )
            modelContext.insert(routine)
```

becomes:

```swift
    private func saveRoutine() {
        if let r = routineToEdit {
            r.name        = routineName
            r.exerciseIDs = selectedIDs
        } else {
            let routine = Routine(
                name: routineName,
                exerciseIDs: selectedIDs
            )
            modelContext.insert(routine)
```

- [ ] **Step 5: Build and confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineBuilderView.swift"
git commit -m "refactor(routines): remove publish-to-community UI from RoutineBuilderView"
```

---

### Task 3: Remove the dead public-routines network layer

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SupabaseService.swift`
- Modify: `Breath - Relax & Stretch/Services/SupabaseDTOs.swift`

**Interfaces:**
- Consumes: nothing (this task removes code with no remaining callers — `fetchPublicRoutines()`/`RemoteRoutine` were already unused before this plan, per repo-wide grep).
- Produces: nothing new; `RemoteRoutine` and `SupabaseService.fetchPublicRoutines()` no longer exist.

- [ ] **Step 1: Remove `fetchPublicRoutines()` from `SupabaseService.swift`**

```swift
    // MARK: - Public Routines

    /// Fetches all routines marked is_public = true.
    func fetchPublicRoutines() async throws -> [RemoteRoutine] {
        let data = try await get(path: "/rest/v1/routines?select=*&is_public=eq.true&order=name")
        return try JSONDecoder().decode([RemoteRoutine].self, from: data)
    }

    // Note: the write-side counterpart of this fetch (uploadRoutine) was
    // removed as dead code — nothing in the app called it. See
    // supabase_schema.sql for the matching RLS policy removal.

    // MARK: - Community (leaderboard / public profile)
```

becomes:

```swift
    // MARK: - Community (leaderboard / public profile)
```

- [ ] **Step 2: Remove the `RemoteRoutine` struct from `SupabaseDTOs.swift`**

```swift
struct RemoteRoutine: Codable, Sendable {
    let id: String
    let name: String
    let exerciseIDs: [String]
    let authorID: String?
    let authorName: String?      // display name at publish time; nil on legacy records
    let borrowedFromID: String?
    let isPublic: Bool
    let borrowCount: Int?        // nil on legacy records — treat as 0

    enum CodingKeys: String, CodingKey {
        case id, name
        case exerciseIDs    = "exercise_ids"
        case authorID       = "author_id"
        case authorName     = "author_name"
        case borrowedFromID = "borrowed_from_id"
        case isPublic       = "is_public"
        case borrowCount    = "borrow_count"
    }
}

struct RemoteProfile: Codable, Sendable, Identifiable {
```

becomes:

```swift
struct RemoteProfile: Codable, Sendable, Identifiable {
```

- [ ] **Step 3: Build and confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SupabaseService.swift" "Breath - Relax & Stretch/Services/SupabaseDTOs.swift"
git commit -m "refactor(routines): remove dead public-routines network layer"
```

---

### Task 4: Drop public-routine columns from the data export

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Profile/DataExportView.swift`

**Interfaces:**
- Consumes: `Routine.borrowedFromID` (stays on the model — see Task 5).
- Produces: `RoutineExportRow` with fields `id, name, exerciseIDs, borrowedFromID, createdAt` only — later tasks don't depend on this row's shape.

- [ ] **Step 1: Shrink the `RoutineExportRow` snapshot struct**

```swift
private struct RoutineExportRow: Sendable {
    let id:             String
    let name:           String
    let exerciseIDs:    [String]
    let authorID:       String?
    let authorName:     String?
    let borrowedFromID: String?
    let isPublic:       Bool
    let borrowCount:    Int
    let createdAt:      Date

    init(_ r: Routine) {
        id             = r.uuid.uuidString
        name           = r.name
        exerciseIDs    = r.exerciseIDs.map { $0.uuidString }
        authorID       = r.authorID
        authorName     = r.authorName
        borrowedFromID = r.borrowedFromID?.uuidString
        isPublic       = r.isPublic
        borrowCount    = r.borrowCount
        createdAt      = r.createdAt
    }
}
```

becomes:

```swift
private struct RoutineExportRow: Sendable {
    let id:             String
    let name:           String
    let exerciseIDs:    [String]
    let borrowedFromID: String?
    let createdAt:      Date

    init(_ r: Routine) {
        id             = r.uuid.uuidString
        name           = r.name
        exerciseIDs    = r.exerciseIDs.map { $0.uuidString }
        borrowedFromID = r.borrowedFromID?.uuidString
        createdAt      = r.createdAt
    }
}
```

- [ ] **Step 2: Update the CSV routines block in `makeCSV`**

```swift
        lines.append("")
        lines.append("# Routines")
        lines.append("id,name,exerciseIDs,authorID,authorName,borrowedFromID,isPublic,borrowCount,createdAt")
        for r in routineRows {
            lines.append([
                r.id,
                csvField(r.name),
                r.exerciseIDs.joined(separator: ";"),
                r.authorID ?? "",
                csvField(r.authorName ?? ""),
                r.borrowedFromID ?? "",
                "\(r.isPublic)",
                "\(r.borrowCount)",
                iso.string(from: r.createdAt)
            ].joined(separator: ","))
        }
```

becomes:

```swift
        lines.append("")
        lines.append("# Routines")
        lines.append("id,name,exerciseIDs,borrowedFromID,createdAt")
        for r in routineRows {
            lines.append([
                r.id,
                csvField(r.name),
                r.exerciseIDs.joined(separator: ";"),
                r.borrowedFromID ?? "",
                iso.string(from: r.createdAt)
            ].joined(separator: ","))
        }
```

- [ ] **Step 3: Update the JSON routines block in `makeJSON`**

```swift
        let routinesArr: [[String: Any]] = routineRows.map { r in
            var d: [String: Any] = [
                "id":           r.id,
                "name":         r.name,
                "exerciseIDs":  r.exerciseIDs,
                "isPublic":     r.isPublic,
                "borrowCount":  r.borrowCount,
                "createdAt":    iso.string(from: r.createdAt)
            ]
            if let a = r.authorID { d["authorID"] = a }
            if let n = r.authorName { d["authorName"] = n }
            if let b = r.borrowedFromID { d["borrowedFromID"] = b }
            return d
        }
```

becomes:

```swift
        let routinesArr: [[String: Any]] = routineRows.map { r in
            var d: [String: Any] = [
                "id":           r.id,
                "name":         r.name,
                "exerciseIDs":  r.exerciseIDs,
                "createdAt":    iso.string(from: r.createdAt)
            ]
            if let b = r.borrowedFromID { d["borrowedFromID"] = b }
            return d
        }
```

- [ ] **Step 4: Build and confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`. (No dedicated export test file exists in the repo today — `csvField` is the only export helper under direct test, in `SharePayloadTests`, and its signature is unchanged.)

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Profile/DataExportView.swift"
git commit -m "refactor(routines): drop public-routine columns from data export"
```

---

### Task 5: Remove isPublic/borrowCount/authorID/authorName from the Routine model

**Files:**
- Modify: `Breath - Relax & Stretch/Models/Routine.swift`
- Modify: `Breath - Relax & Stretch/Views/PreviewCatalog.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `Routine.init(uuid:name:exerciseIDs:borrowedFromID:)` — the shape every later task (and Phases 2-4 of the spec) builds on. `exerciseDurationOverrides` is **not** added in this task; that's Phase 4's job per the spec's sequencing.

- [ ] **Step 1: Shrink the `@Model` and its initializer**

```swift
@Model
final class Routine {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var exerciseIDs: [UUID] = []
    var authorID: String? = nil
    var authorName: String? = nil
    var borrowedFromID: UUID? = nil
    var isPublic: Bool = false
    var borrowCount: Int = 0
    var createdAt: Date = Date()

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        authorID: String? = nil,
        authorName: String? = nil,
        borrowedFromID: UUID? = nil,
        isPublic: Bool = false,
        borrowCount: Int = 0
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.authorID = authorID
        self.authorName = authorName
        self.borrowedFromID = borrowedFromID
        self.isPublic = isPublic
        self.borrowCount = borrowCount
        self.createdAt = Date()
    }
}
```

becomes:

```swift
@Model
final class Routine {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var exerciseIDs: [UUID] = []
    var borrowedFromID: UUID? = nil
    var createdAt: Date = Date()

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        borrowedFromID: UUID? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.borrowedFromID = borrowedFromID
        self.createdAt = Date()
    }
}
```

- [ ] **Step 2: Fix the last remaining call site passing the removed `isPublic` argument**

```swift
private func sampleRoutine() -> Routine {
    Routine(name: "Morning Wake-Up", exerciseIDs: [], isPublic: false)
}
```

becomes:

```swift
private func sampleRoutine() -> Routine {
    Routine(name: "Morning Wake-Up", exerciseIDs: [])
}
```

- [ ] **Step 3: Build and confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`. This is the task most likely to surface a missed call site — if it fails, the error names the file/line still passing a removed argument.

- [ ] **Step 4: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: all tests pass except `CuratedContentIntegrityTests`'s content-pack/guided-program cases, which are still present until Task 7 and are already known-failing on `main` from unrelated data drift (see the "Testing Setup" project memory) — not a regression from this task.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/Routine.swift" "Breath - Relax & Stretch/Views/PreviewCatalog.swift"
git commit -m "refactor(routines): remove isPublic/borrowCount/authorID/authorName from Routine"
```

---

### Task 6: Delete Content Packs and Guided Programs

**Files:**
- Delete: `Breath - Relax & Stretch/Views/Monetization/ContentPacksView.swift`
- Delete: `Breath - Relax & Stretch/Views/Monetization/GuidedProgramsView.swift`
- Delete: `Breath - Relax & Stretch/Views/Monetization/GuidedProgramDetailView.swift`
- Delete: `Breath - Relax & Stretch/Models/ContentPack.swift`
- Delete: `Breath - Relax & Stretch/Models/GuidedProgram.swift`
- Modify: `Breath - Relax & Stretch/Views/Routines/RoutineListView.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `RoutineListView` with no top entry-row section (no live entry point into premade content until Phase 3 adds `PremadeRoutinesView` and a new call to the still-present `entryRow(title:systemImage:)` helper — intentionally left in place rather than deleted here, since Phase 3 reuses it as-is).

- [ ] **Step 1: Delete the five files**

```bash
rm "Breath - Relax & Stretch/Views/Monetization/ContentPacksView.swift"
rm "Breath - Relax & Stretch/Views/Monetization/GuidedProgramsView.swift"
rm "Breath - Relax & Stretch/Views/Monetization/GuidedProgramDetailView.swift"
rm "Breath - Relax & Stretch/Models/ContentPack.swift"
rm "Breath - Relax & Stretch/Models/GuidedProgram.swift"
```

- [ ] **Step 2: Remove the top entry-row `Section` from `RoutineListView.swift`**

```swift
            List {
                Section {
                    NavigationLink(destination: GuidedProgramsView()) {
                        entryRow(title: "Guided Programs", systemImage: "calendar.badge.clock")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    NavigationLink(destination: ContentPacksView()) {
                        entryRow(title: "Content Packs", systemImage: "shippingbox.fill")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(routines) { routine in
```

becomes:

```swift
            List {
                ForEach(routines) { routine in
```

- [ ] **Step 3: Build and confirm it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: `BUILD SUCCEEDED`. If it fails on an unresolved `ContentPack`/`GuidedProgram` reference, that reference is handled in Task 7 next — check the error is scoped to `CuratedContentIntegrityTests.swift` before treating it as a miss.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Routines/RoutineListView.swift"
git rm "Breath - Relax & Stretch/Views/Monetization/ContentPacksView.swift" \
       "Breath - Relax & Stretch/Views/Monetization/GuidedProgramsView.swift" \
       "Breath - Relax & Stretch/Views/Monetization/GuidedProgramDetailView.swift" \
       "Breath - Relax & Stretch/Models/ContentPack.swift" \
       "Breath - Relax & Stretch/Models/GuidedProgram.swift"
git commit -m "refactor(routines): delete Content Packs and Guided Programs"
```

---

### Task 7: Update CuratedContentIntegrityTests for the deleted content types

**Files:**
- Modify: `Breath - Relax & StretchTests/CuratedContentIntegrityTests.swift`

**Interfaces:**
- Consumes: `GoalMeta.all` (unchanged, not part of this spec).
- Produces: `CuratedContentIntegrityTests` with only `everyGoalMetaExerciseNameExistsInSeedCatalog` remaining.

- [ ] **Step 1: Replace the whole file**

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

// GoalMeta references exercises by display-name string matched against
// SeedData.json at render time, not by a compiler-checked reference. This
// test keeps that mapping honest rather than relying on manual review.
struct CuratedContentIntegrityTests {

    private func seedExerciseNames() throws -> Set<String> {
        let url = try #require(Bundle(for: BundleToken.self)
            .url(forResource: "SeedData", withExtension: "json")
            ?? Bundle.main.url(forResource: "SeedData", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let exercises = try #require(json["exercises"] as? [[String: Any]])
        return Set(exercises.compactMap { $0["name"] as? String })
    }

    @Test func everyGoalMetaExerciseNameExistsInSeedCatalog() throws {
        let seedNames = try seedExerciseNames()
        for goal in GoalMeta.all {
            for name in goal.exerciseNames {
                #expect(seedNames.contains(name), "\"\(name)\" in goal \(goal.id) doesn't match any seed exercise")
            }
        }
    }
}

private final class BundleToken {}
```

- [ ] **Step 2: Run the full unit test suite**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
Expected: `** TEST SUCCEEDED **`, no failures anywhere — this was the last place a known pre-existing failure could hide, and it's now gone along with the tests that produced it.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & StretchTests/CuratedContentIntegrityTests.swift"
git commit -m "test(routines): drop ContentPack/GuidedProgram cases from CuratedContentIntegrityTests"
```

---

## Plan complete

At this point: no `Routine.isPublic`/`borrowCount`/`authorID`/`authorName` anywhere in the codebase, `BorrowRoutineView`/`ContentPacksView`/`GuidedProgramsView`/`GuidedProgramDetailView`/`ContentPack`/`GuidedProgram` are all deleted, `RoutineListView` has no top entry-row section (expected — Phase 3 adds `PremadeRoutinesView` back in), and the full test suite is green with no known-failing tests left. This is Phase 1 of 4; Phase 2 ("Today" pin generalization) gets its own plan next, following the same spec.
