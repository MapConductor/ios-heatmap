# HeatmapTileRenderer

Renders heatmap tiles from a set of `HeatmapPoint` values. Used internally by `HeatmapOverlay`
to produce raster tiles that are composited onto the map.

## Signature

```swift
public final class HeatmapTileRenderer: TileProvider {
    public static let defaultTileSize: Int = RasterSource.defaultTileSize  // 512
    public static let defaultCacheSizeKb: Int = 8192  // 8 MB

    public let tileSize: Int

    public init(
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        cacheSizeKb: Int = HeatmapTileRenderer.defaultCacheSizeKb
    )
}
```

## Constructor Parameters

- `tileSize`
    - Type: `Int`
    - Default: `512`
    - Description: Tile size in pixels. Matches `RasterSource.defaultTileSize`.
- `cacheSizeKb`
    - Type: `Int`
    - Default: `8192`
    - Description: In-memory tile cache size in kilobytes.

## Static Properties

- `defaultTileSize` — `Int` — `512`. Same as `RasterSource.defaultTileSize`.
- `defaultCacheSizeKb` — `Int` — `8192` (8 MB).

## Methods

### `update(points:radiusPx:gradient:maxIntensity:)`

Replaces the current point set and invalidates all cached tiles.

```swift
public func update(
    points: [HeatmapPoint],
    radiusPx: Int,
    gradient: HeatmapGradient,
    maxIntensity: Double?
)
```

### `updateCameraZoom(_:)`

Notifies the renderer of a zoom change, enabling zoom-responsive radius scaling.

```swift
public func updateCameraZoom(_ zoom: Double)
```

### `resetCameraZoom()`

Resets zoom-responsive scaling to the default state.

```swift
public func resetCameraZoom()
```
