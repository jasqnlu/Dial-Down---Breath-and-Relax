import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedType: ExerciseType? = nil
    @State private var selectedExercise: Exercise?
    @State private var visibleSearchCount = ExerciseSearchResults.pageSize
    @FocusState private var isSearchFocused: Bool

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResults: ExerciseSearchResults {
        ExerciseSearchResults(
            exercises: exercises,
            searchText: normalizedSearchText,
            selectedType: selectedType,
            visibleCount: visibleSearchCount
        )
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(get: { selectedExercise != nil }, set: { if !$0 { selectedExercise = nil } })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                content
            }
            .background(Color.luminaSurface)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .floatingTabBarClearance()
            .onChange(of: normalizedSearchText) { _, _ in
                resetSearchPage()
            }
            .onChange(of: selectedType) { _, _ in
                resetSearchPage()
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

    @ViewBuilder
    private var content: some View {
        Group {
            if normalizedSearchText.isEmpty {
                ExerciseGraphView(exercises: exercises, typeFilter: selectedType) { exercise in
                    selectedExercise = exercise
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.visible, id: \.uuid) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .luminaCard()
                            .padding(.horizontal)
                        }

                        if searchResults.canLoadMore {
                            ProgressView()
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    visibleSearchCount = searchResults.nextVisibleCount
                                }
                        }
                    }
                    .padding(.top, 8)
                }
                .overlay {
                    if searchResults.matches.isEmpty {
                        ContentUnavailableView(
                            "No Exercises",
                            systemImage: "figure.mind.and.body",
                            description: Text("No results for your search.")
                        )
                    }
                }
            }
        }
    }

    private func resetSearchPage() {
        visibleSearchCount = ExerciseSearchResults.pageSize
    }

    private var header: some View {
        HStack(spacing: 10) {
            searchBar

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
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.cyan.opacity(0.95))

            TextField("Search exercises", text: $searchText)
                .font(.luminaLabel)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .padding(.horizontal, 12)
        .background(Color.luminaCardFill.opacity(0.96), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.58),
                            Color.mint.opacity(0.34),
                            Color.cyan.opacity(0.50)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .shadow(color: Color.cyan.opacity(0.18), radius: 7, x: 0, y: 0)
        .shadow(color: Color.mint.opacity(0.10), radius: 11, x: 0, y: 0)
        .accessibilityElement(children: .contain)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Fixed rather than proportional-to-row-width: a `GeometryReader`
    /// measuring this view's own width, fed back into `@State` that this same
    /// view's layout then depends on, is a measure→re-render→re-measure loop
    /// — SwiftUI doesn't always settle it in one pass, and with many rows
    /// alive at once (a `List`/`LazyVStack` of ~180 exercises) it can pin the
    /// main thread relaying out indefinitely. A constant sidesteps the loop
    /// entirely; the `stats` column still flexes to fill the rest of the row.
    private let thumbnailSide: CGFloat = 120

    var difficultyLabel: String {
        switch exercise.difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return ""
        }
    }

    private var hasDemo: Bool {
        exercise.demoVideoURL != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaOnSurface)
                .lineLimit(2)

            HStack(alignment: .top, spacing: 12) {
                thumbnail
                    .frame(width: thumbnailSide, height: thumbnailSide)
                    .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.panel, style: .continuous))
                    .accessibilityHidden(true)

                stats
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.type.rawValue), \(exercise.durationFormatted), \(difficultyLabel)\(hasDemo ? ", has animated demo" : "")\(exercise.caution.map { ", caution: \($0)" } ?? "")")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = exercise.demoVideoURL {
            LoopingVideoThumbnail(url: url, reduceMotion: reduceMotion)
        } else {
            ZStack {
                Color.luminaContainer
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(exercise.type.rawValue)
                    .font(.luminaLabel)
                    .foregroundStyle(Color.luminaPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.luminaMintTint, in: Capsule())

                difficultyDots
            }

            Label(exercise.durationFormatted, systemImage: "clock")
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)

            if let caution = exercise.caution, !caution.isEmpty {
                cautionLine(caution)
            }
        }
    }

    private var difficultyDots: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { level in
                Circle()
                    .fill(level <= exercise.difficulty ? Color.luminaPrimary : Color.luminaOutline)
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityLabel(difficultyLabel)
    }

    private func cautionLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.luminaOnOrange)
            Text(text)
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnOrange)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.luminaOrange.opacity(0.16), in: RoundedRectangle(cornerRadius: LuminaRadius.tag, style: .continuous))
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
