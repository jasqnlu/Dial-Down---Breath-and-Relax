import SwiftUI

// MARK: - Sensation colour palette
//
// The vocabulary for body marks: each marked region carries one sensation
// (BodyMarkStore keys marks by region name → SensationColor.id).

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

                Section {
                    Text("Pick a colour, then tap the muscles that feel this way. Your marks are saved automatically and will be here next time you open the app.")
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
}

#Preview {
    LegendSheet()
}
