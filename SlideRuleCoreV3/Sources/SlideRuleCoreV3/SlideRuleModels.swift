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

// MARK: - Margin Side

/// Which margin a scale element (name or formula) appears in
/// Used for flexible per-scale positioning as seen on rules like Graphoplex 698
/// where scale names appear on left for some scales and right for others
public enum MarginSide: String, Sendable, Equatable, Hashable, Codable {
    /// Element appears in left margin (default for scale names)
    case left
    /// Element appears in right margin (default for formulas)
    case right
    /// Element is suppressed entirely
    case none
}

// MARK: - Rule Display Settings

/// Rule-level display settings for scale names and formulas
/// These provide global toggles that apply to all scales on a slide rule,
/// with per-scale overrides possible via MarginSide settings
///
/// ## Usage Pattern
/// ```swift
/// // Create settings that hide all formulas (like Pickett N-16 ES testing)
/// let settings = RuleDisplaySettings(showFormulas: false)
///
/// // Create settings with names on right by default (European style)
/// let euroSettings = RuleDisplaySettings(defaultScaleNameMargin: .right)
/// ```
public struct RuleDisplaySettings: Sendable, Equatable, Hashable, Codable {
    /// Whether to show scale names on this rule (default: true)
    /// When false, no scale names are rendered regardless of per-scale settings
    public var showScaleNames: Bool
    
    /// Whether to show formulas on this rule (default: true)
    /// When false, no formulas are rendered regardless of per-scale settings
    public var showFormulas: Bool
    
    /// Default margin for scale names when not specified per-scale (default: .left)
    public var defaultScaleNameMargin: MarginSide
    
    /// Default margin for formulas when not specified per-scale (default: .right)
    public var defaultFormulaMargin: MarginSide
    
    public init(
        showScaleNames: Bool = true,
        showFormulas: Bool = true,
        defaultScaleNameMargin: MarginSide = .left,
        defaultFormulaMargin: MarginSide = .right
    ) {
        self.showScaleNames = showScaleNames
        self.showFormulas = showFormulas
        self.defaultScaleNameMargin = defaultScaleNameMargin
        self.defaultFormulaMargin = defaultFormulaMargin
    }
    
    /// Standard display settings (names left, formulas right, both visible)
    public static let standard = RuleDisplaySettings()
    
    /// Names only (no formulas) - common for simpler rules
    public static let namesOnly = RuleDisplaySettings(showFormulas: false)
    
    /// Formulas only (no names) - rare but possible
    public static let formulasOnly = RuleDisplaySettings(showScaleNames: false)
    
    /// No margin labels at all
    public static let none = RuleDisplaySettings(showScaleNames: false, showFormulas: false)
}

// MARK: - Margin Annotations

/// Annotation for per-scale left/right margin text
/// Used to add custom text in the margins that replaces or supplements the scale name/formula
public struct MarginAnnotation: Sendable, Equatable, Hashable {
    /// The text to display (single line)
    public let text: String
    
    /// Color for the annotation text
    public let color: LabelColor
    
    /// Fine-tuning offset from default position (in points)
    public let offset: Offset
    
    /// Font size multiplier relative to base margin font (1.0 = normal)
    public let fontSizeMultiplier: Double
    
    public init(
        text: String,
        color: LabelColor = .black,
        offset: Offset = .zero,
        fontSizeMultiplier: Double = 1.0
    ) {
        self.text = text
        self.color = color
        self.offset = offset
        self.fontSizeMultiplier = fontSizeMultiplier
    }
}

// MARK: - Component Annotations

/// Text alignment for multi-line text blocks
public enum AnnotationTextAlignment: String, Sendable, Equatable, Hashable, Codable {
    case leading
    case center
    case trailing
}

/// Anchor point for positioning annotations
/// Determines which part of the annotation is placed at the specified position
public enum AnnotationAnchor: String, Sendable, Equatable, Hashable, Codable {
    case topLeading, top, topTrailing
    case leading, center, trailing
    case bottomLeading, bottom, bottomTrailing
}

