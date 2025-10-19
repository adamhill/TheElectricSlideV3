import Foundation

// MARK: - Scale Configuration

/// Complete configuration for a slide rule scale
public struct ScaleDefinition: Sendable {
    /// Human-readable name/label for the scale (e.g., "C", "D", "LL3")
    public let name: String
    
    /// The mathematical function this scale represents
    public let function: any ScaleFunction
    
    /// Starting value of the scale
    public let beginValue: ScaleValue
    
    /// Ending value of the scale
    public let endValue: ScaleValue
    
    /// Physical length of the scale in points
    public let scaleLengthInPoints: Distance
    
    /// Layout type: linear or circular
    public let layout: ScaleLayout
    
    /// Direction ticks point
    public let tickDirection: TickDirection
    
    /// Subsections with different tick patterns
    public let subsections: [ScaleSubsection]
    
    /// Overall default tick mark styles (from longest to shortest)
    public let defaultTickStyles: [TickStyle]
    
    /// Optional custom label formatter for the entire scale
    public let labelFormatter: (@Sendable (ScaleValue) -> String)?
    
    /// Optional color for labels (as RGB components 0-1)
    public let labelColor: (red: Double, green: Double, blue: Double)?
    
    /// Optional constants to mark on the scale (like π, e)
    public let constants: [ScaleConstant]
    
    public init(
        name: String,
        function: any ScaleFunction,
        beginValue: ScaleValue,
        endValue: ScaleValue,
        scaleLengthInPoints: Distance,
        layout: ScaleLayout,
        tickDirection: TickDirection = .up,
        subsections: [ScaleSubsection] = [],
        defaultTickStyles: [TickStyle] = [.major, .medium, .minor, .tiny],
        labelFormatter: (@Sendable (ScaleValue) -> String)? = nil,
        labelColor: (red: Double, green: Double, blue: Double)? = nil,
        constants: [ScaleConstant] = []
    ) {
        self.name = name
        self.function = function
        self.beginValue = beginValue
        self.endValue = endValue
        self.scaleLengthInPoints = scaleLengthInPoints
        self.layout = layout
        self.tickDirection = tickDirection
        self.subsections = subsections
        self.defaultTickStyles = defaultTickStyles
        self.labelFormatter = labelFormatter
        self.labelColor = labelColor
        self.constants = constants
    }
    /// Whether this is a circular scale
    public var isCircular: Bool {
        layout.isCircular
    }
}

/// Represents a constant value marked on a scale (like π or e)
public struct ScaleConstant: Sendable {
    /// The constant value to mark
    public let value: ScaleValue
    
    /// The label to display (e.g., "π", "e")
    public let label: String
    
    /// Style of the tick mark
    public let style: TickStyle
    
    public init(value: ScaleValue, label: String, style: TickStyle = .major) {
        self.value = value
        self.label = label
        self.style = style
    }
}

// MARK: - Scale Builder

/// Fluent API for building scale definitions
public struct ScaleBuilder {
    private var name: String = ""
    private var function: (any ScaleFunction)?
    private var beginValue: ScaleValue = 1.0
    private var endValue: ScaleValue = 10.0
    private var scaleLengthInPoints: Distance = 250.0
    private var layout: ScaleLayout = .linear
    private var tickDirection: TickDirection = .up
    private var subsections: [ScaleSubsection] = []
    private var defaultTickStyles: [TickStyle] = [.major, .medium, .minor, .tiny]
    private var labelFormatter: (@Sendable (ScaleValue) -> String)?
    private var labelColor: (red: Double, green: Double, blue: Double)?
    private var constants: [ScaleConstant] = []
    
    public init() {}
    
    public func withName(_ name: String) -> ScaleBuilder {
        var copy = self
        copy.name = name
        return copy
    }
    
    public func withFunction(_ function: any ScaleFunction) -> ScaleBuilder {
        var copy = self
        copy.function = function
        return copy
    }
    
