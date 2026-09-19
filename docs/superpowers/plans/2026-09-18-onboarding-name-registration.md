# Onboarding Showcase, Name Capture & Supabase Registration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fresh installs see a feature showcase before sign-in; every non-guest account supplies a first and last name; an account with no named `profiles` row in Supabase replays the name step and coach-mark tour.

**Architecture:** A pure routing function (`RegistrationRouting`) decides "registered vs needs name" from a remote lookup plus local state. A `@MainActor RegistrationCoordinator` runs the lookup (with a session wait and a timeout) and uploads the name. A `RegistrationGate` view, mounted where `RootView` currently shows `HomeView`, drives `NameEntryView` / a spinner / Home. The tour flag becomes per-account. Onboarding gains three static-screenshot showcase pages ahead of the existing pages.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing (`import Testing`, module `BreathRelaxStretch`), Supabase REST (PostgREST) via `SupabaseService` (an `actor`), XCUITest for screenshots/verification.

**Spec:** `docs/superpowers/specs/2026-09-18-onboarding-name-registration-design.md`

## Global Constraints

- Test framework is **Swift Testing**, not XCTest. Test files go in `Breath - Relax & StretchTests/`; both targets are `PBXFileSystemSynchronizedRootGroup`, so new `.swift` files need **no pbxproj edits**.
- Unit test command (run from repo root; substitute the suite name):
  `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests/<SuiteName>"`
- Build command: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17'`
- Pre-existing failures that are **not regressions**: `CuratedContentIntegrityTests` and the UITest-runner failures.
- "Registered" = a Supabase `profiles` row for the auth uid with non-empty `first_name` AND `last_name`.
- `AuthManager.displayName` stays as the composed `"First Last"` so existing screens keep working.
- The `TodayView` greeting uses the first name only (`"Good morning, First"`).
- `profiles.first_name` / `last_name` are **nullable** (existing rows must stay valid).
- Showcase pages are **skippable**. Showcase screenshots are captured from the app itself.
- Guests get no name step and no registration check, but **still get the tour once**.
- `hasCompletedOnboarding` stays device-level; sign-out must not clear it.
- Never use `git commit -- <paths>` (it re-adds working-tree content). Use `git add <paths>` then plain `git commit`.
- Every commit message ends with the trailer `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`; commit with `git commit -m "<subject>" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"`.
- Never put a `@FocusState` `TextField` inside a `NavigationStack` `.toolbar`; host fields in content.
- The app is dark-only; use the existing `luminaSurface`, `luminaContainer`, `luminaPrimary`, `luminaTitle`, `luminaSubheadline`, `LuminaPillButtonStyle`, `LuminaRadius.tag` styling tokens.
- After all code changes: `graphify update .` from the repo root.
- **Actor-isolation contingency:** the project may use default `@MainActor` isolation (existing code notes `RemoteProfile.encode` is `@MainActor`). If a compile error says a new type's member is main-actor isolated when used from a nonisolated/actor context, prefix that type with `nonisolated` (e.g. `nonisolated struct PersonName`). Task 1 Step 3 checks this up front.

## Decision required before Task 4 (privacy)

`profiles` is publicly readable (`using (true)`), and the leaderboard already shows `display_name`. Under this plan `display_name` becomes the full `"First Last"` and `first_name`/`last_name` are stored in the same public table, so **last names become publicly readable via the anon key**. Alternatives: (a) accept it (spec as written); (b) store `display_name` as `"First L."` (public-safe) while keeping full names in a private table; (c) same as (b) but keep first/last only locally. This plan implements (a). **Ask the user to confirm (a) before applying the Task 4 migration.**

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `Breath - Relax & Stretch/Models/PersonName.swift` | Create | Value type: trimmed/clamped first+last, `isComplete`, `fullName`, `split(fullName:)` |
| `Breath - Relax & Stretch/Services/RegistrationRouting.swift` | Create | Pure `resolve(lookup:local:providerPrefill:)` -> `RegistrationOutcome` |
| `Breath - Relax & Stretch/Services/RegistrationCoordinator.swift` | Create | Runs lookup (session wait + timeout), backfill, `completeName`; publishes `State` |
| `Breath - Relax & Stretch/Services/SupabaseDTOs.swift` | Modify | `RemoteProfile` gains optional `firstName`/`lastName`; new `RemoteProfileName` |
| `Breath - Relax & Stretch/Services/SupabaseService.swift` | Modify | `fetchProfile`, `upsertProfileName`, `SupabaseProfileStoring`; drop `name` from `signUpWithPassword` |
| `Breath - Relax & Stretch/Services/AuthManager.swift` | Modify | `firstName`/`lastName`, `setName`, `providerPrefill`, `greetingName`, `signUp(email:password:)` |
| `Breath - Relax & Stretch/Views/Onboarding/AppGuideSeen.swift` | Create | Per-account tour-seen flag + legacy migration for guests |
| `Breath - Relax & Stretch/Views/Auth/NameEntryView.swift` | Create | First/last name form |
| `Breath - Relax & Stretch/Views/Auth/RegistrationGate.swift` | Create | Drives checking/name/home; starts the tour |
| `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift` | Modify | `RootView`: mount gate, sync `UserProfile.displayName` |
| `Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift` | Modify | Remove global tour auto-start; add showcase pages + Skip |
| `Breath - Relax & Stretch/Views/Onboarding/ShowcasePage.swift` | Create | Screenshot + title + subtitle page |
| `Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift` | Modify | Remove name field |
| `Breath - Relax & Stretch/Views/Home/TodayView.swift` | Modify | Greeting uses `auth.greetingName` |
| `Breath - Relax & Stretch/Assets.xcassets/showcase-*.imageset` | Create | 3 showcase screenshots |
| `supabase_schema.sql` | Modify | `first_name`/`last_name` columns |
| `Breath - Relax & StretchTests/*` | Create/Modify | `PersonNameTests`, `RegistrationRoutingTests`, `RegistrationCoordinatorTests`, `AppGuideSeenTests`, edits to `SupabaseServiceTests`, `AuthManagerTests` |
| `Breath - Relax & StretchUITests/ShowcaseScreenshotUITests.swift`, `RegistrationFlowUITests.swift` | Create | Screenshot capture; flow verification |

---

### Task 0: Implementation branch

- [ ] **Step 1: Commit this plan on `main`, then branch**

```bash
cd "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
git add docs/superpowers/plans/2026-09-18-onboarding-name-registration.md
git commit -m "docs(plan): onboarding showcase, name capture, registration" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
git checkout -b feature/onboarding-name-registration
```

Expected: on branch `feature/onboarding-name-registration`, clean tree.

---

### Task 1: `PersonName` value type

**Files:**
- Create: `Breath - Relax & Stretch/Models/PersonName.swift`
- Test: `Breath - Relax & StretchTests/PersonNameTests.swift`

**Interfaces:**
- Produces: `struct PersonName: Equatable, Sendable` with `init(first:last:)` (trims whitespace, clamps each part to 35 chars), `static let empty`, `static let maxComponentLength = 35`, `var isComplete: Bool`, `var fullName: String`, `static func split(fullName: String) -> PersonName` (returns `.empty` for placeholder names `""`, `"user"`, `"guest"`, `"apple user"`).

- [ ] **Step 1: Write the failing test**

Create `Breath - Relax & StretchTests/PersonNameTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

@MainActor
struct PersonNameTests {

    @Test func initTrimsWhitespace() {
        let name = PersonName(first: "  Ada ", last: "\nLovelace  ")
        #expect(name.first == "Ada")
        #expect(name.last == "Lovelace")
    }

    @Test func initClampsEachPartToTheMaxLength() {
        let long = String(repeating: "a", count: 60)
        let name = PersonName(first: long, last: long)
        #expect(name.first.count == PersonName.maxComponentLength)
        #expect(name.last.count == PersonName.maxComponentLength)
    }

    @Test func isCompleteNeedsBothParts() {
        #expect(PersonName(first: "Ada", last: "Lovelace").isComplete)
        #expect(!PersonName(first: "Ada", last: "").isComplete)
        #expect(!PersonName(first: "", last: "Lovelace").isComplete)
        #expect(!PersonName(first: "  ", last: "  ").isComplete)
    }

    @Test func fullNameJoinsNonEmptyPartsWithASpace() {
        #expect(PersonName(first: "Ada", last: "Lovelace").fullName == "Ada Lovelace")
        #expect(PersonName(first: "Ada", last: "").fullName == "Ada")
        #expect(PersonName.empty.fullName == "")
    }

    @Test func splitTakesTheFirstWordAsFirstAndTheRestAsLast() {
        #expect(PersonName.split(fullName: "Ada Lovelace") == PersonName(first: "Ada", last: "Lovelace"))
        #expect(PersonName.split(fullName: "Ada Byron King") == PersonName(first: "Ada", last: "Byron King"))
        #expect(PersonName.split(fullName: "Ada") == PersonName(first: "Ada", last: ""))
    }

    @Test func splitIgnoresPlaceholderNames() {
        #expect(PersonName.split(fullName: "") == .empty)
        #expect(PersonName.split(fullName: "Apple User") == .empty)
        #expect(PersonName.split(fullName: "guest") == .empty)
        #expect(PersonName.split(fullName: "User") == .empty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run the unit test command with `-only-testing:"Breath - Relax & StretchTests/PersonNameTests"`.
Expected: build FAIL, `cannot find 'PersonName' in scope`.

- [ ] **Step 3: Check default actor isolation, then implement**

Run: `grep -n "SWIFT_DEFAULT_ACTOR_ISOLATION" "Breath - Relax & Stretch.xcodeproj/project.pbxproj" | head -3`
If it prints `MainActor`, declare the type as `nonisolated struct PersonName` (below); otherwise plain `struct` also works, and `nonisolated` is harmless. Use `nonisolated` either way.

Create `Breath - Relax & Stretch/Models/PersonName.swift`:

```swift
import Foundation

