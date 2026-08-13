import SwiftUI
import SwiftData

// MARK: - TodayView
// The landing tab. One job: get the user into today's session in a single
// tap, with their momentum (streak/minutes/points) visible at a glance.
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
    @State private var isBreathingIn = false
    @State private var brokenStreakValue: Int? = nil

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
                    statRow
                    programCard
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

            if let profile, profile.streak > 0 {
                HStack(spacing: 4) {
                    if showStreakEmoji { Text("🔥") }
                    Text("\(profile.streak)")
                        .font(.custom("ManropeExtraLight-Bold", size: 15, relativeTo: .subheadline))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.luminaCardFill, in: Capsule())
                .accessibilityLabel("\(profile.streak) day streak")
            }
        }
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
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
    }

    // MARK: - Stats

    private var statRow: some View {
        HStack(spacing: 10) {
            statTile(value: "\(profile?.streak ?? 0)", label: "day streak")
            statTile(value: "\(profile?.totalMinutes ?? 0)", label: "minutes")
            statTile(value: "\(profile?.totalPoints ?? 0)", label: "points")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.luminaTitle)
            Text(label)
                .font(.luminaCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .luminaCard(padding: 0)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Starter program

    private var programCard: some View {
        let program = GuidedProgram.starterProgram(goalIDs: activeGoalIDs)

        return NavigationLink(destination: GuidedProgramDetailView(program: program)) {
            HStack(spacing: 14) {
                Image(systemName: program.icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.luminaMintTint, in: RoundedRectangle(cornerRadius: LuminaRadius.chip, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(program.title)
                        .font(.luminaCardTitle)
                        .foregroundStyle(.primary)
                    Text("\(program.days.count) days · free")
                        .font(.luminaCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .luminaCard(padding: 14)
        }
        .buttonStyle(.plain)
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
