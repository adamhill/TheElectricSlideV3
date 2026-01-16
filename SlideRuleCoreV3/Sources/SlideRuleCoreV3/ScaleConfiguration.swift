//  ScaleConfiguration.swift
//  SlideRuleCoreV3
//
//  Created by AI Assistant on 2025-01-XX.
//
//  Phase 1: Core position types for the fluent configuration API
//  See swift-docs/scale-configuration-api-design.md for full design

import Foundation

// MARK: - Scale Identification

/// Type-safe scale identification
///
/// Provides both type-safe enum cases for common scales and string-based
/// identification for custom or unusual scales.
///
/// ## Usage
/// ```swift
/// let key1: ScaleKey = .c           // Type-safe C scale
/// let key2: ScaleKey = .named("Θ₁") // Custom scale by name
/// let key3: ScaleKey = .matching(pattern: "LL[0-3]")  // Regex pattern
/// ```
public enum ScaleKey: Hashable, Sendable {
    // MARK: - Primary Scales
    case c, d, cf, df, ci, di, cif, dif
    case a, b, k
    case l, ln
    
    // MARK: - Trig Scales
    case s, st, t, t1, t2, p
    
    // MARK: - Log-Log Scales
    case ll0, ll1, ll2, ll3
    case ll00, ll01, ll02, ll03
    
    // MARK: - Specialty Scales
    case sq1, sq2, w1, w2
    case theta1, theta2
    
    // MARK: - Flexible Matchers
    
    /// Match a specific scale by its canonical name
    case named(String)
    
    /// Match scales whose names match a regex pattern
    case matching(pattern: String)
    
    // MARK: - Canonical Name
    
    /// The canonical string name for this key
    public var canonicalName: String? {
        switch self {
        case .c: return "C"
        case .d: return "D"
        case .cf: return "CF"
        case .df: return "DF"
        case .ci: return "CI"
        case .di: return "DI"
        case .cif: return "CIF"
        case .dif: return "DIF"
        case .a: return "A"
        case .b: return "B"
        case .k: return "K"
        case .l: return "L"
        case .ln: return "Ln"
        case .s: return "S"
        case .st: return "ST"
        case .t: return "T"
        case .t1: return "T1"
        case .t2: return "T2"
        case .p: return "P"
        case .ll0: return "LL0"
        case .ll1: return "LL1"
        case .ll2: return "LL2"
        case .ll3: return "LL3"
        case .ll00: return "LL00"
        case .ll01: return "LL01"
        case .ll02: return "LL02"
        case .ll03: return "LL03"
        case .sq1: return "Sq1"
        case .sq2: return "Sq2"
        case .w1: return "W1"
        case .w2: return "W2"
        case .theta1: return "Θ₁"
        case .theta2: return "Θ₂"
        case .named(let name): return name
        case .matching: return nil  // Patterns don't have a single canonical name
        }
    }
    
    /// Check if this key matches a given scale name
    public func matches(_ scaleName: String) -> Bool {
        switch self {
        case .matching(let pattern):
            // Regex matching
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(scaleName.startIndex..., in: scaleName)
            return regex.firstMatch(in: scaleName, options: [], range: range) != nil
            
        case .named(let name):
            return scaleName.caseInsensitiveCompare(name) == .orderedSame
            
        default:
            // Type-safe keys match their canonical name
            guard let canonical = canonicalName else { return false }
            return scaleName.caseInsensitiveCompare(canonical) == .orderedSame
        }
    }
}

// MARK: - ScaleKey Codable

extension ScaleKey: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    private enum KeyType: String, Codable {
        case c, d, cf, df, ci, di, cif, dif
        case a, b, k
        case l, ln
        case s, st, t, t1, t2, p
        case ll0, ll1, ll2, ll3
        case ll00, ll01, ll02, ll03
        case sq1, sq2, w1, w2
        case theta1, theta2
        case named, matching
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(KeyType.self, forKey: .type)
        
