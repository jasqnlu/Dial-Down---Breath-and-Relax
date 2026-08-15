import SwiftUI
import SwiftData

// MARK: - TodayView
// The landing tab. One job: get the user into today's session in a single
// tap. Momentum is a single glance, not a dashboard: the streak button in
// the header's top-right is the only stat on this screen — the old
// streak/minutes/points tile row and the starter-program promo card were
// both removed as clutter competing with that one job (their content is
// still reachable from Profile → Progress & Charts).
// Visually it continues the AuthView motif — same teal→indigo gradient,
// same breathing halo, same white pill button — so sign-in and home read
// as one flow.

struct TodayView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query private var profiles: [UserProfile]
    @Query private var routines: [Routine]
    @AppStorage("onboardingGoals") private var goalsStr = ""
    @AppStorage("onboardingAreas") private var onboardingAreas = ""
    @AppStorage("showStreakEmoji") private var showStreakEmoji = true
    @AppStorage("pinnedWakeUpRoutineID") private var pinnedWakeUpRoutineIDString = ""

    @State private var showingSession = false
    @State private var showingCustomize = false
    @State private var pendingShowSessionAfterCustomize = false
    @State private var isBreathingIn = false
    @State private var brokenStreakValue: Int? = nil
    @EnvironmentObject private var pickingSession: ExercisePickingSession
    @State private var customizeOverride: (title: String, exercises: [Exercise], isPinned: Bool)?

    enum TimeOfDayFocus: Equatable {
        case wakeUp, unwind, none

        var heroTitle: String {
            switch self {
            case .wakeUp: return "Wake Up"
            case .unwind: return "Unwind"
            case .none:   return "Today's session"
            }
        }
    }

    static func timeOfDayFocus(forHour hour: Int) -> TimeOfDayFocus {
        switch hour {
        case 5..<11:         return .wakeUp
        case 20..<24, 0..<5: return .unwind
        default:             return .none
        }
    }

    private var timeOfDayFocus: TimeOfDayFocus {
        Self.timeOfDayFocus(forHour: Calendar.current.component(.hour, from: .now))
    }

    private var profile: UserProfile? { profiles.first }

    private var activeGoalIDs: Set<String> {
        Set(goalsStr.split(separator: ",").map(String.init))
    }

    /// The saved routine the user pinned via Customize ("Keep as my Wake Up
    /// routine"), if any is set and it still resolves to at least one real
    /// exercise. Checked before the goal-based fallback below.
    private var pinnedSessionExercises: [Exercise]? {
        guard let pinnedID = UUID(uuidString: pinnedWakeUpRoutineIDString),
              let routine = routines.first(where: { $0.uuid == pinnedID }) else {
            return nil
        }
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        let resolved = routine.exerciseIDs.compactMap { byID[$0] }
        return resolved.isEmpty ? nil : resolved
    }

    /// Today's session: goal-based recommendations, falling back to the first
    /// few catalog exercises when no goals were picked during onboarding.
    ///
    /// The pinned routine only activates during Wake Up hours — it's named
    /// after the AppStorage key (`pinnedWakeUpRoutineID`) and the hero's
    /// literal "Wake Up" wording. Pinning from Unwind or the midday
    /// fallback state must not leak into the other time-of-day sessions.
    private var sessionExercises: [Exercise] {
        switch timeOfDayFocus {
        case .wakeUp:
            if let pinnedSessionExercises {
                return pinnedSessionExercises
            }
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["wake_up"], limit: 4)
            if !pool.isEmpty { return pool }
        case .unwind:
            let pool = GoalMeta.recommend(from: exercises, activeGoalIDs: ["unwind"], limit: 4)
            if !pool.isEmpty { return pool }
        case .none:
            break
        }
        let recommended = GoalMeta.recommend(from: exercises, activeGoalIDs: activeGoalIDs, limit: 4)
        return recommended.isEmpty ? Array(exercises.prefix(4)) : recommended
    }

    private var forYouExercises: [Exercise] {
        GoalMeta.recommend(from: exercises, activeGoalIDs: activeGoalIDs, limit: 8)
    }

    /// Personalised recommendations for the rotating carousel, keyed off the
    /// focus areas the user picked at signup (`onboardingAreas`).
    private var recommendedItems: [RecommendedExercise] {
        ExerciseCategory.recommendedExercises(
            from: exercises,
            areas: ExerciseCategory.areas(from: onboardingAreas),
            limit: 10
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingHeader
                    heroCard
                    recommendedSection
                    forYouSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.luminaSurface)
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .floatingTabBarClearance()
        }
        .sheet(isPresented: $showingSession) {
            SessionPlayerView(exercises: sessionExercises)
        }
        .sheet(isPresented: $showingCustomize, onDismiss: {
            // Present the session sheet only after Customize has fully
            // dismissed — two sibling .sheet(isPresented:) modifiers can't
            // both be driven true in the same tick, or the second one
            // silently never appears.
            if pendingShowSessionAfterCustomize {
                pendingShowSessionAfterCustomize = false
                showingSession = true
            }
            // Cleared here rather than only in `onDone`, so it is cleared no
            // matter HOW the re-presented Customize sheet was left (Done,
            // swipe-to-dismiss, or the toolbar X). Left set, a stale override
            // would silently win over the fresh `timeOfDayFocus` default the
            // next time Customize is opened — possibly hours or a day later.
            // Safe against the picking flow: its re-population happens in the
            // `.exercisePickingFinished` `.onReceive` below, which fires from
            // the NEXT session's Done, not from this dismissal.
            customizeOverride = nil
        }) {
            CustomizeRoutineView(
                title: customizeOverride?.title ?? timeOfDayFocus.heroTitle,
                exercises: customizeOverride?.exercises ?? sessionExercises,
                isPinned: customizeOverride?.isPinned ?? (timeOfDayFocus == .wakeUp && pinnedSessionExercises != nil),
                onDone: { exercises, pinned in
                    customizeOverride = nil
                    if pinned {
                        if let existingID = UUID(uuidString: pinnedWakeUpRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            // Update the already-pinned routine in place rather
                            // than inserting a duplicate every time the user
                            // re-pins from Customize.
                            existing.exerciseIDs = exercises.map(\.uuid)
                            existing.name = timeOfDayFocus.heroTitle
                        } else {
                            let routine = Routine(name: timeOfDayFocus.heroTitle, exerciseIDs: exercises.map(\.uuid))
                            modelContext.insert(routine)
                            pinnedWakeUpRoutineIDString = routine.uuid.uuidString
                        }
                        try? modelContext.save()
                    } else {
                        // Delete the underlying Routine on unpin, not just the
                        // AppStorage pointer to it — otherwise it survives as
                        // an orphan in the CloudKit-synced store, and the next
                        // re-pin (with the ID already cleared) would insert a
                        // brand-new duplicate instead of ever finding it again.
                        if let existingID = UUID(uuidString: pinnedWakeUpRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            modelContext.delete(existing)
                            try? modelContext.save()
                        }
                        pinnedWakeUpRoutineIDString = ""
                    }
                    pendingShowSessionAfterCustomize = true
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            guard let result = pickingSession.consumeFinished() else { return }
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
        .alert(
            "Streak Lost",
            isPresented: Binding(
                get: { brokenStreakValue != nil },
                set: { if !$0 { brokenStreakValue = nil } }
            )
        ) {
            if let profile, profile.streakFreezeTokens > 0 {
                Button("Restore Streak (\(profile.streakFreezeTokens) left)") {
                    GamificationService.restoreStreak(for: profile)
                    try? modelContext.save()
                    brokenStreakValue = nil
                }
            }
            Button("Dismiss", role: .cancel) {
                if let profile {
                    GamificationService.dismissStreakBreak(for: profile)
                    try? modelContext.save()
                }
                brokenStreakValue = nil
            }
        } message: {
            if let brokenStreakValue {
                Text("Your \(brokenStreakValue)-day streak was lost.")
            }
        }
        .onAppear {
            if !reduceMotion { isBreathingIn = true }
            if let profile {
                let broken = GamificationService.checkForBrokenStreak(for: profile)
                brokenStreakValue = broken
                if broken != nil {
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Greeting

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Time to unwind"
        }
    }

    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(auth.displayName.isEmpty || auth.isGuest
                     ? greeting
                     : "\(greeting), \(auth.displayName)")
                    .font(.luminaHeadline)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.luminaSubheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            streakButton
        }
    }

    /// The only stat on this screen — always visible (even at a 0 streak,
    /// now that the removed stat-tile row isn't showing it as a fallback)
    /// and a real NavigationLink into Progress & Charts, not just a
    /// decorative badge.
    private var streakButton: some View {
        NavigationLink(destination: ProgressChartsView()) {
            HStack(spacing: 4) {
                if showStreakEmoji { Text("🔥") }
                Text("\(profile?.streak ?? 0)")
                    .font(.custom("ManropeExtraLight-Bold", size: 15, relativeTo: .subheadline))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.luminaCardFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile?.streak ?? 0) day streak, view progress")
    }

    // MARK: - Hero: today's session

    private var heroCard: some View {
        let totalSecs = sessionExercises.reduce(0) { $0 + $1.durationSeconds }
        // Round rather than truncate, so e.g. a 90s session reads "2m" instead
        // of always flooring to "1m" regardless of how much over a minute it is.
        let mins = totalSecs > 0 ? max(1, Int((Double(totalSecs) / 60).rounded())) : 0

        return ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color.luminaGradientStart, Color.luminaGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // The breathing halo — same cadence as the sign-in screen. The
            // animation is scoped to these circles via .animation(value:);
            // a withAnimation(.repeatForever) in onAppear would leak into
            // every concurrent layout change (tab bar, sheets) forever.
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 170, height: 170)
                    .scaleEffect(isBreathingIn ? 1.16 : 0.9)
                Circle()
                    .fill(.white.opacity(0.14))
                    .frame(width: 110, height: 110)
                    .scaleEffect(isBreathingIn ? 1.08 : 0.94)
            }
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isBreathingIn)
            .offset(x: 40, y: -30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayFocus.heroTitle)
                        .font(.luminaTitle)
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.luminaSubheadline)
                        .opacity(0.85)
                }

                RoadmapWave(exercises: sessionExercises)

                HStack(spacing: 10) {
                    Button {
                        showingCustomize = true
                    } label: {
                        Text("Customize")
                            .font(.luminaLabel)
                    }
                    .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))

                    Button {
                        showingSession = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Begin")
                        }
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaBlue)
                        .padding(.horizontal, 28)
                        .frame(height: 44)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Begin today's session: \(sessionExercises.count) exercises, \(mins) minutes")
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
    }

    // MARK: - Recommended (rotating carousel)

    @ViewBuilder
    private var recommendedSection: some View {
        let items = recommendedItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended for You")
                    .font(.luminaTitle)
                RecommendedCarousel(items: items)
            }
        }
    }

    // MARK: - For You

    @ViewBuilder
    private var forYouSection: some View {
        if !forYouExercises.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("For You")
                    .font(.luminaTitle)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(forYouExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ForYouCard(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

#Preview {
    let schema = Schema([Exercise.self, Routine.self, Session.self, UserProfile.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    TodayView()
        .modelContainer(container)
        .environmentObject(AuthManager.shared)
}
