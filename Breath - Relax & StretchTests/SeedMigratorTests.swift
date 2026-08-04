import Testing
import SwiftData
import Foundation
@testable import BreathRelaxStretch

// Covers the rename-safety fix for the seed migration pipeline: matching
// installed Exercise rows to bundled SeedData.json entries by a stable
// `seedID` instead of `name`, so renaming an exercise in the seed catalog
// no longer orphans the user's row / inserts a silent duplicate.
@MainActor
struct SeedMigratorTests {

    private func makeContext() -> ModelContext {
        let container = try! ModelContainer(
            for: Exercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func rawExercise(
        id: String, name: String, targetBodyParts: [String] = ["Left Quadriceps"]
    ) -> [String: Any] {
        [
            "id": id,
            "name": name,
            "type": "Stretch",
            "targetBodyParts": targetBodyParts,
            "durationSeconds": 60,
            "difficulty": 1,
            "instructions": ["Step one.", "Step two.", "Step three."],
        ]
    }

    // MARK: - v4: normal migration still works

    @Test func v4UpdatesExistingRowMatchedBySeedID() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Quad Stretch", type: .stretch,
            targetBodyParts: ["Left Leg"], durationSeconds: 60,
            difficulty: 1, instructions: ["a", "b", "c"]
        )
        exercise.seedID = "quad-stretch-id"
        context.insert(exercise)
        try context.save()

        let raw = [rawExercise(id: "quad-stretch-id", name: "Quad Stretch")]
        let changed = SeedMigrator.migrateV4(context: context, rawExercises: raw)
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all.count == 1)
        #expect(all[0].targetBodyParts == ["Left Quadriceps"])
        #expect(all[0].seedID == "quad-stretch-id")
    }

    @Test func v4InsertsBrandNewSeedExercise() throws {
        let context = makeContext()
        let raw = [rawExercise(id: "new-id", name: "New Stretch")]
        let changed = SeedMigrator.migrateV4(context: context, rawExercises: raw)
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all.count == 1)
        #expect(all[0].name == "New Stretch")
        #expect(all[0].seedID == "new-id")
    }

    @Test func v4LeavesUserCreatedExerciseAlone() throws {
        let context = makeContext()
        let custom = Exercise(
            name: "My Custom Move", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 30,
            difficulty: 1, instructions: ["x", "y", "z"]
        )
        context.insert(custom)
        try context.save()

        let raw = [rawExercise(id: "seed-1", name: "Something Else")]
        _ = SeedMigrator.migrateV4(context: context, rawExercises: raw)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all.count == 2)
        let mine = all.first { $0.name == "My Custom Move" }
        #expect(mine?.targetBodyParts == ["Left Quadriceps"])
    }

    // MARK: - v4: rename doesn't break migration

    @Test func v4RenameInSeedDoesNotOrphanOrDuplicate() throws {
        let context = makeContext()
        // User's installed row already carries the stable seedID from a
        // previous migration/seed — the exercise's *display name* is stale
        // relative to a since-renamed bundle entry.
        let exercise = Exercise(
            name: "Old Name", type: .stretch,
            targetBodyParts: ["Left Leg"], durationSeconds: 60,
            difficulty: 1, instructions: ["a", "b", "c"]
        )
        exercise.seedID = "stable-id-1"
        context.insert(exercise)
        try context.save()

        // The bundle seed renamed this exercise but kept the same id.
        let raw = [rawExercise(id: "stable-id-1", name: "New Name")]
        let changed = SeedMigrator.migrateV4(context: context, rawExercises: raw)
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        // Must still be exactly one row — a name-keyed match would have
        // missed the existing row (still called "Old Name" on-device) and
        // inserted a duplicate under "New Name" instead of updating in place.
        #expect(all.count == 1)
        #expect(all[0].seedID == "stable-id-1")
        #expect(all[0].targetBodyParts == ["Left Quadriceps"])
    }

    // MARK: - v6: seedID backfill bootstrap

    @Test func v6BackfillsSeedIDForLegacyRowsByName() throws {
        let context = makeContext()
        let legacy = Exercise(
            name: "Legacy Stretch", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 60,
            difficulty: 1, instructions: ["a", "b", "c"]
        )
        // Simulates a row seeded before Exercise.seedID existed.
        #expect(legacy.seedID == nil)
        context.insert(legacy)
        try context.save()

        let raw = [rawExercise(id: "legacy-id", name: "Legacy Stretch")]
        let changed = SeedMigrator.migrateV6(context: context, rawExercises: raw)
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all.count == 1)
        #expect(all[0].seedID == "legacy-id")
    }

    @Test func v6IsNoOpOnceSeedIDIsSet() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Already Linked", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 60,
            difficulty: 1, instructions: ["a", "b", "c"]
        )
        exercise.seedID = "already-set"
        context.insert(exercise)
        try context.save()

        let raw = [rawExercise(id: "already-set", name: "Renamed In Bundle")]
        let changed = SeedMigrator.migrateV6(context: context, rawExercises: raw)
        #expect(!changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].seedID == "already-set")
        // v6 never touches name/content — that's v4's job.
        #expect(all[0].name == "Already Linked")
    }

    // MARK: - v5: isBilateral backfill

    @Test func v5FlipsIsBilateralFalseForNamedUnilateralExercises() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Left Single-Leg Reach", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 60,
            difficulty: 1, instructions: ["a", "b", "c"]
        )
        #expect(exercise.isBilateral)
        context.insert(exercise)
        try context.save()

        var raw = rawExercise(id: "unilateral-1", name: "Left Single-Leg Reach")
        raw["isBilateral"] = false
        let changed = SeedMigrator.migrateV5(context: context, rawExercises: [raw])
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].isBilateral == false)
    }

    @Test func v5NeverTouchesUserCreatedExercises() throws {
        let context = makeContext()
        let custom = Exercise(
            name: "My Custom Move", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 30,
            difficulty: 1, instructions: ["x", "y", "z"]
        )
        context.insert(custom)
        try context.save()

        let changed = SeedMigrator.migrateV5(context: context, rawExercises: [])
        #expect(!changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].isBilateral)
    }

    // MARK: - v4: animationName on fresh insert

    @Test func v4InsertsAnimationName() throws {
        let context = makeContext()
        var raw = rawExercise(id: "new-id", name: "New Stretch")
        raw["animationName"] = "anim.mp4"
        _ = SeedMigrator.migrateV4(context: context, rawExercises: [raw])

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].animationName == "anim.mp4")
    }

    // MARK: - v7: animationName backfill onto existing installs

    @Test func v7BackfillsAnimationNameBySeedID() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Clasp", type: .stretch,
            targetBodyParts: ["Left Shoulder"], durationSeconds: 45,
            difficulty: 2, instructions: ["a", "b", "c"]
        )
        exercise.seedID = "clasp-id"
        #expect(exercise.animationName == nil)
        context.insert(exercise)
        try context.save()

        var raw = rawExercise(id: "clasp-id", name: "Clasp")
        raw["animationName"] = "clasped_hands_behind_back.mp4"
        let changed = SeedMigrator.migrateV7(context: context, rawExercises: [raw])
        #expect(changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].animationName == "clasped_hands_behind_back.mp4")
    }

    @Test func v7DoesNotClobberExistingAnimation() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Clasp", type: .stretch,
            targetBodyParts: ["Left Shoulder"], durationSeconds: 45,
            difficulty: 2, instructions: ["a", "b", "c"]
        )
        exercise.seedID = "clasp-id"
        exercise.animationName = "already.mp4"
        context.insert(exercise)
        try context.save()

        var raw = rawExercise(id: "clasp-id", name: "Clasp")
        raw["animationName"] = "clasped_hands_behind_back.mp4"
        let changed = SeedMigrator.migrateV7(context: context, rawExercises: [raw])
        #expect(!changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].animationName == "already.mp4")
    }

    @Test func v7NeverTouchesUserCreatedExercises() throws {
        let context = makeContext()
        let custom = Exercise(
            name: "My Custom Move", type: .stretch,
            targetBodyParts: ["Left Quadriceps"], durationSeconds: 30,
            difficulty: 1, instructions: ["x", "y", "z"]
        )
        context.insert(custom)   // no seedID
        try context.save()

        var raw = rawExercise(id: "seed-1", name: "Some Seed")
        raw["animationName"] = "x.mp4"
        let changed = SeedMigrator.migrateV7(context: context, rawExercises: [raw])
        #expect(!changed)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        #expect(all[0].animationName == nil)
    }
}
