import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - DataExportView

struct DataExportView: View {
    @Query(sort: \Session.startedAt) private var sessions: [Session]
    @Query private var routines: [Routine]
    @Query private var profiles: [UserProfile]

    @State private var exportFormat: ExportFormat = .csv
    @State private var exportURL: URL?
    @State private var isGenerating = false

    enum ExportFormat: String, CaseIterable {
        case csv  = "CSV"
        case json = "JSON"
        var fileExtension: String { rawValue.lowercased() }
    }

    // MARK: Body

    var body: some View {
        List {
            Group {
                formatSection
                summarySection
                exportSection
            }
            .listRowBackground(Color.luminaCardFill)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .navigationTitle("Export My Data")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
        .onChange(of: exportFormat) { _, _ in exportURL = nil }
    }

    // MARK: Sections

    private var formatSection: some View {
        Section {
            Picker("Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        } header: {
            Text("Format")
        } footer: {
            Text(exportFormat == .csv
                 ? "Comma-separated values — opens in Numbers, Excel, or any spreadsheet app."
                 : "Structured JSON — useful for importing into other tools or scripts.")
        }
    }

    private var summarySection: some View {
        Section("Your Data") {
            LabeledContent("Total Sessions") {
                Text("\(sessions.count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            LabeledContent("Points Earned") {
                Text("\(sessions.reduce(0) { $0 + $1.pointsEarned }) pts")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            LabeledContent("Minutes Logged") {
                Text("\(sessions.reduce(0) { $0 + $1.durationMinutes }) min")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            LabeledContent("Routines Saved") {
                Text("\(routines.count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            LabeledContent("Badges Earned") {
                Text("\(profiles.first?.badges.count ?? 0)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var exportSection: some View {
        Section {
            // Build / regenerate button
            Button {
                buildExport()
            } label: {
                if isGenerating {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Building export…")
                    }
                } else {
                    Label(
                        exportURL == nil ? "Build \(exportFormat.rawValue) Export" : "Rebuild Export",
                        systemImage: "doc.badge.plus"
                    )
                }
            }
            .disabled(isGenerating || !hasExportableData)

            // Share button — only shown once the file is ready
            if let url = exportURL {
                ShareLink(
                    item: url,
                    subject: Text("My Breath & Stretch Data"),
                    message: Text("Exported from Breath: Relax & Stretch"),
                    preview: SharePreview(
                        url.lastPathComponent,
                        image: Image(systemName: "doc.text.fill")
                    )
                ) {
                    Label(
                        "Share \(exportFormat.rawValue) File",
                        systemImage: "square.and.arrow.up"
                    )
                    .foregroundStyle(Color.accentColor)
                }
            }
        } footer: {
            if !hasExportableData {
                Text("Complete a session, save a routine, or set up your profile to export your data.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// True once there is at least one session, routine, or profile record to export.
    private var hasExportableData: Bool {
        !sessions.isEmpty || !routines.isEmpty || !profiles.isEmpty
    }

    // MARK: Export generation

    private func buildExport() {
        guard hasExportableData else { return }
        isGenerating = true
        exportURL = nil

        // Snapshot everything on the main actor before leaving — SwiftData
        // models must not be read from a detached task.
        let rows        = sessions.map { SessionExportRow($0) }
        let routineRows = routines.map { RoutineExportRow($0) }
        let profileRow  = profiles.first.map { ProfileExportRow($0) }
        let format      = exportFormat
        let fileExt     = exportFormat.fileExtension   // capture before leaving actor

        Task.detached(priority: .userInitiated) {
            let content: String
            switch format {
            case .csv:  content = DataExportView.makeCSV(sessions: rows, routines: routineRows, profile: profileRow)
            case .json: content = DataExportView.makeJSON(sessions: rows, routines: routineRows, profile: profileRow)
            }

            let tag = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.string(from: Date())
            }()
            let filename = "breath_data_\(tag).\(fileExt)"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)
            try? content.write(to: url, atomically: true, encoding: .utf8)

            await MainActor.run {
                exportURL = url
                isGenerating = false
            }
        }
    }

    // MARK: CSV builder

    /// Multi-section CSV: sessions / routines / profile each get their own
    /// header + row block, separated by a blank line and a "# Section" marker
    /// comment row. This keeps the export a single file (so the existing
    /// single-item `ShareLink` above needs no changes) while still surfacing
    /// every user-generated data type. Spreadsheet apps show the marker rows
    /// as a one-cell comment, which is harmless.
    nonisolated private static func makeCSV(
        sessions rows: [SessionExportRow],
        routines routineRows: [RoutineExportRow],
        profile profileRow: ProfileExportRow?
    ) -> String {
        let iso = ISO8601DateFormatter()
        var lines: [String] = []

        lines.append("# Sessions")
        lines.append("id,routineID,startedAt,completedAt,durationMinutes,completionPercent,pointsEarned")
        for r in rows {
            lines.append([
                r.id,
                r.routineID,
                iso.string(from: r.startedAt),
                r.completedAt.map { iso.string(from: $0) } ?? "",
                "\(r.durationMinutes)",
                String(format: "%.0f", r.completionPercent),
                "\(r.pointsEarned)"
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append("# Routines")
        lines.append("id,name,exerciseIDs,authorID,authorName,borrowedFromID,isPublic,borrowCount,createdAt")
        for r in routineRows {
            lines.append([
                r.id,
                r.name,
                r.exerciseIDs.joined(separator: ";"),
                r.authorID ?? "",
                r.authorName ?? "",
                r.borrowedFromID ?? "",
                "\(r.isPublic)",
                "\(r.borrowCount)",
                iso.string(from: r.createdAt)
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append("# Profile")
        lines.append("profileID,displayName,totalMinutes,totalPoints,streak,lastSessionDate,badges,streakFreezeTokens,sessionsTowardNextFreezeToken,pendingStreakBreak")
        if let p = profileRow {
            lines.append([
                p.profileID,
                p.displayName,
                "\(p.totalMinutes)",
                "\(p.totalPoints)",
                "\(p.streak)",
                p.lastSessionDate.map { iso.string(from: $0) } ?? "",
                p.badges.joined(separator: ";"),
                "\(p.streakFreezeTokens)",
                "\(p.sessionsTowardNextFreezeToken)",
                "\(p.pendingStreakBreak)"
            ].joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: JSON builder

    nonisolated private static func makeJSON(
        sessions rows: [SessionExportRow],
        routines routineRows: [RoutineExportRow],
        profile profileRow: ProfileExportRow?
    ) -> String {
        let iso = ISO8601DateFormatter()

        let sessionsArr: [[String: Any]] = rows.map { r in
            var d: [String: Any] = [
                "id":                r.id,
                "routineID":         r.routineID,
                "startedAt":         iso.string(from: r.startedAt),
                "durationMinutes":   r.durationMinutes,
                "completionPercent": r.completionPercent,
                "pointsEarned":      r.pointsEarned
            ]
            if let c = r.completedAt { d["completedAt"] = iso.string(from: c) }
            return d
        }

        let routinesArr: [[String: Any]] = routineRows.map { r in
            var d: [String: Any] = [
                "id":           r.id,
                "name":         r.name,
                "exerciseIDs":  r.exerciseIDs,
                "isPublic":     r.isPublic,
                "borrowCount":  r.borrowCount,
                "createdAt":    iso.string(from: r.createdAt)
            ]
            if let a = r.authorID { d["authorID"] = a }
            if let n = r.authorName { d["authorName"] = n }
            if let b = r.borrowedFromID { d["borrowedFromID"] = b }
            return d
        }

        var profileDict: Any = NSNull()
        if let p = profileRow {
            var d: [String: Any] = [
                "profileID":                      p.profileID,
                "displayName":                    p.displayName,
                "totalMinutes":                   p.totalMinutes,
                "totalPoints":                    p.totalPoints,
                "streak":                         p.streak,
                "badges":                         p.badges,
                "streakFreezeTokens":             p.streakFreezeTokens,
                "sessionsTowardNextFreezeToken":  p.sessionsTowardNextFreezeToken,
                "pendingStreakBreak":             p.pendingStreakBreak
            ]
            if let last = p.lastSessionDate { d["lastSessionDate"] = iso.string(from: last) }
            profileDict = d
        }

        let root: [String: Any] = [
            "exportedAt": iso.string(from: Date()),
            "profile":    profileDict,
            "sessions":   sessionsArr,
            "routines":   routinesArr
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root,
                                                      options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return #"{"profile":null,"sessions":[],"routines":[]}"#
        }
        return str
    }
}

// MARK: - Value-type snapshot (safe across actor boundaries)

private struct SessionExportRow: Sendable {
    let id:                String
    let routineID:         String
    let startedAt:         Date
    let completedAt:       Date?
    let durationMinutes:   Int
    let completionPercent: Double
    let pointsEarned:      Int

    init(_ s: Session) {
        id                = s.uuid.uuidString
        routineID         = s.routineID.uuidString
        startedAt         = s.startedAt
        completedAt       = s.completedAt
        durationMinutes   = s.durationMinutes
        completionPercent = s.completionPercent
        pointsEarned      = s.pointsEarned
    }
}

private struct RoutineExportRow: Sendable {
    let id:             String
    let name:           String
    let exerciseIDs:    [String]
    let authorID:       String?
    let authorName:     String?
    let borrowedFromID: String?
    let isPublic:       Bool
    let borrowCount:    Int
    let createdAt:      Date

    init(_ r: Routine) {
        id             = r.uuid.uuidString
        name           = r.name
        exerciseIDs    = r.exerciseIDs.map { $0.uuidString }
        authorID       = r.authorID
        authorName     = r.authorName
        borrowedFromID = r.borrowedFromID?.uuidString
        isPublic       = r.isPublic
        borrowCount    = r.borrowCount
        createdAt      = r.createdAt
    }
}

private struct ProfileExportRow: Sendable {
    let profileID:                     String
    let displayName:                   String
    let totalMinutes:                  Int
    let totalPoints:                   Int
    let streak:                        Int
    let lastSessionDate:               Date?
    let badges:                        [String]
    let streakFreezeTokens:            Int
    let sessionsTowardNextFreezeToken: Int
    let pendingStreakBreak:            Int

    init(_ p: UserProfile) {
        profileID                     = p.profileID
        displayName                   = p.displayName
        totalMinutes                  = p.totalMinutes
        totalPoints                   = p.totalPoints
        streak                        = p.streak
        lastSessionDate               = p.lastSessionDate
        badges                        = p.badges
        streakFreezeTokens            = p.streakFreezeTokens
        sessionsTowardNextFreezeToken = p.sessionsTowardNextFreezeToken
        pendingStreakBreak            = p.pendingStreakBreak
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataExportView()
            .modelContainer(for: [Session.self, Routine.self, UserProfile.self], inMemory: true)
    }
}
