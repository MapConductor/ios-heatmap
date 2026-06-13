/// Adds a batch of heatmap points to a HeatmapOverlay in a single update.
/// This is the recommended API for large datasets.
public struct HeatmapPoints: HeatmapContentItemProtocol {
    private let states: [HeatmapPointState]

    public init(_ states: [HeatmapPointState]) {
        self.states = states
    }

    public func append(to content: inout HeatmapViewContent) {
        content.pointStates.append(contentsOf: states)
    }
}
