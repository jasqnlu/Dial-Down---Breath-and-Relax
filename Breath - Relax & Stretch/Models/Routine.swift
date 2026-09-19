import Foundation
import SwiftData

@Model
final class Routine {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var exerciseIDs: [UUID] = []
    var borrowedFromID: UUID? = nil
    var createdAt: Date = Date()
    /// Per-exercise duration overrides, keyed by exercise UUID — seconds.
    /// Absent key means "use the exercise's own durationSeconds." Set via
    /// RoutineBuilderView's +/− stepper, read by SessionPlayerView during
    /// playback (see `effectiveDuration(for:)`).
    var exerciseDurationOverrides: [UUID: Int] = [:]
    /// Whether this routine is one of the user's "Today" launch candidates
    /// — replaces the old single `pinnedTodayRoutineID` AppStorage string,
    /// which could only ever point at one routine. Several routines can be
    /// pinned at once; `pinnedOrder` breaks the tie for which one Today
    /// actually shows/starts. Additive, defaulted field — no explicit
    /// SwiftData migration needed (see the inline-defaults comment above).
    var isPinnedToToday: Bool = false
    /// Priority among pinned routines, ascending — 0 is shown first. Only
    /// meaningful when `isPinnedToToday` is true; irrelevant (but left as
    /// whatever it last was) once unpinned, so re-pinning doesn't need to
    /// invent a fresh value from scratch.
    var pinnedOrder: Int = 0
    /// `AuthManager.backendID` of whoever created this routine — Supabase
    /// auth.uid() when signed in, the local anonymous UUID otherwise. Empty
    /// string means "not yet claimed" (routines created before this field
    /// existed); `Breath__Relax___StretchApp.claimOwnerlessRoutines()` backfills
    /// those once at launch. Every query site filters on this so one
    /// device's routines don't leak across different signed-in accounts.
    var ownerID: String = ""

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        borrowedFromID: UUID? = nil,
        exerciseDurationOverrides: [UUID: Int] = [:],
        isPinnedToToday: Bool = false,
        pinnedOrder: Int = 0,
        ownerID: String = ""
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.borrowedFromID = borrowedFromID
        self.createdAt = Date()
        self.exerciseDurationOverrides = exerciseDurationOverrides
        self.isPinnedToToday = isPinnedToToday
        self.pinnedOrder = pinnedOrder
        self.ownerID = ownerID
    }
}
