import Foundation
import SwiftData

enum BodyLayer: String, Codable, CaseIterable {
    case skin = "Skin"
    case muscle = "Muscle"
    case skeleton = "Skeleton"
}

@Model
final class BodyPart {
    // Inline defaults on every stored property keep the model CloudKit-compatible
    // (CloudKit requires all attributes optional or defaulted).
    var uuid: UUID = UUID()
    var name: String = ""            // e.g. "Hamstring", "Quadricep"
    var layer: BodyLayer = BodyLayer.skin
    var group: String = ""           // e.g. "Leg", "Back", "Arm"
    var svgPathID: String = ""       // matches the SVG element ID for highlighting
    var connectedParts: [String] = []

    init(
        uuid: UUID = UUID(),
        name: String,
        layer: BodyLayer,
        group: String,
        svgPathID: String,
        connectedParts: [String] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.layer = layer
        self.group = group
        self.svgPathID = svgPathID
        self.connectedParts = connectedParts
    }
}
