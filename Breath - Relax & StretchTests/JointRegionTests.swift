import Testing
@testable import BreathRelaxStretch

struct JointRegionTests {
    @Test func hasExactlyFifteenRegions() {
        #expect(JointRegion.allCases.count == 15)
    }

    @Test func containsTheExpectedNames() {
        let expected: Set<String> = [
            "Neck", "Upper Spine", "Lower Spine",
            "Left Shoulder Joint", "Right Shoulder Joint",
            "Left Elbow", "Right Elbow", "Left Wrist", "Right Wrist",
            "Left Hip", "Right Hip", "Left Knee", "Right Knee",
            "Left Ankle", "Right Ankle",
        ]
        #expect(JointRegion.allNames == expected)
    }

    @Test func doesNotCollideWithMuscleGroups() {
        let groups = Set(MuscleGroup.allCases.map(\.rawValue))
        #expect(JointRegion.allNames.isDisjoint(with: groups))
    }

    @Test func isJointRecognizesMembersAndRejectsOthers() {
        #expect(JointRegion.isJoint("Left Elbow"))
        #expect(JointRegion.isJoint("Neck"))
        #expect(!JointRegion.isJoint("Left Biceps"))
        #expect(!JointRegion.isJoint("Nonsense"))
    }
}
