import Combine
import Foundation
import MapConductorCore

public final class HeatmapOverlayState: ObservableObject {
    let rasterLayerState: RasterLayerState
    let pointCollector: HeatmapPointCollector
    let renderer: HeatmapTileRenderer
    let cameraController: HeatmapCameraController
    let tileSize: Int
    let disableTileServerCache: Bool
    var trackPointUpdates: Bool {
        didSet { updatePointTracking() }
    }

    public var radiusPx: Int {
        didSet { scheduleUpdate() }
    }

    public var opacity: Double {
        didSet {
            rasterLayerState.opacity = clampOpacity(opacity)
        }
    }

    public var gradient: HeatmapGradient {
        didSet { scheduleUpdate() }
    }

    public var maxIntensity: Double? {
        didSet { scheduleUpdate() }
    }

    public var weightProvider: (HeatmapPointState) -> Double {
        didSet { scheduleUpdate() }
    }

    var useCameraZoomForTiles: Bool = true {
        didSet {
            if !useCameraZoomForTiles {
                renderer.resetCameraZoom()
            }
        }
    }

    private let groupId: String
    private let tileServer: LocalTileServer
    private var version: Int64 = 0
    private var pointUpdatesCancellable: AnyCancellable?
    private let updateQueue = DispatchQueue(label: "MapConductorHeatmapOverlay")
    private var explicitPoints: [HeatmapPoint]?
    private var lastPointsFingerprint: Int?
    private var lastCameraZoomKey: Int?
    private var cameraUpdateWorkItem: DispatchWorkItem?

    public convenience init(
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider
    ) {
        self.init(
            tileSize: tileSize,
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            weightProvider: weightProvider,
            trackPointUpdates: false,
            disableTileServerCache: false
        )
    }

    @available(*, deprecated, message: "Use init(tileSize:radiusPx:opacity:gradient:maxIntensity:weightProvider:) instead.")
    public convenience init(
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider
    ) {
        self.init(
            tileSize: HeatmapTileRenderer.defaultTileSize,
            radiusPx: radiusPx,
            opacity: opacity,
            gradient: gradient,
            maxIntensity: maxIntensity,
            weightProvider: weightProvider,
            trackPointUpdates: false,
            disableTileServerCache: false
        )
    }

    public init(
        tileSize: Int,
        radiusPx: Int,
        opacity: Double,
        gradient: HeatmapGradient,
        maxIntensity: Double?,
        weightProvider: @escaping (HeatmapPointState) -> Double,
        trackPointUpdates: Bool,
        disableTileServerCache: Bool
    ) {
        let initialOpacity = min(1.0, max(0.0, opacity))
        self.tileSize = tileSize
        self.disableTileServerCache = disableTileServerCache
        self.radiusPx = radiusPx
        self.opacity = opacity
        self.gradient = gradient
        self.maxIntensity = maxIntensity
        self.weightProvider = weightProvider
        self.trackPointUpdates = trackPointUpdates
        self.groupId = UUID().uuidString
        self.tileServer = TileServerRegistry.get(forceNoStoreCache: disableTileServerCache)
        self.renderer = HeatmapTileRenderer(tileSize: tileSize)
        self.cameraController = HeatmapCameraController(renderer: renderer)
        self.pointCollector = HeatmapPointCollector()

        self.rasterLayerState = RasterLayerState(
            source: RasterSource.urlTemplate(
                template: tileServer.urlTemplate(routeId: groupId, tileSize: renderer.tileSize, cacheKey: String(version)),
                tileSize: renderer.tileSize,
                scheme: .XYZ
            ),
            opacity: initialOpacity,
            visible: false,
            id: "heatmap-\(groupId)",
            extra: version
        )

        tileServer.register(routeId: groupId, provider: renderer)
        updatePointTracking()
    }

    deinit {
        tileServer.unregister(routeId: groupId)
    }

    public func copy(
        radiusPx: Int? = nil,
        opacity: Double? = nil,
        gradient: HeatmapGradient? = nil,
        maxIntensity: Double? = nil,
        weightProvider: ((HeatmapPointState) -> Double)? = nil
    ) -> HeatmapOverlayState {
        HeatmapOverlayState(
            tileSize: self.tileSize,
            radiusPx: radiusPx ?? self.radiusPx,
            opacity: opacity ?? self.opacity,
            gradient: gradient ?? self.gradient,
            maxIntensity: maxIntensity ?? self.maxIntensity,
            weightProvider: weightProvider ?? self.weightProvider,
            trackPointUpdates: self.trackPointUpdates,
            disableTileServerCache: self.disableTileServerCache
        )
    }

