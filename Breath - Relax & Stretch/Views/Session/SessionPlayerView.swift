import SwiftUI
import SwiftData
import Combine
import AudioToolbox
import StoreKit

struct SessionPlayerView: View {
    let exercises: [Exercise]
    var routineID: UUID = UUID()
    var isBorrowedRoutine: Bool = false   // true when playing a forked public routine
    var onComplete: ((Int) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @AppStorage("totalSessionsCompleted") private var totalSessionsCompleted = 0
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false
    @AppStorage("hasSeenInitialPaywall") private var hasSeenInitialPaywall = false
    @State private var shouldShowPaywall = false

    @State private var currentIndex = 0
    @State private var secondsRemaining = 0
    @State private var isPaused = false
    @State private var showingSummary = false
    @State private var totalPointsEarned = 0
    @State private var sessionStarted = Date()
    /// Set to false in .onDisappear so the timer stops processing ticks after dismiss
    @State private var sessionActive = false
    @State private var shouldRequestReview = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Haptics
    private let impactLight   = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium  = UIImpactFeedbackGenerator(style: .medium)
    private let notifySuccess = UINotificationFeedbackGenerator()

    // Sound IDs (AudioToolbox built-in system sounds — no audio files needed)
    private let soundTick:       SystemSoundID = 1104  // keyboard click — breathing cue
    private let soundTransition: SystemSoundID = 1057  // short tock — exercise advance
    private let soundComplete:   SystemSoundID = 1016  // tweet chime — session done
    @State private var breathTick = 0  // counts seconds to fire cue every 4s

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
            sessionActive  = true
            sessionStarted = Date()
            startExercise()
            impactLight.prepare()
            impactMedium.prepare()
            notifySuccess.prepare()
        }
        .onDisappear {
            sessionActive = false
            VoiceCueService.shared.stop()
        }
        .onChange(of: showingSummary) { _, showing in
            guard showing, shouldRequestReview else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                requestReview()
                shouldRequestReview = false
            }
        }
        .sheet(isPresented: $shouldShowPaywall) {
            PaywallView()
        }
        .onReceive(timer) { _ in
            guard sessionActive, !isPaused, !showingSummary else { return }
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                // Breathing tick every 4 seconds
                breathTick += 1
                if breathTick % 4 == 0 {
                    AudioServicesPlaySystemSound(soundTick)
                }
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

            if exercise.type != .breath, !exercise.poses.isEmpty {
                StickFigureView(
                    poses: exercise.poses,
                    activeBodyParts: Set(exercise.targetBodyParts),
                    isPaused: isPaused
                )
                .frame(maxWidth: 220)
                .padding(.horizontal)
            } else {
                BreathingCircle(isPaused: isPaused)
                    .padding()
            }

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
                .accessibilityLabel("Skip exercise")

                Button {
                    impactLight.impactOccurred()
                    isPaused.toggle()
                } label: {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityLabel(isPaused ? "Resume session" : "Pause session")

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
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
    }

    private func advanceToNext(completion: Double) {
        totalPointsEarned += GamificationService.points(for: currentExercise, completion: completion)

        if currentIndex + 1 < exercises.count {
            impactMedium.impactOccurred()
            AudioServicesPlaySystemSound(soundTransition)
            currentIndex += 1
            breathTick = 0
            startExercise()
        } else {
            // Session complete
            notifySuccess.notificationOccurred(.success)
            AudioServicesPlaySystemSound(soundComplete)
            saveSession(completion: completion)
            showingSummary = true
        }
    }

    // MARK: - Persistence

    private func saveSession(completion: Double) {
        let completedAt = Date()
        let bodyPartsCovered = Set(exercises.flatMap { $0.targetBodyParts })

        let session = Session(
            routineID: routineID,
            startedAt: sessionStarted,
            completionPercent: completion,
            pointsEarned: totalPointsEarned
        )
        session.completedAt = completedAt
        session.exerciseIDs = exercises.map { $0.uuid }
        modelContext.insert(session)

        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.totalPoints   += totalPointsEarned
            profile.totalMinutes  += max(1, Int(completedAt.timeIntervalSince(sessionStarted) / 60))
            GamificationService.updateStreak(for: profile)
            let newBadges = GamificationService.newBadges(for: profile, bodyPartsCovered: bodyPartsCovered)
            GamificationService.applyBadges(newBadges, to: profile)
            if isBorrowedRoutine {
                GamificationService.awardBadge("Borrowed & Built", to: profile)
            }
        }

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ SwiftData save failed in SessionPlayerView: \(error)")
            #endif
        }

        totalSessionsCompleted += 1
        if totalSessionsCompleted == 3 && !hasSeenInitialPaywall {
            hasSeenInitialPaywall = true
            shouldShowPaywall = true
        } else {
            let reviewMilestones: Set<Int> = [10, 25]
            if reviewMilestones.contains(totalSessionsCompleted) {
                shouldRequestReview = true
            }
        }

        // HealthKit — log as Flexibility workout; request auth only if not yet granted
        Task {
            if !HealthKitService.shared.isWriteAuthorized {
                await HealthKitService.shared.requestAuthorization()
            }
            await HealthKitService.shared.logStretchSession(
                startedAt: sessionStarted, completedAt: completedAt)
        }

        // Calendar — opt-in, mirrors the session as an event
        if calendarSyncEnabled {
            let exerciseNames = exercises.map { $0.name }.joined(separator: ", ")
            CalendarService.shared.logCompletedSession(
                title: "Stretch Session: \(exerciseNames)",
                start: sessionStarted, end: completedAt)
        }

        // Widget — update shared data so home screen widgets refresh
        let streak = (try? modelContext.fetch(FetchDescriptor<UserProfile>()).first?.streak) ?? 0
        WidgetDataService.write(
            streak: streak,
            totalSessions: totalSessionsCompleted,
            lastSessionDate: completedAt
        )
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
