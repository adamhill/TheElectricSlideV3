# Scale Configuration API - Complete Reference

> **Status:** All Phases Complete (Phases 1-6 Implemented)

## Overview

The Scale Configuration API provides a flexible, type-safe system for customizing scale display in The Electric Slide app. It enables fine-grained control over individual scales while maintaining backward compatibility with existing rule definitions through a hierarchical configuration system.

**Key Capabilities:**
- ✅ Suppress names on specific scales (e.g., every other scale on dense stators)
- ✅ Color specific scale labels differently (e.g., red for inverted scales)
- ✅ Add annotations to rules and components (e.g., "LL" brackets for Log-Log groups)
- ✅ Configure different defaults for different components (stators vs slides)
- ✅ Override scale display names with custom text
- ✅ Precisely position labels using nudge adjustments

---

## Architecture: Hierarchical Configuration

The configuration system follows a **Rule → Component → Scale** hierarchy with cascading priority:

```
┌─────────────────────────────────────────────────────────────────┐
│                    SlideRuleConfiguration                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  RuleDisplaySettings (defaults for entire rule)            │  │
│  │  • showScaleNames, showFormulas                           │  │
│  │  • defaultScaleNameMargin, defaultFormulaMargin           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  ComponentConfiguration[] (per stator/slide)               │  │
│  │  • selector: which component(s) this applies to           │  │
│  │  • displaySettings: override rule defaults                │  │
│  │  • scaleConfigs: per-scale configurations                 │  │
│  │  • annotations: visual annotations on component           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  ScaleConfiguration (per-scale overrides)                  │  │
│  │  • selector: which scale(s) this applies to               │  │
│  │  • showName/showFormula: visibility overrides             │  │
│  │  • nameColor/formulaColor: label coloring                 │  │
│  │  • nameNudge/formulaNudge: position adjustments           │  │
│  │  • customName: display name override                      │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Resolution Priority (highest to lowest):**
1. Scale-specific configuration (most specific wins)
2. Component display settings  
3. Rule display settings (defaults)

---

## Phase 1: Core Types

### ScaleKey - Type-Safe Scale Identification

`ScaleKey` provides compile-time safe identification for standard scales, with fallback to string patterns for custom scales.

```swift
public enum ScaleKey: Hashable, Codable, Sendable {
    // === Primary Scales ===
    case c, d, cf, df, ci, di, cif, dif
    case a, b, k
    case l, ln
    
    // === Trigonometric Scales ===
    case s, st, t, t1, t2, p
    
    // === Log-Log Scales (positive) ===
    case ll0, ll1, ll2, ll3
    
    // === Log-Log Scales (negative/reciprocal) ===
    case ll00, ll01, ll02, ll03
    
    // === Square Root & Cube Root ===
    case sq1, sq2, w1, w2
    
    // === Hyperbolic Scales ===
    case sh1, sh2, th
    
    // === Split Scales ===
    case r1, r2      // Square root split
    
    // === Electrical Engineering ===
    case dB          // Decibel scale
    
    // === Flexible Matching ===
    case named(String)           // Exact name match: .named("DF")
    case matching(pattern: String) // Regex: .matching(pattern: "LL[0-3]")
}
```

**Usage Examples:**

```swift
// Type-safe standard scale
let cScale = ScaleKey.c

// Custom scale by exact name
let customScale = ScaleKey.named("MyCustomScale")

// Pattern matching for groups
let allLogLog = ScaleKey.matching(pattern: "LL[0-9]+")

// Get canonical display name
ScaleKey.ci.canonicalName  // "CI"
ScaleKey.ll2.canonicalName // "LL2"

