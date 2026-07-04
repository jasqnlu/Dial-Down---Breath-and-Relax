# Exercise Library Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** New muscle-group exercise vocabulary, ~190 seed exercises covering every group, stick-figure + YouTube removal, local-video placeholder slot.

**Architecture:** A new `MuscleGroup` vocabulary type is the single source of truth for group names and the old-region→group migration map. `SeedData.json` is regenerated against that vocabulary (seed version 4). Media rendering collapses to one placeholder/local-video hero card.

**Tech Stack:** SwiftUI, SwiftData (CloudKit-compatible models), Swift Testing (`@testable import BreathRelaxStretch`), AVKit.

## Global Constraints

- Branch: `feature/exercise-library` off `main`.
- SwiftData models: never delete stored properties, only add optionals with inline defaults (CloudKit rule already used in `Exercise.swift`).
- Tests live in `Breath - Relax & StretchTests/` (folder auto-syncs into the test target).
- Test command: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- Build check: same command with `build` instead of `test` (or omit `-only-testing`).

---

### Task 1: MuscleGroup vocabulary + migration map

**Files:**
- Create: `Breath - Relax & Stretch/Models/MuscleGroups.swift`
- Test: `Breath - Relax & StretchTests/MuscleGroupsTests.swift`

**Interfaces:**
- Produces: `enum MuscleGroup: String, CaseIterable, Codable` — `rawValue` is the display/storage name (e.g. `"Left Hamstrings"`); `static let oldRegionMap: [String: [String]]` mapping every legacy region name to ≥1 group rawValues; `static func migrate(_ oldNames: [String]) -> [String]`.

- [ ] **Step 1: Write the failing test**

```swift
import Testing
@testable import BreathRelaxStretch

struct MuscleGroupsTests {
    /// Every legacy region name used by seed v3 / saved marks must map somewhere.
    static let legacyNames = [
        "Chest", "Core", "Glutes", "Head", "Hips", "Left Arm", "Left Calf",
        "Left Elbow", "Left Foot", "Left Forearm", "Left Hamstring", "Left Hand",
        "Left Knee", "Left Leg", "Left Shin", "Left Shoulder", "Lower Back",
        "Neck", "Right Arm", "Right Calf", "Right Elbow", "Right Foot",
        "Right Forearm", "Right Hamstring", "Right Hand", "Right Knee",
        "Right Leg", "Right Shin", "Right Shoulder", "Upper Back"
    ]

    @Test func everyLegacyNameMigrates() {
        for old in Self.legacyNames {
            let mapped = MuscleGroup.migrate([old])
            #expect(!mapped.isEmpty, "\(old) has no migration target")
            for name in mapped {
                #expect(MuscleGroup(rawValue: name) != nil, "\(name) is not a valid group")
            }
        }
    }

    @Test func migrationPassesUnknownNamesThrough() {
        #expect(MuscleGroup.migrate(["My Custom Area"]) == ["My Custom Area"])
    }

    @Test func migrationDeduplicates() {
        // "Left Leg" and "Left Knee" both include Left Quadriceps — no dupes.
        let out = MuscleGroup.migrate(["Left Leg", "Left Knee"])
        #expect(Set(out).count == out.count)
    }

    @Test func groupCountIsAround40() {
        #expect((38...52).contains(MuscleGroup.allCases.count))
    }
}
```

- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL, `MuscleGroup` not defined.

- [ ] **Step 3: Write implementation**

