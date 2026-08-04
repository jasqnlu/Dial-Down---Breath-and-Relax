import Testing
@testable import BreathRelaxStretch

struct ExerciseGraphGroupingTests {
    @Test func groupsExercisesBySpecificBodyPartWithinCategory() {
        let exercises = [
            makeExercise(name: "Left quad opener", targetBodyParts: ["Left Quadriceps"], difficulty: 1),
            makeExercise(name: "Right quad opener", targetBodyParts: ["Right Quadriceps"], difficulty: 1),
            makeExercise(name: "Calf stretch", targetBodyParts: ["Left Calves"], difficulty: 2)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .legs)

        #expect(groups.map(\.title).contains("Quadriceps"))
        #expect(groups.map(\.title).contains("Calves"))
        #expect(groups.first { $0.title == "Quadriceps" }?.exercises.count == 2)
    }

    /// Head sub-zone tags ("Left Temple", "Forehead") must resolve to the
    /// Neck category node the same way `RegionExerciseResolver` resolves them
    /// for the Body Map — otherwise these exercises never appear anywhere in
    /// the Exercises tab's pinch-zoom graph.
    @Test func headSubZoneExercisesResolveToNeckCategory() {
        let exercises = [
            makeExercise(name: "Temporalis Release", targetBodyParts: ["Left Temple", "Right Temple"], difficulty: 1),
            makeExercise(name: "Brow & Forehead Smoother", targetBodyParts: ["Forehead"], difficulty: 1)
        ]

        #expect(ExerciseCategory.categories(for: exercises[0].targetBodyParts) == [.neck])
        #expect(ExerciseCategory.categories(for: exercises[1].targetBodyParts) == [.neck])

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .neck)
        #expect(groups.flatMap(\.exercises).map(\.name).sorted() ==
                ["Brow & Forehead Smoother", "Temporalis Release"])
    }

    @Test func fallsBackToDifficultyWhenBodyPartDoesNotMatchCategory() {
        let exercises = [
            makeExercise(name: "Starter stretch", targetBodyParts: [], difficulty: 1),
            makeExercise(name: "Deep stretch", targetBodyParts: [], difficulty: 3)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .legs)

        #expect(groups.map(\.title).contains("Beginner"))
        #expect(groups.map(\.title).contains("Advanced"))
    }

    @Test func chestGroupsUseMajorMinorAndGeneralSubcategories() {
        let exercises = [
            makeExercise(name: "High Doorway Chest Stretch (Upper Chest)", targetBodyParts: ["Left Chest", "Right Chest"], difficulty: 2),
            makeExercise(name: "Pec Minor Corner Stretch", targetBodyParts: ["Left Chest"], difficulty: 2),
            makeExercise(name: "Deep Belly Breath", targetBodyParts: ["Left Chest", "Right Chest"], difficulty: 1)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .chest)

        #expect(groups.map(\.title).contains("Pectoralis Major"))
        #expect(groups.map(\.title).contains("Pectoralis Minor"))
        #expect(groups.map(\.title).contains("General Chest"))
    }

    @Test func generalChestGroupKeepsChestTargetedExercisesThatDoNotSayChestOrPec() {
        let exercises = [
            makeExercise(name: "Reverse Prayer Shoulder Mobiliser", targetBodyParts: ["Left Shoulder", "Right Shoulder", "Left Chest", "Right Chest"], difficulty: 2),
            makeExercise(name: "Left Doorway Bicep Stretch", targetBodyParts: ["Left Biceps", "Left Chest"], difficulty: 1)
        ]

        let groups = ExerciseGraphGrouping.groups(for: exercises, in: .chest)
        let generalChest = groups.first { $0.title == "General Chest" }

        #expect(generalChest?.exercises.map(\.name).sorted() == [
            "Left Doorway Bicep Stretch",
            "Reverse Prayer Shoulder Mobiliser"
        ])
    }

    private func makeExercise(name: String, targetBodyParts: [String], difficulty: Int) -> Exercise {
        Exercise(
            name: name,
            type: .stretch,
            targetBodyParts: targetBodyParts,
            durationSeconds: 60,
            difficulty: difficulty,
            instructions: []
        )
    }
}

// MARK: - Region → exercise resolution (task C)

