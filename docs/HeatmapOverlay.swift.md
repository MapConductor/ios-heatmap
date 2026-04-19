# HeatmapOverlay

A generic SwiftUI `View` that also conforms to `ViewBasedMapOverlay` (`MapOverlayItemProtocol` +
`View`). Place `HeatmapOverlay` inside a map view's `@MapViewContentBuilder` to render a heatmap.

`HeatmapOverlay` injects `heatmapPointCollector` and `heatmapOverlayState` into the SwiftUI
environment for use by `HeatmapPointView` and `HeatmapPoints` children.

## Signature

```swift
public struct HeatmapOverlay<Content: View>: ViewBasedMapOverlay, Identifiable {
    // Multiple overloads — see below
}
```

## Initializers

### With `HeatmapOverlayState` and content (unlabeled state)

```swift
public init(
    _ state: HeatmapOverlayState,
    @ViewBuilder content: () -> Content
)
```

### With `HeatmapOverlayState` and content (labeled state)

```swift
public init(
    state: HeatmapOverlayState,
    @ViewBuilder content: () -> Content
)
```

### With individual parameters and content

```swift
public init(
    radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
    opacity: Double = HeatmapDefaults.defaultOpacity,
    gradient: HeatmapGradient = .default,
    maxIntensity: Double? = nil,
    weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider,
    tileSize: Int = HeatmapTileRenderer.defaultTileSize,
    trackPointUpdates: Bool = false,
    disableTileServerCache: Bool = false,
    @ViewBuilder content: () -> Content
)
```

### Without content (when `Content == EmptyView`)

```swift
// Unlabeled state
public init(_ state: HeatmapOverlayState)

// Labeled state
public init(state: HeatmapOverlayState)

// Individual parameters
public init(
    radiusPx: Int = HeatmapDefaults.defaultRadiusPx,
    opacity: Double = HeatmapDefaults.defaultOpacity,
    gradient: HeatmapGradient = .default,
    maxIntensity: Double? = nil,
    weightProvider: @escaping (HeatmapPointState) -> Double = HeatmapOverlayState.defaultWeightProvider,
    tileSize: Int = HeatmapTileRenderer.defaultTileSize,
    trackPointUpdates: Bool = false,
    disableTileServerCache: Bool = false
)
```

## Parameters

- `state`
    - Type: `HeatmapOverlayState`
    - Description: Observable state controlling the heatmap's visual parameters.
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
    - Default: `.default`
    - Description: Color gradient applied to the heatmap intensity.
- `maxIntensity`
    - Type: `Double?`
    - Default: `nil`
    - Description: Maximum intensity for normalization. When `nil`, computed automatically.
- `weightProvider`
    - Type: `(HeatmapPointState) -> Double`
    - Default: `HeatmapOverlayState.defaultWeightProvider`
    - Description: Closure that extracts a weight value from a `HeatmapPointState`.
- `tileSize`
    - Type: `Int`
    - Default: `512`
    - Description: Tile size in pixels for rendering.
- `trackPointUpdates`
    - Type: `Bool`
    - Default: `false`
    - Description: When `true`, re-renders the heatmap when individual point states change.
- `disableTileServerCache`
    - Type: `Bool`
    - Default: `false`
    - Description: When `true`, disables the tile server cache.
- `content`
    - Type: `@ViewBuilder () -> Content`
    - Description: SwiftUI content containing `HeatmapPointView` or `HeatmapPoints` children.

## Notes

- `HeatmapPointView` and `HeatmapPoints` must be placed inside a `HeatmapOverlay`. Using them
  outside will crash at runtime.

## Example

```swift
GoogleMapView(state: mapState) {
    HeatmapOverlay(radiusPx: 30, opacity: 0.8) {
        ForArray(pointStates) { state in
            HeatmapPointView(state: state)
        }
    }
}

// Or with just state (no additional content):
GoogleMapView(state: mapState) {
    HeatmapOverlay(state: heatmapState)
}
```
