import SwiftUI

// MARK: - Drawing tool

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen        = "pencil"
    case highlighter = "highlighter"
    case eraser     = "eraser"

    var id: String { rawValue }
    var icon: String { rawValue }

    var label: String {
        switch self {
        case .pen:         return "Pen"
        case .highlighter: return "Highlighter"
        case .eraser:      return "Eraser"
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .pen:         return 3
        case .highlighter: return 22
        case .eraser:      return 28
        }
    }

    var opacity: Double {
        switch self {
        case .pen:         return 1.0
        case .highlighter: return 0.38
        case .eraser:      return 1.0
        }
    }
}

// MARK: - Sensation colour palette

struct SensationColor: Identifiable, Equatable {
    let id: String
    let color: Color
    let label: String
    let icon: String
}

let sensationColors: [SensationColor] = [
    SensationColor(id: "pain",     color: .red,    label: "Pain",     icon: "bolt.fill"),
    SensationColor(id: "tension",  color: .orange, label: "Tension",  icon: "arrow.up.and.down"),
    SensationColor(id: "stress",   color: .yellow, label: "Stress",   icon: "exclamationmark.triangle.fill"),
    SensationColor(id: "numb",     color: .blue,   label: "Numbness", icon: "snowflake"),
    SensationColor(id: "fatigue",  color: .purple, label: "Fatigue",  icon: "moon.fill"),
]

// MARK: - Legend sheet

struct LegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("What each colour means") {
                    ForEach(sensationColors) { sc in
                        HStack(spacing: 14) {
                            Image(systemName: sc.icon)
                                .foregroundStyle(sc.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sc.label)
                                    .font(.headline)
                                Text(legendDescription(for: sc.id))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Tools") {
                    ForEach(DrawingTool.allCases) { tool in
                        HStack(spacing: 14) {
                            Image(systemName: tool.icon)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.label)
                                    .font(.headline)
                                Text(toolDescription(for: tool))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Text("Your marks are saved automatically and light up the matching muscles in 3D — they’ll be here next time you open the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Marking Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func legendDescription(for id: String) -> String {
        switch id {
        case "pain":    return "Sharp, aching, or burning sensations"
        case "tension": return "Tight muscles, stiffness, or pressure"
        case "stress":  return "Areas that feel tense due to stress or anxiety"
        case "numb":    return "Numbness, tingling, or reduced sensation"
        case "fatigue": return "Fatigue, heaviness, or low energy in a region"
        default:        return ""
        }
    }

    private func toolDescription(for tool: DrawingTool) -> String {
        switch tool {
        case .pen:         return "Fine strokes — precise circling or pointing"
        case .highlighter: return "Wide strokes — cover a broad region fast"
        case .eraser:      return "Remove marks you don't need"
        }
    }
}
