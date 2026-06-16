import Foundation
import SwiftData

@Model
final class UserProfile {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var profileID: String = ""
    var displayName: String = ""
    var totalMinutes: Int = 0
    var totalPoints: Int = 0
    var streak: Int = 0
    var lastSessionDate: Date? = nil
    var badges: [String] = []

    init(profileID: String, displayName: String) {
        self.profileID = profileID
        self.displayName = displayName
    }
}