/// Content type for component annotations
public enum AnnotationContent: Sendable, Equatable, Hashable, Codable {
    /// Text content, supports \n for multi-line
    case text(String)
    
    /// Image from asset catalog (PNG, JPEG with @1x/@2x/@3x)
    case assetImage(name: String)
    
    /// SF Symbol with optional rendering mode
    case sfSymbol(name: String)
    
    /// SVG file from bundle resources
    case svg(name: String)
}

/// Annotation for text blocks and images positioned on a Stator or Slide
/// Uses normalized coordinates (0.0-1.0) with origin at top-left of the component
///
/// ## Coordinate System
/// ```
/// (0.0, 0.0) ─────────────────── (1.0, 0.0)
///     │                               │
///     │     STATOR or SLIDE           │
///     │                               │
/// (0.0, 1.0) ─────────────────── (1.0, 1.0)
/// ```
public struct ComponentAnnotation: Sendable, Equatable, Hashable {
    /// The content to display (text, image, SF Symbol, or SVG)
    public let content: AnnotationContent
    
    /// Color for text or SF Symbol; ignored for images/SVGs
    public let color: LabelColor?
    
    /// Horizontal position (0.0 = left edge, 1.0 = right edge)
    public let horizontalPosition: Double
    
    /// Vertical position (0.0 = top edge, 1.0 = bottom edge)
    public let verticalPosition: Double
    
    /// Which part of the annotation is anchored at the position
    public let anchor: AnnotationAnchor
    
    /// Explicit size for images (width, height in points); nil = intrinsic size
    public let size: (width: Double, height: Double)?
    
    /// Font size for text; nil = use default
    public let fontSize: Double?
    
    /// Font weight/style for text
    public let fontWeight: LabelFontStyle
    
    /// Text alignment for multi-line text
    public let textAlignment: AnnotationTextAlignment
    
    /// Fine-grained position adjustment (applied after main positioning)
    /// Use this for small tweaks without changing the base position
    public let nudge: PositionNudge?
    
    public init(
        content: AnnotationContent,
        color: LabelColor? = nil,
        horizontalPosition: Double,
        verticalPosition: Double,
        anchor: AnnotationAnchor = .topLeading,
        size: (width: Double, height: Double)? = nil,
        fontSize: Double? = nil,
        fontWeight: LabelFontStyle = .medium,
        textAlignment: AnnotationTextAlignment = .leading,
        nudge: PositionNudge? = nil
    ) {
        self.content = content
        self.color = color
        self.horizontalPosition = horizontalPosition
        self.verticalPosition = verticalPosition
        self.anchor = anchor
        self.size = size
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.textAlignment = textAlignment
        self.nudge = nudge
    }
    
    // MARK: - Hashable (manual due to tuple)
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(color)
        hasher.combine(horizontalPosition)
        hasher.combine(verticalPosition)
        hasher.combine(anchor)
        if let size = size {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }
        hasher.combine(fontSize)
        hasher.combine(fontWeight)
        hasher.combine(textAlignment)
        hasher.combine(nudge)
    }
    
    public static func == (lhs: ComponentAnnotation, rhs: ComponentAnnotation) -> Bool {
        lhs.content == rhs.content &&
        lhs.color == rhs.color &&
        lhs.horizontalPosition == rhs.horizontalPosition &&
        lhs.verticalPosition == rhs.verticalPosition &&
        lhs.anchor == rhs.anchor &&
        lhs.size?.width == rhs.size?.width &&
        lhs.size?.height == rhs.size?.height &&
        lhs.fontSize == rhs.fontSize &&
        lhs.fontWeight == rhs.fontWeight &&
        lhs.textAlignment == rhs.textAlignment &&
        lhs.nudge == rhs.nudge
    }
}

// MARK: - ComponentAnnotation Codable Conformance

extension ComponentAnnotation: Codable {
    enum CodingKeys: String, CodingKey {
        case content, color, horizontalPosition, verticalPosition, anchor
        case sizeWidth, sizeHeight, fontSize, fontWeight, textAlignment, nudge
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(AnnotationContent.self, forKey: .content)
        color = try container.decodeIfPresent(LabelColor.self, forKey: .color)
        horizontalPosition = try container.decode(Double.self, forKey: .horizontalPosition)
        verticalPosition = try container.decode(Double.self, forKey: .verticalPosition)
        anchor = try container.decode(AnnotationAnchor.self, forKey: .anchor)
        
