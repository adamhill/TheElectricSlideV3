import Foundation

// MARK: - Cursor Precision

/// Defines how cursor reading precision is determined
public enum CursorPrecision: Sendable, Equatable, Hashable {
    /// Automatically compute precision from tick intervals
    case automatic
    
    /// Fixed number of decimal places
    case fixed(places: Int)
    
    /// Future: zoom-dependent precision (placeholder implementation)
    case zoomDependent(basePlaces: Int)
    
    // MARK: - Equatable
    
    public static func == (lhs: CursorPrecision, rhs: CursorPrecision) -> Bool {
        switch (lhs, rhs) {
        case (.automatic, .automatic):
            return true
        case (.fixed(let l), .fixed(let r)):
            return l == r
        case (.zoomDependent(let l), .zoomDependent(let r)):
            return l == r
        default:
            return false
        }
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .automatic:
            hasher.combine(0)
        case .fixed(let places):
            hasher.combine(1)
            hasher.combine(places)
        case .zoomDependent(let basePlaces):
            hasher.combine(2)
            hasher.combine(basePlaces)
        }
    }
}

// MARK: - Scale Configuration

/// Complete configuration for a slide rule scale
public struct ScaleDefinition: Sendable {
    /// Default placeholder formula: ℵ√-1 (ALEPH SYMBOL × sqrt(-1))
    public static let defaultFormula: String = {
        let aleph = "\u{2135}"  // ℵ ALEPH SYMBOL
        let sqrt = "√"          // SQUARE ROOT SYMBOL
        return "\(aleph)√-1"
    }()
    
    /// Human-readable name/label for the scale (e.g., "C", "D", "LL3")
    public let name: String
    
    /// Formula representation for this scale (displayed on right side)
    public let formula: String
    
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
    
    /// Whether to render a horizontal baseline for this scale
    public let showBaseline: Bool
    
    /// Typography adjustment for formula text spacing
    /// - 1.0 = normal spacing (no modification)
    /// - < 1.0 = tighter/condensed spacing
    /// - > 1.0 = looser/expanded spacing
    public let formulaTracking: Double
    
