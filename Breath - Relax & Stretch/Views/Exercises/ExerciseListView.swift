import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedType: ExerciseType? = nil
    @State private var showingCreate = false

    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false
    @State private var suggestedSlot: Date?
    @State private var lastNightSleepHours: Double?
    @State private var showingGentleSession = false

    var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || ex.type == selectedType
            return matchesSearch && matchesType
        }
    }

    private func gentleSessionExercises() -> [Exercise] {
        Array(exercises.filter { $0.difficulty == 1 }.prefix(4))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Personalized section — hidden while the user is actively searching or filtering
                if searchText.isEmpty && selectedType == nil {
                    if let hours = lastNightSleepHours, hours < 7 {
                        SleepSuggestionBanner(hours: hours) {
                            showingGentleSession = true
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    if let slot = suggestedSlot {
                        SuggestedTimeBanner(date: slot)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    ForYouSection(allExercises: exercises)
                }

                LazyVStack(spacing: 0) {
                    ForEach(filtered, id: \.uuid) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            ExerciseRow(exercise: exercise)
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
            .sheet(isPresented: $showingGentleSession) {
                SessionPlayerView(exercises: gentleSessionExercises())
            }
            .onAppear {
                if calendarSyncEnabled {
                    suggestedSlot = CalendarService.shared.suggestFreeSlot()
                }
                Task {
                    lastNightSleepHours = await HealthKitService.shared.lastNightSleepHours()
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

    private var videoSource: VideoSource? {
        VideoSource(urlString: exercise.mediaURL)
    }

    private var videoBadgeTint: Color {
        switch videoSource {
        case .youTube:            return .red
        case .vimeo:              return Color(red: 0.10, green: 0.66, blue: 0.93)
        case .directFile, .web:   return .accentColor
        case nil:                 return .clear
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                if let source = videoSource {
                    Image(systemName: source.symbolName)
                        .font(.caption)
                        .foregroundStyle(videoBadgeTint)
                        .accessibilityHidden(true)
                }
            }
            HStack(spacing: 12) {
                Label(exercise.durationFormatted, systemImage: "clock")
                Label(exercise.type.rawValue, systemImage: "figure.mind.and.body")
                Label(difficultyLabel, systemImage: "chart.bar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.type.rawValue), \(exercise.durationFormatted), \(difficultyLabel)\(videoSource != nil ? ", has video" : "")")
    }
}

// MARK: - Sleep suggestion banner

private struct SleepSuggestionBanner: View {
    let hours: Double
    let onStartGentleSession: () -> Void

    private var hoursLabel: String {
        String(format: "%.1f", hours)
    }

    var body: some View {
        Button(action: onStartGentleSession) {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You slept \(hoursLabel)h last night")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Tap for a gentler routine today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Suggested time banner

private struct SuggestedTimeBanner: View {
    let date: Date

    private var timeLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(Color.accentColor)
            Text("You're free at \(timeLabel) today — good time for a session.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