        switch type {
        case .c: self = .c
        case .d: self = .d
        case .cf: self = .cf
        case .df: self = .df
        case .ci: self = .ci
        case .di: self = .di
        case .cif: self = .cif
        case .dif: self = .dif
        case .a: self = .a
        case .b: self = .b
        case .k: self = .k
        case .l: self = .l
        case .ln: self = .ln
        case .s: self = .s
        case .st: self = .st
        case .t: self = .t
        case .t1: self = .t1
        case .t2: self = .t2
        case .p: self = .p
        case .ll0: self = .ll0
        case .ll1: self = .ll1
        case .ll2: self = .ll2
        case .ll3: self = .ll3
        case .ll00: self = .ll00
        case .ll01: self = .ll01
        case .ll02: self = .ll02
        case .ll03: self = .ll03
        case .sq1: self = .sq1
        case .sq2: self = .sq2
        case .w1: self = .w1
        case .w2: self = .w2
        case .theta1: self = .theta1
        case .theta2: self = .theta2
        case .named:
            let value = try container.decode(String.self, forKey: .value)
            self = .named(value)
        case .matching:
            let value = try container.decode(String.self, forKey: .value)
            self = .matching(pattern: value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .c: try container.encode(KeyType.c, forKey: .type)
        case .d: try container.encode(KeyType.d, forKey: .type)
        case .cf: try container.encode(KeyType.cf, forKey: .type)
        case .df: try container.encode(KeyType.df, forKey: .type)
        case .ci: try container.encode(KeyType.ci, forKey: .type)
        case .di: try container.encode(KeyType.di, forKey: .type)
        case .cif: try container.encode(KeyType.cif, forKey: .type)
        case .dif: try container.encode(KeyType.dif, forKey: .type)
        case .a: try container.encode(KeyType.a, forKey: .type)
        case .b: try container.encode(KeyType.b, forKey: .type)
        case .k: try container.encode(KeyType.k, forKey: .type)
        case .l: try container.encode(KeyType.l, forKey: .type)
        case .ln: try container.encode(KeyType.ln, forKey: .type)
        case .s: try container.encode(KeyType.s, forKey: .type)
        case .st: try container.encode(KeyType.st, forKey: .type)
        case .t: try container.encode(KeyType.t, forKey: .type)
        case .t1: try container.encode(KeyType.t1, forKey: .type)
        case .t2: try container.encode(KeyType.t2, forKey: .type)
        case .p: try container.encode(KeyType.p, forKey: .type)
        case .ll0: try container.encode(KeyType.ll0, forKey: .type)
        case .ll1: try container.encode(KeyType.ll1, forKey: .type)
        case .ll2: try container.encode(KeyType.ll2, forKey: .type)
        case .ll3: try container.encode(KeyType.ll3, forKey: .type)
        case .ll00: try container.encode(KeyType.ll00, forKey: .type)
        case .ll01: try container.encode(KeyType.ll01, forKey: .type)
        case .ll02: try container.encode(KeyType.ll02, forKey: .type)
        case .ll03: try container.encode(KeyType.ll03, forKey: .type)
        case .sq1: try container.encode(KeyType.sq1, forKey: .type)
        case .sq2: try container.encode(KeyType.sq2, forKey: .type)
        case .w1: try container.encode(KeyType.w1, forKey: .type)
        case .w2: try container.encode(KeyType.w2, forKey: .type)
        case .theta1: try container.encode(KeyType.theta1, forKey: .type)
        case .theta2: try container.encode(KeyType.theta2, forKey: .type)
        case .named(let value):
            try container.encode(KeyType.named, forKey: .type)
            try container.encode(value, forKey: .value)
        case .matching(let pattern):
            try container.encode(KeyType.matching, forKey: .type)
            try container.encode(pattern, forKey: .value)
        }
    }
}

// MARK: - Position Nudge

/// Fine-grained position adjustment in four directions
///
/// Nudges are specified as positive values in each direction.
/// The net offset is computed by subtracting opposites.
///
/// ## Usage
/// ```swift
/// let nudge = PositionNudge.up(2)                    // Move up 2 points
/// let nudge2 = PositionNudge(up: 2, right: 4)        // Up and right
/// let offset = nudge.verticalOffset                   // -2.0 (negative = up)
/// ```
public struct PositionNudge: Sendable, Codable, Equatable, Hashable {
    /// Points to nudge upward
    public let up: Double
    
    /// Points to nudge downward
    public let down: Double
    
    /// Points to nudge leftward
    public let left: Double
    
    /// Points to nudge rightward
    public let right: Double
    
    public init(up: Double = 0, down: Double = 0, left: Double = 0, right: Double = 0) {
        self.up = up
        self.down = down
        self.left = left
        self.right = right
    }
    
    /// Net vertical offset in screen coordinates (positive = down)
    public var verticalOffset: Double { down - up }
    
    /// Net horizontal offset in screen coordinates (positive = right)
    public var horizontalOffset: Double { right - left }
    
