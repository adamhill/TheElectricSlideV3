# Scale Testing in SwiftUI Previews

**Date**: December 31, 2025  
**Project**: TheElectricSlide - SlideRuleCoreV3

## Overview

This document describes the debug preview pattern used for testing scale rendering in TheElectricSlide application. The pattern uses reusable SwiftUI components to provide visual feedback, debug information, and pass/fail validation during scale development.

---

## Preview Components

### 1. SplitScaleTestComponent

A specialized component for testing split scales (scales that share physical space, each occupying half the width).

**Location**: [`TheElectricSlide/Previews/Components/SplitScaleTestComponent.swift`](TheElectricSlide/Previews/Components/SplitScaleTestComponent.swift)

#### Purpose

Visualizes and validates split scale rendering with:
- **Dual debug panels** showing both LEFT and RIGHT segment information
- **Color-coded backgrounds** (green = left half, orange = right half)
- **Boundary markers** at the 50% split point
- **Pass/Fail validation** based on tick position tolerance

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `leftScale` | `GeneratedScale` | The left segment scale (positions 0.0...0.5) |
| `rightScale` | `GeneratedScale` | The right segment scale (positions 0.5...1.0) |
| `title` | `String` | Test case title |
| `segmentDescription` | `String` | Description of segment ranges |
| `expectedDescription` | `String` | Expected behavior description |
| `expectedBoundaryPosition` | `CGFloat` | Expected boundary position (typically 0.5) |
| `actualBoundaryPosition` | `CGFloat` | Actual first tick position of right segment |
| `actualFirstTickValue` | `Double` | Actual first tick value of right segment |
| `scaleLength` | `CGFloat` | Physical width in points |
| `scaleHeight` | `CGFloat` | Physical height in points |
| `leftMarginWidth` | `CGFloat` | Left margin for scale name |
| `rightMarginWidth` | `CGFloat` | Right margin for formula |

#### Debug Output Format

```
🔍 Debug Info:
LEFT segment (Θ₁):
  Domain: 6.000 → 0.000
  First tick: value=5.7100, pos=0.0000
  Last tick: value=0.0000, pos=1.0000
  Expected: pos 0.00→0.50 (left half)

RIGHT segment (Θ₂):
  Domain: 0.000 → 5.710
  First tick: value=0.0000, pos=0.5000
  Last tick: value=5.7100, pos=1.0000
  Expected: pos 0.50→1.00 (right half)

Validation: Left ✓, Right ✓ → ✓ PASS
```

#### Usage Example

```swift
SplitScaleTestComponent(
    leftScale: thetaSmall,
    rightScale: thetaLarge,
    title: "THETA Scales (Θ₁ ^ Θ₂) - Split Scale Architecture",
    segmentDescription: "Left: Θ₁ (6.0°→0.57°), Right: Θ₂ (0.01°→5.71°)",
    expectedDescription: "Expected: Both segments share baseline with ticks UP, split at 50%",
    expectedBoundaryPosition: 0.5,
    actualBoundaryPosition: thetaLarge.tickMarks.first?.normalizedPosition ?? 0.0,
    actualFirstTickValue: thetaLarge.tickMarks.first?.value ?? 0.0,
    scaleLength: 800,
    scaleHeight: 40,
    leftMarginWidth: 60,
    rightMarginWidth: 80
)
```

---

### 2. ScalePairTestComponent

A component for testing non-split scale pairs (vertically stacked scales that share alignment).

**Location**: [`TheElectricSlide/Previews/Components/ScalePairTestComponent.swift`](TheElectricSlide/Previews/Components/ScalePairTestComponent.swift)

#### Purpose