// Match checking
ScaleKey.ci.matches("CI")     // true
ScaleKey.ci.matches("ci")     // true (case-insensitive)
ScaleKey.matching(pattern: "LL[0-3]").matches("LL2") // true
```

### PositionNudge - Fine-Grained Position Adjustment

Small adjustments to label positioning without changing the base position. Uses directional properties (`up`, `down`, `left`, `right`) with computed offsets for rendering.

```swift
public struct PositionNudge: Sendable, Equatable, Hashable, Codable {
    /// Points to nudge upward
    public let up: Double
    
    /// Points to nudge downward
    public let down: Double
    
    /// Points to nudge leftward
    public let left: Double
    
    /// Points to nudge rightward
    public let right: Double
    
    /// Net vertical offset in screen coordinates (positive = down)
    public var verticalOffset: Double { down - up }
    
    /// Net horizontal offset in screen coordinates (positive = right)
    public var horizontalOffset: Double { right - left }
    
    /// CGPoint representation of the net offset
    public var asCGOffset: (x: Double, y: Double)
    
    // Convenience factories
    public static var zero: PositionNudge
    public static func right(_ points: Double) -> PositionNudge
    public static func left(_ points: Double) -> PositionNudge
    public static func up(_ points: Double) -> PositionNudge
    public static func down(_ points: Double) -> PositionNudge
    
    /// Combine two nudges
    public func combined(with other: PositionNudge) -> PositionNudge
}
```

**Usage Examples:**

```swift
// Move label 2 points right
let nudge = PositionNudge.right(2)

// Move label up and right using directional initializer
let nudge = PositionNudge(up: 2, right: 4)

// Get the computed offset for SwiftUI .offset() modifier
let xOffset = nudge.horizontalOffset  // 4.0 (right - left)
let yOffset = nudge.verticalOffset    // -2.0 (down - up, negative = up)

// Combine nudges
let combined = nudge.combined(with: .down(1))  // up: 2, down: 1, right: 4
```

### PositionTransform - Coordinate Transformation

For more complex positioning needs (not commonly used):

```swift
public struct PositionTransform: Sendable, Equatable, Hashable, Codable {
    public let offset: PositionNudge       // Applied first
    public let scale: (x: Double, y: Double) // Applied second (default: 1.0)
    
    public static let identity = PositionTransform(
        offset: .zero,
        scale: (x: 1.0, y: 1.0)
    )
}
```

### AnnotationPosition - Flexible Label Positioning

Describes where labels appear relative to a scale:

```swift
public struct AnnotationPosition: Sendable, Equatable, Hashable, Codable {
    public let edge: Edge              // .top, .bottom, .leading, .trailing
    public let alignment: Double       // 0.0 = start, 0.5 = center, 1.0 = end
    public let nudge: PositionNudge?   // Fine-tuning adjustment
    
    public enum Edge: String, Codable, Sendable {
        case top, bottom, leading, trailing
    }
    
    // Convenience factories
    static let topLeading: AnnotationPosition
    static let topCenter: AnnotationPosition
    static let topTrailing: AnnotationPosition
    static let bottomLeading: AnnotationPosition
    static let bottomCenter: AnnotationPosition
    static let bottomTrailing: AnnotationPosition
    
    static func custom(edge: Edge, alignment: Double, nudge: PositionNudge?) -> AnnotationPosition
}
```

---

## Phase 2: Scale Configuration & Selection

### ScaleSelector - Pattern-Based Scale Selection

`ScaleSelector` determines which scales a configuration applies to:

```swift
public enum ScaleSelector: Hashable, Codable, Sendable {
    // === Single Scale Selection ===
    case scale(ScaleKey)                 // One specific scale
    
    // === Pattern Matching ===
    case matching(pattern: String)       // Regex pattern match
    
    // === Index-Based Selection ===
    case indices(Set<Int>)              // Specific indices: [0, 2, 4]
    case evenIndices                     // 0, 2, 4, 6, ...
    case oddIndices                      // 1, 3, 5, 7, ...
    case first(Int)                      // First N scales
    case last(Int)                       // Last N scales
    