    /// CGPoint representation of the net offset
    public var asCGOffset: (x: Double, y: Double) {
        (x: horizontalOffset, y: verticalOffset)
    }
    
    // MARK: - Convenience Factories
    
    /// No nudge adjustment
    public static var zero: Self { .init() }
    
    /// Nudge upward by the specified amount
    public static func up(_ amount: Double) -> Self { .init(up: amount) }
    
    /// Nudge downward by the specified amount
    public static func down(_ amount: Double) -> Self { .init(down: amount) }
    
    /// Nudge leftward by the specified amount
    public static func left(_ amount: Double) -> Self { .init(left: amount) }
    
    /// Nudge rightward by the specified amount
    public static func right(_ amount: Double) -> Self { .init(right: amount) }
    
    /// Combine two nudges
    public func combined(with other: PositionNudge) -> PositionNudge {
        PositionNudge(
            up: up + other.up,
            down: down + other.down,
            left: left + other.left,
            right: right + other.right
        )
    }
}

// MARK: - Position Transform

/// Full 2D affine transform for advanced positioning
///
/// Use this for rotation, scaling, or complex transformations.
/// For simple offset adjustments, prefer `PositionNudge`.
///
/// ## Usage
/// ```swift
/// let transform = PositionTransform(rotation: 45)  // Rotate 45°
/// let transform2 = PositionTransform(scaleX: 0.8, scaleY: 0.8)  // Scale down
/// ```
public struct PositionTransform: Sendable, Codable, Equatable, Hashable {
    /// Rotation in degrees (clockwise positive)
    public let rotation: Double
    
    /// Horizontal scale factor (1.0 = no scale)
    public let scaleX: Double
    
    /// Vertical scale factor (1.0 = no scale)
    public let scaleY: Double
    
    /// Horizontal translation in points
    public let translateX: Double
    
    /// Vertical translation in points
    public let translateY: Double
    
    public init(
        rotation: Double = 0,
        scaleX: Double = 1,
        scaleY: Double = 1,
        translateX: Double = 0,
        translateY: Double = 0
    ) {
        self.rotation = rotation
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.translateX = translateX
        self.translateY = translateY
    }
    
    /// Identity transform (no change)
    public static var identity: Self {
        .init(rotation: 0, scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)
    }
    
    /// Whether this is effectively an identity transform
    public var isIdentity: Bool {
        rotation == 0 && scaleX == 1 && scaleY == 1 && translateX == 0 && translateY == 0
    }
}

// MARK: - Annotation Position

/// Unified positioning system supporting both normalized and edge-relative coordinates
///
/// ## Coordinate Systems
/// - **Normalized**: 0.0 to 1.0 where (0,0) is top-left, (1,1) is bottom-right
/// - **Edge-relative**: Points from a specific edge
///
/// ## Usage
/// ```swift
/// // Center of component
/// let pos1 = AnnotationPosition.centered
///
/// // 10% from left, 50% down
/// let pos2 = AnnotationPosition.normalized(h: 0.1, v: 0.5)
///
/// // 20 points from right edge, 10 points from top
/// let pos3 = AnnotationPosition(
///     horizontal: .fromTrailing(20),
///     vertical: .fromTop(10)
/// )
/// ```
public struct AnnotationPosition: Sendable, Codable, Equatable, Hashable {
    /// Horizontal position specification
    public let horizontal: HorizontalPosition
    
    /// Vertical position specification
    public let vertical: VerticalPosition
    
    public init(horizontal: HorizontalPosition, vertical: VerticalPosition) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    // MARK: - Horizontal Position
    
    public enum HorizontalPosition: Sendable, Codable, Equatable, Hashable {
        /// Percentage of width (0.0 = left, 1.0 = right)
        case normalized(Double)
        
        /// Points from left edge
        case fromLeading(Double)
        
        /// Points from right edge
        case fromTrailing(Double)
        
        /// Centered horizontally
        case center
        
        /// Convert to normalized position given container width
        public func normalized(in width: Double) -> Double {
            switch self {
            case .normalized(let value):
                return value
            case .fromLeading(let points):
                return width > 0 ? points / width : 0
            case .fromTrailing(let points):
                return width > 0 ? 1.0 - (points / width) : 1.0
            case .center:
                return 0.5
            }
        }
    }
    
    // MARK: - Vertical Position
    
    public enum VerticalPosition: Sendable, Codable, Equatable, Hashable {
        /// Percentage of height (0.0 = top, 1.0 = bottom)
        case normalized(Double)
        
        /// Points from top edge
        case fromTop(Double)
        
