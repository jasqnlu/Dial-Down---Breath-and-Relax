import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable {
    case stretch = "Stretch"
    case breath = "Breath"
    case both = "Both"
}

@Model
final class Exercise {
    // Inline defaults required for CloudKit (iCloud) sync compatibility.
    var uuid: UUID = UUID()
    var name: String = ""
    var type: ExerciseType = ExerciseType.stretch
    var targetBodyParts: [String] = []
    var durationSeconds: Int = 60
    var difficulty: Int = 1
    var instructions: [String] = []
    var mediaURL: String? = nil
    var caution: String? = nil
    var posesData: Data = Data()

    /// Decoded pose keyframes for the stick-figure animation.
    var poses: [ExercisePose] {
        get { (try? JSONDecoder().decode([ExercisePose].self, from: posesData)) ?? [] }
        set { posesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

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
