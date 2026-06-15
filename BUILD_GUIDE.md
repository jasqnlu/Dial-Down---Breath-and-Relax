# Breath: Relax & Stretch — Build Guide

## GitHub Status
Project is now connected to: https://github.com/jasqnlu/Breath-Relax-Stretch

---

## Honest Assessment

### What's great
- 3-layer body visualization (Skin → Muscle → Skeleton) is genuinely novel
- "Borrow a pose and build your own routine" is a smart community hook
- Gamification (points, minutes, badges) adds retention without being gimmicky
- Breathing + stretching combo is well-timed with the wellness market

### What needs more thought
- **Body part hit detection** is the hardest technical problem — SVG or SpriteKit body maps with tappable zones take time to build right
- **Content is a major dependency** — you need a library of exercises before the app is useful (start with 20 solid stretches)
- **The "slime highlight" effect** needs a design spec — what gets highlighted? Just the muscle group, or connected groups too?
- **iOS only** to start — don't try to support macOS until v2
- **Backend scope** — start with Supabase, don't over-engineer before you have users

---

## Step-by-Step Build Plan

### PHASE 0 — Setup

#### Step 1: Clean up the Xcode template
The current `ContentView.swift` and `Item.swift` are boilerplate — delete them and start fresh. Also fix the broken app name in `Breath__Relax___StretchApp.swift` (the `___PACKAGENAME:identifier___` template variable didn't render properly).

#### Step 2: Fix .gitignore
Already done — xcuserstate, DerivedData, .DS_Store are now excluded.

---

### PHASE 1 — Core Data Models (Week 1)

**BodyPart.swift**
```swift
@Model class BodyPart {
    var id: UUID
    var name: String               // "Hamstring", "Quadricep"
    var layer: BodyLayer           // .skin, .muscle, .skeleton
    var group: String              // "Leg", "Back", "Arm"
    var svgPathID: String          // matches SVG element ID for highlighting
    var connectedParts: [String]   // related body part names
}

enum BodyLayer: String, Codable {
    case skin, muscle, skeleton
}
```

**Exercise.swift**
```swift
@Model class Exercise {
    var id: UUID
    var name: String
    var type: ExerciseType         // .stretch, .breath, .both
    var targetBodyParts: [String]
    var durationSeconds: Int
    var difficulty: Int            // 1–3
    var instructions: [String]
    var mediaURL: String?
}
```

**Routine.swift**
```swift
@Model class Routine {
    var id: UUID
    var name: String
    var poses: [Exercise]
    var authorID: String?
    var borrowedFromID: UUID?      // tracks "fork" origin
    var isPublic: Bool
    var totalDuration: Int
}
```

**Session.swift**
```swift
@Model class Session {
    var id: UUID
    var routineID: UUID
    var startedAt: Date
    var completedAt: Date?
    var completionPercent: Double
    var pointsEarned: Int
}
```

**UserProfile.swift**
```swift
@Model class UserProfile {
    var id: String
    var displayName: String
    var totalMinutes: Int
    var totalPoints: Int
    var streak: Int
    var lastSessionDate: Date?
    var badges: [String]
}
```

---

### PHASE 2 — Body Map UI (Week 2–3)

Use an SVG of a human body with named paths per muscle/region. Load in a WKWebView or convert paths to SwiftUI Shapes. On tap, identify the path ID → look up BodyPart → highlight connected parts.

**Layer switching:**
```swift
@State var currentLayer: BodyLayer = .skin

withAnimation(.easeInOut(duration: 0.4)) {
    currentLayer = .muscle
}
```

**Highlight effect ("slime glow"):**
```swift
.overlay(Color.green.opacity(isHighlighted ? 0.5 : 0))
.animation(.easeInOut(duration: 0.3), value: isHighlighted)
```

---

### PHASE 3 — Exercise & Routine Browser (Week 3–4)

Screens to build:
- `ExerciseListView` — searchable, filterable by body part / duration / type
- `ExerciseDetailView` — instructions, body map highlight, start button
- `RoutineListView` — your routines + public/borrowed routines
- `RoutineBuilderView` — drag to reorder poses, add/remove exercises
- `BorrowRoutineView` — browse public routines, tap to fork

---

### PHASE 4 — Session Player (Week 4–5)

The in-session experience: step through exercises one at a time.

Show: current exercise + body map highlight, countdown timer, progress bar, breathing guide (animated circle), Next/Skip buttons, points summary on finish.

```swift
@State var secondsRemaining: Int = exercise.durationSeconds
let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

.onReceive(timer) { _ in
    if secondsRemaining > 0 {
        secondsRemaining -= 1
    } else {
        advanceToNextExercise()
    }
}
```

---

### PHASE 5 — Gamification (Week 5)

**Points formula:**
```
points = baseDuration(min) × difficultyMultiplier × completionBonus
difficultyMultiplier: easy=1.0, medium=1.5, hard=2.0
completionBonus: 100%=×1.2, 75%+=×1.0, <75%=×0.7
```

**Starter badges:**
| Badge | Trigger |
|---|---|
| First Breath | Complete first session |
| Streak Starter | 3-day streak |
| Full Body | Hit all major muscle groups in one session |
| Routine Builder | Create your first custom routine |
| Borrowed & Built | Fork a public routine and complete it |

---

### PHASE 6 — Backend with Supabase (Week 6–7)

Use Supabase — free tier is generous and has a great Swift SDK.

```
https://github.com/supabase/supabase-swift
```

Tables: `users`, `exercises`, `routines`, `sessions`

Use Supabase Auth with Sign in with Apple (required for App Store if you offer any social login).

Strategy: store everything locally in SwiftData first, sync to Supabase in the background. Offline-first feels snappier.

---

### PHASE 7 — Polish & App Store Prep (Week 8)

- Haptic feedback on exercise transitions (`UIImpactFeedbackGenerator`)
- Sound: ambient background + completion chime (`AVAudioPlayer`)
- Dark mode support
- Accessibility: VoiceOver labels on all body map regions
- App icon + App Store screenshots
- TestFlight beta → gather feedback → iterate

---

## Recommended File Structure

```
Breath: Relax & Stretch/
├── Models/
│   ├── BodyPart.swift
│   ├── Exercise.swift
│   ├── Routine.swift
│   ├── Session.swift
│   └── UserProfile.swift
├── Views/
│   ├── Home/HomeView.swift
│   ├── BodyMap/BodyMapView.swift
│   ├── Exercises/ExerciseListView.swift
│   ├── Routines/RoutineListView.swift
│   ├── Session/SessionPlayerView.swift
│   └── Profile/ProfileView.swift
├── Services/
│   ├── SupabaseService.swift
│   └── GamificationService.swift
└── Resources/
    ├── BodyMap.svg
    └── SeedData.json
```

---

## Priority Order

1. ✅ Push to GitHub
2. Fix app template / clean boilerplate
3. Data models (SwiftData)
4. Body map with layer switching + tap highlighting
5. Seed 20 exercises manually
6. Session player (the core loop)
7. Gamification (points + badges)
8. Routine builder + borrow feature
9. Supabase backend + auth
10. Polish + App Store