Visualizes and validates paired scale rendering with:
- **Debug panel** showing all scale information
- **Boundary markers** at 0% (red) and 100% (blue)
- **Tick direction indicators** (upward/downward)
- **Flexible stacking** for 1+ scales

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `scales` | `[GeneratedScale]` | Array of scales to display (1 or more) |
| `title` | `String` | Test case title |
| `description` | `String` | Description of the scale pairing |
| `scaleLength` | `CGFloat` | Physical width in points |
| `scaleHeight` | `CGFloat` | Physical height in points |
| `leftMarginWidth` | `CGFloat` | Left margin for scale name |
| `rightMarginWidth` | `CGFloat` | Right margin for formula |
| `stackSpacing` | `CGFloat` | Vertical spacing between scales (default: 4pt) |

#### Debug Output Format

```
🔍 Debug Info:
Scale 1: LL00 (upward ticks) - Range: 0.9900 → 0.9990
Scale 2: C (downward ticks) - Range: 1.0000 → 10.0000
```

#### Usage Example

```swift
ScalePairTestComponent(
    scales: [ll00, cWithDownTicks],
    title: "Pair 1: LL00 + C",
    description: "LL00 (upward ticks) paired with C scale (downward ticks)",
    scaleLength: 800,
    scaleHeight: 40,
    leftMarginWidth: 60,
    rightMarginWidth: 80
)
```

---

## Preview Files

### SplitScalesPreview.swift

**Location**: [`TheElectricSlide/Previews/SplitScalesPreview.swift`](TheElectricSlide/Previews/SplitScalesPreview.swift)

Tests the split scale infrastructure with four test cases:

1. **Test Case 1**: Simple C Scale 50/50 Split
   - Left: C₁ (1→√10), Right: C₂ (√10→10)

2. **Test Case 2**: Hemmi 266 LL01^/LL02B Pattern
   - Reciprocal log-log scales split pattern

3. **Test Case 3**: Hyperbolic Sh1/Sh2 Pattern
   - Tests natural overlap at boundary

4. **Test Case 4**: Parser Integration Test
   - Tests `A^ B C` syntax parsing

---

### LogLogScalesPreview.swift

**Location**: [`TheElectricSlide/Previews/LogLogScalesPreview.swift`](TheElectricSlide/Previews/LogLogScalesPreview.swift)

Tests Log-Log scale pairs using `ScalePairTestComponent`:

1. **Pair 1**: LL00 + C
   - LL00 (e^-0.01 to e^-0.001, upward ticks)
   - C (1 to 10, downward ticks)

2. **Pair 2**: LL0 + C
   - LL0 (e^0.001 to e^0.01, upward ticks)
   - C (1 to 10, downward ticks)

---

### PickettN16ESPreview.swift

**Location**: [`TheElectricSlide/Previews/PickettN16ESPreview.swift`](TheElectricSlide/Previews/PickettN16ESPreview.swift)

Tests Pickett N-16 ES phase angle scales:

1. **THETA Scales** (using `SplitScaleTestComponent`)
   - Θ₁ (THETA SMALL): 6.0° → 0.57° (left half)
   - Θ₂ (THETA LARGE): 0.01° → 5.71° (right half)

2. **ALPHA Scale** (using `ScalePairTestComponent`)
   - α: 84.29° → 5.71° (full width)

---

## Debug Pattern Best Practices

### 1. Always Show First and Last Tick

The debug output should show both extremes:

```swift
let leftFirstTick = leftScale.tickMarks.first
let leftLastTick = leftScale.tickMarks.last
let leftDebugText = """
LEFT segment (\(leftScale.definition.name)):
  Domain: \(String(format: "%.3f", leftScale.definition.beginValue)) → \(String(format: "%.3f", leftScale.definition.endValue))
  First tick: value=\(String(format: "%.4f", leftFirstTick?.value ?? 0)), pos=\(String(format: "%.4f", leftFirstTick?.normalizedPosition ?? 0))
  Last tick: value=\(String(format: "%.4f", leftLastTick?.value ?? 0)), pos=\(String(format: "%.4f", leftLastTick?.normalizedPosition ?? 0))
"""
```

### 2. Use Color-Coded Validation

Visual pass/fail indicators are essential:

