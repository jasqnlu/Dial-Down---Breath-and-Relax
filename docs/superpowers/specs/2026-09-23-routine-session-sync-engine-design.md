# Design: Routine and session sync engine

Date: 2026-09-23 · Owner: Sonnet 5 (interactive session with Jason)
Status: approved, ready for implementation plan

---

## Problem

Today "offline-first" only covers the seed catalog (pull-only refresh) and,
as of 2026-09-22, the `profiles` row (streak/points/minutes/name — see
`docs/investigations/2026-09-22-streak-cross-device-sync-and-backend-sync-banner.md`).
Routines and sessions never leave the device — their write paths
(`SupabaseService.uploadRoutine`/`uploadSession`) were previously deleted as
dead code (`RemoteSession was removed along with SupabaseService.uploadSession()`
— see `SupabaseDTOs.swift`). This is the last committed item in
`TODO.md` §3 "Supabase full sync": **Restore write paths** + **Sync engine**.

Server-side RLS is already correct and ready — confirmed by reading
`supabase_schema.sql` directly (not assumed): `routines` and `sessions` both
have owner-scoped insert/update/delete policies keyed on
`auth.uid()::text = author_id` / `= user_id`. This project is entirely
client-side.

## Goal

A signed-in user's routines and completed sessions sync across every device
signed into the same account, survive the app being offline or force-quit
mid-write, and reconcile sensibly when two devices both changed something
before either saw the other's write.

Explicitly out of scope (decided during brainstorming, revisit later if
needed):
- **Guest/anonymous users.** `AuthManager.backendID` falls back to the local
  anonymous UUID when there's no Supabase session; RLS rejects anon writes to
  either table by design (owner must equal `auth.uid()`). Guests stay
  local-only, exactly like today. No code needs to special-case this — the
  outbox just accumulates ops that permanently fail RLS and get dropped after
  the retry budget (see Error handling); acceptable because it's the same
  "best-effort, offline-first" posture every other upload in this app
  already has.
- **A "sync failed" UI.** The `BackendSyncBanner` added 2026-09-22 is
  specifically about the Apple token-exchange gap, not general sync health.
  Extending it (or building a separate indicator) to surface per-entity sync
  failures is a reasonable follow-up, not part of this project.
- **Incremental/delta pull.** `fetchRoutines`/`fetchSessions` fetch the
  account's full remote set each time they run (on sign-in and on each
  foreground/reconnect drain that follows a successful push). Given the
  expected per-user volume (tens to low hundreds of rows, not thousands),
  this is simpler and cheap enough to not need a `since` cursor for v1.
- **Session deletion.** No delete UI was found for sessions in this codebase
  (only `SessionDayDetailView`/`DataExportView`, both read-only). If one
  exists and I missed it, sessions need the same soft-delete treatment as
  routines — flag this during implementation if discovered.
- **Conflict resolution finer than whole-row last-write-wins.** E.g. merging
  a rename on device A with an exercise-list edit on device B (rather than
  one clobbering the other) is real field-level merge and meaningfully more
  complex. Not attempted here — whichever `updatedAt` is newer wins the
  entire row, same as the committed direction in `TODO.md` states.

## Data model changes

### `Models/Routine.swift`
Add two fields (inline defaults, so no explicit SwiftData migration needed —
same pattern the file's own comment already documents for CloudKit
compatibility):
```swift
var updatedAt: Date = Date()
var deletedAt: Date? = nil
```
`updatedAt` is bumped on every local mutation: rename, exercise list edit,
duration override change, pin/unpin, reorder. `deletedAt` is set (never nil'd
back) by whatever today calls `modelContext.delete(routine)` for a
user-owned routine — that call becomes "set `deletedAt`, don't hard-delete"
instead. Every existing fetch site that lists routines for display must add
`deletedAt == nil` to its predicate; a grep for `FetchDescriptor<Routine>`
at implementation time is how to find them all.

### `Models/Session.swift`
No changes. Sessions are created once via `SessionRecorder.record()` and
never edited or (as far as this investigation found) deleted through any UI.

