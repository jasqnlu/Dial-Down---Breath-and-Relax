# Onboarding Survey + Facts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bend-style onboarding for new users: survey questions interleaved with stretching-fact cards; answers personalize the app (pre-marked body areas, reminder time, Today recommendations).

**Architecture:** A `SurveyModel` value type holds questions/answers and persistence; two reusable page views (`SurveyQuestionPage`, `FactCardPage`) slot into the existing `OnboardingView` `TabView` pager. Answers write to `@AppStorage` keys + pre-mark `MuscleMarkStore`.

**Tech Stack:** SwiftUI, `@AppStorage`, Swift Testing.

## Global Constraints

- Branch: `feature/onboarding-survey`, cut from `feature/bodymap-3d-marking` (uses `MuscleMarkStore` + `MuscleGroup` for problem-area pre-marking).
- New users only: gated by existing `hasCompletedOnboarding`; no change for completed installs.
- Facts are static, no network; every fact carries a real citation line.
- Test command: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`

---

### Task 1: Survey model + fact content

**Files:**
- Create: `Views/Onboarding/SurveyModel.swift`
- Test: `Breath - Relax & StretchTests/SurveyModelTests.swift`

**Interfaces:**
- Produces:

```swift
struct SurveyQuestion: Identifiable {
    let id: String                 // stable key, e.g. "goal"
    let prompt: String
    let options: [String]
    let multiSelect: Bool
}

struct StretchFact: Identifiable {
    let id: String
    let headline: String           // e.g. "10 minutes is enough"
    let body: String
    let citation: String           // e.g. "Journal of Physiology, 2018"
    let sfSymbol: String
}

enum OnboardingSurvey {
    static let questions: [SurveyQuestion]   // goal, problemAreas, flexibility, frequency, preferredTime
    static let facts: [StretchFact]          // ≥5 entries
    /// Problem-area option label → MuscleGroup rawValues to pre-mark.
    static let problemAreaMap: [String: [String]]
}
```

- [ ] **Step 1: Failing tests**

```swift
import Testing
@testable import BreathRelaxStretch