/// A person's first + last name as collected by the name step. Parts are
/// trimmed and clamped so they always fit the `profiles` column limits
/// (display_name <= 80, so 35 + 1 + 35 = 71).
nonisolated struct PersonName: Equatable, Sendable {
    static let maxComponentLength = 35
    static let empty = PersonName(first: "", last: "")

    /// Provider-supplied stand-ins that must never prefill the name step.
    private static let placeholders: Set<String> = ["", "user", "guest", "apple user"]

    let first: String
    let last: String

    init(first: String, last: String) {
        self.first = Self.clean(first)
        self.last = Self.clean(last)
    }

    var isComplete: Bool { !first.isEmpty && !last.isEmpty }

    var fullName: String {
        [first, last].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Best-effort split of a single display string: first word is the first
    /// name, the remainder is the last name. Placeholder names give `.empty`.
    static func split(fullName: String) -> PersonName {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !placeholders.contains(trimmed.lowercased()) else { return .empty }
        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let head = parts.first else { return .empty }
        return PersonName(first: String(head), last: parts.count > 1 ? String(parts[1]) : "")
    }

    private static func clean(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxComponentLength))
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Same command as Step 2. Expected: all 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Models/PersonName.swift" "Breath - Relax & StretchTests/PersonNameTests.swift"
git commit -m "feat(auth): add PersonName value type" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: Pure registration routing

**Files:**
- Create: `Breath - Relax & Stretch/Services/RegistrationRouting.swift`
- Test: `Breath - Relax & StretchTests/RegistrationRoutingTests.swift`

**Interfaces:**
- Consumes: `PersonName` (Task 1).
- Produces:
  - `enum RemoteProfileLookup: Equatable, Sendable { case named(PersonName); case notRegistered(rowPrefill: PersonName); case unavailable }`
  - `enum RegistrationOutcome: Equatable, Sendable { case registered(name: PersonName, backfillRemote: Bool); case needsName(prefill: PersonName) }`
  - `enum RegistrationRouting { static func resolve(lookup: RemoteProfileLookup, local: PersonName, providerPrefill: PersonName) -> RegistrationOutcome }`

- [ ] **Step 1: Write the failing test**

Create `Breath - Relax & StretchTests/RegistrationRoutingTests.swift`:

```swift
import Testing
@testable import BreathRelaxStretch

@MainActor
struct RegistrationRoutingTests {
    private let ada = PersonName(first: "Ada", last: "Lovelace")
    private let grace = PersonName(first: "Grace", last: "Hopper")

    @Test func namedRemoteRowMeansRegisteredWithTheRemoteName() {
        let outcome = RegistrationRouting.resolve(lookup: .named(ada), local: .empty, providerPrefill: grace)
        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func remoteNameWinsOverADifferentLocalName() {
        let outcome = RegistrationRouting.resolve(lookup: .named(ada), local: grace, providerPrefill: .empty)
        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func noRemoteRowButCompleteLocalNameIsRegisteredAndBackfills() {
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: .empty), local: ada, providerPrefill: .empty)
        #expect(outcome == .registered(name: ada, backfillRemote: true))
    }

    @Test func noRemoteRowAndNoLocalNameNeedsNamePrefilledFromTheRow() {
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: grace), local: .empty, providerPrefill: ada)
        #expect(outcome == .needsName(prefill: grace))
    }

    @Test func noRemoteRowAndNoLocalNameFallsBackToTheProviderPrefill() {
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: .empty), local: .empty, providerPrefill: ada)
        #expect(outcome == .needsName(prefill: ada))
    }

    @Test func incompleteLocalNameDoesNotCountAsRegistered() {
        let partial = PersonName(first: "Ada", last: "")
        let outcome = RegistrationRouting.resolve(lookup: .notRegistered(rowPrefill: .empty), local: partial, providerPrefill: .empty)
        #expect(outcome == .needsName(prefill: .empty))
    }

    @Test func unavailableLookupWithLocalNameIsRegisteredWithoutBackfill() {
        let outcome = RegistrationRouting.resolve(lookup: .unavailable, local: ada, providerPrefill: .empty)
        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func unavailableLookupWithoutLocalNameNeedsNameWithProviderPrefill() {
        let outcome = RegistrationRouting.resolve(lookup: .unavailable, local: .empty, providerPrefill: grace)
        #expect(outcome == .needsName(prefill: grace))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run with `-only-testing:"Breath - Relax & StretchTests/RegistrationRoutingTests"`.
Expected: build FAIL, `cannot find 'RegistrationRouting' in scope`.

- [ ] **Step 3: Write minimal implementation**

Create `Breath - Relax & Stretch/Services/RegistrationRouting.swift`:

```swift
import Foundation

/// What the `profiles` lookup for the signed-in account found.
nonisolated enum RemoteProfileLookup: Equatable, Sendable {
    /// A row exists with a complete first + last name.
    case named(PersonName)
    /// No row, or a row without a complete name. `rowPrefill` is the row's
    /// `display_name` split into parts (empty when there was no row).
    case notRegistered(rowPrefill: PersonName)
    /// Offline, timed out, or the backend errored — the answer is unknown.
    case unavailable
}

nonisolated enum RegistrationOutcome: Equatable, Sendable {
    /// Skip the name step. `backfillRemote` means the row is confirmed missing
    /// but a complete local name exists, so upload it best-effort.
    case registered(name: PersonName, backfillRemote: Bool)
    case needsName(prefill: PersonName)
}

nonisolated enum RegistrationRouting {
    static func resolve(
        lookup: RemoteProfileLookup,
        local: PersonName,
        providerPrefill: PersonName
    ) -> RegistrationOutcome {
        switch lookup {
        case .named(let remote):
            return .registered(name: remote, backfillRemote: false)
        case .notRegistered(let rowPrefill):
            if local.isComplete { return .registered(name: local, backfillRemote: true) }
            return .needsName(prefill: rowPrefill == .empty ? providerPrefill : rowPrefill)
        case .unavailable:
            // Unknown remote state: trust a complete local name so a flaky
            // connection never forces re-onboarding, but never overwrite the
            // remote row from here.
            if local.isComplete { return .registered(name: local, backfillRemote: false) }
            return .needsName(prefill: providerPrefill)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Same command. Expected: all 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/RegistrationRouting.swift" "Breath - Relax & StretchTests/RegistrationRoutingTests.swift"
git commit -m "feat(auth): pure registration routing decision" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: `profiles` name fields in the DTO and `SupabaseService`

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SupabaseDTOs.swift:28-46` (`RemoteProfile`)
- Modify: `Breath - Relax & Stretch/Services/SupabaseService.swift` (add methods after `fetchLeaderboard`, ~line 240; add protocol after `SupabaseAuthenticating`, ~line 503)
- Test: `Breath - Relax & StretchTests/SupabaseServiceTests.swift`

**Interfaces:**
- Consumes: `PersonName` (Task 1).
- Produces:
  - `RemoteProfile.firstName: String?`, `RemoteProfile.lastName: String?` (declared `var … = nil`, so existing memberwise calls still compile; `nil` is omitted on encode so session uploads never wipe names).
  - `struct RemoteProfileName: Codable, Sendable` (`id`, `displayName`, `firstName`, `lastName`).
  - `SupabaseService.fetchProfile(id: String) async throws -> RemoteProfile?`
  - `SupabaseService.upsertProfileName(id: String, name: PersonName) async throws`
  - `protocol SupabaseProfileStoring: Sendable` with those two methods; `extension SupabaseService: SupabaseProfileStoring {}`.

- [ ] **Step 1: Extend the test fake to record requests, then write failing tests**

In `SupabaseServiceTests.swift`, modify `FakeHTTPSession` to record requests. Replace its stored properties and `data(for:)` body's first lines:

```swift
private final class FakeHTTPSession: SupabaseHTTPSession, @unchecked Sendable {
    enum Canned {
        case success(status: Int, body: Data)
    }
    private var responses: [Canned]
    private var recorded: [URLRequest] = []
    private let lock = NSLock()

    var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return recorded
    }

    init(responses: [Canned]) { self.responses = responses }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        recorded.append(request)
        guard !responses.isEmpty else {
            lock.unlock()
            throw URLError(.unknown)
        }
        let next = responses.removeFirst()
        lock.unlock()
        switch next {
        case .success(let status, let body):
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status,
                httpVersion: nil, headerFields: nil
            )!
            return (body, response)
        }
    }
}
```

Add these tests inside `struct SupabaseServiceTests` (before `private static func tokenGrantJSON`):

```swift
    // MARK: - profiles name fields

    @Test @MainActor func fetchProfileDecodesTheNameColumns() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 200, body: Data("""
            [{"id":"u1","display_name":"Ada Lovelace","total_points":10,"streak":2,"total_minutes":30,"first_name":"Ada","last_name":"Lovelace"}]
            """.utf8))
        ])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        let row = try await service.fetchProfile(id: "u1")
        #expect(row?.firstName == "Ada")
        #expect(row?.lastName == "Lovelace")
        #expect(row?.displayName == "Ada Lovelace")
    }

    @Test @MainActor func fetchProfileToleratesRowsWithoutNameColumns() async throws {
        let session = FakeHTTPSession(responses: [
            .success(status: 200, body: Data("""
            [{"id":"u1","display_name":"Old Name","total_points":0,"streak":0,"total_minutes":0}]
            """.utf8))
        ])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        let row = try await service.fetchProfile(id: "u1")
        #expect(row?.firstName == nil)
        #expect(row?.lastName == nil)
    }

    @Test @MainActor func fetchProfileReturnsNilWhenThereIsNoRow() async throws {
        let session = FakeHTTPSession(responses: [.success(status: 200, body: Data("[]".utf8))])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        #expect(try await service.fetchProfile(id: "u1") == nil)
    }

    @Test @MainActor func fetchProfileFiltersByIdWithStrictEncoding() async throws {
        let session = FakeHTTPSession(responses: [.success(status: 200, body: Data("[]".utf8))])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        _ = try await service.fetchProfile(id: "a&b=c")
        let url = try #require(session.requests.first?.url?.absoluteString)
        #expect(url.contains("/rest/v1/profiles?id=eq.a%26b%3Dc"))
        #expect(url.contains("limit=1"))
    }

    @Test @MainActor func fetchProfileThrowsOnAnHTTPErrorStatus() async throws {
        let session = FakeHTTPSession(responses: [.success(status: 500, body: Data("{}".utf8))])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        await #expect(throws: (any Error).self) {
            _ = try await service.fetchProfile(id: "u1")
        }
    }

    @Test @MainActor func upsertProfileNameSendsOnlyIdentityColumnsAsAMergeUpsert() async throws {
        let session = FakeHTTPSession(responses: [.success(status: 201, body: Data())])
        let service = SupabaseService(keychain: FakeSupabaseKeychainStore(), urlSession: session)
        try await service.upsertProfileName(id: "u1", name: PersonName(first: "Ada", last: "Lovelace"))

        let request = try #require(session.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/rest/v1/profiles")
        #expect(request.value(forHTTPHeaderField: "Prefer") == "resolution=merge-duplicates")
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["id"] as? String == "u1")
        #expect(json["display_name"] as? String == "Ada Lovelace")
        #expect(json["first_name"] as? String == "Ada")
        #expect(json["last_name"] as? String == "Lovelace")
        #expect(json["total_points"] == nil)   // merge-duplicates must not reset stats
    }

    @Test @MainActor func remoteProfileOmitsNameKeysWhenTheyAreNil() throws {
        // SessionRecorder uploads RemoteProfile on every session; if nil names
        // were encoded as null they would wipe the names the name step saved.
        let profile = RemoteProfile(id: "u1", displayName: "Ada Lovelace", totalPoints: 1,
                                    streak: 1, totalMinutes: 1, lastSessionAt: nil)
        let data = try SupabaseService.makeEncoder().encode(profile)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["first_name"] == nil)
        #expect(json["last_name"] == nil)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run with `-only-testing:"Breath - Relax & StretchTests/SupabaseServiceTests"`.
