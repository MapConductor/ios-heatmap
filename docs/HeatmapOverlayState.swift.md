# HeatmapOverlayState

Controls the visual parameters of a `HeatmapOverlay`. Changes to properties automatically trigger
heatmap re-rendering via `didSet` observers (not `@Published`).

## Signature

```swift
public final class HeatmapOverlayState {
    public var radiusPx: Int
    public var opacity: Double
    public var gradient: HeatmapGradient
    public var maxIntensity: Double?
    public var weightProvider: (HeatmapPointState) -> Double
    var trackPointUpdates: Bool

    public convenience init(
        tileSize: Int = HeatmapTileRenderer.defaultTileSize,
        radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
        opacity: Double = HeatmapDefaults.defaultOpacity,
        gradient: HeatmapGradient = .default,
        maxIntensity: Double? = nil,
        weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider
    )
}
```

## Constructor Parameters

- `tileSize`
    - Type: `Int`
    - Default: `512`
    - Description: Tile size in pixels for rendering.
- `radiusPx`
    - Type: `Int`
    - Default: `20`
    - Description: Blur radius in pixels.
- `opacity`
    - Type: `Double`
    - Default: `0.7`
    - Description: Overall heatmap opacity `[0.0, 1.0]`.
- `gradient`
    - Type: `HeatmapGradient`
    - Default: `.default` (green-to-red)
    - Description: Color gradient applied to the heatmap intensity.
- `maxIntensity`
    - Type: `Double?`
    - Default: `nil`
    - Description: Fixed maximum intensity. When `nil`, computed automatically from current data.
- `weightProvider`
    - Type: `(HeatmapPointState) -> Double`
    - Default: `HeatmapOverlayState.defaultWeightProvider`
    - Description: Custom function that maps a `HeatmapPointState` to its weight.

## Static Properties

- `defaultWeightProvider` — `(HeatmapPointState) -> Double` — Returns `state.weight` directly.

## Methods

### `onCameraChanged(_:)`

Called by the map when the camera position changes. Triggers zoom-responsive heatmap re-rendering.

```swift
public func onCameraChanged(_ cameraPosition: MapCameraPosition)
```

## Example

```swift
let heatmapState = HeatmapOverlayState(
    radiusPx: 30,
    opacity: 0.85,
    gradient: HeatmapGradient(stops: [
        HeatmapGradientStop(position: 0.0, color: 0xFF0000FF),
        HeatmapGradientStop(position: 1.0, color: 0xFFFF0000)
    ])
)
```
