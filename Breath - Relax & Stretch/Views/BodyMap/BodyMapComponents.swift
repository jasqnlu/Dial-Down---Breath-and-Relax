import SwiftUI
import SwiftData

// MARK: - Marked-areas banner
//
// Appears once the user has marked one or more regions by tapping the 3D body.
// Summarises what's marked and lets them jump to a combined exercise list.

struct MarkedAreasBanner: View {
    let regionNames: [String]
    let onFind:  () -> Void
    let onClear: () -> Void

    private var title: String {
        regionNames.count == 1
            ? regionNames[0]
            : "\(regionNames.count) areas marked"
    }

    private var subtitle: String {
        regionNames.count == 1
            ? "Find stretches that target this area"
            : regionNames.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.luminaTitle)
                Text(subtitle)
                    .font(.luminaCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Clear marked areas")

            Button(action: onFind) {
                Label("Find Exercises", systemImage: "figure.mind.and.body")
            }
            .buttonStyle(LuminaPillButtonStyle(compact: true))
            .accessibilityLabel("Find exercises for marked areas")
        }
        .luminaCard(padding: 16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Region → exercise resolution
//
// Marked regions use the body map's COARSE names ("Core", "Left Arm", "Hips"),
// but exercises target the FINE muscle-group names the seed data uses ("Abs",
// "Left Biceps", "Left Hip Flexors"). The old code matched the two with a naive
// bidirectional substring test, so coarse regions that don't share a substring
// with any muscle name ("Core"↛"Abs", "Left Arm"↛"Left Biceps") silently
// matched nothing.
//
// This resolver instead translates coarse → fine via `MuscleGroup.migrate`
// (the same mapping the rest of the app uses), matches exactly, and then adds a
// same-category fallback: exercises in the marked region's `ExerciseCategory`
// that don't directly hit the muscle group. So a region with few specific
// stretches surfaces related ones from the same area instead of nothing — and
// never the whole catalog.
struct RegionExerciseResolver {
    /// Exercises that directly target one of the marked muscle groups.
    let direct: [Exercise]
    /// Other exercises in the same body-area category (the "related" fallback).
    let related: [Exercise]

    init(regions: [String], exercises: [Exercise]) {
        // Migrate coarse/joint region names ("Left Knee") to the fine
        // muscle-group names exercises target ("Left Quadriceps", …).
        let fineNames = MuscleGroup.migrate(regions)
        let fineSet = Set(fineNames.map { $0.lowercased() })
        let categories = ExerciseCategory.categories(for: fineNames)

        var directList: [Exercise] = []
        var relatedList: [Exercise] = []
        for exercise in exercises {
            let targets = exercise.targetBodyParts
            if targets.contains(where: { fineSet.contains($0.lowercased()) }) {
                directList.append(exercise)
            } else if !categories.isEmpty,
                      !categories.isDisjoint(with: ExerciseCategory.categories(for: targets)) {
                relatedList.append(exercise)
            }
        }
        self.direct = directList.sorted { $0.name < $1.name }
        self.related = relatedList.sorted { $0.name < $1.name }
    }

    var isEmpty: Bool { direct.isEmpty && related.isEmpty }
}

// MARK: - Filtered exercise list for one or more body parts

struct BodyPartExercisesView: View {
    let bodyParts: [String]
    @Query private var allExercises: [Exercise]

    init(bodyPart: String)        { self.bodyParts = [bodyPart] }
    init(bodyParts: [String])     { self.bodyParts = bodyParts }

    private var resolver: RegionExerciseResolver {
        RegionExerciseResolver(regions: bodyParts, exercises: allExercises)
    }

    private var navTitle: String {
        bodyParts.count == 1 ? bodyParts[0] : "\(bodyParts.count) Areas"
    }

    var body: some View {
        let resolver = resolver
        return Group {
            if resolver.isEmpty {
                ContentUnavailableView(
                    "No Exercises Found",
                    systemImage: "figure.mind.and.body",
                    description: Text(emptyDescription)
                )
            } else {
                List {
                    if bodyParts.count > 1 {
                        Section {
                            Text(bodyParts.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } header: {
                            Text("Targeting")
                        }
                    }
                    if !resolver.direct.isEmpty {
                        Section {
                            exerciseRows(resolver.direct)
                        } header: {
                            Text("\(resolver.direct.count) exercise\(resolver.direct.count == 1 ? "" : "s")")
                        }
                    }
                    if !resolver.related.isEmpty {
                        Section {
                            exerciseRows(resolver.related)
                        } header: {
                            Text("More from this area")
                        } footer: {
                            Text(resolver.direct.isEmpty
                                 ? "No exercises target this exact spot yet — here are related ones for the same area."
                                 : "Other exercises that work the same area.")
                        }
                    }
                }
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
    }

    @ViewBuilder
    private func exerciseRows(_ exercises: [Exercise]) -> some View {
        ForEach(exercises, id: \.uuid) { exercise in
            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                ExerciseRow(exercise: exercise)
            }
        }
    }

    private var emptyDescription: String {
        bodyParts.count == 1
            ? "No exercises target \(bodyParts[0]) yet."
            : "No exercises target the marked areas yet."
    }
}