```swift
import Foundation

/// The body-map / exercise vocabulary: ~40 major muscle groups plus coarse
/// fallback areas (head/hands/feet) that muscles don't cover.
enum MuscleGroup: String, CaseIterable, Codable {
    // Neck & shoulders
    case neckFront = "Front Neck", neckBack = "Back Neck"
    case leftTraps = "Left Trapezius",   rightTraps = "Right Trapezius"
    case leftDelts = "Left Shoulder",    rightDelts = "Right Shoulder"
    // Torso
    case leftChest = "Left Chest",       rightChest = "Right Chest"
    case abs = "Abs"
    case leftObliques = "Left Obliques", rightObliques = "Right Obliques"
    case leftLats = "Left Lats",         rightLats = "Right Lats"
    case spinalErectors = "Spinal Erectors"
    case lowerBack = "Lower Back"
    // Arms
    case leftBiceps = "Left Biceps",     rightBiceps = "Right Biceps"
    case leftTriceps = "Left Triceps",   rightTriceps = "Right Triceps"
    case leftForearm = "Left Forearm",   rightForearm = "Right Forearm"
    // Hips & legs
    case leftGlutes = "Left Glutes",     rightGlutes = "Right Glutes"
    case leftHipFlexors = "Left Hip Flexors", rightHipFlexors = "Right Hip Flexors"
    case leftAdductors = "Left Adductors",    rightAdductors = "Right Adductors"
    case leftQuads = "Left Quadriceps",  rightQuads = "Right Quadriceps"
    case leftHamstrings = "Left Hamstrings", rightHamstrings = "Right Hamstrings"
    case leftCalves = "Left Calves",     rightCalves = "Right Calves"
    case leftTibialis = "Left Tibialis", rightTibialis = "Right Tibialis"
    // Coarse fallback areas (no skeletal muscle proxy coverage)
    case head = "Head"
    case leftHand = "Left Hand",  rightHand = "Right Hand"
    case leftFoot = "Left Foot",  rightFoot = "Right Foot"

    /// Legacy body-map region name → new group names.
    static let oldRegionMap: [String: [String]] = [
        "Head": ["Head"], "Neck": ["Front Neck", "Back Neck"],
        "Left Shoulder": ["Left Shoulder"], "Right Shoulder": ["Right Shoulder"],
        "Chest": ["Left Chest", "Right Chest"],
        "Core": ["Abs"],
        "Upper Back": ["Left Trapezius", "Right Trapezius"],
        "Lower Back": ["Lower Back"],
        "Left Arm": ["Left Biceps", "Left Triceps"],
        "Right Arm": ["Right Biceps", "Right Triceps"],
        "Left Elbow": ["Left Forearm"], "Right Elbow": ["Right Forearm"],
        "Left Forearm": ["Left Forearm"], "Right Forearm": ["Right Forearm"],
        "Left Hand": ["Left Hand"], "Right Hand": ["Right Hand"],
        "Hips": ["Left Hip Flexors", "Right Hip Flexors"],
        "Glutes": ["Left Glutes", "Right Glutes"],
        "Left Leg": ["Left Quadriceps"], "Right Leg": ["Right Quadriceps"],
        "Left Hamstring": ["Left Hamstrings"], "Right Hamstring": ["Right Hamstrings"],
        "Left Knee": ["Left Quadriceps"], "Right Knee": ["Right Quadriceps"],
        "Left Shin": ["Left Tibialis"], "Right Shin": ["Right Tibialis"],
        "Left Calf": ["Left Calves"], "Right Calf": ["Right Calves"],
        "Left Foot": ["Left Foot"], "Right Foot": ["Right Foot"],
    ]

    /// Maps legacy names to group names; unknown names pass through unchanged.
    /// Order-preserving, deduplicated.
    static func migrate(_ oldNames: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for old in oldNames {
            for name in oldRegionMap[old] ?? [old] where seen.insert(name).inserted {
                out.append(name)
            }
        }
        return out
    }
}
```

- [ ] **Step 4: Run tests — Expected: PASS**
- [ ] **Step 5: Commit** — `git commit -m "feat: MuscleGroup vocabulary + legacy region migration"`

---

### Task 2: Remove stick figure, YouTube video, pose editing; add placeholder video slot

**Files:**
- Delete: `Views/Exercises/StickFigureView.swift`, `Views/Exercises/VideoSource.swift`, `Views/Exercises/VideoPreviewCard.swift`
- Create: `Views/Exercises/ExerciseMediaCard.swift`
- Modify: `Models/Exercise.swift` (add `localVideoName`), `Views/Exercises/ExerciseDetailView.swift`, `Views/Exercises/CreateExerciseView.swift` (strip video-URL + pose UI), plus any other reference found via `grep -rn "VideoSource\|VideoPreviewCard\|StickFigureView\|poses" "Breath - Relax & Stretch/Views"` (check `ForYouSection.swift`, `ExerciseListView.swift`, session player).
- Test: `Breath - Relax & StretchTests/ExerciseMediaTests.swift`

