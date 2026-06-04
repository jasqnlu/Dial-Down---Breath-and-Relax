import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Query private var routines: [Routine]
    @State private var showingBuilder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                let items: [Routine] = Array(routines)
                LazyVStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { i in
                        RoutineRow(routine: items[i])
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        Divider().padding(.leading)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines Yet",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Create your own or borrow one from the library.")
                    )
                }
            }
            .sheet(isPresented: $showingBuilder) {
                RoutineBuilderView()
            }
        }
    }
}

struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                if routine.borrowedFromID != nil {
                    Label("Borrowed", systemImage: "arrow.triangle.branch")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 12) {
                Label("\(routine.exerciseIDs.count) exercises", systemImage: "list.number")
                if routine.isPublic {
                    Label("Public", systemImage: "globe")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoutineListView()
        .modelContainer(for: Routine.self, inMemory: true)
}
