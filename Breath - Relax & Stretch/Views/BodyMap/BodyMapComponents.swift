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
        // A marked region is a muscle group / coarse name, an anatomical
        // sub-head ("Left Triceps Long Head"), or a joint region ("Left Hip").
        // Heads and joints both match their own tagged exercises directly
        // (distinct, dedicated content), and fall back to the parent/crossing
        // muscles' exercises as "related" so a region with no curated
        // stretches yet still shows something useful. Group/coarse names keep
        // the original behaviour: migrate coarse → fine, then category fallback.
        var directNames: [String] = []
        var parentNames: [String] = []
        for region in regions {
            if let parent = MuscleGroup.parentOfHead(region) {
                directNames.append(region)
                parentNames.append(parent)
            } else if JointRegion.isJoint(region) {
                directNames.append(region)
                parentNames.append(contentsOf: MuscleGroup.migrate([region]))
            } else {
                directNames.append(contentsOf: MuscleGroup.migrate([region]))
            }
        }
        let directSet = Set(directNames.map { $0.lowercased() })
        let parentSet = Set(MuscleGroup.migrate(parentNames).map { $0.lowercased() })
        let categories = ExerciseCategory.categories(for: directNames + parentNames)

        var directList: [Exercise] = []
        var relatedList: [Exercise] = []
        for exercise in exercises {
            // Pure breathing exercises have no body-part target of their own;
            // never let one leak into a body-map region via the same-area
            // fallback below (mirrors ExerciseGraphView's type filtering).
            guard exercise.type != .breath else { continue }
            let targets = exercise.targetBodyParts
            let lowered = targets.map { $0.lowercased() }
            if lowered.contains(where: { directSet.contains($0) }) {
                directList.append(exercise)
            } else if lowered.contains(where: { parentSet.contains($0) }) {
                relatedList.append(exercise)                       // parent-muscle fallback
            } else if !categories.isEmpty,
                      !categories.isDisjoint(with: ExerciseCategory.categories(for: targets)) {
                relatedList.append(exercise)                       // same-area fallback
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
                            Text(relatedSectionTitle)
                        } footer: {
                            Text(relatedFooterText)
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

    // A single tapped region is named directly ("Spinal Erectors") rather
    // than lumped into generic "this area" copy, so a specific muscle/joint
    // reads as its own distinct thing even when it has no exercises of its
    // own yet and is falling back to a nearby one's stretches.
    private var relatedSectionTitle: String {
        bodyParts.count == 1 ? "Related to \(bodyParts[0])" : "More from this area"
    }

    private var relatedFooterText: String {
        guard bodyParts.count == 1 else {
            return resolver.direct.isEmpty
                ? "No exercises target this exact spot yet — here are related ones for the same area."
                : "Other exercises that work the same area."
        }
        return resolver.direct.isEmpty
            ? "No exercises target \(bodyParts[0]) directly yet — here are ones for nearby muscles."
            : "Other exercises that work near \(bodyParts[0])."
    }

    private var emptyDescription: String {
        bodyParts.count == 1
            ? "No exercises target \(bodyParts[0]) yet."
            : "No exercises target the marked areas yet."
    }
}