    public init(
        name: String,
        formula: String = ScaleDefinition.defaultFormula,
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
        constants: [ScaleConstant] = [],
        showBaseline: Bool = false,
        formulaTracking: Double = 1.0
    ) {
        self.name = name
        self.formula = formula
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
        self.showBaseline = showBaseline
        self.formulaTracking = formulaTracking
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
@available(macOS 12, *)
public struct ScaleBuilder {
    private var name: String = ""
    private var formula: String = ScaleDefinition.defaultFormula
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
    private var showBaseline: Bool = false
    private var formulaTracking: Double = 1.0
    
    public init() {}
    
    public func withName(_ name: String) -> ScaleBuilder {
        var copy = self
        copy.name = name
        return copy
    }
    
    /// Sets the formula display for this scale
    /// - Parameter formula: The formula as a String
    /// - Returns: Updated builder
    public func withFormula(_ formula: String) -> ScaleBuilder {
        var copy = self
        copy.formula = formula
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
    
    public func withBaseline(_ show: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.showBaseline = show
        return copy
    }
    
    /// Sets the formula tracking/kerning adjustment
    /// - Parameter tracking: Typography adjustment (1.0 = normal, <1.0 = tighter, >1.0 = looser)
    /// - Returns: Updated builder
    public func withFormulaTracking(_ tracking: Double) -> ScaleBuilder {
        var copy = self
        copy.formulaTracking = tracking
        return copy
    }
    
    public func build() -> ScaleDefinition {
        guard let function = function else {
            fatalError("Scale function must be specified")
        }
        
        return ScaleDefinition(
            name: name,
            formula: formula,
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
            constants: constants,
            showBaseline: showBaseline,
            formulaTracking: formulaTracking
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
    
    /// Four decimal places
    public static let fourDecimals: @Sendable (ScaleValue) -> String = { value in
        String(format: "%.4f", value)
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
    
    // MARK: - K Scale Formatter (Compact Decade Display)
    
    /// K scale formatter: shows actual value at power-of-10 boundaries, compact form elsewhere
    /// Examples: 10→"10", 20→"2", 100→"100", 200→"2", 1000→"1000"
    /// Uses ClosedRange to properly detect the power-of-10 boundaries
    public static let kScale: @Sendable (ScaleValue) -> String = { value in
        // Define all power-of-10 boundaries
        let tenBoundary: ClosedRange<Double> = 9.5...10.5
        let hundredBoundary: ClosedRange<Double> = 99.5...100.5
        let thousandBoundary: ClosedRange<Double> = 995.0...1005.0
        
        // Check boundaries and show actual values
        if thousandBoundary.contains(value) {
            return "1000"
        }
        if hundredBoundary.contains(value) {
            return "100"
        }
        if tenBoundary.contains(value) {
            return "10"
        }
        
        // For non-boundary values, use appropriate division
        if value >= 100.0 {
            // 100-1000 range: divide by 100 (200→"2", 300→"3", etc.)
            let divided = value / 100.0
            return String(Int(divided.rounded()))
        } else if value >= 10.0 {
            // 10-100 range: divide by 10 (20→"2", 30→"3", etc.)
            let divided = value / 10.0
            return String(Int(divided.rounded()))
        } else {
            // 1-10 range: show as integer
            return String(Int(value.rounded()))
        }
    }
    
    // MARK: - Dual Label Formatters (PostScript plabelR/plabelL support)
    
    /// S scale dual labeling: sine (right italic) and cosine (left italic)
    /// PostScript reference: /plabelR and /plabelL in S scale definition
    /// Right label shows angle, left label shows complementary angle (90° - angle)
    public static func sScaleDual(value: ScaleValue) -> [LabelConfig] {
        let angle = value
        let complementary = 90.0 - value
        
        return [
            // Right label: sine angle in italic (PostScript: NumFontRi)
            LabelConfig(
                text: String(Int(angle.rounded())),
                position: .right,
                fontStyle: .italic,
                color: .black,
                fontSizeMultiplier: 1.5
            ),
            // Left label: cosine (complementary) in italic red (PostScript: NumFontLi)
            LabelConfig(
                text: String(Int(complementary.rounded())),
                position: .left,
                fontStyle: .italic,
                color: .red,
                fontSizeMultiplier: 1.5
            )
        ]
    }
    
    /// Create a single-label configuration with specified position and style
    public static func singleLabel(
        _ formatter: @escaping @Sendable (ScaleValue) -> String,
        position: LabelPosition = .centered,
        fontStyle: LabelFontStyle = .regular,
        color: LabelColor = .black
    ) -> @Sendable (ScaleValue) -> [LabelConfig] {
        return { value in
            [LabelConfig(
                text: formatter(value),
                position: position,
                fontStyle: fontStyle,
                color: color
            )]
        }
    }
}



// MARK: - Cursor Precision Helpers

extension CursorPrecision {
    /// Calculate decimal places for a given value and zoom level
    /// - Parameters:
    ///   - value: The scale value being displayed
    ///   - zoomLevel: Current zoom level (1.0 = normal, 2.0 = 2x zoom, etc.)
    /// - Returns: Number of decimal places (1-5)
    public func decimalPlaces(for value: Double, zoomLevel: Double = 1.0) -> Int {
        switch self {
        case .automatic:
            // Will be computed from intervals by the subsection
            return 2 // Fallback default
            
        case .fixed(let places):
            return Self.clamp(places, min: 1, max: 5)
            
        case .zoomDependent(let basePlaces):
            // Future: add zoom adjustment logic
            let zoomAdjusted = basePlaces + Int(log2(zoomLevel))
            return Self.clamp(zoomAdjusted, min: 1, max: 5)
        }
    }
    
    /// Calculate precision from interval array using standard formula
    /// Formula: -floor(log10(smallest_interval)) + 1, clamped to [1, 5]
    internal static func calculateFromIntervals(_ intervals: [Double]) -> Int {
        guard let smallest = intervals.last(where: { $0 > 0 }) else {
            return 2 // Fallback default
        }
        
        // Formula from Python analysis
        if smallest >= 1.0 {
            return 1 // Integer intervals: show 1 decimal for interpolation
        }
        
        let decimalPlaces = -Int(floor(log10(smallest))) + 1
        return clamp(decimalPlaces, min: 1, max: 5)
    }
    
    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - ScaleDefinition Extensions for Cursor Precision

extension ScaleDefinition {
    /// Get appropriate decimal places for cursor reading at a position
    /// - Parameters:
    ///   - normalizedPosition: Position along scale (0.0-1.0)
    ///   - zoomLevel: Current zoom level (default 1.0)
    /// - Returns: Number of decimal places (1-5)
    public func cursorDecimalPlaces(
        at normalizedPosition: Double,
        zoomLevel: Double = 1.0
    ) -> Int {
        // Convert normalized position to actual scale value
        let value = ScaleCalculator.value(at: normalizedPosition, on: self)
        
        // Find active subsection
        guard let subsection = activeSubsection(for: value) else {
            return 2 // Fallback default
        }
        
        return subsection.decimalPlaces(for: value, zoomLevel: zoomLevel)
    }
    
    /// Find the subsection that applies to a given value
    /// - Parameter value: Scale value to query
    /// - Returns: Active subsection, or nil if none found
    public func activeSubsection(for value: Double) -> ScaleSubsection? {
        var active: ScaleSubsection? = nil
        
        for subsection in subsections {
            if value >= subsection.startValue {
                active = subsection
            } else {
                // Subsections assumed to be sorted by startValue
                break
            }
        }
        
        return active
    }
    
    /// Format a value for cursor display with appropriate precision
    /// - Parameters:
    ///   - value: Value to format
    ///   - normalizedPosition: Position for precision lookup
    ///   - zoomLevel: Current zoom level
    /// - Returns: Formatted string
    public func formatForCursor(
        value: Double,
        at normalizedPosition: Double,
        zoomLevel: Double = 1.0
    ) -> String {
        // Handle non-finite values
        guard value.isFinite else {
            return "—"  // Em dash
        }
        
        let places = cursorDecimalPlaces(at: normalizedPosition, zoomLevel: zoomLevel)
        
        // Use scientific notation for very small values
        let absValue = abs(value)
        if absValue > 0 && absValue < 0.001 {
            return String(format: "%.2e", value)
        }
        
        // Standard decimal formatting
        return String(format: "%.\(places)f", value)
    }
}
