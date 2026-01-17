import Foundation

// MARK: - Split Scale Support

/// Represents a segment of a split scale
///
/// Split scales divide a physical scale into two segments, typically left and right halves,
/// each displaying a different portion of the mathematical range. This concept originates
/// from PostScript slide rule implementations where physical space constraints required
/// dividing scales across the rule length.
///
/// ## Physical Layout
/// - **Left segment**: occupies physical positions 0.0...0.5 (left half of rule)
/// - **Right segment**: occupies physical positions 0.5...1.0 (right half of rule)
///
/// ## Formula Offset
/// The `formulaOffset` parameter specifies where the segment's mathematical range begins
/// relative to the scale's full range. For example, a split D scale might have:
/// - Left segment:  formulaOffset = 0.0, displays values 1-√10 (physical 0.0-0.5)
    /// - Right segment: formulaOffset = 0.0, displays values √10-10 (physical 0.5-1.0)
///
/// ## PostScript Heritage
/// This design matches PostScript slide rule engines where split scales were implemented
/// using offset and length adjustments to map different mathematical ranges onto fixed
/// physical positions.
public enum SplitSegment: Sendable, Equatable, Hashable {
    /// Left segment of a split scale
    /// - Parameter formulaOffset: Starting position in the scale's full mathematical range (typically 0.0)
    case left(formulaOffset: Double)
    
    /// Right segment of a split scale
    /// - Parameter formulaOffset: Starting position in the scale's full mathematical range (typically 0.0)
    case right(formulaOffset: Double)
    
    /// The physical range this segment occupies on the slide rule
    ///
    /// - Left segment: `0.0...0.5` (left half)
    /// - Right segment: `0.5...1.0` (right half)
    public var physicalRange: ClosedRange<Double> {
        switch self {
        case .left:
            return 0.0...0.5
        case .right:
            return 0.5...1.0
        }
    }
    
    /// Zero-based index of this segment
    ///
    /// - Left segment: `0`
    /// - Right segment: `1`
    public var segmentIndex: Int {
        switch self {
        case .left:
            return 0
        case .right:
            return 1
        }
    }
    
    /// The formula offset for this segment
    public var formulaOffset: Double {
        switch self {
        case .left(let offset), .right(let offset):
            return offset
        }
    }
}

// MARK: - Label Configuration (Future Enhancement)

/// Configuration for manual label suppression and density control near split boundaries.
///
/// ## Purpose
/// Split scales often have labels that crowd or overlap at their junction point.
/// This struct provides manual configuration to:
/// - Suppress specific labels that cause visual collision
/// - Reduce label density in specific physical regions
/// - Offset labels away from split boundaries
///
/// ## Design Philosophy
/// - Manual configuration, NOT automatic collision detection
/// - Scale designers explicitly specify which labels to suppress
/// - Follows PostScript engine heritage where scale definitions include label customization
///
/// ## Status: SKELETON
/// This struct defines the intended API. Implementation pending.
///
/// ## Reference
/// See `split-scales-implementation-plan.md` Section 5 for full specification.
public struct LabelConfiguration: Sendable, Equatable {
    
    // MARK: - Label Suppression
    
    /// Specific label values to suppress (not render) on this scale.
    ///
    /// ## Use Case
    /// At split boundaries, adjacent scale segments may have labels that
    /// visually overlap. Rather than automatic detection, scale designers
    /// manually specify which labels to suppress.
    ///
    /// ## Example
    /// ```swift
    /// // Suppress "6" label on Θ₁ scale (overlaps with Θ₂ start)
    /// LabelConfiguration(suppressedLabels: ["6"])
    /// ```
    ///
    /// ## Implementation Notes (TODO)
    /// - Matching should be exact string comparison
    /// - Consider supporting regex patterns for range suppression
    /// - Should work with both numeric and text labels
    public let suppressedLabels: Set<String>?
    
    // MARK: - Density Override
    
