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
    @Query private var exercises: [Exercise]
    @Query private var profiles: [UserProfile]
    @AppStorage("onboardingGoals") private var goalsStr = ""
    @AppStorage("showStreakEmoji") private var showStreakEmoji = true

    @State private var showingSession = false
    @State private var isBreathingIn = false

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

    /// Today's session: goal-based recommendations, falling back to the first
    /// few catalog exercises when no goals were picked during onboarding.
    private var sessionExercises: [Exercise] {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingHeader
                    heroCard
                    statRow
                    programCard
                    forYouSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .floatingTabBarClearance()
        }
        .sheet(isPresented: $showingSession) {
            SessionPlayerView(exercises: sessionExercises)
        }
        .onAppear {
            guard !reduceMotion else { return }
            isBreathingIn = true
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
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let profile, profile.streak > 0 {
                HStack(spacing: 4) {
                    if showStreakEmoji { Text("🔥") }
                    Text("\(profile.streak)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                .accessibilityLabel("\(profile.streak) day streak")
            }
        }
    }

    // MARK: - Hero: today's session

    private var heroCard: some View {
        let totalSecs = sessionExercises.reduce(0) { $0 + $1.durationSeconds }
        let mins = max(1, totalSecs / 60)

        return ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color(.systemTeal).opacity(0.75), Color(.systemIndigo).opacity(0.9)],
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
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("\(sessionExercises.count) exercises · \(mins) min")
                        .font(.subheadline)
                        .opacity(0.85)
                }

                Button {
                    showingSession = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Begin")
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.systemIndigo))
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
        .clipShape(RoundedRectangle(cornerRadius: 22))
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
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
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
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(program.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(program.days.count) days · free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - For You

    @ViewBuilder
    private var forYouSection: some View {
        if !forYouExercises.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("For You")
                    .font(.system(.title3, design: .rounded, weight: .bold))

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
    let schema = Schema([Exercise.self, Routine.self, Session.self, UserProfile.self, BodyPart.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    TodayView()
        .modelContainer(container)
        .environmentObject(AuthManager.shared)
}
