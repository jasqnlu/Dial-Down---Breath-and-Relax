import Foundation
import SwiftData

@Model
final class Routine {
    var uuid: UUID
    var name: String
    var exerciseIDs: [UUID]     // ordered list of Exercise UUIDs
    var authorID: String?
    var borrowedFromID: UUID?   // tracks the original routine this was forked from
    var isPublic: Bool
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        name: String,
        exerciseIDs: [UUID] = [],
        authorID: String? = nil,
        borrowedFromID: UUID? = nil,
        isPublic: Bool = false
    ) {
        self.uuid = uuid
        self.name = name
        self.exerciseIDs = exerciseIDs
        self.authorID = authorID
        self.borrowedFromID = borrowedFromID
        self.isPublic = isPublic
        self.createdAt = Date()
    }
}
