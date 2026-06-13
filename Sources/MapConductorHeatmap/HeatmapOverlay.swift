import MapConductorCore
import SwiftUI

public struct HeatmapOverlay: ViewBasedMapOverlay, Identifiable {
    public let id: String
    private let overlayState: HeatmapOverlayState
    private let pointStates: [HeatmapPointState]

    public init(
        _ state: HeatmapOverlayState,
        @HeatmapContentBuilder content: () -> HeatmapViewContent = { HeatmapViewContent() }
    ) {
        self.overlayState = state
        self.pointStates = content().pointStates
        self.id = state.rasterLayerState.id
    }

    public init(
        state: HeatmapOverlayState,
        @HeatmapContentBuilder content: () -> HeatmapViewContent = { HeatmapViewContent() }
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
        @HeatmapContentBuilder content: () -> HeatmapViewContent = { HeatmapViewContent() }
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
        HeatmapStateUpdater(overlayState: overlayState, pointStates: pointStates)
    }

    public func append(to content: inout MapViewContent) {
        content.rasterLayers.append(RasterLayer(state: overlayState.rasterLayerState))
    }
}

private struct HeatmapStateUpdater: View {
    let overlayState: HeatmapOverlayState
    let pointStates: [HeatmapPointState]

    private var updateToken: Int {
        var result: Int32 = 1
        for state in pointStates {
            let finger = state.fingerPrint()
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.id)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.position)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.weight)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.extra)
        }
        return Int(result)
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task(id: updateToken) {
                let points = pointStates.map { HeatmapPoint(position: $0.position, weight: $0.weight) }
                overlayState.setPoints(points)
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
            disableTileServerCache: disableTileServerCache
        )
    }
}
