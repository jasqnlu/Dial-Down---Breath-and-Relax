import SwiftUI

struct BodyMapView: View {
    @State private var currentLayer: BodyLayer = .skin
    @State private var highlightedPart: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Layer", selection: $currentLayer) {
                    ForEach(BodyLayer.allCases, id: \.self) { layer in
                        Text(layer.rawValue).tag(layer)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // TODO: Replace BodyMapPlaceholder with real SVG body map (Phase 2)
                BodyMapPlaceholder(layer: currentLayer, highlightedPart: $highlightedPart)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let part = highlightedPart {
                    BodyPartInfoBanner(partName: part)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Body Map")
            .animation(.easeInOut(duration: 0.3), value: currentLayer)
            .animation(.easeInOut(duration: 0.2), value: highlightedPart)
        }
    }
}

// MARK: - Placeholder body map (grid of tappable regions)
// Replace this with a real SVG or SpriteKit body diagram in Phase 2

struct BodyMapPlaceholder: View {
    let layer: BodyLayer
    @Binding var highlightedPart: String?

    let regions = [
        "Head", "Neck", "Left Shoulder", "Right Shoulder",
        "Chest", "Left Arm", "Right Arm", "Core",
        "Upper Back", "Lower Back", "Left Leg", "Right Leg",
        "Left Foot", "Right Foot"
    ]

    var layerColor: Color {
        switch layer {
        case .skin:     return .orange
        case .muscle:   return .red
        case .skeleton: return .gray
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(regions, id: \.self) { region in
                    Button {
                        withAnimation {
                            highlightedPart = highlightedPart == region ? nil : region
                        }
                    } label: {
                        Text(region)
                            .font(.subheadline)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                highlightedPart == region
                                    ? layerColor.opacity(0.35)
                                    : Color(.secondarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        highlightedPart == region ? layerColor : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - Info banner shown when a body part is selected

struct BodyPartInfoBanner: View {
    let partName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(partName)
                .font(.headline)
            Text("Tap to find stretches targeting this area")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .shadow(color: .black.opacity(0.08), radius: 6, y: -2)
    }
}

#Preview {
    BodyMapView()
}
