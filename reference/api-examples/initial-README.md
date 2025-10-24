# Slide Rule Scale Engine - Swift Implementation

A modern Swift implementation of a slide rule scale calculation engine, based on the PostScript slide rule engine by Derek Pressnall and the mathematical foundations described by Joseph Pasquale.

## Overview

This implementation provides:
- **Mathematical precision**: Based on rigorous mathematical principles for scale construction
- **Functional design**: Pure functions, immutable data structures, protocol-oriented
- **Modern Swift**: Swift 6 concurrency, Sendable types, actor isolation
- **Type safety**: Strong typing with clear separation of concerns
- **No drawing code**: Pure calculation engine - rendering is separate

## Architecture

### Core Mathematical Model

The engine is built on the fundamental formula from "Mathematical Foundations of the Slide Rule":

```
d(x) = m × (f(x) - f(x_L)) / (f(x_R) - f(x_L))
```

Where:
- `d(x)` = distance of value x from the left edge
- `m` = physical length of the scale
- `f` = the scale's mathematical function (e.g., log₁₀)
- `x_L` = leftmost value on the scale
- `x_R` = rightmost value on the scale

This formula works for ANY mathematical function, making the engine extremely flexible.

### File Organization

#### 1. `SlideRuleModels.swift` - Core Types
- `ScaleFunction` protocol and implementations
- `TickMark` and `TickStyle` value types
- `ScaleSubsection` for defining tick patterns
- Basic type aliases

#### 2. `ScaleDefinition.swift` - Scale Configuration
- `ScaleDefinition`: Complete scale specification
- `ScaleBuilder`: Fluent API for scale creation
- `StandardLabelFormatter`: Common label formatting functions
- `ScaleConstant`: For marking special values (π, e)

#### 3. `ScaleCalculator.swift` - Calculation Engine
- `ScaleCalculator`: Pure functions for position/value calculations
- `GeneratedScale`: Complete calculated scale with all tick marks
- Position normalization (0.0 to 1.0)
- Tick mark generation from subsections

#### 4. `StandardScales.swift` - Predefined Scales
- Factory functions for common slide rule scales
- C, D, CI, A, K scales (logarithmic family)
- LL1, LL2, LL3 scales (log-log family)
- S, T, ST scales (trigonometric family)
- L, Ln scales (linear/natural log)

#### 5. `SlideRuleAssembly.swift` - Rule Construction
- `Stator` and `Slide` components
- `SlideRule`: Complete rule assembly
- `RuleDefinitionParser`: Parses PostScript-style definitions
- Rule dimension handling

#### 6. `ScaleUtilities.swift` - Advanced Features
- `ConcurrentScaleGenerator`: Async/await scale generation
- `ScaleInterpolation`: Value finding and interpolation
- `ScaleValidator`: Validation of scale definitions
- `ScaleAnalysis`: Statistical analysis
- `ScaleExporter`: CSV and JSON export

#### 7. `Examples.swift` - Usage Examples
- Comprehensive examples of all features
- Quick reference documentation
- Best practices demonstrations

## Usage

### Basic Scale Creation

```swift
// Create a standard C scale
let cScale = StandardScales.cScale(length: 250.0)

// Generate all tick marks
let generated = GeneratedScale(definition: cScale)

// Find position of a value
let position = ScaleCalculator.normalizedPosition(for: 2.5, on: cScale)
print("2.5 is at position \(position)") // 0.0 = left, 1.0 = right

// Find value at a position
let value = ScaleCalculator.value(at: 0.5, on: cScale)
print("Value at midpoint: \(value)") // Should be ≈3.162 (√10)
```

### Custom Scale Creation

```swift
let customScale = ScaleBuilder()
    .withName("MyScale")
    .withFunction(LogarithmicFunction())
    .withRange(begin: 1, end: 100)
    .withLength(300.0)
    .withTickDirection(.up)
    .withSubsections([
        ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [10.0, 1.0, 0.1],
            labelLevels: [0, 1],
            labelFormatter: StandardLabelFormatter.integer
        )
    ])
    .addConstant(value: .pi, label: "π", style: .major)
    .build()
```

### Parsing Rule Definitions

```swift
// Parse a complete slide rule from PostScript-style definition
let dimensions = RuleDefinitionParser.Dimensions(
    topStatorMM: 14,
    slideMM: 13,
    bottomStatorMM: 14
)

let rule = try RuleDefinitionParser.parse(
    "(K A [ C T ST S ] D L : LL1 LL2 [ CI C ] D)",
    dimensions: dimensions,
    scaleLength: 250.0
)

// Access components
let frontScales = rule.frontTopStator.scales
let slideScales = rule.frontSlide.scales
```

### Concurrent Generation

```swift
@available(macOS 13.0, iOS 16.0, *)
func generateMultipleScales() async {
    let definitions = [
        StandardScales.cScale(),
        StandardScales.dScale(),
        StandardScales.aScale()
    ]
    
    let generator = ConcurrentScaleGenerator()
    let generated = await generator.generateScales(definitions)
    
    // All scales generated concurrently
    for scale in generated {
        print("\(scale.definition.name): \(scale.tickMarks.count) ticks")
    }
}
```

## Key Design Decisions

