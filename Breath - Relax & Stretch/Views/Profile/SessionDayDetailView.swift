import SwiftUI

// MARK: - SessionDayDetailView
// Shown when tapping a day with completed sessions in the streak calendar
// or year heatmap. Resolves each session's exercises (or breathing pattern)
// from the live Exercise catalog.

struct SessionDayDetailView: View {
    let date: Date
    let sessions: [Session]
    let exercises: [Exercise]

    private var totalMinutes: Int { sessions.reduce(0) { $0 + $1.durationMinutes } }
    private var totalPoints: Int { sessions.reduce(0) { $0 + $1.pointsEarned } }

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.locale = AppLanguage.current().effectiveLocale
        fmt.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return fmt.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        statBlock(value: "\(sessions.count)", label: sessions.count == 1 ? "Session" : "Sessions")
                        statBlock(value: "\(totalMinutes)", label: "Minutes")
                        statBlock(value: "\(totalPoints)", label: "Points")
                    }
                    .padding(.vertical, 4)
                }

                Section("Sessions") {
                    ForEach(sessions.sorted(by: { $0.startedAt < $1.startedAt })) { session in
                        SessionDetailRow(session: session, exercises: exercises)
                    }
                }
            }
            .navigationTitle(dateLabel)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Row

private struct SessionDetailRow: View {
    let session: Session
    let exercises: [Exercise]

    private var resolvedNames: [String] {
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        return session.exerciseIDs.compactMap { byID[$0]?.localizedName() }
    }

    private var timeLabel: String {
        let fmt = DateFormatter()
        fmt.locale = AppLanguage.current().effectiveLocale
        fmt.setLocalizedDateFormatFromTemplate("jmm")
        return fmt.string(from: session.startedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                (session.sessionLabel.map { Text(verbatim: $0) } ?? Text("Exercise Session"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(timeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !resolvedNames.isEmpty {
                Text(resolvedNames.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if session.roundsCompleted > 0 {
                Text("\(session.roundsCompleted) rounds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(session.durationMinutes)m", systemImage: "clock")
                Label("\(session.pointsEarned) pts", systemImage: "star.fill")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let session = Session(routineID: UUID(), completionPercent: 1.0, pointsEarned: 42)
    session.completedAt = Date()
    session.sessionLabel = "Box Breathing"
    session.roundsCompleted = 5

    return SessionDayDetailView(date: Date(), sessions: [session], exercises: [])
}
