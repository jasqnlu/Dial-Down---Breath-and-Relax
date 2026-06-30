import SwiftUI
import SwiftData
import Charts

// MARK: - ProgressChartsView

struct ProgressChartsView: View {

    @Query(sort: \Session.startedAt) private var sessions: [Session]
    @Query private var profiles: [UserProfile]
    @Query private var exercises: [Exercise]

    @State private var selectedDay: DaySelection?
    @State private var showingStreakShare = false

    private var profile: UserProfile? { profiles.first }

    private struct DaySelection: Identifiable {
        let date: Date
        var id: Date { date }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weeklyBarChartSection
                    allTimeStatsSection
                    streakCalendarSection
                    yearHeatmapSection
                    pointsHistorySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingStreakShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share streak card")
                }
            }
            .sheet(item: $selectedDay) { selection in
                SessionDayDetailView(
                    date: selection.date,
                    sessions: sessionsOnDay(selection.date),
                    exercises: exercises
                )
            }
            .sheet(isPresented: $showingStreakShare) {
                StreakCardShareSheet(
                    streak: profile?.streak ?? longestStreak,
                    totalPoints: profile?.totalPoints ?? sessions.reduce(0) { $0 + $1.pointsEarned },
                    totalMinutes: totalMinutes,
                    displayName: profile?.displayName ?? ""
                )
            }
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
                                .onTapGesture {
                                    if cell.hasSession, let date = cell.date {
                                        selectedDay = DaySelection(date: date)
                                    }
                                }
                                .accessibilityAddTraits(cell.hasSession ? .isButton : [])
                        }
                    }
                }
            }
            .padding()
            .cardStyle()
        }
    }

    // MARK: - Section 3b: Year Heatmap

    private var yearHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Year in Review")

            VStack(alignment: .leading, spacing: 8) {
                let weeks = yearHeatmapWeeks()
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 3) {
                            ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                                VStack(spacing: 3) {
                                    ForEach(week, id: \.self) { day in
                                        let count = sessionCount(on: day)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(heatColor(for: count, isFuture: day > Date()))
                                            .frame(width: 10, height: 10)
                                            .onTapGesture {
                                                if count > 0 { selectedDay = DaySelection(date: day) }
                                            }
                                    }
                                }
                                .id(weekIndex)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        proxy.scrollTo(weeks.count - 1, anchor: .trailing)
                    }
                }

                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach([0, 1, 2, 3], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatColor(for: level, isFuture: false))
                            .frame(width: 10, height: 10)
                    }
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .cardStyle()
        }
    }

    private func sessionCount(on date: Date) -> Int {
        let cal = Calendar.current
        return sessions.filter { cal.isDate($0.startedAt, inSameDayAs: date) }.count
    }

    private func heatColor(for count: Int, isFuture: Bool) -> Color {
        if isFuture { return Color.clear }
        switch count {
        case 0:  return Color(.systemFill)
        case 1:  return Color.accentColor.opacity(0.35)
        case 2:  return Color.accentColor.opacity(0.65)
        default: return Color.accentColor
        }
    }

    // Returns 53ish columns of 7 days (Sun…Sat) covering the last 365 days, oldest first.
    private func yearHeatmapWeeks() -> [[Date]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yearAgo = cal.date(byAdding: .day, value: -364, to: today) else { return [] }

        let startWeekday = cal.component(.weekday, from: yearAgo) // 1 = Sunday
        guard let alignedStart = cal.date(byAdding: .day, value: -(startWeekday - 1), to: yearAgo) else { return [] }

        var columns: [[Date]] = []
        var weekStart = alignedStart
        while weekStart <= today {
            var week: [Date] = []
            for i in 0..<7 {
                if let d = cal.date(byAdding: .day, value: i, to: weekStart) {
                    week.append(d)
                }
            }
            columns.append(week)
            guard let next = cal.date(byAdding: .day, value: 7, to: weekStart) else { break }
            weekStart = next
        }
        return columns
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
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
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
        let date: Date?      // nil for padding cells before month starts
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
                cells.append(CalendarCell(id: i, day: nil, date: nil, hasSession: false))
            } else {
                let cellDate = cal.date(byAdding: .day, value: dayNumber - 1, to: monthStart) ?? monthStart
                let hasSession = sessionDays.contains(cal.startOfDay(for: cellDate))
                cells.append(CalendarCell(id: i, day: dayNumber, date: cellDate, hasSession: hasSession))
            }
        }
        return cells
    }

    private func sessionsOnDay(_ date: Date) -> [Session] {
        let cal = Calendar.current
        return sessions.filter { cal.isDate($0.startedAt, inSameDayAs: date) }
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
    let schema = Schema([Session.self, UserProfile.self, Exercise.self])
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