        // Decode size tuple from separate keys
        if let width = try container.decodeIfPresent(Double.self, forKey: .sizeWidth),
           let height = try container.decodeIfPresent(Double.self, forKey: .sizeHeight) {
            size = (width: width, height: height)
        } else {
            size = nil
        }
        
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize)
        fontWeight = try container.decode(LabelFontStyle.self, forKey: .fontWeight)
        textAlignment = try container.decode(AnnotationTextAlignment.self, forKey: .textAlignment)
        nudge = try container.decodeIfPresent(PositionNudge.self, forKey: .nudge)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(horizontalPosition, forKey: .horizontalPosition)
        try container.encode(verticalPosition, forKey: .verticalPosition)
        try container.encode(anchor, forKey: .anchor)
        
        // Encode size tuple as separate keys
        if let size = size {
            try container.encode(size.width, forKey: .sizeWidth)
            try container.encode(size.height, forKey: .sizeHeight)
        }
        
        try container.encodeIfPresent(fontSize, forKey: .fontSize)
        try container.encode(fontWeight, forKey: .fontWeight)
        try container.encode(textAlignment, forKey: .textAlignment)
        try container.encodeIfPresent(nudge, forKey: .nudge)
    }
}

// MARK: - ComponentAnnotation Factory Methods

extension ComponentAnnotation {
    /// Create a manufacturer logo annotation
    /// - Parameters:
    ///   - svgName: Name of the SVG file in bundle resources
    ///   - position: Normalized position (h: 0.0-1.0, v: 0.0-1.0)
    ///   - anchor: Which part of the image is at the position
    ///   - size: Optional explicit size; nil = intrinsic
    public static func logo(
        svg svgName: String,
        at position: (h: Double, v: Double),
        anchor: AnnotationAnchor = .center,
        size: (width: Double, height: Double)? = nil
    ) -> ComponentAnnotation {
        ComponentAnnotation(
            content: .svg(name: svgName),
            horizontalPosition: position.h,
            verticalPosition: position.v,
            anchor: anchor,
            size: size
        )
    }
    
    /// Create a logo from asset catalog image
    public static func logo(
        asset assetName: String,
        at position: (h: Double, v: Double),
        anchor: AnnotationAnchor = .center,
        size: (width: Double, height: Double)? = nil
    ) -> ComponentAnnotation {
        ComponentAnnotation(
            content: .assetImage(name: assetName),
            horizontalPosition: position.h,
            verticalPosition: position.v,
            anchor: anchor,
            size: size
        )
    }
    
    /// Create a multi-line text block
    /// - Parameters:
    ///   - text: Text content (supports \n for newlines)
    ///   - color: Text color
    ///   - position: Normalized position (h: 0.0-1.0, v: 0.0-1.0)
    ///   - anchor: Which part of the text block is at the position
    ///   - fontSize: Optional font size; nil = default
    ///   - alignment: Text alignment for multi-line text
    ///   - nudge: Optional fine-grained position adjustment
    public static func textBlock(
        _ text: String,
        color: LabelColor = .black,
        at position: (h: Double, v: Double),
        anchor: AnnotationAnchor = .topLeading,
        fontSize: Double? = nil,
        alignment: AnnotationTextAlignment = .leading,
        nudge: PositionNudge? = nil
    ) -> ComponentAnnotation {
        ComponentAnnotation(
            content: .text(text),
            color: color,
            horizontalPosition: position.h,
            verticalPosition: position.v,
            anchor: anchor,
            fontSize: fontSize,
            textAlignment: alignment,
            nudge: nudge
        )
    }
    
