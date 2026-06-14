import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable {
    case stretch = "Stretch"
    case breath = "Breath"
    case both = "Both"
}

@Model
final class Exercise {
    var uuid: UUID
    var name: String
    var type: ExerciseType
    var targetBodyParts: [String]   // BodyPart names this exercise targets
    var durationSeconds: Int
    var difficulty: Int             // 1 = easy, 2 = medium, 3 = hard
    var instructions: [String]      // step-by-step instructions
    var mediaURL: String?           // animation or image URL
    var caution: String?            // optional safety note / contraindication

    /// Human-readable duration: "30s", "2m", "1m 30s"
    var durationFormatted: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }

    init(
        uuid: UUID = UUID(),
        name: String,
        type: ExerciseType,
        targetBodyParts: [String],
        durationSeconds: Int,
        difficulty: Int,
        instructions: [String],
        mediaURL: String? = nil,
        caution: String? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.type = type
        self.targetBodyParts = targetBodyParts
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.instructions = instructions
        self.mediaURL = mediaURL
        self.caution = caution
    }
}
