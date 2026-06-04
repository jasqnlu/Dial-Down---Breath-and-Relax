import Foundation
import SwiftData

@Model
final class UserProfile {
    var profileID: String
    var displayName: String
    var totalMinutes: Int
    var totalPoints: Int
    var streak: Int
    var lastSessionDate: Date?
    var badges: [String]

    init(profileID: String, displayName: String) {
        self.profileID = profileID
        self.displayName = displayName
        self.totalMinutes = 0
        self.totalPoints = 0
        self.streak = 0
        self.badges = []
    }
}
