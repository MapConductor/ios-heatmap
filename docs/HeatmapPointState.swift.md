# HeatmapPointState

An `ObservableObject` representing a single observable heatmap data point. Use inside a
`HeatmapOverlay` via `HeatmapPointView`.

## Signature

```swift
public final class HeatmapPointState: ObservableObject {
    @Published public var position: GeoPoint
    @Published public var weight: Double
    @Published public var extra: AnyHashable?

    public init(
        position: GeoPoint,
        weight: Double = 1.0,
        extra: AnyHashable? = nil
    )
}
```

## Constructor Parameters

- `position`
    - Type: `GeoPoint`
    - Description: The geographic coordinate of this data point.
- `weight`
    - Type: `Double`
    - Default: `1.0`
    - Description: Intensity contribution. Higher values produce hotter colors.
- `extra`
    - Type: `AnyHashable?`
    - Default: `nil`
    - Description: Arbitrary additional data attached to this point. Must be `Hashable`.

## Example

```swift
let pointState = HeatmapPointState(
    position: GeoPoint(latitude: 35.6812, longitude: 139.7671),
    weight: 2.5
)

// Update position dynamically:
pointState.position = GeoPoint(latitude: 35.70, longitude: 139.80)
```
