import SwiftUI
import SwiftData
import os

struct RoutineBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var auth: AuthManager

    @Query private var exercises: [Exercise]
    @Query private var allRoutines: [Routine]

    var routineToEdit: Routine? = nil

    @State private var routineName = ""
    @State private var selectedIDs: [UUID] = []
    @State private var isPublic = false
    @State private var showingExercisePicker = false

    private let maxPublicRoutines = 3

    private var isEditing: Bool { routineToEdit != nil }

    private var selectedExercises: [Exercise] {
        selectedIDs.compactMap { id in exercises.first { $0.uuid == id } }
    }

    private var totalDuration: Int {
        selectedExercises.reduce(0) { $0 + $1.durationSeconds }
    }

    private var myPublicCount: Int {
        allRoutines.filter { $0.isPublic && $0.authorID == auth.backendID && $0.uuid != routineToEdit?.uuid }.count
    }

    private var publishLimitReached: Bool {
        myPublicCount >= maxPublicRoutines
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
                    .onMove { selectedIDs.move(fromOffsets: $0, toOffset: $1) }

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
                    Toggle("Publish to Community", isOn: $isPublic)
                        .disabled(!isPublic && publishLimitReached)
                } footer: {
                    if isPublic {
                        Text("Your routine will appear in the community library. You've used \(myPublicCount) of \(maxPublicRoutines) publish slots.")
                    } else if publishLimitReached {
                        Text("You've reached the \(maxPublicRoutines)-routine publish limit. Un-publish an existing routine to free a slot.")
                            .foregroundStyle(.red)
                    } else {
                        let remaining = maxPublicRoutines - myPublicCount
                        Text("Share this routine with the community (\(remaining) publish slot\(remaining == 1 ? "" : "s") remaining).")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { saveRoutine() }
                        .disabled(routineName.isEmpty || selectedIDs.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(allExercises: Array(exercises), selectedIDs: selectedIDs) { id in
                    if !selectedIDs.contains(id) { selectedIDs.append(id) }
                }
            }
            .onAppear {
                if let r = routineToEdit {
                    routineName  = r.name
                    selectedIDs  = r.exerciseIDs
                    isPublic     = r.isPublic
                }
            }
        }
    }

    private func saveRoutine() {
        if let r = routineToEdit {
            r.name        = routineName
            r.exerciseIDs = selectedIDs
            r.isPublic    = isPublic
            r.authorName  = isPublic ? auth.displayName : nil
        } else {
            let routine = Routine(
                name: routineName,
                exerciseIDs: selectedIDs,
                authorID: auth.backendID,
                authorName: isPublic ? auth.displayName : nil,
                isPublic: isPublic
            )
            modelContext.insert(routine)

            if let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first {
                GamificationService.awardBadge("Routine Builder", to: profile)
            }
        }

        do {
            try modelContext.save()
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "routineBuilder").warning("Save failed: \(error)")
        }

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
