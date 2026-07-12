import SwiftUI
import SwiftData

// MARK: - GuidedProgramDetailView
// Day 1 is always free to preview. Pro programs lock day 2 onward behind
// the paywall.

struct GuidedProgramDetailView: View {
    let program: GuidedProgram

    @ObservedObject private var store = StoreManager.shared
    @Query private var exercises: [Exercise]
    @State private var dayToPlay: ProgramDay?
    @State private var showingPaywall = false

    var body: some View {
        List {
            Section {
                Text(program.summary)
                    .font(.luminaSubheadline)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }

            Section {
                ForEach(program.days) { day in
                    dayRow(day)
                }
            } header: {
                Text("Days")
                    .font(.luminaLabel)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .listRowBackground(Color.luminaCardFill)
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
        .sheet(item: $dayToPlay) { day in
            let resolved = resolvedExercises(for: day)
            if resolved.isEmpty {
                ContentUnavailableView(
                    "No Exercises Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This day's exercises couldn't be loaded.")
                )
            } else {
                SessionPlayerView(exercises: resolved)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func dayRow(_ day: ProgramDay) -> some View {
        let isLocked = program.isPro && !store.isPro && day.dayNumber > 1

        return Button {
            if isLocked {
                showingPaywall = true
            } else {
                dayToPlay = day
            }
        } label: {
            HStack {
                Text("Day \(day.dayNumber)")
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                if day.dayNumber == 1 && program.isPro {
                    Text("Free Preview")
                        .font(.luminaCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.luminaOrange.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.luminaOrange)
                }
                Spacer()
                Text("\(day.exerciseNames.count) exercises")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
        }
        .foregroundStyle(.primary)
    }

    private func resolvedExercises(for day: ProgramDay) -> [Exercise] {
        let byName = Dictionary(grouping: exercises, by: \.name).compactMapValues(\.first)
        return day.exerciseNames.compactMap { byName[$0] }
    }
}

#Preview {
    NavigationStack {
        GuidedProgramDetailView(program: .proFullReset)
            .modelContainer(for: Exercise.self, inMemory: true)
    }
}