    // === Wildcard ===
    case all                            // Every scale in scope
    
    // === Split Scale Segments ===
    case leftSegment(ScaleKey)          // Left part of split scale
    case rightSegment(ScaleKey)         // Right part of split scale
}
```

**Usage Examples:**

```swift
// Single scale
ScaleSelector.scale(.ci)

// All Log-Log scales
ScaleSelector.matching(pattern: "LL[0-9]+")

// Alternate scales (for dense stators)
ScaleSelector.evenIndices  // Suppress every other name
ScaleSelector.oddIndices

// First 3 scales
ScaleSelector.first(3)

// All scales in component
ScaleSelector.all

// Split scale handling
ScaleSelector.leftSegment(.sq1)   // Just the left half
ScaleSelector.rightSegment(.sq1)  // Just the right half
```

### ScaleConfiguration - Per-Scale Display Settings

Defines display overrides for selected scales:

```swift
public struct ScaleConfiguration: Sendable, Equatable, Hashable, Codable {
    public let selector: ScaleSelector
    
    // Visibility overrides (nil = inherit from component/rule)
    public let showName: Bool?
    public let showFormula: Bool?
    
    // Color overrides (nil = use default)
    public let nameColor: LabelColor?
    public let formulaColor: LabelColor?
    
    // Position adjustments
    public let nameNudge: PositionNudge?
    public let formulaNudge: PositionNudge?
    
    // Margin overrides (nil = use component/rule default)
    public let nameMargin: MarginSide?
    public let formulaMargin: MarginSide?
    
    // Display name override
    public let customName: String?
}
```

**Factory Methods:**

```swift
// Hide scale name
ScaleConfiguration.hideNames(for: .ci)

// Hide formula
ScaleConfiguration.hideFormulas(for: .scale(.l))

// Hide both name and formula
ScaleConfiguration.hideLabels(for: .evenIndices)

// Hide completely (equivalent to hideLabels)
ScaleConfiguration.hide(for: .scale(.st))

// Color labels
ScaleConfiguration.colorLabels(
    for: .matching(pattern: "LL[0-9]+"),
    nameColor: .red
)

// Nudge name position
ScaleConfiguration.nudgeName(for: .scale(.a), nudge: .right(2))

// Nudge formula position
ScaleConfiguration.nudgeFormula(for: .scale(.b), nudge: .up(1))
```

### ScaleConfigurationResolver - Configuration Resolution

Resolves the final display settings for a scale by checking configurations in order:

```swift
public struct ResolvedScaleDisplay: Sendable, Equatable {
    public let showName: Bool
    public let showFormula: Bool
    public let nameColor: LabelColor?
    public let formulaColor: LabelColor?
    public let nameNudge: PositionNudge?
    public let formulaNudge: PositionNudge?
    public let nameMargin: MarginSide
    public let formulaMargin: MarginSide
    public let customName: String?
}

public struct ScaleConfigurationResolver: Sendable {
    public init(
        configurations: [ScaleConfiguration],
        defaultSettings: RuleDisplaySettings
    )
    
    public func resolve(
        scaleName: String,
        scaleIndex: Int,
        totalScales: Int
    ) -> ResolvedScaleDisplay
}
```

**Usage Example:**

```swift
let resolver = ScaleConfigurationResolver(
    configurations: [
        .hideNames(for: .evenIndices),
        .colorLabels(for: .scale(.ci), nameColor: .red)
    ],
    defaultSettings: .standard
)

