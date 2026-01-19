# Log-Log Scale Formatting: Labeling and Tick Heights for Small Values

This document captures lessons learned from implementing custom label formatters and tick height control for LL03 scale subsections, particularly when dealing with small floating-point values (0.01-0.1 range) and matching historical Faber-Castell 62/83N tick patterns.

## Problem Overview

When implementing Faber-Castell 62/83N style labeling for the LL03 scale, we encountered several challenges:

1. **Selective labeling** - Only certain tick values should be labeled (e.g., even hundredths like 0.08, 0.06, 0.04, 0.02)
2. **Special notation** - Some values need special display (e.g., 0.01 → "10⁻²")
3. **Duplicate labels** - Multiple subsections generating labels for the same value
4. **Floating-point precision** - Values that "look like" 0.01 but aren't exactly 0.01
5. **Tick height control** - Different regions need different tick heights to match historical patterns

## Key Learnings

### 1. String Formatting Comparison is Dangerous for Value Detection

**Problem:** Using `String(format: "%.2f", value) == "0.01"` to detect a specific value will match ANY value that rounds to "0.01" when formatted with 2 decimal places.

```swift
// ❌ DANGEROUS - matches 0.005 to 0.0149999...
let formatted = String(format: "%.2f", rounded)
if formatted == "0.01" {
    return "10⁻²"  // Will trigger for 0.015!
}
```

**Solution:** Use tight numeric range checks instead:

```swift
// ✅ SAFE - only matches values actually close to 0.01
if rounded >= 0.0095 && rounded <= 0.0105 {
    return "10⁻²"
}
```

### 2. Subsection Overlap Creates Duplicate Labels

**Problem:** When two subsections share a boundary value (e.g., one ends at 0.01, next starts at 0.01), BOTH subsections may generate a tick at that value, leading to duplicate labels.

**Example:**
- Subsection A: `startValue: 0.02, tickIntervals: [0.01, ...]` → generates tick at 0.01
- Subsection B: `startValue: 0.01, tickIntervals: [0.01, ...]` → also generates tick at 0.01

**Solution:** Use separate formatters for each subsection where one explicitly skips the boundary value:

```swift
// Subsection A's formatter - labels 0.01 as "10⁻²"
public static let ll03MiddleRangeLower: @Sendable (ScaleValue) -> String = { value in
    if rounded >= 0.0095 && rounded <= 0.0105 {
        return "10⁻²"
    }
    return ""
}

// Subsection B's formatter - skips 0.01 (already labeled by A)
public static let ll03LowerRange: @Sendable (ScaleValue) -> String = { value in
    let formatted = String(format: "%.2f", rounded)
    if formatted == "0.01" {
        return ""  // Skip - already labeled
    }
    return String(format: "%.3f", rounded)
}
```

### 3. Debug Labels are Essential for Troubleshooting

**Technique:** When labels appear incorrectly, add prefix markers to identify which formatter is generating each label:

```swift
// Debug version - add prefixes to trace source
return "[M]10⁻²"   // From Middle formatter
return "[L]0.005"  // From Lower formatter
return "[M]skip"   // Middle formatter returning skip
```

This immediately reveals:
- Which formatter is generating unexpected labels
- Whether the same value is being labeled by multiple formatters
- Which code path is being taken

### 4. Selective Labeling by Digit Pattern

**Requirement:** Only label values where the hundredths digit is EVEN (0.08, 0.06, 0.04, 0.02).

**Implementation:**

```swift
// Extract the hundredths digit
let hundredths = Int((rounded * 100).rounded()) % 10

// Only label if EVEN and non-zero
if hundredths % 2 == 0 && hundredths != 0 {
    return String(format: "%.2f", rounded)
}

// Skip odd digits
return ""
```

**Note:** The `hundredths != 0` check prevents labeling values like 0.10 (where hundredths digit is 0).

### 5. Rounding Before Comparison

**Always round before comparing** to avoid floating-point representation issues:

```swift
// Round to appropriate decimal places first
let rounded = (value * 10000).rounded() / 10000  // 4 decimal places

// Then perform comparisons on rounded value
if rounded >= 0.0095 && rounded <= 0.0105 { ... }
```