    /// Create an SF Symbol annotation
    public static func symbol(
        _ symbolName: String,
        color: LabelColor = .black,
        at position: (h: Double, v: Double),
        anchor: AnnotationAnchor = .center,
        size: Double? = nil
    ) -> ComponentAnnotation {
        ComponentAnnotation(
            content: .sfSymbol(name: symbolName),
            color: color,
            horizontalPosition: position.h,
            verticalPosition: position.v,
            anchor: anchor,
            fontSize: size
        )
    }
}

// MARK: - Label Configuration

/// Source system that generated a label (used for debugging)
public enum LabelSource: Sendable, Equatable, Hashable {
    case subsection    // Standard subsection tick generation
    case boundary      // Boundary tick injection (begin/end of scale)
    case constant      // ScaleConstant marker
    case scaleName     // Scale name display
    case unknown
}

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
public enum LabelFontStyle: String, Sendable, Equatable, Hashable, Codable {
    case regular
    case medium         // Default: medium weight for better readability
    case italic         // PostScript: NumFontRi (20° right slant)
    case leftItalic     // PostScript: NumFontLi (20° left slant)
    case bold
    case boldItalic
}

/// 2D offset for fine-tuning label positions
/// Positive horizontal = right, negative = left
/// Positive vertical = down, negative = up
public struct Offset: Sendable, Equatable, Hashable {
    public let horizontal: Double
    public let vertical: Double
    
    public init(horizontal: Double = 0, vertical: Double = 0) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    /// No offset
    public static let zero = Offset(horizontal: 0, vertical: 0)
    
    /// Convenience initializers for common adjustments
    public static func left(_ amount: Double) -> Offset {
        Offset(horizontal: -amount, vertical: 0)
    }
    
    public static func right(_ amount: Double) -> Offset {
        Offset(horizontal: amount, vertical: 0)
    }
    
    public static func up(_ amount: Double) -> Offset {
        Offset(horizontal: 0, vertical: -amount)
    }
    
    public static func down(_ amount: Double) -> Offset {
        Offset(horizontal: 0, vertical: amount)
    }
}

/// Color specification for labels
public struct LabelColor: Sendable, Equatable, Hashable, Codable {
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

/// Specifies which parts of a scale should use the custom labelColor
/// - scaleName: Apply color to the scale name label (e.g., "LL00", "CI")
/// - scaleLabels: Apply color to the value labels (e.g., "0.990", "1.0")
/// - scaleTicks: Apply color to the tick marks and scale drawing
public typealias ScaleColorApplication = (scaleName: Bool, scaleLabels: Bool, scaleTicks: Bool)

/// Common preset configurations for ScaleColorApplication
public enum ScaleColorPresets {
    /// Apply color to all elements (scale name, labels, and ticks)
    public static let all: ScaleColorApplication = (scaleName: true, scaleLabels: true, scaleTicks: true)
    
    /// Apply color only to labels (scale name and value labels, but not ticks)
    public static let labelsOnly: ScaleColorApplication = (scaleName: true, scaleLabels: true, scaleTicks: false)
    
    /// Apply color only to ticks (not to any labels)
    public static let ticksOnly: ScaleColorApplication = (scaleName: false, scaleLabels: false, scaleTicks: true)
    
    /// Apply color to scale name only (not to value labels or ticks)
    public static let scaleNameOnly: ScaleColorApplication = (scaleName: true, scaleLabels: false, scaleTicks: false)
    
    /// Apply color to ticks and scale name (but not value labels)
    public static let ticksAndScaleName: ScaleColorApplication = (scaleName: true, scaleLabels: false, scaleTicks: true)
    
    /// No color applied to any element
    public static let none: ScaleColorApplication = (scaleName: false, scaleLabels: false, scaleTicks: false)
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
    
    /// Fine-tuning offset from calculated position (in points)
    public let offset: Offset
    
    /// Source system that generated this label
    public let source: LabelSource
    
