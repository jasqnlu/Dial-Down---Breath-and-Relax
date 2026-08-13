import SwiftUI
import SwiftData

/// Presented from CustomizeRoutineView's "Add Exercises" pill. A lightweight
/// search + grid picker, entirely local to the Customize sheet — no tab
/// switch, no cross-tab shared state. Reuses the exact ExerciseGridTile +
/// add-badge interaction already proven in Body Map's mini-routine picker,
/// and MiniRoutineState for the running selection (same "ad hoc, no
/// persistence" fit as here — nothing is written until Customize's own
/// Pin/Begin flow runs).
struct ExercisePickerSheet: View {
    /// Exercises already in the routine being built — filtered out of the
    /// list so the user can't add the same exercise twice.
    let excluding: [Exercise]
    let onAdd: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]
    @StateObject private var picked = MiniRoutineState()
    @State private var searchText = ""

    private var candidates: [Exercise] {
        ExercisePickerCandidates.available(from: allExercises, excluding: excluding)
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: ExerciseSearchResults {
        ExerciseSearchResults(
            exercises: candidates,
            searchText: normalizedSearchText,
            selectedType: nil,
            visibleCount: ExerciseSearchResults.pageSize
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                grid
            }
            .background(Color.luminaSurface)
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !picked.exercises.isEmpty {
                    addButton
                }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(results.visible, id: \.uuid) { exercise in
                    ExerciseGridTile(
                        exercise: exercise,
                        badge: .add(isSelected: picked.contains(exercise))
                    ) {
                        picked.toggle(exercise)
                    } onBadgeTap: {
                        picked.toggle(exercise)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .overlay {
            if candidates.isEmpty {
                ContentUnavailableView(
                    "Nothing Left to Add",
                    systemImage: "checkmark.circle",
                    description: Text("Every exercise is already in this routine.")
                )
            } else if results.matches.isEmpty {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "figure.mind.and.body",
                    description: Text("No results for your search.")
                )
            }
        }
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

            if !searchText.isEmpty {
                Button {
                    searchText = ""
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
        .accessibilityElement(children: .contain)
    }

    private var addButton: some View {
        Button {
            onAdd(picked.exercises)
            dismiss()
        } label: {
            Text("Add \(picked.exercises.count)")
        }
        .buttonStyle(LuminaPillButtonStyle(kind: .prominent))
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
    }
}