### `supabase_schema.sql`
```sql
alter table routines add column if not exists updated_at timestamptz not null default now();
alter table routines add column if not exists deleted_at timestamptz;
```
No changes to `sessions` — its existing columns are already sufficient for an
append-only table.

### New: `Models/PendingSyncOp.swift`
```swift
@Model
final class PendingSyncOp {
    enum EntityType: String, Codable { case routine, session }
    enum OpType: String, Codable { case upsert, delete }

    var id: UUID = UUID()
    var entityType: EntityType = EntityType.routine
    var entityID: UUID = UUID()
    var opType: OpType = OpType.upsert
    var createdAt: Date = Date()
    var attemptCount: Int = 0
    var lastAttemptAt: Date? = nil
    var lastError: String? = nil
}
```
At most one `PendingSyncOp` exists per `(entityType, entityID)` at a time —
enqueuing when one already exists updates it in place (bumps `opType` if it
changed, e.g. upsert→delete when the user deletes something they'd just
edited; resets `attemptCount` to 0 since it's now a different operation)
rather than inserting a second row. This is enforced in `SyncOutbox.enqueue`,
not via a uniqueness constraint (SwiftData doesn't support compound
`.unique`, same reason `UserProfile.dedupe` exists as a fold-after-the-fact
routine rather than a DB constraint).

`opType == .delete` ops don't need a payload snapshot — by the time the
outbox drains, the local `Routine` row still exists (soft-deleted, so
`deletedAt` is set but the row itself is still there with an `updatedAt`
newer than the delete), so the drain step re-reads current local state to
build the upload body rather than storing a snapshot in the op itself. This
also means an upsert queued, then edited again before drain, always uploads
the latest state — no double-write, no stale-data bugs from a queued
snapshot going stale.

## Components

### `Services/SyncOutbox.swift` (new)
Thin SwiftData wrapper, `@MainActor` (matches every other `ModelContext`
touchpoint in this app — `RootView`, `SessionRecorder`, `UserProfile.dedupe`
all assume main-actor SwiftData access, no reason to deviate here):
```swift
@MainActor
struct SyncOutbox {
    func enqueue(_ entityType: PendingSyncOp.EntityType, id: UUID, op: PendingSyncOp.OpType, in context: ModelContext)
    func pendingOps(in context: ModelContext) -> [PendingSyncOp]
    func clear(_ op: PendingSyncOp, in context: ModelContext)
    func recordFailure(_ op: PendingSyncOp, error: Error, in context: ModelContext)
}
```

### `Services/SyncEngine.swift` (new)
`@MainActor final class SyncEngine: ObservableObject`, instantiated once
alongside `AuthManager`/`DeepLinkRouter` in `BreathRelaxStretchApp`.
```swift
func drain(context: ModelContext) async
func pullRemote(context: ModelContext) async
```
- `drain()`: reads `pendingOps`, and for each op still within its retry
  budget (see Error handling), calls the matching `SupabaseService` upload
  method. Success clears the op; failure calls `recordFailure` (bumps
  `attemptCount`, stores `lastError`, leaves the op queued unless the budget
  is exhausted, in which case it's cleared and only logged — matching how
  `uploadProfile`/every other best-effort call in this app already degrades).
- `pullRemote()`: fetches `fetchRoutines`/`fetchSessions` for
  `auth.backendID`, merges into local storage (see Sync semantics below).
- Triggered from: `RootView`'s existing `.onChange(of: auth.isBackendAuthenticated)`
  and `.onAppear` hooks (same two triggers `pullRemoteProfile` already uses —
  extend that function or call `pullRemote()` alongside it, implementer's
  call which reads cleaner), a `.onChange(of: scenePhase)` when it becomes
  `.active` (foreground), and an `NWPathMonitor` callback debounced to avoid
  firing on every network blip. Every local mutation site also calls
  `drain()` once immediately after enqueueing, best-effort — the queue is
  the fallback path for when that immediate attempt fails or the app isn't
  running.

### `SupabaseService.swift` additions
Mirrors the existing `uploadProfile`/`fetchProfile` shape exactly:
```swift
func uploadRoutine(_ routine: RemoteRoutine) async throws   // POST .../routines, upsert
func fetchRoutines(ownerID: String) async throws -> [RemoteRoutine]
func uploadSession(_ session: RemoteSession) async throws   // POST .../sessions, upsert
func fetchSessions(userID: String) async throws -> [RemoteSession]
```
New `RemoteRoutine`/`RemoteSession` DTOs go in `SupabaseDTOs.swift`
(`RemoteSession`'s doc comment already marks where the old one used to
live). Field mapping is a direct translation of the `routines`/`sessions`
schema columns.

### Call-site changes
- Wherever `RoutineBuilderView` (or its view model) currently
  `modelContext.insert`/mutates/`modelContext.delete`s a `Routine` it owns
  (`ownerID == auth.backendID`), bump `updatedAt` (or set `deletedAt`) and
  call `SyncOutbox.enqueue`. Borrowed/public routines the user doesn't own
  are never enqueued — RLS would reject the write anyway.
- `SessionRecorder.record()` enqueues a `.upsert` op for the new session
  right alongside its existing best-effort profile upload `Task`.

## Sync semantics

**Routines — last-write-wins by `updatedAt`:**
- Pull: for each remote routine, if no local row with that `uuid` exists,
  insert it. If one exists, compare `updatedAt`; the newer row (whole-row)
  wins and replaces the other's fields locally (or is what gets pushed, if
  local is newer and there's no pending op for it yet — shouldn't normally
  happen since local edits always enqueue, but covers the case where the
  outbox was cleared after exhausting retries).
