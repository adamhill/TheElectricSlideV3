# Scale Name Customization System

## Overview

The Electric Slide now supports customizing displayed scale names on a per-slide-rule basis. This allows historical accuracy where different manufacturers labeled the same scale differently (e.g., Hemmi 266 labels the L scale as "dB L").

## Architecture

### 1. ScaleName Enum (`SlideRuleCoreV3/Sources/ScaleName.swift`)

Type-safe enumeration of all known scale names with:
- **Canonical names**: Standard scale identifiers (C, D, CI, L, LL1, etc.)
- **Human-readable descriptions**: Purpose of each scale
- **Aliases**: Alternative names accepted during parsing (e.g., "C10-100" = "C10.100")

```swift
public enum ScaleName: String, CaseIterable, Sendable {
    case c = "C"
    case l = "L"
    case ll1 = "LL1"
    // ... 80+ scale types
    
    public var description: String { /* ... */ }
    public var aliases: [String] { /* ... */ }
    public static func lookup(_ name: String) -> ScaleName? { /* ... */ }
}
```

### 2. Scale Name Overrides Dictionary

`SlideRuleDefinitionModel` now includes a `scaleNameOverrides` property:

```swift
@Model
final class SlideRuleDefinitionModel {
    // ... existing properties
    
    /// Scale name overrides for custom display labels
    /// Key: canonical scale name (e.g., "L")
    /// Value: display name (e.g., "dB L")
    var scaleNameOverrides: [String: String]
}
```

### 3. Override Application

When parsing a slide rule definition, overrides are automatically applied:

```swift
func parseSlideRule(scaleLength: Distance = 1000.0) throws -> SlideRule {
    var rule = try RuleDefinitionParser.parse(/* ... */)
    
    if !scaleNameOverrides.isEmpty {
        rule = applyScaleNameOverrides(to: rule)
    }
    
    return rule
}
```

The `applyScaleNameOverrides` method:
1. Iterates through all scales in the slide rule (front/back, stators/slides)
2. Checks if each scale's canonical name has an override
3. Creates new `ScaleDefinition` with overridden name
4. Preserves all other scale properties (tick marks, formulas, etc.)

## Usage

### Example: Hemmi 266 with "dB L" Label

```swift
static func hemmi266() -> SlideRuleDefinitionModel {
    SlideRuleDefinitionModel(
        name: "Hemmi 266",
        description: "Japanese precision slide rule...",
        definitionString: "(H266LL03 ... D L- S T- : ...)",
        topStatorMM: 15,
        slideMM: 15,
        bottomStatorMM: 15,
        sortOrder: 1,
        scaleNameOverrides: [
            "L": "dB L"  // Display as "dB L" instead of "L"
        ]
    )
}
```

### Example: Multiple Overrides

```swift
SlideRuleDefinitionModel(
    name: "Custom Rule",
    definitionString: "(A [ B CI C ] D L)",
    scaleNameOverrides: [
        "L": "Log₁₀",      // More explicit logarithm label
        "CI": "C⁻¹",       // Mathematical notation for reciprocal
        "A": "x²"          // Direct formula notation
    ]
)
```

## Key Features

### 1. Type Safety
- Use `ScaleName` enum for autocomplete and compile-time checking
- Dictionary keys are strings for SwiftData persistence

### 2. Canonical Name Preservation
- Parser uses canonical names (from `StandardScales` factory)
- Overrides applied post-parsing
- Cursor readings still use canonical names internally

### 3. SwiftData Persistence
- Overrides stored as `[String: String]` dictionary
- Automatic migration support
- No schema changes required for new scale types

### 4. Historical Accuracy
- Each slide rule definition can match original manufacturer labeling
- Preserves historical context (e.g., Hemmi's decibel focus)
- User sees authentic scale labels

## Scale Name Reference

### Basic Scales
- C, D, CI, DI - Logarithmic scales
- A, B, AI, BI - Square scales
- K - Cube scale

### Log-Log Scales
- LL00, LL01, LL02, LL03 (or LL0-LL3) - Exponential scales

### Trigonometric
- S - Sine scale
- T - Tangent scale
- ST - Small tangent scale

### Logarithmic
- L - Common logarithm (log₁₀)
- Ln - Natural logarithm (ln)

### Electrical Engineering (Hemmi 266)
- XL - Inductive reactance
- Xc - Capacitive reactance
- F - Frequency
- r1, r2 - Resistance/Impedance
- Q - Quality factor
- Li - Inductance
- Cf, Cz - Capacitance
- Z - Impedance
- Fo - Resonant frequency

### Full List
See `ScaleName.swift` for complete enumeration of 80+ scale types.

## Implementation Notes

### Performance
- Overrides applied once during parsing (not per render)
- Pre-computed tick marks reused (no recalculation)
- Minimal memory overhead (~8 bytes per override)

### Future Enhancements
Potential additions:
1. **Formula overrides**: Custom formula strings per scale
2. **Color overrides**: Per-rule color customization
3. **UI editor**: Visual scale name editor in app settings
4. **Import/export**: Share custom rule definitions

### Migration Strategy
Existing slide rule definitions work unchanged:
- Empty `scaleNameOverrides` dictionary by default
- No breaking changes to API
- Backward compatible with existing data

## Testing

Verify overrides work correctly:

```swift
let hemmi = SlideRuleLibrary.hemmi266()
let parsed = try hemmi.parseSlideRule(scaleLength: 1000)

// Check front bottom stator for L scale
let lScale = parsed.frontBottomStator.scales.first { $0.definition.name == "dB L" }
XCTAssertNotNil(lScale, "L scale should be overridden to 'dB L'")
```

## Example Customizations

### K&E 4081-3 (Standard)
No overrides needed - uses canonical names.

### Hemmi 266 (Japanese)
```swift
scaleNameOverrides: ["L": "dB L"]
```

### Pickett N3 (NASA Apollo)
No overrides - uses standard naming.

### Future: Faber-Castell 2/83N (German)
```swift
scaleNameOverrides: [
    "ST": "P",  // German "P" for Prozent (percent)
    "K": "W"    // German "W" for Wurfel (cube)
]
```

## Conclusion

The scale name customization system provides:
- ✅ Historical accuracy for manufacturer-specific labeling
- ✅ Type-safe scale name enumeration
- ✅ Simple dictionary-based override mechanism
- ✅ SwiftData persistence support
- ✅ No performance impact on rendering
- ✅ Backward compatible with existing rules
