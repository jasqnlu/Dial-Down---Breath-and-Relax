import SwiftUI

// MARK: - CustomPatternEditorView
// Lets the user define their own inhale/hold/exhale/hold timing for the
// "Custom" breathing pattern. Values are read directly by
// BreathingPattern.phases via UserDefaults.

struct CustomPatternEditorView: View {
    @AppStorage("customBreath.inhale") private var inhale = 4
    @AppStorage("customBreath.hold")   private var hold   = 4
    @AppStorage("customBreath.exhale") private var exhale = 4
    @AppStorage("customBreath.hold2")  private var hold2  = 0

    @Environment(\.dismiss) private var dismiss

    private var totalSeconds: Int { inhale + hold + exhale + hold2 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    stepperRow("Inhale", value: $inhale, range: 1...20)
                    stepperRow("Hold", value: $hold, range: 0...20)
                    stepperRow("Exhale", value: $exhale, range: 1...20)
                    stepperRow("Hold (after exhale)", value: $hold2, range: 0...20)
                } footer: {
                    Text("Set a hold to 0 seconds to skip it. One full round takes \(totalSeconds)s.")
                }
            }
            .navigationTitle("Custom Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value.wrappedValue)s")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    CustomPatternEditorView()
}