        /// Points from bottom edge
        case fromBottom(Double)
        
        /// Centered vertically
        case center
        
        /// Convert to normalized position given container height
        public func normalized(in height: Double) -> Double {
            switch self {
            case .normalized(let value):
                return value
            case .fromTop(let points):
                return height > 0 ? points / height : 0
            case .fromBottom(let points):
                return height > 0 ? 1.0 - (points / height) : 1.0
            case .center:
                return 0.5
            }
        }
    }
    
    // MARK: - Convenience Factories
    
    /// Create position from normalized coordinates
    public static func normalized(h: Double, v: Double) -> Self {
        .init(horizontal: .normalized(h), vertical: .normalized(v))
    }
    
    /// Create position from edge-relative coordinates (leading and top)
    public static func edgeRelative(leading: Double, top: Double) -> Self {
        .init(horizontal: .fromLeading(leading), vertical: .fromTop(top))
    }
    
    /// Create position from edge-relative coordinates (trailing and bottom)
    public static func edgeRelativeTrailing(trailing: Double, bottom: Double) -> Self {
        .init(horizontal: .fromTrailing(trailing), vertical: .fromBottom(bottom))
    }
    
    /// Centered in container
    public static var centered: Self {
        .init(horizontal: .center, vertical: .center)
    }
    
    /// Top-left corner
    public static var topLeading: Self {
        .normalized(h: 0, v: 0)
    }
    
    /// Top-right corner
    public static var topTrailing: Self {
        .normalized(h: 1, v: 0)
    }
    
    /// Bottom-left corner
    public static var bottomLeading: Self {
        .normalized(h: 0, v: 1)
    }
    
    /// Bottom-right corner
    public static var bottomTrailing: Self {
        .normalized(h: 1, v: 1)
    }
    
    // MARK: - Resolution
    
    /// Resolve to normalized coordinates given container dimensions
    public func normalized(in size: (width: Double, height: Double)) -> (h: Double, v: Double) {
        (
            h: horizontal.normalized(in: size.width),
            v: vertical.normalized(in: size.height)
        )
    }
}

// MARK: - Component Selector

/// Type selector for slide rule components
public enum ComponentType: String, Sendable, Codable, CaseIterable, Hashable {
    case topStator
    case slide
    case bottomStator
}

/// Side selector for front/back of rule
public enum RuleSideSelector: String, Sendable, Codable, CaseIterable, Hashable {
    case front
    case back
    case both
}

/// Full component selector combining side and type
public struct ComponentSelector: Sendable, Codable, Hashable {
    public let side: RuleSideSelector
    public let component: ComponentType
    
    public init(side: RuleSideSelector, component: ComponentType) {
        self.side = side
        self.component = component
    }
    
    // MARK: - Convenience Selectors
    
    public static let frontTopStator = ComponentSelector(side: .front, component: .topStator)
    public static let frontSlide = ComponentSelector(side: .front, component: .slide)
    public static let frontBottomStator = ComponentSelector(side: .front, component: .bottomStator)
    public static let backTopStator = ComponentSelector(side: .back, component: .topStator)
    public static let backSlide = ComponentSelector(side: .back, component: .slide)
    public static let backBottomStator = ComponentSelector(side: .back, component: .bottomStator)
    
    /// All components on front side
    public static var allFront: [ComponentSelector] {
        [.frontTopStator, .frontSlide, .frontBottomStator]
    }
    
    /// All components on back side
    public static var allBack: [ComponentSelector] {
        [.backTopStator, .backSlide, .backBottomStator]
    }
    
    /// All components on both sides
    public static var all: [ComponentSelector] {
        allFront + allBack
    }
}

// MARK: - Scale Selector

/// Pattern-based scale selection for configuration
///
/// Allows targeting scales by name, index, pattern, or other criteria.
public enum ScaleSelector: Sendable, Codable, Hashable {
    /// Specific scale by key
    case scale(ScaleKey)
    
    /// All scales matching regex pattern
    case matching(pattern: String)
    
    /// Scales at specific indices (0-based)
    case indices(Set<Int>)
    
    /// Even-indexed scales (0, 2, 4, ...)
    case evenIndices
    
    /// Odd-indexed scales (1, 3, 5, ...)
    case oddIndices
    
    /// First N scales
    case first(Int)
    
    /// Last N scales
    case last(Int)
    
    /// All scales in component
    case all
    
    /// Left segment of a split scale
    case leftSegment(of: ScaleKey)
    