struct SurveyModelTests {
    @Test func fiveQuestionsWithStableIDs() {
        let ids = OnboardingSurvey.questions.map(\.id)
        #expect(ids == ["goal", "problemAreas", "flexibility", "frequency", "preferredTime"])
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyQuestionHasTwoToSixOptions() {
        for q in OnboardingSurvey.questions {
            #expect((2...8).contains(q.options.count), "\(q.id)")
        }
    }

    @Test func factsHaveCitations() {
        #expect(OnboardingSurvey.facts.count >= 5)
        for f in OnboardingSurvey.facts {
            #expect(!f.citation.isEmpty)
            #expect(!f.headline.isEmpty)
        }
    }

    @Test func problemAreaMapCoversAllOptionsWithValidGroups() {
        let q = OnboardingSurvey.questions.first { $0.id == "problemAreas" }!
        for option in q.options {
            let groups = OnboardingSurvey.problemAreaMap[option]
            #expect(groups != nil, "\(option) unmapped")
            if option != "Nothing specific" {
                #expect(groups?.isEmpty == false, "\(option) empty")
            }
            for g in groups ?? [] {
                #expect(MuscleGroup(rawValue: g) != nil, "\(g) invalid")
            }
        }
    }
}
```

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Implement.** Content to write verbatim:
  - **goal** (single): Improve flexibility / Ease pain & tightness / Reduce stress / Better posture / Sleep better
  - **problemAreas** (multi): Neck & shoulders / Lower back / Hips / Hamstrings / Knees & calves / Wrists & forearms / Nothing specific — with `problemAreaMap` e.g. `"Neck & shoulders": ["Front Neck", "Back Neck", "Left Trapezius", "Right Trapezius"]`, `"Lower back": ["Lower Back", "Spinal Erectors"]`, `"Hips": ["Left Hip Flexors", "Right Hip Flexors", "Left Glutes", "Right Glutes"]`, `"Hamstrings": ["Left Hamstrings", "Right Hamstrings"]`, `"Knees & calves": ["Left Quadriceps", "Right Quadriceps", "Left Calves", "Right Calves"]`, `"Wrists & forearms": ["Left Forearm", "Right Forearm"]`, `"Nothing specific": []` (the test above already allows this one to be empty).
  - **flexibility** (single): Can't touch my toes / Fingertips to toes / Palms to floor / Not sure
  - **frequency** (single): Never / Occasionally / Few times a week / Daily
  - **preferredTime** (single): Morning / Midday / Evening / Varies
  - **facts** (5, real literature): ① "10 minutes a day is enough" — regular short static-stretch sessions measurably improve range of motion within 4–8 weeks (cite: Thomas et al., *Int J Sports Med*, 2018). ② "Stretching lowers stress" — slow stretching activates the parasympathetic nervous system, reducing heart rate (cite: Inami et al., *Int J Sports Med*, 2014). ③ "Desk workers lose hip mobility" — prolonged sitting shortens hip flexors; regular stretching counteracts it (cite: *J Phys Ther Sci*, 2015). ④ "Stretching before bed improves sleep quality" — low-intensity stretching improved sleep in adults with poor sleep (cite: D'Aurea et al., *Sleep Sci*, 2018). ⑤ "Flexibility protects against injury-related pain" — hamstring flexibility correlates with lower back-pain incidence (cite: *J Back Musculoskelet Rehabil*, 2017).

- [ ] **Step 4: Run — PASS. Commit** `git commit -m "feat: onboarding survey model + stretching facts content"`

---

### Task 2: Survey + fact pages, wired into the pager

**Files:**
- Create: `Views/Onboarding/SurveyQuestionPage.swift`, `Views/Onboarding/FactCardPage.swift`
- Modify: `Views/Onboarding/OnboardingView.swift`
- Delete: `Views/Onboarding/GoalPickerPage.swift` (superseded by the goal survey question)

**Interfaces:**
- `SurveyQuestionPage(question: SurveyQuestion, selection: Binding<Set<String>>, onContinue: () -> Void)` — option chips (single-select auto-advances after 0.25s; multi-select shows Continue).
- `FactCardPage(fact: StretchFact)` — full-screen: large SF symbol, headline (`.largeTitle.bold()` to match existing pages), body, citation footnote.
- OnboardingView page order: Welcome(0) → goal(1) → fact ①(2) → problemAreas(3) → fact ②(4) → flexibility(5) → fact ④(6) → frequency(7) → preferredTime(8) → Gender(9) → BodyMapIntro(10) → Notifications(11, completes). `totalPages = 12`. Facts ③/⑤ reserved for future paywall/Today use.
- Persistence on completion (`completeOnboarding()`): `@AppStorage("surveyGoal")`, `("surveyFlexibility")`, `("surveyFrequency")`, `("surveyPreferredTime")` as raw option strings; `("onboardingGoals")` kept in sync with goal for existing Today-view logic; problem areas → `MuscleMarkStore().mark(_:colorID:"tension")` for each mapped group (`OnboardingSurvey.problemAreaMap`).
- Preferred time pre-fills the `NotificationsPage` suggested reminder hour: Morning=8, Midday=12, Evening=19, Varies=9 — pass as `suggestedHour: Int` parameter (check NotificationsPage's current API and thread it through).

- [ ] **Step 1:** Build both page views (chip style: capsule, `Color.accentColor` fill when selected — mirror `patternCard` styling conventions).
- [ ] **Step 2:** Rewire `OnboardingView` (survey answers as `@State var answers: [String: Set<String>]`, persisted in `completeOnboarding`).
- [ ] **Step 3:** Full suite + build — green.
- [ ] **Step 4:** Simulator run with onboarding reset (`-hasCompletedOnboarding NO` via UserDefaults launch args if supported, else delete app first): screenshot each new page; verify body map shows pre-marked areas after completing with "Neck & shoulders" selected.
- [ ] **Step 5: Commit** `git commit -m "feat: survey + facts onboarding flow"`