    public func withRange(begin: ScaleValue, end: ScaleValue) -> ScaleBuilder {
        var copy = self
        copy.beginValue = begin
        copy.endValue = end
        return copy
    }
    
    public func withLength(_ length: Distance) -> ScaleBuilder {
        var copy = self
        copy.scaleLengthInPoints = length
        return copy
    }
    
    public func withTickDirection(_ direction: TickDirection) -> ScaleBuilder {
        var copy = self
        copy.tickDirection = direction
        return copy
    }
    
    public func withSubsections(_ subsections: [ScaleSubsection]) -> ScaleBuilder {
        var copy = self
        copy.subsections = subsections
        return copy
    }
    
    public func addSubsection(_ subsection: ScaleSubsection) -> ScaleBuilder {
        var copy = self
        copy.subsections.append(subsection)
        return copy
    }
    
    public func withDefaultTickStyles(_ styles: [TickStyle]) -> ScaleBuilder {
        var copy = self
        copy.defaultTickStyles = styles
        return copy
    }
    
    public func withLabelFormatter(_ formatter: @escaping @Sendable (ScaleValue) -> String) -> ScaleBuilder {
        var copy = self
        copy.labelFormatter = formatter
        return copy
    }
    
    public func withLabelColor(red: Double, green: Double, blue: Double) -> ScaleBuilder {
        var copy = self
        copy.labelColor = (red, green, blue)
        return copy
    }
    
    public func withConstants(_ constants: [ScaleConstant]) -> ScaleBuilder {
        var copy = self
        copy.constants = constants
        return copy
    }
    
    public func addConstant(value: ScaleValue, label: String, style: TickStyle = .major) -> ScaleBuilder {
        var copy = self
        copy.constants.append(ScaleConstant(value: value, label: label, style: style))
        return copy
    }
    
    public func build() -> ScaleDefinition {
        guard let function = function else {
            fatalError("Scale function must be specified")
        }
        
        return ScaleDefinition(
            name: name,
            function: function,
            beginValue: beginValue,
            endValue: endValue,
            scaleLengthInPoints: scaleLengthInPoints,
            layout: layout,
            tickDirection: tickDirection,
            subsections: subsections,
            defaultTickStyles: defaultTickStyles,
            labelFormatter: labelFormatter,
            labelColor: labelColor,
            constants: constants
        )
    }
}

// MARK: - Common Label Formatters

public enum StandardLabelFormatter {
    /// Standard integer formatting (rounds to nearest integer)
    public static let integer: @Sendable (ScaleValue) -> String = { value in
        String(Int(value.rounded()))
    }
    
    /// One decimal place
    public static let oneDecimal: @Sendable (ScaleValue) -> String = { value in
        String(format: "%.1f", value)
    }
    
    /// Two decimal places
    public static let twoDecimals: @Sendable (ScaleValue) -> String = { value in
        String(format: "%.2f", value)
    }
    
    /// Three decimal places
    public static let threeDecimals: @Sendable (ScaleValue) -> String = { value in
        String(format: "%.3f", value)
    }
    
    /// Scientific notation
    public static let scientific: @Sendable (ScaleValue) -> String = { value in
        String(format: "%.2e", value)
    }
    
    /// Angle formatting (for trig scales) - removes unnecessary decimals
    public static let angle: @Sendable (ScaleValue) -> String = { value in
        let rounded = value.rounded()
        if abs(value - rounded) < 0.01 {
            return String(Int(rounded))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    /// Creates a formatter that multiplies by a factor before displaying
    public static func scaled(by factor: Double, decimals: Int = 0) -> @Sendable (ScaleValue) -> String {
        { value in
            let scaled = value * factor
            if decimals == 0 {
                return String(Int(scaled.rounded()))
            } else {
                return String(format: "%.\(decimals)f", scaled)
            }
        }
    }
    
    /// Creates a formatter for powers of e (for LL scales)
    public static let ePower: @Sendable (ScaleValue) -> String = { value in
        let power = log(value)
        if abs(power) < 0.01 {
            return "1"
        }
        return String(format: "e^%.2f", power)
    }
}