    /// Right segment of a split scale
    case rightSegment(of: ScaleKey)
    
    // MARK: - Matching
    
    /// Check if this selector matches a scale at the given index with the given name
    /// - Parameters:
    ///   - scaleName: The canonical name of the scale
    ///   - index: The 0-based index of the scale in its container
    ///   - totalCount: Total number of scales in container
    ///   - isLeftSegment: Whether this scale is a left split segment
    ///   - isRightSegment: Whether this scale is a right split segment
    public func matches(
        scaleName: String,
        at index: Int,
        totalCount: Int,
        isLeftSegment: Bool = false,
        isRightSegment: Bool = false
    ) -> Bool {
        switch self {
        case .scale(let key):
            return key.matches(scaleName)
            
        case .matching(let pattern):
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(scaleName.startIndex..., in: scaleName)
            return regex.firstMatch(in: scaleName, options: [], range: range) != nil
            
        case .indices(let indices):
            return indices.contains(index)
            
        case .evenIndices:
            return index % 2 == 0
            
        case .oddIndices:
            return index % 2 == 1
            
        case .first(let n):
            return index < n
            
        case .last(let n):
            return index >= totalCount - n
            
        case .all:
            return true
            
        case .leftSegment(let key):
            return key.matches(scaleName) && isLeftSegment
            
        case .rightSegment(let key):
            return key.matches(scaleName) && isRightSegment
        }
    }
}

// MARK: - Scale Configuration

/// Configuration for a single scale or pattern of scales
///
/// `ScaleConfiguration` binds a `ScaleSelector` to specific display settings.
/// Multiple configurations can be applied to a component, with later configurations
/// taking precedence over earlier ones (last-write-wins).
///
/// ## Usage
/// ```swift
/// // Hide names for even-indexed scales
/// let config1 = ScaleConfiguration(
///     selector: .evenIndices,
///     nameVisibility: .hidden
/// )
///
/// // Move LL1 scale name up 2 points
/// let config2 = ScaleConfiguration(
///     selector: .scale(.ll1),
///     nameNudge: .up(2)
/// )
///
/// // Red labels for all log-log scales
/// let config3 = ScaleConfiguration(
///     selector: .matching(pattern: "LL[0-3]"),
///     labelColor: .red
/// )
/// ```
public struct ScaleConfiguration: Sendable, Codable, Equatable, Hashable {
    /// Which scales this configuration applies to
    public let selector: ScaleSelector
    
    /// Scale name visibility and position (nil = use default)
    public let nameMargin: MarginSide?
    
    /// Formula visibility and position (nil = use default)
    public let formulaMargin: MarginSide?
    
    /// Nudge adjustment for scale name label (nil = no nudge)
    public let nameNudge: PositionNudge?
    
    /// Nudge adjustment for formula label (nil = no nudge)
    public let formulaNudge: PositionNudge?
    
    /// Custom label color override (nil = use default)
    public let labelColor: LabelColor?
    
    /// Custom formula text override (nil = use scale's formula)
    public let formulaOverride: String?
    
    /// Whether scale is visible at all (true = visible, false = hidden)
    public let visible: Bool
    
    /// Priority for conflict resolution (higher = applied later)
    public let priority: Int
    
    public init(
        selector: ScaleSelector,
        nameMargin: MarginSide? = nil,
        formulaMargin: MarginSide? = nil,
        nameNudge: PositionNudge? = nil,
        formulaNudge: PositionNudge? = nil,
        labelColor: LabelColor? = nil,
        formulaOverride: String? = nil,
        visible: Bool = true,
        priority: Int = 0
    ) {
        self.selector = selector
        self.nameMargin = nameMargin
        self.formulaMargin = formulaMargin
        self.nameNudge = nameNudge
        self.formulaNudge = formulaNudge
        self.labelColor = labelColor
        self.formulaOverride = formulaOverride
        self.visible = visible
        self.priority = priority
    }
    
    // MARK: - Convenience Factories
    
    /// Hide scale names for matching scales
    public static func hideNames(for selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, nameMargin: MarginSide.none, priority: priority)
    }
    
    /// Hide formulas for matching scales
    public static func hideFormulas(for selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, formulaMargin: MarginSide.none, priority: priority)
    }
    
    /// Hide both names and formulas for matching scales
    public static func hideLabels(for selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, nameMargin: MarginSide.none, formulaMargin: MarginSide.none, priority: priority)
    }
    
    /// Hide entire scale (not rendered at all)
    public static func hide(selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, visible: false, priority: priority)
    }
    
    /// Set custom label color for matching scales
    public static func colorLabels(_ color: LabelColor, for selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, labelColor: color, priority: priority)
    }
    
    /// Nudge scale name position
    public static func nudgeName(_ nudge: PositionNudge, for selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, nameNudge: nudge, priority: priority)
    }
    
    /// Nudge formula position
    public static func nudgeFormula(_ nudge: PositionNudge, for selector: ScaleSelector, priority: Int = 0) -> Self {
        .init(selector: selector, formulaNudge: nudge, priority: priority)
    }
}

