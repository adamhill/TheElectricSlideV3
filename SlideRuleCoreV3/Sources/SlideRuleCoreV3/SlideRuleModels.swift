import Foundation

// MARK: - Core Types

/// Represents a position on a scale as a normalized distance (0.0 to 1.0)
/// where 0.0 is the left/start and 1.0 is the right/end
public typealias NormalizedPosition = Double

/// Represents an actual value on a scale (e.g., 1.5, 3.14, etc.)
public typealias ScaleValue = Double

/// Represents a physical distance in points
public typealias Distance = Double

/// Represents an angular position in degrees (0° to 360°) for circular scales
public typealias AngularPosition = Double

// MARK: - Scale Function Protocol

/// Represents a mathematical function that maps values to positions on a scale
public protocol ScaleFunction: Sendable {
    /// The mathematical formula that transforms a value to a logarithmic or other position
    /// For example, for a standard C/D scale: log10(value)
    func transform(_ value: ScaleValue) -> Double
    
    /// The inverse of the transform function
    /// For example, for a standard C/D scale: pow(10, position)
    func inverseTransform(_ transformedValue: Double) -> ScaleValue
    
    /// Human-readable name for this function (e.g., "log", "log-log", "sin")
    var name: String { get }
}

// MARK: - Common Scale Functions

/// Standard logarithmic function (base 10)
public struct LogarithmicFunction: ScaleFunction {
    public let name = "log"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue)
    }
}

/// Double logarithmic function for LL scales: log(log(value))
public struct LogLogFunction: ScaleFunction {
    public let name = "log-log"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(log(value))
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        exp(pow(10, transformedValue))
    }
}

/// Natural logarithm function
public struct NaturalLogFunction: ScaleFunction {
    public let name = "ln"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log(value)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        exp(transformedValue)
    }
}

/// Linear function (identity)
public struct LinearFunction: ScaleFunction {
    public let name = "linear"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        value
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        transformedValue
    }
}

/// Sine function for trig scales
public struct SineFunction: ScaleFunction {
    public let name = "sin"
    public let multiplier: Double
    
    public init(multiplier: Double = 10.0) {
        self.multiplier = multiplier
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(sin(value * .pi / 180.0) * multiplier)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        asin(pow(10, transformedValue) / multiplier) * 180.0 / .pi
    }
}

/// Tangent function for trig scales
public struct TangentFunction: ScaleFunction {
    public let name = "tan"
    public let multiplier: Double
    
    public init(multiplier: Double = 10.0) {
        self.multiplier = multiplier
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(tan(value * .pi / 180.0) * multiplier)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        atan(pow(10, transformedValue) / multiplier) * 180.0 / .pi
    }
}

/// Custom function that allows a closure-based transformation
public struct CustomFunction: ScaleFunction {
    public let name: String
    private let _transform: @Sendable (ScaleValue) -> Double
    private let _inverseTransform: @Sendable (Double) -> ScaleValue
    
    public init(
        name: String,
        transform: @escaping @Sendable (ScaleValue) -> Double,
        inverseTransform: @escaping @Sendable (Double) -> ScaleValue
    ) {
        self.name = name
        self._transform = transform
        self._inverseTransform = inverseTransform
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        _transform(value)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        _inverseTransform(transformedValue)
    }
}
// MARK: - Scale Layout Types

/// Defines the layout type for a slide rule scale
public enum ScaleLayout: Sendable, Equatable {
    /// Linear slide rule (traditional straight rule)
    case linear
    
    /// Circular slide rule (scales arranged in concentric circles)
    /// - diameter: Overall diameter of the circular rule in points
    /// - radiusInPoints: Radius from center to this scale's ring in points
    case circular(diameter: Distance, radiusInPoints: Distance)
    
    /// Whether this is a circular layout
    public var isCircular: Bool {
        if case .circular = self {
            return true
        }
        return false
    }
    
    /// Get the diameter if circular, nil otherwise
    public var diameter: Distance? {
        if case .circular(let diameter, _) = self {
            return diameter
        }
        return nil
    }
    
    /// Get the radius if circular, nil otherwise
    public var radius: Distance? {
        if case .circular(_, let radius) = self {
            return radius
        }
        return nil
    }
}

// MARK: - Label Configuration

/// Position of a label relative to its tick mark
/// Corresponds to PostScript /Nright, /Nleft, /Ntop, /Nbottom positioning functions
public enum LabelPosition: Sendable, Equatable, Hashable {
    case top        // Above tick (PostScript: /Ntop)
    case bottom     // Below tick
    case left       // Left of tick (PostScript: /Nleft)
    case right      // Right of tick (PostScript: /Nright)
    case centered   // Centered on tick (default)
}

/// Font style modifiers for labels
/// Corresponds to PostScript font selections like NumFontRi (right italic), NumFontLi (left italic)
public enum LabelFontStyle: Sendable, Equatable, Hashable {
    case regular
    case italic         // PostScript: NumFontRi (20° right slant)
    case leftItalic     // PostScript: NumFontLi (20° left slant)
    case bold
    case boldItalic
}

/// Color specification for labels
public struct LabelColor: Sendable, Equatable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    /// Standard colors
    public static let black = LabelColor(red: 0, green: 0, blue: 0)
    public static let red = LabelColor(red: 1, green: 0, blue: 0)
    public static let blue = LabelColor(red: 0, green: 0, blue: 1)
    public static let green = LabelColor(red: 0, green: 0.5, blue: 0)
}

/// Configuration for a single label on a tick mark
/// Supports PostScript's dual labeling system (plabelR, plabelL)
public struct LabelConfig: Sendable, Equatable, Hashable {
    /// The text to display
    public let text: String
    
    /// Position relative to tick mark
    public let position: LabelPosition
    
