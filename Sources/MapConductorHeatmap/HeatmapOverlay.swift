import MapConductorCore
import SwiftUI

public struct HeatmapOverlay<Content: View>: ViewBasedMapOverlay, Identifiable {
    public let id: String

    private let overlayState: HeatmapOverlayState
    private let content: Content

    public init(
        _ state: HeatmapOverlayState,
        @ViewBuilder content: () -> Content
    ) {
        self.overlayState = state
        self.content = content()
        self.id = state.rasterLayerState.id
    }

    public init(
        state: HeatmapOverlayState,
        @ViewBuilder content: () -> Content
    ) {
        self.init(state, content: content)
    }

    public init(
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider,
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        trackPointUpdates: Bool = false,
        disableTileServerCache: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        let state = HeatmapOverlayState(
            tileSize: tileSize,
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            weightProvider: weightProvider,
            trackPointUpdates: trackPointUpdates,
            disableTileServerCache: disableTileServerCache
        )
        self.init(state, content: content)
    }

    public var body: some View {
        content
            .environment(\.heatmapPointCollector, overlayState.pointCollector)
            .environment(\.heatmapOverlayState, overlayState)
    }

    public func append(to content: inout MapViewContent) {
        content.rasterLayers.append(RasterLayer(state: overlayState.rasterLayerState))
    }
}

public extension HeatmapOverlay where Content == EmptyView {
    init(
        _ state: HeatmapOverlayState
    ) {
        self.init(state) {
            EmptyView()
        }
    }

    init(
        state: HeatmapOverlayState
    ) {
        self.init(state) {
            EmptyView()
        }
    }

    init(
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider,
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        trackPointUpdates: Bool = false,
        disableTileServerCache: Bool = false
    ) {
        self.init(
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            weightProvider: weightProvider,
            tileSize: tileSize,
            trackPointUpdates: trackPointUpdates,
            disableTileServerCache: disableTileServerCache
        ) {
            EmptyView()
        }
    }
}

@available(*, deprecated, renamed: "HeatmapOverlay")
public struct HeatmapOverlayWithParameters<Content: View>: View {
    private let radiusPx: Int
    private let opacity: Double
    private let gradient: HeatmapGradient
    private let maxIntensity: Double?
    private let weightProvider: (HeatmapPointState) -> Double
    private let tileSize: Int
    private let trackPointUpdates: Bool
    private let disableTileServerCache: Bool
    private let content: () -> Content

    public init(
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider,
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        trackPointUpdates: Bool = false,
        disableTileServerCache: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.radiusPx = radiusPx
        self.opacity = opacity
        self.gradient = gradient
        self.maxIntensity = maxIntensity
        self.weightProvider = weightProvider
        self.tileSize = tileSize
        self.trackPointUpdates = trackPointUpdates
        self.disableTileServerCache = disableTileServerCache
        self.content = content
    }

    public var body: some View {
        HeatmapOverlay(
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            weightProvider: weightProvider,
            tileSize: tileSize,
            trackPointUpdates: trackPointUpdates,
            disableTileServerCache: disableTileServerCache,
            content: content
        )
    }
}
