import SwiftUI
import SwiftData
import Charts

// MARK: - ProgressChartsView

struct ProgressChartsView: View {

    @Query(sort: \Session.startedAt) private var sessions: [Session]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weeklyBarChartSection
                    allTimeStatsSection
                    streakCalendarSection
                    pointsHistorySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Section 1: This Week

    private var weeklyBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("This Week")

            let weekData = minutesPerDayLastSevenDays()

            if weekData.allSatisfy({ $0.minutes == 0 }) {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "chart.bar",
                    description: Text("Complete a session to see your weekly activity.")
                )
                .frame(height: 180)
                .cardStyle()
            } else {
                Chart(weekData) { point in
                    BarMark(
                        x: .value("Day", point.label),
                        y: .value("Minutes", point.minutes)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 180)
                .padding()
                .cardStyle()
            }
        }
    }

    // MARK: - Section 2: All Time

    private var allTimeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("All Time")

            HStack(spacing: 12) {
                statCard(
                    value: "\(sessions.count)",
                    label: "Sessions",
                    icon: "figure.mind.and.body"
                )
                statCard(
                    value: "\(totalMinutes)",
                    label: "Minutes",
                    icon: "clock.fill"
                )
                statCard(
                    value: "\(profile?.streak ?? longestStreak)",
                    label: "Streak",
                    icon: "flame.fill"
                )
            }
        }
    }

    // MARK: - Section 3: Streak Calendar

    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Streak Calendar")

            VStack(alignment: .leading, spacing: 10) {
                // Month label
                Text(currentMonthLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                // Day-of-week header
                let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                HStack(spacing: 6) {
                    ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // 5-week grid
                ScrollView(.horizontal, showsIndicators: false) {
                    let grid = calendarGrid()
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(32), spacing: 6), count: 7),
                        spacing: 6
                    ) {
                        ForEach(grid) { cell in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(cell.hasSession ? Color.accentColor : Color(.systemFill))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if let day = cell.day {
                                        Text("\(day)")
                                            .font(.caption2)
                                            .foregroundStyle(cell.hasSession ? .white : .secondary)
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
            .cardStyle()
        }
    }

    // MARK: - Section 4: Points History

    private var pointsHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Points History")

            let pointsData = cumulativePointsLast30Days()

            if pointsData.isEmpty {
                ContentUnavailableView(
                    "No data yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Earn points by completing sessions.")
                )
                .frame(height: 160)
                .cardStyle()
            } else {
                Chart(pointsData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Points", point.cumulativePoints)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Points", point.cumulativePoints)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 160)
                .padding()
                .cardStyle()
            }
        }
    }

    // MARK: - Helpers: Data

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var longestStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        let sessionDays = Set(sessions.map { cal.startOfDay(for: $0.startedAt) }).sorted()
        var maxStreak = 1
        var current = 1
        for i in 1..<sessionDays.count {
            let diff = cal.dateComponents([.day], from: sessionDays[i - 1], to: sessionDays[i]).day ?? 0
            if diff == 1 {
                current += 1
                maxStreak = max(maxStreak, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return maxStreak
    }

    // Returns [DayPoint] for the last 7 calendar days (oldest first).
    private func minutesPerDayLastSevenDays() -> [DayPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> DayPoint in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let label = day.shortWeekdayLabel
            let minutes = sessions
                .filter { cal.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationMinutes }
            return DayPoint(date: day, label: label, minutes: minutes)
        }
    }

    // Returns cumulative points plotted over the last 30 days.
    private func cumulativePointsLast30Days() -> [PointsDataPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let startDay = cal.date(byAdding: .day, value: -29, to: today) else { return [] }

        let relevant = sessions.filter { $0.startedAt >= startDay }
        guard !relevant.isEmpty else { return [] }

        var running = 0
        return relevant.map { session -> PointsDataPoint in
            running += session.pointsEarned
            return PointsDataPoint(date: session.startedAt, cumulativePoints: running)
        }
    }

    // MARK: - Helpers: Calendar Grid

    private struct CalendarCell: Identifiable {
        let id: Int          // index in the 35-cell grid
        let day: Int?        // nil for padding cells before month starts
        let hasSession: Bool
    }

    private var currentMonthLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: Date())
    }

    private func calendarGrid() -> [CalendarCell] {
        let cal = Calendar.current
        let today = Date()
        guard
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today)),
            let range = cal.range(of: .day, in: .month, for: monthStart)
        else { return [] }

        let sessionDays = Set(sessions.map { cal.startOfDay(for: $0.startedAt) })

        // Weekday of the first day (1 = Sunday in Gregorian)
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leadingPads  = firstWeekday - 1

        // Build 5 rows * 7 columns = 35 cells
        let totalCells = 35
        var cells: [CalendarCell] = []
        for i in 0..<totalCells {
            let dayNumber = i - leadingPads + 1
            if dayNumber < 1 || dayNumber > range.count {
                cells.append(CalendarCell(id: i, day: nil, hasSession: false))
            } else {
                let cellDate = cal.date(byAdding: .day, value: dayNumber - 1, to: monthStart)!
                let hasSession = sessionDays.contains(cal.startOfDay(for: cellDate))
                cells.append(CalendarCell(id: i, day: dayNumber, hasSession: hasSession))
            }
        }
        return cells
    }

    // MARK: - Sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

// MARK: - Supporting Types

private struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let minutes: Int
}

private struct PointsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativePoints: Int
}

// MARK: - Card Style Modifier

private extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Date Helper

private extension Date {
    var shortWeekdayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        let full = fmt.string(from: self)   // e.g. "Mon"
        return String(full.prefix(3))
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([Session.self, UserProfile.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    // Seed sample sessions
    let ctx = container.mainContext
    let cal = Calendar.current
    let today = Date()
    for offset in [0, 1, 2, 4, 5] {
        let start = cal.date(byAdding: .day, value: -offset, to: today)!
        let end   = cal.date(byAdding: .minute, value: Int.random(in: 8...25), to: start)!
        let s = Session(routineID: UUID(), startedAt: start, completionPercent: 1.0, pointsEarned: Int.random(in: 30...120))
        s.completedAt = end
        ctx.insert(s)
    }
    let profile = UserProfile(profileID: "preview@example.com", displayName: "Alex")
    profile.streak = 3
    profile.totalMinutes = 87
    profile.totalPoints = 340
    ctx.insert(profile)

    return ProgressChartsView()
        .modelContainer(container)
}
