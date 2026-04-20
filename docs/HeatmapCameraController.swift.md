# HeatmapCameraController

An `OverlayControllerProtocol` implementation that forwards camera changes to the
`HeatmapTileRenderer` for zoom-responsive radius scaling. All other overlay controller protocol
methods (marker/polyline/polygon management) are no-ops.

## Signature

```swift
public final class HeatmapCameraController: OverlayControllerProtocol {
    public init(renderer: HeatmapTileRenderer)
}
```

## Constructor Parameters

- `renderer`
    - Type: `HeatmapTileRenderer`
    - Description: The tile renderer to notify when the camera zoom changes.

## Methods

### `onCameraChanged(mapCameraPosition:)`

Called by the map when the camera position changes. Forwards the new zoom level to
`HeatmapTileRenderer.updateCameraZoom(_:)`.

```swift
public func onCameraChanged(mapCameraPosition: MapCameraPosition) async
```

## Notes

- All other `OverlayControllerProtocol` methods (`add`, `update`, `clear`, `find`) are
  implemented as no-ops. `HeatmapCameraController` only responds to camera events.
