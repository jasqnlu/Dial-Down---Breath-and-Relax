import SwiftUI

/// The single place that decides "real animation, or the glyph" for an
/// exercise. Rule: real LoopingVideoThumbnail when the rendered size is at
/// least `animationThreshold` points AND the exercise has a resolved
/// demoVideoURL; PoseGlyphIcon otherwise. Every call site (search results,
/// category groups, Body Map, ForYouCard/RecommendedCard) goes through
/// this one view so the threshold only ever needs to change in one place.
struct ExerciseArt: View {
    let exercise: Exercise
    let category: ExerciseCategory
    var size: CGFloat = 112

    static let animationThreshold: CGFloat = 52

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if size >= Self.animationThreshold, let url = exercise.demoVideoURL {
                LoopingVideoThumbnail(url: url, reduceMotion: reduceMotion)
                    .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel, style: .continuous))
            } else {
                PoseGlyphIcon(exercise: exercise, category: category, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}
