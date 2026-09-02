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
    @AppStorage("pinnedTodayRoutineID") private var pinnedTodayRoutineIDString = ""

    @State private var showingSession = false
    @State private var showingCustomize = false
    @State private var pendingShowSessionAfterCustomize = false
    @State private var selectedPremadeRoutine: PremadeRoutine?
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

    /// The saved "Today" routine the user pinned via Customize ("Keep as my
    /// Today routine"), if any is set and it still resolves to at least one
    /// real exercise. Checked before any time-of-day-based recommendation.
    private var pinnedSessionExercises: [Exercise]? {
        guard let pinnedID = UUID(uuidString: pinnedTodayRoutineIDString),
              let routine = routines.first(where: { $0.uuid == pinnedID }) else {
            return nil
        }
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        let resolved = routine.exerciseIDs.compactMap { byID[$0] }
        return resolved.isEmpty ? nil : resolved
    }

    /// Whether the hero card is currently showing the pinned "Today"
    /// routine rather than a time-of-day/goal-based recommendation — drives
    /// the "Pinned as Today" tag next to the hero title.
    private var isPinnedActive: Bool {
        pinnedSessionExercises != nil
    }

    /// The pinned "Today" routine's per-exercise duration overrides, or
    /// empty when nothing is pinned — threaded into SessionPlayerView so
    /// durations customized (and saved) via Customize actually take effect
    /// during playback, not just in the preview.
    private var sessionDurationOverrides: [UUID: Int] {
        guard let pinnedID = UUID(uuidString: pinnedTodayRoutineIDString),
              let routine = routines.first(where: { $0.uuid == pinnedID }),
              pinnedSessionExercises != nil else {
            return [:]
        }
        return routine.exerciseDurationOverrides
    }

    /// Today's session: the pinned "Today" routine if one is set, else
    /// goal-based recommendations, falling back to the first few catalog
    /// exercises when no goals were picked during onboarding.
    ///
    /// The pin now applies regardless of time of day — a single "Today"
    /// routine, not one scoped to Wake Up hours.
    private var sessionExercises: [Exercise] {
        if let pinnedSessionExercises {
            return pinnedSessionExercises
        }
        switch timeOfDayFocus {
        case .wakeUp:
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
                    premadeRoutinesSection
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
            SessionPlayerView(exercises: sessionExercises, durationOverrides: sessionDurationOverrides)
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
                isPinned: customizeOverride?.isPinned ?? isPinnedActive,
                onDone: { exercises, pinned, durationOverrides in
                    customizeOverride = nil
                    if pinned {
                        if let existingID = UUID(uuidString: pinnedTodayRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            // Update the already-pinned routine in place rather
                            // than inserting a duplicate every time the user
                            // re-pins from Customize.
                            existing.exerciseIDs = exercises.map(\.uuid)
                            existing.name = "Today"
                            existing.exerciseDurationOverrides = durationOverrides
                        } else {
                            let routine = Routine(
                                name: "Today",
                                exerciseIDs: exercises.map(\.uuid),
                                exerciseDurationOverrides: durationOverrides
                            )
                            modelContext.insert(routine)
                            pinnedTodayRoutineIDString = routine.uuid.uuidString
                        }
                        try? modelContext.save()
                    } else {
                        // Delete the underlying Routine on unpin, not just the
                        // AppStorage pointer to it — otherwise it survives as
                        // an orphan in the CloudKit-synced store, and the next
                        // re-pin (with the ID already cleared) would insert a
                        // brand-new duplicate instead of ever finding it again.
                        if let existingID = UUID(uuidString: pinnedTodayRoutineIDString),
                           let existing = routines.first(where: { $0.uuid == existingID }) {
                            modelContext.delete(existing)
                            try? modelContext.save()
                        }
                        pinnedTodayRoutineIDString = ""
                    }
                    pendingShowSessionAfterCustomize = true
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .exercisePickingFinished)) { _ in
            // Peek first and check originTab before consuming — a second screen
            // (RoutineBuilderView, via RoutineListView) can also finish a pick
            // now, and this same notification fires at every mounted listener.
            guard let result = pickingSession.lastFinished, result.context.originTab == 0 else { return }
            _ = pickingSession.consumeFinished()
            customizeOverride = (result.context.title, result.merged, result.context.isPinned)
            showingCustomize = true
        }
        .sheet(item: $selectedPremadeRoutine) { routine in
            RoutineBuilderView(
                initialExerciseIDs: routine.resolvedExercises(in: exercises).map(\.uuid),
                initialName: routine.title,
                pickingOriginTab: 0
            )
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
            // One-time migration: the pin used to be scoped to Wake Up hours
            // only, under this key. Carry an existing pin forward under the
            // new key rather than silently dropping it for upgrading users.
            // The old key is left in place (unused) rather than deleted —
            // there's no reader left for it either way.
            if pinnedTodayRoutineIDString.isEmpty,
               let legacy = UserDefaults.standard.string(forKey: "pinnedWakeUpRoutineID"),
               !legacy.isEmpty {
                pinnedTodayRoutineIDString = legacy
            }
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
    /// decorative badge. At 0 the flame+count reads as a small failure
    /// badge, so instead of swapping it out at 0 the same flame+count stays
    /// in place at every streak value — only the flame's own color changes,
    /// unlit (grey) at 0 and lit (orange) once today counts toward a
    /// streak, so the badge never reads as a bare failure state.
    private var streakButton: some View {
        let streak = profile?.streak ?? 0
        let isLit = streak > 0
        return NavigationLink(destination: ProgressChartsView()) {
            HStack(spacing: 5) {
                if showStreakEmoji {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isLit ? Color.luminaOrange : Color.luminaOnSurfaceVariant.opacity(0.5))
                }
                Text("\(streak)")
                    .font(.custom("ManropeExtraLight-Bold", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(isLit ? Color.luminaOnSurface : Color.luminaOnSurfaceVariant)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.luminaCardFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLit ? "\(streak) day streak, view progress" : "No streak yet today, view progress")
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
                    HStack(spacing: 8) {
                        Text(timeOfDayFocus.heroTitle)
                            .font(.luminaTitle)
                        if isPinnedActive {
                            Label("Pinned as Today", systemImage: "bookmark.fill")
                                .font(.luminaCaption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.22), in: Capsule())
                        }
                    }
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.luminaSubheadline)
                        .opacity(0.85)
                }

                RoadmapWave(exercises: sessionExercises)

                HStack {
                    // Demoted to a plain text link — a second pill here
                    // read as competing with Begin for the primary action.
                    // A Spacer (rather than a fixed gap) pins it to the
                    // leading edge and Begin to the trailing edge, so the
                    // pair spans the card's full width instead of both
                    // bunching on the left.
                    Button {
                        showingCustomize = true
                    } label: {
                        Text("Customize")
                            .font(.luminaLabel)
                            .foregroundStyle(.white.opacity(0.8))
                            .underline()
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 12)

                    Button {
                        showingSession = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Begin")
                            if mins > 0 {
                                Text("\(mins) min")
                                    .font(.luminaCaption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.luminaOnPrimary.opacity(0.18), in: Capsule())
                            }
                        }
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaOnPrimary)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(Color.luminaPrimary, in: Capsule())
                        .shadow(color: Color.luminaPrimary.opacity(0.35), radius: 10, y: 5)
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
        .tourAnchor("today.heroCard")
    }

    // MARK: - Section headers
    //
    // A small uppercase label rather than `.luminaTitle` — the size the hero
    // title uses. These sections are secondary to "Today's session"; giving
    // their headers the same weight made them compete with the hero for top
    // billing instead of reading as its supporting content.
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.luminaCaption)
            .fontWeight(.bold)
            .tracking(1.2)
            .foregroundStyle(Color.luminaOnSurfaceVariant)
    }

    // MARK: - Recommended (rotating carousel)

    @ViewBuilder
    private var recommendedSection: some View {
        let items = recommendedItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Recommended for You")
                RecommendedCarousel(items: items)
            }
            .tourAnchor("today.recommended")
        }
    }

    // MARK: - Premade Routines

    @ViewBuilder
    private var premadeRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Premade Routines")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(PremadeRoutine.all) { routine in
                        let meta = premadeMeta(for: routine)
                        Button {
                            selectedPremadeRoutine = routine
                        } label: {
                            PremadeRoutineCard(routine: routine, meta: meta)
                        }
                        .buttonStyle(.plain)
                        .disabled(meta == nil)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    /// The raw (count, minutes) behind the card's meta line, or nil if the
    /// routine currently resolves to zero exercises. Kept as data rather
    /// than a formatted String so the call site can render a `Text` literal
    /// that participates in localization — see PremadeRoutineCard.
    private func premadeMeta(for routine: PremadeRoutine) -> (count: Int, minutes: Int)? {
        let resolved = routine.resolvedExercises(in: exercises)
        guard !resolved.isEmpty else { return nil }
        let totalSecs = resolved.reduce(0) { $0 + $1.durationSeconds }
        let mins = max(1, Int((Double(totalSecs) / 60).rounded()))
        return (resolved.count, mins)
    }

    // MARK: - For You

    @ViewBuilder
    private var forYouSection: some View {
        if !forYouExercises.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("For You")

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
