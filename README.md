# MapConductor Heatmap

## Description

MapConductor Heatmap is a map-implementation-agnostic heatmap overlay for the MapConductor iOS SDK.
It renders heatmap data as a tile-based overlay so it works with any map implementation (Google Maps, MapLibre, MapKit, Mapbox, ArcGIS, etc.).

## Setup

https://docs-ios.mapconductor.com/setup/

------------------------------------------------------------------------

## Usage

### Basic HeatmapOverlay

Place `HeatmapOverlay` inside any `XxxMapView` content block and add points with `HeatmapPoints`:

```swift
XxxMapView(state: mapState) {
    HeatmapOverlay(
        state: HeatmapOverlayState(radiusPx: 20, opacity: 0.7)
    ) {
        HeatmapPoints([
            HeatmapPointState(
                position: GeoPoint(latitude: 35.6762, longitude: 139.6503),
                weight: 1.0,
                id: "point-1"
            ),
            HeatmapPointState(
                position: GeoPoint(latitude: 35.6895, longitude: 139.6917),
                weight: 2.5,
                id: "point-2"
            ),
        ])
    }
}
```

### HeatmapPoints (batch)

For large datasets, use `HeatmapPoints` to add all points in a single update:

```swift
let pointStates: [HeatmapPointState] = buildPointList()

XxxMapView(state: mapState) {
    HeatmapOverlay(state: HeatmapOverlayState(radiusPx: 20)) {
        HeatmapPoints(pointStates)
    }
}
```

### HeatmapOverlayState

Use `HeatmapOverlayState` to control heatmap properties dynamically:

```swift
@State private var heatmapState = HeatmapOverlayState(
    radiusPx: 20,
    opacity: 0.7,
    gradient: .default
)

// Update dynamically
heatmapState.radiusPx = 30
heatmapState.opacity = 0.5

XxxMapView(state: mapState) {
    HeatmapOverlay(state: heatmapState) {
        HeatmapPoints(pointStates)
    }
}
```

### Custom HeatmapGradient

```swift
let gradient = HeatmapGradient(stops: [
    HeatmapGradientStop(position: 0.0, color: UIColor(red: 0, green: 0, blue: 1, alpha: 0)),  // transparent blue
    HeatmapGradientStop(position: 0.5, color: UIColor(red: 0, green: 1, blue: 0, alpha: 1)),  // green
    HeatmapGradientStop(position: 1.0, color: UIColor(red: 1, green: 0, blue: 0, alpha: 1)),  // red
])

@State private var heatmapState = HeatmapOverlayState(gradient: gradient)
```

### HeatmapPointState

`HeatmapPointState` allows per-point customization:

```swift
let pointState = HeatmapPointState(
    position: GeoPoint(latitude: 35.6762, longitude: 139.6503),
    weight: 3.0,
    id: "point-1"
)
```

------------------------------------------------------------------------

## API Reference

### HeatmapOverlayState

| Property | Type | Default | Description |
|---|---|---|---|
| `radiusPx` | `Int` | `20` | Blur radius of each point in pixels |
| `opacity` | `Double` | `0.7` | Layer opacity (0.0–1.0) |
| `gradient` | `HeatmapGradient` | `.default` | Color gradient |
| `maxZoom` | `Int` | `22` | Maximum zoom level for rendering |

### HeatmapGradient.default

Green (`rgb(102, 225, 0)`) at position 0.2 → Red (`rgb(255, 0, 0)`) at position 1.0.
