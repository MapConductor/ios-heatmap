import Foundation

/// ズームごとの「色マップの上限に対応する強度」を決める部分。
///
/// ヒートマップは重なりの濃さを色で表すので、何をもって最濃とするかを決めないと
/// 色が付かない。ズームが変われば同じ画面に入る点の数も変わるため、上限は
/// ズームごとに持つ（引いたときだけ真っ赤、寄ると全部薄い、を避ける）。
///
/// 求め方は「その画面サイズで、半径 2 つ分の升目に落としたときの最大合計」。
/// 実際に畳み込んだ値ではないが、それに比例した量になり、はるかに軽い。
///
/// android-sdk / react-sdk の同名ファイルと同じ式。
enum HeatmapIntensity {
    /// ズーム 3 での基準画面サイズ（px）。ズーム 1 ごとに 2 倍していく。
    private static let screenSize = 1280.0
    private static let screenSizeBaseZoom = 3
    private static let defaultMinZoom = 5
    private static let defaultMaxZoom = 11
    static let maxZoomLevel = 22

    static func getMaxIntensities(
        points: [WeightedPoint],
        bounds: Bounds,
        radius: Int,
        customMaxIntensity: Double?
    ) -> [Double] {
        var maxIntensityArray = Array(repeating: 0.0, count: maxZoomLevel)
        if let customMaxIntensity, customMaxIntensity != 0.0 {
            for i in 0..<maxIntensityArray.count {
                maxIntensityArray[i] = customMaxIntensity
            }
            return maxIntensityArray
        }

        // 実際に計算するのは 5..10 だけ。外側は端の値で埋める
        // （引きすぎ・寄りすぎの領域は見た目が変わらず、計算だけ重くなるため）。
        for i in defaultMinZoom..<defaultMaxZoom {
            let screenDim = Int((screenSize * pow(2.0, Double(i - screenSizeBaseZoom))).rounded())
            maxIntensityArray[i] = getMaxValue(points: points, bounds: bounds, radius: radius, screenDim: screenDim)
            if i == defaultMinZoom {
                for j in 0..<i {
                    maxIntensityArray[j] = maxIntensityArray[i]
                }
            }
        }

        if defaultMaxZoom < maxZoomLevel {
            for i in defaultMaxZoom..<maxZoomLevel {
                maxIntensityArray[i] = maxIntensityArray[defaultMaxZoom - 1]
            }
        }

        return maxIntensityArray
    }

    static func getMaxValue(points: [WeightedPoint], bounds: Bounds, radius: Int, screenDim: Int) -> Double {
        let minX = bounds.minX
        let maxX = bounds.maxX
        let minY = bounds.minY
        let maxY = bounds.maxY
        let boundsDim = max(maxX - minX, maxY - minY)
        if boundsDim == 0.0 {
            // 全点が同じ位置。升目に落としても意味がないので、最大の重みをそのまま使う。
            return points.map { $0.intensity }.max() ?? 0.0
        }
        let nBuckets = max(1, Int(Double(screenDim) / (2.0 * Double(radius)) + 0.5))
        let scale = Double(nBuckets) / boundsDim
        var buckets: [Int: [Int: Double]] = [:]
        var maxValue = 0.0
        for point in points {
            let xBucket = Int((point.x - minX) * scale)
            let yBucket = Int((point.y - minY) * scale)
            var column = buckets[xBucket] ?? [:]
            let nextValue = (column[yBucket] ?? 0.0) + point.intensity
            column[yBucket] = nextValue
            buckets[xBucket] = column
            if nextValue > maxValue {
                maxValue = nextValue
            }
        }
        return maxValue
    }
}
