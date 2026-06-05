import Foundation

struct BodyHighlightService {

    /// Returns the set of body part names to highlight given a tapped part and current layer.
    /// Includes the selected part and all of its connected parts.
    static func highlightedParts(
        for selectedPart: String,
        in bodyParts: [BodyPart],
        layer: BodyLayer
    ) -> Set<String> {
        var result = Set<String>()
        result.insert(selectedPart)

        if let part = bodyParts.first(where: { $0.name == selectedPart && $0.layer == layer }) {
            result.formUnion(part.connectedParts)
        }

        return result
    }

    /// Returns exercises that target a given body part name.
    static func exercises(targeting partName: String, in exercises: [Exercise]) -> [Exercise] {
        exercises.filter { $0.targetBodyParts.contains(partName) }
    }

    /// Returns all body parts belonging to a group (e.g. "Leg") in a given layer.
    static func parts(inGroup group: String, layer: BodyLayer, from bodyParts: [BodyPart]) -> [BodyPart] {
        bodyParts.filter { $0.group == group && $0.layer == layer }
    }
}
