import Testing
@testable import BreathRelaxStretch

struct PoseArchetypeMappingTests {
    @Test func breathTypeAlwaysResolvesToBreathSeated() {
        let result = PoseArchetypeMapping.resolve(name: "Box Breathing", type: .breath)
        #expect(result.id == .breathSeated)
    }

    @Test func seatedTwistKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Spinal Twist", type: .stretch).id == .seatedTwist)
        #expect(PoseArchetypeMapping.resolve(name: "Right Seated Spinal Twist", type: .stretch).id == .seatedTwist)
    }

    @Test func standingTwistKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Standing Reach-Through Twist", type: .stretch).id == .standingTwist)
    }

    @Test func childsPoseResolvesExactly() {
        #expect(PoseArchetypeMapping.resolve(name: "Child's Pose", type: .stretch).id == .childsPose)
    }

    @Test func standingForwardFoldKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Standing Hamstring Stretch", type: .stretch).id == .standingForwardFold)
        #expect(PoseArchetypeMapping.resolve(name: "Standing Forward Fold (Ragdoll)", type: .stretch).id == .standingForwardFold)
    }

    @Test func seatedForwardFoldKeywordsResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Hamstring Stretch", type: .stretch).id == .seatedForwardFold)
        #expect(PoseArchetypeMapping.resolve(name: "Seated Forward Fold", type: .stretch).id == .seatedForwardFold)
    }

    @Test func neckAndHeadMicroExercisesResolveToSeatedNeck() {
        #expect(PoseArchetypeMapping.resolve(name: "Seated Neck Rolls", type: .stretch).id == .seatedNeck)
        #expect(PoseArchetypeMapping.resolve(name: "Jaw-Open Temporalis Stretch", type: .stretch).id == .seatedNeck)
        #expect(PoseArchetypeMapping.resolve(name: "20-20-20 Focus Shift", type: .stretch).id == .seatedNeck)
    }

    @Test func manualOverridesResolveCorrectly() {
        #expect(PoseArchetypeMapping.resolve(name: "Downward-Facing Dog", type: .stretch).id == .quadruped)
        #expect(PoseArchetypeMapping.resolve(name: "Pigeon Pose (Left Leg Forward)", type: .stretch).id == .seatedFigureFour)
        #expect(PoseArchetypeMapping.resolve(name: "World's Greatest Stretch (Right Lead Leg)", type: .stretch).id == .standingTwist)
    }

    @Test func unmatchedNameFallsBackToStandingNeutral() {
        #expect(PoseArchetypeMapping.resolve(name: "Completely Made-Up Exercise Name", type: .stretch).id == .standingNeutral)
    }

    @Test func chinAndDiagonalNeckNamesResolveToSeatedNeck() {
        #expect(PoseArchetypeMapping.resolve(name: "Chin Tuck (Forward Head Reset)", type: .stretch).id == .seatedNeck)
        #expect(PoseArchetypeMapping.resolve(name: "Left Chin-to-Shoulder Diagonal Stretch", type: .stretch).id == .seatedNeck)
    }

    @Test func lyingDownNamesResolveToSupineNeutral() {
        // No supine-twist / supine-fold archetype exists, so these must fall
        // through to an honest lying-down figure rather than a seated one.
        #expect(PoseArchetypeMapping.resolve(name: "Left Supine Spinal Twist (Windshield Wipers)", type: .stretch).id == .supineNeutral)
        #expect(PoseArchetypeMapping.resolve(name: "Right Supine Hamstring Stretch with Towel", type: .stretch).id == .supineNeutral)
        #expect(PoseArchetypeMapping.resolve(name: "Left Reclined Quad Stretch with Strap", type: .stretch).id == .supineNeutral)
        #expect(PoseArchetypeMapping.resolve(name: "Left Side-Lying Quad Stretch", type: .stretch).id == .supineNeutral)
        #expect(PoseArchetypeMapping.resolve(name: "Legs Up the Wall", type: .stretch).id == .supineNeutral)
        #expect(PoseArchetypeMapping.resolve(name: "Pelvic Tilt", type: .stretch).id == .supineNeutral)
    }

    @Test func lyingDownCheckDoesNotSwallowMoreSpecificSupinePoses() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Single-Leg Supine Knee-to-Chest", type: .stretch).id == .supineKneeToChest)
        #expect(PoseArchetypeMapping.resolve(name: "Left Supine Figure-4 Stretch", type: .stretch).id == .seatedFigureFour)
    }

    @Test func numeralFigureFourNamesResolveLikeSpelledOutOnes() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Supine Figure-4 Stretch", type: .stretch).id == .seatedFigureFour)
        #expect(PoseArchetypeMapping.resolve(name: "Right Standing Figure-4 Stretch", type: .stretch).id == .seatedFigureFour)
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Figure-Four Stretch", type: .stretch).id == .seatedFigureFour)
    }

    @Test func resolvesThroughTheExerciseEntryPoint() {
        let exercise = Exercise(name: "Right Seated Spinal Twist", type: .stretch,
                                targetBodyParts: ["Spine"], durationSeconds: 30,
                                difficulty: 1, instructions: [])
        let result = PoseArchetypeMapping.resolve(for: exercise)
        #expect(result.id == .seatedTwist)
        #expect(result.mirrored == true)
    }

    @Test func mirrorFlagTracksRightInName() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Spinal Twist", type: .stretch).mirrored == false)
        #expect(PoseArchetypeMapping.resolve(name: "Right Seated Spinal Twist", type: .stretch).mirrored == true)
        #expect(PoseArchetypeMapping.resolve(name: "Cat-Cow Flow", type: .stretch).mirrored == false)
    }
}