// Resolve for CI scale at index 3
let display = resolver.resolve(scaleName: "CI", scaleIndex: 3, totalScales: 8)
// display.showName = true (odd index, not hidden)
// display.nameColor = .red (CI color override applies)
```

---

## Phase 3: Component Configuration

### ComponentType - Stator/Slide Identification

```swift
public enum ComponentType: String, Codable, Sendable, CaseIterable {
    case topStator
    case slide
    case bottomStator
}
```

### RuleSideSelector - Front/Back Selection

```swift
public enum RuleSideSelector: Hashable, Codable, Sendable {
    case front              // Front side only
    case back               // Back side only
    case both               // Both sides
}
```

### ComponentSelector - Target Component Selection

```swift
public enum ComponentSelector: Hashable, Codable, Sendable {
    case specific(side: RuleSideSelector, component: ComponentType)
    case allStators(side: RuleSideSelector)
    case allSlides(side: RuleSideSelector)
    case all(side: RuleSideSelector)
    case global                          // All components, all sides
}
```

**Usage Examples:**

```swift
// Front top stator only
ComponentSelector.specific(side: .front, component: .topStator)

// All stators on both sides
ComponentSelector.allStators(side: .both)

// Everything on the back
ComponentSelector.all(side: .back)

// All components everywhere
ComponentSelector.global
```

### ComponentConfiguration - Per-Component Settings

```swift
public struct ComponentConfiguration: Sendable, Equatable, Hashable, Codable {
    public let selector: ComponentSelector
    
    // Override rule-level display settings for this component
    public let displaySettings: RuleDisplaySettings?
    
    // Scale-specific configurations within this component
    public let scaleConfigs: [ScaleConfiguration]
    
    // Annotations on this component
    public let annotations: [ComponentAnnotation]
}
```

**Factory Methods:**

```swift
// Basic component with scale configs
ComponentConfiguration.forComponent(
    .specific(side: .front, component: .topStator),
    scaleConfigs: [
        .hideNames(for: .evenIndices),
        .colorLabels(for: .scale(.ci), nameColor: .red)
    ]
)

// Component with display settings override
ComponentConfiguration.forComponent(
    .allStators(side: .both),
    displaySettings: .namesOnly,  // Only show names, no formulas
    scaleConfigs: []
)

// Component with annotations
ComponentConfiguration.forComponent(
    .specific(side: .front, component: .slide),
    annotations: [
        ComponentAnnotation(
            content: .text("LL"),
            horizontalPosition: 0.02,
            verticalPosition: 0.5
        )
    ]
)
```

---

## Phase 4: Rule-Level Configuration

### SlideRuleConfiguration - Complete Rule Configuration

The top-level configuration container:

```swift
public struct SlideRuleConfiguration: Sendable, Equatable, Hashable, Codable {
    /// Rule-level display defaults
    public let displaySettings: RuleDisplaySettings
    
    /// Component-specific configurations
    public let componentConfigs: [ComponentConfiguration]
    
    /// Rule-level annotations (branding, model numbers, etc.)
    public let ruleAnnotations: [ComponentAnnotation]
    
    /// Global scale name overrides
    public let scaleNameOverrides: [ScaleKey: String]
}
```

**Factory Constructors:**

```swift
// Standard configuration (names and formulas visible)
SlideRuleConfiguration.standard

// Names only, no formulas
SlideRuleConfiguration.namesOnly

// Formulas only, no names
SlideRuleConfiguration.formulasOnly

// No labels at all
SlideRuleConfiguration.noLabels

// Custom from RuleDisplaySettings
SlideRuleConfiguration.with(displaySettings: customSettings)
```

**Query Methods:**

```swift
let config = SlideRuleConfiguration.standard

// Get component configurations
let frontTopConfig = config.configurationFor(
    side: .front,
    component: .topStator
)

// Get all scale configs for a component
let scaleConfigs = config.allScaleConfigsFor(
    side: .front,
    component: .slide
)

// Create resolver for a specific component
let resolver = config.resolverFor(
    side: .front,
    component: .topStator
)
```

**Mutation Methods (returns new instance):**

```swift
// Add component configuration
let updated = config.withComponentConfig(newComponentConfig)

// Add rule-level annotation
let updated = config.withRuleAnnotation(annotation)

// Add scale name override
let updated = config.withScaleNameOverride(key: .ci, name: "1/x")

