import CoreGraphics
import Foundation
import UIKit

/// 強度の配列を PNG の `Data` にする部分。
///
/// CoreGraphics で `CGImage` を組み、`UIImage.pngData()` に書かせる。
/// android-sdk / react-sdk は PNG を自前で書いているが、iOS は OS の
/// エンコーダが十分速く、依存も増えないのでそちらに任せている。
///
/// アルファは**乗算済み**で詰める。`premultipliedLast` を指定しているため、
/// 素のまま入れると半透明部分が明るく浮く。
enum HeatmapImageEncoder {
    static func colorize(grid: [Double], dim: Int, colorMap: [UInt32], max: Double) -> Data? {
        let maxColor = colorMap[colorMap.count - 1]
        let colorMapScaling = Double(colorMap.count - 1) / max
        var pixels = [UInt8](repeating: 0, count: dim * dim * 4)

        for i in 0..<dim {
            for j in 0..<dim {
                let value = grid[j * dim + i]
                let index = (i * dim + j) * 4
                if value != 0.0 {
                    let colorIndex = Int(value * colorMapScaling)
                    let color = colorIndex < colorMap.count ? colorMap[colorIndex] : maxColor
                    let alpha = HeatmapColor.alpha(color)
                    pixels[index] = UInt8(HeatmapColor.red(color) * alpha / 255)
                    pixels[index + 1] = UInt8(HeatmapColor.green(color) * alpha / 255)
                    pixels[index + 2] = UInt8(HeatmapColor.blue(color) * alpha / 255)
                    pixels[index + 3] = UInt8(alpha)
                } else {
                    pixels[index + 3] = 0
                }
            }
        }
        return pngData(pixels: pixels, dim: dim)
    }

    /// 全面透明のタイル。描くものが無いときに返す。
    static func makeEmptyTile(size: Int) -> Data {
        let dim = max(1, size)
        return pngData(pixels: [UInt8](repeating: 0, count: dim * dim * 4), dim: dim) ?? Data()
    }

    private static func pngData(pixels: [UInt8], dim: Int) -> Data? {
        let data = Data(pixels)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big
            .union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        guard let image = CGImage(
            width: dim,
            height: dim,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: dim * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        return UIImage(cgImage: image).pngData()
    }
}