Expected: build FAIL (`value of type 'SupabaseService' has no member 'fetchProfile'`, etc.).

- [ ] **Step 3: Implement DTO changes**

In `SupabaseDTOs.swift`, edit `RemoteProfile` — add two properties after `lastSessionAt` and two coding keys:

```swift
    let lastSessionAt: Date?
    /// Nullable in the database. `var … = nil` keeps existing memberwise call
    /// sites compiling, and nil is omitted from the encoded body so a session
    /// upload (which never sets names) can't overwrite the saved name.
    var firstName: String? = nil
    var lastName: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case displayName  = "display_name"
        case totalPoints  = "total_points"
        case streak
        case totalMinutes = "total_minutes"
        case lastSessionAt = "last_session_at"
        case firstName    = "first_name"
        case lastName     = "last_name"
    }
```

Add directly below `RemoteProfile`:

```swift
/// Upsert body for the name step. Only identity columns are sent so
/// `resolution=merge-duplicates` leaves points/streak/minutes untouched.
struct RemoteProfileName: Codable, Sendable {
    let id: String
    let displayName: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case firstName   = "first_name"
        case lastName    = "last_name"
    }
}
```

- [ ] **Step 4: Implement service methods and protocol**

In `SupabaseService.swift`, after `fetchLeaderboard` add:

```swift
    // MARK: - Registration (name step)

    /// Fetches this account's own `profiles` row, or nil when none exists.
    /// `profiles` is publicly readable, so no session is needed to *read*;
    /// callers still wait for one because the id is only meaningful once it is
    /// the Supabase uid (see RegistrationCoordinator).
    func fetchProfile(id: String) async throws -> RemoteProfile? {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? ""
        let data = try await get(path: "/rest/v1/profiles?id=eq.\(encoded)&select=*&limit=1")
        return try Self.makeDecoder().decode([RemoteProfile].self, from: data).first
    }

    /// Upserts just the identity columns for this account. This write is what
    /// makes the account "registered". Requires a Supabase session (RLS:
    /// id = auth.uid()); callers treat failure as best-effort.
    func upsertProfileName(id: String, name: PersonName) async throws {
        let data = try await MainActor.run {
            try Self.makeEncoder().encode(RemoteProfileName(
                id: id, displayName: name.fullName,
                firstName: name.first, lastName: name.last))
        }
        try await post(path: "/rest/v1/profiles", body: data, upsert: true)
    }
```

After the `SupabaseAuthenticating` protocol (end of file region near line 503) add:

```swift
/// Profile read/write seam for the registration flow, so
/// `RegistrationCoordinator` can be tested without the network.
protocol SupabaseProfileStoring: Sendable {
    func fetchProfile(id: String) async throws -> RemoteProfile?
    func upsertProfileName(id: String, name: PersonName) async throws
}

extension SupabaseService: SupabaseProfileStoring {}
```

- [ ] **Step 5: Run tests to verify they pass**

Same command as Step 2. Expected: all `SupabaseServiceTests` PASS (including the pre-existing ones).

- [ ] **Step 6: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SupabaseDTOs.swift" "Breath - Relax & Stretch/Services/SupabaseService.swift" "Breath - Relax & StretchTests/SupabaseServiceTests.swift"
git commit -m "feat(supabase): profile name fields, fetchProfile, upsertProfileName" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Database migration (**requires user approval**)

**Files:**
- Modify: `supabase_schema.sql` (append after the `last_session_at` additions block, ~line 188)

- [ ] **Step 1: Confirm the privacy decision**

Stop and ask the user to confirm option (a) from "Decision required before Task 4". Do not continue until they answer.

- [ ] **Step 2: Record the migration in the schema file**

Insert after `alter table profiles add column if not exists last_session_at timestamptz;`:

```sql

-- ───────────────────────── profiles (name columns) ─────────────────────────
-- Added 2026-09-18. A profiles row with non-empty first_name AND last_name is
-- what the app treats as "registered" (skips the name step and tour on
-- sign-in). Nullable so existing rows stay valid; existing users get the name
-- step once on their next sign-in. 35 + 1 + 35 <= display_name's 80 limit.
alter table profiles add column if not exists first_name text
  check (first_name is null or char_length(first_name) <= 35);
alter table profiles add column if not exists last_name text
  check (last_name is null or char_length(last_name) <= 35);
```

- [ ] **Step 3: Inspect the live table**

Load `mcp__supabase__list_tables` and `mcp__supabase__list_projects` via ToolSearch, then confirm `profiles` exists in the project used by `SupabaseService.supabaseURL` (`wmsutfittuxrvcwuywrk`) and lacks `first_name`/`last_name`.

- [ ] **Step 4: Ask, then apply**

Ask the user for explicit approval to apply. On approval call `mcp__supabase__apply_migration` with `name: "profiles_add_first_last_name"` and the two `alter table` statements from Step 2. Then run `mcp__supabase__get_advisors` (type `security`) and report any new findings.

- [ ] **Step 5: Verify**

`mcp__supabase__execute_sql`: `select column_name, is_nullable from information_schema.columns where table_name = 'profiles' and column_name in ('first_name','last_name');`
Expected: 2 rows, both `YES` nullable.

