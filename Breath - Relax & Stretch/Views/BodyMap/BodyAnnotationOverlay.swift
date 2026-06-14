import SwiftUI
import Combine

// MARK: - Drawing tool

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen        = "pencil"
    case highlighter = "highlighter"
    case eraser     = "eraser"

    var id: String { rawValue }
    var icon: String { rawValue }

    var label: String {
        switch self {
        case .pen:         return "Pen"
        case .highlighter: return "Highlighter"
        case .eraser:      return "Eraser"
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .pen:         return 3
        case .highlighter: return 22
        case .eraser:      return 28
        }
    }

    var opacity: Double {
        switch self {
        case .pen:         return 1.0
        case .highlighter: return 0.38
        case .eraser:      return 1.0
        }
    }
}

// MARK: - Sensation colour palette

struct SensationColor: Identifiable, Equatable {
    let id: String
    let color: Color
    let label: String
    let icon: String
}

let sensationColors: [SensationColor] = [
    SensationColor(id: "pain",     color: .red,    label: "Pain",     icon: "bolt.fill"),
    SensationColor(id: "tension",  color: .orange, label: "Tension",  icon: "arrow.up.and.down"),
    SensationColor(id: "stress",   color: .yellow, label: "Stress",   icon: "exclamationmark.triangle.fill"),
    SensationColor(id: "numb",     color: .blue,   label: "Numbness", icon: "snowflake"),
    SensationColor(id: "fatigue",  color: .purple, label: "Fatigue",  icon: "moon.fill"),
]

// MARK: - Stroke model (Codable for persistence)

struct AnnotationStroke: Codable, Identifiable {
    let id: UUID
    var points: [StoredPoint]
    var colorID: String          // matches SensationColor.id, or "eraser"
    var lineWidth: Double
    var opacity: Double
    var facing: String?          // "Front" / "Back"; nil = legacy front-view stroke

    init(points: [CGPoint], colorID: String, lineWidth: CGFloat, opacity: Double, facing: String? = nil) {
        self.id        = UUID()
        self.points    = points.map { StoredPoint(x: $0.x, y: $0.y) }
        self.colorID   = colorID
        self.lineWidth = lineWidth
        self.opacity   = opacity
        self.facing    = facing
    }

    struct StoredPoint: Codable {
        let x, y: Double
        var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    }

    var cgPoints: [CGPoint] { points.map(\.cgPoint) }

    func color(for id: String) -> Color {
        sensationColors.first { $0.id == id }?.color ?? .red
    }

    /// Build a smooth quadratic bezier path through the points
    var smoothPath: Path {
        Path.smooth(through: cgPoints)
    }
}

extension Path {
    static func smooth(through pts: [CGPoint]) -> Path {
        var path = Path()
        guard pts.count > 1 else {
            if let p = pts.first { path.addEllipse(in: CGRect(x: p.x-1, y: p.y-1, width: 2, height: 2)) }
            return path
        }
        path.move(to: pts[0])
        for i in 1..<pts.count - 1 {
            let mid = CGPoint(x: (pts[i].x + pts[i+1].x) / 2,
                              y: (pts[i].y + pts[i+1].y) / 2)
            path.addQuadCurve(to: mid, control: pts[i])
        }
        path.addLine(to: pts[pts.count - 1])
        return path
    }
}

// MARK: - Persistence