    /// Regions where label density should be reduced.
    ///
    /// ## Use Case
    /// Near split boundaries, even without direct collision, labels may be
    /// too dense for comfortable reading. This allows reducing density
    /// in specific normalized position ranges.
    ///
    /// ## Example
    /// ```swift
    /// // Reduce density in last 20% of left segment
    /// LabelConfiguration(
    ///     densityOverride: [
    ///         DensityOverride(range: 0.8...1.0, density: .sparse)
    ///     ]
    /// )
    /// ```
    ///
    /// ## Implementation Notes (TODO)
    /// - `range` is normalized position (0.0...1.0) within scale's physical extent
    /// - For split scales, this is relative to the segment, not full scale
    /// - Multiple overrides can be specified for different regions
    public let densityOverride: [DensityOverride]?
    
    // MARK: - Boundary Offset
    
    /// Offset (in points) to push labels away from split boundary.
    ///
    /// ## Use Case
    /// When labels are close to but not overlapping the split boundary,
    /// a small offset can improve visual separation without suppression.
    ///
    /// ## Example
    /// ```swift
    /// // Offset labels 2mm away from boundary
    /// LabelConfiguration(boundaryOffset: 2.0 * 2.83464567) // mm to points
    /// ```
    ///
    /// ## Implementation Notes (TODO)
    /// - Positive offset pushes labels toward scale center
    /// - Only affects labels within a threshold distance of boundary
    /// - Should consider left vs right segment direction
    public let boundaryOffset: Double?
    
    // MARK: - Initialization
    
    /// Creates a label configuration with the specified options.
    ///
    /// All parameters are optional; `nil` means no modification for that aspect.
    public init(
        suppressedLabels: Set<String>? = nil,
        densityOverride: [DensityOverride]? = nil,
        boundaryOffset: Double? = nil
    ) {
        self.suppressedLabels = suppressedLabels
        self.densityOverride = densityOverride
        self.boundaryOffset = boundaryOffset
    }
    
    // MARK: - Query Methods (Stubs)
    
    /// Checks if a label should be rendered at the given position.
    ///
    /// ## Parameters
    /// - label: The label text to check
    /// - normalizedPosition: Position within scale (0.0...1.0)
    ///
    /// ## Returns
    /// `true` if label should be rendered, `false` if suppressed
    ///
    /// ## Implementation Notes (TODO)
    /// - Check suppressedLabels set first
    /// - If not suppressed, check density override regions
    /// - Return true if no configuration affects this label
    public func shouldRenderLabel(_ label: String, at normalizedPosition: Double) -> Bool {
        // STUB: Always returns true until implemented
        // TODO: Implement suppression and density checks
        return true
    }
    
    /// Calculates adjusted position for a label near the boundary.
    ///
    /// ## Parameters
    /// - originalPosition: Original label position (0.0...1.0)
    /// - isLeftSegment: Whether this is the left segment of a split
    ///
    /// ## Returns
    /// Adjusted position if offset applies, otherwise original position
    ///
    /// ## Implementation Notes (TODO)
    /// - Only apply offset within threshold of boundary
    /// - Direction depends on segment (left pushes left, right pushes right)
    public func adjustedPosition(
        for originalPosition: Double,
        isLeftSegment: Bool
    ) -> Double {
        // STUB: Returns original position until implemented
        // TODO: Apply boundaryOffset based on proximity to edge
        return originalPosition
    }
}

// MARK: - Supporting Types

/// Density level for label rendering.
///
/// ## Implementation Notes (TODO)
/// - Define what each level means in terms of skip patterns
/// - Consider: `.normal` = every label, `.sparse` = every other, `.minimal` = majors only
public enum LabelDensity: String, Sendable, Equatable {
    case normal   // Default: render all labels
    case sparse   // Reduced: skip some intermediate labels
    case minimal  // Minimal: only render primary/major labels
}

/// Region-specific density override configuration.
///
/// ## Implementation Notes (TODO)
/// - Used by LabelConfiguration.densityOverride
/// - Range is normalized (0.0...1.0) within the scale segment
public struct DensityOverride: Sendable, Equatable {
    /// Normalized position range where override applies (0.0...1.0)
    public let range: ClosedRange<Double>
    
    /// Density level to use within this range
    public let density: LabelDensity
    
