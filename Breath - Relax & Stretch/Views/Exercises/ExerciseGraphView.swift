import SwiftUI

// MARK: - Exercise Graph View
//
// Pinch-zoom node graph: 8 category circles arranged on a ring; pinching in
// near one focuses it, fading in its exercises on a smaller ring around it.
// Mirrors the zoom/pan gesture pattern already used by BodyMapView.

struct ExerciseGraphView: View {
    let exercises: [Exercise]
    let typeFilter: ExerciseType?
    let onSelect: (Exercise) -> Void

    @State private var zoomScale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var focusedCategory: ExerciseCategory?

    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 3
    private let focusThreshold: CGFloat = 1.8
    private let categoryRadius: CGFloat = 0.62      // normalised distance from canvas center
    private let exerciseRingRadius: CGFloat = 0.30  // normalised distance from a focused category

    private var filteredExercises: [Exercise] {
        guard let typeFilter else { return exercises }
        return exercises.filter { $0.type == typeFilter }
    }

    private func exercises(in category: ExerciseCategory) -> [Exercise] {
        filteredExercises.filter { ExerciseCategory.categories(for: $0.targetBodyParts).contains(category) }
    }

    private var visibleCategories: [ExerciseCategory] {
        ExerciseCategory.allCases.filter { !exercises(in: $0).isEmpty }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let scale = min(size.width, size.height) / 2
            let categories = visibleCategories

            ZStack {
                ForEach(Array(categories.enumerated()), id: \.element) { pair in
                    categoryLayer(pair: pair, categories: categories, center: center, scale: scale)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .scaleEffect(zoomScale, anchor: .center)
            .offset(panOffset)
            .gesture(magnifyGesture(center: center, scale: scale))
            .simultaneousGesture(panGesture)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: focusedCategory)
        }
    }

    @ViewBuilder
    private func categoryLayer(pair: (offset: Int, element: ExerciseCategory),
                                categories: [ExerciseCategory],
                                center: CGPoint, scale: CGFloat) -> some View {
        let index = pair.offset
        let category = pair.element
        let normalized = GraphLayout.categoryPosition(index: index, count: categories.count)
        let isFocused = focusedCategory == category
        let isDimmed = focusedCategory != nil && !isFocused
        let categoryExercises = exercises(in: category)

        CategoryNode(category: category, count: categoryExercises.count, isFocused: isFocused)
            .position(x: center.x + normalized.x * scale * categoryRadius,
                      y: center.y + normalized.y * scale * categoryRadius)
            .opacity(isDimmed ? 0 : 1)
            .allowsHitTesting(!isDimmed)
            .onTapGesture { focus(on: category, index: index, categories: categories, center: center, scale: scale) }

        if isFocused {
            let categoryCenter = CGPoint(x: normalized.x * categoryRadius, y: normalized.y * categoryRadius)
            ForEach(Array(categoryExercises.enumerated()), id: \.element.uuid) { exPair in
                let exIndex = exPair.offset
                let exercise = exPair.element
                let exNormalized = GraphLayout.exercisePosition(
                    index: exIndex, count: categoryExercises.count,
                    around: categoryCenter, radius: exerciseRingRadius)
                ExerciseNode(exercise: exercise, color: category.accentColor)
                    .position(x: center.x + exNormalized.x * scale,
                              y: center.y + exNormalized.y * scale)
                    .transition(.opacity.combined(with: .scale(scale: 0.5)))
                    .onTapGesture { onSelect(exercise) }
            }
        }
    }

    // MARK: - Focus state

    private func focus(on category: ExerciseCategory, index: Int, categories: [ExerciseCategory],
                        center: CGPoint, scale: CGFloat) {
        let normalized = GraphLayout.categoryPosition(index: index, count: categories.count)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            focusedCategory = category
            zoomScale = focusThreshold
            lastScale = focusThreshold
            panOffset = CGSize(width: -normalized.x * scale * categoryRadius * (focusThreshold - 1),
                                height: -normalized.y * scale * categoryRadius * (focusThreshold - 1))
            lastPan = panOffset
        }
    }

    private func unfocus() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            focusedCategory = nil
            zoomScale = minZoom
            lastScale = minZoom
            panOffset = .zero
            lastPan = .zero
        }
    }

    // MARK: - Gestures

    private func magnifyGesture(center: CGPoint, scale: CGFloat) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(lastScale * value.magnification, minZoom), maxZoom)
                if zoomScale < focusThreshold, focusedCategory != nil {
                    focusedCategory = nil
                }
            }
            .onEnded { _ in
                lastScale = zoomScale
                let categories = visibleCategories
                if zoomScale < focusThreshold {
                    unfocus()
                } else if focusedCategory == nil,
                          let nearestIndex = nearestCategoryIndex(categories: categories, center: center, scale: scale) {
                    focus(on: categories[nearestIndex], index: nearestIndex, categories: categories,
                          center: center, scale: scale)
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                panOffset = CGSize(width: lastPan.width + value.translation.width,
                                    height: lastPan.height + value.translation.height)
            }
            .onEnded { _ in lastPan = panOffset }
    }

    /// Index of whichever visible category's node sits nearest the canvas
    /// center under the current pan/zoom — the category a pinch-in focuses.
    private func nearestCategoryIndex(categories: [ExerciseCategory], center: CGPoint, scale: CGFloat) -> Int? {
        guard !categories.isEmpty else { return nil }
        var bestIndex = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in categories.indices {
            let normalized = GraphLayout.categoryPosition(index: index, count: categories.count)
            let screenX = normalized.x * scale * categoryRadius * zoomScale + panOffset.width
            let screenY = normalized.y * scale * categoryRadius * zoomScale + panOffset.height
            let distance = (screenX * screenX + screenY * screenY).squareRoot()
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }
}

// MARK: - Category node

private struct CategoryNode: View {
    let category: ExerciseCategory
    let count: Int
    let isFocused: Bool

    private var diameter: CGFloat { isFocused ? 90 : 64 }

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(category.accentColor.opacity(0.85))
                .frame(width: diameter, height: diameter)
                .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1.5))
            Text(category.rawValue)
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurface)
            Text("\(count)")
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        .contentShape(Circle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(count) exercise\(count == 1 ? "" : "s")")
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Exercise node

private struct ExerciseNode: View {
    let exercise: Exercise
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.75))
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
            Text(exercise.name)
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurface)
                .lineLimit(1)
                .frame(maxWidth: 76)
        }
        .contentShape(Circle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(exercise.name)
    }
}

// MARK: - Preview

#Preview {
    ExerciseGraphView(exercises: [], typeFilter: nil, onSelect: { _ in })
        .background(Color.luminaSurface)
}
