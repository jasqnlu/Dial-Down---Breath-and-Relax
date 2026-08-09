import SwiftUI
import SwiftData

// MARK: - GuidedProgramDetailView
// Every day of every program is free — this app has no paid tier.

struct GuidedProgramDetailView: View {
    let program: GuidedProgram

    @Query private var exercises: [Exercise]
    @State private var dayToPlay: ProgramDay?

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
    }

    private func dayRow(_ day: ProgramDay) -> some View {
        Button {
            dayToPlay = day
        } label: {
            HStack {
                Text("Day \(day.dayNumber)")
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                Spacer()
                Text("\(day.exerciseNames.count) exercises")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                Image(systemName: "chevron.right")
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
        GuidedProgramDetailView(program: .fullReset)
            .modelContainer(for: Exercise.self, inMemory: true)
    }
}
