# Exercise Session Cues Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** During an exercise in `SessionPlayerView`, show a "Hold" vs "Keep Going" cue badge and cycle the exercise's own instructions on screen, with a soft reminder beep on each new cue, exercise start, exercise end, and side switch.

**Architecture:** A new `ExerciseCueStyle` enum + `Exercise.cueStyle` field (seeded per-exercise from hand-classified data, backfilled onto existing installs via a new `SeedMigrator.migrateV8`), plus three additive pieces of `SessionPlayerView` UI/audio: a cue badge under the exercise name, a cycling instruction-text view between the media card and the countdown, and a fourth `SystemSoundID` reminder beep wired into four existing call sites.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing (`@Suite`/`@Test`/`#expect`, `@testable import BreathRelaxStretch`), XCUITest for simulator verification, AudioToolbox (`AudioServicesPlaySystemSound`). Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new `.swift` files under `Breath - Relax & Stretch/` or `Breath - Relax & StretchTests/`/`Breath - Relax & StretchUITests/` are picked up automatically, no `.pbxproj` edits needed. Build/test with scheme `BreathRelaxStretch`, destination `platform=iOS Simulator,name=iPhone 17`.

## Global Constraints

- Badge and instruction cue exist only inside `SessionPlayerView`'s `playerContent(exercise:)` — no changes to the exercise list/detail pages, `ExerciseMediaCard`, or the get-ready screen.
- Reuse existing Lumina design tokens only: `Color.luminaMintTint`, `Color.luminaPrimary`, `Color.luminaOnSurface`, `Font.luminaLabel` — no new colors/fonts.
- Instruction-text dwell time is a fixed 3.5s for every exercise regardless of `cueStyle` — cycling speed carries no meaning; the badge already signals hold vs. repeat.
- Badge pulse (repeat-type only) is independent of the instruction-cycling cadence: continuous ~1.1s loop, scale 1 → 1.07 → 1, opacity 1 → 0.82 → 1, ease-in-out.
- Instruction text transition: pop in from the left (~24pt offset + fade, 0.35s ease-out), dwell, fade out in place (opacity only, 0.25s ease-in) before the next line pops in. Insertion and removal need *different* durations/curves, which requires attaching `.animation(...)` to each half of the `AnyTransition` individually (an ambient `withAnimation(...)` around the state change applies one animation to both halves) — see Task 5 for the exact snippet.
- `cueStyle` never affects `isBilateral`/side-switch logic, `GamificationService` points, or `SessionRecorder` — purely a display/audio concern.
- The reminder beep (`soundCueBeep`, `SystemSoundID = 1103`) fires at exactly four sites: exercise start, each instruction pop-in, the existing side-switch cue, and natural exercise end — never on manual skip.
- All 207 `SeedData.json` exercises get an authored, hand-classified `"cueStyle"` value (`"hold"` or `"repeat"`) — no heuristic fallback in the app itself.
- Full spec: `docs/superpowers/specs/2026-08-01-exercise-session-cues-design.md`.

---

### Task 1: `ExerciseCueStyle` enum + `Exercise.cueStyle` field

**Files:**
- Modify: `Breath - Relax & Stretch/Models/Exercise.swift`
- Test: `Breath - Relax & StretchTests/ExerciseCueStyleTests.swift` (create)

**Interfaces:**
- Consumes: nothing new.
- Produces: `enum ExerciseCueStyle: String, Codable, CaseIterable { case hold = "Hold"; case repeatMotion = "Repeat" }` and `Exercise.cueStyle: ExerciseCueStyle` (default `.hold`) — consumed by Task 3 (seed insert + migration) and Task 4 (badge UI).

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/ExerciseCueStyleTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

