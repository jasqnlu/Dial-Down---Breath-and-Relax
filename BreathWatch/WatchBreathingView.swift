import SwiftUI

// MARK: - WatchBreathingView
// Glanceable breathing timer for the wrist. Reuses BreathingPattern/BreathPhase
// from the iPhone app's BreathingModels.swift — add that file to this target's
// membership in Xcode (File Inspector → Target Membership) so it compiles here.
// ".custom" is skipped since its editor only exists on the iPhone.

struct WatchBreathingView: View {
    @State private var selectedPattern: BreathingPattern = .box
    @State private var isRunning = false
    @State private var currentPhase: BreathPhase = .inhale
    @State private var phaseSecondsLeft = 0
    /// Wall-clock deadline for the current phase. phaseSecondsLeft is derived
    /// from this each tick instead of being decremented, matching the fix
    /// applied to the iPhone app's BreathingView — a stalled timer under
    /// wrist-down/backgrounding otherwise leaves the countdown out of sync.
    @State private var phaseEndDate = Date()
    @State private var round = 0
    @State private var totalRounds = 5
    @State private var circleScale: CGFloat = 1.0

    @StateObject private var workout = WatchWorkoutManager()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var patterns: [BreathingPattern] {
        BreathingPattern.allCases.filter { $0 != .custom }
    }

    var body: some View {
        NavigationStack {
            if isRunning {
                sessionView
            } else {
                pickerView
            }
        }
        .onReceive(timer) { _ in tick() }
    }

    // MARK: Picker

    private var pickerView: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(patterns) { pattern in
                    Button {
                        selectedPattern = pattern
                        start()
                    } label: {
                        HStack {
                            Image(systemName: pattern.icon)
                            Text(pattern.rawValue)
                                .font(.footnote)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Breathe")
    }

    // MARK: Session

    private var sessionView: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(currentPhase.color.opacity(0.3))
                .scaleEffect(circleScale)
                .frame(width: 90, height: 90)
                .overlay(
                    Text("\(phaseSecondsLeft)")
                        .font(.system(size: 26, weight: .light, design: .rounded))
                )
                .animation(.easeInOut(duration: 0.4), value: circleScale)

            Text(currentPhase.displayLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(currentPhase.color)

            if workout.heartRate > 0 {
                Label("\(Int(workout.heartRate)) bpm", systemImage: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Text("Round \(round)/\(totalRounds)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button("Stop", role: .destructive) { stop() }
                .font(.caption2)
        }
        .padding()
    }

    // MARK: Logic — mirrors BreathingView's phase machine

    private func start() {
        Task {
            if await workout.requestAuthorization() {
                workout.start()
            }
        }
        round = 1
        currentPhase = .inhale
        phaseSecondsLeft = selectedPattern.phases.inhale
        phaseEndDate = Date().addingTimeInterval(TimeInterval(selectedPattern.phases.inhale))
        circleScale = 1.0
        isRunning = true
        withAnimation(.easeInOut(duration: Double(selectedPattern.phases.inhale))) {
            circleScale = 1.4
        }
    }

    private func stop() {
        workout.stop()
        isRunning = false
    }

    private func tick() {
        guard isRunning else { return }
        let remaining = Int(phaseEndDate.timeIntervalSinceNow.rounded(.up))
        if remaining > 1 {
            phaseSecondsLeft = remaining
        } else {
            advancePhase()
        }
    }

    private func advancePhase() {
        let p = selectedPattern.phases
        switch currentPhase {
        case .inhale:
            transition(to: p.hold > 0 ? .hold : .exhale, duration: p.hold > 0 ? p.hold : p.exhale)
        case .hold:
            transition(to: .exhale, duration: p.exhale)
        case .exhale:
            if p.hold2 > 0 {
                transition(to: .hold2, duration: p.hold2)
            } else {
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
            stop()
        }
    }

    private func transition(to phase: BreathPhase, duration: Int) {
        currentPhase = phase
        phaseSecondsLeft = max(1, duration)
        phaseEndDate = Date().addingTimeInterval(TimeInterval(max(1, duration)))
        withAnimation(.easeInOut(duration: Double(max(1, duration)))) {
            if phase == .inhale { circleScale = 1.4 }
            if phase == .exhale { circleScale = 1.0 }
        }
    }
}

#Preview {
    WatchBreathingView()
}
