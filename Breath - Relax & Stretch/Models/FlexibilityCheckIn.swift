import Foundation
import SwiftData

// MARK: - FlexibilityTest
// The fixed catalog of self-tests (code, not user data — adding one is a code
// change, which keeps the schema stable and the copy localizable). Each test
// is a standard reach with 5 ordinal levels, worst → best; the level index is
// what gets stored and charted.

enum FlexibilityTest: String, CaseIterable, Identifiable, Codable {
    case toeTouch
    case shoulderReach
    case neckRotation
    case butterfly

    var id: String { rawValue }

    var name: String {
        switch self {
        case .toeTouch:      return "Toe Touch"
        case .shoulderReach: return "Shoulder Reach"
        case .neckRotation:  return "Neck Rotation"
        case .butterfly:     return "Butterfly"
        }
    }

    var targetArea: String {
        switch self {
        case .toeTouch:      return "Hamstrings & Lower Back"
        case .shoulderReach: return "Shoulders"
        case .neckRotation:  return "Neck"
        case .butterfly:     return "Hips & Groin"
        }
    }

    var icon: String {
        switch self {
        case .toeTouch:      return "figure.flexibility"
        case .shoulderReach: return "figure.arms.open"
        case .neckRotation:  return "figure.cooldown"
        case .butterfly:     return "figure.yoga"
        }
    }

    var instructions: [String] {
        switch self {
        case .toeTouch:
            return [
                "Stand tall with your feet together, knees straight but not locked.",
                "Exhale and slowly fold forward, reaching toward your toes.",
                "No bouncing — note the farthest point you can hold for two seconds."
            ]
        case .shoulderReach:
            return [
                "Reach one arm over your shoulder and down your back.",
                "Reach the other arm up your back from below.",
                "Try to touch your fingers behind your back. Record your tighter side."
            ]
        case .neckRotation:
            return [
                "Sit or stand tall with your shoulders relaxed.",
                "Keeping your chin level, turn your head slowly to one side.",
                "Note how far you can comfortably turn. Record your tighter side."
            ]
        case .butterfly:
            return [
                "Sit on the floor with the soles of your feet together.",
                "Hold your ankles and let your knees fall outward.",
                "Sit tall — note how close your knees get to the floor."
            ]
        }
    }

    /// 5 entries, worst → best. The stored `level` is an index into this.
    var levels: [String] {
        switch self {
        case .toeTouch:
            return [
                "Fingertips reach my knees",
                "Fingertips reach mid-shin",
                "Fingertips reach my ankles",
                "Fingertips touch the floor",
                "Palms rest flat on the floor"
            ]
        case .shoulderReach:
            return [
                "Hands more than a forearm apart",
                "Hands about a hand-width apart",
                "Fingertips almost touch",
                "Fingertips touch",
                "Fingers overlap or clasp"
            ]
        case .neckRotation:
            return [
                "Chin turns less than halfway to my shoulder",
                "Chin turns about halfway",
                "Chin nearly reaches my shoulder line",
                "Chin lines up with my shoulder",
                "Chin turns past my shoulder"
            ]
        case .butterfly:
            return [
                "Knees stay up near my chest",
                "Knees drop about halfway down",
                "Knees hover a hand-width from the floor",
                "Knees nearly touch the floor",
                "Knees rest on the floor"
            ]
        }
    }
}

// MARK: - FlexibilityCheckIn
// One recorded answer: "on this date, this test scored this level."
// A check-in session writes up to one row per test (skipped tests write none).

@Model
final class FlexibilityCheckIn {
    // Inline defaults on every stored property keep the model CloudKit-compatible
    // (CloudKit requires all attributes optional or defaulted).
    var uuid: UUID = UUID()
    var date: Date = Date()
    var testID: String = FlexibilityTest.toeTouch.rawValue // raw value, not enum — keeps the schema a plain String like the rest of the models
    var level: Int = 0                                     // index into test.levels (0–4)

    var test: FlexibilityTest? { FlexibilityTest(rawValue: testID) }

    init(uuid: UUID = UUID(), date: Date = Date(), test: FlexibilityTest, level: Int) {
        self.uuid = uuid
        self.date = date
        self.testID = test.rawValue
        self.level = min(max(level, 0), test.levels.count - 1)
    }
}

// MARK: - FlexibilityStats
// Pure math over fetched check-ins, kept out of the views so it's testable
// without SwiftData or SwiftUI.

enum FlexibilityStats {

    static let checkInCadenceDays = 14

    private static func history(_ checkIns: [FlexibilityCheckIn], for test: FlexibilityTest) -> [FlexibilityCheckIn] {
        checkIns.filter { $0.testID == test.rawValue }.sorted { $0.date < $1.date }
    }

    static func latest(_ checkIns: [FlexibilityCheckIn], for test: FlexibilityTest) -> FlexibilityCheckIn? {
        history(checkIns, for: test).last
    }

    /// Latest level minus the first ever recorded level; nil until a test has
    /// at least two check-ins (there's no "progress" with a single point).
    static func delta(_ checkIns: [FlexibilityCheckIn], for test: FlexibilityTest) -> Int? {
        let ordered = history(checkIns, for: test)
        guard ordered.count >= 2, let first = ordered.first, let last = ordered.last else { return nil }
        return last.level - first.level
    }

    /// True when it's time to nudge: no check-in ever, or the most recent one
    /// (across all tests) is at least `checkInCadenceDays` old.
    static func isDue(_ checkIns: [FlexibilityCheckIn], now: Date = Date()) -> Bool {
        guard let mostRecent = checkIns.map(\.date).max() else { return true }
        return now.timeIntervalSince(mostRecent) >= Double(checkInCadenceDays) * 86_400
    }
}