// Update display settings
let updated = config.withDisplaySettings(newSettings)
```

**Legacy Migration:**

```swift
// Convert from old RuleDisplaySettings
let config = SlideRuleConfiguration.fromLegacy(oldRuleDisplaySettings)
```

---

## Phase 5: Fluent Builder API

### ScaleConfigurationResultBuilder - DSL Syntax

Enables declarative syntax for building scale configuration arrays:

```swift
@resultBuilder
public struct ScaleConfigurationResultBuilder {
    public static func buildBlock(_ components: ScaleConfiguration...) -> [ScaleConfiguration]
    public static func buildOptional(_ component: [ScaleConfiguration]?) -> [ScaleConfiguration]
    public static func buildEither(first: [ScaleConfiguration]) -> [ScaleConfiguration]
    public static func buildEither(second: [ScaleConfiguration]) -> [ScaleConfiguration]
    public static func buildArray(_ components: [[ScaleConfiguration]]) -> [ScaleConfiguration]
    public static func buildExpression(_ expression: ScaleConfiguration) -> [ScaleConfiguration]
    public static func buildExpression(_ expression: [ScaleConfiguration]) -> [ScaleConfiguration]
}
```

**Usage Example:**

```swift
@ScaleConfigurationResultBuilder
func denseStatorConfig() -> [ScaleConfiguration] {
    ScaleConfiguration.hideNames(for: .evenIndices)
    ScaleConfiguration.colorLabels(for: .scale(.ci), nameColor: .red)
    
    if showLogLogColors {
        ScaleConfiguration.colorLabels(
            for: .matching(pattern: "LL[0-9]+"),
            nameColor: .blue
        )
    }
}
```

### SlideRuleConfigurationBuilder - Fluent API

Chainable builder for constructing configurations:

```swift
public struct SlideRuleConfigurationBuilder: Sendable {
    // Start with defaults
    public init()
    
    // === Display Settings ===
    
    /// Hide all formulas rule-wide
    public func hideFormulas() -> SlideRuleConfigurationBuilder
    
    /// Hide all scale names rule-wide
    public func hideScaleNames() -> SlideRuleConfigurationBuilder
    
    /// Hide all labels (names and formulas)
    public func hideAllLabels() -> SlideRuleConfigurationBuilder
    
    /// Set default margin for scale names
    public func defaultScaleNameMargin(_ margin: MarginSide) -> SlideRuleConfigurationBuilder
    
    /// Set default margin for formulas
    public func defaultFormulaMargin(_ margin: MarginSide) -> SlideRuleConfigurationBuilder
    
    // === Component Configuration ===
    
    /// Add scale configurations for a specific component
    public func configure(
        _ selector: ComponentSelector,
        @ScaleConfigurationResultBuilder scales: () -> [ScaleConfiguration]
    ) -> SlideRuleConfigurationBuilder
    
    // === Convenience Methods ===
    
    /// Suppress names on even-indexed scales (for dense stators)
    public func suppressEvenScaleNames(
        for selector: ComponentSelector = .global
    ) -> SlideRuleConfigurationBuilder
    
    /// Suppress names on odd-indexed scales
    public func suppressOddScaleNames(
        for selector: ComponentSelector = .global
    ) -> SlideRuleConfigurationBuilder
    
    /// Color all Log-Log scales
    public func colorLogLogScales(
        _ color: LabelColor,
        for selector: ComponentSelector = .global
    ) -> SlideRuleConfigurationBuilder
    
    /// Color all inverted scales (CI, DI, CIF, DIF)
    public func colorInvertedScales(
        _ color: LabelColor,
        for selector: ComponentSelector = .global
    ) -> SlideRuleConfigurationBuilder
    
    // === Name Overrides ===
    
    /// Override display name for a single scale
    public func addNameOverride(
        key: ScaleKey,
        name: String
    ) -> SlideRuleConfigurationBuilder
    
