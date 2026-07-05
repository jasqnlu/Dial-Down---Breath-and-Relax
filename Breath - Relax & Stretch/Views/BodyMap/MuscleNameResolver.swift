import Foundation
import simd

/// Maps Z-Anatomy node names (and, failing that, positions) to MuscleGroups.
enum MuscleNameResolver {

    /// Substring (lowercased) → the left/right pair (or single) group.
    /// Order matters: first match wins, so more specific entries go first.
    private static let table: [(key: String, left: MuscleGroup, right: MuscleGroup)] = [
        ("sternocleido", .neckFront, .neckFront),
        ("scalen",       .neckFront, .neckFront),
        ("splenius",     .neckBack,  .neckBack),
        ("levator scapul", .neckBack, .neckBack),
        ("trapezius",    .leftTraps, .rightTraps),
        ("deltoid",      .leftDelts, .rightDelts),
        ("pectoralis",   .leftChest, .rightChest),
        ("rectus abdominis", .abs, .abs),
        ("obliqu",       .leftObliques, .rightObliques),
        ("latissimus",   .leftLats, .rightLats),
        ("rhomboid",     .leftTraps, .rightTraps),
        ("erector",      .spinalErectors, .spinalErectors),
        ("iliocostalis", .spinalErectors, .spinalErectors),
        ("longissimus",  .spinalErectors, .spinalErectors),
        ("multifidus",   .lowerBack, .lowerBack),
        ("quadratus lumborum", .lowerBack, .lowerBack),
        ("biceps brachii", .leftBiceps, .rightBiceps),
        ("brachialis",   .leftBiceps, .rightBiceps),
        ("triceps",      .leftTriceps, .rightTriceps),
        ("brachioradialis", .leftForearm, .rightForearm),
        ("carpi",        .leftForearm, .rightForearm),
        ("digitorum",    .leftForearm, .rightForearm),   // superficialis/profundus etc.
        ("pronator",     .leftForearm, .rightForearm),
        ("supinator",    .leftForearm, .rightForearm),
        ("gluteus",      .leftGlutes, .rightGlutes),
        ("piriformis",   .leftGlutes, .rightGlutes),
        ("iliopsoas",    .leftHipFlexors, .rightHipFlexors),
        ("psoas",        .leftHipFlexors, .rightHipFlexors),
        ("iliacus",      .leftHipFlexors, .rightHipFlexors),
        ("sartorius",    .leftHipFlexors, .rightHipFlexors),
        ("tensor fascia", .leftHipFlexors, .rightHipFlexors),
        ("adductor",     .leftAdductors, .rightAdductors),
        ("gracilis",     .leftAdductors, .rightAdductors),
        ("pectineus",    .leftAdductors, .rightAdductors),
        ("rectus femoris", .leftQuads, .rightQuads),
        ("vastus",       .leftQuads, .rightQuads),
        ("biceps femoris", .leftHamstrings, .rightHamstrings),
        ("semitendinosus", .leftHamstrings, .rightHamstrings),
        ("semimembranosus", .leftHamstrings, .rightHamstrings),
        ("gastrocnemius", .leftCalves, .rightCalves),
        ("soleus",       .leftCalves, .rightCalves),
        ("tibialis anterior", .leftTibialis, .rightTibialis),
        ("peroneus",     .leftTibialis, .rightTibialis),
        ("fibularis",    .leftTibialis, .rightTibialis),
        ("tibialis",     .leftCalves, .rightCalves),      // posterior — after anterior
    ]

    static func group(forNodeName raw: String, localX: Float) -> MuscleGroup? {
        let name = raw.lowercased()
        // Suffix side markers: ".l"/"_l"/" l" (and .r variants), tolerant of ".001" counters.
        let cleaned = name.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        let side: Character? = {
            if cleaned.hasSuffix(".l") || cleaned.hasSuffix("_l") || cleaned.hasSuffix(" l") { return "l" }
            if cleaned.hasSuffix(".r") || cleaned.hasSuffix("_r") || cleaned.hasSuffix(" r") { return "r" }
            return nil
        }()
        guard let entry = table.first(where: { cleaned.contains($0.key) }) else { return nil }
        if entry.left == entry.right { return entry.left }
        // NOTE (provisional convention — Task 3 Step 4 verifies empirically against
        // the mesh; adjust here if flipped): Z-Anatomy ".l" is anatomical left,
        // which reads as screen-RIGHT at front facing, but our vocabulary is
        // screen-relative (matches old region names). Provisionally we map the
        // suffix straight through (".l" → left group), and take model +X =
        // screen-left at front facing → left group when no suffix is present.
        switch side {
        case "l": return entry.left
        case "r": return entry.right
        default:  return localX > 0 ? entry.left : entry.right
        }
    }

    /// Position fallback in unit space (x −0.5…0.5 screen-left→right at front,
    /// y 0 feet … 1 head). Used when a stroke hits skin but no named muscle.
    static func fallbackGroup(unitPoint p: SIMD3<Float>) -> MuscleGroup {
        if p.y > 0.87 { return .head }
        if p.y < 0.08 { return p.x < 0 ? .leftFoot : .rightFoot }
        if abs(p.x) > 0.28 && (0.30...0.55).contains(p.y) {
            return p.x < 0 ? .leftHand : .rightHand
        }
        // Torso/limb miss with a merged OBJ: nearest coarse group by height.
        switch p.y {
        case ..<0.30:  return p.x < 0 ? .leftCalves : .rightCalves
        case ..<0.50:  return p.x < 0 ? .leftQuads : .rightQuads
        case ..<0.62:  return .abs
        case ..<0.80:  return p.x < 0 ? .leftChest : .rightChest
        default:       return p.x < 0 ? .leftDelts : .rightDelts
        }
    }
}
