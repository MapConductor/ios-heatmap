import Foundation
import MapConductorCore

/// 世界座標系の 1 点（0..1 の正規化 Web メルカトル）。
struct WorldPoint {
    let x: Double
    let y: Double
}

/// 世界座標に落とし、重みを確定させたヒートマップの点。
struct WeightedPoint {
    let x: Double
    let y: Double
    let intensity: Double
}

struct Bounds {
    let minX: Double
    let maxX: Double
    let minY: Double
    let maxY: Double

    func intersects(_ other: Bounds) -> Bool {
        minX <= other.maxX &&
            maxX >= other.minX &&
            minY <= other.maxY &&
            maxY >= other.minY
    }
}

/// 緯度経度を世界座標へ移し、範囲を出す部分。
///
/// すべて副作用のない計算で、タイルの中身にもキャッシュにも触らない。
///
/// android-sdk の `HeatmapWorld.kt` / react-sdk の `HeatmapWorld.ts` と同じ式。
/// 片方だけ直すと 3 者のヒートマップの見え方がずれるので、変えるときは 3 つとも直すこと。
enum HeatmapWorld {
    static let worldWidth = 1.0
    static let defaultIntensity = 1.0
    private static let maxAbsSinLat = 0.9999

    static func buildWeightedPoints(_ points: [HeatmapPoint]) -> [WeightedPoint] {
        if points.isEmpty { return [] }
        var weighted: [WeightedPoint] = []
        weighted.reserveCapacity(points.count)
        for point in points {
            // NaN と負の重みは既定値に倒す（負は面積が減る方向に効いてしまうため）。
            let weight: Double
            if point.weight.isNaN || point.weight < 0.0 {
                weight = defaultIntensity
            } else {
                weight = point.weight
            }
            let world = toWorldPoint(point.position)
            weighted.append(WeightedPoint(x: world.x, y: world.y, intensity: weight))
        }
        return weighted
    }

    static func toWorldPoint(_ position: GeoPoint) -> WorldPoint {
        let x = position.longitude / 360.0 + 0.5
        let siny = sin(position.latitude * Double.pi / 180.0)
        let clamped = max(-maxAbsSinLat, min(maxAbsSinLat, siny))
        let y = 0.5 * log((1 + clamped) / (1 - clamped)) / -(2 * Double.pi) + 0.5
        return WorldPoint(x: x, y: y)
    }

    static func calculateBounds(_ points: [WeightedPoint]) -> Bounds {
        var minX = points[0].x
        var maxX = points[0].x
        var minY = points[0].y
        var maxY = points[0].y
        for point in points {
            if point.x < minX { minX = point.x }
            if point.x > maxX { maxX = point.x }
            if point.y < minY { minY = point.y }
            if point.y > maxY { maxY = point.y }
        }
        return Bounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }
}