// MARK: - Resolved Scale Display

/// The resolved display settings for a single scale after applying all configurations
///
/// This is the final computed result after merging rule-level settings,
/// component configurations, and scale-specific overrides.
public struct ResolvedScaleDisplay: Sendable, Equatable {
    /// Whether the scale should be rendered at all
    public let visible: Bool
    
    /// Where the scale name appears (or .none if hidden)
    public let nameMargin: MarginSide
    
    /// Where the formula appears (or .none if hidden)
    public let formulaMargin: MarginSide
    
    /// Nudge offset for the scale name
    public let nameNudge: PositionNudge
    
    /// Nudge offset for the formula
    public let formulaNudge: PositionNudge
    
    /// Label color (nil = use component default)
    public let labelColor: LabelColor?
    
    /// Custom formula text (nil = use scale's formula)
    public let formulaOverride: String?
    
    public init(
        visible: Bool = true,
        nameMargin: MarginSide = .left,
        formulaMargin: MarginSide = .right,
        nameNudge: PositionNudge = .zero,
        formulaNudge: PositionNudge = .zero,
        labelColor: LabelColor? = nil,
        formulaOverride: String? = nil
    ) {
        self.visible = visible
        self.nameMargin = nameMargin
        self.formulaMargin = formulaMargin
        self.nameNudge = nameNudge
        self.formulaNudge = formulaNudge
        self.labelColor = labelColor
        self.formulaOverride = formulaOverride
    }
    
    /// Default display settings
    public static var `default`: Self { .init() }
}

// MARK: - Configuration Resolver

/// Resolves multiple scale configurations into final display settings
public struct ScaleConfigurationResolver: Sendable {
    /// The configurations to apply (order matters for priority ties)
    public let configurations: [ScaleConfiguration]
    
    /// Default display settings to start from
    public let defaults: ResolvedScaleDisplay
    
    public init(configurations: [ScaleConfiguration], defaults: ResolvedScaleDisplay = .default) {
        self.configurations = configurations
        self.defaults = defaults
    }
    
    /// Resolve display settings for a specific scale
    /// - Parameters:
    ///   - scaleName: Canonical name of the scale
    ///   - index: 0-based index in its container
    ///   - totalCount: Total scales in container
    ///   - isLeftSegment: Is this a left split segment
    ///   - isRightSegment: Is this a right split segment
    /// - Returns: Resolved display settings with all matching configurations applied
    public func resolve(
        scaleName: String,
        at index: Int,
        totalCount: Int,
        isLeftSegment: Bool = false,
        isRightSegment: Bool = false
    ) -> ResolvedScaleDisplay {
        // Find all matching configurations
        let matching = configurations.filter { config in
            config.selector.matches(
                scaleName: scaleName,
                at: index,
                totalCount: totalCount,
                isLeftSegment: isLeftSegment,
                isRightSegment: isRightSegment
            )
        }
        
        // Sort by priority (lower first, so higher priority applies last)
        let sorted = matching.sorted { $0.priority < $1.priority }
        
        // Apply each configuration in order
        var result = defaults
        for config in sorted {
            result = apply(config, to: result)
        }
        
        return result
    }
    
    /// Apply a single configuration to current resolved display
    private func apply(_ config: ScaleConfiguration, to current: ResolvedScaleDisplay) -> ResolvedScaleDisplay {
        ResolvedScaleDisplay(
            visible: config.visible,  // Always apply visibility
            nameMargin: config.nameMargin ?? current.nameMargin,
            formulaMargin: config.formulaMargin ?? current.formulaMargin,
            nameNudge: config.nameNudge.map { $0.combined(with: current.nameNudge) } ?? current.nameNudge,
            formulaNudge: config.formulaNudge.map { $0.combined(with: current.formulaNudge) } ?? current.formulaNudge,
            labelColor: config.labelColor ?? current.labelColor,
            formulaOverride: config.formulaOverride ?? current.formulaOverride
        )
    }
}
