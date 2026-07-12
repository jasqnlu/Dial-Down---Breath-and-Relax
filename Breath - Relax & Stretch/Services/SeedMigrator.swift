import Foundation
import SwiftData

/// Pure, testable seed-migration logic used by `BreathRelaxStretchApp`.
///
/// Backfills data added to the bundled seed after a user first installed:
///   v2 — pose keyframes for the stick-figure animation
///   v3 — video tutorial links (mediaURL) for select exercises
///   v4 — full muscle-group vocabulary (MuscleGroup) + full coverage seed
///   v5 — isBilateral flag (side-switch cue for unilateral stretches)
///   v6 — backfills `Exercise.seedID` onto rows seeded before that field
///        existed, so all subsequent matching can key off a stable id
///        instead of `name` (renaming a seed exercise used to silently
///        orphan the user's row and insert a duplicate under the new name)
enum SeedMigrator {

    /// v3 — the one place name-matching is still acceptable: it predates
    /// `Exercise.seedID` and only ever runs once, on installs old enough to
    /// lack the id entirely.
    @discardableResult
    static func migrateV3(context: ModelContext, rawExercises: [[String: Any]]) -> Bool {
        var posesByName: [String: Data] = [:]
        var mediaByName: [String: String] = [:]
        for raw in rawExercises {
            guard let name = raw["name"] as? String else { continue }
            if let posesRaw = raw["poses"],
               let poseData = try? JSONSerialization.data(withJSONObject: posesRaw) {
                posesByName[name] = poseData
            }
            if let media = raw["mediaURL"] as? String, !media.isEmpty {
                mediaByName[name] = media
            }
        }

        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in existing {
            if exercise.posesData.isEmpty, let poseData = posesByName[exercise.name] {
                exercise.posesData = poseData
                changed = true
            }
            // Only fill in a video when the exercise doesn't already have one,
            // so we never clobber a link the user added themselves.
            if (exercise.mediaURL ?? "").isEmpty, let media = mediaByName[exercise.name] {
                exercise.mediaURL = media
                changed = true
            }
        }
        return changed
    }

