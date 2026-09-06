import SwiftUI

/// The Exercises tab's filter sheet — Type, Difficulty, and Duration, each a
/// row of `LuminaChip`s. Difficulty and Duration are additions on top of the
/// pre-existing Type-only `Menu`; kept as its own file (rather than growing
/// `ExerciseListView`'s `header` further) since it's a self-contained facet
/// picker that only needs bindings in and out.
///
/// Difficulty is multi-select (a user filtering for "easier" exercises isn't
/// choosing a single difficulty, they're excluding the harder ones — so
/// selecting both Easier and Medium should show both). Type and Duration stay
/// single-select: an exercise has exactly one type and one duration, so
/// picking more than one bucket there would just mean "no filter."
struct ExerciseFilterSheet: View {
    @Binding var selectedType: ExerciseType?
    @Binding var selectedDifficulties: Set<Int>
    @Binding var durationBucket: ExerciseDurationBucket
    @Environment(\.dismiss) private var dismiss

    private var hasActiveFilters: Bool {
        selectedType != nil || !selectedDifficulties.isEmpty || durationBucket != .any
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section(title: "Type") {
                        chipRow {
                            LuminaChip(title: "All", isSelected: selectedType == nil) {
                                selectedType = nil
                            }
                            ForEach(ExerciseType.allCases, id: \.self) { type in
                                LuminaChip(title: type.rawValue, isSelected: selectedType == type) {
                                    selectedType = type
                                }
                            }
                        }
                    }

                    section(title: "Difficulty") {
                        chipRow {
                            ForEach(difficultyLevels, id: \.level) { level in
                                LuminaChip(title: level.title, isSelected: selectedDifficulties.contains(level.level)) {
                                    if selectedDifficulties.contains(level.level) {
                                        selectedDifficulties.remove(level.level)
                                    } else {
                                        selectedDifficulties.insert(level.level)
                                    }
                                }
                            }
                        }
                    }

                    section(title: "Duration") {
                        chipRow {
                            ForEach(ExerciseDurationBucket.allCases) { bucket in
                                LuminaChip(title: bucket.rawValue, isSelected: durationBucket == bucket) {
                                    durationBucket = bucket
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.luminaSurface)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        selectedType = nil
                        selectedDifficulties = []
                        durationBucket = .any
                    }
                    .disabled(!hasActiveFilters)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private let difficultyLevels: [(level: Int, title: String)] = [
        (1, "Easier"), (2, "Medium"), (3, "Hard")
    ]

    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.luminaCardTitle)
                .foregroundStyle(Color.luminaOnSurface)
            content()
        }
    }

    /// A horizontally scrolling row rather than a wrapping `HStack` — this
    /// codebase has no flow-layout helper, and up to 4 chips ("Under 1 min",
    /// "1-3 min", "3+ min", "Any") can be tight on the smallest phone widths.
    /// Scrolling sidesteps the overflow question entirely instead of betting
    /// on a fixed screen size.
    @ViewBuilder
    private func chipRow(@ViewBuilder content: () -> some View) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                content()
            }
        }
    }
}

#Preview {
    ExerciseFilterSheet(
        selectedType: .constant(nil),
        selectedDifficulties: .constant([]),
        durationBucket: .constant(.any)
    )
}