**Interfaces:**
- Produces: `Exercise.localVideoName: String?` (bundle-relative video file name, e.g. `"hamstring_fold.mp4"`); `ExerciseMediaCard(exercise: Exercise)` view — plays looping muted `AVPlayer` when `localVideoName` resolves to a bundled file, else renders the "Video coming soon" placeholder.
- Consumes: nothing from other tasks.

- [ ] **Step 1: Write the failing test**

```swift
import Testing
@testable import BreathRelaxStretch

struct ExerciseMediaTests {
    @Test func localVideoURLNilWhenUnset() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.localVideoURL == nil)
    }

    @Test func localVideoURLNilWhenFileMissing() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.localVideoName = "definitely_not_bundled.mp4"
        #expect(e.localVideoURL == nil)   // missing file → placeholder, never broken player
    }
}
```

- [ ] **Step 2: Run test — Expected: FAIL (`localVideoURL` undefined).**

- [ ] **Step 3: Model change** — in `Exercise.swift` add:

```swift
    /// Bundle-relative file name of Jason's self-filmed demo clip.
    var localVideoName: String? = nil

    /// Resolved bundle URL — nil when unset OR the file isn't bundled,
    /// so the UI can always fall back to the placeholder card.
    var localVideoURL: URL? {
        guard let name = localVideoName, !name.isEmpty else { return nil }
        let ns = name as NSString
        return Bundle.main.url(forResource: ns.deletingPathExtension,
                               withExtension: ns.pathExtension.isEmpty ? "mp4" : ns.pathExtension)
    }
```

- [ ] **Step 4: Run test — Expected: PASS.**

- [ ] **Step 5: New media card** — `ExerciseMediaCard.swift`:

```swift
import SwiftUI
import AVKit

/// Hero media slot: looping local video when available, otherwise a
/// "coming soon" placeholder. Never renders a broken player.
struct ExerciseMediaCard: View {
    let exercise: Exercise
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let url = exercise.localVideoURL {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        let p = AVPlayer(url: url)
                        p.isMuted = true
                        p.actionAtItemEnd = .none
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: p.currentItem, queue: .main) { _ in
                                p.seek(to: .zero); p.play()
                            }
                        p.play()
                        player = p
                    }
                    .onDisappear { player?.pause(); player = nil }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "video.badge.waveform")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.accentColor)
                    Text("Video coming soon")
                        .font(.subheadline.weight(.semibold))
                    Text("Follow the steps below in the meantime.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16/9, contentMode: .fit)
                .background(Color(.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
```

- [ ] **Step 6: Rewire ExerciseDetailView** — delete the `videoSource` property, the stick-figure block (lines 33–45) and the `VideoPreviewCard` block (lines 49–55); insert `ExerciseMediaCard(exercise: exercise)` directly after the caution card. Delete the three dead files. Strip CreateExerciseView's video-URL field and pose editor UI (keep name/type/parts/duration/difficulty/instructions). Fix every grep hit from the Files list.

- [ ] **Step 7: Build + full test run — Expected: compiles, all green.**
- [ ] **Step 8: Commit** — `git commit -m "feat: local-video media card; remove stick figures and YouTube embeds"`

---

### Task 3: Seed data v4 — full muscle-group coverage

**Files:**
- Modify: `Resources/SeedData.json`, `Breath__Relax___StretchApp.swift` (seed import + v4 migration + stale alert copy)
- Test: `Breath - Relax & StretchTests/SeedDataTests.swift`

**Interfaces:**
- Consumes: `MuscleGroup` (Task 1).
- Produces: `SeedData.json` with `"exercises"` array where every `targetBodyParts` entry is a valid `MuscleGroup` rawValue and every non-fallback group has ≥3 stretch exercises.

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