struct ExerciseCueStyleTests {
    @Test func defaultsToHold() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.cueStyle == .hold)
    }

    @Test func initAcceptsExplicitCueStyle() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [],
                         cueStyle: .repeatMotion)
        #expect(e.cueStyle == .repeatMotion)
    }

    @Test func rawValuesMatchCapitalizedSeedStrings() {
        // Breath__Relax___StretchApp.swift parses seed JSON via
        // `ExerciseCueStyle(rawValue: rawStr.capitalized)` against lowercase
        // "hold"/"repeat" bundle strings — verify that lookup actually works.
        #expect(ExerciseCueStyle(rawValue: "hold".capitalized) == .hold)
        #expect(ExerciseCueStyle(rawValue: "repeat".capitalized) == .repeatMotion)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseCueStyleTests"`
Expected: FAIL to build — `Exercise` has no member `cueStyle`, no `ExerciseCueStyle` type.

- [ ] **Step 3: Write the implementation**

In `Breath - Relax & Stretch/Models/Exercise.swift`, add directly after the existing `enum ExerciseType` block (after its closing `}`, before `@Model final class Exercise {`):

```swift
enum ExerciseCueStyle: String, Codable, CaseIterable {
    case hold = "Hold"
    case repeatMotion = "Repeat"
}
```

Inside `final class Exercise`, add directly below the existing `var isBilateral: Bool = true` property (and its doc comment) and above `var posesData: Data = Data()`:

```swift
    /// Whether this exercise is a static position held for the whole
    /// duration (.hold) or a rhythmic motion repeated throughout (.repeatMotion).
    /// Drives the session player's cue badge. Defaults to `.hold`.
    var cueStyle: ExerciseCueStyle = .hold
```

In `Exercise.init(...)`, add a `cueStyle` parameter with default `.hold` directly after the existing `isBilateral: Bool = true` parameter, and assign it in the body directly after `self.isBilateral = isBilateral`:

```swift
    init(
        uuid: UUID = UUID(),
        name: String,
        type: ExerciseType,
        targetBodyParts: [String],
        durationSeconds: Int,
        difficulty: Int,
        instructions: [String],
        mediaURL: String? = nil,
        caution: String? = nil,
        isBilateral: Bool = true,
        cueStyle: ExerciseCueStyle = .hold
    ) {
        self.uuid = uuid
        self.name = name
        self.type = type
        self.targetBodyParts = targetBodyParts
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.instructions = instructions
        self.mediaURL = mediaURL
        self.caution = caution
        self.isBilateral = isBilateral
        self.cueStyle = cueStyle
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/ExerciseCueStyleTests"`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/Exercise.swift" "Breath - Relax & StretchTests/ExerciseCueStyleTests.swift"
git commit -m "feat(exercise): add ExerciseCueStyle enum and Exercise.cueStyle field"
```

---

### Task 2: Author `cueStyle` for all 207 seed exercises

**Files:**
- Modify: `Breath - Relax & Stretch/Resources/SeedData.json`
- Test: `Breath - Relax & StretchTests/SeedDataTests.swift:80-86` (extend existing `everyExerciseIsComplete`-adjacent area)

**Interfaces:**
- Consumes: nothing from Task 1's Swift code (this task only edits the JSON data file).
- Produces: every object in `SeedData.json`'s `"exercises"` array carries a `"cueStyle"` key (`"hold"` or `"repeat"`) — consumed by Task 3 (seed-insert parsing + migration).

- [ ] **Step 1: Write the failing test**

In `Breath - Relax & StretchTests/SeedDataTests.swift`, add a new test directly after `everyExerciseIsComplete` (before the closing `}` of the `SeedDataTests` struct):

```swift
    @Test func everyExerciseHasCueStyle() throws {
        for raw in try Self.loadExercises() {
            let cueStyle = raw["cueStyle"] as? String
            #expect(["hold", "repeat"].contains(cueStyle ?? ""),
                    "\(raw["name"] ?? "?") has missing/invalid cueStyle: \(cueStyle ?? "nil")")
        }
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedDataTests/everyExerciseHasCueStyle"`
Expected: FAIL — every exercise currently has no `cueStyle` key.

- [ ] **Step 3: Merge the hand-classified cueStyle values into SeedData.json**

This mapping was produced by reading every exercise's actual `instructions` text (not guessed from `type` — e.g. `Cat-Cow Flow` and `Shoulder Roll` are `stretch`-typed but dynamic, so they're `"repeat"`; `Eye Palming` is `breath`-typed but a static held position, so it's `"hold"`) and hand-reviewed, including the 12 exercises with alternating/mixed motion (toe/finger stretches, `Frontalis Release`, `Suboccipital Release (Finger Press)`, `Wrist & Forearm Release`, etc.) — all classified `"repeat"` since the alternating/switch/hold guidance in those cases already lives in their existing `instructions` steps, which Task 5's instruction-cycling will surface on its own.

Create a one-off script at `/tmp/merge_cue_style.py` (not part of the app — delete after running):