    /// v4 — migrates the exercise vocabulary from the old coarse body-map
    /// regions (e.g. "Left Leg", "Upper Back") to the full `MuscleGroup` set
    /// (e.g. "Left Quadriceps", "Left Trapezius"/"Right Trapezius"), and adds
    /// the new stretches needed for full muscle-group coverage.
    ///
    /// Matches rows to seed entries by the stable `seedID` first, falling
    /// back to `name` only for rows seeded before `Exercise.seedID` existed.
    /// Once matched, `seedID` is backfilled — so renaming an exercise in the
    /// bundle seed can never again orphan the user's row (which used to
    /// leave the old row un-migrated and insert an unwanted duplicate).
    @discardableResult
    static func migrateV4(context: ModelContext, rawExercises: [[String: Any]]) -> Bool {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []

        var existingBySeedID: [String: Exercise] = [:]
        var existingByName: [String: Exercise] = [:]
        for exercise in existing {
            if let seedID = exercise.seedID {
                existingBySeedID[seedID] = exercise
            } else {
                existingByName[exercise.name] = exercise
            }
        }

        var changed = false

        for raw in rawExercises {
            guard
                let name         = raw["name"] as? String,
                let typeStr      = raw["type"] as? String,
                let type         = ExerciseType(rawValue: typeStr.capitalized),
                let parts        = raw["targetBodyParts"] as? [String],
                let duration     = raw["durationSeconds"] as? Int,
                let difficulty   = raw["difficulty"] as? Int,
                let instructions = raw["instructions"] as? [String]
            else { continue }

            let seedID = raw["id"] as? String
            let match = seedID.flatMap { existingBySeedID[$0] } ?? existingByName[name]

            if let exercise = match {
                // Already-seeded exercise the user has — adopt the bundle's
                // re-authored targets verbatim so upgrading users get the
                // same anatomically-correct groups as fresh installs (a
                // plain MuscleGroup.migrate of e.g. "Left Leg" would land
                // hamstring stretches on Quadriceps).
                if exercise.targetBodyParts != parts {
                    exercise.targetBodyParts = parts
                    changed = true
                }
                if let seedID, exercise.seedID != seedID {
                    exercise.seedID = seedID
                    changed = true
                }
            } else {
                // Brand-new in v4 — insert it as-is.
                let exercise = Exercise(
                    name: name, type: type, targetBodyParts: parts,
                    durationSeconds: duration, difficulty: difficulty,
                    instructions: instructions,
                    mediaURL: raw["mediaURL"] as? String,
                    caution: raw["caution"] as? String,
                    isBilateral: raw["isBilateral"] as? Bool ?? true
                )
                exercise.seedID = seedID
                exercise.localVideoName = raw["localVideoName"] as? String
                context.insert(exercise)
                if let seedID { existingBySeedID[seedID] = exercise }
                existingByName[name] = exercise
                changed = true
            }
        }

        // User-created exercises (anything not seeded from the bundle) keep
        // their own content but still need old region names mapped forward;
        // unrecognized/custom entries pass through unchanged.
        let seedIDs = Set(rawExercises.compactMap { $0["id"] as? String })
        let seedNames = Set(rawExercises.compactMap { $0["name"] as? String })
        for exercise in existing {
            let isSeeded = (exercise.seedID.map { seedIDs.contains($0) } ?? false) || seedNames.contains(exercise.name)
            guard !isSeeded else { continue }
            let migrated = MuscleGroup.migrate(exercise.targetBodyParts)
            if migrated != exercise.targetBodyParts {
                exercise.targetBodyParts = migrated
                changed = true
            }
        }

        // Body-map marks saved from the old region set need the same
        // one-time vocabulary migration.
        let defaults = UserDefaults.standard
        if let markedRegions = defaults.stringArray(forKey: "bodymap.markedRegions") {
            let migratedRegions = MuscleGroup.migrate(markedRegions)
            if migratedRegions != markedRegions {
                defaults.set(migratedRegions, forKey: "bodymap.markedRegions")
            }
        }

        return changed
    }

    /// v5 — backfills the `isBilateral` flag onto already-seeded exercises so
    /// upgrading users get the same "switch sides" cues as fresh installs. New
    /// installs already read `isBilateral` at seed time, so this only matters
    /// for users seeded before the flag existed (all such rows defaulted to
    /// true). We only ever flip a bundle-seeded exercise to `false`; we never
    /// touch user-created exercises (default stays true).
    @discardableResult
    static func migrateV5(context: ModelContext, rawExercises: [[String: Any]]) -> Bool {
        // Only the exercises the bundle explicitly marks unilateral.
        var unilateralNames: Set<String> = []
        for raw in rawExercises {
            guard let name = raw["name"] as? String else { continue }
            if (raw["isBilateral"] as? Bool) == false {
                unilateralNames.insert(name)
            }
        }

        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in existing where unilateralNames.contains(exercise.name) {
            if exercise.isBilateral {
                exercise.isBilateral = false
                changed = true
            }
        }
        return changed
    }

    /// v6 — backfills `Exercise.seedID` for rows that were seeded before that
    /// field existed (matched by name, the last time name-matching is ever
    /// used for these rows). From here on, renaming an exercise in the
    /// bundled seed can no longer orphan or duplicate an installed user's row.
    @discardableResult
    static func migrateV6(context: ModelContext, rawExercises: [[String: Any]]) -> Bool {
        var seedIDByName: [String: String] = [:]
        for raw in rawExercises {
            guard let name = raw["name"] as? String, let id = raw["id"] as? String else { continue }
            seedIDByName[name] = id
        }

        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in existing where exercise.seedID == nil {
            if let id = seedIDByName[exercise.name] {
                exercise.seedID = id
                changed = true
            }
        }
        return changed
    }
}
