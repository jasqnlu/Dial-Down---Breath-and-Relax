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
    @StateObject private var miniRoutine = MiniRoutineState()
    @State private var quickStartExercise: Exercise?
    @State private var showingMiniRoutineSession = false

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
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if bodyParts.count > 1 {
                            Text(bodyParts.joined(separator: ", "))
                                .font(.luminaCaption)
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                        }
                        if !resolver.direct.isEmpty {
                            exerciseSection(title: "\(resolver.direct.count) exercise\(resolver.direct.count == 1 ? "" : "s")", exercises: resolver.direct)
                        }
                        if !resolver.related.isEmpty {
                            exerciseSection(title: relatedSectionTitle, footer: relatedFooterText, exercises: resolver.related)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        // `.safeAreaInset` stacks bottom-up in application order: the LAST
        // one applied claims the outermost slot, right at the screen edge —
        // exactly the 80pt zone the real floating `CustomTabBar` overlay
        // occupies. `miniRoutineBar` must be applied BEFORE
        // `.floatingTabBarClearance()` so it lands just above that reserved
        // zone instead of underneath the tab bar (where its taps would be
        // swallowed by the tab bar sitting on top of it).
        .safeAreaInset(edge: .bottom) {
            if !miniRoutine.exercises.isEmpty {
                miniRoutineBar
            }
        }
        .floatingTabBarClearance()
        .sheet(item: $quickStartExercise) { exercise in
            SessionPlayerView(exercises: [exercise])
        }
        .sheet(isPresented: $showingMiniRoutineSession) {
            SessionPlayerView(exercises: miniRoutine.exercises)
        }
    }

    @ViewBuilder
    private func exerciseSection(title: String, footer: String? = nil, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurfaceVariant)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(exercises, id: \.uuid) { exercise in
                    ExerciseGridTile(
                        exercise: exercise,
                        badge: .add(isSelected: miniRoutine.contains(exercise))
                    ) {
                        quickStartExercise = exercise
                    } onBadgeTap: {
                        miniRoutine.toggle(exercise)
                    }
                }
            }

            if let footer {
                Text(footer)
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
        }
    }

    private var miniRoutineBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(miniRoutine.exercises.count) selected")
                    .font(.luminaCardTitle)
                let m = miniRoutine.totalSeconds / 60, s = miniRoutine.totalSeconds % 60
                Text("\(m):\(String(format: "%02d", s)) mini routine")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            Spacer(minLength: 8)
            Button {
                showingMiniRoutineSession = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
            }
            .buttonStyle(LuminaPillButtonStyle(kind: .prominent, compact: true))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 8)
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