### 6. Empty String vs Nil for Suppressing Labels

The `ScaleSubsection.labelFormatter` type is `@Sendable (ScaleValue) -> String` (not `String?`), so you cannot return `nil` to suppress a label.

**Solution:** Return an empty string `""` to suppress the label:

```swift
// ✅ Correct - return empty string to suppress
return ""

// ❌ Wrong - type doesn't allow nil
return nil  // Compiler error
```

## Architecture: Formatter Per Subsection

For complex labeling requirements, create **separate formatters for each subsection** rather than one formatter trying to handle all cases:

```swift
public enum LL03LabelFormatters {
    /// Upper range (0.4 to 0.1): Primary and secondary labels
    public static let ll03UpperRange: @Sendable (ScaleValue) -> String = { ... }
    
    /// Middle upper range (0.1 to 0.02): Even hundredths only
    public static let ll03MiddleRangeUpper: @Sendable (ScaleValue) -> String = { ... }
    
    /// Middle lower range (0.02 to 0.01): Just 10⁻² label
    public static let ll03MiddleRangeLower: @Sendable (ScaleValue) -> String = { ... }
    
    /// Lower range (0.01 to 0.001): Skip 0.01, label others
    public static let ll03LowerRange: @Sendable (ScaleValue) -> String = { ... }
}
```

Then assign each formatter to its corresponding subsection:

```swift
.withSubsections([
    ScaleSubsection(startValue: 0.4, ..., labelFormatter: LL03LabelFormatters.ll03UpperRange),
    ScaleSubsection(startValue: 0.1, ..., labelFormatter: LL03LabelFormatters.ll03MiddleRangeUpper),
    ScaleSubsection(startValue: 0.02, ..., labelFormatter: LL03LabelFormatters.ll03MiddleRangeLower),
    ScaleSubsection(startValue: 0.01, ..., labelFormatter: LL03LabelFormatters.ll03LowerRange),
    // ...
])
```

## Summary Checklist

When implementing custom label formatters for small values:

- [ ] Use numeric range checks, not string comparison, for detecting specific values
- [ ] Account for subsection overlap at boundary values
- [ ] Create separate formatters for each subsection with different labeling rules
- [ ] Return empty string `""` to suppress labels (not `nil`)
- [ ] Round values before comparison to avoid floating-point issues
- [ ] Use debug prefixes `[A]`, `[B]` etc. when troubleshooting duplicate labels
- [ ] Test with cursor to verify labels appear at correct tick positions
- [ ] Use dummy intervals (`10.0`) to control tick heights via level shifting
- [ ] Create debug tests to verify tick heights match expected patterns

---

## Part 2: Controlling Tick Heights with the Level System

### The Tick Level System

Tick heights are controlled by the **level** assigned to each tick, which corresponds to the index in the `tickIntervals` array:

| Level | `relativeLength` | Description |
|-------|------------------|-------------|
| 0     | 0.85             | Full height (labeled ticks) |
| 1     | 0.75             | Tall intermediate |
| 2     | 0.65             | "Halfish" height |
| 3     | 0.4              | Short ticks |

### The Dummy Interval Technique

**Problem:** Ticks generated at a certain interval level are too tall and need to be shorter.

**Solution:** Insert a "dummy" interval (like `10.0`) that never fires but pushes actual intervals to higher level indices (shorter heights).

```swift
// ❌ BEFORE - ticks at 0.0001 are level 1 (tall: 0.75)
ScaleSubsection(
    startValue: 0.001,
    tickIntervals: [0.001, 0.0001, 0.00002],  // 0.0001 is level 1
    ...
)

// ✅ AFTER - ticks at 0.0001 are level 2 (halfish: 0.65)
ScaleSubsection(
    startValue: 0.001,
    tickIntervals: [0.001, 10.0, 0.0001, 0.00002],  // Dummy 10.0 at level 1
    ...                                              // 0.0001 is now level 2
)
```

**Why `10.0`?** Any value larger than the subsection range will never generate ticks, but it occupies a level slot, pushing subsequent intervals to higher levels.

