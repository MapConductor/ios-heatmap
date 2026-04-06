import SwiftUI

// Environment key for HeatmapPointCollector
private struct HeatmapPointCollectorKey: EnvironmentKey {
    static let defaultValue: HeatmapPointCollector? = nil
}

// Environment key for HeatmapOverlayState
private struct HeatmapOverlayStateKey: EnvironmentKey {
    static let defaultValue: HeatmapOverlayState? = nil
}

extension EnvironmentValues {
    var heatmapPointCollector: HeatmapPointCollector? {
        get { self[HeatmapPointCollectorKey.self] }
        set { self[HeatmapPointCollectorKey.self] = newValue }
    }

    var heatmapOverlayState: HeatmapOverlayState? {
        get { self[HeatmapOverlayStateKey.self] }
        set { self[HeatmapOverlayStateKey.self] = newValue }
    }
}
