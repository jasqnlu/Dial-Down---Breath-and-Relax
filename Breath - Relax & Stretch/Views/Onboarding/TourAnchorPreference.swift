import SwiftUI

struct TourAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Tags this view as a coach-mark target. `TourSpotlightOverlay` looks
    /// up the reported frame by `id` to know where to cut the spotlight and
    /// place the tooltip.
    func tourAnchor(_ id: String) -> some View {
        anchorPreference(key: TourAnchorPreferenceKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }
}
