import Foundation
import MapConductorCore
import UIKit

/// ヒートマップのタイルを描くタイルプロバイダ。
///
/// このファイルが持つのは**元データの保持とタイル要求の段取り**だけで、
/// 実際の計算は責務ごとのファイルにある:
///
/// | ファイル                | 担当                                       |
/// |-------------------------|--------------------------------------------|
/// | ``HeatmapWorld``        | 緯度経度→世界座標、範囲                    |
/// | ``HeatmapIntensity``    | ズームごとの色マップ上限                   |
/// | ``HeatmapColorMap``     | グラデーション→強度別の色表                |
/// | ``HeatmapKernel``       | ガウシアンカーネルと畳み込み               |
/// | ``HeatmapImageEncoder`` | 強度配列→PNG                               |
///
/// android-sdk / react-sdk も同じ責務分けのファイル構成にしてある。
public final class HeatmapTileRenderer: TileProvider {
    public let tileSize: Int

    private let cacheLock = NSLock()
    private let cache = NSCache<NSString, NSData>()
    /// 空タイルを実体ではなくこの目印で覚える。何百枚ぶんも同じバイト列を持つ意味がない。
    private let emptyTileMarker = NSData(bytes: [0], length: 1)
    private var emptyTileDataByPixelRatio: [Int: Data] = [:]

    private let kernel = HeatmapKernel()

    private let stateLock = NSLock()
    private var cameraZoom: Double?
    private var cameraZoomKey: Int?
    private var state: TileState

    public init(
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        cacheSizeKb: Int = HeatmapTileRenderer.defaultCacheSizeKb
    ) {
        self.tileSize = tileSize
        self.state = TileState(
            points: [],
            bounds: nil,
            radiusPx: HeatmapTileRenderer.defaultRadiusPx,
            colorMap: Array(repeating: HeatmapColor.argb(0, 0, 0, 0), count: HeatmapColorMap.colorMapSize),
            maxIntensities: Array(repeating: 0.0, count: HeatmapIntensity.maxZoomLevel)
        )
        cache.totalCostLimit = cacheSizeKb * 1024
    }

    public func update(points: [HeatmapPoint], radiusPx: Int, gradient: HeatmapGradient, maxIntensity: Double?) {
        let safeRadius = max(1, radiusPx)
        let weightedPoints = HeatmapWorld.buildWeightedPoints(points)
        let bounds = weightedPoints.isEmpty ? nil : HeatmapWorld.calculateBounds(weightedPoints)
        let colorMap = HeatmapColorMap.build(gradient)
        let maxIntensities: [Double]
        if let bounds {
            maxIntensities = HeatmapIntensity.getMaxIntensities(
                points: weightedPoints,
                bounds: bounds,
                radius: safeRadius,
                customMaxIntensity: maxIntensity
            )
        } else {
            maxIntensities = Array(repeating: 0.0, count: HeatmapIntensity.maxZoomLevel)
        }
        let nextState = TileState(
            points: weightedPoints,
            bounds: bounds,
            radiusPx: safeRadius,
            colorMap: colorMap,
            maxIntensities: maxIntensities
        )
        stateLock.lock()
        state = nextState
        stateLock.unlock()
        clearCache()
    }

    /// カメラのズームを覚える。半径はこの値で決まるので、タイルの z ではなく
    /// 実際の見え方に合わせた太さになる。刻んで持つのはキャッシュキーを
    /// 安定させるため（連続値だと毎フレーム別キーになる）。
    public func updateCameraZoom(_ zoom: Double) {
        let nextKey = Int((zoom * 100.0).rounded())
        var shouldClearCache = false
        stateLock.lock()
        let previousKey = cameraZoomKey
        cameraZoom = zoom
        if previousKey != nextKey {
            cameraZoomKey = nextKey
            shouldClearCache = true
        }
        stateLock.unlock()
        if shouldClearCache {
            clearCache()
        }
    }

    public func resetCameraZoom() {
        var shouldClearCache = false
        stateLock.lock()
        if cameraZoomKey != nil {
            shouldClearCache = true
        }
        cameraZoom = nil
        cameraZoomKey = nil
        stateLock.unlock()
        if shouldClearCache {
            clearCache()
        }
    }

