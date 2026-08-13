import SwiftUI

/// What (if anything) sits in a tile's bottom-trailing corner. `.none` is
/// plain browsing (search results, category groups) — the whole tile is
/// one tap target going to `onTap`. `.add` is used by both the Customize
/// add-mode flow and Body Map's mini-routine builder: the corner circle is
/// its own tap target (`onBadgeTap`), independent of the tile's main
/// `onTap` (which, per call site, is either "go to detail" or "start this
/// exercise now" — ExerciseGridTile itself doesn't know or care which).
enum ExerciseGridBadge: Equatable {
    case none
    case add(isSelected: Bool)
}

/// The one exercise-list visual used everywhere an exercise list renders:
/// Exercises tab search results, a category group screen, and Body Map's
/// region list. Replaces the old ExerciseRow (text + a video-or-gray-icon
/// thumbnail) at all three call sites.
struct ExerciseGridTile: View {
    let exercise: Exercise
    var badge: ExerciseGridBadge = .none
    var onTap: () -> Void
    var onBadgeTap: (() -> Void)? = nil

    private var category: ExerciseCategory {
        ExerciseCategory.primary(for: exercise.targetBodyParts)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    ExerciseArt(exercise: exercise, category: category, size: 112)
                        .frame(maxWidth: .infinity)

                    badgeView
                }

                Text(exercise.name)
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(exercise.durationFormatted) · \(exercise.type.rawValue)")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .luminaCard(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.durationFormatted), \(exercise.type.rawValue)")
    }

    @ViewBuilder
    private var badgeView: some View {
        switch badge {
        case .none:
            EmptyView()
        case .add(let isSelected):
            Button {
                onBadgeTap?()
            } label: {
                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.luminaOnSurfaceVariant)
                    .frame(width: 26, height: 26)
                    .background(isSelected ? Color.luminaPrimary : Color.luminaContainer, in: Circle())
            }
            .padding(8)
            .accessibilityLabel(isSelected ? "Remove \(exercise.name)" : "Add \(exercise.name)")
        }
    }
}
