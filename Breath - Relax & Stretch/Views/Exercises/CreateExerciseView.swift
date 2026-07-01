import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Basic Info
    @State private var name: String = ""
    @State private var exerciseType: ExerciseType = .stretch

    // MARK: - Duration & Difficulty
    @State private var durationSeconds: Int = 30
    @State private var difficulty: Int = 1

    // MARK: - Target Body Parts
    @State private var selectedBodyParts: Set<String> = []

    // MARK: - Instructions
    @State private var steps: [String] = [""]

    // MARK: - Video link
    @State private var videoURL: String = ""

    /// Parsed video link, used for the live "detected platform" hint.
    private var detectedVideo: VideoSource? {
        VideoSource(urlString: videoURL)
    }

    // MARK: - Constants
    private let allBodyParts: [String] = [
        "Head", "Neck",
        "Left Shoulder", "Right Shoulder",
        "Chest", "Upper Back", "Lower Back", "Core",
        "Hips", "Glutes",
        "Left Arm", "Right Arm",
        "Left Elbow", "Right Elbow",
        "Left Forearm", "Right Forearm",
        "Left Hand", "Right Hand",
        "Left Leg", "Right Leg",
        "Left Hamstring", "Right Hamstring",
        "Left Knee", "Right Knee",
        "Left Calf", "Right Calf",
        "Left Shin", "Right Shin",
        "Left Ankle", "Right Ankle",
        "Left Foot", "Right Foot",
    ]

    // MARK: - Validation
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !selectedBodyParts.isEmpty
        && steps.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: - Helpers
    private func formattedDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                durationDifficultySection
                targetBodyPartsSection
                instructionsSection
                videoSection
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("Basic Info") {
            TextField("Exercise name", text: $name)
                .textInputAutocapitalization(.words)

            Picker("Type", selection: $exerciseType) {
                ForEach(ExerciseType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
        }
    }

    private var durationDifficultySection: some View {
        Section("Duration & Difficulty") {
            Stepper(
                value: $durationSeconds,
                in: 15...600,
                step: 15
            ) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(formattedDuration(durationSeconds))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty")
                    .font(.body)
                Picker("Difficulty", selection: $difficulty) {
                    Text("Easy").tag(1)
                    Text("Medium").tag(2)
                    Text("Hard").tag(3)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
        }
    }

    private var targetBodyPartsSection: some View {
        Section {
            ForEach(allBodyParts, id: \.self) { (part: String) in
                Button {
                    if selectedBodyParts.contains(part) {
                        selectedBodyParts.remove(part)
                    } else {
                        selectedBodyParts.insert(part)
                    }
                } label: {
                    HStack {
                        Text(part)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedBodyParts.contains(part) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Target Body Parts")
        } footer: {
            if selectedBodyParts.isEmpty {
                Text("Select at least one body part.")
                    .foregroundStyle(.red)
            }
        }
    }

    private var instructionsSection: some View {
        Section {
            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Circle())
                        .padding(.top, 8)

                    TextField("Step \(index + 1)", text: $steps[index], axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .onDelete { indexSet in
                steps.remove(atOffsets: indexSet)
                if steps.isEmpty {
                    steps.append("")
                }
            }

            Button {
                steps.append("")
            } label: {
                Label("Add Step", systemImage: "plus.circle")
            }
        } header: {
            Text("Instructions")
        } footer: {
            let hasContent = steps.contains {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !hasContent {
                Text("At least one instruction step is required.")
                    .foregroundStyle(.red)
            }
        }
    }

    private var videoSection: some View {
        Section {
            TextField("https://youtube.com/watch?v=…", text: $videoURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textContentType(.URL)
                .submitLabel(.done)
        } header: {
            Text("Video (optional)")
        } footer: {
            let trimmed = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                Text("Paste a YouTube, Vimeo, or other video link to show a demo of this exercise.")
            } else if let detectedVideo {
                Label("\(detectedVideo.platformName) link detected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("That doesn't look like a valid video link.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Save

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSteps = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let trimmedVideo = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)

        let exercise = Exercise(
            name: trimmedName,
            type: exerciseType,
            targetBodyParts: Array(selectedBodyParts).sorted(),
            durationSeconds: durationSeconds,
            difficulty: difficulty,
            instructions: trimmedSteps,
            mediaURL: trimmedVideo.isEmpty ? nil : trimmedVideo
        )

        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CreateExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