    /// Override display names for multiple scales
    public func addNameOverrides(
        _ overrides: [ScaleKey: String]
    ) -> SlideRuleConfigurationBuilder
    
    // === Annotations ===
    
    /// Add a rule-level annotation
    public func addAnnotation(
        _ annotation: ComponentAnnotation
    ) -> SlideRuleConfigurationBuilder
    
    // === Build ===
    
    /// Build the final configuration
    public func build() -> SlideRuleConfiguration
}
```

**Extension on SlideRuleConfiguration:**

```swift
extension SlideRuleConfiguration {
    /// Start building a new configuration
    public static func build(
        _ configure: (SlideRuleConfigurationBuilder) -> SlideRuleConfigurationBuilder
    ) -> SlideRuleConfiguration
}
```

---

## Complete Usage Examples

### Example 1: Dense Stator with Alternating Names

When a stator has many scales, suppress every other name for readability:

```swift
let config = SlideRuleConfiguration.build { builder in
    builder
        .suppressEvenScaleNames(
            for: .specific(side: .front, component: .topStator)
        )
}
```

### Example 2: Colored Inverted and Log-Log Scales

Make inverted scales red and Log-Log scales blue:

```swift
let config = SlideRuleConfiguration.build { builder in
    builder
        .colorInvertedScales(.red)
        .colorLogLogScales(.blue)
}
```

### Example 3: Custom Component Configuration (with Scale Nudging)

Fine-grained control over a specific component, including position adjustments:

```swift
let config = SlideRuleConfiguration.build { builder in
    builder
        .configure(.specific(side: .front, component: .slide)) {
            ScaleConfiguration.hideNames(for: .first(2))
            ScaleConfiguration.colorLabels(for: .scale(.ci), nameColor: .red)
            // Nudge the C scale name 5 points to the right
            ScaleConfiguration.nudgeName(.right(5), for: .scale(.c))
        }
}
```

**How Nudging Works:**
1. The `ScaleConfiguration.nudgeName()` factory creates a config with `nameNudge` set
2. During rule parsing, `applyScaleConfig()` copies the nudge to `ScaleDefinition`
3. At render time, `ScaleView` applies `.offset(x: horizontalOffset, y: verticalOffset)`

### Example 4: Scale Name Overrides

Display custom names instead of standard abbreviations:

```swift
let config = SlideRuleConfiguration.build { builder in
    builder
        .addNameOverrides([
            .ci: "1/x",
            .a: "x²",
            .k: "x³"
        ])
}
```

### Example 5: Complex Multi-Component Configuration

Different settings for different parts of the rule:

```swift
let config = SlideRuleConfiguration.build { builder in
    builder
        // Global: hide formulas
        .hideFormulas()
        
        // Front top stator: suppress alternate names
        .configure(.specific(side: .front, component: .topStator)) {
            ScaleConfiguration.hideNames(for: .evenIndices)
        }
        
        // Slide: color inverted scales
        .configure(.allSlides(side: .both)) {
            ScaleConfiguration.colorLabels(for: .scale(.ci), nameColor: .red)
            ScaleConfiguration.colorLabels(for: .scale(.cif), nameColor: .red)
        }
        
        // Back: different naming convention
        .addNameOverride(key: .ll2, name: "e^0.1x")
}
```

### Example 6: Using the Resolver Directly

For rendering code that needs resolved settings:

```swift
let config = SlideRuleConfiguration.build { builder in
    builder
        .colorLogLogScales(.blue)
        .suppressOddScaleNames(for: .specific(side: .front, component: .topStator))
}

// In rendering code:
let resolver = config.resolverFor(side: .front, component: .topStator)

