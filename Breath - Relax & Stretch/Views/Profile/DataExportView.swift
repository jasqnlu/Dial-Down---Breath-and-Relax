import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - DataExportView

struct DataExportView: View {
    @Query(sort: \Session.startedAt) private var sessions: [Session]

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
            formatSection
            summarySection
            exportSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Export My Data")
        .navigationBarTitleDisplayMode(.inline)
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
            .disabled(isGenerating || sessions.isEmpty)

            // Share button — only shown once the file is ready
            if let url = exportURL {
                ShareLink(
                    item: url,
                    subject: Text("My Breath & Stretch Sessions"),
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
            if sessions.isEmpty {
                Text("Complete at least one session to export your data.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Export generation

    private func buildExport() {
        guard !sessions.isEmpty else { return }
        isGenerating = true
        exportURL = nil

        // Snapshot everything on the main actor before leaving — SwiftData
        // models must not be read from a detached task.
        let rows    = sessions.map { SessionExportRow($0) }
        let format  = exportFormat
        let fileExt = exportFormat.fileExtension   // capture before leaving actor

        Task.detached(priority: .userInitiated) {
            let content: String
            switch format {
            case .csv:  content = DataExportView.makeCSV(from: rows)
            case .json: content = DataExportView.makeJSON(from: rows)
            }

            let tag = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.string(from: Date())
            }()
            let filename = "breath_sessions_\(tag).\(fileExt)"
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

    nonisolated private static func makeCSV(from rows: [SessionExportRow]) -> String {
        let iso = ISO8601DateFormatter()
        var lines = [
            "id,routineID,startedAt,completedAt,durationMinutes,completionPercent,pointsEarned"
        ]
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
        return lines.joined(separator: "\n")
    }

    // MARK: JSON builder

    nonisolated private static func makeJSON(from rows: [SessionExportRow]) -> String {
        let iso = ISO8601DateFormatter()
        let arr: [[String: Any]] = rows.map { r in
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
        let root: [String: Any] = [
            "exportedAt": iso.string(from: Date()),
            "sessions": arr
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root,
                                                      options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return #"{"sessions":[]}"#
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

// MARK: - Preview

#Preview {
    NavigationStack {
        DataExportView()
            .modelContainer(for: Session.self, inMemory: true)
    }
}
