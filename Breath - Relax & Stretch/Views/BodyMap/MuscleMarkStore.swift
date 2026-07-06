import Foundation
import Combine

/// Persistent store of body-map muscle marks: `MuscleGroup` rawValue → sensation
/// color id (see `sensationColors`). Backs the 3D x-ray highlight layer.
///
/// Storage is a single Codable envelope under `bodymap.muscleMarks.v1`. On first
/// load it migrates the legacy `bodymap.markedRegions` array (old body-map region
/// names) through `MuscleGroup.migrate`, defaulting each to the `"tension"` color.
@MainActor
final class MuscleMarkStore: ObservableObject {

    /// group rawValue → sensation color id.
    @Published private(set) var marks: [String: String] = [:]

    /// Group rawValues in the order they were first marked; drives `undo()`.
    private var orderAdded: [String] = []

    private let defaults: UserDefaults

    private static let storageKey = "bodymap.muscleMarks.v1"
    private static let legacyKey = "bodymap.markedRegions"
    private static let defaultColorID = "tension"

    private struct Envelope: Codable {
        var marks: [String: String]
        var order: [String]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let env = try? JSONDecoder().decode(Envelope.self, from: data) {
            marks = env.marks
            // Keep order consistent with what's actually stored.
            orderAdded = env.order.filter { marks[$0] != nil }
        } else {
            migrateLegacyIfNeeded()
        }
    }

    // MARK: - Mutations

    func mark(_ group: MuscleGroup, colorID: String) {
        let name = group.rawValue
        if marks[name] == nil { orderAdded.append(name) }
        marks[name] = colorID
        persist()
    }

    func unmark(_ group: MuscleGroup) {
        let name = group.rawValue
        guard marks[name] != nil else { return }
        marks[name] = nil
        orderAdded.removeAll { $0 == name }
        persist()
    }

    /// Removes the most recently added mark.
    func undo() {
        guard let last = orderAdded.popLast() else { return }
        marks[last] = nil
        persist()
    }

    func clear() {
        guard !marks.isEmpty else { return }
        marks.removeAll()
        orderAdded.removeAll()
        persist()
    }

    /// Marked group names in the order they were added (stable for the UI banner).
    var markedNames: [String] { orderAdded }

    // MARK: - Persistence

    private func persist() {
        let env = Envelope(marks: marks, order: orderAdded)
        if let data = try? JSONEncoder().encode(env) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    /// One-time migration of legacy region-name marks into the new vocabulary.
    private func migrateLegacyIfNeeded() {
        guard let legacy = defaults.stringArray(forKey: Self.legacyKey) else { return }
        for name in MuscleGroup.migrate(legacy) where marks[name] == nil {
            marks[name] = Self.defaultColorID
            orderAdded.append(name)
        }
        defaults.removeObject(forKey: Self.legacyKey)
        persist()
    }
}
