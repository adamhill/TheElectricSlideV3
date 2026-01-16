# Scale Configuration API Design

## Overview

This document outlines a comprehensive, fluent, declarative configuration system for slide rule scale customization. The design replaces ad-hoc manual JSON encoding with a properly typed, multi-level configuration system.

## Design Goals

1. **Fluent & Declarative** - Chainable methods, result builders, reads like a specification
2. **Multi-Level Overrides** - Rule → Component → Scale (including split scales)
3. **Type-Safe & String Keys** - Enum keys for common scales, string fallback for edge cases
4. **Positioning Flexibility** - Edge-relative + normalized, nudge + transform
5. **Pattern-Based Configuration** - Index patterns, component selectors, regex matching
6. **Clean Persistence** - SwiftData with Codable types (no manual JSON)

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│  SlideRuleConfiguration (Rule-Level)                            │
│  - displaySettings, annotations, componentConfigs               │
├─────────────────────────────────────────────────────────────────┤
│  ComponentConfiguration (.topStator, .slide, .bottomStator)     │
│  - scalePatterns, annotations                                   │
├─────────────────────────────────────────────────────────────────┤
│  ScaleConfiguration (Per-Scale or Pattern-Based)                │
│  - nameMargin, formulaMargin, labelNudge, visibility            │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: Core Types (Foundation)

### Scale Identification

```swift
/// Type-safe scale identification
public enum ScaleKey: Hashable, Codable, Sendable {
    // Primary scales
    case c, d, cf, df, ci, di, cif, dif
    case a, b, k
    case l, ln
    
    // Trig scales
    case s, st, t, t1, t2, p
    
    // Log-Log scales  
    case ll0, ll1, ll2, ll3
    case ll00, ll01, ll02, ll03
    
    // Specialty scales
    case sq1, sq2, w1, w2
    case theta1, theta2
    
    // Generic matcher
    case named(String)
    
    /// Regex pattern matcher
    case matching(pattern: String)
}
```

### Position System

```swift
/// Unified positioning with edge-relative and normalized modes
public struct AnnotationPosition: Sendable, Codable, Equatable {
    public let horizontal: HorizontalPosition
    public let vertical: VerticalPosition
    
    public enum HorizontalPosition: Sendable, Codable, Equatable {
        /// Percentage of width (0.0 = left, 1.0 = right)
        case normalized(Double)
        
        /// Points from left edge
        case fromLeading(Double)
        
        /// Points from right edge  
        case fromTrailing(Double)
        
        /// Centered horizontally
        case center
    }
    
    public enum VerticalPosition: Sendable, Codable, Equatable {
        /// Percentage of height (0.0 = top, 1.0 = bottom)
        case normalized(Double)
        
        /// Points from top edge
        case fromTop(Double)
        
        /// Points from bottom edge
        case fromBottom(Double)
        
        /// Centered vertically
        case center
    }
    
    // Convenience initializers
    public static func normalized(h: Double, v: Double) -> Self
    public static func edgeRelative(leading: Double, top: Double) -> Self
    public static func centered() -> Self
}
```

### Nudge & Transform

```swift
/// Fine-grained position adjustment
public struct PositionNudge: Sendable, Codable, Equatable {
    public let up: Double
    public let down: Double
    public let left: Double
    public let right: Double
    
    public init(up: Double = 0, down: Double = 0, left: Double = 0, right: Double = 0) {
        self.up = up
        self.down = down
        self.left = left
        self.right = right
    }
    
    /// Net vertical offset (up is negative in screen coords)
    public var verticalOffset: Double { down - up }
    
    /// Net horizontal offset
    public var horizontalOffset: Double { right - left }
    
    // Convenience
    public static var zero: Self { .init() }
    public static func up(_ amount: Double) -> Self { .init(up: amount) }
    public static func down(_ amount: Double) -> Self { .init(down: amount) }
    public static func left(_ amount: Double) -> Self { .init(left: amount) }
    public static func right(_ amount: Double) -> Self { .init(right: amount) }
}

/// Full 2D affine transform for advanced positioning
public struct PositionTransform: Sendable, Codable, Equatable {
    public let rotation: Double  // Degrees
    public let scaleX: Double
    public let scaleY: Double
    public let translateX: Double
    public let translateY: Double
    
    public static var identity: Self {
        .init(rotation: 0, scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)
    }
}
```

## Phase 2: Scale Configuration