for (index, scale) in scales.enumerated() {
    let display = resolver.resolve(
        scaleName: scale.name,
        scaleIndex: index,
        totalScales: scales.count
    )
    
    if display.showName {
        let name = display.customName ?? scale.name
        let color = display.nameColor ?? .defaultLabel
        // render name with color
    }
}
```

### Example 7: Annotations

Add visual annotations to components:

```swift
let annotation = ComponentAnnotation(
    content: .text("K&E 4081-3"),
    color: .gray,
    horizontalPosition: 0.5,  // Center
    verticalPosition: 0.02,   // Near top
    anchor: .topCenter,
    fontSize: 8,
    fontWeight: .light
)

let config = SlideRuleConfiguration.build { builder in
    builder
        .addAnnotation(annotation)
}
```

---

## Supporting Types Reference

### RuleDisplaySettings (from SlideRuleModels.swift)

```swift
public struct RuleDisplaySettings: Sendable, Equatable, Hashable, Codable {
    public var showScaleNames: Bool
    public var showFormulas: Bool
    public var defaultScaleNameMargin: MarginSide
    public var defaultFormulaMargin: MarginSide
    
    // Static factories
    public static let standard: RuleDisplaySettings      // names + formulas
    public static let namesOnly: RuleDisplaySettings     // names only
    public static let formulasOnly: RuleDisplaySettings  // formulas only  
    public static let none: RuleDisplaySettings          // nothing
}
```

### LabelColor (from SlideRuleModels.swift)

```swift
public struct LabelColor: Sendable, Equatable, Hashable, Codable {
    public let red: Double    // 0.0-1.0
    public let green: Double  // 0.0-1.0
    public let blue: Double   // 0.0-1.0
    public let alpha: Double  // 0.0-1.0
    
    // Static constants
    public static let black: LabelColor
    public static let white: LabelColor
    public static let red: LabelColor
    public static let green: LabelColor
    public static let blue: LabelColor
    public static let yellow: LabelColor
    public static let cyan: LabelColor
    public static let magenta: LabelColor
    public static let orange: LabelColor
    public static let brown: LabelColor
    public static let gray: LabelColor
    public static let darkGray: LabelColor
    public static let lightGray: LabelColor
    public static let defaultLabel: LabelColor
}
```

### MarginSide (from SlideRuleModels.swift)

```swift
public enum MarginSide: String, Sendable, Equatable, Hashable, Codable {
    case top
    case bottom
    case none
}
```

### ComponentAnnotation (from SlideRuleModels.swift)

```swift
public struct ComponentAnnotation: Sendable, Equatable, Hashable {
    public let content: AnnotationContent
    public let color: LabelColor?
    public let horizontalPosition: Double  // 0.0 = left, 1.0 = right
    public let verticalPosition: Double    // 0.0 = top, 1.0 = bottom
    public let anchor: AnnotationAnchor
    public let size: (width: Double, height: Double)?
    public let fontSize: Double?
    public let fontWeight: LabelFontStyle
    public let textAlignment: AnnotationTextAlignment
    public let nudge: PositionNudge?
}
```

---

## Resolution Algorithm

When resolving display settings for a scale, the system follows this priority order:

```
1. Check scale-specific configs in component (most specific first)
2. Check component display settings
3. Fall back to rule display settings

For each property (showName, nameColor, etc.):
  - Use first non-nil value found
  - If all nil, use rule default
```

**Example Resolution:**

```
Rule: showScaleNames = true, showFormulas = true
Component: displaySettings = nil (inherit)
ScaleConfig for CI: showName = nil, nameColor = .red

Result for CI:
  - showName = true (from rule default)
  - nameColor = .red (from scale config)
