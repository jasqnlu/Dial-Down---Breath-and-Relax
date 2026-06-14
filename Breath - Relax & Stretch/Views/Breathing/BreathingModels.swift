import SwiftUI

// MARK: - Breathing Pattern

enum BreathingPattern: String, CaseIterable, Identifiable {
    case box            = "Box Breathing"
    case fourSevenEight = "4-7-8"
    case belly          = "Belly Breathing"
    case energising     = "Energising"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .box:            return "square.fill"
        case .fourSevenEight: return "lungs.fill"
        case .belly:          return "circle.fill"
        case .energising:     return "bolt.fill"
        }
    }

    var description: String {
        switch self {
        case .box:
            return "Equal inhale, hold, exhale, hold — great for stress relief and focus."
        case .fourSevenEight:
            return "Calming ratio that activates the parasympathetic nervous system."
        case .belly:
            return "Diaphragmatic breathing to deepen relaxation and release tension."
        case .energising:
            return "Short exhale ratio to boost alertness and mental clarity."
        }
    }

    /// Durations: (inhale, hold, exhale, hold2) in seconds. 0 = skip phase.
    var phases: (inhale: Int, hold: Int, exhale: Int, hold2: Int) {
        switch self {
        case .box:            return (4, 4, 4, 4)
        case .fourSevenEight: return (4, 7, 8, 0)
        case .belly:          return (4, 1, 6, 0)
        case .energising:     return (6, 0, 2, 0)
        }
    }

    /// Total seconds for one full round.
    var roundDuration: Int {
        let p = phases
        return p.inhale + p.hold + p.exhale + p.hold2
    }
}

// MARK: - Breath Phase

enum BreathPhase: String {
    case inhale = "Inhale..."
    case hold   = "Hold..."
    case exhale = "Exhale..."
    case hold2  = "Hold2..."   // distinct raw value; displayLabel used for UI text

    /// Human-readable label — both hold phases show "Hold..."
    var displayLabel: String {
        switch self {
        case .inhale:       return "Inhale..."
        case .hold, .hold2: return "Hold..."
        case .exhale:       return "Exhale..."
        }
    }

    var color: Color {
        switch self {
        case .inhale:       return Color(red: 0.25, green: 0.55, blue: 0.95)   // blue
        case .hold, .hold2: return Color(red: 0.60, green: 0.35, blue: 0.90)   // purple
        case .exhale:       return Color(red: 0.25, green: 0.78, blue: 0.55)   // green
        }
    }
}
