import SwiftUI
import SwiftData
import Combine
import StoreKit

// BreathingPattern and BreathPhase enums live in BreathingModels.swift

// MARK: - BreathingView

struct BreathingView: View {

    // MARK: Session state
    @State private var selectedPattern: BreathingPattern = .box
    @State private var isRunning:        Bool            = false
    @State private var isPaused:         Bool            = false
    @State private var currentPhase:     BreathPhase     = .inhale
    @State private var phaseSecondsLeft: Int             = 0
    @State private var round:            Int             = 0
    @State private var totalRounds:      Int             = 5
    @State private var sessionStarted:   Date            = Date()
    @State private var showCompletion:   Bool            = false
    @State private var showingCustomEditor: Bool         = false

    // Animation
    @State private var circleScale:  CGFloat = 1.0
    @State private var circleColor:  Color   = BreathPhase.inhale.color

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    @AppStorage("totalSessionsCompleted") private var totalSessionsCompleted = 0
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false
    @AppStorage("hasSeenInitialPaywall") private var hasSeenInitialPaywall = false
    @State private var shouldRequestReview = false
    @State private var shouldShowPaywall = false

    // Fixed breathing-session routine ID (not tied to a real Routine record).
    // NOTE: must be a valid hex UUID — the previous literal contained non-hex
    // characters (B,R,E,A,T,H,I,N,G) so UUID(uuidString:) returned nil and the
    // force-unwrap trapped on launch. Kept deterministic, with a safe fallback.
    private let breathingRoutineID = UUID(uuidString: "0B5EA7B0-0000-0000-0000-000000000001") ?? UUID()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 28) {
                        patternPicker
                        circleSection
                        controlsSection
                    }
                    .padding(.bottom, 40)
                }

                // Completion overlay
                if showCompletion {
                    completionOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .navigationTitle("Breathing")
            .navigationBarTitleDisplayMode(.large)
            .animation(.easeInOut(duration: 0.35), value: showCompletion)
        }
        .onReceive(timer) { _ in
            tickTimer()
        }
        .onChange(of: showCompletion) { _, showing in
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
        .sheet(isPresented: $showingCustomEditor) {
            CustomPatternEditorView()
        }
    }

    // MARK: - Pattern picker

    private var patternPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BreathingPattern.allCases) { pattern in
                    patternCard(pattern)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func patternCard(_ pattern: BreathingPattern) -> some View {
        let isSelected = selectedPattern == pattern

        Button {
            guard !isRunning else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPattern = pattern
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: pattern.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.accentColor)

                Text(pattern.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 90, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
        .accessibilityLabel(pattern.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isRunning ? "Stop the session to change patterns" : "")
    }

    // MARK: - Circle section

    private var circleSection: some View {
        VStack(spacing: 20) {
            // Concentric ring circle
            ZStack {
                // Outer ring
                Circle()
                    .fill(circleColor.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale * 1.4)
                    .animation(circleAnimation, value: circleScale)

                // Middle ring
                Circle()
                    .fill(circleColor.opacity(0.16))
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale * 1.2)
                    .animation(circleAnimation, value: circleScale)

                // Inner filled circle
                Circle()
                    .fill(circleColor.opacity(0.35))
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale)
                    .animation(circleAnimation, value: circleScale)

                // Center content
                VStack(spacing: 4) {
                    if isRunning {
                        Text("\(phaseSecondsLeft)")
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: phaseSecondsLeft)
                    } else {
                        Image(systemName: selectedPattern.icon)
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(circleColor)
                    }
                }
            }
            .frame(height: 200 * 1.4 * 1.1)   // reserve space for outermost ring at full scale
            .animation(.easeInOut(duration: 0.4), value: circleColor)

            // Phase label
            if isRunning {
                Text(currentPhase.displayLabel)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(circleColor)
                    .id(currentPhase)          // forces crossfade on phase change
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .animation(.easeInOut(duration: 0.4), value: currentPhase)
            } else {
                Text(selectedPattern.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: selectedPattern)

                if selectedPattern == .custom {
                    Button {
                        showingCustomEditor = true
                    } label: {
                        Label("Edit Pattern", systemImage: "pencil")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.top, 4)
                }
            }

            // Round counter
            if isRunning {
                Text("Round \(round) / \(totalRounds)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .animation(.easeInOut(duration: 0.3), value: round)
            } else {
                // Round selector when idle
                HStack(spacing: 12) {
                    Text("Rounds:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Stepper("\(totalRounds)", value: $totalRounds, in: 1...20)
                        .labelsHidden()

                    Text("\(totalRounds)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .frame(minWidth: 24)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
    }

    /// The animation duration mirrors the phase duration so the circle reaches full scale at the end of inhale / fully contracts at end of exhale.
    private var circleAnimation: Animation {
        let duration: Double
        switch currentPhase {
        case .inhale:           duration = Double(selectedPattern.phases.inhale)
        case .hold, .hold2:     duration = 0.3
        case .exhale:           duration = Double(selectedPattern.phases.exhale)
        }
        return .easeInOut(duration: max(0.3, duration))
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 14) {
            // Start / Pause pill button
            Button {
                handleStartPause()
            } label: {
                Label(
                    isRunning ? (isPaused ? "Resume" : "Pause") : "Start",
                    systemImage: isRunning ? (isPaused ? "play.fill" : "pause.fill") : "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
            }

            // Stop button (shown only while running)
            if isRunning {
                Button(role: .destructive) {
                    stopSession()
                } label: {
                    Text("Stop")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemFill))
                        .clipShape(Capsule())
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.3), value: isRunning)
    }

    // MARK: - Completion overlay

    private var completionOverlay: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Session Complete")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Nice work!")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Stats card
                VStack(spacing: 12) {
                    statRow(icon: "arrow.triangle.2.circlepath",
                            color: .blue,
                            label: "Rounds completed",
                            value: "\(totalRounds)")

                    Divider()

                    statRow(icon: "star.fill",
                            color: .yellow,
                            label: "Points earned",
                            value: "+\(totalRounds * 5)")

                    Divider()

                    statRow(icon: selectedPattern.icon,
                            color: .accentColor,
                            label: "Pattern",
                            value: selectedPattern.rawValue)
                }
                .padding(20)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    // Go again
                    Button {
                        resetSession()
                    } label: {
                        Text("Go Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
                    }

                    Button {
                        resetSession()
                    } label: {
                        Text("Done")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemFill))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func statRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 26)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    // MARK: - Timer logic

    private func tickTimer() {
        guard isRunning, !isPaused, !showCompletion else { return }

        if phaseSecondsLeft > 1 {
            phaseSecondsLeft -= 1
        } else {
            advancePhase()
        }
    }

    private func advancePhase() {
        let p = selectedPattern.phases

        switch currentPhase {
        case .inhale:
            if p.hold > 0 {
                transition(to: .hold, duration: p.hold)
            } else {
                transition(to: .exhale, duration: p.exhale)
            }

        case .hold:
            transition(to: .exhale, duration: p.exhale)

        case .exhale:
            if p.hold2 > 0 {
                transition(to: .hold2, duration: p.hold2)
            } else {
                // End of round
                finishRound()
            }

        case .hold2:
            finishRound()
        }
    }

    private func finishRound() {
        if round < totalRounds {
            round += 1
            transition(to: .inhale, duration: selectedPattern.phases.inhale)
        } else {
            // Session complete
            completeSession()
        }
    }

    private func transition(to phase: BreathPhase, duration: Int) {
        VoiceCueService.shared.speak(phase.displayLabel.replacingOccurrences(of: "...", with: ""))
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPhase    = phase
            circleColor     = phase.color
            phaseSecondsLeft = duration
        }

        // Drive the circle scale
        switch phase {
        case .inhale:
            withAnimation(.easeInOut(duration: Double(duration))) {
                circleScale = 1.4
            }
        case .exhale:
            withAnimation(.easeInOut(duration: Double(duration))) {
                circleScale = 1.0
            }
        case .hold, .hold2:
            // Hold at current scale — no change needed
            break
        }
    }

    // MARK: - Session control

    private func handleStartPause() {
        if !isRunning {
            startSession()
        } else {
            if !isPaused { VoiceCueService.shared.stop() }
            withAnimation(.easeInOut(duration: 0.2)) {
                isPaused.toggle()
            }
        }
    }

    private func startSession() {
        let p = selectedPattern.phases
        sessionStarted   = Date()
        round            = 1
        isPaused         = false
        showCompletion   = false

        withAnimation(.easeInOut(duration: 0.4)) {
            isRunning        = true
            currentPhase     = .inhale
            circleColor      = BreathPhase.inhale.color
            phaseSecondsLeft = p.inhale
        }

        // Kick off the expand animation
        withAnimation(.easeInOut(duration: Double(p.inhale))) {
            circleScale = 1.4
        }
    }

    private func stopSession() {
        VoiceCueService.shared.stop()
        withAnimation(.easeInOut(duration: 0.35)) {
            isRunning  = false
            isPaused   = false
            circleScale = 1.0
            circleColor = BreathPhase.inhale.color
        }
        round            = 0
        phaseSecondsLeft = 0
        currentPhase     = .inhale
    }

    private func completeSession() {
        isRunning = false
        isPaused  = false

        withAnimation(.easeInOut(duration: 0.5)) {
            circleScale = 1.0
        }

        saveSession()

        withAnimation(.easeInOut(duration: 0.45).delay(0.1)) {
            showCompletion = true
        }
    }

    private func resetSession() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCompletion = false
        }
        circleScale      = 1.0
        circleColor      = BreathPhase.inhale.color
        currentPhase     = .inhale
        phaseSecondsLeft = 0
        round            = 0
        isRunning        = false
        isPaused         = false
    }

    // MARK: - Persistence

    private func saveSession() {
        let completedAt    = Date()
        let pointsEarned   = totalRounds * 5

        let session        = Session(
            routineID:         breathingRoutineID,
            startedAt:         sessionStarted,
            completionPercent: 1.0,
            pointsEarned:      pointsEarned
        )
        session.completedAt     = completedAt
        session.sessionLabel    = selectedPattern.rawValue
        session.roundsCompleted = totalRounds
        modelContext.insert(session)

        // Update UserProfile if present
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.totalPoints  += pointsEarned
            profile.totalMinutes += max(1, Int(completedAt.timeIntervalSince(sessionStarted) / 60))
            GamificationService.updateStreak(for: profile)
            let newBadges = GamificationService.newBadges(for: profile)
            GamificationService.applyBadges(newBadges, to: profile)
        }

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ SwiftData save failed in BreathingView: \(error)")
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

        // HealthKit — log as Mindful Session (shows in Health → Mindfulness)
        Task {
            await HealthKitService.shared.requestAuthorization()
            await HealthKitService.shared.logBreathingSession(
                startedAt: sessionStarted, completedAt: completedAt)
        }

        // Calendar — opt-in, mirrors the session as an event
        if calendarSyncEnabled {
            CalendarService.shared.logCompletedSession(
                title: "\(selectedPattern.rawValue) (\(totalRounds) rounds)",
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
}

// MARK: - Preview

#Preview {
    BreathingView()
        .modelContainer(for: [Session.self, UserProfile.self], inMemory: true)
}
