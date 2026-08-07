import Foundation

/// 色マップ上の 1 区間。`duration` は区間が占めるインデックス数。
private struct ColorInterval {
    let color1: UInt32
    let color2: UInt32
    let duration: Double
}

/// グラデーション定義から、強度 → 色の引き当て表を作る部分。
///
/// 描画のたびに補間すると重いので、`colorMapSize` 段の表へ一度だけ展開しておき、
/// タイル描画では配列の添字を引くだけにする。
///
/// **補間は HSV で行う。** RGB で補間すると青→赤のような組み合わせで中間が
/// 濁った灰色になり、ヒートマップとして意図した色相の変化にならない。
///
/// android-sdk / react-sdk の同名ファイルと同じ式。
enum HeatmapColorMap {
    static let colorMapSize = 1000

    static func build(_ gradient: HeatmapGradient) -> [UInt32] {
        generate(colors: gradient.colors(), startPoints: gradient.startPoints(), mapSize: colorMapSize)
    }

    static func generate(colors: [UInt32], startPoints: [Float], mapSize: Int) -> [UInt32] {
        precondition(!colors.isEmpty, "Heatmap gradient requires at least one color.")
        var colorIntervals: [Int: ColorInterval] = [:]

        // 最初の停止点が 0 でないときは、透明から最初の色へ立ち上げる区間を足す。
        if startPoints[0] != 0 {
            let initialColor = HeatmapColor.argb(
                0,
                HeatmapColor.red(colors[0]),
                HeatmapColor.green(colors[0]),
                HeatmapColor.blue(colors[0])
            )
            colorIntervals[0] = ColorInterval(
                color1: initialColor,
                color2: colors[0],
                duration: Double(mapSize) * Double(startPoints[0])
            )
        }

        if colors.count > 1 {
            for i in 1..<colors.count {
                colorIntervals[Int(Double(mapSize) * Double(startPoints[i - 1]))] = ColorInterval(
                    color1: colors[i - 1],
                    color2: colors[i],
                    duration: Double(mapSize) * Double(startPoints[i] - startPoints[i - 1])
                )
            }
        }

        // 最後の停止点が 1 でないときは、最後の色のまま最後まで伸ばす。
        if let last = startPoints.last, last != 1.0 {
            let index = startPoints.count - 1
            colorIntervals[Int(Double(mapSize) * Double(last))] = ColorInterval(
                color1: colors[index],
                color2: colors[index],
                duration: Double(mapSize) * Double(1.0 - last)
            )
        }

        var colorMap = Array(repeating: colors[0], count: mapSize)
        var interval = colorIntervals[0] ?? ColorInterval(color1: colors[0], color2: colors[0], duration: 1.0)
        var start = 0
        for i in 0..<mapSize {
            if let next = colorIntervals[i] {
                interval = next
                start = i
            }
            let ratio = interval.duration == 0 ? 0.0 : Double(i - start) / interval.duration
            colorMap[i] = interpolateColor(color1: interval.color1, color2: interval.color2, ratio: ratio)
        }
        return colorMap
    }

    /// HSV 空間で 2 色を補間する。
    ///
    /// 色相は 360 度で循環するので、差が 180 度を超える場合は近い方を回る
    /// （そうしないと赤→マゼンタが緑側を大回りしてしまう）。
    static func interpolateColor(color1: UInt32, color2: UInt32, ratio: Double) -> UInt32 {
        let clamped = max(0.0, min(1.0, ratio))
        let alpha = Int(
            (Double(HeatmapColor.alpha(color2) - HeatmapColor.alpha(color1)) * clamped
                + Double(HeatmapColor.alpha(color1))).rounded()
        )
        var hsv1 = HeatmapColor.hsvComponents(color1)
        var hsv2 = HeatmapColor.hsvComponents(color2)

        if hsv1.h - hsv2.h > 180 {
            hsv2.h += 360
        } else if hsv2.h - hsv1.h > 180 {
            hsv1.h += 360
        }

        let h = (hsv2.h - hsv1.h) * clamped + hsv1.h
        let s = (hsv2.s - hsv1.s) * clamped + hsv1.s
        let v = (hsv2.v - hsv1.v) * clamped + hsv1.v

        return HeatmapColor.colorFromHSV(alpha: alpha, h: h, s: s, v: v)
    }
}
