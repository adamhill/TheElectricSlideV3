---
applyTo: "SlideRuleCoreV3/**/*.swift"
---

# SlideRuleCoreV3 Package Guidelines

## Purpose
Pure calculation engine for scale creation, manipulation, tick mark calculations, and value-from-position lookups. **NO drawing/rendering code by design.**

## Platform Compatibility
- **iOS 18+, macOS 15+, Swift 6**
- **Linux Compatible**: Package builds and tests run on Linux runners (Swift 6.2+)
- Use `swift build` to compile, `swift test` to run tests
- Remote agents can fully develop and test this package in CI/CD environments

## Core Files to Understand
- `SlideRuleModels.swift` - Core types: `ScaleFunction`, `TickMark`, `TickStyle`, `ScaleLayout`
- `ScaleDefinition.swift` - Scale configuration and formula strings
- `ScaleCalculator.swift` - Tick mark generation using modulo algorithm
- `StandardScales.swift` - Factory functions for all standard scales (C, D, CI, A, K, LL1-3, S, T, L, etc.)
- `SlideRuleAssembly.swift` - `Stator`, `Slide`, `SlideRule` assembly, `RuleDefinitionParser`

## Key Patterns

### Pre-computed Tick Marks
```swift
// GeneratedScale contains PRE-COMPUTED tick marks - NEVER recalculate
public struct GeneratedScale: Sendable {
    public let definition: ScaleDefinition
    public let tickMarks: [TickMark]  // Already computed during init
}
```

### PostScript-style DSL Parser
```swift
// Parentheses = stators (fixed), Brackets = slide (movable)
// Example: "(DF [ CF CIF CI C ] D ST)" 
let rule = try RuleDefinitionParser.parse(
    "(DF [ CF CIF CI C ] D ST)",
    dimensions: RuleDefinitionParser.Dimensions(...),
    scaleLength: 1000
)
```

## Design Decisions
1. **Sendable Everywhere** - All types conform to `Sendable` for Swift 6 concurrency
2. **Value Semantics** - Immutable structs, no classes except actors
3. **Protocol-Oriented** - `ScaleFunction` protocol for extensibility
4. **No Drawing** - Calculations return data; rendering is a separate responsibility
