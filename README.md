# MapConductorHeatmap

Heatmap module for MapConductor iOS SDK.

This package is **standalone** and depends only on **ios-sdk-core**.

## Requirements

- iOS 15+
- Swift 5.9+
- Xcode 15+

## Installation (Swift Package Manager)

### Option 1: Add via Xcode

1. In Xcode, open **File > Add Package Dependencies...**
2. Enter this repository URL
3. Add the product **MapConductorHeatmap** to your target

### Option 2: Add to `Package.swift`

Add the dependency:

```swift
dependencies: [
    .package(url: "https://github.com/MapConductor/mapconductor-heatmap", from: "1.0.0"),
],
```

Then add `MapConductorHeatmap` to your target dependencies:

```
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "MapConductorHeatmap", package: "mapconductor-heatmap"),
    ]
),
```

## Usage

```swift
import MapConductorHeatmap
```

### Create and update a heatmap layer

The Heatmap module provides utilities to create a heatmap layer and update it with your data.

```swift
let heatmapState: HeatmapOverlayState = HeatmapOverlayState(tileSize: 512)
let points = [
   HeatmapPointState(position: GeoPoint.fromLatLong(...),
                    weight: 1.0,
                    id: "location-1"),
   HeatmapPointState(position: GeoPoint.fromLatLong(...),
                    weight: 1.0,
                    id: "location-2"),
   ...
   HeatmapPointState(position: GeoPoint.fromLatLong(...),
                    weight: 1.0,
                    id: "location-n"),
]

HeatmapOverlay(heatmapState) {
    HeatmapPoints(points)
}
```

> The concrete map rendering (Google Maps / MapLibre / MapKit) is provided by separate packages.
> This module focuses on heatmap logic and data handling.
