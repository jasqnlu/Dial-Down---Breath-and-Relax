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
    /// Whether the exercise is performed on both sides at once / inherently
    /// bilateral (true) vs. one side at a time (false). Unilateral exercises
    /// get a mid-duration "switch sides" cue in the session player.
    /// Defaults to true — most stretches are bilateral — so the seed JSON only
    /// needs to specify `false` for the one-side-at-a-time exercises.
    var isBilateral: Bool = true
    var posesData: Data = Data()

    /// Decoded pose keyframes for the stick-figure animation.
    var poses: [ExercisePose] {
        get { (try? JSONDecoder().decode([ExercisePose].self, from: posesData)) ?? [] }
        set { posesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// Bundle-relative file name of Jason's self-filmed demo clip.
    var localVideoName: String? = nil

    /// Resolved bundle URL — nil when unset OR the file isn't bundled,
    /// so the UI can always fall back to the placeholder card.
    var localVideoURL: URL? {
        guard let name = localVideoName, !name.isEmpty else { return nil }
        let ns = name as NSString
        return Bundle.main.url(forResource: ns.deletingPathExtension,
                               withExtension: ns.pathExtension.isEmpty ? "mp4" : ns.pathExtension)
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
        caution: String? = nil,
        isBilateral: Bool = true
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
        self.isBilateral = isBilateral
    }
}