struct RegionExerciseResolverTests {
    /// The regression: a coarse region name ("Core") must resolve to the fine
    /// muscle it maps to ("Left Abs"/"Right Abs") instead of matching nothing.
    @Test func coarseRegionResolvesToItsMuscleGroup() {
        let abs = makeExercise(name: "Ab Crunch", targetBodyParts: ["Left Abs", "Right Abs"])
        let oblique = makeExercise(name: "Oblique Twist", targetBodyParts: ["Left Obliques"])
        let bicep = makeExercise(name: "Bicep Stretch", targetBodyParts: ["Left Biceps"])

        let resolver = RegionExerciseResolver(regions: ["Core"], exercises: [abs, oblique, bicep])

        #expect(resolver.direct.map(\.name) == ["Ab Crunch"])
        // Same category (Core) but different muscle → related fallback.
        #expect(resolver.related.map(\.name) == ["Oblique Twist"])
        // Never the whole catalog: an arms exercise is excluded entirely.
        #expect(!(resolver.direct + resolver.related).contains { $0.name == "Bicep Stretch" })
    }

    /// When nothing targets the exact muscle, the same-category fallback still
    /// surfaces related exercises instead of an empty screen.
    @Test func fallsBackToSameCategoryWhenNoDirectMatch() {
        let forearm = makeExercise(name: "Forearm Stretch", targetBodyParts: ["Left Forearm"])
        let leg = makeExercise(name: "Quad Stretch", targetBodyParts: ["Left Quadriceps"])

        // "Left Arm" migrates to biceps/triceps — no exercise targets those,
        // but the forearm one shares the Arms category.
        let resolver = RegionExerciseResolver(regions: ["Left Arm"], exercises: [forearm, leg])

        #expect(resolver.direct.isEmpty)
        #expect(resolver.related.map(\.name) == ["Forearm Stretch"])
    }

    /// A sub-head shows its OWN tagged stretches as `direct` (distinct-per-head
    /// content), with the parent muscle's stretches as the `related` fallback.
    @Test func headResolvesToOwnExercisesThenParentFallback() {
        let headEx   = makeExercise(name: "Long-Head Overhead Stretch",
                                    targetBodyParts: ["Left Triceps Long Head"])
        let parentEx = makeExercise(name: "Triceps Wall Press",
                                    targetBodyParts: ["Left Triceps"])
        let other    = makeExercise(name: "Quad Stretch",
                                    targetBodyParts: ["Left Quadriceps"])

        let resolver = RegionExerciseResolver(regions: ["Left Triceps Long Head"],
                                              exercises: [headEx, parentEx, other])

        #expect(resolver.direct.map(\.name) == ["Long-Head Overhead Stretch"])
        #expect(resolver.related.map(\.name) == ["Triceps Wall Press"])
        #expect(!(resolver.direct + resolver.related).contains { $0.name == "Quad Stretch" })
    }

    /// A head with no curated content of its own gracefully falls back to the
    /// parent muscle's list rather than showing nothing.
    @Test func headWithoutOwnExercisesFallsBackToParent() {
        let parentEx = makeExercise(name: "Triceps Wall Press",
                                    targetBodyParts: ["Left Triceps"])
        let resolver = RegionExerciseResolver(regions: ["Left Triceps Medial Head"],
                                              exercises: [parentEx])

        #expect(resolver.direct.isEmpty)
        #expect(resolver.related.map(\.name) == ["Triceps Wall Press"])
    }

    /// A joint region shows its OWN tagged exercises as `direct` (dedicated
    /// joint-mobility content), falling back to the crossing muscles'
    /// stretches as `related`.
    @Test func jointResolvesToOwnExercisesThenCrossingMuscleFallback() {
        let jointEx  = makeExercise(name: "Standing Hip Circles",
                                    targetBodyParts: ["Left Hip Flexors", "Left Adductors", "Left Hip"])
        let crossing = makeExercise(name: "Glute Stretch",
                                    targetBodyParts: ["Left Glutes"])
        // "Left Hip" crosses into both .hipsGlutes (glutes/hip flexors/adductors)
        // and .legs (hamstrings), so pick an unrelated exercise outside both.
        let other    = makeExercise(name: "Bicep Stretch",
                                    targetBodyParts: ["Left Biceps"])

        let resolver = RegionExerciseResolver(regions: ["Left Hip"],
                                              exercises: [jointEx, crossing, other])

        #expect(resolver.direct.map(\.name) == ["Standing Hip Circles"])
        #expect(resolver.related.map(\.name) == ["Glute Stretch"])
        #expect(!(resolver.direct + resolver.related).contains { $0.name == "Bicep Stretch" })
    }

