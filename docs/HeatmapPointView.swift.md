# HeatmapPointView

A SwiftUI `View` that registers a single heatmap data point into the enclosing `HeatmapOverlay`.
Must be used inside a `HeatmapOverlay` content block — using it elsewhere crashes at runtime.

## Signature

```swift
public struct HeatmapPointView: View {
    public init(state: HeatmapPointState)

    public init(
        position: GeoPoint,
        weight: Double = 1.0,
        id: String? = nil,
        extra: AnyHashable? = nil
    )
}
```

## Initializers

### `init(state:)`

Creates a view from an observable `HeatmapPointState`. Updates the heatmap whenever the state
changes (if `trackPointUpdates` is enabled on the enclosing `HeatmapOverlayState`).

```swift
public init(state: HeatmapPointState)
```

### `init(position:weight:id:extra:)`

Creates a view from a static position and weight.

```swift
public init(
    position: GeoPoint,
    weight: Double = 1.0,
    id: String? = nil,
    extra: AnyHashable? = nil
)
```

**Parameters**

- `position`
    - Type: `GeoPoint`
    - Description: The geographic coordinate of this data point.
- `weight`
    - Type: `Double`
    - Default: `1.0`
    - Description: Intensity contribution of this point.
- `id`
    - Type: `String?`
    - Default: `nil`
    - Description: Stable identifier. Auto-generated if `nil`.
- `extra`
    - Type: `AnyHashable?`
    - Default: `nil`
    - Description: Arbitrary hashable user data attached to the point.

## Notes

- Reads `@Environment(\.heatmapPointCollector)` to register the point. This environment value
  is only set by `HeatmapOverlay`, so using `HeatmapPointView` outside one will crash.

## Example

```swift
HeatmapOverlay(radiusPx: 25) {
    ForArray(pointStates) { state in
        HeatmapPointView(state: state)
    }
    HeatmapPointView(
        position: GeoPoint(latitude: 35.6812, longitude: 139.7671),
        weight: 5.0
    )
}
```
