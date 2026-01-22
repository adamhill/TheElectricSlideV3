# Scale Diagnostics Guide

The `ScaleDiagnostics` system provides configurable debug output for scale calculations. All diagnostic code compiles out in Release builds.

## Quick Start

```swift
import SlideRuleCoreV3

// Enable diagnostics for specific scales
ScaleDiagnostics.shared.enableScale("LL02")
ScaleDiagnostics.shared.enableScale("LL03")

// Now run your code - diagnostic output will print to console
let rule = try RuleDefinitionParser.parse("(LL02 [ C ] D)", ...)
```

## Enabling Diagnostics

### By Scale Name

```swift
// Single scale
ScaleDiagnostics.shared.enableScale("LL02")

// Multiple scales
ScaleDiagnostics.shared.enableScale("LL01")
ScaleDiagnostics.shared.enableScale("LL02")
ScaleDiagnostics.shared.enableScale("LL03")

// Unicode variants are matched automatically
// "LL02" will match "LL₀₂" and vice versa
```

### By Category

Categories control what type of diagnostic output is shown:

| Category | Description |
|----------|-------------|
| `.tickGeneration` | Tick mark positions, values, counts |
| `.boundaries` | Subsection boundary calculations |
| `.labels` | Label formatting and placement |
| `.gaugeMarks` | Constants (π, e, C, etc.) |
| `.splitScales` | Split scale segment processing |
| `.positions` | Position calculations and lookups |

```swift
// Enable all tick generation diagnostics (for ALL scales)
ScaleDiagnostics.shared.enableCategory(.tickGeneration)

// Enable boundary calculations only
ScaleDiagnostics.shared.enableCategory(.boundaries)
```

### Using Dictionary Configuration

```swift
ScaleDiagnostics.shared.configure([
    "LL02": true,           // Enable scale by name
    "LL03": true,
    "TickGeneration": true, // Enable category
    "Labels": false         // Explicitly disable
])
```

### Convenience Methods

```swift
// Enable all Log-Log scales (LL0, LL01, LL02, LL03, LL1, LL2, LL3)
ScaleDiagnostics.shared.enableLogLogScales()

// Enable trigonometric scales (S, T, ST, T1, T2, SRT, P)
ScaleDiagnostics.shared.enableTrigScales()

// Enable all categories (verbose mode)
ScaleDiagnostics.shared.enableAllCategories()
```

## Testing Patterns

### In Unit Tests

```swift
import Testing
@testable import SlideRuleCoreV3

@Suite("LL02 Scale Diagnostics")
struct LL02DiagnosticsSuite {
    
    init() {
        // Enable diagnostics before tests run
        ScaleDiagnostics.shared.enableScale("LL02")
        ScaleDiagnostics.shared.enableCategory(.boundaries)
    }
    
    @Test("LL02 tick generation")
    func tickGeneration() throws {
        // Diagnostic output will appear in test console
        let scale = StandardScales.fc283n_LL02Scale(length: 1000)
        let ticks = ScaleCalculator.generateTickMarks(for: scale)
        
        #expect(ticks.count > 0)
    }
}
```

### In App Startup (Debug Only)

```swift
// In TheElectricSlideApp.swift or AppDelegate
#if DEBUG
import SlideRuleCoreV3

func setupDiagnostics() {
    // Configure based on what you're debugging
    ScaleDiagnostics.shared.configure([
        "LL02": true,
        "LL03": true,
        "Boundaries": true
    ])
}
#endif
```

### Interactive Debugging in Xcode

1. Set a breakpoint in your code
2. In the debugger console (lldb), type:
   ```
   po ScaleDiagnostics.shared.enableScale("C")
   ```
3. Continue execution to see diagnostics

## Resetting Diagnostics

```swift
// Clear all enabled scales and categories
ScaleDiagnostics.shared.reset()

// Disable specific items
ScaleDiagnostics.shared.disableScale("LL02")
ScaleDiagnostics.shared.disableCategory(.tickGeneration)
```

## Checking Current Configuration

```swift
// See what's enabled
print(ScaleDiagnostics.shared.currentlyEnabledScales)
print(ScaleDiagnostics.shared.currentlyEnabledCategories)

// Check specific items
if ScaleDiagnostics.shared.isScaleEnabled("LL02") {
    print("LL02 diagnostics are on")
}
```

## Sample Output

When diagnostics are enabled for a scale, you'll see output like:

```
🔍 [ScaleCalculator] Generating ticks for: LL₀₂
   beginValue: 0.001
   endValue: 1.0
   visibleBeginValue: Optional(0.32)
   visibleEndValue: nil
   📐 Subsection[0] boundaries:
      startCandidate: 0.32, endCandidate: 0.4
      domain: [0.001, 1.0], isAscending: true
      visibleEndValue: nil
      → final bounds: lower=0.32, upper=0.4, includeUpper=false
   📊 Subsection[0] generated 8 ticks: min=0.32, max=0.39
   📊 Subsection[1] generated 60 ticks: min=0.4, max=1.0
   ✅ FINAL: 68 ticks, value range: [0.32, 1.0]
   ✓ All ticks >= 0.32 as expected
```

## Adding Diagnostics to New Code

Use the diagnostics API in your own code:

```swift
// Check before expensive debug operations
#if DEBUG
if ScaleDiagnostics.shared.shouldLog(scale: definition.name, category: .labels) {
    print("Label info: \(labelDetails)")
}
#endif

// Or use the convenience logger
ScaleDiagnostics.shared.log(
    scale: definition.name,
    category: .tickGeneration,
    "Generated \(ticks.count) ticks"
)
```

## Thread Safety

`ScaleDiagnostics` is thread-safe. You can enable/disable diagnostics from any thread.

## Performance Note

All diagnostic checks compile to `return false` in Release builds, so there's zero runtime cost in production.
