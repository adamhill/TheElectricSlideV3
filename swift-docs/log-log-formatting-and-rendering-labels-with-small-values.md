# Log-Log Scale Formatting: Labeling Small Values Correctly

This document captures lessons learned from implementing custom label formatters for LL03 scale subsections, particularly when dealing with small floating-point values (0.01-0.1 range).

## Problem Overview

When implementing Faber-Castell 62/83N style labeling for the LL03 scale, we encountered several challenges:

1. **Selective labeling** - Only certain tick values should be labeled (e.g., even hundredths like 0.08, 0.06, 0.04, 0.02)
2. **Special notation** - Some values need special display (e.g., 0.01 → "10⁻²")
3. **Duplicate labels** - Multiple subsections generating labels for the same value
4. **Floating-point precision** - Values that "look like" 0.01 but aren't exactly 0.01

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

## Related Files

- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/LogLogScales.swift` - LL03 scale implementation
- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift` - `ScaleSubsection` type definition
- `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift` - `ScaleBuilder` with boundary suppression
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