- [ ] **Step 6: Commit**

```bash
git add supabase_schema.sql
git commit -m "feat(supabase): add profiles.first_name/last_name" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: `AuthManager` name storage and email sign-up without a name

**Files:**
- Modify: `Breath - Relax & Stretch/Services/AuthManager.swift`
- Modify: `Breath - Relax & Stretch/Services/SupabaseService.swift:331-340, 503-507` (`signUpWithPassword` loses `name`)
- Modify: `Breath - Relax & StretchTests/AuthManagerTests.swift`, `Breath - Relax & StretchTests/SupabaseServiceTests.swift`

**Interfaces:**
- Consumes: `PersonName` (Task 1).
- Produces (all on `AuthManager`):
  - `@Published private(set) var firstName: String`, `lastName: String`
  - `var personName: PersonName` (complete only after `setName`)
  - `var providerPrefill: PersonName` (= `PersonName.split(fullName: displayName)`)
  - `var greetingName: String` (`""` for guests)
  - `func setName(_ name: PersonName)` (sets first/last and `displayName = fullName`)
  - `func signUp(email: String, password: String) async -> String?` (no `name`)
  - `SupabaseAuthenticating.signUpWithPassword(email:password:) async throws -> String`

- [ ] **Step 1: Write the failing tests**

In `AuthManagerTests.swift`:

1. Add `"auth.firstName", "auth.lastName"` to `keysToReset`.
2. In `FakeSupabaseAuthenticating`, change the signature:
   ```swift
   func signUpWithPassword(email: String, password: String) async throws -> String {
       try signUpWithPasswordResult.get()
   }
   ```
3. Update every existing `signUp(name: X, email: E, password: P)` call to `signUp(email: E, password: P)`. In `signUpSucceedsAndPersistsIdentity` change `#expect(manager.displayName == "Ada")` to `#expect(manager.displayName == "")`. **Delete** `signUpRejectsEmptyName`.
4. Add:

```swift
    // MARK: - Name (first/last)

    @Test func setNameStoresPartsAndComposesDisplayName() {
        let manager = makeManager()
        manager.setName(PersonName(first: " Ada ", last: "Lovelace"))
        #expect(manager.firstName == "Ada")
        #expect(manager.lastName == "Lovelace")
        #expect(manager.displayName == "Ada Lovelace")
        #expect(manager.personName.isComplete)
    }

    @Test func setNamePersistsAcrossInstances() {
        makeManager().setName(PersonName(first: "Ada", last: "Lovelace"))
        let reloaded = makeManager()
        #expect(reloaded.firstName == "Ada")
        #expect(reloaded.lastName == "Lovelace")
        #expect(reloaded.displayName == "Ada Lovelace")
    }

    @Test func providerSuppliedNamesPrefillButNeverCountAsAStoredName() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithGoogleResult = .success("g1")
        let manager = makeManager(supabase: fake)
        _ = await manager.handleGoogleSignIn(idToken: "t", nonce: "n", name: "Ada Lovelace", email: "a@b.com")
        #expect(manager.providerPrefill == PersonName(first: "Ada", last: "Lovelace"))
        #expect(!manager.personName.isComplete)   // must still go through the name step
    }

    @Test func providerPrefillIgnoresPlaceholderNames() {
        let manager = makeManager()
        manager.continueAsGuest()                 // displayName becomes "Guest"
        #expect(manager.providerPrefill == .empty)
    }

    @Test func signOutClearsTheName() {
        let manager = makeManager()
        manager.setName(PersonName(first: "Ada", last: "Lovelace"))
        manager.signOut()
        #expect(manager.firstName.isEmpty)
        #expect(manager.lastName.isEmpty)
        #expect(manager.displayName.isEmpty)
    }

    @Test func greetingNameIsTheFirstNameAndEmptyForGuests() async {
        let manager = makeManager()
        manager.setName(PersonName(first: "Ada", last: "Lovelace"))
        #expect(manager.greetingName == "Ada")

        let guest = makeManager()
        guest.continueAsGuest()
        #expect(guest.greetingName == "")
    }

    @Test func greetingNameFallsBackToTheFirstWordOfADisplayNameAndSkipsPlaceholders() async {
        let fake = FakeSupabaseAuthenticating()
        fake.signInWithGoogleResult = .success("g1")
        let manager = makeManager(supabase: fake)
        _ = await manager.handleGoogleSignIn(idToken: "t", nonce: "n", name: "Ada Lovelace", email: "a@b.com")
        #expect(manager.greetingName == "Ada")

        let apple = makeManager()
        apple.continueAsGuest()
        #expect(apple.greetingName == "")
    }
```

In `SupabaseServiceTests.swift`, remove the `name:` argument from the two `signUpWithPassword(email:password:name:)` calls in `signUpWithPasswordReturnsTheUserIDFromASuccessfulGrant` and `signUpWithPasswordMapsUserAlreadyExistsToAReadableMessage`.

- [ ] **Step 2: Run tests to verify they fail**

Run with `-only-testing:"Breath - Relax & StretchTests/AuthManagerTests"`.
Expected: build FAIL (`extra argument 'name'` / no member `setName`).

- [ ] **Step 3: Implement**

`SupabaseService.swift` — replace `signUpWithPassword`:

```swift
    func signUpWithPassword(email: String, password: String) async throws -> String {
        struct Body: Encodable {
            let email: String
            let password: String
        }
        let body = try JSONEncoder().encode(Body(email: email, password: password))
        let grant = try await authRequest(path: "/auth/v1/signup", body: body)
        return grant.user.id
    }
```
and in `protocol SupabaseAuthenticating` change to `func signUpWithPassword(email: String, password: String) async throws -> String`.

`AuthManager.swift`:

- Add published state and computed helpers after `provider`:
  ```swift
      @Published private(set) var firstName: String = ""
      @Published private(set) var lastName: String  = ""

      /// Complete only once the name step has run — provider-supplied names
      /// (Apple/Google/email) deliberately never populate these.
      var personName: PersonName { PersonName(first: firstName, last: lastName) }

      /// What to prefill the name step with: the provider/legacy display name,
      /// split. Placeholders ("Apple User", "Guest", "User") give `.empty`.
      var providerPrefill: PersonName { PersonName.split(fullName: displayName) }

      /// First name for greetings; empty for guests and placeholder names.
      var greetingName: String {
          guard !isGuest else { return "" }
          return firstName.isEmpty ? PersonName.split(fullName: displayName).first : firstName
      }
  ```
- Add keys: `private let kFirstName = "auth.firstName"` and `private let kLastName = "auth.lastName"`.
- In `loadPersistedState()` add `firstName = d.string(forKey: kFirstName) ?? ""` and `lastName = d.string(forKey: kLastName) ?? ""`.
- Add:
  ```swift
      // MARK: - Name

      /// Records the name from the name step (or restored from the server).
      func setName(_ name: PersonName) {
          let d = UserDefaults.standard
          d.set(name.first,    forKey: kFirstName)
          d.set(name.last,     forKey: kLastName)
          d.set(name.fullName, forKey: kDisplayName)
          firstName   = name.first
          lastName    = name.last
          displayName = name.fullName
      }
  ```
- In `clearLocalSignIn()` add `d.removeObject(forKey: kFirstName)`, `d.removeObject(forKey: kLastName)`, `firstName = ""`, `lastName = ""`.
- Replace `signUp`:
  ```swift
      func signUp(email: String, password: String) async -> String? {
          let email = normalizedEmail(email)
          guard email.contains("@") else { return "Enter a valid email address." }
          guard password.count >= 8 else { return "Password must be at least 8 characters." }
          guard SupabaseService.isConfigured else {
              return "Account creation isn't available right now. Please try again later."
          }
          do {
              let uid = try await supabase.signUpWithPassword(email: email, password: password)
              UserDefaults.standard.set(uid, forKey: kSupabaseUserID)
              objectWillChange.send()
              // Name is collected by the name step right after sign-up.
              persist(name: "", email: email, providerVal: .email)
              return nil
          } catch {
              return (error as? LocalizedError)?.errorDescription
                  ?? "Couldn't create your account. Please try again."
          }
      }
  ```