    public init(
        text: String,
        position: LabelPosition = .centered,
        fontStyle: LabelFontStyle = .medium,
        color: LabelColor = .black,
        fontSizeMultiplier: Double = 1.0,
        offset: Offset = .zero,
        source: LabelSource = .subsection
    ) {
        self.text = text
        self.position = position
        self.fontStyle = fontStyle
        self.color = color
        self.fontSizeMultiplier = fontSizeMultiplier
        self.offset = offset
        self.source = source
    }
}

// MARK: - Tick Mark Types

/// Defines the type and visual properties of a tick mark
///
/// ## Label Creation Logic (OR Logic)
///
/// The `shouldLabel` property participates in OR logic with `labelLevels` in `ScaleSubsection`:
///
/// ```swift
/// let shouldLabel = subsection.labelLevels.contains(level) || style.shouldLabel
/// ```
///
/// This means labels appear when **EITHER**:
/// 1. `labelLevels.contains(level)` is true (the subsection explicitly includes this level), **OR**
/// 2. `style.shouldLabel` is true (the tick style itself requests labeling)
///
/// ## Important Notes
///
/// - `TickStyle.major` has `shouldLabel: true` by default, meaning major ticks **will** get labels
///   even if `labelLevels: []` is empty
/// - To create truly unlabeled ticks, use `TickStyle.absolutelyNone` with `labelLevels: []`
/// - Other predefined styles (`.medium`, `.minor`, `.tiny`) have `shouldLabel: false`
///
/// ## Examples
///
/// ```swift
/// // Major ticks labeled via style (ignores empty labelLevels):
/// ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [])
/// // Uses default .major style → labels appear due to style.shouldLabel = true
///
/// // Truly unlabeled ticks:
/// // Use TickStyle.absolutelyNone as the first tick style:
/// defaultTickStyles: [.absolutelyNone, .medium, .minor, .tiny]
/// // Combined with labelLevels: [] → no labels appear
/// ```
public struct TickStyle: Sendable, Hashable {
    /// Relative length of the tick (1.0 = full height)
    public let relativeLength: Double
    
    /// Whether this tick should have a label.
    ///
    /// This participates in OR logic with `labelLevels` in `ScaleSubsection`:
    /// - If `true`, labels appear regardless of `labelLevels`
    /// - If `false`, labels only appear if `labelLevels.contains(level)`
    ///
    /// Note: `TickStyle.major` has this set to `true` by default.
    /// Use `TickStyle.absolutelyNone` when you need tick marks that are never labeled.
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
    
    // MARK: - Predefined Tick Styles
    
    /// Major tick mark - full height with labels enabled by default.
    ///
    /// - `relativeLength`: 1.0 (full height)
    /// - `shouldLabel`: **true** (labels appear even with `labelLevels: []`)
    /// - `lineWidth`: 1.0
    public static let major = TickStyle(relativeLength: 1.0, shouldLabel: true, lineWidth: 1.0)
    
    /// Medium tick mark - 75% height without labels.
    public static let medium = TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.85)
    
    /// Minor tick mark - 50% height without labels.
    public static let minor = TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.65)
    
    /// Tiny tick mark - 25% height without labels.
    public static let tiny = TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.40)
    
    /// Major-sized tick that is **never** labeled.
    ///
    /// Use this style when you want tick marks at the major level that should never have labels,
    /// even when combined with `labelLevels: []`. This bypasses the OR logic entirely since
    /// `shouldLabel` is `false`.
    ///
    /// ## When to Use
    /// - Sparse labeling patterns where some major ticks should be unlabeled
    /// - Scales with `labelLevels: []` where you don't want the default `.major` style's
    ///   automatic labeling behavior
    ///
    /// ## Example
    /// ```swift
    /// // Omega scale unlabeled range (0.5-0.7):
    /// ScaleSubsection(
    ///     startValue: 0.5,
    ///     tickIntervals: [0.1, 0.05, 0.02],
    ///     labelLevels: []  // No labels from labelLevels
    /// )
    /// // Use .absolutelyNone as the major style to ensure no labels
    /// ```
    ///
    /// - `relativeLength`: 1.0 (full height, same as `.major`)
    /// - `shouldLabel`: **false** (never produces labels)
    /// - `lineWidth`: 1.0 (same as `.major`)
    public static let absolutelyNone = TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0)
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
        self.labels = label.map { [LabelConfig(text: $0, source: .subsection)] } ?? []
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
