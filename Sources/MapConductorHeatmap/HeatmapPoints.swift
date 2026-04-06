import SwiftUI

/// Adds a batch of heatmap points to a HeatmapOverlay in a single update.
/// This is the recommended API for large datasets.
public struct HeatmapPoints: View {
    @Environment(\.heatmapOverlayState) private var overlayState

    private let states: [HeatmapPointState]

    public init(_ states: [HeatmapPointState]) {
        self.states = states
    }

    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task(id: updateToken) {
                applyStates(states)
            }
    }

    private var updateToken: Int {
        var result: Int32 = 1
        for state in states {
            let finger = state.fingerPrint()
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.id)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.weight)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.latitude)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.longitude)
            result = result &* 31 &+ Int32(truncatingIfNeeded: finger.altitude)
        }
        return Int(result)
    }

    private func applyStates(_ states: [HeatmapPointState]) {
        guard let overlayState else {
            fatalError("HeatmapPoints must be used inside HeatmapOverlay")
        }

        let points = states.map { state in
            HeatmapPoint(position: state.position, weight: state.weight)
        }
        overlayState.setPoints(points)
    }
}
