import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var routineID: UUID
    var startedAt: Date
    var completedAt: Date?
    var completionPercent: Double
    var pointsEarned: Int

    var durationMinutes: Int {
        guard let end = completedAt else { return 0 }
        return Int(end.timeIntervalSince(startedAt) / 60)
    }

    init(
        id: UUID = UUID(),
        routineID: UUID,
        startedAt: Date = Date(),
        completionPercent: Double = 0,
        pointsEarned: Int = 0
    ) {
        self.id = id
        self.routineID = routineID
        self.startedAt = startedAt
        self.completionPercent = completionPercent
        self.pointsEarned = pointsEarned
    }
}
