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

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        borrowedFromID: UUID? = nil,
        exerciseDurationOverrides: [UUID: Int] = [:]
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.borrowedFromID = borrowedFromID
        self.createdAt = Date()
        self.exerciseDurationOverrides = exerciseDurationOverrides
    }
}