- Confirm delete-account clears names: run `sed -n 408,460p "Breath - Relax & Stretch/Services/AuthManager.swift"`. If `deleteAccount()` calls `clearLocalSignIn()` nothing more is needed; if it removes keys itself, also remove `kFirstName`/`kLastName` and reset `firstName`/`lastName` there.
- Fix any other `signUp(name:` caller: `grep -rn "signUp(name" "Breath - Relax & Stretch" "Breath - Relax & StretchTests"` (the only production caller is `EmailAuthView`, fixed in Task 9 — the build stays broken until then, so do Task 9 Step 3's one-line call fix now: change `auth.signUp(name: name, email: email, password: password)` to `auth.signUp(email: email, password: password)`).

- [ ] **Step 4: Run tests to verify they pass**

Run with `-only-testing:"Breath - Relax & StretchTests/AuthManagerTests"` then `-only-testing:"Breath - Relax & StretchTests/SupabaseServiceTests"`.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/AuthManager.swift" "Breath - Relax & Stretch/Services/SupabaseService.swift" "Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift" "Breath - Relax & StretchTests/AuthManagerTests.swift" "Breath - Relax & StretchTests/SupabaseServiceTests.swift"
git commit -m "feat(auth): first/last name storage, email sign-up without name" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: `RegistrationCoordinator`

**Files:**
- Create: `Breath - Relax & Stretch/Services/RegistrationCoordinator.swift`
- Test: `Breath - Relax & StretchTests/RegistrationCoordinatorTests.swift`

**Interfaces:**
- Consumes: `PersonName`, `RemoteProfileLookup`, `RegistrationOutcome`, `RegistrationRouting` (Tasks 1-2); `SupabaseProfileStoring`, `RemoteProfile` (Task 3).
- Produces: `@MainActor final class RegistrationCoordinator: ObservableObject`
  - `enum State: Equatable { case idle, checking, needsName(prefill: PersonName), registered }`
  - `@Published private(set) var state: State`
  - `init(store: SupabaseProfileStoring = SupabaseService.shared, lookupTimeout: Duration = .seconds(6), sessionPollInterval: Duration = .milliseconds(200))`
  - `@discardableResult func resolve(userID: String, local: PersonName, providerPrefill: PersonName, hasBackendSession: () -> Bool) async -> RegistrationOutcome?` (nil when cancelled or already showing the name step)
  - `@discardableResult func completeName(_ name: PersonName, userID: String) async -> Bool` (true when uploaded; state becomes `.registered` regardless)

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/RegistrationCoordinatorTests.swift`:

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

@MainActor
struct RegistrationCoordinatorTests {
    private let ada = PersonName(first: "Ada", last: "Lovelace")
    private let grace = PersonName(first: "Grace", last: "Hopper")

    private func row(first: String?, last: String?, display: String) -> RemoteProfile {
        RemoteProfile(id: "u1", displayName: display, totalPoints: 0, streak: 0, totalMinutes: 0,
                      lastSessionAt: nil, firstName: first, lastName: last)
    }

    private func makeCoordinator(_ store: FakeProfileStore,
                                 timeout: Duration = .seconds(2)) -> RegistrationCoordinator {
        RegistrationCoordinator(store: store, lookupTimeout: timeout, sessionPollInterval: .milliseconds(10))
    }

    @Test func namedRowIsRegistered() async {
        let store = FakeProfileStore()
        store.fetchResult = .success(row(first: "Ada", last: "Lovelace", display: "Ada Lovelace"))
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: { true })

        #expect(outcome == .registered(name: ada, backfillRemote: false))
        #expect(coordinator.state == .registered)
        #expect(store.upserts.isEmpty)
    }

    @Test func missingRowWithNoLocalNameNeedsNameWithProviderPrefill() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })

        #expect(outcome == .needsName(prefill: ada))
        #expect(coordinator.state == .needsName(prefill: ada))
    }

    @Test func legacyRowWithOnlyADisplayNamePrefillsFromIt() async {
        let store = FakeProfileStore()
        store.fetchResult = .success(row(first: nil, last: nil, display: "Grace Hopper"))
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })

        #expect(outcome == .needsName(prefill: grace))
    }

    @Test func fetchFailureWithACompleteLocalNameIsRegistered() async {
        let store = FakeProfileStore()
        store.fetchResult = .failure(URLError(.notConnectedToInternet))
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: ada, providerPrefill: .empty, hasBackendSession: { true })

        #expect(outcome == .registered(name: ada, backfillRemote: false))
        #expect(store.upserts.isEmpty)
    }

    @Test func slowLookupTimesOutAsUnavailable() async {
        let store = FakeProfileStore()
        store.fetchDelay = .seconds(5)
        let coordinator = makeCoordinator(store, timeout: .milliseconds(50))

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: grace, hasBackendSession: { true })

        #expect(outcome == .needsName(prefill: grace))
    }

    @Test func missingRowWithACompleteLocalNameBackfillsTheRemoteRow() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)

        let outcome = await coordinator.resolve(userID: "u1", local: ada, providerPrefill: .empty, hasBackendSession: { true })

        #expect(outcome == .registered(name: ada, backfillRemote: true))
        #expect(store.upserts.count == 1)
        #expect(store.upserts.first?.id == "u1")
        #expect(store.upserts.first?.name == ada)
    }

    @Test func withoutABackendSessionItWaitsThenTreatsTheLookupAsUnavailable() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store, timeout: .milliseconds(60))

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: grace, hasBackendSession: { false })

        #expect(outcome == .needsName(prefill: grace))
        #expect(store.fetchCount == 0)   // never queried with an unauthenticated (anonymous) id
    }

    @Test func aBackendSessionThatAppearsLateIsWaitedFor() async {
        let store = FakeProfileStore()
        store.fetchResult = .success(row(first: "Ada", last: "Lovelace", display: "Ada Lovelace"))
        let coordinator = makeCoordinator(store, timeout: .seconds(2))
        var polls = 0

        let outcome = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: {
            polls += 1
            return polls > 3
        })

        #expect(outcome == .registered(name: ada, backfillRemote: false))
    }

    @Test func aSecondResolveWhileTheNameStepIsShownIsIgnored() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)
        await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })
        #expect(coordinator.state == .needsName(prefill: ada))

        store.fetchResult = .success(row(first: "Ada", last: "Lovelace", display: "Ada Lovelace"))
        let again = await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: ada, hasBackendSession: { true })

        #expect(again == nil)
        #expect(coordinator.state == .needsName(prefill: ada))   // never clobbers what the user is typing
    }

    @Test func completeNameUploadsAndRegisters() async {
        let store = FakeProfileStore()
        let coordinator = makeCoordinator(store)
        await coordinator.resolve(userID: "u1", local: .empty, providerPrefill: .empty, hasBackendSession: { true })

        let uploaded = await coordinator.completeName(ada, userID: "u1")

        #expect(uploaded)
        #expect(coordinator.state == .registered)
        #expect(store.upserts.first?.name == ada)
    }

    @Test func completeNameStillRegistersWhenTheUploadFails() async {
        let store = FakeProfileStore()
        store.upsertShouldFail = true
        let coordinator = makeCoordinator(store)

        let uploaded = await coordinator.completeName(ada, userID: "u1")

        #expect(!uploaded)
        #expect(coordinator.state == .registered)   // offline-first: the local name is kept, backfilled later
    }
}

final class FakeProfileStore: SupabaseProfileStoring, @unchecked Sendable {
    var fetchResult: Result<RemoteProfile?, Error> = .success(nil)
    var fetchDelay: Duration = .zero
    var upsertShouldFail = false
    private(set) var fetchCount = 0
    private(set) var upserts: [(id: String, name: PersonName)] = []

    func fetchProfile(id: String) async throws -> RemoteProfile? {
        fetchCount += 1
        try await Task.sleep(for: fetchDelay)
        return try fetchResult.get()
    }

    func upsertProfileName(id: String, name: PersonName) async throws {
        upserts.append((id, name))
        if upsertShouldFail { throw URLError(.notConnectedToInternet) }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run with `-only-testing:"Breath - Relax & StretchTests/RegistrationCoordinatorTests"`.
Expected: build FAIL, `cannot find 'RegistrationCoordinator' in scope`.

- [ ] **Step 3: Write minimal implementation**

Create `Breath - Relax & Stretch/Services/RegistrationCoordinator.swift`:

```swift
import Foundation
import Combine

/// Decides whether the signed-in (non-guest) account still needs the name
/// step, by looking for a named `profiles` row. Owns no UI — RegistrationGate
/// renders `state`.
@MainActor
final class RegistrationCoordinator: ObservableObject {

    enum State: Equatable {
        case idle
        case checking
        case needsName(prefill: PersonName)
        case registered
    }

    @Published private(set) var state: State = .idle

    private let store: SupabaseProfileStoring
    private let lookupTimeout: Duration
    private let sessionPollInterval: Duration

    init(
        store: SupabaseProfileStoring = SupabaseService.shared,
        lookupTimeout: Duration = .seconds(6),
        sessionPollInterval: Duration = .milliseconds(200)
    ) {
        self.store = store
        self.lookupTimeout = lookupTimeout
        self.sessionPollInterval = sessionPollInterval
    }

    /// Returns nil when cancelled, or when the name step is already showing
    /// (a late re-resolve, e.g. the Apple → Supabase exchange finishing after
    /// the timeout, must not clobber what the user is typing).
    @discardableResult
    func resolve(
        userID: String,
        local: PersonName,
        providerPrefill: PersonName,
        hasBackendSession: () -> Bool
    ) async -> RegistrationOutcome? {
        if case .needsName = state { return nil }
        // Keep showing Home if we already resolved as registered; only a
        // first/unknown resolve shows the spinner.
        if state != .registered { state = .checking }

        let lookup = await lookup(userID: userID, hasBackendSession: hasBackendSession)
        guard !Task.isCancelled else { return nil }

        let outcome = RegistrationRouting.resolve(lookup: lookup, local: local, providerPrefill: providerPrefill)
        switch outcome {
        case .registered(let name, let backfill):
            state = .registered
            if backfill { try? await store.upsertProfileName(id: userID, name: name) }
        case .needsName(let prefill):
            state = .needsName(prefill: prefill)
        }
        return outcome
    }

    /// Called by the name step. The state flips first so the user is never
    /// blocked on the network; the upload is best-effort and, if it fails,
    /// `resolve` backfills it on a later launch from the locally stored name.
    @discardableResult
    func completeName(_ name: PersonName, userID: String) async -> Bool {
        state = .registered
        do {
            try await store.upsertProfileName(id: userID, name: name)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Lookup

    /// The profile can only be addressed by the Supabase uid, which for Sign in
    /// with Apple arrives asynchronously after `isSignedIn` flips — until then
    /// `backendID` is the anonymous UUID and a lookup would falsely say "no
    /// row". So wait (bounded) for a session before querying.
    private func lookup(userID: String, hasBackendSession: () -> Bool) async -> RemoteProfileLookup {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: lookupTimeout)
        while !hasBackendSession() {
            if Task.isCancelled || clock.now >= deadline { return .unavailable }
            try? await Task.sleep(for: sessionPollInterval)
        }

        let store = self.store
        let timeout = lookupTimeout
        let result: Result<RemoteProfile?, any Error> = await withTaskGroup(
            of: Result<RemoteProfile?, any Error>.self
        ) { group in
            group.addTask {
                do { return .success(try await store.fetchProfile(id: userID)) }
                catch { return .failure(error) }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return .failure(URLError(.timedOut))
            }
            let first = await group.next() ?? .failure(URLError(.timedOut))
            group.cancelAll()
            return first
        }

        switch result {
        case .failure:
            return .unavailable
        case .success(let row):
            guard let row else { return .notRegistered(rowPrefill: .empty) }
            let name = PersonName(first: row.firstName ?? "", last: row.lastName ?? "")
            if name.isComplete { return .named(name) }
            return .notRegistered(rowPrefill: PersonName.split(fullName: row.displayName))
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Same command. Expected: all 11 tests PASS. If the compiler reports main-actor isolation errors for `PersonName`/`RemoteProfile` inside the task-group closures, apply the "Actor-isolation contingency" from Global Constraints (mark the offending type `nonisolated`).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/RegistrationCoordinator.swift" "Breath - Relax & StretchTests/RegistrationCoordinatorTests.swift"
git commit -m "feat(auth): RegistrationCoordinator (lookup, timeout, backfill)" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: Per-account tour flag

**Files:**
- Create: `Breath - Relax & Stretch/Views/Onboarding/AppGuideSeen.swift`
- Test: `Breath - Relax & StretchTests/AppGuideSeenTests.swift`

**Interfaces:**
- Produces: `enum AppGuideSeen` with `static func key(for userID: String) -> String`, `isSeen(userID:defaults:) -> Bool`, `markSeen(userID:defaults:)`, `migrateLegacy(userID:defaults:)` (marks seen when the old global `"hasSeenAppGuide"` is true). `defaults` defaults to `.standard`.

- [ ] **Step 1: Write the failing test**

Create `Breath - Relax & StretchTests/AppGuideSeenTests.swift`:

```swift
import Testing
import Foundation
@testable import BreathRelaxStretch

@MainActor
struct AppGuideSeenTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "AppGuideSeenTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func unseenByDefault() {
        #expect(!AppGuideSeen.isSeen(userID: "u1", defaults: makeDefaults()))
    }

    @Test func markSeenIsScopedToTheAccount() {
        let defaults = makeDefaults()
        AppGuideSeen.markSeen(userID: "u1", defaults: defaults)
        #expect(AppGuideSeen.isSeen(userID: "u1", defaults: defaults))
        #expect(!AppGuideSeen.isSeen(userID: "u2", defaults: defaults))
    }

    @Test func legacyGlobalFlagMigratesToTheGivenAccount() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "hasSeenAppGuide")
        AppGuideSeen.migrateLegacy(userID: "guest-1", defaults: defaults)
        #expect(AppGuideSeen.isSeen(userID: "guest-1", defaults: defaults))
    }

    @Test func migrationDoesNothingWithoutTheLegacyFlag() {
        let defaults = makeDefaults()
        AppGuideSeen.migrateLegacy(userID: "guest-1", defaults: defaults)
        #expect(!AppGuideSeen.isSeen(userID: "guest-1", defaults: defaults))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run with `-only-testing:"Breath - Relax & StretchTests/AppGuideSeenTests"`. Expected: FAIL, `cannot find 'AppGuideSeen'`.

- [ ] **Step 3: Write minimal implementation**

Create `Breath - Relax & Stretch/Views/Onboarding/AppGuideSeen.swift`:

```swift
import Foundation

/// Whether an account has already been shown the coach-mark tour. Keyed per
/// account (`AuthManager.backendID`) so a new/unregistered account on an
/// already-onboarded device replays it. The old global `hasSeenAppGuide` flag
/// is honored only for guests (see `migrateLegacy`), preserving their behavior.
enum AppGuideSeen {
    private static let legacyKey = "hasSeenAppGuide"

    static func key(for userID: String) -> String { "hasSeenAppGuide.\(userID)" }

    static func isSeen(userID: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(for: userID))
    }

    static func markSeen(userID: String, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(for: userID))
    }

    /// Carries the pre-existing global "already saw the tour" flag over to one
    /// account so guests who already saw it don't see it again.
    static func migrateLegacy(userID: String, defaults: UserDefaults = .standard) {
        if defaults.bool(forKey: legacyKey) { markSeen(userID: userID, defaults: defaults) }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Same command. Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/AppGuideSeen.swift" "Breath - Relax & StretchTests/AppGuideSeenTests.swift"
git commit -m "feat(onboarding): per-account tour-seen flag" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 8: Name step UI, registration gate, wiring

**Files:**
- Create: `Breath - Relax & Stretch/Views/Auth/NameEntryView.swift`
- Create: `Breath - Relax & Stretch/Views/Auth/RegistrationGate.swift`
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift:480-522` (`RootView`)
- Modify: `Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift:5-32` (`OnboardingGate`)

**Interfaces:**
- Consumes: `PersonName`, `RegistrationCoordinator` (`resolve`, `completeName`, `state`), `AppGuideSeen`, `AuthManager.setName/personName/providerPrefill/backendID/isBackendAuthenticated/isGuest`, `TourCoordinator.restart()`.
- Produces: `NameEntryView(prefill: PersonName, onSubmit: (PersonName) -> Void)`; `RegistrationGate<Content: View>` initialized with `RegistrationGate { HomeView() }`.

- [ ] **Step 1: Create `NameEntryView`**

```swift
import SwiftUI

/// Collects first + last name after sign-in. Prefilled when Apple/Google (or a
/// pre-existing profile row) supplied a name, but always shown so every account
/// ends up with the same two fields.
struct NameEntryView: View {
    let prefill: PersonName
    let onSubmit: (PersonName) -> Void

    @State private var first = ""
    @State private var last = ""
    @FocusState private var focus: Field?

    private enum Field { case first, last }

    private var candidate: PersonName { PersonName(first: first, last: last) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.luminaPrimary)
                    Text("What should we call you?")
                        .font(.luminaTitle)
                        .foregroundStyle(Color.luminaOnSurface)
                        .multilineTextAlignment(.center)
                    Text("Your name shows on your profile and greets you each day.")
                        .font(.luminaSubheadline)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                VStack(spacing: 14) {
                    nameField("First name", text: $first, contentType: .givenName, field: .first)
                        .submitLabel(.next)
                        .onSubmit { focus = .last }
                    nameField("Last name", text: $last, contentType: .familyName, field: .last)
                        .submitLabel(.done)
                        .onSubmit { submitIfValid() }
                }

                Button(action: submitIfValid) {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(LuminaPillButtonStyle())
                .disabled(!candidate.isComplete)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.luminaSurface.ignoresSafeArea())
        .onAppear {
            if first.isEmpty && last.isEmpty {
                first = prefill.first
                last = prefill.last
            }
            focus = prefill.first.isEmpty ? .first : nil
        }
    }

    private func nameField(_ label: String, text: Binding<String>,
                           contentType: UITextContentType, field: Field) -> some View {
        TextField(label, text: text)
            .textContentType(contentType)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focus, equals: field)
            .font(.luminaBody)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.luminaContainer, in: RoundedRectangle(cornerRadius: LuminaRadius.tag))
            .accessibilityLabel(label)
    }

    private func submitIfValid() {
        guard candidate.isComplete else { return }
        onSubmit(candidate)
    }
}

#Preview {
    NameEntryView(prefill: PersonName(first: "Ada", last: "Lovelace")) { _ in }
}
```

- [ ] **Step 2: Create `RegistrationGate`**

```swift
import SwiftUI

/// Sits between App Lock and Home. Guests pass straight through; everyone else
/// is checked against Supabase and shown the name step if unregistered. Also
/// owns the once-per-account coach-mark tour (previously `OnboardingGate`).
struct RegistrationGate<Content: View>: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var tourCoordinator: TourCoordinator
    @StateObject private var registration = RegistrationCoordinator()
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if auth.isGuest {
                content.onAppear { startTourIfFirstTime() }
            } else {
                switch registration.state {
                case .idle, .checking:
                    RegistrationCheckingView()
                case .needsName(let prefill):
                    NameEntryView(prefill: prefill) { name in submit(name) }
                case .registered:
                    content.onAppear { startTourIfFirstTime() }
                }
            }
        }
        // Re-runs when the account changes — including anonymous id → Supabase
        // uid once Sign in with Apple's async token exchange completes.
        .task(id: "\(auth.backendID)|\(auth.provider.rawValue)") { await resolve() }
    }

    // MARK: - Actions

    private func resolve() async {
        guard auth.isSignedIn, !auth.isGuest else { return }
        let outcome = await registration.resolve(
            userID: auth.backendID,
            local: auth.personName,
            providerPrefill: auth.providerPrefill,
            hasBackendSession: { auth.isBackendAuthenticated || !SupabaseService.isConfigured }
        )
        if case .registered(let name, _)? = outcome {
            // A returning registered account: restore the name locally and
            // don't replay the tour.
            auth.setName(name)
            AppGuideSeen.markSeen(userID: auth.backendID)
        }
    }

    private func submit(_ name: PersonName) {
        auth.setName(name)
        let uid = auth.backendID
        Task { await registration.completeName(name, userID: uid) }
    }

    private func startTourIfFirstTime() {
        let uid = auth.backendID
        if auth.isGuest { AppGuideSeen.migrateLegacy(userID: uid) }
        guard !AppGuideSeen.isSeen(userID: uid) else { return }
        AppGuideSeen.markSeen(userID: uid)
        // The tour runs live in HomeView's own ZStack (it switches real tabs
        // underneath itself), so it can only start once Home is on screen.
        tourCoordinator.restart()
    }
}

