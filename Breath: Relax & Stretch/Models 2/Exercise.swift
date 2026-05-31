import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable {
    case stretch = "Stretch"
    case breath = "Breath"
    case both = "Both"
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var type: ExerciseType
    var targetBodyParts: [String]   // BodyPart names this exercise targets
    var durationSeconds: Int
    var difficulty: Int             // 1 = easy, 2 = medium, 3 = hard
    var instructions: [String]      // step-by-step instructions
    var mediaURL: String?           // animation or image URL

    init(
        id: UUID = UUID(),
        name: String,
        type: ExerciseType,
        targetBodyParts: [String],
        durationSeconds: Int,
        difficulty: Int,
        instructions: [String],
        mediaURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.targetBodyParts = targetBodyParts
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.instructions = instructions
        self.mediaURL = mediaURL
    }
}