### Consistent Decade Pattern (LL03 Example)

For the LL03 scale, each decade follows this pattern:

| Region | Tick Heights | Implementation |
|--------|--------------|----------------|
| Decade boundary → 5 | 0.65 at "round" positions, 0.4 between | Short ticks for dense area |
| 5 → 2 | 0.4 throughout | Very short for high density |
| 2 → next decade | Exactly 4 ticks at 0.65 | "Halfish" ticks (18, 16, 14, 12 × 10⁻ⁿ) |

**Implementation Pattern:**

```swift
// 10⁻³ to 5 region (0.001 to 0.0005)
ScaleSubsection(
    startValue: 0.001,
    tickIntervals: [0.001, 10.0, 0.0001, 0.00002],  // Dummy level 1, short ticks
    labelLevels: [0],
    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
),

// 5 to 2 region (0.0005 to 0.0002)
ScaleSubsection(
    startValue: 0.0005,
    tickIntervals: [0.0005, 10.0, 0.0001, 0.00002],  // Dummy level 1, short ticks
    labelLevels: [0],
    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
),

// 2 to next decade boundary (0.0002 to 0.0001)
ScaleSubsection(
    startValue: 0.0002,
    tickIntervals: [0.0002, 10.0, 0.00002],  // Dummy level 1, exactly 4 halfish ticks
    labelLevels: [0],
    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
)
```

### Testing Tick Heights

**Create debug tests** to verify tick heights match the expected pattern:

```swift
@Test("Debug 10⁻³ to 10⁻⁴ decade")
func debugDecade3to4() {
    let rangeMin = 0.0001
    let rangeMax = 0.001
    let ticksInRange = ticks.filter { $0.value >= rangeMin && $0.value <= rangeMax }
        .sorted { $0.value > $1.value }
    
    print("\n=== Debug: 10⁻³ to 10⁻⁴ Decade ===")
    for tick in ticksInRange {
        let label = tick.label ?? "(none)"
        let level = tick.style.relativeLength
        print("  \(String(format: "%.7f", tick.value)) → '\(label)' (relLength: \(level))")
    }
    print("==================================\n")
    
    #expect(true)  // Visual inspection test
}
```

**Expected Output Pattern:**

```
=== Debug: 10⁻³ to 10⁻⁴ Decade ===
  0.0010000 → '10⁻³' (relLength: 0.85)     // Labeled decade boundary
  0.0009800 → '(none)' (relLength: 0.4)    // Short tick
  0.0009600 → '(none)' (relLength: 0.4)    // Short tick
  ...
  0.0009000 → '(none)' (relLength: 0.65)   // Halfish at "round" position
  ...
  0.0005000 → '5' (relLength: 0.85)        // Labeled "5"
  0.0004800 → '(none)' (relLength: 0.4)    // Short tick (5→2 region)
  ...
  0.0002000 → '2' (relLength: 0.85)        // Labeled "2"
  0.0001800 → '(none)' (relLength: 0.65)   // Halfish (2→decade region)
  0.0001600 → '(none)' (relLength: 0.65)   // Halfish
  0.0001400 → '(none)' (relLength: 0.65)   // Halfish
  0.0001200 → '(none)' (relLength: 0.65)   // Halfish (exactly 4 ticks)
  0.0001000 → '10⁻⁴' (relLength: 0.85)     // Labeled decade boundary
==================================
```

### Tick Height Verification Checklist

When implementing a new decade:

- [ ] Decade boundary (10⁻ⁿ) has `relLength: 0.85` and correct label
- [ ] "5" position has `relLength: 0.85` and label "5"
- [ ] "2" position has `relLength: 0.85` and label "2"
- [ ] Ticks between decade→5 are short (0.4) with some 0.65 at "round" positions
- [ ] Ticks between 5→2 are all short (0.4)
- [ ] Ticks between 2→next decade are exactly 4 halfish ticks (0.65)
- [ ] No duplicate labels at any position

---

## Part 3: Applying Patterns to Other LL0x Scales

### Scale Ranges Reference

