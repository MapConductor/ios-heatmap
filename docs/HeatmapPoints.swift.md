# HeatmapPoints

A SwiftUI `View` that replaces the entire heatmap point set in the enclosing `HeatmapOverlay`
with a given list of `HeatmapPointState` objects. Must be used inside a `HeatmapOverlay` content
block.

## Signature

```swift
public struct HeatmapPoints: View {
    public init(_ states: [HeatmapPointState])
}
```

## Parameters

- `states`
    - Type: `[HeatmapPointState]`
    - Description: The complete set of observable data points. This replaces (not appends to)
      any previously registered points in the overlay.

## Notes

- Reads `@Environment(\.heatmapOverlayState)` to register points. This environment value is
  only set by `HeatmapOverlay`, so using `HeatmapPoints` outside one will crash.
- Use `HeatmapPoints` when you manage a flat array of `HeatmapPointState` objects and want to
  supply them all at once, rather than iterating with `ForEach` + `HeatmapPointView`.

## Example

```swift
@StateObject private var overlayState = HeatmapOverlayState()
@State private var pointStates: [HeatmapPointState] = [...]

HeatmapOverlay(state: overlayState) {
    HeatmapPoints(pointStates)
}
```
