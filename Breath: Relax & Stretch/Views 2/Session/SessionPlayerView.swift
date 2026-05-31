import SwiftUI

struct SessionPlayerView: View {
    let exercises: [Exercise]
    var onComplete: ((Int) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var secondsRemaining = 0
    @State private var isPaused = false
    @State private var showingSummary = false
    @State private var totalPointsEarned = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var body: some View {
        Group {
            if showingSummary {
                SessionSummaryView(pointsEarned: totalPointsEarned) {
                    onComplete?(totalPointsEarned)
                    dismiss()
                }
            } else if let exercise = currentExercise {
                playerContent(exercise: exercise)
            }
        }
        .onAppear { startExercise() }
        .onReceive(timer) { _ in
            guard !isPaused, !showingSummary else { return }
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                advanceToNext(completion: 1.0)
            }
        }
    }

    // MARK: - Player UI

    @ViewBuilder
    private func playerContent(exercise: Exercise) -> some View {
        VStack(spacing: 0) {

            // Top bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(currentIndex + 1) / \(exercises.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            ProgressView(value: Double(currentIndex), total: Double(exercises.count))
                .padding(.horizontal)

            Spacer()

            // Exercise name
            Text(exercise.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(exercise.type.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Spacer()

            // Breathing animation circle
            BreathingCircle(isPaused: isPaused)
                .padding()

            // Countdown timer
            Text(timeString(secondsRemaining))
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .monospacedDigit()

            Spacer()

            // Controls
            HStack(spacing: 48) {
                Button {
                    advanceToNext(completion: 0.5)
                } label: {
                    Image(systemName: "forward.skip")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                Button {
                    isPaused.toggle()
                } label: {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.accentColor)
                }

                // Spacer to balance the skip button
                Image(systemName: "forward.skip")
                    .font(.title)
                    .hidden()
            }
            .padding(.bottom, 48)
        }
    }

    // MARK: - Logic

    private func startExercise() {
        secondsRemaining = currentExercise?.durationSeconds ?? 60
        isPaused = false
    }

    private func advanceToNext(completion: Double) {
        totalPointsEarned += GamificationService.points(for: currentExercise, completion: completion)
        if currentIndex + 1 < exercises.count {
            currentIndex += 1
            startExercise()
        } else {
            showingSummary = true
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Breathing animation

struct BreathingCircle: View {
    let isPaused: Bool
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.08))
                .frame(width: 160, height: 160)
                .scaleEffect(scale * 1.2)

            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 160, height: 160)
                .scaleEffect(scale)

            Circle()
                .fill(Color.accentColor.opacity(0.25))
                .frame(width: 100, height: 100)
        }
        .onAppear { animate() }
        .onChange(of: isPaused) { _, paused in
            if paused {
                withAnimation(.easeOut(duration: 0.3)) { scale = 1.0 }
            } else {
                animate()
            }
        }
    }

    private func animate() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            scale = 1.35
        }
    }
}

#Preview {
    SessionPlayerView(exercises: [
        Exercise(
            name: "Deep Belly Breath",
            type: .breath,
            targetBodyParts: ["Core", "Chest"],
            durationSeconds: 120,
            difficulty: 1,
            instructions: ["Breathe in slowly.", "Hold.", "Breathe out."]
        )
    ])
}