    public init(range: ClosedRange<Double>, density: LabelDensity) {
        self.range = range
        self.density = density
    }
}

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
    
    /// Optional display name override (e.g., "W2" instead of canonical "Sq2")
    /// Used when an alias is specified in the definition string
    public let displayName: String?
    
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
    
    /// Physical height of the scale in points
    public let height: Distance
    
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
    
    /// Optional color for labels
    public let labelColor: LabelColor?
    
    /// Specifies which parts of the scale should use the labelColor
    public let colorApplication: ScaleColorApplication
    
    /// Optional constants to mark on the scale (like π, e)
    public let constants: [ScaleConstant]
    
    /// Whether to render a horizontal baseline for this scale
    public let showBaseline: Bool
    
    /// Whether to render a separator line below this scale (from `|` symbol in definition)
    public let hasBottomSeparator: Bool
    
    /// Typography adjustment for formula text spacing
    /// - 1.0 = normal spacing (no modification)
    /// - < 1.0 = tighter/condensed spacing
    /// - > 1.0 = looser/expanded spacing
    public let formulaTracking: Double
    
    /// Whether to suppress the label at the beginning of the scale range
    public let suppressBeginBoundaryLabel: Bool
    
    /// Whether to suppress the tick mark at the beginning of the scale range
    public let suppressBeginBoundaryTick: Bool
    
    /// Whether to suppress the label at the end of the scale range
    public let suppressEndBoundaryLabel: Bool
    
    /// Whether to suppress the tick mark at the end of the scale range
    public let suppressEndBoundaryTick: Bool
    
    /// Optional split segment configuration
    ///
    /// When `nil`, the scale occupies the full physical width (0.0...1.0).
    /// When set, the scale represents only the specified segment (left or right half).
    ///
    /// - Note: This property enables split scale support without breaking existing code.
    ///   All existing scales default to `nil` (full width).
    public let splitSegment: SplitSegment?
    
    /// Whether to suppress rendering the scale name label (left margin)
    /// When true, the name is still stored (for use in previews/debugging) but not rendered on the scale.
    /// DEPRECATED: Use `scaleNameMargin = .none` instead
    public let suppressScaleNameLabel: Bool
    
    /// Whether to suppress rendering the formula label (right margin)
    /// When true, the formula is still stored (for use in previews/debugging) but not rendered on the scale.
    /// DEPRECATED: Use `formulaMargin = .none` instead
    public let suppressFormulaLabel: Bool
    
    /// Which margin the scale name appears in (nil = use rule default, typically .left)
    /// Examples:
    /// - `.left`: Name appears in left margin (traditional)
    /// - `.right`: Name appears in right margin (Graphoplex style)
    /// - `.none`: Name is suppressed
    /// - `nil`: Use rule-level default (RuleDisplaySettings.defaultScaleNameMargin)
    public let scaleNameMargin: MarginSide?
    
    /// Which margin the formula appears in (nil = use rule default, typically .right)
    /// Examples:
    /// - `.right`: Formula appears in right margin (traditional)
    /// - `.left`: Formula appears in left margin
    /// - `.none`: Formula is suppressed
    /// - `nil`: Use rule-level default (RuleDisplaySettings.defaultFormulaMargin)
    public let formulaMargin: MarginSide?
    
    /// Custom annotations for the left margin (replaces or supplements scale name)
    /// If non-empty, these are rendered instead of the scale name.
    /// If empty/nil and suppressScaleNameLabel is false, the scale name is rendered.
    public let leftAnnotations: [MarginAnnotation]
    
    /// Custom annotations for the right margin (replaces or supplements formula)
    /// If non-empty, these are rendered instead of the formula.
    /// If empty/nil and suppressFormulaLabel is false, the formula is rendered.
    public let rightAnnotations: [MarginAnnotation]
    
    /// Position nudge for scale name label (for fine-tuning layout)
    /// Applied as an offset to the rendered scale name position
    public let nameNudge: PositionNudge?
    
    /// Position nudge for formula label (for fine-tuning layout)
    /// Applied as an offset to the rendered formula position
    public let formulaNudge: PositionNudge?
    
    public init(
        name: String,
        formula: String = ScaleDefinition.defaultFormula,
        function: any ScaleFunction,
        beginValue: ScaleValue,
        endValue: ScaleValue,
        scaleLengthInPoints: Distance,
        height: Distance = 36.0,
        layout: ScaleLayout,
        tickDirection: TickDirection = .up,
        subsections: [ScaleSubsection] = [],
        defaultTickStyles: [TickStyle] = [.major, .medium, .minor, .tiny],
        labelFormatter: (@Sendable (ScaleValue) -> String)? = nil,
        labelColor: LabelColor? = nil,
        colorApplication: ScaleColorApplication = ScaleColorPresets.all,
        constants: [ScaleConstant] = [],
        showBaseline: Bool = false,
        hasBottomSeparator: Bool = false,
        formulaTracking: Double = 1.0,
        displayName: String? = nil,
        splitSegment: SplitSegment? = nil,
        suppressBeginBoundaryLabel: Bool = false,
        suppressBeginBoundaryTick: Bool = false,
        suppressEndBoundaryLabel: Bool = false,
        suppressEndBoundaryTick: Bool = false,
        suppressScaleNameLabel: Bool = false,
        suppressFormulaLabel: Bool = false,
        scaleNameMargin: MarginSide? = nil,
        formulaMargin: MarginSide? = nil,
        leftAnnotations: [MarginAnnotation] = [],
        rightAnnotations: [MarginAnnotation] = [],
        nameNudge: PositionNudge? = nil,
        formulaNudge: PositionNudge? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.formula = formula
        self.function = function
        self.beginValue = beginValue
        self.endValue = endValue
        self.scaleLengthInPoints = scaleLengthInPoints
        self.height = height
        self.layout = layout
        self.tickDirection = tickDirection
        self.subsections = subsections
        self.defaultTickStyles = defaultTickStyles
        self.labelFormatter = labelFormatter
        self.labelColor = labelColor
        self.colorApplication = colorApplication
        self.constants = constants
        self.showBaseline = showBaseline
        self.hasBottomSeparator = hasBottomSeparator
        self.formulaTracking = formulaTracking
        self.splitSegment = splitSegment
        self.suppressBeginBoundaryLabel = suppressBeginBoundaryLabel
        self.suppressBeginBoundaryTick = suppressBeginBoundaryTick
        self.suppressEndBoundaryLabel = suppressEndBoundaryLabel
        self.suppressEndBoundaryTick = suppressEndBoundaryTick
        self.suppressScaleNameLabel = suppressScaleNameLabel
        self.suppressFormulaLabel = suppressFormulaLabel
        self.scaleNameMargin = scaleNameMargin
        self.formulaMargin = formulaMargin
        self.leftAnnotations = leftAnnotations
        self.rightAnnotations = rightAnnotations
        self.nameNudge = nameNudge
        self.formulaNudge = formulaNudge
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
    private var displayName: String?
    private var formula: String = ScaleDefinition.defaultFormula
    private var function: (any ScaleFunction)?
    private var beginValue: ScaleValue = 1.0
    private var endValue: ScaleValue = 10.0
    private var scaleLengthInPoints: Distance = 250.0
    private var height: Distance = 36.0
    private var layout: ScaleLayout = .linear
    private var tickDirection: TickDirection = .up
    private var subsections: [ScaleSubsection] = []
    private var defaultTickStyles: [TickStyle] = [.major, .medium, .minor, .tiny]
    private var labelFormatter: (@Sendable (ScaleValue) -> String)?
    private var labelColor: LabelColor?
    private var colorApplication: ScaleColorApplication = ScaleColorPresets.all
    private var constants: [ScaleConstant] = []
    private var showBaseline: Bool = false
    private var hasBottomSeparator: Bool = false
    private var formulaTracking: Double = 1.0
    private var splitSegment: SplitSegment?
    private var suppressBeginBoundaryLabel: Bool = false
    private var suppressBeginBoundaryTick: Bool = false
    private var suppressEndBoundaryLabel: Bool = false
    private var suppressEndBoundaryTick: Bool = false
    private var suppressScaleNameLabel: Bool = false
    private var suppressFormulaLabel: Bool = false
    private var scaleNameMargin: MarginSide?
    private var formulaMargin: MarginSide?
    private var leftAnnotations: [MarginAnnotation] = []
    private var rightAnnotations: [MarginAnnotation] = []
    private var nameNudge: PositionNudge?
    private var formulaNudge: PositionNudge?
    
    public init() {}
    
    /// Initialize ScaleBuilder from existing ScaleDefinition for modification
    /// Allows fluent modification of existing scale definitions
    /// - Parameter definition: Existing scale definition to clone
    public init(from definition: ScaleDefinition) {
        self.name = definition.name
        self.displayName = definition.displayName
        self.formula = definition.formula
        self.function = definition.function
        self.beginValue = definition.beginValue
        self.endValue = definition.endValue
        self.scaleLengthInPoints = definition.scaleLengthInPoints
        self.height = definition.height
        self.layout = definition.layout
        self.tickDirection = definition.tickDirection
        self.subsections = definition.subsections
        self.defaultTickStyles = definition.defaultTickStyles
        self.labelFormatter = definition.labelFormatter
        self.labelColor = definition.labelColor
        self.colorApplication = definition.colorApplication
        self.constants = definition.constants
        self.showBaseline = definition.showBaseline
        self.hasBottomSeparator = definition.hasBottomSeparator
        self.formulaTracking = definition.formulaTracking
        self.splitSegment = definition.splitSegment
        self.suppressBeginBoundaryLabel = definition.suppressBeginBoundaryLabel
        self.suppressBeginBoundaryTick = definition.suppressBeginBoundaryTick
        self.suppressEndBoundaryLabel = definition.suppressEndBoundaryLabel
        self.suppressEndBoundaryTick = definition.suppressEndBoundaryTick
        self.suppressScaleNameLabel = definition.suppressScaleNameLabel
        self.suppressFormulaLabel = definition.suppressFormulaLabel
        self.scaleNameMargin = definition.scaleNameMargin
        self.formulaMargin = definition.formulaMargin
        self.leftAnnotations = definition.leftAnnotations
        self.rightAnnotations = definition.rightAnnotations
        self.nameNudge = definition.nameNudge
        self.formulaNudge = definition.formulaNudge
    }
    
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
    
    public func withLabelColor(_ color: LabelColor) -> ScaleBuilder {
        var copy = self
        copy.labelColor = color
        return copy
    }
    
    public func withColorApplication(_ application: ScaleColorApplication) -> ScaleBuilder {
        var copy = self
        copy.colorApplication = application
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
    
    public func withDisplayName(_ displayName: String?) -> ScaleBuilder {
        var copy = self
        copy.displayName = displayName
        return copy
    }
    
    /// Sets the split segment configuration for this scale
    /// - Parameter segment: The split segment (left or right), or nil for full-width scale
    /// - Returns: Updated builder
    public func withSplitSegment(_ segment: SplitSegment?) -> ScaleBuilder {
        var copy = self
        copy.splitSegment = segment
        return copy
    }
    /// Convenience: Configure as left segment of a 50/50 split scale.
    /// - Returns: Builder configured with `.left(formulaOffset: 0.0)`
    /// - Note: Left segment renders in physical range 0.0...0.5
    public func leftSegment() -> ScaleBuilder {
        return withSplitSegment(.left(formulaOffset: 0.0))
    }
    
    /// Convenience: Configure as right segment of a 50/50 split scale.
    /// - Returns: Builder configured with `.right(formulaOffset: 0.0)`
    /// - Note: Right segment renders in physical range 0.5...1.0
    /// - Note: Uses `0.0` offset because modern scales are typically defined as independent segments
    public func rightSegment() -> ScaleBuilder {
        #if DEBUG
        print("[SplitScaleDebug] ScaleBuilder.rightSegment() called - setting formulaOffset to 0.0")
        #endif
        return withSplitSegment(.right(formulaOffset: 0.0))
    }

    public func withSuppressBeginBoundaryLabel(_ suppress: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.suppressBeginBoundaryLabel = suppress
        return copy
    }

    public func withSuppressBeginBoundaryTick(_ suppress: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.suppressBeginBoundaryTick = suppress
        return copy
    }

    public func withSuppressEndBoundaryLabel(_ suppress: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.suppressEndBoundaryLabel = suppress
        return copy
    }

    public func withSuppressEndBoundaryTick(_ suppress: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.suppressEndBoundaryTick = suppress
        return copy
    }
    
    /// Suppress rendering the scale name label in the left margin
    /// The name is still stored for use in previews/debugging, just not rendered on the scale
    public func withSuppressScaleNameLabel(_ suppress: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.suppressScaleNameLabel = suppress
        return copy
    }
    
    /// Convenience: Suppress the scale name label
    public func suppressScaleName() -> ScaleBuilder {
        return withSuppressScaleNameLabel(true)
    }
    
    /// Suppress rendering the formula label in the right margin
    /// The formula is still stored for use in previews/debugging, just not rendered on the scale
    public func withSuppressFormulaLabel(_ suppress: Bool = true) -> ScaleBuilder {
        var copy = self
        copy.suppressFormulaLabel = suppress
        return copy
    }
    
    /// Convenience: Suppress the formula label
    public func suppressFormula() -> ScaleBuilder {
        return withSuppressFormulaLabel(true)
    }
    
    // MARK: - Margin Side Control
    
    /// Set which margin the scale name appears in
    /// - Parameter margin: `.left` (traditional), `.right` (Graphoplex style), or `.none` (suppressed)
    /// - Returns: Updated builder
    /// - Note: `nil` defers to rule-level `RuleDisplaySettings.defaultScaleNameMargin`
    public func withScaleNameMargin(_ margin: MarginSide?) -> ScaleBuilder {
        var copy = self
        copy.scaleNameMargin = margin
        return copy
    }
    
    /// Convenience: Place scale name in left margin (traditional)
    public func scaleNameOnLeft() -> ScaleBuilder {
        return withScaleNameMargin(.left)
    }
    
    /// Convenience: Place scale name in right margin (Graphoplex style)
    public func scaleNameOnRight() -> ScaleBuilder {
        return withScaleNameMargin(.right)
    }
    
    /// Set which margin the formula appears in
    /// - Parameter margin: `.right` (traditional), `.left`, or `.none` (suppressed)
    /// - Returns: Updated builder
    /// - Note: `nil` defers to rule-level `RuleDisplaySettings.defaultFormulaMargin`
    public func withFormulaMargin(_ margin: MarginSide?) -> ScaleBuilder {
        var copy = self
        copy.formulaMargin = margin
        return copy
    }
    
    /// Convenience: Place formula in right margin (traditional)
    public func formulaOnRight() -> ScaleBuilder {
        return withFormulaMargin(.right)
    }
    
    /// Convenience: Place formula in left margin
    public func formulaOnLeft() -> ScaleBuilder {
        return withFormulaMargin(.left)
    }
    
    // MARK: - Label Position Nudge
    
    /// Set the position nudge for the scale name label
    /// - Parameter nudge: The position nudge to apply
    /// - Returns: Updated builder
    public func withNameNudge(_ nudge: PositionNudge?) -> ScaleBuilder {
        var copy = self
        copy.nameNudge = nudge
        return copy
    }
    
    /// Set the position nudge for the formula label
    /// - Parameter nudge: The position nudge to apply
    /// - Returns: Updated builder
    public func withFormulaNudge(_ nudge: PositionNudge?) -> ScaleBuilder {
        var copy = self
        copy.formulaNudge = nudge
        return copy
    }
    
    // MARK: - Margin Annotations
    
    /// Set left margin annotations (replaces scale name)
    public func withLeftAnnotations(_ annotations: [MarginAnnotation]) -> ScaleBuilder {
        var copy = self
        copy.leftAnnotations = annotations
        return copy
    }
    
    /// Add a single left margin annotation
    public func addLeftAnnotation(_ annotation: MarginAnnotation) -> ScaleBuilder {
        var copy = self
        copy.leftAnnotations.append(annotation)
        return copy
    }
    
    /// Add a simple text annotation to the left margin
    public func addLeftAnnotation(
        text: String,
        color: LabelColor = .black,
        offset: Offset = .zero,
        fontSizeMultiplier: Double = 1.0
    ) -> ScaleBuilder {
        return addLeftAnnotation(MarginAnnotation(
            text: text,
            color: color,
            offset: offset,
            fontSizeMultiplier: fontSizeMultiplier
        ))
    }
    
    /// Set right margin annotations (replaces formula)
    public func withRightAnnotations(_ annotations: [MarginAnnotation]) -> ScaleBuilder {
        var copy = self
        copy.rightAnnotations = annotations
        return copy
    }
    
    /// Add a single right margin annotation
    public func addRightAnnotation(_ annotation: MarginAnnotation) -> ScaleBuilder {
        var copy = self
        copy.rightAnnotations.append(annotation)
        return copy
    }
    
    /// Add a simple text annotation to the right margin
    public func addRightAnnotation(
        text: String,
        color: LabelColor = .black,
        offset: Offset = .zero,
        fontSizeMultiplier: Double = 1.0
    ) -> ScaleBuilder {
        return addRightAnnotation(MarginAnnotation(
            text: text,
            color: color,
            offset: offset,
            fontSizeMultiplier: fontSizeMultiplier
        ))
    }
    
    /// Clear all left margin annotations
    public func clearLeftAnnotations() -> ScaleBuilder {
        var copy = self
        copy.leftAnnotations = []
        return copy
    }
    
    /// Clear all right margin annotations
    public func clearRightAnnotations() -> ScaleBuilder {
        var copy = self
        copy.rightAnnotations = []
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
            colorApplication: colorApplication,
            constants: constants,
            showBaseline: showBaseline,
            formulaTracking: formulaTracking,
            displayName: displayName,
            splitSegment: splitSegment,
            suppressBeginBoundaryLabel: suppressBeginBoundaryLabel,
            suppressBeginBoundaryTick: suppressBeginBoundaryTick,
            suppressEndBoundaryLabel: suppressEndBoundaryLabel,
            suppressEndBoundaryTick: suppressEndBoundaryTick,
            suppressScaleNameLabel: suppressScaleNameLabel,
            suppressFormulaLabel: suppressFormulaLabel,
            scaleNameMargin: scaleNameMargin,
            formulaMargin: formulaMargin,
            leftAnnotations: leftAnnotations,
            rightAnnotations: rightAnnotations,
            nameNudge: nameNudge,
            formulaNudge: formulaNudge
        )
    }
}

