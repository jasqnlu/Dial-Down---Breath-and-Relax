import Testing
@testable import BreathRelaxStretch

struct JointRegionTests {
    @Test func hasExactlySixRegions() {
        #expect(JointRegion.allCases.count == 6)
    }

    @Test func containsTheExpectedNames() {
        let expected: Set<String> = ["Neck", "Lower Spine",
            "Left Hip", "Right Hip", "Left Shoulder Joint", "Right Shoulder Joint"]
        #expect(JointRegion.allNames == expected)
    }

    @Test func doesNotCollideWithMuscleGroups() {
        let groups = Set(MuscleGroup.allCases.map(\.rawValue))
        #expect(JointRegion.allNames.isDisjoint(with: groups))
    }

    @Test func isJointRecognizesMembersAndRejectsOthers() {
        #expect(JointRegion.isJoint("Left Hip"))
        #expect(JointRegion.isJoint("Neck"))
        #expect(!JointRegion.isJoint("Left Elbow"))
        #expect(!JointRegion.isJoint("Nonsense"))
    }
}
