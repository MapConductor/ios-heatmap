import Accelerate
import Foundation

/// ガウシアンカーネルの生成と、それを使った畳み込み。
///
/// **2 次元の畳み込みを縦横 2 回の 1 次元に分けている。** ガウシアンは可分なので
/// 結果は同じで、計算量が O(r^2) から O(r) に落ちる。
///
/// 既定では Accelerate（vDSP）を使う。使えなかったときのために素の実装も残してあり、
/// 結果は同じ。作業配列はサイズが変わったときだけ作り直して使い回す。
///
/// カーネルは半径ごとにキャッシュする。半径はズームで決まり、同じズームの
/// タイルが大量に来るため、毎回作ると無駄になる。
///
/// android-sdk / react-sdk の同名ファイルと同じ式。
final class HeatmapKernel {
    /// 半径を標準偏差へ落とす除数。3σ でほぼ 0 になるので半径の 1/3。
    private static let kernelSdDivisor = 3.0

    private let useAccelerate: Bool
    private var cache: [Int: [Double]] = [:]
    private let cacheLock = NSLock()

    private let convolutionLock = NSLock()
    private var vDSPIntermediateBuffer: [Double] = []
    private var vDSPOutputBuffer: [Double] = []
    private var vDSPIntermediateSize = 0
    private var vDSPOutputSize = 0

    init(useAccelerate: Bool = true) {
        self.useAccelerate = useAccelerate
    }

    func resolveKernel(_ radius: Int) -> [Double] {
        if radius <= 0 { return [1.0] }
        cacheLock.lock()
        if let cached = cache[radius] {
            cacheLock.unlock()
            return cached
        }
        let built = generateKernel(radius: radius, sd: Double(radius) / Self.kernelSdDivisor)
        cache[radius] = built
        cacheLock.unlock()
        return built
    }

    func generateKernel(radius: Int, sd: Double) -> [Double] {
        let size = radius * 2 + 1
        var kernel = Array(repeating: 0.0, count: size)
        for i in -radius...radius {
            kernel[i + radius] = exp(-Double(i * i) / (2 * sd * sd))
        }
        return kernel
    }

    /// `grid`（`dimOld` 角）に縦横のカーネルをかけ、余白を落とした `dim` 角を返す。
    func convolve(grid: [Double], dimOld: Int, kernel: [Double]) -> (grid: [Double], dim: Int) {
        if useAccelerate, let result = convolveAccelerate(grid: grid, dimOld: dimOld, kernel: kernel) {
            return result
        }
        let radius = kernel.count / 2
        let dim = dimOld - 2 * radius
        let lowerLimit = radius
        let upperLimit = radius + dim - 1

        var intermediate = Array(repeating: 0.0, count: dimOld * dimOld)
        for x in 0..<dimOld {
            let base = x * dimOld
            for y in 0..<dimOld {
                let value = grid[base + y]
                if value == 0.0 { continue }
                let xUpperLimit = min(upperLimit, x + radius) + 1
                let initial = max(lowerLimit, x - radius)
                for x2 in initial..<xUpperLimit {
                    intermediate[x2 * dimOld + y] += value * kernel[x2 - (x - radius)]
                }
            }
        }

        var output = Array(repeating: 0.0, count: dim * dim)
        for x in lowerLimit...upperLimit {
            let base = x * dimOld
            for y in 0..<dimOld {
                let value = intermediate[base + y]
                if value == 0.0 { continue }
                let yUpperLimit = min(upperLimit, y + radius) + 1
                let initial = max(lowerLimit, y - radius)
                for y2 in initial..<yUpperLimit {
                    output[(x - radius) * dim + (y2 - radius)] += value * kernel[y2 - (y - radius)]
                }
            }
        }
        return (output, dim)
    }

    private func convolveAccelerate(grid: [Double], dimOld: Int, kernel: [Double]) -> (grid: [Double], dim: Int)? {
        let radius = kernel.count / 2
        let dim = dimOld - 2 * radius
        guard dimOld > 0, dim > 0 else { return nil }

        convolutionLock.lock()
        ensureConvolutionBuffers(dimOld: dimOld, dim: dim)

        grid.withUnsafeBufferPointer { gridPtr in
            vDSPIntermediateBuffer.withUnsafeMutableBufferPointer { interPtr in
                for y in 0..<dimOld {
                    let inputStart = gridPtr.baseAddress! + y
                    let outputStart = interPtr.baseAddress! + y
                    vDSP_convD(
                        inputStart,
                        vDSP_Stride(dimOld),
                        kernel,
                        1,
                        outputStart,
                        vDSP_Stride(dimOld),
                        vDSP_Length(dim),
                        vDSP_Length(kernel.count)
                    )
                }
            }
        }

        vDSPIntermediateBuffer.withUnsafeBufferPointer { interPtr in
            vDSPOutputBuffer.withUnsafeMutableBufferPointer { outPtr in
                for x in 0..<dim {
                    let inputStart = interPtr.baseAddress! + (x * dimOld)
                    let outputStart = outPtr.baseAddress! + (x * dim)
                    vDSP_convD(
                        inputStart,
                        1,
                        kernel,
                        1,
                        outputStart,
                        1,
                        vDSP_Length(dim),
                        vDSP_Length(kernel.count)
                    )
                }
            }
        }

        let output = vDSPOutputBuffer
        convolutionLock.unlock()

        return (output, dim)
    }

    private func ensureConvolutionBuffers(dimOld: Int, dim: Int) {
        let intermediateSize = dimOld * dim
        if vDSPIntermediateSize != intermediateSize {
            vDSPIntermediateBuffer = Array(repeating: 0.0, count: intermediateSize)
            vDSPIntermediateSize = intermediateSize
        }

        let outputSize = dim * dim
        if vDSPOutputSize != outputSize {
            vDSPOutputBuffer = Array(repeating: 0.0, count: outputSize)
            vDSPOutputSize = outputSize
        }
    }
}