    public func renderTile(request: TileRequest) -> Data? {
        let snapshot: TileState
        let cameraZoomSnapshot: Double?
        let cameraZoomKeySnapshot: Int
        stateLock.lock()
        snapshot = state
        cameraZoomSnapshot = cameraZoom
        cameraZoomKeySnapshot = cameraZoomKey ?? -1
        stateLock.unlock()

        let pixelRatio = max(1, min(request.pixelRatio, 3))
        let normalizedRequest = TileRequest(x: request.x, y: request.y, z: request.z, pixelRatio: pixelRatio)
        let key = "\(cameraZoomKeySnapshot)/\(pixelRatio)x/\(request.z)/\(request.x)/\(request.y)" as NSString
        cacheLock.lock()
        if let cached = cache.object(forKey: key) {
            cacheLock.unlock()
            return cached === emptyTileMarker ? nil : cached as Data
        }
        cacheLock.unlock()

        let bytes = renderTileInternal(request: normalizedRequest, tileState: snapshot, cameraZoom: cameraZoomSnapshot)
        cacheLock.lock()
        cache.setObject(bytes == nil ? emptyTileMarker : (bytes! as NSData), forKey: key, cost: bytes?.count ?? 1)
        cacheLock.unlock()
        return bytes
    }

    private func renderTileInternal(request: TileRequest, tileState: TileState, cameraZoom: Double?) -> Data? {
        let pixelRatio = request.pixelRatio
        let renderSize = tileSize * pixelRatio
        let emptyTile = emptyTileData(pixelRatio: pixelRatio)
        guard let bounds = tileState.bounds else { return emptyTile }
        if tileState.points.isEmpty { return emptyTile }

        let zoom = Double(request.z)
        let zoomScale = pow(2.0, (cameraZoom ?? zoom) - zoom)
        let radiusRaw = Int((Double(tileState.radiusPx * pixelRatio) / zoomScale).rounded())
        // Clamp to avoid excessive allocations when camera zoom differs greatly from tile zoom.
        let radius = max(1, min(radiusRaw, renderSize))
        let tileKernel = kernel.resolveKernel(radius)
        let tileWidth = HeatmapWorld.worldWidth / pow(2.0, zoom)
        // 半径ぶんの余白を取る。隣のタイルにある点も、この余白ぶんは影響するため。
        let padding = tileWidth * Double(radius) / Double(renderSize)
        let gridDim = renderSize + radius * 2
        let bucketWidth = (tileWidth + 2.0 * padding) / Double(gridDim)

        let geometry = TileGeometry(
            minX: Double(request.x) * tileWidth - padding,
            maxX: Double(request.x + 1) * tileWidth + padding,
            minY: Double(request.y) * tileWidth - padding,
            maxY: Double(request.y + 1) * tileWidth + padding,
            bucketWidth: bucketWidth,
            gridDim: gridDim
        )

        let tileBounds = Bounds(
            minX: geometry.minX,
            maxX: geometry.maxX,
            minY: geometry.minY,
            maxY: geometry.maxY
        )
        let paddedBounds = Bounds(
            minX: bounds.minX - padding,
            maxX: bounds.maxX + padding,
            minY: bounds.minY - padding,
            maxY: bounds.maxY + padding
        )
        if !tileBounds.intersects(paddedBounds) { return emptyTile }

        guard let intensity = HeatmapTileBinner.bin(points: tileState.points, geometry: geometry) else {
            return emptyTile
        }

        let convolved = kernel.convolve(grid: intensity, dimOld: gridDim, kernel: tileKernel)
        let zoomIndex = Int(cameraZoom ?? zoom)
        let clampedIndex = max(0, min(zoomIndex, tileState.maxIntensities.count - 1))
        let maxIntensity = tileState.maxIntensities[clampedIndex]
        if maxIntensity <= 0.0 { return emptyTile }

        return HeatmapImageEncoder.colorize(
            grid: convolved.grid,
            dim: convolved.dim,
            colorMap: tileState.colorMap,
            max: maxIntensity
        ) ?? emptyTile
    }

    private func clearCache() {
        cacheLock.lock()
        cache.removeAllObjects()
        cacheLock.unlock()
    }

    private func emptyTileData(pixelRatio: Int) -> Data {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = emptyTileDataByPixelRatio[pixelRatio] { return cached }
        let data = HeatmapImageEncoder.makeEmptyTile(size: tileSize * pixelRatio)
        emptyTileDataByPixelRatio[pixelRatio] = data
        return data
    }

    /// 描画中に元データが差し替わっても矛盾しないよう、1 回ぶんをまとめて固めたもの。
    private struct TileState {
        let points: [WeightedPoint]
        let bounds: Bounds?
        let radiusPx: Int
        let colorMap: [UInt32]
        let maxIntensities: [Double]
    }

    public static let defaultTileSize = RasterLayerSource.defaultTileSize
    public static let defaultCacheSizeKb = 8 * 1024
    private static let defaultRadiusPx = 20
}
