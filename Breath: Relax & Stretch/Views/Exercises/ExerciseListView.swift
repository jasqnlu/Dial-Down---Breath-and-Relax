import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedType: ExerciseType? = nil

    var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || ex.type == selectedType
            return matchesSearch && matchesType
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let items: [Exercise] = Array(filtered)
                LazyVStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { i in
                        NavigationLink(destination: ExerciseDetailView(exercise: items[i])) {
                            ExerciseRow(exercise: items[i])
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                        Divider().padding(.leading)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("All Types") { selectedType = nil }
                        Divider()
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Button(type.rawValue) { selectedType = type }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedType == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "figure.mind.and.body",
                        description: Text(exercises.isEmpty
                                          ? "Seed exercises will load on first launch."
                                          : "No results for your search.")
                    )
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var difficultyLabel: String {
        switch exercise.difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.name)
                .font(.headline)
            HStack(spacing: 12) {
                Label(exercise.durationFormatted, systemImage: "clock")
                Label(exercise.type.rawValue, systemImage: "figure.mind.and.body")
                Label(difficultyLabel, systemImage: "chart.bar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