    /// A joint with no curated content of its own gracefully falls back to
    /// its crossing muscles' stretches rather than showing nothing.
    @Test func jointWithoutOwnExercisesFallsBackToCrossingMuscles() {
        let crossing = makeExercise(name: "Glute Stretch", targetBodyParts: ["Left Glutes"])
        let resolver = RegionExerciseResolver(regions: ["Left Hip"], exercises: [crossing])

        #expect(resolver.direct.isEmpty)
        #expect(resolver.related.map(\.name) == ["Glute Stretch"])
    }

    /// A breathing-type exercise must never surface on the Body Map, even if
    /// (due to a seed-data mistake) its `targetBodyParts` directly names the
    /// tapped region or shares its category — regression for the bug where
    /// "Progressive Relaxation Breath" leaked into Core/Legs regions.
    @Test func excludesBreathTypeExercisesEvenWhenTargetBodyPartsMatch() {
        let breathEx = makeExercise(name: "Progressive Relaxation Breath",
                                    targetBodyParts: ["Left Abs", "Left Quadriceps"],
                                    type: .breath)
        let stretchEx = makeExercise(name: "Ab Crunch", targetBodyParts: ["Left Abs"])

        let resolver = RegionExerciseResolver(regions: ["Left Abs"], exercises: [breathEx, stretchEx])

        #expect(resolver.direct.map(\.name) == ["Ab Crunch"])
        #expect(!(resolver.direct + resolver.related).contains { $0.name == "Progressive Relaxation Breath" })

        // Also check the same-category fallback path (a different region,
        // same category, no direct match on either exercise).
        let resolverFallback = RegionExerciseResolver(regions: ["Left Obliques"], exercises: [breathEx])
        #expect(resolverFallback.isEmpty)
    }

    private func makeExercise(name: String, targetBodyParts: [String], type: ExerciseType = .stretch) -> Exercise {
        Exercise(name: name, type: type, targetBodyParts: targetBodyParts,
                 durationSeconds: 60, difficulty: 1, instructions: [])
    }
}

// MARK: - Focus-area recommendations (task A)

struct FocusAreaRecommendationTests {
    @Test func parsesStoredAreas() {
        #expect(ExerciseCategory.areas(from: "Chest,Legs") == [.chest, .legs])
        #expect(ExerciseCategory.areas(from: "") == [])
    }

    @Test func recommendsOnlyFromChosenAreasTaggedWithCategory() {
        let chest = makeExercise(name: "Chest Opener", targetBodyParts: ["Left Chest"])
        let leg = makeExercise(name: "Quad Stretch", targetBodyParts: ["Left Quadriceps"])
        let arm = makeExercise(name: "Bicep Stretch", targetBodyParts: ["Left Biceps"])

        let recs = ExerciseCategory.recommendedExercises(
            from: [chest, leg, arm], areas: [.chest, .legs], limit: 10)

        #expect(recs.count == 2)
        #expect(recs.contains { $0.exercise.name == "Chest Opener" && $0.category == .chest })
        #expect(recs.contains { $0.exercise.name == "Quad Stretch" && $0.category == .legs })
        #expect(!recs.contains { $0.exercise.name == "Bicep Stretch" })
    }

    @Test func emptyAreasFallBackToEveryCategory() {
        let chest = makeExercise(name: "Chest Opener", targetBodyParts: ["Left Chest"])
        let arm = makeExercise(name: "Bicep Stretch", targetBodyParts: ["Left Biceps"])

        let recs = ExerciseCategory.recommendedExercises(
            from: [chest, arm], areas: [], limit: 10)

        #expect(recs.count == 2)
    }

    private func makeExercise(name: String, targetBodyParts: [String]) -> Exercise {
        Exercise(name: name, type: .stretch, targetBodyParts: targetBodyParts,
                 durationSeconds: 60, difficulty: 1, instructions: [])
    }
}