| Scale | Range | Decades | Notes |
|-------|-------|---------|-------|
| LL03 | 0.0001 → ~0.4 (e⁻¹⁰ → e⁻⁰·⁰¹) | 10⁻⁵ → 10⁻¹ | Implemented ✅ |
| LL02 | ~0.9 → ~0.4 (e⁻⁰·¹ → e⁻¹) | Near 1.0 | TODO |
| LL01 | ~0.99 → ~0.9 (e⁻⁰·⁰¹ → e⁻⁰·¹) | Very near 1.0 | TODO |
| LL00 | ~0.999 → ~0.99 (e⁻⁰·⁰⁰¹ → e⁻⁰·⁰¹) | Extremely near 1.0 | TODO |

### Mantissa Detection for Labels

For decade boundaries and key positions, use mantissa detection:

```swift
/// Detects if value is at decade boundary or "2" or "5" position
public static let ll03DecadeRegion: @Sendable (ScaleValue) -> String = { value in
    let rounded = (value * 1000000).rounded() / 1000000
    
    // Check for decade boundaries (10⁻², 10⁻³, 10⁻⁴, 10⁻⁵)
    if rounded >= 0.0095 && rounded <= 0.0105 { return "10⁻²" }
    if rounded >= 0.00095 && rounded <= 0.00105 { return "10⁻³" }
    if rounded >= 0.000095 && rounded <= 0.000105 { return "10⁻⁴" }
    if rounded >= 0.0000095 && rounded <= 0.0000105 { return "10⁻⁵" }
    
    // Check for "5" and "2" positions using mantissa
    let log = log10(rounded)
    let exponent = floor(log)
    let mantissa = rounded / pow(10.0, exponent)
    
    // Mantissa ≈ 5.0 → label "5"
    if abs(mantissa - 5.0) < 0.05 {
        return "5"
    }
    
    // Mantissa ≈ 2.0 → label "2" (TIGHT tolerance to avoid false matches)
    if abs(mantissa - 2.0) < 0.05 {
        return "2"
    }
    
    return ""
}
```

**Critical:** The tolerance for mantissa ≈ 2 must be **tight** (0.05, not 0.15) to avoid labeling values like 1.9 or 2.1 as "2".

### Subsection Structure Template

For each decade in an LL0x scale, follow this template:

```swift
// DECADE n to n+1 (e.g., 10⁻³ to 10⁻⁴)

// Region 1: Decade boundary to "5"
ScaleSubsection(
    startValue: /* decade start, e.g., 0.001 */,
    tickIntervals: [/* start */, 10.0, /* fine */, /* finest */],  // Dummy level 1
    labelLevels: [0],
    labelFormatter: /* decade formatter */
),

// Region 2: "5" to "2"
ScaleSubsection(
    startValue: /* 5 position, e.g., 0.0005 */,
    tickIntervals: [/* start */, 10.0, /* fine */, /* finest */],  // Dummy level 1
    labelLevels: [0],
    labelFormatter: /* decade formatter */
),

// Region 3: "2" to next decade boundary
ScaleSubsection(
    startValue: /* 2 position, e.g., 0.0002 */,
    tickIntervals: [/* start */, 10.0, /* finest for 4 ticks */],  // Dummy level 1
    labelLevels: [0],
    labelFormatter: /* decade formatter */
)
```

### Test File Template

Create a test file for each LL0x scale following this pattern:

