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
    @AppStorage("pendingInitialPaywall") private var pendingInitialPaywall = false
    @AppStorage("sessionDurationMultiplier") private var durationMultiplier: Double = 1.0

    @State private var currentIndex = 0
    @State private var secondsRemaining = 0
    @State private var isPaused = false
    @State private var showingSummary = false
    @State private var totalPointsEarned = 0
    @State private var sessionStarted = Date()
    @State private var shouldRequestReview = false
    @State private var showingExitConfirmation = false
    /// Each exercise's own completion fraction, so the session's overall
    /// completionPercent reflects everything done, not just the last exercise.
    @State private var exerciseCompletions: [Double] = []

    // Big countdown numerals aren't inside any fixed-size container here (just
    // a plain VStack with Spacers), so unlike the breathing circle / graph
    // node labels there's no overflow risk in letting these scale.
    @ScaledMetric(relativeTo: .largeTitle) private var exerciseTimerSize: CGFloat = 64
    @ScaledMetric(relativeTo: .largeTitle) private var getReadyCountSize: CGFloat = 72

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

    // Side-switch cue for unilateral (one-side-at-a-time) stretches. The switch
    // point is anchored to `phaseEndDate` (via a lead offset) rather than a
    // fixed wall-clock date, so it survives pause/resume and background
    // catch-up, which already restore `phaseEndDate` as the source of truth.
    @State private var sideSwitchPending = false
    @State private var sideSwitchLeadFromEnd: TimeInterval = 0

    // Haptics
    private let impactLight   = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium  = UIImpactFeedbackGenerator(style: .medium)
    private let notifySuccess = UINotificationFeedbackGenerator()

    // Sound IDs (AudioToolbox built-in system sounds — no audio files needed)
    private let soundTick:       SystemSoundID = 1104  // keyboard click — breathing cue
    private let soundTransition: SystemSoundID = 1057  // short tock — exercise advance
    private let soundComplete:   SystemSoundID = 1016  // tweet chime — session done
    @State private var breathTick = 0  // counts seconds to fire cue every 4s
    @State private var cueBadgePulsing = false

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    private var totalSessionSeconds: Int {
        exercises.reduce(0) { total, exercise in
            total + Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
        }
    }

    private var elapsedSessionSeconds: Int {
        guard currentIndex < exercises.count else { return totalSessionSeconds }

        let completed = exercises.prefix(currentIndex).reduce(0) { total, exercise in
            total + Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
        }
        let currentDuration = Self.scaledDuration(base: exercises[currentIndex].durationSeconds, multiplier: durationMultiplier)
        let currentElapsed = max(0, min(currentDuration, currentDuration - secondsRemaining))
        return completed + currentElapsed
    }

    private var sessionProgress: Double {
        guard totalSessionSeconds > 0 else { return 0 }
        return min(1, Double(elapsedSessionSeconds) / Double(totalSessionSeconds))
    }

    var body: some View {
        Group {
            if showingSummary {
                SessionSummaryView(pointsEarned: totalPointsEarned) {
                    onComplete?(totalPointsEarned)
                    dismiss()
                    requestDeferredPaywallIfNeeded()
                }
            } else if exercises.isEmpty {
                ContentUnavailableView {
                    Label("No Exercises", systemImage: "figure.mind.and.body")
                } description: {
                    Text("There are no exercises to play.")
                } actions: {
                    Button {
                        dismiss()
                        NotificationCenter.default.post(name: .browseExercisesRequested, object: nil)
                    } label: {
                        Label("Browse Exercises", systemImage: "list.bullet")
                    }
                    .buttonStyle(LuminaPillButtonStyle())
                }
                .background(Color.luminaSurface.ignoresSafeArea())
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
                    checkSideSwitch()
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
        .confirmationDialog(
            "End session?",
            isPresented: $showingExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) { dismiss() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress on this session won't be saved.")
        }
    }

    // MARK: - Player UI

    @ViewBuilder
    private func playerContent(exercise: Exercise) -> some View {
        VStack(spacing: 0) {

            // Top bar
            HStack {
                Button { requestExit() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
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
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            }
            .padding()

            ProgressView(value: sessionProgress)
                .tint(Color.luminaPrimary)
                .padding(.horizontal)
                .animation(.linear(duration: 1), value: sessionProgress)
                .accessibilityLabel("Session progress")
                .accessibilityValue("\(Int((sessionProgress * 100).rounded())) percent")

            Spacer()

            Text(exercise.name)
                .font(.luminaDisplay)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(exercise.type.rawValue)
                .font(.luminaLabel)
                .textCase(.uppercase)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .padding(.top, 4)

            cueBadge(for: exercise.cueStyle)

            Spacer()

            if exercise.type != .breath {
                ExerciseMediaCard(exercise: exercise)
            } else {
                BreathingCircle(
                    isPaused: isPaused,
                    cycleDuration: breathingCycleDuration(for: exercise)
                )
                    .padding()
            }

            Text(timeString(secondsRemaining))
                .font(.system(size: exerciseTimerSize, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.luminaOnSurface)

            Spacer()

            HStack(spacing: 48) {
                Button {
                    impactLight.impactOccurred()
                    advanceToNext(completion: skipCompletion())
                } label: {
                    Image(systemName: "forward.skip")
                        .font(.title)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
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
                        .foregroundStyle(Color.luminaPrimary)
                        .shadow(color: Color.luminaPrimary.opacity(0.25), radius: 10, y: 5)
                }
                .accessibilityLabel(isPaused ? "Resume session" : "Pause session")

                Image(systemName: "forward.skip")
                    .font(.title)
                    .hidden()
            }
            .padding(.bottom, 48)
        }
        .background(Color.luminaSurface.ignoresSafeArea())
    }

    @ViewBuilder
    private func cueBadge(for cueStyle: ExerciseCueStyle) -> some View {
        Text(cueStyle == .hold ? "Hold" : "Keep Going")
            .font(.luminaLabel)
            .textCase(.uppercase)
            .foregroundStyle(Color.luminaPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.luminaMintTint, in: Capsule())
            .scaleEffect(cueStyle == .repeatMotion && cueBadgePulsing ? 1.07 : 1.0)
            .opacity(cueStyle == .repeatMotion && cueBadgePulsing ? 0.82 : 1.0)
            .padding(.top, 12)
            .accessibilityLabel("Exercise cue")
            .accessibilityValue(cueStyle == .hold ? "Hold" : "Keep going")
            .onAppear {
                guard cueStyle == .repeatMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    cueBadgePulsing = true
                }
            }
    }

    @ViewBuilder
    private func getReadyView(name: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Get Ready")
                .font(.luminaLabel)
                .textCase(.uppercase)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
            Text(name)
                .font(.luminaHeadline)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("\(getReadyCount)")
                .font(.system(size: getReadyCountSize, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.luminaPrimary)
            // Surface the exercise's safety caution here — this is the only
            // screen every session-launch path passes through, so users who
            // start a Quick / For You / guided-program session (skipping the
            // exercise detail page) still see it before the exercise begins.
            if let caution = currentExercise?.caution, !caution.isEmpty {
                CautionCard(text: caution)
                    .padding(.horizontal)
            }
            Spacer()
            Button("Skip") { skipGetReady() }
                .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))
        }
        .padding()
        .background(Color.luminaSurface.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { skipGetReady() }
        .accessibilityLabel("Get ready for \(name), starting in \(getReadyCount)")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Logic

    static func scaledDuration(base: Int, multiplier: Double) -> Int {
        max(1, Int(Double(base) * multiplier))
    }

    private func breathingCycleDuration(for exercise: Exercise) -> Double {
        let scaled = Self.scaledDuration(base: exercise.durationSeconds, multiplier: durationMultiplier)
        // Breath exercises in the stretch player do not carry a phase model,
        // so tie the visual cadence to the exercise length instead of a fixed
        // 4s pulse. Longer holds breathe more slowly; short drills stay lively.
        return min(8, max(3, Double(scaled) / 10))
    }

    private func beginNextExercise() {
        guard let exercise = currentExercise else {
            startExercise()
            return
        }
        // Auto-skip is a convenience preference for the get-ready countdown,
        // but we never skip it for an exercise that carries a safety caution —
        // the get-ready screen is the slot where that caution is surfaced.
        if autoSkipGetReadyCountdown && (exercise.caution ?? "").isEmpty {
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
        guard isShowingGetReady else { return }
        getReadyTask?.cancel()
        isShowingGetReady = false
        startExercise()
    }

    /// Dismisses immediately if nothing has been done yet; otherwise confirms
    /// first so an accidental tap mid-routine doesn't silently discard progress.
    private func requestExit() {
        if currentIndex > 0 {
            showingExitConfirmation = true
        } else {
            dismiss()
        }
    }

    private func skipCompletion() -> Double {
        guard let duration = currentExercise?.durationSeconds else { return 0.5 }
        return GamificationService.skipCompletion(elapsedSeconds: duration - secondsRemaining, durationSeconds: duration)
    }

    private func startExercise() {
        let baseDuration = currentExercise?.durationSeconds ?? 60
        let duration = Self.scaledDuration(base: baseDuration, multiplier: durationMultiplier)
        secondsRemaining = duration
        phaseEndDate = Date().addingTimeInterval(TimeInterval(duration))
        pausedRemaining = nil
        isPaused = false
        // Unilateral stretches: cue a side switch at the halfway point, then
        // let the same exercise run the second half before advancing.
        if let exercise = currentExercise, exercise.isBilateral == false {
            sideSwitchPending = true
            sideSwitchLeadFromEnd = TimeInterval(duration) / 2
        } else {
            sideSwitchPending = false
            sideSwitchLeadFromEnd = 0
        }
        if let exercise = currentExercise {
            VoiceCueService.shared.speak(exercise.name)
        }
    }

    /// Fires the "switch sides" haptic + voice cue once, when the current
    /// unilateral exercise passes its halfway point. Anchored to
    /// `phaseEndDate` so pause/resume and background catch-up stay correct.
    private func checkSideSwitch() {
        guard sideSwitchPending else { return }
        let switchDate = phaseEndDate.addingTimeInterval(-sideSwitchLeadFromEnd)
        guard Date() >= switchDate else { return }
        sideSwitchPending = false
        impactMedium.impactOccurred()
        VoiceCueService.shared.speak("Switch sides")
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
                // If the halfway switch point elapsed while backgrounded, fire
                // the cue now (once) so the user isn't left on the wrong side.
                checkSideSwitch()
                break
            }
            advanceToNext(completion: 1.0, showGetReady: false)
        }
    }

    private func advanceToNext(completion: Double, showGetReady: Bool = true) {
        totalPointsEarned += GamificationService.points(for: currentExercise, completion: completion)
        exerciseCompletions.append(completion)

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
            saveSession()
            showingSummary = true
        }
    }

    // MARK: - Persistence

    private func saveSession() {
        let completedAt = Date()
        let bodyPartsCovered = Set(exercises.flatMap { $0.targetBodyParts })
        let exerciseNames = exercises.map { $0.name }.joined(separator: ", ")

        totalSessionsCompleted += 1
        SessionRecorder.record(
            SessionRecorder.Input(
                routineID: routineID,
                startedAt: sessionStarted,
                completedAt: completedAt,
                completionPercent: GamificationService.aggregateCompletion(exerciseCompletions),
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
            pendingInitialPaywall = true
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

    private func requestDeferredPaywallIfNeeded() {
        guard pendingInitialPaywall else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            NotificationCenter.default.post(name: .deferredPaywallRequested, object: nil)
        }
    }
}

// MARK: - Breathing animation

struct BreathingCircle: View {
    let isPaused: Bool
    let cycleDuration: Double
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.luminaGradientStart.opacity(0.10))
                .frame(width: 160, height: 160)
                .scaleEffect(scale * 1.2)

            Circle()
                .fill(Color.luminaPrimary.opacity(0.15))
                .frame(width: 160, height: 160)
                .scaleEffect(scale)

            Circle()
                .fill(Color.luminaPrimary.opacity(0.25))
                .frame(width: 100, height: 100)
        }
        .onAppear { animate() }
        .onChange(of: cycleDuration) { _, _ in
            guard !isPaused else { return }
            scale = 1.0
            animate()
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                withAnimation(.easeOut(duration: 0.3)) { scale = 1.0 }
            } else {
                animate()
            }
        }
    }

    private func animate() {
        withAnimation(.easeInOut(duration: cycleDuration).repeatForever(autoreverses: true)) {
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