```swift
let leftPassed = (leftLastTick?.normalizedPosition ?? 0) <= 0.52  // tolerance for 0.50
let rightPassed = (rightFirstTick?.normalizedPosition ?? 0) >= 0.48
let overallPassed = leftPassed && rightPassed

Text("Validation: Left \(leftPassed ? "✓" : "✗"), Right \(rightPassed ? "✓" : "✗") → \(overallPassed ? "✓ PASS" : "✗ FAIL")")
    .foregroundColor(overallPassed ? .green : .red)
```

### 3. Enable Text Selection

Allow developers to copy debug values:

```swift
Text(debugText)
    .font(.system(size: 10, weight: .medium).monospaced())
    .textSelection(.enabled)  // Critical for debugging
```

### 4. Use Colored Backgrounds

Visual segmentation helps identify positioning issues:

```swift
HStack(spacing: 0) {
    Color.green.opacity(0.25)
        .frame(width: scaleLength / 2, height: scaleHeight)
    Color.orange.opacity(0.25)
        .frame(width: scaleLength / 2, height: scaleHeight)
}
```

### 5. Include Measurement Ruler

A dual-unit ruler (percentage + points) aids debugging:

```swift
// Shows: 0% (0pt), 25% (200pt), 50% (400pt), 75% (600pt), 100% (800pt)
ForEach(0..<21) { i in
    let percentage = Double(i) * 5.0
    let pointValue = scaleLength * CGFloat(percentage / 100.0)
    // Render tick and labels at each position
}
```

---

## Creating a New Preview

### Step 1: Define Generated Scales

```swift
private var myScale: GeneratedScale {
    GeneratedScale(definition: StandardScales.myScale(length: scaleLength))
}
```

### Step 2: Choose Component Type

- **Split scales**: Use `SplitScaleTestComponent`
- **Paired/stacked scales**: Use `ScalePairTestComponent`
- **Custom layout**: Create a new component following the pattern

### Step 3: Add Multiple Preview Configurations

```swift
#Preview("Default Configuration") {
    MyScalesPreview()
}

#Preview("Compact (iPhone)") {
    MyScalesPreview(scaleLength: 600, scaleHeight: 35)
}

#Preview("Large (iPad)") {
    MyScalesPreview(scaleLength: 1000, scaleHeight: 50)
}

#Preview("Dark Mode") {
    MyScalesPreview()
        .preferredColorScheme(.dark)
}
```

---

## Debugging Workflow

### When a Test Fails

1. **Read the debug output** - Check domain ranges and tick positions
2. **Verify domain range** - Is the scale's `beginValue`/`endValue` correct?
3. **Check split segment** - Is `.withSplitSegment()` applied to the correct side?
4. **Verify transform function** - Does the function output 0→1 for the domain range?
5. **Check subsections** - Do subsection boundaries align with the scale range?

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| All ticks at left edge | Missing `.withSplitSegment()` | Add `.withSplitSegment(.right(...))` |
| Wrong domain shown | Incorrect `begin`/`end` values | Fix `withRange()` parameters |
| Position 0.0 instead of 0.5 | Right segment not configured | Add split segment configuration |
| Missing boundary tick | Subsection doesn't include boundary | Use boundary tick injection |

---

## Validation Tolerance

The components use a 2% tolerance for position validation:

```swift
// For split scales at 50%:
let leftPassed = (leftLastTick?.normalizedPosition ?? 0) <= 0.52   // 50% + 2%
let rightPassed = (rightFirstTick?.normalizedPosition ?? 0) >= 0.48 // 50% - 2%
```

This accounts for:
- Floating-point rounding errors
- Boundary tick positioning variations
- Subsection boundary effects

---

## Related Documentation

- [`split-scales-implementation-summary.md`](split-scales-implementation-summary.md) - Complete split scales architecture
- [`ScaleDefinition.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift) - SplitSegment enum definition
- [`ScaleCalculator.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleCalculator.swift) - Tick generation and boundary injection

---

**Document Version**: 1.0  
**Date**: December 31, 2025  
**Author**: TheElectricSlide Development Team
