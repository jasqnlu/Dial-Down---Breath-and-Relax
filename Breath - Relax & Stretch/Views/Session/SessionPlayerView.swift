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
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("totalSessionsCompleted") private var totalSessionsCompleted = 0
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false
    @AppStorage("hasSeenInitialPaywall") private var hasSeenInitialPaywall = false
    @AppStorage("sessionDurationMultiplier") private var durationMultiplier: Double = 1.0
    @State private var shouldShowPaywall = false

    @State private var currentIndex = 0
    @State private var secondsRemaining = 0
    @State private var isPaused = false
    @State private var showingSummary = false
    @State private var totalPointsEarned = 0
    @State private var sessionStarted = Date()
    @State private var shouldRequestReview = false

    // Wall-clock end of the current exercise's countdown. `secondsRemaining` is
    // a display value derived from this each tick, so backgrounding the app
    // (a call, app-switch) doesn't stall the countdown — real elapsed time
    // still counts down, and `scenePhase` catches us up on return.
    @State private var phaseEndDate = Date()
    @State private var pausedRemaining: TimeInterval? = nil

    @AppStorage("autoSkipGetReadyCountdown") private var autoSkipGetReadyCountdown = false
    @State private var isShowingGetReady = false
    @State private var getReadyExerciseName = ""
    @State private var getReadyCount = 3
    @State private var getReadyTask: Task<Void, Never>? = nil

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
            } else if exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "figure.mind.and.body",
                    description: Text("There are no exercises to play.")
                )
                .overlay(alignment: .topLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            } else if isShowingGetReady {
                getReadyView(name: getReadyExerciseName)
            } else if let exercise = currentExercise {
                playerContent(exercise: exercise)
            }
        }
        .onAppear {
            sessionStarted = Date()
            beginNextExercise()
            impactLight.prepare()
            impactMedium.prepare()
            notifySuccess.prepare()
            // Keep the screen awake — the user is mid-stretch and not touching
            // the screen; auto-lock would freeze the main-runloop timer.
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            VoiceCueService.shared.stop()
            getReadyTask?.cancel()
        }
        .task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                guard !isPaused, !showingSummary, !isShowingGetReady else { continue }
                let remaining = Int(phaseEndDate.timeIntervalSinceNow.rounded(.up))
                if remaining > 0 {
                    secondsRemaining = remaining
                    breathTick += 1
                    if breathTick % 4 == 0 { AudioServicesPlaySystemSound(soundTick) }
                } else {
                    advanceToNext(completion: 1.0)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, !isPaused, !showingSummary, !isShowingGetReady else { return }
            catchUpAfterBackground()
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
                Picker("Speed", selection: $durationMultiplier) {
                    Text("0.5x").tag(0.5)
                    Text("1x").tag(1.0)
                    Text("2x").tag(2.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityLabel("Exercise duration speed")
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

            if exercise.type != .breath {
                ExerciseMediaCard(exercise: exercise)
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
                    if isPaused {
                        phaseEndDate = Date().addingTimeInterval(pausedRemaining ?? 0)
                        pausedRemaining = nil
                    } else {
                        pausedRemaining = max(0, phaseEndDate.timeIntervalSinceNow)
                    }
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

    @ViewBuilder
    private func getReadyView(name: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Get Ready")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(name)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("\(getReadyCount)")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .monospacedDigit()
            Spacer()
            Button("Skip") { skipGetReady() }
                .buttonStyle(.bordered)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { skipGetReady() }
        .accessibilityLabel("Get ready for \(name), starting in \(getReadyCount)")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Logic

    static func scaledDuration(base: Int, multiplier: Double) -> Int {
        max(1, Int(Double(base) * multiplier))
    }

    private func beginNextExercise() {
        guard !autoSkipGetReadyCountdown, let exercise = currentExercise else {
            startExercise()
            return
        }
        getReadyExerciseName = exercise.name
        getReadyCount = 3
        isShowingGetReady = true
        runGetReadyCountdown()
    }

    private func runGetReadyCountdown() {
        getReadyTask = Task { @MainActor in
            while isShowingGetReady, getReadyCount > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard isShowingGetReady, !Task.isCancelled else { return }
                getReadyCount -= 1
            }
            guard isShowingGetReady, !Task.isCancelled else { return }
            isShowingGetReady = false
            startExercise()
        }
    }

    private func skipGetReady() {
        getReadyTask?.cancel()
        isShowingGetReady = false
        startExercise()
    }

    private func startExercise() {
        let baseDuration = currentExercise?.durationSeconds ?? 60
        let duration = Self.scaledDuration(base: baseDuration, multiplier: durationMultiplier)
        secondsRemaining = duration
        phaseEndDate = Date().addingTimeInterval(TimeInterval(duration))
        pausedRemaining = nil
        isPaused = false
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
    }

    /// Called when the app returns to the foreground. `Timer.publish` doesn't
    /// fire while backgrounded, so real elapsed time may have already blown
    /// past one or more exercises' durations — walk forward through them
    /// (each picking up a fresh full duration) until we land on one that's
    /// still in progress, or the session completes.
    private func catchUpAfterBackground() {
        while !showingSummary {
            let remaining = phaseEndDate.timeIntervalSinceNow
            if remaining > 0 {
                secondsRemaining = Int(remaining.rounded(.up))
                break
            }
            advanceToNext(completion: 1.0, showGetReady: false)
        }
    }

    private func advanceToNext(completion: Double, showGetReady: Bool = true) {
        totalPointsEarned += GamificationService.points(for: currentExercise, completion: completion)

        if currentIndex + 1 < exercises.count {
            impactMedium.impactOccurred()
            AudioServicesPlaySystemSound(soundTransition)
            currentIndex += 1
            breathTick = 0
            if showGetReady {
                beginNextExercise()
            } else {
                startExercise()
            }
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
        let exerciseNames = exercises.map { $0.name }.joined(separator: ", ")

        totalSessionsCompleted += 1
        SessionRecorder.record(
            SessionRecorder.Input(
                routineID: routineID,
                startedAt: sessionStarted,
                completedAt: completedAt,
                completionPercent: completion,
                pointsEarned: totalPointsEarned,
                exerciseIDs: exercises.map { $0.uuid },
                bodyPartsCovered: bodyPartsCovered,
                isBorrowedRoutine: isBorrowedRoutine,
                calendarTitle: "Stretch Session: \(exerciseNames)",
                healthKitKind: .stretch
            ),
            modelContext: modelContext,
            calendarSyncEnabled: calendarSyncEnabled,
            totalSessionsCompleted: totalSessionsCompleted
        )

        if totalSessionsCompleted == 3 && !hasSeenInitialPaywall {
            hasSeenInitialPaywall = true
            shouldShowPaywall = true
        } else {
            let reviewMilestones: Set<Int> = [10, 25]
            if reviewMilestones.contains(totalSessionsCompleted) {
                shouldRequestReview = true
            }
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
    .modelContainer(for: [Session.self, UserProfile.self], inMemory: true)
}
