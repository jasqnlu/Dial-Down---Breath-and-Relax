import SwiftUI

/// A per-exercise accent color, so each exercise's PoseGlyphIcon reads as
/// visually distinct instead of every exercise in a category sharing one
/// flat ExerciseCategory.accentColor.
extension Color {
    /// Deterministic color for one exercise, keyed by its name (the same
    /// stable string PoseArchetypeMapping's manual overrides already key
    /// on). Fixed saturation/brightness keeps every result mid-toned and
    /// clearly colored — never washed-out white, sunk to black, or at a
    /// neon/muddy extreme.
    static func forExercise(named name: String) -> Color {
        Color(hue: exerciseHue(for: name), saturation: 0.6, brightness: 0.62)
    }

    /// Hue (0..<1) derived from an FNV-1a hash of the name. `String.hashValue`
    /// is randomized per process launch, so a real hash is used instead — this
    /// must return the same hue for the same name across app launches.
    static func exerciseHue(for name: String) -> Double {
        var hash: UInt32 = 2166136261
        for byte in name.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        return Double(hash % 360) / 360.0
    }
}
