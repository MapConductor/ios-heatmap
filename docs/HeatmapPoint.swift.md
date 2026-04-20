# HeatmapPoint

A value type representing a single heatmap data point with a geographic position and weight.

## Signature

```swift
public struct HeatmapPoint {
    public let position: GeoPoint
    public let weight: Double

    public init(position: GeoPoint, weight: Double)
}
```

## Properties

- `position`
    - Type: `GeoPoint`
    - Description: The geographic coordinate of this data point.
- `weight`
    - Type: `Double`
    - Description: The intensity contribution of this point to the heatmap. Higher values produce
      hotter colors at this location. There is no default — always provide an explicit value.

## Example

```swift
let points = [
    HeatmapPoint(position: GeoPoint(latitude: 35.68, longitude: 139.77), weight: 1.0),
    HeatmapPoint(position: GeoPoint(latitude: 35.69, longitude: 139.78), weight: 3.0)
]
```