```python
import json

CUE_STYLE_BY_NAME = {
    "20-20-20 Focus Shift": "hold",
    "4-7-8 Breathing": "repeat",
    "Alternate Nostril Breathing": "repeat",
    "Ankle Alphabet": "repeat",
    "Bent-Knee Wall Calf Stretch (Soleus)": "hold",
    "Body Scan Breathing": "repeat",
    "Box Breathing": "repeat",
    "Bridge Pose": "hold",
    "Brow & Forehead Smoother": "repeat",
    "Calf Stretch at Wall (Straight-Knee)": "hold",
    "Cat-Cow Flow": "repeat",
    "Child's Pose": "hold",
    "Chin Tuck (Forward Head Reset)": "repeat",
    "Clasped-Hands Behind-Back Stretch": "hold",
    "Cobra Stretch (Prone Press-Up)": "hold",
    "Coherent Breathing": "repeat",
    "Cooling Sitali Breath": "repeat",
    "Counting Down Sleep Breath": "repeat",
    "Deep Belly Breath": "repeat",
    "Diaphragmatic Breath with Counting": "repeat",
    "Doorway Overhead Chest Stretch": "hold",
    "Doorway Pec Stretch (Mid Chest)": "hold",
    "Doorway Shoulder & Chest Opener": "hold",
    "Double Knee-to-Chest Release": "repeat",
    "Downward-Facing Dog": "repeat",
    "Dynamic Standing Leg Swings": "repeat",
    "Equal Breathing (Sama Vritti)": "repeat",
    "Extended Exhale Breathing": "repeat",
    "Eye Palming": "hold",
    "Frog Stretch (Kneeling Groin Stretch)": "hold",
    "Frontalis Release": "repeat",
    "Gentle Eye Rolls": "repeat",
    "Happy Baby Pose": "repeat",
    "High Doorway Chest Stretch (Upper Chest)": "hold",
    "Humming Bee Breath": "repeat",
    "Jaw-Open Temporalis Stretch": "repeat",
    "Kneeling Abdominal Stretch (Camel-Lite)": "hold",
    "Kneeling Chest Stretch on Chair": "hold",
    "Kneeling Tibialis Stretch": "hold",
    "Left Behind-Head Strap-Assisted Triceps Stretch": "hold",
    "Left Chin-to-Shoulder Diagonal Stretch": "hold",
    "Left Cossack Squat Stretch": "repeat",
    "Left Couch Stretch": "hold",
    "Left Cow-Face Arm Stretch": "hold",
    "Left Cross-Body Elbow Pull": "hold",
    "Left Cross-Body Rear Delt Stretch": "hold",
    "Left Doorframe Hamstring Stretch": "hold",
    "Left Doorway Bicep Stretch": "hold",
    "Left Doorway External Rotation Stretch": "hold",
    "Left Extended-Fingers Bicep Stretch": "hold",
    "Left Finger Extension Stretch": "repeat",
    "Left Half-Kneeling Rear-Foot Instep Stretch": "hold",
    "Left Isometric Neck Side Press": "repeat",
    "Left Kneeling Hip-Flexor Lunge": "hold",
    "Left Kneeling Lat Stretch (Hands on Chair)": "hold",
    "Left Kneeling Quad Stretch": "hold",
    "Left Levator Scapulae Stretch": "hold",
    "Left Low Lunge (Anjaneyasana)": "hold",
    "Left Overhead Reach Lat Stretch with Strap": "hold",
    "Left Overhead Shoulder Stretch with Strap": "hold",
    "Left Overhead Triceps Stretch": "hold",
    "Left Pigeon Pose Hip Stretch": "hold",
    "Left Plantar Fascia Stretch (Toe Raise)": "hold",
    "Left Reclined Quad Stretch with Strap": "hold",
    "Left Scalene Neck Stretch": "hold",
    "Left Seated Behind-Hip Bicep Stretch": "hold",
    "Left Seated Calf Stretch with Towel": "hold",
    "Left Seated Figure-Four Stretch": "hold",
    "Left Seated Hamstring Stretch": "hold",
    "Left Seated Spinal Twist": "hold",
    "Left Side Lunge (Groin Stretch)": "hold",
    "Left Side-Lying Quad Stretch": "hold",
    "Left Single-Leg Supine Knee-to-Chest": "hold",
    "Left Sleeper Stretch (Internal Rotation)": "hold",
    "Left Standing Crescent Moon Side Stretch": "hold",
    "Left Standing Crossed-Leg Fold": "hold",
    "Left Standing Figure-4 Stretch": "hold",
    "Left Standing Hip-Flexor Stretch (Foot Elevated)": "hold",
    "Left Standing Quad Stretch": "hold",
    "Left Standing Reach-Through Twist": "repeat",
    "Left Standing Side Bend": "hold",
    "Left Standing Side Reach": "hold",
    "Left Standing Tibialis Stretch (Toe Point)": "hold",
    "Left Step-Edge Calf Drop Stretch": "hold",
    "Left Supine Chest Opener (Open Book)": "hold",
    "Left Supine Figure-4 Stretch": "hold",
    "Left Supine Hamstring Stretch with Towel": "hold",
    "Left Supine Spinal Twist (Windshield Wipers)": "hold",
    "Left Thread the Needle": "hold",
    "Left Toe Spread & Stretch": "repeat",
    "Left Towel-Assisted Triceps Stretch": "hold",
    "Left Upper Trapezius Stretch": "hold",
    "Left Wall Bicep Stretch": "hold",
    "Left Wall Corner Pec Stretch": "hold",
    "Left Wall-Assisted Overhead Triceps Stretch": "hold",
    "Left Wrist Extensor Stretch": "hold",
    "Left Wrist Flexor Stretch": "hold",
    "Left-Nostril Calming Breath (Chandra Bhedana)": "repeat",
    "Legs Up the Wall": "hold",
    "Lion's Breath": "repeat",
    "Neck Extension Stretch (Gentle Look-Up)": "hold",
    "Neck Flexion Stretch (Chin-to-Chest)": "hold",
    "Ocean Breath (Ujjayi)": "repeat",
    "Pelvic Tilt": "repeat",
    "Physiological Sigh": "repeat",
    "Pigeon Pose (Left Leg Forward)": "hold",
    "Pigeon Pose (Right Leg Forward)": "hold",
    "Prayer Push Against Wall": "hold",
    "Prayer Stretch (Palms Together, Lower)": "hold",
    "Progressive Relaxation Breath": "repeat",
    "Prone Neck Retraction": "repeat",
    "Pursed-Lip Breathing": "repeat",
    "Resisted Jaw Opening": "repeat",
    "Reverse Prayer Shoulder Mobiliser": "hold",
    "Reverse Prayer Stretch": "hold",
    "Right Behind-Head Strap-Assisted Triceps Stretch": "hold",
    "Right Chin-to-Shoulder Diagonal Stretch": "hold",
    "Right Cossack Squat Stretch": "repeat",
    "Right Couch Stretch": "hold",
    "Right Cow-Face Arm Stretch": "hold",
    "Right Cross-Body Elbow Pull": "hold",
    "Right Cross-Body Rear Delt Stretch": "hold",
    "Right Doorframe Hamstring Stretch": "hold",
    "Right Doorway Bicep Stretch": "hold",
    "Right Doorway External Rotation Stretch": "hold",
    "Right Extended-Fingers Bicep Stretch": "hold",
    "Right Finger Extension Stretch": "repeat",
    "Right Half-Kneeling Rear-Foot Instep Stretch": "hold",
    "Right Isometric Neck Side Press": "repeat",
    "Right Kneeling Hip-Flexor Lunge": "hold",
    "Right Kneeling Lat Stretch (Hands on Chair)": "hold",
    "Right Kneeling Quad Stretch": "hold",
    "Right Levator Scapulae Stretch": "hold",
    "Right Low Lunge (Anjaneyasana)": "hold",
    "Right Overhead Reach Lat Stretch with Strap": "hold",
    "Right Overhead Shoulder Stretch with Strap": "hold",
    "Right Overhead Triceps Stretch": "hold",
    "Right Pigeon Pose Hip Stretch": "hold",
    "Right Plantar Fascia Stretch (Toe Raise)": "hold",
    "Right Reclined Quad Stretch with Strap": "hold",
    "Right Scalene Neck Stretch": "hold",
    "Right Seated Behind-Hip Bicep Stretch": "hold",
    "Right Seated Calf Stretch with Towel": "hold",
    "Right Seated Figure-Four Stretch": "hold",
    "Right Seated Hamstring Stretch": "hold",
    "Right Seated Spinal Twist": "hold",
    "Right Side Lunge (Groin Stretch)": "hold",
    "Right Side-Lying Quad Stretch": "hold",
    "Right Single-Leg Supine Knee-to-Chest": "hold",
    "Right Sleeper Stretch (Internal Rotation)": "hold",
    "Right Standing Crescent Moon Side Stretch": "hold",
    "Right Standing Crossed-Leg Fold": "hold",
    "Right Standing Figure-4 Stretch": "hold",
    "Right Standing Hip-Flexor Stretch (Foot Elevated)": "hold",
    "Right Standing Quad Stretch": "hold",
    "Right Standing Reach-Through Twist": "repeat",
    "Right Standing Side Bend": "hold",
    "Right Standing Side Reach": "hold",
    "Right Standing Tibialis Stretch (Toe Point)": "hold",
    "Right Step-Edge Calf Drop Stretch": "hold",
    "Right Supine Chest Opener (Open Book)": "hold",
    "Right Supine Figure-4 Stretch": "hold",
    "Right Supine Hamstring Stretch with Towel": "hold",
    "Right Supine Spinal Twist (Windshield Wipers)": "hold",
    "Right Thread the Needle": "hold",
    "Right Toe Spread & Stretch": "repeat",
    "Right Towel-Assisted Triceps Stretch": "hold",
    "Right Upper Trapezius Stretch": "hold",
    "Right Wall Bicep Stretch": "hold",
    "Right Wall Corner Pec Stretch": "hold",
    "Right Wall-Assisted Overhead Triceps Stretch": "hold",
    "Right Wrist Extensor Stretch": "hold",
    "Right Wrist Flexor Stretch": "hold",
    "Runner's Calf Stretch (Staggered Stance)": "repeat",
    "Runner's Lunge with Rotation (Left)": "hold",
    "Runner's Lunge with Rotation (Right)": "hold",
    "Seated Butterfly Stretch": "hold",
    "Seated Forward Fold": "hold",
    "Seated Neck Rolls": "repeat",
    "Seated Neck Rotation": "hold",
    "Seated Thoracic Extension Over Chair Back": "hold",
    "Segmented Exhale Breathing (Viloma)": "repeat",
    "Shin & Ankle Mobiliser": "repeat",
    "Shoulder Roll": "repeat",
    "Side-to-Side Jaw Glide": "repeat",
    "Sphinx Pose": "hold",
    "Standing Ankle Dorsiflexion Stretch (Left)": "hold",
    "Standing Ankle Dorsiflexion Stretch (Right)": "hold",
    "Standing Back Extension": "repeat",
    "Standing Chest Expansion Stretch": "hold",
    "Standing Forward Fold (Ragdoll)": "repeat",
    "Standing Hamstring Stretch": "hold",
    "Standing Hip Circles": "repeat",
    "Standing IT Band Side Stretch (Left)": "hold",
    "Standing IT Band Side Stretch (Right)": "hold",
    "Standing Split Prep Stretch": "hold",
    "Suboccipital Release (Finger Press)": "repeat",
    "Sun Salutation Warm-Up": "repeat",
    "Temporalis Release": "repeat",
    "Three-Part Breath (Dirga Pranayama)": "repeat",
    "Tongue-Up Controlled Open/Close": "repeat",
    "Upper-Back Cat-Cow (Seated)": "repeat",
    "Wide-Legged Forward Fold": "hold",
    "Wrist & Forearm Release": "repeat",
    "Wrist Circles": "repeat",
    "Wrist Extensor Reverse-Prayer Stretch": "hold",
    "Wrist Flexor Prayer Stretch": "hold",
}

PATH = "Breath - Relax & Stretch/Resources/SeedData.json"

with open(PATH) as f:
    data = json.load(f)

missing = []
for exercise in data["exercises"]:
    name = exercise["name"]
    if name not in CUE_STYLE_BY_NAME:
        missing.append(name)
        continue
    # Insert cueStyle right after "type" for readable diffs — rebuild the
    # dict in the desired key order since plain assignment always appends.
    rebuilt = {}
    for key, value in exercise.items():
        rebuilt[key] = value
        if key == "type":
            rebuilt["cueStyle"] = CUE_STYLE_BY_NAME[name]
    exercise.clear()
    exercise.update(rebuilt)

if missing:
    raise SystemExit(f"No cueStyle for: {missing}")

with open(PATH, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(f"Updated {len(data['exercises'])} exercises.")
```

