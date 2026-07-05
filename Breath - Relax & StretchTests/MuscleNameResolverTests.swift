import Testing
@testable import BreathRelaxStretch

struct MuscleNameResolverTests {
    @Test(arguments: [
        ("Biceps brachii.l", Float(0),  MuscleGroup.leftBiceps),
        ("Rectus femoris.r", Float(0),  MuscleGroup.rightQuads),
        ("Vastus lateralis_L", Float(0), MuscleGroup.leftQuads),
        ("Gastrocnemius.001.r", Float(0), MuscleGroup.rightCalves),
        ("Trapezius", Float(0.2),        MuscleGroup.leftTraps),   // side from localX
        ("Rectus abdominis", Float(0),   MuscleGroup.abs),
        ("Gluteus maximus.l", Float(0),  MuscleGroup.leftGlutes),
        ("Erector spinae", Float(0),     MuscleGroup.spinalErectors),
        ("Sternocleidomastoideus.r", Float(0), MuscleGroup.neckFront),
    ]) func resolvesKnownNames(name: String, x: Float, expected: MuscleGroup) {
        #expect(MuscleNameResolver.group(forNodeName: name, localX: x) == expected)
    }

    @Test func unknownNameReturnsNil() {
        #expect(MuscleNameResolver.group(forNodeName: "AnatomyExport", localX: 0) == nil)
    }

    @Test func fallbackByPosition() {
        // Unit-space: y in 0(feet)…1(head), x negative = screen-left.
        #expect(MuscleNameResolver.fallbackGroup(unitPoint: .init(-0.2, 0.97, 0)) == .head)
        #expect(MuscleNameResolver.fallbackGroup(unitPoint: .init(-0.4, 0.45, 0)) == .leftHand)
        #expect(MuscleNameResolver.fallbackGroup(unitPoint: .init(0.2, 0.02, 0)) == .rightFoot)
    }
}
