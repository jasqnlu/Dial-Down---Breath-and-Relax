import Testing
import Foundation
@testable import BreathRelaxStretch

@MainActor struct MuscleMarkStoreTests {
    private func freshDefaults() -> UserDefaults {
        let d = UserDefaults(suiteName: "MuscleMarkStoreTests")!
        d.removePersistentDomain(forName: "MuscleMarkStoreTests")
        return d
    }

    @Test func markUnmarkRoundTrip() {
        let store = MuscleMarkStore(defaults: freshDefaults())
        store.mark(.leftQuads, colorID: "pain")
        #expect(store.marks["Left Quadriceps"] == "pain")
        store.unmark(.leftQuads)
        #expect(store.marks.isEmpty)
    }

    @Test func undoRemovesMostRecent() {
        let store = MuscleMarkStore(defaults: freshDefaults())
        store.mark(.abs, colorID: "tension")
        store.mark(.leftLats, colorID: "tension")
        store.undo()
        #expect(store.marks.keys.contains("Abs"))
        #expect(!store.marks.keys.contains("Left Lats"))
    }

    @Test func migratesLegacyRegionNames() {
        let d = freshDefaults()
        d.set(["Left Hamstring", "Core"], forKey: "bodymap.markedRegions")
        let store = MuscleMarkStore(defaults: d)
        #expect(store.marks["Left Hamstrings"] == "tension")
        #expect(store.marks["Abs"] == "tension")
        #expect(d.stringArray(forKey: "bodymap.markedRegions") == nil)
    }

    @Test func persistsAcrossInstances() {
        let d = freshDefaults()
        MuscleMarkStore(defaults: d).mark(.rightCalves, colorID: "stress")
        #expect(MuscleMarkStore(defaults: d).marks["Right Calves"] == "stress")
    }
}
