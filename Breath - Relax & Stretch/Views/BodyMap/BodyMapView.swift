import SwiftUI
import SwiftData

struct BodyMapView: View {
    @State private var currentLayer: BodyLayer = .skin
    @State private var highlightedPart: String? = nil
    @State private var navigateToPart: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Layer", selection: $currentLayer) {
                    ForEach(BodyLayer.allCases, id: \.self) { layer in
                        Text(layer.rawValue).tag(layer)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                BodyMapPlaceholder(layer: currentLayer, highlightedPart: $highlightedPart)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let part = highlightedPart {
                    BodyPartInfoBanner(partName: part) {
                        navigateToPart = part
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Body Map")
            .animation(.easeInOut(duration: 0.3), value: currentLayer)
            .animation(.easeInOut(duration: 0.2), value: highlightedPart)
            .navigationDestination(item: $navigateToPart) { part in
                BodyPartExercisesView(bodyPart: part)
            }
        }
    }
}

// MARK: - Placeholder body map (grid of tappable regions)

struct BodyMapPlaceholder: View {
    let layer: BodyLayer
    @Binding var highlightedPart: String?

    let regions = [
        "Head", "Neck", "Left Shoulder", "Right Shoulder",
        "Chest", "Left Arm", "Right Arm", "Core",
        "Upper Back", "Lower Back", "Left Leg", "Right Leg",
        "Left Foot", "Right Foot"
    ]

    var layerColor: Color {
        switch layer {
        case .skin:     return .orange
        case .muscle:   return .red
        case .skeleton: return .gray
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(regions, id: \.self) { region in
                    Button {
                        withAnimation {
                            highlightedPart = highlightedPart == region ? nil : region
                        }
                    } label: {
                        Text(region)
                            .font(.subheadline)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                highlightedPart == region
                                    ? layerColor.opacity(0.35)
                                    : Color(.secondarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        highlightedPart == region ? layerColor : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(region) body region")
                    .accessibilityHint("Double tap to select and find exercises")
                }
            }
            .padding()
        }
    }
}

// MARK: - Info banner

struct BodyPartInfoBanner: View {
    let partName: String
    let onFindExercises: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(partName)
                    .font(.headline)
                Text("Tap to find stretches targeting this area")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                onFindExercises()
            } label: {
                Label("Find Exercises", systemImage: "figure.mind.and.body")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint.opacity(0.12))
                    .foregroundStyle(.tint)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.regularMaterial)
        .shadow(color: .black.opacity(0.08), radius: 6, y: -2)
    }
}

// MARK: - Filtered exercise list for a body part

struct BodyPartExercisesView: View {
    let bodyPart: String
    @Query private var allExercises: [Exercise]

    private var filtered: [Exercise] {
        allExercises.filter { ex in
            ex.targetBodyParts.contains { $0.localizedCaseInsensitiveContains(bodyPart)
                || bodyPart.localizedCaseInsensitiveContains($0) }
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No Exercises Found",
                    systemImage: "figure.mind.and.body",
                    description: Text("No exercises target \(bodyPart) yet.")
                )
            } else {
                List {
                    ForEach(filtered, id: \.uuid) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            ExerciseRow(exercise: exercise)
                        }
                    }
                }
            }
        }
        .navigationTitle(bodyPart)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BodyMapView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