```

---

## File Locations

| Type | Location |
|------|----------|
| All Configuration Types | `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleConfiguration.swift` |
| ScaleDefinition (with nameNudge) | `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift` |
| RuleDisplaySettings | `SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift` |
| LabelColor | `SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift` |
| ComponentAnnotation | `SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift` |
| Configuration Tests | `SlideRuleCoreV3/Tests/SlideRuleCoreV3Tests/ScaleConfigurationTests.swift` |
| Configuration to Scale Wiring | `TheElectricSlide/CurrentSlideRule.swift` (applyScaleConfig) |
| Scale Rendering (nudge applied) | `TheElectricSlide/Components/ScaleView.swift` |

---

## Implementation Notes: nameNudge/formulaNudge Data Flow

The `nameNudge` and `formulaNudge` properties flow through the system as follows:

```
SlideRuleConfiguration
    └── ComponentConfiguration
        └── ScaleConfiguration.nameNudge: PositionNudge?
                    │
                    ▼ (during rule parsing in CurrentSlideRule.swift)
            applyScaleConfig() copies to ScaleBuilder
                    │
                    ▼
            ScaleDefinition.nameNudge: PositionNudge?
                    │
                    ▼ (during rendering in ScaleView.swift)
            GeneratedScale.definition.nameNudge
                    │
                    ▼
            Text(scaleLabel)
                .offset(x: nameNudge.horizontalOffset, y: nameNudge.verticalOffset)
```

**Key Points:**
- `ScaleConfiguration.nameNudge` is configuration-level (what the user specifies)
- `ScaleDefinition.nameNudge` is scale-level storage (attached to each scale)
- `ScaleBuilder.withNameNudge()` is the builder method to set the nudge
- `applyScaleConfig()` in `CurrentSlideRule.swift` bridges configuration to definition
- `ScaleView` reads `generatedScale.definition.nameNudge` and applies SwiftUI `.offset()`

---

## Phase 6: SwiftData Integration ✅

SwiftData persistence is now implemented in `CurrentSlideRule.swift`:

### Storage Approach

Instead of `@Attribute(.transformable)`, we use **JSON String storage** for better SwiftData compatibility:

```swift
@Model
final class SlideRuleDefinitionModel {
    // JSON-encoded SlideRuleConfiguration for persistence
    var configurationJSON: String?
    
    // Computed property for type-safe access
    var configuration: SlideRuleConfiguration {
        get {
            guard let json = configurationJSON,
                  let data = json.data(using: .utf8),
                  let config = try? JSONDecoder().decode(SlideRuleConfiguration.self, from: data)
            else { return migratedConfiguration }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                configurationJSON = json
            }
        }
    }
}
```

### Backward Compatibility

Legacy properties are preserved as computed properties with backing storage:

```swift
// Internal storage for migration
private var _showScaleNames: Bool = true
private var _showFormulas: Bool = true
private var _suppressEvenScaleNames: Bool = false

// Computed property that reads from configuration first
var showScaleNames: Bool {
    get { configuration.displaySettings.showScaleNames }
    set {
        var config = configuration
        config.displaySettings.showScaleNames = newValue
        configuration = config
    }
}
```

### New Initializer

Factory methods can now pass configuration directly:

```swift
// Using the new Configuration API
let configuration = SlideRuleConfigurationBuilder()
    .hideFormulas()
    .suppressEvenScaleNames()
    .addNameOverrides(["DQ": "D/Q", "L": "C/L"])
    .addAnnotation(legendAnnotation, on: .back)
    .build()

// Create model with configuration
SlideRuleDefinitionModel(
    name: "Rule Name",
    description: "Description",
    definitionString: "(DF [ CF CI C ] D)",
    manufacturer: SlideRuleManufacturer.pickett.rawValue,
    configuration: configuration
)
```

### Migration Helper

```swift
/// Migrate from legacy properties to configuration JSON
func migrateToConfiguration() {
    guard configurationJSON == nil else { return } // Already migrated
    configuration = migratedConfiguration
}
```

This enables:
- ✅ Persisting custom configurations per rule
- ✅ Migrating existing rules automatically via `migratedConfiguration`
- ✅ Full backward compatibility with existing code
- ✅ Type-safe access via computed `configuration` property