    /// Font style
    public let fontStyle: LabelFontStyle
    
    /// Color
    public let color: LabelColor
    
    /// Font size multiplier (relative to base size determined by tick length)
    public let fontSizeMultiplier: Double
    
    public init(
        text: String,
        position: LabelPosition = .centered,
        fontStyle: LabelFontStyle = .regular,
        color: LabelColor = .black,
        fontSizeMultiplier: Double = 1.0
    ) {
        self.text = text
        self.position = position
        self.fontStyle = fontStyle
        self.color = color
        self.fontSizeMultiplier = fontSizeMultiplier
    }
}

// MARK: - Tick Mark Types

/// Defines the type and visual properties of a tick mark
public struct TickStyle: Sendable, Hashable {
    /// Relative length of the tick (1.0 = full height)
    public let relativeLength: Double
    
    /// Whether this tick should have a label
    public let shouldLabel: Bool
    
    /// Line width in points
    public let lineWidth: Double
    
    public init(
        relativeLength: Double = 1.0,
        shouldLabel: Bool = false,
        lineWidth: Double = 0.5
    ) {
        self.relativeLength = relativeLength
        self.shouldLabel = shouldLabel
        self.lineWidth = lineWidth
    }
    
    /// Predefined tick styles
    public static let major = TickStyle(relativeLength: 1.0, shouldLabel: true, lineWidth: 1.0)
    public static let medium = TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75)
    public static let minor = TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5)
    public static let tiny = TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
}

/// Represents a single tick mark on a scale
public struct TickMark: Sendable {
    /// The value this tick represents
    public let value: ScaleValue
    
    /// The normalized position (0.0 to 1.0) along the scale
    public let normalizedPosition: NormalizedPosition
    
    /// The angular position (0° to 360°) for circular scales
    public let angularPosition: AngularPosition?
    
    /// The visual style of this tick
    public let style: TickStyle
    
    /// Optional simple label text (backward compatibility)
    /// Deprecated: Use `labels` array for full dual-labeling support
    public let label: String?
    
    /// Multiple labels with full configuration (PostScript dual labeling)
    /// Supports plabelR/plabelL with position, style, and color
    public let labels: [LabelConfig]
    
    public init(
        value: ScaleValue,
        normalizedPosition: NormalizedPosition,
        angularPosition: AngularPosition? = nil,
        style: TickStyle,
        label: String? = nil
    ) {
        self.value = value
        self.normalizedPosition = normalizedPosition
        self.angularPosition = angularPosition
        self.style = style
        self.label = label
        // Convert simple label to LabelConfig for consistency
        self.labels = label.map { [LabelConfig(text: $0)] } ?? []
    }
    
    /// Initialize with multiple configured labels (dual labeling support)
    public init(
        value: ScaleValue,
        normalizedPosition: NormalizedPosition,
        angularPosition: AngularPosition? = nil,
        style: TickStyle,
        labels: [LabelConfig]
    ) {
        self.value = value
        self.normalizedPosition = normalizedPosition
        self.angularPosition = angularPosition
        self.style = style
        self.label = labels.first?.text  // For backward compatibility
        self.labels = labels
    }
}

// MARK: - Scale Direction

/// Indicates which direction tick marks point
public enum TickDirection: Sendable {
    case up
    case down
    
    public var multiplier: Double {
        switch self {
        case .up: return 1.0
        case .down: return -1.0
        }
    }
}

// MARK: - Subsection Definition

/// Defines a range of a scale with specific tick mark patterns
public struct ScaleSubsection: Sendable {
    /// Starting value for this subsection
    public let startValue: ScaleValue
    
    /// Tick intervals at different levels (major, medium, minor, tiny)
    /// Each value represents the increment between ticks at that level
    public let tickIntervals: [Double]
    
    /// Which tick levels should have labels
    public let labelLevels: Set<Int>
    
    /// Optional custom label formatter for this subsection (returns single string)
    public let labelFormatter: (@Sendable (ScaleValue) -> String)?
    
    /// Optional dual label formatter (returns multiple LabelConfig for complex labeling)
    public let dualLabelFormatter: (@Sendable (ScaleValue) -> [LabelConfig])?
    
    /// Cursor reading precision for this subsection
    /// Defaults to automatic calculation from tickIntervals if not specified
    public let cursorPrecision: CursorPrecision?
    
    public init(
        startValue: ScaleValue,
        tickIntervals: [Double],
        labelLevels: Set<Int> = [0],
        labelFormatter: (@Sendable (ScaleValue) -> String)? = nil,
        dualLabelFormatter: (@Sendable (ScaleValue) -> [LabelConfig])? = nil,
        cursorPrecision: CursorPrecision? = nil
    ) {
        self.startValue = startValue
        self.tickIntervals = tickIntervals
        self.labelLevels = labelLevels
        self.labelFormatter = labelFormatter
        self.dualLabelFormatter = dualLabelFormatter
        self.cursorPrecision = cursorPrecision
    }
    
    /// Get decimal places for a value at current zoom level
    /// - Parameters:
    ///   - value: The scale value
    ///   - zoomLevel: Current zoom level (default 1.0)
    /// - Returns: Number of decimal places (1-5)
    public func decimalPlaces(for value: Double, zoomLevel: Double = 1.0) -> Int {
        let precision = cursorPrecision ?? .automatic
        
        switch precision {
        case .automatic:
            // Compute from tick intervals
            return CursorPrecision.calculateFromIntervals(tickIntervals)
        case .fixed(let places):
            return min(max(places, 1), 5)
        case .zoomDependent(let basePlaces):
            let zoomAdjusted = basePlaces + Int(log2(zoomLevel))
            return min(max(zoomAdjusted, 1), 5)
        }
    }
}
