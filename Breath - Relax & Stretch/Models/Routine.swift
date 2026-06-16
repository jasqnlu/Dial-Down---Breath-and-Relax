import Foundation
import SwiftData

@Model
final class Routine {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var exerciseIDs: [UUID] = []
    var authorID: String? = nil
    var authorName: String? = nil
    var borrowedFromID: UUID? = nil
    var isPublic: Bool = false
    var borrowCount: Int = 0
    var createdAt: Date = Date()

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        authorID: String? = nil,
        authorName: String? = nil,
        borrowedFromID: UUID? = nil,
        isPublic: Bool = false,
        borrowCount: Int = 0
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.authorID = authorID
        self.authorName = authorName
        self.borrowedFromID = borrowedFromID
        self.isPublic = isPublic
        self.borrowCount = borrowCount
        self.createdAt = Date()
    }
}