private struct RegistrationCheckingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.luminaPrimary)
            Text("Setting things up…")
                .font(.luminaSubheadline)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.luminaSurface.ignoresSafeArea())
    }
}
```

- [ ] **Step 3: Mount the gate and sync the local profile name in `RootView`**

In `Breath__Relax___StretchApp.swift`, change the `else` branch of `RootView.body`:

```swift
            } else {
                RegistrationGate { HomeView() }
            }
```

Add to the `.onChange(of: auth.isSignedIn)` chain and `.onAppear`:

```swift
        .onChange(of: auth.displayName) { _, _ in syncProfileDisplayName() }
        .onAppear {
            if auth.isSignedIn { ensureUserProfile(); syncProfileDisplayName() }
        }
```
(replace the existing `.onAppear` block), and add below `ensureUserProfile()`:

```swift
    /// The local `UserProfile` is created at sign-in, before the name step runs
    /// (so it starts as "User"/"Apple User"). Keep it in step with the name the
    /// user entered or that was restored from Supabase — SessionRecorder uploads
    /// `profile.displayName` to the leaderboard row.
    private func syncProfileDisplayName() {
        guard auth.isSignedIn, !auth.isGuest, !auth.displayName.isEmpty,
              let profile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first,
              profile.displayName != auth.displayName else { return }
        profile.displayName = auth.displayName
        do {
            try modelContext.save()
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "profile").warning("Profile name sync failed: \(error)")
        }
    }