- A remote `deleted_at` newer than the local row's last known state deletes
  it locally (sets local `deletedAt` too, filtered out of every list query).

**Sessions — append-only union:**
- Pull: insert any remote session whose `uuid` isn't already present
  locally. Never update, never delete — matches that sessions are immutable
  once recorded.
- Push: each locally-recorded session enqueues exactly one `.upsert`; once
  it clears the outbox (success or retry-budget-exhausted), it's done
  forever.

## Error handling

- Each `PendingSyncOp` gets a bounded retry budget — 5 attempts, exponential
  backoff via `lastAttemptAt` (skip an op in `drain()` if it hasn't been
  `2^attemptCount` seconds, capped at some ceiling like 5 minutes, since its
  last attempt) — enough to ride out a flaky connection without hammering
  the backend on every foreground event.
- An op that exhausts its budget is cleared from the outbox and logged via
  `Logger(subsystem: "com.jasonlu.breath", category: "sync").warning(...)`,
  same pattern as every other best-effort call site in this app
  (`uploadProfile`, `registerPushToken`, etc.). No user-facing failure state
  — explicitly out of scope, see Goal.
- A `4xx` from RLS (e.g. a stale/rotated identity) is treated the same as
  any other failure for retry-budget purposes — no special-casing "this
  will never succeed," since distinguishing permanent-vs-transient HTTP
  failures isn't information `SupabaseService` currently surfaces
  (`SupabaseError.httpError(Int)` has the status code, so this could be
  tightened later to fail fast on 4xx, but isn't necessary for v1).

## Testing

- `SyncOutboxTests` (new, in-memory `ModelContext` — same pattern
  `SeedMigratorTests` already uses): enqueue collapses to one op per
  entity, enqueue-upsert-then-enqueue-delete leaves a single `.delete` op,
  `drain()` clears successful ops and leaves failed ones with incremented
  `attemptCount`, an op past its retry budget is dropped.
- `SyncEngineTests` or extending `SupabaseServiceTests`: the merge logic
  (routine last-write-wins by `updatedAt`, tombstone propagation, session
  union-only-insert) as pure functions over `[RemoteRoutine]`/local rows,
  no network — same style as `AuthManagerTests`' fakes.
- `SupabaseServiceTests` additions: request-shaping tests for
  `uploadRoutine`/`fetchRoutines`/`uploadSession`/`fetchSessions` using the
  existing `FakeHTTPSession` seam, mirroring `signInWithGoogleReturnsThe...`.
- Manual: two-simulator repro (same pattern used to verify the profile sync
  fix on 2026-09-22) — create/edit/delete a routine on one, confirm it
  appears/updates/disappears on the other after a foreground/sign-in pull.