Run it, then delete the script:

```bash
python3 /tmp/merge_cue_style.py
rm /tmp/merge_cue_style.py
```

Expected output: `Updated 207 exercises.`

- [ ] **Step 4: Verify the JSON is well-formed and every entry matched**

```bash
python3 -c "
import json
data = json.load(open('Breath - Relax & Stretch/Resources/SeedData.json'))
ex = data['exercises']
assert len(ex) == 207, len(ex)
missing = [e['name'] for e in ex if e.get('cueStyle') not in ('hold', 'repeat')]
assert not missing, missing
from collections import Counter
print(Counter(e['cueStyle'] for e in ex))
"
```

Expected: no assertion error, prints `Counter({'hold': 148, 'repeat': 59})`.

- [ ] **Step 5: Run the test to verify it passes**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedDataTests"`
Expected: PASS (all `SeedDataTests`, including the new `everyExerciseHasCueStyle`).

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Resources/SeedData.json" "Breath - Relax & StretchTests/SeedDataTests.swift"
git commit -m "content(seed): author cueStyle for all 207 seed exercises"
```

---

### Task 3: Read `cueStyle` at seed-insert time + `SeedMigrator.migrateV8` backfill

**Files:**
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`
- Modify: `Breath - Relax & Stretch/Services/SeedMigrator.swift`
- Test: `Breath - Relax & StretchTests/SeedMigratorTests.swift`

