import Foundation
import SwiftData

enum BodyLayer: String, Codable, CaseIterable {
    case skin = "Skin"
    case muscle = "Muscle"
    case skeleton = "Skeleton"
}

@Model
final class BodyPart {
    var id: UUID
    var name: String            // e.g. "Hamstring", "Quadricep"
    var layer: BodyLayer        // .skin, .muscle, .skeleton
    var group: String           // e.g. "Leg", "Back", "Arm"
    var svgPathID: String       // matches the SVG element ID for highlighting
    var connectedParts: [String]

    init(
        id: UUID = UUID(),
        name: String,
        layer: BodyLayer,
        group: String,
        svgPathID: String,
        connectedParts: [String] = []
    ) {
        self.id = id
        self.name = name
        self.layer = layer
        self.group = group
        self.svgPathID = svgPathID
        self.connectedParts = connectedParts
    }
}
