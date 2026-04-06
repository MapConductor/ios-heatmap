import SwiftUI
import MapConductorCore

/// A heatmap overlay that displays weighted points as a heat distribution on the map.
/// This overlay accepts dynamic content using @ViewBuilder, allowing points to be
/// added and removed reactively.
///
/// Example with HeatmapOverlayState (recommended for dynamic property changes):
/// ```swift
/// let heatmapState = HeatmapOverlayState()
///
/// GoogleMapView(state: mapViewState) {
///     HeatmapOverlay(heatmapState) {
///         ForEach(points) { pointState in
///             HeatmapPointView(state: pointState)
///         }
///     }
/// }
/// ```
///
/// Example with direct parameters (simpler, but parameters are fixed):
/// ```swift
/// GoogleMapView(state: mapViewState) {
///     HeatmapOverlayWithParameters(radiusPx: 20, opacity: 0.7) {
///         ForEach(points) { pointState in
///             HeatmapPointView(state: pointState)
///         }
///     }
/// }
/// ```
public struct HeatmapOverlay<Content: View>: ViewBasedMapOverlay, Identifiable {
    public let id: String
    private let overlayState: HeatmapOverlayState
    private let content: Content

    /// Creates a heatmap overlay with an existing HeatmapOverlayState.
    ///
    /// - Parameters:
    ///   - state: The HeatmapOverlayState to use
    ///   - content: View builder containing HeatmapPoint views
    public init(
        _ state: HeatmapOverlayState,
        @ViewBuilder content: () -> Content
    ) {
        self.overlayState = state
        self.id = state.rasterLayerState.id
        self.content = content()
    }

    public init(
        state: HeatmapOverlayState,
        @ViewBuilder content: () -> Content
    ) {
        self.init(state, content: content)
    }

    public var body: some View {
        let contentWithCollector = content
            .environment(\.heatmapPointCollector, overlayState.pointCollector)
            .environment(\.heatmapOverlayState, overlayState)

        return Color.clear
            .frame(width: 0, height: 0)
            .background(contentWithCollector)
    }

    public func append(to mapContent: inout MapViewContent) {
        mapContent.rasterLayers.append(RasterLayer(state: overlayState.rasterLayerState))
    }
}

/// Heatmap overlay with parameter tracking.
/// This view manages HeatmapOverlayState internally and updates it when parameters change.
///
/// Example:
/// ```swift
/// @State var radius = 20
///
/// GoogleMapView(state: mapViewState) {
///     HeatmapOverlayWithParameters(radiusPx: radius, opacity: 0.7) {
///         ForEach(points) { pointState in
///             HeatmapPointView(state: pointState)
///         }
///     }
/// }
/// ```
public struct HeatmapOverlayWithParameters<Content: View>: View {
    @StateObject private var stateHolder: HeatmapOverlayStateHolder
    private let radiusPx: Int
    private let opacity: Double
    private let gradient: HeatmapGradient
    private let maxIntensity: Double?
    private let trackPointUpdates: Bool
    private let content: Content

    public init(
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        trackPointUpdates: Bool = false,
        disableTileServerCache: Bool = false,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider,
        @ViewBuilder content: () -> Content
    ) {
        self.radiusPx = radiusPx
        self.opacity = opacity
        self.gradient = gradient
        self.maxIntensity = maxIntensity
        self.trackPointUpdates = trackPointUpdates
        self.content = content()
        _stateHolder = StateObject(wrappedValue: HeatmapOverlayStateHolder(
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            trackPointUpdates: trackPointUpdates,
            disableTileServerCache: disableTileServerCache,
            weightProvider: weightProvider
        ))
    }

    public var body: some View {
        HeatmapOverlay(stateHolder.state) {
            content
        }
        .onChange(of: radiusPx) { newValue in
            stateHolder.state.radiusPx = newValue
        }
        .onChange(of: opacity) { newValue in
            stateHolder.state.opacity = newValue
        }
        .onChange(of: gradient) { newValue in
            stateHolder.state.gradient = newValue
        }
        .onChange(of: maxIntensity) { newValue in
            stateHolder.state.maxIntensity = newValue
        }
    }
}

/// Observable holder for HeatmapOverlayState
private class HeatmapOverlayStateHolder: ObservableObject {
    let state: HeatmapOverlayState

    init(
        radiusPx: Int,
        opacity: Double,
        gradient: HeatmapGradient,
        maxIntensity: Double?,
        trackPointUpdates: Bool,
        disableTileServerCache: Bool,
        weightProvider: @escaping (HeatmapPointState) -> Double
    ) {
        self.state = HeatmapOverlayState(
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            weightProvider: weightProvider,
            trackPointUpdates: trackPointUpdates,
            disableTileServerCache: disableTileServerCache,
        )
    }
}

/// Convenience initializer for HeatmapOverlay without generic content type
extension HeatmapOverlay where Content == EmptyView {
    /// Creates an empty heatmap overlay with the specified state.
    /// Points can be added programmatically using the state's setPoints() method.
    public init(_ state: HeatmapOverlayState) {
        self.init(state, content: { EmptyView() })
    }

    public init(state: HeatmapOverlayState) {
        self.init(state)
    }
}