**Interfaces:**
- Consumes: `Exercise.cueStyle: ExerciseCueStyle` + `init(..., cueStyle:)` (Task 1); `"cueStyle"` string values on every `SeedData.json` entry (Task 2).
- Produces: `SeedMigrator.migrateV8(context: ModelContext, rawExercises: [[String: Any]]) -> Bool`, `seedDataVersion` reaching `8` — nothing later depends on these beyond the running app itself.

- [ ] **Step 1: Write the failing tests**

In `Breath - Relax & StretchTests/SeedMigratorTests.swift`, add a new `// MARK: - v8: cueStyle backfill` section directly before the closing `}` of the `SeedMigratorTests` struct:

```swift
    // MARK: - v8: cueStyle backfill

    @Test func v8BackfillsCueStyleBySeedID() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Shoulder Roll", type: .stretch,
            targetBodyParts: ["Left Shoulder"], durationSeconds: 30,
            difficulty: 1, instructions: ["a", "b", "c"]
        )
        exercise.seedID = "shoulder-roll-id"
        #expect(exercise.cueStyle == .hold)
        context.insert(exercise)
        try context.save()

        var raw = rawExercise(id: "shoulder-roll-id", name: "Shoulder Roll")
        raw["cueStyle"] = "repeat"
        let changed = SeedMigrator.migrateV8(context: context, rawExercises: [raw])
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].cueStyle == .repeatMotion)
    }

    @Test func v8IsNoOpWhenBundleCueStyleMatchesAlready() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Child's Pose", type: .stretch,
            targetBodyParts: ["Back"], durationSeconds: 45,
            difficulty: 1, instructions: ["a", "b", "c"], cueStyle: .hold
        )
        exercise.seedID = "childs-pose-id"
        context.insert(exercise)
        try context.save()

        var raw = rawExercise(id: "childs-pose-id", name: "Child's Pose")
        raw["cueStyle"] = "hold"
        let changed = SeedMigrator.migrateV8(context: context, rawExercises: [raw])
        #expect(!changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].cueStyle == .hold)
    }

    @Test func v8NeverTouchesUserCreatedExercises() throws {
        let context = makeContext()
        let custom = Exercise(
            name: "My Custom Move", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 30,
            difficulty: 1, instructions: ["x", "y", "z"]
        )
        context.insert(custom)   // no seedID
        try context.save()

        var raw = rawExercise(id: "seed-1", name: "Some Seed")
        raw["cueStyle"] = "repeat"
        let changed = SeedMigrator.migrateV8(context: context, rawExercises: [raw])
        #expect(!changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].cueStyle == .hold)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedMigratorTests"`
