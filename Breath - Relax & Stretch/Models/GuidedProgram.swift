import Foundation

// MARK: - GuidedProgram
// Static, multi-day program content. Days reference exercises by name
// (resolved against the live Exercise table at render time), matching the
// pattern GoalMeta already uses — keeps this decoupled from SwiftData since
// it's curated content, not user data.

struct ProgramDay: Identifiable {
    let dayNumber: Int
    let exerciseNames: [String]
    var id: Int { dayNumber }
}

struct GuidedProgram: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let days: [ProgramDay]
}

extension GuidedProgram {
    /// A rotating 30-day mix of every goal category, generated from the
    /// existing GoalMeta exercise pools rather than hand-authored content.
    /// Free, like everything else in the app.
    static let fullReset: GuidedProgram = {
        let pool = Array(Set(GoalMeta.all.flatMap(\.exerciseNames))).sorted()
        let days = (1...30).map { day -> ProgramDay in
            let offset = (day - 1) * 3
            let names = (0..<4).map { pool[(offset + $0) % pool.count] }
            return ProgramDay(dayNumber: day, exerciseNames: names)
        }
        return GuidedProgram(
            id: "program_30day_full_reset",
            title: "30-Day Full Reset",
            summary: "A rotating month of flexibility, stress relief, pain relief, and breathing work — just a few minutes a day.",
            icon: "calendar.badge.clock",
            days: days
        )
    }()

    /// Free for everyone. Built from the user's onboarding goals so it's
    /// personalized without requiring a Pro purchase.
    static func starterProgram(goalIDs: Set<String>) -> GuidedProgram {
        let activeGoals = GoalMeta.all.filter { goalIDs.contains($0.id) }
        let source = activeGoals.isEmpty ? GoalMeta.all : activeGoals
        let pool = interleavedNames(from: source, limit: 9)

        let days = (1...3).map { day -> ProgramDay in
            let start = (day - 1) * 3
            let names = start < pool.count
                ? Array(pool[start..<min(start + 3, pool.count)])
                : Array(pool.prefix(3))
            return ProgramDay(dayNumber: day, exerciseNames: names)
        }

        return GuidedProgram(
            id: "starter",
            title: "Your Starter Program",
            summary: "A free 3-day program built from your goals.",
            icon: "sparkles",
            days: days
        )
    }

    private static func interleavedNames(from goals: [GoalMeta], limit: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        let lists = goals.map(\.exerciseNames)
        var index = 0
        while result.count < limit {
            var addedAny = false
            for list in lists where index < list.count {
                let name = list[index]
                if seen.insert(name).inserted {
                    result.append(name)
                    addedAny = true
                }
            }
            if !addedAny { break }
            index += 1
        }
        return result
    }
}