```swift
import Testing
@testable import SlideRuleCoreV3

@Suite("LLxx Scale Labels")
struct LLxxScaleLabelTests {
    
    let scale: GeneratedScale
    let ticks: [TickMark]
    
    init() {
        scale = StandardScales.h266LLxx()  // Replace with actual factory
        ticks = scale.tickMarks
    }
    
    // MARK: - Debug Tests (run first to visualize structure)
    
    @Suite("Debug and Diagnostic Tests")
    struct DebugTests {
        let ticks: [TickMark]
        
        init() {
            let scale = StandardScales.h266LLxx()
            ticks = scale.tickMarks
        }
        
        @Test("Debug decade X to Y")
        func debugDecadeXtoY() {
            let rangeMin = /* lower bound */
            let rangeMax = /* upper bound */
            let ticksInRange = ticks.filter { $0.value >= rangeMin && $0.value <= rangeMax }
                .sorted { $0.value > $1.value }
            
            print("\n=== Debug: Decade X to Y ===")
            for tick in ticksInRange {
                let label = tick.label ?? "(none)"
                let level = tick.style.relativeLength
                print("  \(String(format: "%.7f", tick.value)) → '\(label)' (relLength: \(level))")
            }
            print("=============================\n")
            
            #expect(true)
        }
    }
    
    // MARK: - Label Verification Tests
    
    @Suite("Decade Boundary Labels")
    struct DecadeBoundaryLabels {
        // Test each decade boundary has correct label
    }
    
    @Suite("Intermediate '5' Labels")
    struct Intermediate5Labels {
        // Test each "5" position has label "5"
    }
    
    @Suite("Intermediate '2' Labels")
    struct Intermediate2Labels {
        // Test each "2" position has label "2"
    }
}
```

---

## Related Files

- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/LogLog-LL0xScales.swift` - LL01, LL02, LL03 scale implementations
- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/LogLogScales.swift` - LL1, LL2, LL3 (positive) scale implementations
- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift` - `ScaleSubsection` type definition
- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift` - `ScaleBuilder` with boundary suppression
- `SlideRuleCoreV3/Tests/SlideRuleCoreV3Tests/Scales/Individual/LogLogScales/LL03ScaleLabelTests.swift` - Example tests
- `swift-docs/testing-docs/floating-point-rounding-in-formatters.md` - Additional floating-point guidance
- `swift-docs/split-scales-implementation-summary.md` - Comprehensive split scale documentation

---

## Appendix: Existing Boundary Suppression API

The codebase already has **built-in boundary suppression methods** on `ScaleBuilder` for split scales. These were implemented for the Pickett N16 ES Theta scales:

### Available Methods

```swift
// Suppress the BEGIN boundary (position 0.0 / leftmost edge)
.withSuppressBeginBoundaryLabel(_ suppress: Bool = true)
.withSuppressBeginBoundaryTick(_ suppress: Bool = true)

// Suppress the END boundary (position 1.0 / rightmost edge)
.withSuppressEndBoundaryLabel(_ suppress: Bool = true)
.withSuppressEndBoundaryTick(_ suppress: Bool = true)
```

### Example Usage (from Pickett N16 ES Theta scales)

```swift
// THETA SMALL (Θ₁): 6.0° → 0.57°
// - 6.0° is domain start: no tick or label
// - 0.57° is center boundary: no label (shared with Θ₂)
return ScaleBuilder()
    .withName("Θ₁")
    .withRange(begin: 6.0, end: 0.57)
    // ... other configuration ...
    .withSuppressBeginBoundaryTick()  // No tick at 6.0° (position 0.0)
    .withSuppressBeginBoundaryLabel() // No label at 6.0°
    .withSuppressEndBoundaryLabel()   // No label at 0.57° (center boundary)
    .build()
```

### When to Use Each Approach

| Scenario | Recommended Approach |
|----------|---------------------|
| Suppress tick/label at scale boundary (begin/end) | Use `withSuppressBeginBoundary*()` / `withSuppressEndBoundary*()` |
| Suppress specific label values (e.g., "6") | Use `LabelConfiguration.suppressedLabels` (skeleton - not yet implemented) |
| Selective labeling within a range | Use custom `labelFormatter` returning empty string |
| Special notation for specific values | Use custom `labelFormatter` with explicit checks |

### Limitation

The boundary suppression methods only work for the **begin** (position 0.0) and **end** (position 1.0) of a scale. For suppressing labels at **subsection boundaries** within a scale (like 0.01 in the middle of LL03), you must use custom formatters as described in this document.

### Future Enhancement

The `LabelConfiguration.suppressedLabels` API is defined but marked as **SKELETON/STUB**. When implemented, it would allow:

```swift
// Future API (not yet implemented)
LabelConfiguration(suppressedLabels: ["0.01", "6"])
```

This would provide a cleaner declarative approach instead of custom formatters for simple label suppression cases.