### 1. Protocol-Oriented Design
All scale functions conform to `ScaleFunction`, enabling:
- Easy addition of new scale types
- Type-safe function composition
- Clear mathematical abstractions

### 2. Value Semantics
All model types are `struct`s (value types):
- No shared mutable state
- Thread-safe by default
- Clear data flow

### 3. Sendable Compliance
All types are marked `Sendable` for Swift 6:
- Safe concurrent access
- No data races
- Actor-friendly

### 4. Separation of Concerns
- **Models**: Pure data (SlideRuleModels.swift)
- **Definitions**: Configuration (ScaleDefinition.swift)
- **Calculation**: Pure functions (ScaleCalculator.swift)
- **Assembly**: Component composition (SlideRuleAssembly.swift)
- **Utilities**: Analysis and export (ScaleUtilities.swift)

### 5. Functional Style
- Immutable data structures
- Pure functions without side effects
- Higher-order functions where appropriate
- Composition over inheritance

### 6. No Drawing Code
This is a **calculation engine only**. Drawing/rendering is intentionally separate because:
- Different platforms (iOS, macOS, visionOS) need different rendering
- PDF, SVG, Canvas all have different APIs
- Calculations are reusable across all rendering backends
- Easier to test without UI dependencies

## How to Integrate with Drawing

When you're ready to draw, you'll have all the data you need:

```swift
let scale = GeneratedScale(definition: StandardScales.cScale())

// For each tick mark:
for tick in scale.tickMarks {
    let x = tick.normalizedPosition * totalWidth  // Convert to actual pixels
    let height = tick.style.relativeLength * maxTickHeight
    let lineWidth = tick.style.lineWidth
    
    // Now draw with your preferred framework:
    // - Core Graphics: CGContext
    // - SwiftUI: Path
    // - PDFKit: PDFContext
    // - etc.
}
```

## Mathematical Background

### Scale Functions

Different types of calculations require different scale functions:

1. **Logarithmic (C, D scales)**: `f(x) = log₁₀(x)`
   - For multiplication and division
   - Most common scale type

2. **Half-logarithmic (A scale)**: `f(x) = 0.5 × log₁₀(x)`
   - Reads squares on D scale
   - For x² calculations

3. **Log-log (LL scales)**: `f(x) = log₁₀(ln(x))`
   - For exponentials and roots
   - For x^y calculations

4. **Trigonometric (S, T scales)**: `f(x) = log₁₀(sin(x))`
   - For angle calculations
   - Combined with C/D for trigonometric operations

### Slide Rule Principle

The fundamental principle (from Pasquale's work):

```
h(x, y, z) = f⁻¹(f(x) + g(y) - g(z))
```

This formula shows that a slide rule can calculate any function that can be expressed in this form. For multiplication:
- `f(x) = log(x)`, `g(y) = log(y)`, `z = 1`
- `h(x, y, 1) = 10^(log(x) + log(y) - log(1)) = xy`

## Testing Strategy

Recommended test categories:

1. **Mathematical Accuracy**
   - Verify transform/inverse round-trips
   - Check position calculations against known values
   - Validate mathematical principles

2. **Scale Generation**
   - Verify tick mark counts
   - Check subsection boundaries
   - Validate label generation

3. **Parser**
   - Test valid definitions
   - Test error cases
   - Test edge cases (empty, malformed)

4. **Concurrency**
   - Verify thread safety
   - Test concurrent generation
   - Check for data races

## Performance Considerations

- Scale generation is O(n) where n = number of ticks
- Position lookup is O(1) - direct calculation
- Tick finding is O(log n) if sorted
- Memory usage: ~100 bytes per tick mark
- A typical scale: 100-500 tick marks = 10-50 KB

## Future Enhancements

Possible extensions (not in current implementation):

1. **Scale Optimizations**
   - Adaptive tick generation based on scale length
   - Density-aware subsection selection

2. **Additional Scale Types**
   - Hyperbolic functions (sinh, cosh, tanh)
   - Specialized engineering scales
   - Custom units (currency, temperature)

3. **Interactive Features**
   - Cursor position tracking
   - Alignment algorithms
   - Calculation assistants

4. **Persistence**
   - Save/load scale definitions
   - Custom scale libraries
   - User preferences

## References

1. **Mathematical Foundations of the Slide Rule**
   Joseph Pasquale, UC San Diego, 2011
   - Rigorous mathematical treatment
   - General principle derivation

2. **PostScript Slide Rule Engine**
   Derek Pressnall, 2011
   - GPL v3 licensed
   - Scale definition format
   - Rule assembly approach

3. **The Slide Rule: A Historical Perspective**
   Florian Cajori, 1910
   - Historical context
   - Evolution of designs

## License

This implementation follows the spirit of the original PostScript engine (GPL v3) and mathematical foundations papers, adapted to modern Swift with original design decisions for iOS/macOS development.

## Contributing

When adding new scale types:
1. Implement the `ScaleFunction` protocol
2. Add factory method to `StandardScales`
3. Include mathematical documentation
4. Add validation tests
5. Provide usage examples

## Support

For questions about:
- **Mathematical principles**: See Pasquale's paper
- **Scale definitions**: See PostScript engine documentation
- **Swift implementation**: Review Examples.swift
- **Integration**: Check the drawing integration section above
