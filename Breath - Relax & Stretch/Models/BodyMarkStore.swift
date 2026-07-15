import Foundation
import Combine
import simd

/// One mark per region, facing-independent. `point` is the tapped surface
/// point in normalized model space — where the marker dot renders.
struct BodyMark: Codable, Equatable {
    let sensationID: String
    let point: SIMD3<Float>
}

/// Replaces AnnotationStore. Persists region → mark as JSON in UserDefaults.
/// No migration from the old "bodymap.markedRegions" key: marks were
/// transient before this feature (nothing ever wrote-then-displayed them).
final class BodyMarkStore: ObservableObject {
    static let storageKey = "bodymap.markedSensations"

    @Published private(set) var marks: [String: BodyMark] = [:]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([String: BodyMark].self, from: data) {
            marks = decoded
        }
    }

    var markedRegions: Set<String> { Set(marks.keys) }

    /// Tap semantics: unmarked → mark; marked with another sensation →
    /// recolor; marked with the same sensation → unmark.
    func toggle(region: String, sensationID: String, point: SIMD3<Float>) {
        if marks[region]?.sensationID == sensationID {
            marks[region] = nil
        } else {
            marks[region] = BodyMark(sensationID: sensationID, point: point)
        }
        save()
    }

    func clear() {
        marks = [:]
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(marks) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
