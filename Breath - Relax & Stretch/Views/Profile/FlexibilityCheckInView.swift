import SwiftUI
import SwiftData
import os

// MARK: - FlexibilityCheckInView
// The periodic "how far can you reach?" self-test — one page per test in
// FlexibilityTest.allCases: instructions, then a tappable list of the five
// ordinal levels. Answers are held in memory and written only when the whole
// flow finishes, so backing out of the sheet records nothing partial.

struct FlexibilityCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var answers: [FlexibilityTest: Int] = [:]

    private let tests = FlexibilityTest.allCases

    private var test: FlexibilityTest { tests[currentIndex] }
    private var isLastTest: Bool { currentIndex == tests.count - 1 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(currentIndex), total: Double(tests.count))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityLabel("Test \(currentIndex + 1) of \(tests.count)")

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(test.targetArea, systemImage: test.icon)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                            ForEach(Array(test.instructions.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(i + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 18, height: 18)
                                        .background(Circle().fill(Color(.tertiarySystemFill)))
                                    Text(step)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("How far did you get?") {
                        ForEach(Array(test.levels.enumerated()), id: \.offset) { level, label in
                            Button {
                                answers[test] = level
                            } label: {
                                HStack {
                                    Text(label)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if answers[test] == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Skip") { advance() }
                        .buttonStyle(.bordered)

                    Button(isLastTest ? "Finish" : "Next") { advance() }
                        .buttonStyle(.borderedProminent)
                        .disabled(answers[test] == nil)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle(test.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .interactiveDismissDisabled(!answers.isEmpty)
    }

    private func advance() {
        if isLastTest {
            finish()
        } else {
            currentIndex += 1
        }
    }

    private func finish() {
        // One shared timestamp so the whole check-in reads as a single event
        // in history and the charts.
        let now = Date()
        for (test, level) in answers {
            modelContext.insert(FlexibilityCheckIn(date: now, test: test, level: level))
        }
        do {
            try modelContext.save()
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "flexibilityCheckIn").warning("Save failed: \(error)")
        }
        dismiss()
    }
}

#Preview {
    FlexibilityCheckInView()
        .modelContainer(for: FlexibilityCheckIn.self, inMemory: true)
}