Expected: FAIL to build — `SeedMigrator.migrateV8` does not exist.

- [ ] **Step 3: Implement `SeedMigrator.migrateV8`**

In `Breath - Relax & Stretch/Services/SeedMigrator.swift`, add directly after `migrateV7` (before the struct's closing `}`):

```swift

    /// v8 — backfills `Exercise.cueStyle` onto already-seeded rows, matched by
    /// `seedID`. New installs already read `cueStyle` at insert time; this
    /// only matters for users seeded before the field existed. Parses the
    /// bundle's lowercase string via `ExerciseCueStyle(rawValue:)` on the
    /// capitalized string, same as the insert-time parsing.
    @discardableResult
    static func migrateV8(context: ModelContext, rawExercises: [[String: Any]]) -> Bool {
        var cueStyleBySeedID: [String: ExerciseCueStyle] = [:]
        for raw in rawExercises {
            guard let id = raw["id"] as? String,
                  let cueStyleStr = raw["cueStyle"] as? String,
                  let cueStyle = ExerciseCueStyle(rawValue: cueStyleStr.capitalized) else { continue }
            cueStyleBySeedID[id] = cueStyle
        }

        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in existing {
            guard let seedID = exercise.seedID,
                  let cueStyle = cueStyleBySeedID[seedID],
                  exercise.cueStyle != cueStyle else { continue }
            exercise.cueStyle = cueStyle
            changed = true
        }
        return changed
    }
```

- [ ] **Step 4: Read `cueStyle` at seed-insert time and wire the migration into the ladder**

In `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`, inside `seedIfNeeded()`, directly below the existing `let isBilateral = raw["isBilateral"] as? Bool ?? true` line, add:

```swift
            // Missing/unparseable key defaults to .hold via Exercise's own
            // inline default — every seed entry has a real value (Task 2),
            // this only guards a malformed bundle.
            let cueStyle = (raw["cueStyle"] as? String).flatMap { ExerciseCueStyle(rawValue: $0.capitalized) } ?? .hold
```

Then add `cueStyle: cueStyle` to the `Exercise(...)` initializer call directly below it, after `isBilateral: isBilateral`:

```swift
            let exercise = Exercise(
                uuid: Exercise.stableSeedUUID(forName: name),
                name: name, type: type, targetBodyParts: parts,
                durationSeconds: duration, difficulty: difficulty,
                instructions: instructions, mediaURL: mediaURL, caution: caution,
                isBilateral: isBilateral, cueStyle: cueStyle
            )
```

Next, add the migration wrapper. Directly after the existing `migrateSeedToV7IfNeeded()` method, add:

```swift

    private func migrateSeedToV8IfNeeded() {
        guard seedDataVersion < 8 else { return }
        if let rawExercises = loadSeedExercises() {
            let context = sharedModelContainer.mainContext
            if SeedMigrator.migrateV8(context: context, rawExercises: rawExercises) {
                try? context.save()
            }
        }
        seedDataVersion = 8
    }
```

Then add the call to `migrateSeedIfNeeded()`'s body, directly after `migrateSeedToV7IfNeeded()`:

```swift
    private func migrateSeedIfNeeded() {
        migrateSeedToV3IfNeeded()
        migrateSeedToV4IfNeeded()
        migrateSeedToV5IfNeeded()
        migrateSeedToV6IfNeeded()
        migrateSeedToV7IfNeeded()
        migrateSeedToV8IfNeeded()
    }
```

Do **not** change `private static let latestContentSeedVersion = 4` — this is a data-only migration (no new exercise content), same treatment as v5's `isBilateral` backfill.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/SeedMigratorTests"`
Expected: PASS (all `SeedMigratorTests`, including the 3 new v8 tests).

- [ ] **Step 6: Build the full app to catch any call-site issues**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift" "Breath - Relax & Stretch/Services/SeedMigrator.swift" "Breath - Relax & StretchTests/SeedMigratorTests.swift"
git commit -m "feat(seed): read cueStyle at insert time, add migrateV8 backfill"
```

---

### Task 4: Cue badge in `SessionPlayerView`

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`

**Interfaces:**
- Consumes: `Exercise.cueStyle: ExerciseCueStyle` (Task 1).
- Produces: a `cueBadge(for:)` view-builder method on `SessionPlayerView` — not consumed elsewhere, purely additive UI. Task 7's UITest queries it by accessibility label `"Exercise cue"`.

- [ ] **Step 1: Add the badge view**

In `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`, add a new `@State` property directly below the existing `@State private var breathTick = 0` line:

```swift
    @State private var cueBadgePulsing = false
```

In `playerContent(exercise:)`, insert the badge directly after the existing:

```swift
            Text(exercise.type.rawValue)
                .font(.luminaLabel)
                .textCase(.uppercase)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .padding(.top, 4)
```

add:

```swift

            cueBadge(for: exercise.cueStyle)
```

Then add the `cueBadge(for:)` view builder directly after `playerContent(exercise:)`'s closing `}` (before `getReadyView`):

```swift
    @ViewBuilder
    private func cueBadge(for cueStyle: ExerciseCueStyle) -> some View {
        Text(cueStyle == .hold ? "Hold" : "Keep Going")
            .font(.luminaLabel)
            .textCase(.uppercase)
            .foregroundStyle(Color.luminaPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.luminaMintTint, in: Capsule())
            .scaleEffect(cueStyle == .repeatMotion && cueBadgePulsing ? 1.07 : 1.0)
            .opacity(cueStyle == .repeatMotion && cueBadgePulsing ? 0.82 : 1.0)
            .padding(.top, 12)
            .accessibilityLabel("Exercise cue")
            .accessibilityValue(cueStyle == .hold ? "Hold" : "Keep going")
            .onAppear {
                guard cueStyle == .repeatMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    cueBadgePulsing = true
                }
            }
    }
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift"
git commit -m "feat(session): add hold/keep-going cue badge to the exercise player"
```

---

### Task 5: Cycling instruction cue text

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`

**Interfaces:**
- Consumes: `Exercise.instructions: [String]` (existing field, previously unused in this view).
- Produces: an `instructionCueIndex` `@State` var and `instructionCue(for:)` view builder — Task 6 reads the index-change moment to fire the reminder beep. Task 7's UITest queries the text by accessibility label `"Exercise instruction"`.

- [ ] **Step 1: Add cycling state and the view**

Add two new `@State` properties directly below `cueBadgePulsing` (from Task 4):

```swift
    @State private var instructionCueIndex = 0
    @State private var instructionCueTask: Task<Void, Never>? = nil
```

In `playerContent(exercise:)`, insert the instruction cue directly after the media block:

```swift
            if exercise.type != .breath {
                ExerciseMediaCard(exercise: exercise)
            } else {
                BreathingCircle(
                    isPaused: isPaused,
                    cycleDuration: breathingCycleDuration(for: exercise)
                )
                    .padding()
            }

            instructionCue(for: exercise)
```

(directly above the existing `Text(timeString(secondsRemaining))` countdown line — do not move the countdown).

Add the view builder directly after `cueBadge(for:)`'s closing `}`:

```swift
    @ViewBuilder
    private func instructionCue(for exercise: Exercise) -> some View {
        if !exercise.instructions.isEmpty {
            let index = min(instructionCueIndex, exercise.instructions.count - 1)
            Text(exercise.instructions[index])
                .id(index)
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity)
                        .animation(.easeOut(duration: 0.35)),
                    removal: .opacity
                        .animation(.easeIn(duration: 0.25))
                ))
                .accessibilityLabel("Exercise instruction")
                .accessibilityValue(exercise.instructions[index])
        }
    }
