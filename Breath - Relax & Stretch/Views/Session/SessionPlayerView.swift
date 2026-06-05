import SwiftUI
import SwiftData
import Combine

struct SessionPlayerView: View {
    let exercises: [Exercise]
    var routineID: UUID = UUID()          // pass the routine's UUID when launching
    var onComplete: ((Int) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var secondsRemaining = 0
    @State private var isPaused = false
    @State private var showingSummary = false
    @State private var totalPointsEarned = 0
    @State private var sessionStarted = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Haptics
    private let impactLight   = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium  = UIImpactFeedbackGenerator(style: .medium)
    private let notifySuccess = UINotificationFeedbackGenerator()

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
        .onAppear {
            sessionStarted = Date()
            startExercise()
            impactLight.prepare()
            impactMedium.prepare()
            notifySuccess.prepare()
        }
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

            BreathingCircle(isPaused: isPaused)
                .padding()

            Text(timeString(secondsRemaining))
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .monospacedDigit()

            Spacer()

            HStack(spacing: 48) {
                Button {
                    impactLight.impactOccurred()
                    advanceToNext(completion: 0.5)
                } label: {
                    Image(systemName: "forward.skip")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                Button {
                    impactLight.impactOccurred()
                    isPaused.toggle()
                } label: {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.accentColor)
                }

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
            impactMedium.impactOccurred()
            currentIndex += 1
            startExercise()
        } else {
            // Session complete
            notifySuccess.notificationOccurred(.success)
            saveSession(completion: completion)
            showingSummary = true
        }
    }

    // MARK: - Persistence

    private func saveSession(completion: Double) {
        let completedAt = Date()

        // Save Session record
        let session = Session(
            routineID: routineID,
            startedAt: sessionStarted,
            completionPercent: completion,
            pointsEarned: totalPointsEarned
        )
        session.completedAt = completedAt
        modelContext.insert(session)

        // Update or create UserProfile
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.totalPoints   += totalPointsEarned
            profile.totalMinutes  += max(1, Int(completedAt.timeIntervalSince(sessionStarted) / 60))
            GamificationService.updateStreak(for: profile)
            let newBadges = GamificationService.newBadges(for: profile)
            GamificationService.applyBadges(newBadges, to: profile)
        }

        try? modelContext.save()
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
    .modelContainer(for: [Session.self, UserProfile.self], inMemory: true)
}
