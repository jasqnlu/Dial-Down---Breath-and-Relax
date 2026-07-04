import SwiftUI
import SwiftData

// MARK: - Region → exercise search expansion
//
// Most regions search by their own name, but the fine-grained finger regions
// have no dedicated exercises, so they fall back to the hand / forearm.

private let fingerNames = ["Thumb", "Index", "Middle", "Ring", "Pinky"]

func exerciseSearchTerms(for region: String) -> [String] {
    if fingerNames.contains(where: { region.contains($0) }) {
        let side = region.hasPrefix("Left") ? "Left" : "Right"
        return [region, "\(side) Hand", "\(side) Forearm", "Hand"]
    }
    return [region]
}

// MARK: - Marked-areas banner
//
// Appears once the user has marked one or more regions (by drawing or tapping).
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
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
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
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint.opacity(0.12))
                    .foregroundStyle(.tint)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Find exercises for marked areas")
        }
        .padding()
        .background(.regularMaterial)
        .shadow(color: Color.primary.opacity(0.08), radius: 6, y: -2)
    }
}

// MARK: - Filtered exercise list for one or more body parts

struct BodyPartExercisesView: View {
    let bodyParts: [String]
    @Query private var allExercises: [Exercise]

    init(bodyPart: String)        { self.bodyParts = [bodyPart] }
    init(bodyParts: [String])     { self.bodyParts = bodyParts }

    /// Finger/toe marks expand to their parent so they still surface useful
    /// exercises (there are no "ring finger" stretches, but hand/forearm ones).
    private var searchParts: [String] {
        var terms = Set<String>()
        for part in bodyParts {
            for t in exerciseSearchTerms(for: part) { terms.insert(t) }
        }
        return Array(terms)
    }

    private var filtered: [Exercise] {
        let parts = searchParts
        return allExercises.filter { ex in
            ex.targetBodyParts.contains { target in
                parts.contains { part in
                    target.localizedCaseInsensitiveContains(part) ||
                    part.localizedCaseInsensitiveContains(target)
                }
            }
        }
    }

    private var navTitle: String {
        bodyParts.count == 1 ? bodyParts[0] : "\(bodyParts.count) Areas"
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
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
                    Section {
                        ForEach(filtered, id: \.uuid) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                        }
                    } header: {
                        Text("\(filtered.count) exercise\(filtered.count == 1 ? "" : "s")")
                    }
                }
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
    }

    private var emptyDescription: String {
        bodyParts.count == 1
            ? "No exercises target \(bodyParts[0]) yet."
            : "No exercises target the marked areas yet."
    }
}
