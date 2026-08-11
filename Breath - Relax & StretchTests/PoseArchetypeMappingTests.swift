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

    @Test func mirrorFlagTracksRightInName() {
        #expect(PoseArchetypeMapping.resolve(name: "Left Seated Spinal Twist", type: .stretch).mirrored == false)
        #expect(PoseArchetypeMapping.resolve(name: "Right Seated Spinal Twist", type: .stretch).mirrored == true)
        #expect(PoseArchetypeMapping.resolve(name: "Cat-Cow Flow", type: .stretch).mirrored == false)
    }
}
