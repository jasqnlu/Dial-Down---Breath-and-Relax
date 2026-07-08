import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedType: ExerciseType? = nil
    @State private var showingCreate = false
    @State private var selectedExercise: Exercise?

    private var searchFiltered: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || ex.type == selectedType
            return matchesSearch && matchesType
        }
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(get: { selectedExercise != nil }, set: { if !$0 { selectedExercise = nil } })
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ExerciseGraphView(exercises: exercises, typeFilter: selectedType) { exercise in
                        selectedExercise = exercise
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchFiltered, id: \.uuid) { exercise in
                                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                    ExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                                .luminaCard()
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .overlay {
                        if searchFiltered.isEmpty {
                            ContentUnavailableView(
                                "No Exercises",
                                systemImage: "figure.mind.and.body",
                                description: Text("No results for your search.")
                            )
                        }
                    }
                }
            }
            .background(Color.luminaSurface)
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .floatingTabBarClearance()
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create exercise")
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateExerciseView()
            }
            .navigationDestination(isPresented: isShowingDetail) {
                if let selectedExercise {
                    ExerciseDetailView(exercise: selectedExercise)
                }
            }
            .overlay {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "figure.mind.and.body",
                        description: Text("Seed exercises will load on first launch.")
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

    private var hasVideo: Bool {
        exercise.localVideoURL != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(exercise.name)
                    .font(.luminaCardTitle)
                if hasVideo {
                    Image(systemName: "film.fill")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            HStack(spacing: 12) {
                Label(exercise.durationFormatted, systemImage: "clock")
                Label(exercise.type.rawValue, systemImage: "figure.mind.and.body")
                Label(difficultyLabel, systemImage: "chart.bar")
            }
            .font(.luminaCaption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.type.rawValue), \(exercise.durationFormatted), \(difficultyLabel)\(hasVideo ? ", has video" : "")")
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