```swift
/// Configuration for a single scale or pattern of scales
public struct ScaleConfiguration: Sendable, Codable, Equatable {
    /// Which scales this configuration applies to
    public let selector: ScaleSelector
    
    /// Scale name visibility and position
    public let nameMargin: MarginSide?
    
    /// Formula visibility and position
    public let formulaMargin: MarginSide?
    
    /// Nudge for scale name label
    public let nameNudge: PositionNudge?
    
    /// Nudge for formula label
    public let formulaNudge: PositionNudge?
    
    /// Custom label color override
    public let labelColorOverride: LabelColor?
    
    /// Custom formula text override
    public let formulaOverride: String?
    
    /// Whether scale is visible at all
    public let visible: Bool
}

/// Pattern-based scale selection
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
    
    /// Split scale segments
    case leftSegment(of: ScaleKey)
    case rightSegment(of: ScaleKey)
}
```

## Phase 3: Component Configuration

```swift
/// Component type selector
public enum ComponentType: String, Sendable, Codable, CaseIterable {
    case topStator
    case slide
    case bottomStator
}

/// Side selector for front/back
public enum RuleSideSelector: String, Sendable, Codable, CaseIterable {
    case front
    case back
    case both
}

/// Full component selector
public struct ComponentSelector: Sendable, Codable, Hashable {
    public let side: RuleSideSelector
    public let component: ComponentType
    
    public static let frontTopStator = ComponentSelector(side: .front, component: .topStator)
    public static let frontSlide = ComponentSelector(side: .front, component: .slide)
    public static let frontBottomStator = ComponentSelector(side: .front, component: .bottomStator)
    public static let backTopStator = ComponentSelector(side: .back, component: .topStator)
    public static let backSlide = ComponentSelector(side: .back, component: .slide)
    public static let backBottomStator = ComponentSelector(side: .back, component: .bottomStator)
}

/// Configuration for a slide rule component
public struct ComponentConfiguration: Sendable, Codable, Equatable {
    /// Which component this applies to
    public let selector: ComponentSelector
    
    /// Scale-level configurations (applied in order, later wins)
    public let scaleConfigs: [ScaleConfiguration]
    
    /// Component-level annotations
    public let annotations: [ComponentAnnotation]
}
```

## Phase 4: Rule-Level Configuration

```swift
/// Complete slide rule configuration
public struct SlideRuleConfiguration: Sendable, Codable, Equatable {
    /// Global display settings (baseline for all components)
    public let displaySettings: RuleDisplaySettings
    
    /// Per-component configurations
    public let componentConfigs: [ComponentConfiguration]
    
    /// Rule-level annotations (rendered on front/back overall)
    public let ruleAnnotations: [RuleSideSelector: [ComponentAnnotation]]
    
    /// Scale name overrides (canonical → display)
    public let scaleNameOverrides: [String: String]
}
```

## Phase 5: Fluent Builder API

### Result Builder for Scale Configurations

```swift
@resultBuilder
public struct ScaleConfigurationBuilder {
    public static func buildBlock(_ components: ScaleConfiguration...) -> [ScaleConfiguration] {
        components
    }
    
    public static func buildOptional(_ component: [ScaleConfiguration]?) -> [ScaleConfiguration] {
        component ?? []
    }
    
    public static func buildEither(first: [ScaleConfiguration]) -> [ScaleConfiguration] {
        first
    }
    
    public static func buildEither(second: [ScaleConfiguration]) -> [ScaleConfiguration] {
        second
    }
    
    public static func buildArray(_ components: [[ScaleConfiguration]]) -> [ScaleConfiguration] {
        components.flatMap { $0 }
    }
}
```

### Fluent API

```swift
/// Fluent builder for slide rule configuration
public struct SlideRuleConfigurationBuilder {
    private var config: SlideRuleConfiguration
    
    public init() {
        config = SlideRuleConfiguration(
            displaySettings: RuleDisplaySettings(),
            componentConfigs: [],
            ruleAnnotations: [:],
            scaleNameOverrides: [:]
        )
    }
    
    // MARK: - Rule-Level Settings
    
    public func hideFormulas() -> Self { ... }
    public func hideScaleNames() -> Self { ... }
    public func showFormulasOn(_ side: MarginSide) -> Self { ... }
    
    // MARK: - Component Configuration
    
    public func configure(_ component: ComponentSelector, 
                          @ScaleConfigurationBuilder _ configs: () -> [ScaleConfiguration]) -> Self {
        var copy = self
        let componentConfig = ComponentConfiguration(
            selector: component,
            scaleConfigs: configs(),
            annotations: []
        )
        copy.config.componentConfigs.append(componentConfig)
        return copy
    }
    
    // MARK: - Convenience for Common Patterns
    
    public func suppressEvenScaleNames() -> Self {
        configure(.frontTopStator) {
            ScaleConfiguration(selector: .evenIndices, nameMargin: .none, ...)
        }
        .configure(.frontSlide) { ... }
        // etc
    }
    
    // MARK: - Annotations
    
    public func addAnnotation(on component: ComponentSelector, 
                              _ annotation: ComponentAnnotation) -> Self { ... }
    
    // MARK: - Build
    
    public func build() -> SlideRuleConfiguration { config }
}
```

