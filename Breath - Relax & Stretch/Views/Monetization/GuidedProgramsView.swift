import SwiftUI

// MARK: - GuidedProgramsView

struct GuidedProgramsView: View {
    @AppStorage("onboardingGoals") private var goalsStr = ""
    @ObservedObject private var store = StoreManager.shared

    private var programs: [GuidedProgram] {
        let goalIDs = Set(goalsStr.split(separator: ",").map(String.init))
        return [.starterProgram(goalIDs: goalIDs), .proFullReset]
    }

    var body: some View {
        List(programs) { program in
            NavigationLink(destination: GuidedProgramDetailView(program: program)) {
                programRow(program)
            }
        }
        .navigationTitle("Programs")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
    }

    private func programRow(_ program: GuidedProgram) -> some View {
        HStack(spacing: 12) {
            Image(systemName: program.icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(program.title)
                        .font(.headline)
                    if program.isPro && !store.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(program.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("\(program.days.count) day\(program.days.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        GuidedProgramsView()
    }
}