```

- [ ] **Step 4: Remove the global tour auto-start from `OnboardingGate`**

In `OnboardingView.swift` replace `OnboardingGate` (lines 5-32) with:

```swift
struct OnboardingGate<Content: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // The coach-mark tour used to auto-start here off a global flag. It is
        // now per-account and started by RegistrationGate, so an unregistered
        // account on an already-onboarded device replays it.
        if hasCompletedOnboarding {
            content
        } else {
            OnboardingView()
        }
    }
}
```

- [ ] **Step 5: Build**

Run the Build command. Expected: `** BUILD SUCCEEDED **`. Fix isolation errors per the Global Constraints contingency if any.

- [ ] **Step 6: Run the full unit suite for regressions**

Run the unit test command with `-only-testing:"Breath - Relax & StretchTests"`. Expected: all pass except the known pre-existing `CuratedContentIntegrityTests` failures.

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Auth/NameEntryView.swift" "Breath - Relax & Stretch/Views/Auth/RegistrationGate.swift" "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift" "Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift"
git commit -m "feat(auth): name step + registration gate, per-account tour" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 9: Email sign-up form and greeting

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift:8, 39-42, 143`
- Modify: `Breath - Relax & Stretch/Views/Home/TodayView.swift:378-380`

- [ ] **Step 1: Remove the name field from email sign-up**

In `EmailAuthView.swift`: delete `@State private var name = ""` (line 8); delete the `if isSignUp { AuthField(label: "Full Name", … ) }` block (lines 39-42); confirm line 143 already reads `if let err = await auth.signUp(email: email, password: password) {` (done in Task 5). Keep the "Sign up with your email address." subtitle.

- [ ] **Step 2: Greet by first name**

In `TodayView.swift` replace the `Text(auth.displayName.isEmpty || auth.isGuest ? … )` expression (lines 378-380) with:

```swift
                Text(auth.greetingName.isEmpty
                     ? greeting
                     : "\(greeting), \(auth.greetingName)")
```

- [ ] **Step 3: Build**

Run the Build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Auth/EmailAuthView.swift" "Breath - Relax & Stretch/Views/Home/TodayView.swift"
git commit -m "feat(auth): drop email name field, greet by first name" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 10: Onboarding feature showcase

**Files:**
- Create: `Breath - Relax & StretchUITests/ShowcaseScreenshotUITests.swift`
- Create: `Breath - Relax & Stretch/Assets.xcassets/showcase-bodymap.imageset/`, `showcase-exercises.imageset/`, `showcase-routines.imageset/` (each `Contents.json` + PNG)
- Create: `Breath - Relax & Stretch/Views/Onboarding/ShowcasePage.swift`
- Modify: `Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift:36-96`

**Interfaces:**
- Produces: `ShowcasePage(imageName: String, title: String, subtitle: String)`; `OnboardingView` now has 8 pages (0 welcome, 1-3 showcase, 4 goals, 5 focus, 6 body map intro, 7 notifications) with a **Skip** button on pages 1-3 that jumps to page 4.

- [ ] **Step 1: Write the screenshot-capture UI test**

Create `Breath - Relax & StretchUITests/ShowcaseScreenshotUITests.swift`:

```swift
import XCTest

/// Not an assertion test — a repeatable way to regenerate the onboarding
/// showcase screenshots straight from the app. Export the attachments with
/// `xcrun xcresulttool export attachments` (see .claude/skills/verify/SKILL.md).
final class ShowcaseScreenshotUITests: XCTestCase {

    func testCaptureShowcaseScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            // Legacy global flag: RegistrationGate migrates it to the guest's
            // per-account flag, so the coach-mark tour stays out of the shots.
            "-hasSeenAppGuide", "YES",
            "-auth.isSignedIn", "YES", "-auth.provider", "guest",
        ]
        app.launch()

        capture(app, tab: "Body", name: "showcase-bodymap", settle: 6)      // 3D model warm-up
        capture(app, tab: "Exercises", name: "showcase-exercises", settle: 2)
        capture(app, tab: "Routines", name: "showcase-routines", settle: 2)
    }

    private func capture(_ app: XCUIApplication, tab: String, name: String, settle: TimeInterval) {
        let button = app.buttons[tab]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing tab button \(tab)")
        button.tap()
        Thread.sleep(forTimeInterval: settle)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

- [ ] **Step 2: Run it and export the PNGs**

```bash
cd "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
xcrun simctl uninstall "iPhone 17" com.jasonlu.Dial--Down--Breath--Stretch 2>/dev/null
rm -rf /tmp/showcase.xcresult
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/ShowcaseScreenshotUITests" -resultBundlePath /tmp/showcase.xcresult
xcrun xcresulttool export attachments --path /tmp/showcase.xcresult --output-path /tmp/showcase-out
cat /tmp/showcase-out/manifest.json | head -40
```

Use the scratchpad directory instead of `/tmp` if the harness provides one. Expected: PNGs plus `manifest.json`; match `suggestedHumanReadableName` values starting `showcase-bodymap`, `showcase-exercises`, `showcase-routines`. Read each PNG and confirm it shows the right screen with **no tour overlay and no alert**. If a "New Content Added" alert or the tour still appears, dismiss it in the test before `capture` (tap its button when it exists) and re-run.

- [ ] **Step 3: Add the imagesets**

For each of the three PNGs (downscaled to keep the app small):

```bash
cd "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch/Breath - Relax & Stretch/Assets.xcassets"
for n in bodymap exercises routines; do
  mkdir -p "showcase-$n.imageset"
  sips --resampleHeight 1700 "<exported showcase-$n PNG>" --out "showcase-$n.imageset/showcase-$n.png"
  cat > "showcase-$n.imageset/Contents.json" <<EOF
{
  "images" : [ { "filename" : "showcase-$n.png", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
done
```

Expected: three `.imageset` folders each with a PNG under ~1 MB (`ls -la`).

- [ ] **Step 4: Create `ShowcasePage`**

```swift
import SwiftUI

/// One feature-showcase slide: an app screenshot in a device-style frame with a
/// title and subtitle. Static image only — no live SceneKit/SwiftData here.
struct ShowcasePage: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 56)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.luminaOutline, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                .frame(maxHeight: 400)
                .padding(.horizontal, 48)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.luminaTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.luminaBody)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 150)   // clears OnboardingView's Next button overlay
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