```

- [ ] **Step 2: Drive the cycling with a 3.5s timer, reset per exercise**

First, add the reminder-beep sound ID. Directly below the existing `private let soundComplete: SystemSoundID = 1016` line, add:

```swift
    private let soundCueBeep: SystemSoundID = 1103  // soft low tock — cue reminder
```

(Task 6 wires this same sound into three more call sites — start, side-switch, natural end. This task only fires it on each instruction pop-in.)

The instruction index must reset to `0` and start a fresh 3.5s cycling loop every time a new exercise begins, and stop when the session ends. `startExercise()` is the single place every exercise transition already funnels through — add the reset there. Directly below the existing line `if let exercise = currentExercise { VoiceCueService.shared.speak(exercise.name) }` inside `startExercise()`, add:

```swift
        instructionCueTask?.cancel()
        instructionCueIndex = 0
        if let count = currentExercise?.instructions.count, count > 1 {
            instructionCueTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3.5))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.35)) {
                        instructionCueIndex += 1
                    }
                    AudioServicesPlaySystemSound(soundCueBeep)
                }
            }
        }
```

The `withAnimation` wrapper is what makes SwiftUI treat the `instructionCueIndex` change as an animated transition at all; the per-side `.animation(...)` calls attached to the transition in Step 1 then override its duration/curve independently for the insertion (0.35s ease-out) and removal (0.25s ease-in) halves, so they don't just both inherit this same 0.35s ease-out.

Cancel the task on dismiss — in the existing `.onDisappear` closure, directly below `getReadyTask?.cancel()`, add:

```swift
            instructionCueTask?.cancel()
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift"
git commit -m "feat(session): cycle exercise instructions on screen during the exercise"
```

---

### Task 6: Cue reminder beep at start / side-switch / natural end

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift`

