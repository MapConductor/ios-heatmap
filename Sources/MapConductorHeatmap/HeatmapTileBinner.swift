import Foundation

/// タイル 1 枚ぶんの、世界座標での位置と格子の刻み。
struct TileGeometry {
    let minX: Double
    let maxX: Double
    let minY: Double
    let maxY: Double
    let bucketWidth: Double
    let gridDim: Int
}

/// タイルにかかる点を集め、格子のセルへ足し込む部分。
///
/// 日付変更線をまたぐタイルは、世界 1 周ぶんずらした位置でも判定する。
/// そうしないと、端をまたぐタイルで反対側にある点を拾えない。
///
/// android-sdk の `HeatmapTileBinner.kt` と同じ選び方
/// （あちらは点が多いとき空間インデックスも使う。iOS は未対応で、これは元からの差）。
enum HeatmapTileBinner {
    /// - Returns: 1 点でも格子に入ったときだけ格子を返す。nil なら描くものが無い。
    static func bin(points: [WeightedPoint], geometry: TileGeometry) -> [Double]? {
        var intensity = Array(repeating: 0.0, count: geometry.gridDim * geometry.gridDim)
        var hasPoints = false

        var overlapMinX = 0.0
        var overlapMaxX = 0.0
        var xOffset = 0.0
        if geometry.minX < 0.0 {
            overlapMinX = geometry.minX + HeatmapWorld.worldWidth
            overlapMaxX = HeatmapWorld.worldWidth
            xOffset = -HeatmapWorld.worldWidth
        } else if geometry.maxX > HeatmapWorld.worldWidth {
            overlapMinX = 0.0
            overlapMaxX = geometry.maxX - HeatmapWorld.worldWidth
            xOffset = HeatmapWorld.worldWidth
        }

        func addPoint(worldX: Double, worldY: Double, weight: Double) {
            let bucketX = Int((worldX - geometry.minX) / geometry.bucketWidth)
            let bucketY = Int((worldY - geometry.minY) / geometry.bucketWidth)
            if bucketX < 0 || bucketX >= geometry.gridDim || bucketY < 0 || bucketY >= geometry.gridDim {
                return
            }
            intensity[bucketX * geometry.gridDim + bucketY] += weight
        }

        for point in points {
            if point.y < geometry.minY || point.y > geometry.maxY { continue }
            var added = false
            if point.x >= geometry.minX && point.x <= geometry.maxX {
                addPoint(worldX: point.x, worldY: point.y, weight: point.intensity)
                added = true
            }
            if xOffset != 0.0 && point.x >= overlapMinX && point.x <= overlapMaxX {
                addPoint(worldX: point.x + xOffset, worldY: point.y, weight: point.intensity)
                added = true
            }
            if added { hasPoints = true }
        }

        return hasPoints ? intensity : nil
    }
}
