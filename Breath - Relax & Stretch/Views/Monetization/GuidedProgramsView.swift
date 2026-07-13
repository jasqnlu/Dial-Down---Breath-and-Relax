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
                programCard(program)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .navigationTitle("Programs")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
    }

    private func programCard(_ program: GuidedProgram) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.luminaGradientStart, .luminaGradientEnd],
                            startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: program.icon)
                    Text("\(program.days.count) day\(program.days.count == 1 ? "" : "s")")
                }
                .font(.luminaLabel)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.35), in: Capsule())

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(program.title)
                            .font(.luminaTitle)
                        if program.isPro && !store.isPro {
                            Image(systemName: "lock.fill")
                                .font(.luminaCaption)
                        }
                    }
                    .foregroundStyle(.white)
                    Text(program.summary)
                        .font(.luminaCaption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .frame(height: 176)
        .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        GuidedProgramsView()
    }
}