struct SeedDataTests {
    static func loadExercises() throws -> [[String: Any]] {
        let url = try #require(Bundle(for: BundleToken.self)
            .url(forResource: "SeedData", withExtension: "json")
            ?? Bundle.main.url(forResource: "SeedData", withExtension: "json"))
        let json = try #require(try JSONSerialization.jsonObject(
            with: Data(contentsOf: url)) as? [String: Any])
        return try #require(json["exercises"] as? [[String: Any]])
    }

    @Test func allTargetsAreValidGroups() throws {
        for raw in try Self.loadExercises() {
            for part in (raw["targetBodyParts"] as? [String] ?? []) {
                #expect(MuscleGroup(rawValue: part) != nil,
                        "\(raw["name"] ?? "?") targets unknown '\(part)'")
            }
        }
    }

    @Test func everyMuscleGroupHasThreeStretches() throws {
        let fallbacks: Set<MuscleGroup> = [.head, .leftHand, .rightHand, .leftFoot, .rightFoot]
        var counts: [String: Int] = [:]
        for raw in try Self.loadExercises() where (raw["type"] as? String) != "breath" {
            for part in (raw["targetBodyParts"] as? [String] ?? []) {
                counts[part, default: 0] += 1
            }
        }
        for group in MuscleGroup.allCases where !fallbacks.contains(group) {
            #expect(counts[group.rawValue, default: 0] >= 3,
                    "\(group.rawValue) has only \(counts[group.rawValue, default: 0]) stretches")
        }
    }

    @Test func everyExerciseIsComplete() throws {
        for raw in try Self.loadExercises() {
            #expect((raw["instructions"] as? [String] ?? []).count >= 3)
            #expect(((raw["durationSeconds"] as? Int) ?? 0) >= 15)
            #expect((1...3).contains((raw["difficulty"] as? Int) ?? 0))
        }
    }
}

private final class BundleToken {}
```

- [ ] **Step 2: Run — Expected: FAIL (old names like "Left Hamstring" invalid, coverage gaps).**

- [ ] **Step 3: Author seed v4.** Rewrite `SeedData.json`:
  - Re-target all 64 existing exercises through `MuscleGroup.migrate` semantics (e.g. `"Left Hamstring"` → `"Left Hamstrings"`, `"Upper Back"` → both traps; bilateral stretches list both sides).
  - Strip every `poses` array and every YouTube/Vimeo `mediaURL`.
  - Add new stretches until every non-fallback group has ≥3 (write real content: name, `"type": "stretch"`, targets, 30–90s durations, difficulty 1–3, 4–7 numbered instruction steps, `caution` for neck/spine/loaded stretches). Expected total ≈ 180–200. Anatomy references for correctness: standard PT stretch catalogs (e.g. doorway pec stretch, cross-body rear-delt, standing quad pull, figure-four glute, kneeling hip-flexor lunge, seated adductor butterfly, downward-dog calves, kneeling tibialis sit-back, wrist flexor/extensor prayer stretches, levator-scapulae chin-tuck, cat-cow erectors, child's pose lats, supine twist obliques).

- [ ] **Step 4: Seed import + migration** in `Breath__Relax___StretchApp.swift`:
  - Read optional `localVideoName` in `seedIfNeeded()` (after `caution`): `exercise.localVideoName = raw["localVideoName"] as? String`.
  - Extend `migrateSeedIfNeeded()` for `seedDataVersion < 4`: fetch all exercises; for seed-named ones update `targetBodyParts` via `MuscleGroup.migrate`; insert bundle exercises whose names don't exist yet; for user-created exercises apply `MuscleGroup.migrate` to their `targetBodyParts` too (pass-through keeps custom names). Set `seedDataVersion = 4`. Replace the v3 alert copy with: `"New stretches were added covering every muscle group — find them in the Exercises tab."`
  - Also migrate saved marks once: `UserDefaults` key `bodymap.markedRegions` → mapped names (same `migrate` call).

- [ ] **Step 5: Run full suite — Expected: PASS.**
- [ ] **Step 6: Simulator sanity** (per docs: launch, screenshot Exercises tab; verify count ≈190 and no "unknown" chips).
- [ ] **Step 7: Commit** — `git commit -m "feat: seed v4 — full muscle-group exercise coverage"`
