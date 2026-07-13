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
                    .tint(Color.luminaPrimary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityLabel("Test \(currentIndex + 1) of \(tests.count)")

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(test.targetArea, systemImage: test.icon)
                                .font(.luminaCardTitle)
                                .foregroundStyle(Color.luminaPrimary)
                            ForEach(Array(test.instructions.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(i + 1)")
                                        .font(.luminaCaption)
                                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                                        .frame(width: 18, height: 18)
                                        .background(Circle().fill(Color.luminaContainer))
                                    Text(step)
                                        .font(.luminaSubheadline)
                                        .foregroundStyle(Color.luminaOnSurface)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.luminaCardFill)

                    Section("How far did you get?") {
                        ForEach(Array(test.levels.enumerated()), id: \.offset) { level, label in
                            Button {
                                answers[test] = level
                            } label: {
                                HStack {
                                    Text(label)
                                        .font(.luminaBody)
                                        .foregroundStyle(Color.luminaOnSurface)
                                    Spacer()
                                    if answers[test] == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.luminaPrimary)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.luminaCardFill)
                }
                .scrollContentBackground(.hidden)

                HStack(spacing: 12) {
                    Button("Skip") { advance() }
                        .buttonStyle(LuminaPillButtonStyle(kind: .ghost))

                    Button(isLastTest ? "Finish" : "Next") { advance() }
                        .buttonStyle(LuminaPillButtonStyle())
                        .disabled(answers[test] == nil)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background(Color.luminaSurface.ignoresSafeArea())
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