final class AnnotationStore: ObservableObject {
    @Published var strokes: [AnnotationStroke] = []

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("body_annotations.json")
    }()

    init() { load() }

    func save() {
        if let data = try? JSONEncoder().encode(strokes) {
            try? data.write(to: saveURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([AnnotationStroke].self, from: data)
        else { return }
        strokes = decoded
    }

    func undo() {
        if !strokes.isEmpty { strokes.removeLast() }
        save()
    }

    func clear() {
        strokes.removeAll()
        save()
    }
}

// MARK: - Main annotation overlay

struct BodyAnnotationOverlay: View {
    @StateObject private var store = AnnotationStore()

    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: SensationColor = sensationColors[0]
    @State private var currentPoints: [CGPoint] = []
    @State private var showLegend = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar — top
            annotationToolbar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)

            // Drawing canvas
            ZStack {
                // Saved strokes — drawn in an isolated layer so eraser
                // uses .destinationOut to genuinely remove pixels instead of
                // painting over them with a background colour.
                Canvas { ctx, size in
                    ctx.drawLayer { layerCtx in
                        for stroke in store.strokes {
                            drawStroke(stroke, in: &layerCtx)
                        }
                    }
                }
                .allowsHitTesting(false)

                // Live stroke being drawn
                Canvas { ctx, size in
                    if !currentPoints.isEmpty {
                        let path = Path.smooth(through: currentPoints)
                        let style = StrokeStyle(lineWidth: selectedTool.lineWidth,
                                               lineCap: .round, lineJoin: .round)
                        if selectedTool == .eraser {
                            // Show a semi-transparent white ring as live preview
                            ctx.stroke(path,
                                       with: .color(.white.opacity(0.55)),
                                       style: style)
                        } else {
                            ctx.stroke(path,
                                       with: .color(selectedColor.color.opacity(selectedTool.opacity)),
                                       style: style)
                        }
                    }
                }
                .allowsHitTesting(false)

                // Invisible drag surface
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { val in
                                currentPoints.append(val.location)
                            }
                            .onEnded { _ in
                                guard !currentPoints.isEmpty else { return }
                                let stroke = AnnotationStroke(
                                    points:    currentPoints,
                                    colorID:   selectedTool == .eraser ? "eraser" : selectedColor.id,
                                    lineWidth: selectedTool.lineWidth,
                                    opacity:   selectedTool.opacity
                                )
                                store.strokes.append(stroke)
                                store.save()
                                currentPoints = []
                            }
                    )
            }

            // Color palette — bottom
            colorPalette
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial)
        }
        .sheet(isPresented: $showLegend) { LegendSheet() }
    }

    // MARK: Toolbar

    private var annotationToolbar: some View {
        HStack(spacing: 12) {
            // Tools
            HStack(spacing: 0) {
                ForEach(DrawingTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        Image(systemName: tool.icon)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 40, height: 36)
                            .foregroundStyle(selectedTool == tool ? .white : .primary)
                            .background(selectedTool == tool ? Color.accentColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel(tool.label)
                }
            }
            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            // Undo
            Button {
                store.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Undo last stroke")
            .disabled(store.strokes.isEmpty)

            // Clear
            Button(role: .destructive) {
                withAnimation { store.clear() }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Clear all annotations")
            .disabled(store.strokes.isEmpty)

            // Legend
            Button {
                showLegend = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Show colour legend")
        }
    }

    // MARK: Color palette

    private var colorPalette: some View {
        HStack(spacing: 0) {
            ForEach(sensationColors) { sc in
                Button {
                    selectedColor = sc
                    if selectedTool == .eraser { selectedTool = .pen }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(sc.color)
                                .frame(width: 30, height: 30)
                            if selectedColor.id == sc.id && selectedTool != .eraser {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2.5)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        Text(sc.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(selectedColor.id == sc.id && selectedTool != .eraser
                                            ? sc.color : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("\(sc.label) colour")
            }
        }
    }

    // MARK: Canvas draw helper

    private func drawStroke(_ stroke: AnnotationStroke, in ctx: inout GraphicsContext) {
        let path  = stroke.smoothPath
        let style = StrokeStyle(lineWidth: stroke.lineWidth,
                                lineCap: .round, lineJoin: .round)
        if stroke.colorID == "eraser" {
            // destinationOut punches a transparent hole through the layer,
            // revealing the body map beneath — no background-colour dependency.
            ctx.blendMode = .destinationOut
            ctx.stroke(path, with: .color(.white), style: style)
            ctx.blendMode = .normal
        } else {
            let color = sensationColors.first { $0.id == stroke.colorID }?.color ?? .red
            ctx.stroke(path, with: .color(color.opacity(stroke.opacity)), style: style)
        }
    }
}

// MARK: - Legend sheet

struct LegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("What each colour means") {
                    ForEach(sensationColors) { sc in
                        HStack(spacing: 14) {
                            Image(systemName: sc.icon)
                                .foregroundStyle(sc.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sc.label)
                                    .font(.headline)
                                Text(legendDescription(for: sc.id))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Tools") {
                    ForEach(DrawingTool.allCases) { tool in
                        HStack(spacing: 14) {
                            Image(systemName: tool.icon)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.label)
                                    .font(.headline)
                                Text(toolDescription(for: tool))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Text("Your annotations are saved automatically and will be here next time you open the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Annotation Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func legendDescription(for id: String) -> String {
        switch id {
        case "pain":    return "Sharp, aching, or burning sensations"
        case "tension": return "Tight muscles, stiffness, or pressure"
        case "stress":  return "Areas that feel tense due to stress or anxiety"
        case "numb":    return "Numbness, tingling, or reduced sensation"
        case "fatigue": return "Fatigue, heaviness, or low energy in a region"
        default:        return ""
        }
    }

    private func toolDescription(for tool: DrawingTool) -> String {
        switch tool {
        case .pen:         return "Fine strokes — precise circling or pointing"
        case .highlighter: return "Wide, transparent strokes — cover a broad region"
        case .eraser:      return "Remove marks you don't need"
        }
    }
}

#Preview {
    BodyAnnotationOverlay()
        .frame(height: 600)
}