#Preview {
    ShowcasePage(imageName: "showcase-bodymap",
                 title: "Tap a muscle, get the stretch",
                 subtitle: "Explore the 3D Body Map to find exercises for exactly where you feel tight.")
}
```

- [ ] **Step 5: Insert the pages and Skip button in `OnboardingView`**

Replace `private let totalPages = 5` and the `TabView` block with:

```swift
    private enum Page {
        static let showcase = 1...3
        static let goals = 4
        static let total = 8
    }
    private var totalPages: Int { Page.total }
```
and

```swift
            TabView(selection: $currentPage) {
                WelcomePage().tag(0)

                ShowcasePage(imageName: "showcase-bodymap",
                             title: "Tap a muscle, get the stretch",
                             subtitle: "Explore the 3D Body Map to find exercises for exactly where you feel tight.")
                    .tag(1)
                ShowcasePage(imageName: "showcase-exercises",
                             title: "200+ guided exercises",
                             subtitle: "Browse animated demos with clear, step-by-step instructions.")
                    .tag(2)
                ShowcasePage(imageName: "showcase-routines",
                             title: "Build your routine",
                             subtitle: "Save your favorites, keep your streak, and earn badges.")
                    .tag(3)

                GoalPickerPage(selectedGoals: onboardingGoalsBinding).tag(Page.goals)
                FocusAreaPickerPage(selectedAreas: onboardingAreasBinding).tag(5)
                BodyMapIntroPage().tag(6)
                NotificationsPage(onComplete: completeOnboarding).tag(7)
            }
```

Add a Skip overlay after `.ignoresSafeArea(edges: .bottom)` on the outer `ZStack`:

```swift
        .overlay(alignment: .topTrailing) {
            if Page.showcase.contains(currentPage) {
                Button("Skip") {
                    withAnimation { currentPage = Page.goals }
                }
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
```

The bottom `if currentPage < totalPages - 1` Next/dots block keeps working unchanged (now with 8 dots).

- [ ] **Step 6: Build**

Run the Build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Onboarding/ShowcasePage.swift" "Breath - Relax & Stretch/Views/Onboarding/OnboardingView.swift" "Breath - Relax & Stretch/Assets.xcassets" "Breath - Relax & StretchUITests/ShowcaseScreenshotUITests.swift"
git commit -m "feat(onboarding): feature showcase slides with skip" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 11: End-to-end verification, regression run, graph update

**Files:**
- Create: `Breath - Relax & StretchUITests/RegistrationFlowUITests.swift`

Apple/Google sign-in can't be driven by XCUITest, so the flow is verified by injecting signed-in state via launch arguments (every `UserDefaults` key works this way, per the `verify` skill). With no Supabase session the coordinator waits ~6s then treats the lookup as `.unavailable`, which exercises the offline-fallback branch.

- [ ] **Step 1: Write the flow test**

```swift
import XCTest

final class RegistrationFlowUITests: XCTestCase {

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"] + extra
        app.launch()
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Signed-in email account with a legacy single-string name and no stored
    /// first/last: must land on the name step, prefilled.
    func testUnregisteredAccountSeesPrefilledNameStepThenHome() {
        let app = launch(["-auth.isSignedIn", "YES", "-auth.provider", "email",
                          "-auth.displayName", "Ada Lovelace"])
        let first = app.textFields["First name"]
        XCTAssertTrue(first.waitForExistence(timeout: 20), "Name step should appear")
        XCTAssertEqual(first.value as? String, "Ada")
        XCTAssertEqual(app.textFields["Last name"].value as? String, "Lovelace")
        attach(app, "1-name-step")

        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 10), "Home should follow")
        attach(app, "2-home-after-name")
    }

    /// A complete stored name means registered: straight to Home, no name step.
    func testRegisteredAccountSkipsTheNameStep() {
        let app = launch(["-auth.isSignedIn", "YES", "-auth.provider", "email",
                          "-auth.firstName", "Ada", "-auth.lastName", "Lovelace",
                          "-auth.displayName", "Ada Lovelace"])
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.textFields["First name"].exists)
        attach(app, "3-registered-home")
    }

    /// Guests never see the name step.
    func testGuestSkipsTheNameStep() {
        let app = launch(["-auth.isSignedIn", "YES", "-auth.provider", "guest"])
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.textFields["First name"].exists)
    }

    /// Fresh install: showcase pages appear, Skip jumps to the goal picker.
    func testFreshInstallShowsShowcaseAndSkipWorks() {
        let app = XCUIApplication()
        app.launch()   // no launch args: hasCompletedOnboarding is false
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 15))
        app.buttons["Next"].tap()                       // -> showcase 1
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 5))
        attach(app, "4-showcase-1")
        app.buttons["Skip"].tap()                       // -> goals page
        XCTAssertFalse(app.buttons["Skip"].exists)
        attach(app, "5-after-skip")
    }
}
```

- [ ] **Step 2: Run the flow tests on a clean install**

```bash
xcrun simctl uninstall "iPhone 17" com.jasonlu.Dial--Down--Breath--Stretch 2>/dev/null
xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchUITests/RegistrationFlowUITests" -resultBundlePath <scratch>/flow.xcresult
```
Expected: 4 tests pass. Export attachments and Read the PNGs to visually confirm: name step prefilled; Home greeting reads "Good morning, Ada" (or the time-of-day equivalent); showcase page with screenshot and Skip; after Skip the goal picker. If the known UITest-runner failure blocks the run, capture the same states with `xcrun simctl launch` + `xcrun simctl io "iPhone 17" screenshot` and say so in the report.

- [ ] **Step 3: Confirm sign-out keeps device onboarding**

Manually or via a unit assertion in `AuthManagerTests`, add:

```swift
    @Test func signOutDoesNotResetDeviceLevelOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let manager = makeManager()
        manager.continueAsGuest()
        manager.signOut()
        #expect(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
```
Run `-only-testing:"Breath - Relax & StretchTests/AuthManagerTests"`. Expected: PASS.

- [ ] **Step 4: Full unit-suite regression run**

Run `-only-testing:"Breath - Relax & StretchTests"`. Expected: everything passes except the known pre-existing `CuratedContentIntegrityTests` failures. Report any other failure verbatim.

- [ ] **Step 5: Update the knowledge graph**

```bash
cd "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch" && graphify update .
git status --short
```
Commit any tracked `graphify-out/` changes only if the repo tracks that directory (`git check-ignore graphify-out` prints nothing when tracked).

- [ ] **Step 6: Commit and hand off**

```bash
git add "Breath - Relax & StretchUITests/RegistrationFlowUITests.swift" "Breath - Relax & StretchTests/AuthManagerTests.swift"
git commit -m "test(auth): registration flow UI tests, sign-out keeps onboarding" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

Then invoke `superpowers:finishing-a-development-branch`.

---

## Self-review (against the spec)

- **Spec §1 launch flow:** showcase pages Task 10; unregistered-on-onboarded-device path Tasks 6+8; fresh-install order unchanged (`OnboardingGate` -> `AuthView`) and verified Task 11.
- **Spec §2 name capture/registration:** three outcomes Tasks 2+6; name step all providers Tasks 5+8+9; `firstName`/`lastName` + composed `displayName` + first-name greeting Tasks 5+9; guests skip Task 8 (and keep the tour, called out).
- **Spec §3 tour flags:** per-account flag Task 7, wired Task 8; sign-out keeps `hasCompletedOnboarding` Task 11 Step 3.
- **Spec §4 backend:** nullable columns + RLS-compatible upsert Tasks 3+4, approval gate Task 4.
- **Spec §5 testing:** pure routing, `AuthManager`, `SupabaseService`, simulator paths — Tasks 2, 5, 3, 11. Spec's "local per-account registered flag" is implemented as "complete local first+last name", which is per-account because sign-out clears it (Task 5).
- **Type consistency:** `PersonName.split(fullName:)`, `RegistrationCoordinator.resolve(userID:local:providerPrefill:hasBackendSession:)`, `completeName(_:userID:)`, `SupabaseProfileStoring.upsertProfileName(id:name:)`, `AppGuideSeen.markSeen/isSeen/migrateLegacy` are used identically across Tasks 1-8.
- **Known caveat:** `SessionRecorder` still uploads `UserProfile.displayName` as `display_name`; Task 8 Step 3 keeps that equal to the composed name.