    public func onCameraChanged(_ cameraPosition: MapCameraPosition) {
        guard useCameraZoomForTiles else { return }

        let zoomKey = HeatmapOverlayState.cameraZoomKey(cameraPosition.zoom)
        updateQueue.async { [weak self] in
            guard let self else { return }
            self.renderer.updateCameraZoom(cameraPosition.zoom)
            if self.lastCameraZoomKey != zoomKey {
                self.lastCameraZoomKey = zoomKey
                self.cameraUpdateWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    guard self.lastCameraZoomKey == zoomKey else { return }
                    self.version += 1
                    let nextVersion = self.version
                    let nextSource = RasterSource.urlTemplate(
                        template: self.tileServer.urlTemplate(
                            routeId: self.groupId,
                            tileSize: self.renderer.tileSize,
                            cacheKey: String(nextVersion)
                        ),
                        tileSize: self.renderer.tileSize,
                        scheme: .XYZ
                    )
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.rasterLayerState.source = nextSource
                        self.rasterLayerState.extra = nextVersion
                    }
                }
                self.cameraUpdateWorkItem = workItem
                self.updateQueue.asyncAfter(deadline: .now() + .milliseconds(400), execute: workItem)
            }
        }
    }


    func setPoints(_ points: [HeatmapPoint]) {
        updatePointsIfNeeded(points)
    }

    func updatePointsIfNeeded(_ points: [HeatmapPoint]) {
        updateQueue.async { [weak self] in
            guard let self else { return }
            let fingerprint = HeatmapOverlayState.pointsFingerprint(points)
            if self.lastPointsFingerprint == fingerprint {
                return
            }
            self.lastPointsFingerprint = fingerprint
            self.explicitPoints = points
            self.applyUpdate()
        }
    }

    private func scheduleUpdate() {
        updateQueue.async { [weak self] in
            self?.applyUpdate()
        }
    }

    private func updatePointTracking() {
        if trackPointUpdates {
            if pointUpdatesCancellable != nil { return }
            pointUpdatesCancellable =
                pointCollector.flow
                    .debounce(for: .milliseconds(50), scheduler: updateQueue)
                    .sink { [weak self] _ in
                        self?.scheduleUpdate()
                    }
        } else {
            pointUpdatesCancellable?.cancel()
            pointUpdatesCancellable = nil
        }
    }

    private func applyUpdate() {
        let points: [HeatmapPoint]
        if let explicitPoints {
            points = explicitPoints
        } else {
            let collectorPoints = pointCollector.flow.value
            points = collectorPoints.values.compactMap { state -> HeatmapPoint? in
                let weight = weightProvider(state)
                guard !weight.isNaN, weight > 0.0 else { return nil }
                return HeatmapPoint(position: state.position, weight: weight)
            }
        }

        renderer.update(
            points: points,
            radiusPx: max(1, radiusPx),
            gradient: gradient,
            maxIntensity: maxIntensity
        )

        version += 1
        let nextVersion = version
        let nextSource = RasterSource.urlTemplate(
            template: tileServer.urlTemplate(routeId: groupId, tileSize: renderer.tileSize, cacheKey: String(nextVersion)),
            tileSize: renderer.tileSize,
            scheme: .XYZ
        )
        let shouldShowLayer = !points.isEmpty
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.rasterLayerState.source = nextSource
            self.rasterLayerState.extra = nextVersion
            self.rasterLayerState.visible = shouldShowLayer
        }
    }

    private func clampOpacity(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    public static let defaultWeightProvider: (HeatmapPointState) -> Double = { state in
        let weight = state.weight
        if weight.isNaN { return 1.0 }
        return weight
    }

    private static func pointsFingerprint(_ points: [HeatmapPoint]) -> Int {
        var result: Int32 = 0
        for point in points {
            result = result &* 31 &+ Int32(truncatingIfNeeded: javaHash(point.position.latitude))
            result = result &* 31 &+ Int32(truncatingIfNeeded: javaHash(point.position.longitude))
            result = result &* 31 &+ Int32(truncatingIfNeeded: javaHash(point.weight))
        }
        return Int(result)
    }

    private static func cameraZoomKey(_ zoom: Double) -> Int {
        Int(zoom)
    }
}

private func javaHash(_ value: Double) -> Int {
    let bits = value.bitPattern
    let combined = bits ^ (bits >> 32)
    return Int(Int32(truncatingIfNeeded: combined))
}
