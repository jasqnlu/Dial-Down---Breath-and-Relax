import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var exercises: [Exercise]
    @State private var routineName = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var isPublic = false
    @State private var showingExercisePicker = false

    var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + $1.durationSeconds }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Name") {
                    TextField("e.g. Morning Wake-Up", text: $routineName)
                }

                Section {
                    ForEach(selectedExercises) { exercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name).font(.subheadline)
                                Text("\(exercise.durationSeconds / 60)m · \(exercise.type.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onMove { from, to in
                        selectedExercises.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { offsets in
                        selectedExercises.remove(atOffsets: offsets)
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
                        if !selectedExercises.isEmpty {
                            Text("\(totalDuration / 60) min total")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRoutine() }
                        .disabled(routineName.isEmpty || selectedExercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }

    private func saveRoutine() {
        let routine = Routine(
            name: routineName,
            exerciseIDs: selectedExercises.map(\.id),
            isPublic: isPublic
        )
        modelContext.insert(routine)
        dismiss()
    }
}

// MARK: - Exercise picker sheet

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
    @State private var searchText = ""

    var filtered: [Exercise] {
        exercises.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { exercise in
                Button {
                    if !selectedExercises.contains(where: { $0.id == exercise.id }) {
                        selectedExercises.append(exercise)
                    }
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(exercise.name).foregroundStyle(.primary)
                            Text("\(exercise.durationSeconds / 60)m · \(exercise.type.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedExercises.contains(where: { $0.id == exercise.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
