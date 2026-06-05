import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var exercises: [Exercise]
    @State private var routineName = ""
    // Store IDs (plain value types) instead of @Model objects to avoid SwiftData binding issues
    @State private var selectedIDs: [UUID] = []
    @State private var isPublic = false
    @State private var showingExercisePicker = false

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + $1.durationSeconds }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Name") {
                    TextField("e.g. Morning Wake-Up", text: $routineName)
                }

                Section {
                    ForEach(selectedIDs.indices, id: \.self) { index in
                        if let exercise = exercises.first(where: { $0.uuid == selectedIDs[index] }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.name).font(.subheadline)
                                    Text("\(exercise.durationFormatted) · \(exercise.type.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    selectedIDs.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                        }
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("Exercises")
                        Spacer()
                        if !selectedIDs.isEmpty {
                            Text(totalDuration < 60 ? "\(totalDuration)s total" : "\(totalDuration / 60)m total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle("Make Public", isOn: $isPublic)
                } footer: {
                    Text("Public routines can be borrowed by other users.")
                }
            }
            .navigationTitle("New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRoutine() }
                        .disabled(routineName.isEmpty || selectedIDs.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(allExercises: Array(exercises), selectedIDs: selectedIDs) { id in
                    if !selectedIDs.contains(id) { selectedIDs.append(id) }
                }
            }
        }
    }

    private func saveRoutine() {
        let routine = Routine(
            name: routineName,
            exerciseIDs: selectedIDs,
            isPublic: isPublic
        )
        modelContext.insert(routine)
        dismiss()
    }
}

// MARK: - Exercise picker sheet

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let allExercises: [Exercise]
    let selectedIDs: [UUID]
    let onSelect: (UUID) -> Void
    @State private var searchText = ""

    private var filtered: [Exercise] {
        allExercises.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    exerciseRows(filtered)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseRows(_ items: [Exercise]) -> some View {
        ForEach(Array(items.enumerated()), id: \.offset) { _, ex in
            Button {
                onSelect(ex.uuid)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(ex.name)
                            .foregroundStyle(.primary)
                        Text("\(ex.durationFormatted) · \(ex.type.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedIDs.contains(ex.uuid) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            Divider().padding(.leading)
        }
    }
}
