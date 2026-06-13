import MapConductorCore

public struct HeatmapViewContent {
    var pointStates: [HeatmapPointState] = []

    public init() {}

    mutating func merge(_ other: HeatmapViewContent) {
        pointStates.append(contentsOf: other.pointStates)
    }
}

public protocol HeatmapContentItemProtocol {
    func append(to content: inout HeatmapViewContent)
}

@resultBuilder
public enum HeatmapContentBuilder {
    public static func buildBlock() -> HeatmapViewContent {
        HeatmapViewContent()
    }

    public static func buildBlock(_ components: HeatmapViewContent...) -> HeatmapViewContent {
        var content = HeatmapViewContent()
        for c in components { content.merge(c) }
        return content
    }

    public static func buildExpression<T: HeatmapContentItemProtocol>(_ expression: T) -> HeatmapViewContent {
        var content = HeatmapViewContent()
        expression.append(to: &content)
        return content
    }

    public static func buildExpression(_ expression: HeatmapViewContent) -> HeatmapViewContent {
        expression
    }

    public static func buildOptional(_ component: HeatmapViewContent?) -> HeatmapViewContent {
        component ?? HeatmapViewContent()
    }

    public static func buildEither(first component: HeatmapViewContent) -> HeatmapViewContent {
        component
    }

    public static func buildEither(second component: HeatmapViewContent) -> HeatmapViewContent {
        component
    }

    public static func buildArray(_ components: [HeatmapViewContent]) -> HeatmapViewContent {
        var content = HeatmapViewContent()
        for c in components { content.merge(c) }
        return content
    }
}