### Usage Examples

```swift
// Example 1: Simple formula suppression
let config = SlideRuleConfigurationBuilder()
    .hideFormulas()
    .build()

// Example 2: Even-indexed scale name suppression
let config = SlideRuleConfigurationBuilder()
    .suppressEvenScaleNames()
    .build()

// Example 3: Complex per-component configuration
let config = SlideRuleConfigurationBuilder()
    .configure(.backSlide) {
        ScaleConfiguration(
            selector: .evenIndices,
            nameMargin: .none,
            formulaMargin: .none
        )
        ScaleConfiguration(
            selector: .scale(.ll1),
            nameNudge: .up(2),
            labelColorOverride: .red
        )
    }
    .addAnnotation(on: .backSlide, .textBlock("PICKETT", color: .green, at: (.normalized(h: 0.5, v: 0.5), anchor: .center)))
    .build()

// Example 4: Pattern-based configuration
let config = SlideRuleConfigurationBuilder()
    .configure(.frontSlide) {
        ScaleConfiguration(
            selector: .matching(pattern: "LL[0-3]"),
            labelColorOverride: .red
        )
        ScaleConfiguration(
            selector: .leftSegment(of: .theta1),
            nameNudge: .left(4)
        )
    }
    .build()
```

## Phase 6: SwiftData Integration

### Model Update

```swift
@Model
final class SlideRuleDefinitionModel {
    // ... existing properties ...
    
    /// Complete configuration (replaces individual booleans)
    /// SwiftData automatically handles Codable types
    var configuration: SlideRuleConfiguration?
    
    // Backward compatibility computed properties
    var showScaleNames: Bool {
        get { configuration?.displaySettings.showScaleNames ?? true }
        set { 
            var newConfig = configuration ?? SlideRuleConfiguration()
            newConfig.displaySettings.showScaleNames = newValue
            configuration = newConfig
        }
    }
    
    // ... etc for other legacy properties
}
```

## Implementation Plan

### Phase 1: Core Types (This PR)
- [ ] Add `ScaleKey` enum
- [ ] Add `AnnotationPosition` with edge-relative support  
- [ ] Add `PositionNudge` and `PositionTransform`
- [ ] Add tests in `SlideRuleCoreV3Tests`

**Test Point:** Add example using new position types to Annotation Test rule

### Phase 2: Scale Configuration
- [ ] Add `ScaleSelector` enum
- [ ] Add `ScaleConfiguration` struct
- [ ] Add selector matching logic
- [ ] Add tests

**Test Point:** Add pattern-based scale config to Annotation Test rule

### Phase 3: Component Configuration  
- [ ] Add `ComponentSelector` and `ComponentConfiguration`
- [ ] Wire into SlideRule construction
- [ ] Add tests

**Test Point:** Configure different components differently in Annotation Test rule

### Phase 4: Rule Configuration
- [ ] Add `SlideRuleConfiguration`
- [ ] Migrate from individual booleans
- [ ] Add tests

**Test Point:** Complete configuration replacement in Annotation Test rule

### Phase 5: Fluent Builder
- [ ] Add result builder
- [ ] Add `SlideRuleConfigurationBuilder`
- [ ] Add convenience methods
- [ ] Add tests

**Test Point:** Rewrite Annotation Test rule using fluent API

### Phase 6: SwiftData Migration
- [ ] Add `configuration` property to model
- [ ] Add backward compatibility layer
- [ ] Add migration logic for library version
- [ ] Test persistence round-trip

**Test Point:** Verify all rules load correctly with new system

## Compatibility Notes

1. **Backward Compatibility**: Legacy boolean properties remain functional via computed property wrappers
2. **Library Versioning**: Bump to version 31 when new configuration system ships
3. **Migration**: Existing rules without configuration use defaults
4. **Codable**: All types are Codable for SwiftData persistence (no manual JSON)

## References

- WWDC 2024: "Demystify SwiftUI containers" - ContainerValues pattern
- Swift Charts: ChartContentBuilder result builder pattern
- RegexBuilder: DSL design patterns
- SwiftData: Automatic Codable handling for complex types