// MARK: - Common Label Formatters

public enum StandardLabelFormatter {
    /// Standard integer formatting (rounds to nearest integer)
    public static let integer: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        return String(Int(value.rounded()))
    }
    
    /// C/D scale first subsection formatter (PostScript-compatible)
    /// For integer values: shows the integer (1, 2)
    /// For decimal values: shows just the tenths digit (1.5 → "5", 1.3 → "3")
    /// Matches PostScript: plabel uses {.5 add cvi}, slabel uses {1 sub 10 mul .5 add cvi}
    public static let cScaleFirstSubsection: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        let rounded = value.rounded()
        // Check if value is effectively an integer
        if abs(value - rounded) < 0.001 {
            return String(Int(rounded))
        } else {
            // Extract the tenths digit: (value - floor(value)) * 10, rounded
            // This matches PostScript: {1 sub 10 mul .5 add cvi} for slabel
            let floor = value.rounded(.down)
            let tenths = ((value - floor) * 10).rounded()
            return String(Int(tenths))
        }
    }
    
    /// One decimal place
    public static let oneDecimal: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        return String(format: "%.1f", value)
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
        guard value.isFinite else { return "—" }
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
        // Guard against invalid values for log
        guard value > 0 && value.isFinite else {
            return "—"  // Em dash for invalid values
        }
        
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
        guard value.isFinite && value > 0 else { return "—" }
        
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
                fontSizeMultiplier: 1.25,
                offset: Offset(horizontal: 2, vertical: -2),
                source: .subsection
            ),
            // Left label: cosine (complementary) in italic red (PostScript: NumFontLi)
            LabelConfig(
                text: String(Int(complementary.rounded())),
                position: .left,
                fontStyle: .italic,
                color: .red,
                fontSizeMultiplier: 1.25,
                offset: Offset(horizontal: -2, vertical: -2),
                source: .subsection
            )
        ]
    }
    
    /// Create a single-label configuration with specified position and style
    public static func singleLabel(
        _ formatter: @escaping @Sendable (ScaleValue) -> String,
        position: LabelPosition = .centered,
        fontStyle: LabelFontStyle = .medium,
        color: LabelColor = .black,
        offset: Offset = .zero
    ) -> @Sendable (ScaleValue) -> [LabelConfig] {
        return { value in
            [LabelConfig(
                text: formatter(value),
                position: position,
                fontStyle: fontStyle,
                color: color,
                offset: offset,
                source: .subsection
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
        // Determine if this is an inverted scale (beginValue > endValue)
        let isInverted = beginValue > endValue
        
        var active: ScaleSubsection? = nil
        
        if isInverted {
            // For inverted scales, subsections are sorted in DESCENDING order
            // (largest startValue first, smallest last)
            // We want the subsection where value <= startValue
            for subsection in subsections {
                if value <= subsection.startValue {
                    active = subsection
                } else {
                    // Found a subsection with startValue smaller than our value
                    // The previous subsection (now in 'active') is the correct one
                    break
                }
            }
        } else {
            // For normal scales, subsections are sorted in ASCENDING order
            // We want the subsection where value >= startValue
            for subsection in subsections {
                if value >= subsection.startValue {
                    active = subsection
                } else {
                    // Subsections assumed to be sorted by startValue
                    break
                }
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

// MARK: - Split Scale Physical Position

extension ScaleDefinition {
    /// Convert normalized position (0.0...1.0) to physical position
    /// accounting for split segments.
    ///
    /// For regular scales: normalizedPosition × length
    /// For split scales: maps to the segment's fractional physical range
    ///
    /// - Parameter normalizedPosition: Position within this scale (0.0...1.0)
    /// - Returns: Physical position in points
    public func physicalPosition(from normalizedPosition: Double) -> Double {
        guard let segment = splitSegment else {
            // Regular scale: full width
            return normalizedPosition * scaleLengthInPoints
        }
        
        let range = segment.physicalRange
        let rangeWidth = range.upperBound - range.lowerBound
        let physicalOffset = range.lowerBound * scaleLengthInPoints
        
        #if DEBUG && SPLIT_SCALES
        print("[SplitScale] \(name): normalizedPos=\(normalizedPosition) -> physicalOffset=\(physicalOffset) + \(normalizedPosition) * \(rangeWidth) * \(scaleLengthInPoints) = \(physicalOffset + (normalizedPosition * rangeWidth * scaleLengthInPoints))")
        #endif
        
        return physicalOffset + (normalizedPosition * rangeWidth * scaleLengthInPoints)
    }
    
    /// Convert normalized position to fraction of total scale width
    /// accounting for split segments.
    ///
    /// This is a convenience for renderers that work in normalized coordinates.
    ///
    /// - Parameter normalizedPosition: Position within this scale (0.0...1.0)
    /// - Returns: Fraction of total scale width (0.0...1.0)
    public func physicalFraction(from normalizedPosition: Double) -> Double {
        guard let segment = splitSegment else {
            // Regular scale: maps directly
            return normalizedPosition
        }
        
        let range = segment.physicalRange
        let rangeWidth = range.upperBound - range.lowerBound
        
        #if DEBUG && SPLIT_SCALES
        let result = range.lowerBound + (normalizedPosition * rangeWidth)
        print("[SplitScale] \(name): physicalFraction normalizedPos=\(normalizedPosition) -> \(result)")
        #endif
        
        return range.lowerBound + (normalizedPosition * rangeWidth)
    }
}
