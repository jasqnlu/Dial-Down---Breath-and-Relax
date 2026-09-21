import SwiftUI
import SwiftData

// MARK: - PremadeRoutinesView
// Curated single-session routine templates. Tapping one opens
// RoutineBuilderView pre-seeded with the template's name and exercises —
// see PremadeRoutine's doc comment. Nothing is saved until the user hits
// Save there.

struct PremadeRoutinesView: View {
    @Query private var exercises: [Exercise]
    @State private var selectedRoutine: PremadeRoutine?

    var body: some View {
        List(PremadeRoutine.all) { routine in
            let meta = metaInfo(for: routine)
            Button {
                selectedRoutine = routine
            } label: {
                PremadeRoutineRow(routine: routine, meta: meta)
            }
            .buttonStyle(.plain)
            .disabled(meta == nil)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .navigationTitle("Premade Routines")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
        .sheet(item: $selectedRoutine) { routine in
            RoutineBuilderView(
                initialExerciseIDs: routine.resolvedExercises(in: exercises).map(\.uuid),
                initialName: routine.title
            )
        }
    }

    /// The raw (count, minutes) behind the row's meta line, or nil if the
    /// routine currently resolves to zero exercises. Kept as data rather
    /// than a formatted String so the call site can render a `Text` literal
    /// that participates in localization — see PremadeRoutineRow.
    private func metaInfo(for routine: PremadeRoutine) -> (count: Int, minutes: Int)? {
        let resolved = routine.resolvedExercises(in: exercises)
        guard !resolved.isEmpty else { return nil }
        let totalSecs = resolved.reduce(0) { $0 + $1.durationSeconds }
        let mins = max(1, Int((Double(totalSecs) / 60).rounded()))
        return (resolved.count, mins)
    }
}

private struct PremadeRoutineRow: View {
    let routine: PremadeRoutine
    let meta: (count: Int, minutes: Int)?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: routine.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 44, height: 44)
                .background(Color.luminaMintTint, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(routine.title)
                    .font(.luminaCardTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                Text(routine.summary)
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .lineLimit(2)
                if let meta {
                    (Text("\(meta.count) exercises") + Text(verbatim: " · ") + Text("\(meta.minutes) min"))
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                } else {
                    Text("Unavailable")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
            }

            Spacer(minLength: 0)
        }
        .luminaCard(padding: 14)
    }
}

#Preview {
    NavigationStack {
        PremadeRoutinesView()
    }
    .modelContainer(for: [Exercise.self, Routine.self], inMemory: true)
}
