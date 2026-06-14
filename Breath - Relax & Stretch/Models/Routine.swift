import Foundation
import SwiftData

@Model
final class Routine {
    var uuid: UUID
    var name: String
    var exerciseIDs: [UUID]     // ordered list of Exercise UUIDs
    var authorID: String?
    var authorName: String?      // display name captured at publish time
    var borrowedFromID: UUID?    // tracks the original routine this was forked from
    var isPublic: Bool
    var borrowCount: Int         // times forked by other users (popularity)
    var createdAt: Date

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
