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

    // MARK: - Constants
    private let allBodyParts: [String] = [
        "Head", "Neck", "Shoulders", "Chest", "Upper Back", "Lower Back",
        "Core", "Hips", "Glutes", "Quadriceps", "Hamstrings", "Calves",
        "Feet", "Arms", "Forearms"
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

    // MARK: - Save

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSteps = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let exercise = Exercise(
            name: trimmedName,
            type: exerciseType,
            targetBodyParts: Array(selectedBodyParts).sorted(),
            durationSeconds: durationSeconds,
            difficulty: difficulty,
            instructions: trimmedSteps
        )

        modelContext.insert(exercise)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CreateExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
