# HeatmapGradient

Types describing the color gradient used to render heatmap overlays.

---

# HeatmapGradientStop

A single color stop in a heatmap gradient.

## Signature

```swift
public struct HeatmapGradientStop: Hashable {
    public let position: Double
    public let color: UIColor

    public init(position: Double, color: UIColor)
}
```

## Properties

- `position`
    - Type: `Double`
    - Description: Normalized position in the gradient, in `[0.0, 1.0]`. Values outside this
      range are invalid.
- `color`
    - Type: `UIColor`
    - Description: The color at this stop.

---

# HeatmapGradient

A sorted list of `HeatmapGradientStop` values defining the heatmap color scale.

## Signature

```swift
public final class HeatmapGradient: Hashable {
    public let stops: [HeatmapGradientStop]

    public init(stops: [HeatmapGradientStop])

    public static let `default`: HeatmapGradient
}
```

## Properties

- `stops`
    - Type: `[HeatmapGradientStop]`
    - Description: Color stops sorted by position. All positions must be in `[0.0, 1.0]`.

## Default Gradient

```
position 0.2 → rgb(102, 225, 0)   — green-ish
position 1.0 → rgb(255,   0, 0)   — red
```

---

# HeatmapDefaults

Static default values for heatmap rendering.

## Signature

```swift
public enum HeatmapDefaults {
    public static let defaultRadiusPx: Int = 20
    public static let defaultOpacity: Double = 0.7
    public static let defaultMaxZoom: Int = 22
}
```

## Example

```swift
let gradient = HeatmapGradient(stops: [
    HeatmapGradientStop(position: 0.0, color: UIColor(red: 0, green: 0, blue: 1, alpha: 1)),   // blue
    HeatmapGradientStop(position: 0.5, color: UIColor(red: 0, green: 1, blue: 0, alpha: 1)),   // green
    HeatmapGradientStop(position: 1.0, color: UIColor(red: 1, green: 0, blue: 0, alpha: 1))    // red
])
```
