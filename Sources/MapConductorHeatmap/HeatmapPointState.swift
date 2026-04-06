import Combine
import MapConductorCore

public struct HeatmapPointFingerPrint: Equatable, Hashable {
    public let id: Int
    public let position: Int
    public let weight: Int
    public let extra: Int
}

public final class HeatmapPointState: ObservableObject, Identifiable, Equatable, Hashable {
    public let id: String

    @Published public var position: GeoPoint
    @Published public var weight: Double
    @Published public var extra: AnyHashable?

    public init(position: GeoPoint, weight: Double = 1.0, id: String? = nil, extra: AnyHashable? = nil) {
        let resolvedId = id ?? HeatmapPointState.makePointId(position: position, extra: extra)
        self.id = resolvedId
        self.position = position
        self.weight = weight
        self.extra = extra
    }

    public func copy(
        id: String? = nil,
        position: GeoPoint? = nil,
        weight: Double? = nil,
        extra: AnyHashable? = nil
    ) -> HeatmapPointState {
        HeatmapPointState(
            position: position ?? self.position,
            weight: weight ?? self.weight,
            id: id ?? self.id,
            extra: extra ?? self.extra
        )
    }

    public func fingerPrint() -> HeatmapPointFingerPrint {
        HeatmapPointFingerPrint(
            id: javaHash(id),
            position: javaHash(position.latitude) ^ javaHash(position.longitude) ^ javaHash(position.altitude ?? 0.0),
            weight: javaHash(weight),
            extra: javaHash(extra)
        )
    }

    public func asFlow() -> AnyPublisher<HeatmapPointFingerPrint, Never> {
        Publishers.CombineLatest3($position, $weight, $extra)
            .map { [id] position, weight, extra in
                HeatmapPointFingerPrint(
                    id: javaHash(id),
                    position: javaHash(position.latitude) ^ javaHash(position.longitude) ^ javaHash(position.altitude ?? 0.0),
                    weight: javaHash(weight),
                    extra: javaHash(extra)
                )
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public static func == (lhs: HeatmapPointState, rhs: HeatmapPointState) -> Bool {
        lhs.hashCode() == rhs.hashCode()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashCode())
    }

    public func hashCode() -> Int {
        var result: Int32 = Int32(truncatingIfNeeded: javaHash(weight))
        result = result &* 31 &+ Int32(truncatingIfNeeded: javaHash(position.latitude))
        result = result &* 31 &+ Int32(truncatingIfNeeded: javaHash(position.longitude))
        result = result &* 31 &+ Int32(truncatingIfNeeded: javaHash(position.altitude ?? 0.0))
        return Int(result)
    }

    private static func makePointId(position: GeoPoint, extra: AnyHashable?) -> String {
        let hashCodes = [
            javaHash(position.latitude),
            javaHash(position.longitude),
            javaHash(position.altitude ?? 0.0),
            javaHash(extra)
        ]
        return pointId(hashCodes: hashCodes)
    }
}

private func pointId(hashCodes: [Int]) -> String {
    var result: Int32 = 0
    for hash in hashCodes {
        result = result &* 31 &+ Int32(truncatingIfNeeded: hash)
    }
    return String(result)
}

private func javaHash(_ value: Double) -> Int {
    let bits = value.bitPattern
    let combined = bits ^ (bits >> 32)
    return Int(Int32(truncatingIfNeeded: combined))
}

private func javaHash(_ value: String) -> Int {
    var result: Int32 = 0
    for scalar in value.unicodeScalars {
        result = result &* 31 &+ Int32(truncatingIfNeeded: scalar.value)
    }
    return Int(result)
}

private func javaHash(_ value: AnyHashable?) -> Int {
    guard let value else { return 0 }
    return value.hashValue
}
