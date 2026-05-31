import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: String
    var displayName: String
    var totalMinutes: Int
    var totalPoints: Int
    var streak: Int
    var lastSessionDate: Date?
    var badges: [String]

    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
        self.totalMinutes = 0
        self.totalPoints = 0
        self.streak = 0
        self.badges = []
    }
}
