import SwiftUI

/// Lets the user drag pinned "Today" routines into priority order — the
/// top one is what Today actually shows/starts when the app launches.
/// Presented from `TodayView.greetingHeader` once 2+ routines are pinned
/// (a single pin has nothing to arrange). Uses the same List+`.onMove`
/// drag-to-reorder mechanism `CustomizeRoutineView`/`RoutineBuilderView`
/// already ship, just applied to routines instead of exercises.
struct PinnedRoutineOrderView: View {
    let routines: [Routine]
    /// Called once, on dismiss, after `pinnedOrder` has been written back
    /// onto every routine — the caller (TodayView) owns the `modelContext`,
    /// this view only reorders in-memory and reports when it's done.
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var orderedRoutines: [Routine]

    init(routines: [Routine], onSave: @escaping () -> Void) {
        self.routines = routines
        self.onSave = onSave
        self._orderedRoutines = State(initialValue: routines)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(orderedRoutines.enumerated()), id: \.element.uuid) { index, routine in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.luminaOnSurfaceVariant)
                                .frame(width: 22, height: 22)
                                .background(Color.luminaContainer, in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name)
                                    .font(.luminaCardTitle)
                                    .foregroundStyle(Color.luminaOnSurface)
                                Text("\(routine.exerciseIDs.count) exercises")
                                    .font(.luminaCaption)
                                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(Color.luminaOnSurfaceVariant.opacity(0.6))
                        }
                        .luminaCard(padding: 12)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove { orderedRoutines.move(fromOffsets: $0, toOffset: $1) }
                } footer: {
                    Text("The top routine is the one Today shows and starts.")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.luminaSurface)
            .navigationTitle("Pinned Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear {
                for (index, routine) in orderedRoutines.enumerated() {
                    routine.pinnedOrder = index
                }
                onSave()
            }
        }
    }
}

#Preview {
    let r1 = Routine(name: "Morning Wake-Up", exerciseIDs: [UUID(), UUID()], isPinnedToToday: true, pinnedOrder: 0)
    let r2 = Routine(name: "Evening Unwind", exerciseIDs: [UUID()], isPinnedToToday: true, pinnedOrder: 1)
    PinnedRoutineOrderView(routines: [r1, r2]) {}
}
