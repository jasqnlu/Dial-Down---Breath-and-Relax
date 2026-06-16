import Foundation
import SwiftData

@Model
final class Session {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var routineID: UUID = UUID()
    var startedAt: Date = Date()
    var completedAt: Date? = nil
    var completionPercent: Double = 0
    var pointsEarned: Int = 0

    var durationMinutes: Int {
        guard let end = completedAt else { return 0 }
        return Int(end.timeIntervalSince(startedAt) / 60)
    }

    init(
        uuid: UUID = UUID(),
        routineID: UUID,
        startedAt: Date = Date(),
        completionPercent: Double = 0,
        pointsEarned: Int = 0
    ) {
        self.uuid = uuid
        self.routineID = routineID
        self.startedAt = startedAt
        self.completionPercent = completionPercent
        self.pointsEarned = pointsEarned
    }
}
