import Testing
import Foundation
import simd
@testable import BreathRelaxStretch

struct BodyMarkStoreTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func toggleMarksUpdatesAndUnmarks() {
        let store = BodyMarkStore(defaults: freshDefaults())
        store.toggle(region: "Left Biceps", sensationID: "pain", point: [0.1, 0.3, 0.05])
        #expect(store.marks["Left Biceps"]?.sensationID == "pain")

        // Different sensation selected → recolor, not unmark.
        store.toggle(region: "Left Biceps", sensationID: "tension", point: [0.1, 0.3, 0.05])
        #expect(store.marks["Left Biceps"]?.sensationID == "tension")

        // Same sensation again → unmark.
        store.toggle(region: "Left Biceps", sensationID: "tension", point: [0.1, 0.3, 0.05])
        #expect(store.marks["Left Biceps"] == nil)
    }

    @Test func persistsAcrossInstances() {
        let defaults = freshDefaults()
        BodyMarkStore(defaults: defaults)
            .toggle(region: "Right Knee", sensationID: "pain", point: [-0.1, -0.35, 0.02])
        let reloaded = BodyMarkStore(defaults: defaults)
        #expect(reloaded.marks["Right Knee"]?.point == SIMD3<Float>(-0.1, -0.35, 0.02))
        #expect(reloaded.markedRegions == ["Right Knee"])
    }

    @Test func clearEmptiesStoreAndDisk() {
        let defaults = freshDefaults()
        let store = BodyMarkStore(defaults: defaults)
        store.toggle(region: "Abs", sensationID: "stress", point: [0, 0.1, 0.12])
        store.clear()
        #expect(store.marks.isEmpty)
        #expect(BodyMarkStore(defaults: defaults).marks.isEmpty)
    }
}