**Interfaces:**
- Consumes: `soundCueBeep: SystemSoundID` (declared in Task 5, directly below `soundComplete`) — Task 5 already fires it on each instruction pop-in; this task adds the remaining 3 of the 4 call sites.
- Produces: nothing new consumed elsewhere.

- [ ] **Step 1: Beep on exercise start**

In `startExercise()`, directly after the existing:

```swift
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
```

add:

```swift
        AudioServicesPlaySystemSound(soundCueBeep)
```

- [ ] **Step 2: Beep on side switch**

In `checkSideSwitch()`, directly after the existing `VoiceCueService.shared.speak("Switch sides")` line, add:

```swift
        AudioServicesPlaySystemSound(soundCueBeep)
```

- [ ] **Step 3: Beep on natural exercise end (not manual skip)**

In the `.task` countdown loop, find:

```swift
                if remaining > 0 {
                    secondsRemaining = remaining
                    checkSideSwitch()
                    breathTick += 1
                    if breathTick % 4 == 0 { AudioServicesPlaySystemSound(soundTick) }
                } else {
                    advanceToNext(completion: 1.0)
                }
```

Change the `else` branch to:

```swift
                } else {
                    AudioServicesPlaySystemSound(soundCueBeep)
                    advanceToNext(completion: 1.0)
                }
```

Leave the skip button's handler (`Button { ... advanceToNext(completion: skipCompletion()) }`) untouched — it must not gain this beep.

- [ ] **Step 4: Build to verify it compiles**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Session/SessionPlayerView.swift"
git commit -m "feat(session): add cue reminder beep on start, switch, and natural end"
```

---

### Task 7: Simulator verification (UITest + manual screenshot check)

**Files:**
- Create: `Breath - Relax & StretchUITests/ExerciseSessionCueUITest.swift`

**Interfaces:**
- Consumes: nothing from app code directly — drives the app as a black box via `XCUIApplication()`, per `.claude/skills/verify/SKILL.md`.
- Produces: nothing consumed by later tasks — this is the terminal verification task.

- [ ] **Step 1: Write the UITest**

Create `Breath - Relax & StretchUITests/ExerciseSessionCueUITest.swift`:

```swift
import XCTest

final class ExerciseSessionCueUITest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Starts a session and confirms both the cue badge and the instruction
    /// text render during the first exercise. Per the repo's `verify` skill,
    /// elements with an explicit combined `.accessibilityLabel` are queried
    /// by that label via `descendants`, not by the raw displayed text.
    func testCueBadgeAndInstructionAppearDuringExercise() throws {
        let app = XCUIApplication()
        app.launch()

        let beginButton = app.buttons["Begin"]
        if beginButton.waitForExistence(timeout: 5) {
            beginButton.tap()
        }

        let cueBadge = app.descendants(matching: .any)["Exercise cue"]
        XCTAssertTrue(cueBadge.waitForExistence(timeout: 8), "Cue badge should appear during the exercise")

        let instruction = app.descendants(matching: .any)["Exercise instruction"]
        XCTAssertTrue(instruction.exists, "Instruction cue should appear alongside the badge")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        screenshot.name = "01-exercise-with-cues"
        add(screenshot)
    }
}
```

- [ ] **Step 2: Run the UITest and export screenshots**

Run:
```bash
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/ExerciseSessionCueUITest" -resultBundlePath /tmp/exercise-cue-verify.xcresult
```
Expected: `Test case '-[ExerciseSessionCueUITest testCueBadgeAndInstructionAppearDuringExercise]' passed`.

If `/tmp/exercise-cue-verify.xcresult` already exists from a prior run, `rm -rf` it first.

Then export and inspect the screenshot:
```bash
xcrun xcresulttool export attachments --path /tmp/exercise-cue-verify.xcresult --output-path /tmp/exercise-cue-verify-screens
```
Read `01-exercise-with-cues.png` (via the manifest's `suggestedHumanReadableName`) and confirm visually: the "Hold" or "Keep Going" badge sits under the exercise name/type, and an instruction line is visible between the media and the countdown, styled per `docs/mockups/exercise-session-cue-badges.html`.

- [ ] **Step 3: Manual audio spot-check**

Beeps are audio-only and not screenshot-verifiable. Launch the app in the simulator (Cmd+R or via the `verify` skill), start any session, and listen for: a beep when the exercise begins, a beep roughly every 3.5s as the instruction text changes, and a beep when the exercise's countdown reaches zero and it auto-advances (not when using the skip button). If a unilateral exercise is available in the session, confirm the existing "switch sides" voice cue now also has a beep. Report any case where `1103` sounds jarring or hard to distinguish — swap the `SystemSoundID` if so (see spec §3, this is a listen-and-adjust value).

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & StretchUITests/ExerciseSessionCueUITest.swift"
git commit -m "test(session): UITest verifying cue badge and instruction text render"
```
