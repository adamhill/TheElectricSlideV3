# Scale Marks UX Improvements

**Date**: October 25, 2025  
**Branch**: adamhill/2-improve-perf-instruments  
**Status**: In Progress

## Problem Statement

The K, S, and LL3 scales currently have crowded labels that make them difficult to read on mobile devices (phones and tablets). Analysis reveals significant discrepancies between the PostScript reference implementation and our Swift implementation:

### Discrepancy Summary

| Scale | PostScript Subsections | Swift Subsections | Missing |
|-------|------------------------|-------------------|---------|
| **K** (Cube, 1-1000) | 10 | 3 | 7 |
| **S** (Sine, 5.7°-90°) | 7 | 3 | 4 |
| **LL3** (e^x, 2.74-21000) | 17 | 5 | 12 |

### Root Causes

1. **Missing Subsections**: Swift implementations are simplified versions lacking the fine-grained subsection control of PostScript
2. **Over-labeling**: Current `labelLevels` show too many labels in dense regions
3. **No Adaptive Logic**: Labels don't adjust based on scale physical length (critical for phones vs tablets)
4. **No Density Tests**: No automated checks prevent label crowding regressions

## Design Goals

### Target Dimensions

- **Phone (5-inch slide rule)**: ~360pt physical scale length
  - iPhone 16 Pro: 393pt wide → ~360pt usable after margins
  - Minimum label spacing: **12pt** (≈30 labels max)
  
- **Tablet (10-inch slide rule)**: ~720pt physical scale length  
  - iPad Air: 820pt wide → ~720pt usable after margins
  - Minimum label spacing: **10pt** (≈72 labels max)

### Legibility Requirements (from Apple HIG)

1. **Font Size**: Minimum 10-11pt for labels (body style)
2. **Font Weight**: Regular or Medium (avoid Light/Thin)
3. **Spacing**: Labels must not overlap or feel cramped
4. **Hierarchy**: Use size/weight variation, not excessive typeface changes
5. **Dynamic Type**: Support system text size preferences (future consideration)

### UX Principles

- **Historical Accuracy**: Preserve PostScript fidelity where practical
- **Progressive Disclosure**: Show fewer labels at small scales, more when zoomed
- **Visual Breathing Room**: Minimum 10-12pt between adjacent labels
- **Predictable Density**: Consistent labeling patterns across scale ranges

## Solution Architecture

### Hybrid Approach (Option 3 + Option 2 Elements)

**Strategy**: 
1. Add ALL PostScript subsections for perfect fidelity
2. Comment out non-essential subsections for initial deployment
3. Implement adaptive label reduction based on scale length
4. Add density tests to prevent regressions

**Rationale**:
- Preserves complete PostScript definitions as reference documentation
- Provides practical usability out-of-the-box
- Allows future fine-tuning by uncommenting subsections
- Ensures testable, maintainable constraints

## Implementation Plan

### Phase 1: K Scale Improvements ✅ COMPLETE

**Status**: All improvements implemented (2025-10-25 to 2025-10-26)

**Three Critical Issues Fixed**:

1. **Tick Generation Algorithm** (over-generation of tick marks)
   - **Problem**: Legacy algorithm generated ticks for every interval level separately, creating hundreds of duplicate tick marks
   - **Fix**: Changed `ScaleCalculator.defaultAlgorithm` from `.legacy` to `.modulo(config: .default)`
   - **File**: `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleCalculator.swift` line 107
   - **Result**: Correct tick density matching PostScript print - each tick generated once at coarsest level

2. **All 10 PostScript Subsections Added** (matching reference implementation)
   - **Problem**: Swift implementation only had 3 subsections vs PostScript's 10
   - **Fix**: Added complete subsection definitions (1-3, 3-6, 6-10, 10-30, 30-60, 60-100, 100-300, 300-600, 600-1000, 1000)
   - **File**: `SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift` lines 411-520
   - **Result**: Perfect fidelity to PostScript intervals and tick spacing

3. **Unified K Scale Formatter** (compact decade display with power-of-10 exceptions)
   - **Problem**: Used `StandardLabelFormatter.integer` showing full values everywhere (10, 20, 100, 200, 1000)
   - **PostScript Pattern**: Shows actual values at power-of-10 boundaries, compact elsewhere
   - **Fix**: Implemented single unified formatter using `ClosedRange.contains()` for boundary detection
   - **File**: `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift` lines 330-358
   
**Unified K Scale Formatter** (Range-based interval logic):

```swift
/// K scale formatter: shows actual value at power-of-10 boundaries, compact form elsewhere
/// Examples: 10→"10", 20→"2", 100→"100", 200→"2", 1000→"1000"
/// Uses ClosedRange to properly detect the power-of-10 boundaries
public static let kScale: @Sendable (ScaleValue) -> String = { value in
    // Define all power-of-10 boundaries
    let tenBoundary: ClosedRange<Double> = 9.5...10.5
    let hundredBoundary: ClosedRange<Double> = 99.5...100.5
    let thousandBoundary: ClosedRange<Double> = 995.0...1005.0
    
    // Check boundaries and show actual values
    if thousandBoundary.contains(value) { return "1000" }
    if hundredBoundary.contains(value) { return "100" }
    if tenBoundary.contains(value) { return "10" }
    
    // For non-boundary values, use appropriate division
    if value >= 100.0 {
        // 100-1000 range: divide by 100 (200→"2", 300→"3", etc.)
        let divided = value / 100.0
        return String(Int(divided.rounded()))
    } else if value >= 10.0 {
        // 10-100 range: divide by 10 (20→"2", 30→"3", etc.)
        let divided = value / 10.0
        return String(Int(divided.rounded()))
    } else {
        // 1-10 range: show as integer
        return String(Int(value.rounded()))
    }
}
```

**Key Design Decision - Range-Based Boundaries**:
- Replaced epsilon comparison (`abs(value - 100.0) < 0.01`) with `ClosedRange.contains()`
- Uses interval arithmetic: `(99.5...100.5).contains(value)` for 100 boundary
- Wider tolerance for 1000 (±5) to handle floating-point drift
- Matches Swift's idiomatic interval checking patterns

**Final Label Pattern**:
- **1-10 range**: "1 2 3 4 5 6 7 8 9 10" (actual values)
- **10-100 range**: "10 2 3 4 5 6 7 8 9 100" (10 and 100 show actual, middle shows compact)
- **100-1000 range**: "100 2 3 4 5 6 7 8 9 1000" (100 and 1000 show actual, middle shows compact)

**Test Coverage**:
- Created comprehensive test suite: `SlideRuleCoreV3Tests/KScaleFormatterTests.swift`
- Tests verify power-of-10 boundaries display correctly (10→"10", 100→"100", 1000→"1000")
- Tests verify compact display for intermediate values (20→"2", 300→"3")
- Tests verify Range-based interval logic works correctly
- Regression tests prevent original bugs from reoccurring

This matches real slide rules and PostScript output exactly!

#### Step 1.1: Add Complete K Scale Subsections ✅ COMPLETE

**Implementation**: All 10 PostScript subsections added to `StandardScales.swift` (lines 411-520)

**Key Changes**:
1. **Subsection 1 (1-3)**: Dense subdivisions [1, 0.5, 0.1, 0.05], labels at 1, 2, 3
2. **Subsection 2 (3-6)**: Medium density [1, 0.5, 0.1], labels at 3, 4, 5, 6
3. **Subsection 3 (6-10)**: Coarser [1, 0.2], labels at 6, 7, 8, 9, 10
4. **Subsections 4-6 (10-100)**: Decade scaling with compact formatter
5. **Subsections 7-9 (100-1000)**: Hundreds scaling with compact formatter
6. **Subsection 10 (1000)**: Endpoint with no labels (handled by subsection 9)

**Applied Formatter**: `StandardLabelFormatter.kScale` to subsections 4-9

**Label Count**: ~13 primary labels (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 1000) + compact labels

**Verification**:
- ✅ Built and ran on macOS
- ✅ K scale displays correct compact decade pattern
- ✅ No label overlapping
- ✅ Power-of-10 boundaries show actual values

---

#### Step 1.2: Unified K Scale Formatter ✅ COMPLETE

**Implementation**: Single unified formatter in `ScaleDefinition.swift` (lines 330-358)

**Design Decision**: Range-based interval logic instead of epsilon comparison
- **Old approach** (buggy): `if abs(value - 100.0) < 0.01 { return "10" }`
- **New approach**: `if (99.5...100.5).contains(value) { return "100" }`

**Key Features**:
```swift
public static let kScale: @Sendable (ScaleValue) -> String = { value in
    // Define all power-of-10 boundaries with appropriate tolerances
    let tenBoundary: ClosedRange<Double> = 9.5...10.5
    let hundredBoundary: ClosedRange<Double> = 99.5...100.5
    let thousandBoundary: ClosedRange<Double> = 995.0...1005.0  // Wider for FP drift
    
    // Check boundaries first (highest to lowest)
    if thousandBoundary.contains(value) { return "1000" }
    if hundredBoundary.contains(value) { return "100" }
    if tenBoundary.contains(value) { return "10" }
    
    // Apply range-based division
    if value >= 100.0 { return String(Int((value / 100.0).rounded())) }
    if value >= 10.0 { return String(Int((value / 10.0).rounded())) }
    return String(Int(value.rounded()))
}
```

**Advantages over epsilon math**:
1. **Type-safe intervals**: Compiler checks boundary definitions
2. **Idiomatic Swift**: Uses `ClosedRange` and `contains()` method
3. **Clearer intent**: Interval membership vs. distance calculation
4. **Easier to adjust**: Change `99.5...100.5` to widen/narrow boundary
5. **Documented pattern**: See `reference/range-based-boundary-handling-design.md`

**Verification**:
- ✅ Tests pass: `KScaleFormatterTests.swift` validates all boundaries
- ✅ Power-of-10 values display correctly: 10→"10", 100→"100", 1000→"1000"
- ✅ Intermediate values show compact form: 20→"2", 300→"3"
- ✅ No epsilon comparison bugs

---

### UI Typography Improvements ✅ COMPLETE

**Status**: Scale name alignment fixed (2025-10-26)

**Issue**: Scale name labels (C, D, K, LL01, etc.) appeared centered instead of right-aligned, creating visual inconsistency when mixing single-character and multi-character labels.

**Root Cause**: Fixed width frame (`width: 20`) centers content when text is shorter than container width.

**Fix**: Changed to minimum width with trailing alignment
- **File**: `TheElectricSlide/ContentView.swift` line 36
- **Old code**: `.frame(width: 20, alignment: .trailing)`
- **New code**: `.frame(minWidth: 28, alignment: .trailing)`

**Result**:
- Single-character labels (C, D, K, A, B) right-align properly
- Multi-character labels (LL01, LL1-) expand frame naturally
- All labels align consistently against tick marks
- Increased minimum width from 20pt to 28pt to accommodate longer labels

**Visual Impact**: Clean right-edge alignment for all scale names, professional typography

---

### Phase 2: S Scale Improvements ⏳ PENDING

**Current State**: 3 subsections, single labeling

**Target State**: 7 PostScript subsections with dual labeling capability

#### Step 2.1: Add Complete S Scale Subsections

Add all 7 PostScript subsections (PostScript lines 592-600):

```swift
// S scale subsections
.withSubsections([
    // 5.7-10°: Very dense for small angles
    ScaleSubsection(
        startValue: 5.7,
        tickIntervals: [1.0, 0.5, 0.1, 0.05],
        labelLevels: [0],  // Only major angles labeled
        labelFormatter: StandardLabelFormatter.angle
    ),
    
    // 10-20°: Medium density
    ScaleSubsection(
        startValue: 10.0,
        tickIntervals: [5.0, 1.0, 0.5, 0.1],
        labelLevels: [0],  // 10°, 15°, 20°
        labelFormatter: StandardLabelFormatter.angle
    ),
    
    // COMMENTED OUT - Uncomment for dual sine/cosine labeling
    // // 20-30°: Transition zone
    // ScaleSubsection(
    //     startValue: 20.0,
    //     tickIntervals: [5.0, 1.0, 0.5],
    //     labelLevels: [0],
    //     labelFormatter: StandardLabelFormatter.angle
    // ),
    
    // 30-60°: Mid-range angles
    ScaleSubsection(
        startValue: 30.0,
        tickIntervals: [10.0, 5.0, 1.0, 0.5],
        labelLevels: [0],  // 30°, 40°, 50°, 60°
        labelFormatter: StandardLabelFormatter.angle
    ),
    
    // COMMENTED OUT
    // // 60-80°: Approaching 90°
    // ScaleSubsection(
    //     startValue: 60.0,
    //     tickIntervals: [10.0, 5.0, 1.0],
    //     labelLevels: [0],
    //     labelFormatter: StandardLabelFormatter.angle
    // ),
    
    // COMMENTED OUT
    // // 80-90°: Very coarse, near vertical
    // ScaleSubsection(
    //     startValue: 80.0,
    //     tickIntervals: [10.0, 5.0],
    //     labelLevels: [],  // No labels, just tick at 90°
    //     labelFormatter: StandardLabelFormatter.angle
    // ),
    
    // 90°: Endpoint
    ScaleSubsection(
        startValue: 90.0,
        tickIntervals: [10.0],
        labelLevels: [0],
        labelFormatter: StandardLabelFormatter.angle
    )
])
```

**Label Count Estimate**: ~9 labels (10°, 15°, 20°, 30°, 40°, 50°, 60°, 70°, 80°, 90°)

**Note on Dual Labeling**: PostScript shows both sine (ascending) and cosine (90° - x, descending) labels. This is visually complex and deferred to future enhancement.

**Verification**:
- Check angle labels end with ° symbol
- Labels should be evenly distributed across scale
- No overlapping labels

---

### Phase 3: LL3 Scale Improvements ✅ TODO

**Current State**: 5 subsections, huge exponential range (2.74 to 21,000)

**Target State**: 17 PostScript subsections with progressive coarsening

#### Step 3.1: Add Complete LL3 Scale Subsections

Add all 17 PostScript subsections (PostScript lines 1426-1442):

```swift
// LL3 scale subsections - exponential e^x range
.withSubsections([
    // 2.6-4: Very fine divisions for e^1 region
    ScaleSubsection(
        startValue: 2.6,
        tickIntervals: [1.0, 0.5, 0.1, 0.02],
        labelLevels: [0]  // Show only major values
    ),
    
    // 4-6: Slightly coarser
    ScaleSubsection(
        startValue: 4.0,
        tickIntervals: [1.0, 0.5, 0.1, 0.05],
        labelLevels: [0]
    ),
    
    // COMMENTED OUT - Uncomment for high-precision displays
    // // 6-10: Transition to decades
    // ScaleSubsection(
    //     startValue: 6.0,
    //     tickIntervals: [1.0, 0.5, 0.1],
    //     labelLevels: [0]
    // ),
    
    // 10-15: Lower decades
    ScaleSubsection(
        startValue: 10.0,
        tickIntervals: [5.0, 1.0, 0.2],
        labelLevels: [0]  // 10, 15
    ),
    
    // COMMENTED OUT
    // // 15-20
    // ScaleSubsection(
    //     startValue: 15.0,
    //     tickIntervals: [5.0, 1.0, 0.5],
    //     labelLevels: [0]
    // ),
    
    // 20-30
    ScaleSubsection(
        startValue: 20.0,
        tickIntervals: [10.0, 5.0, 1.0, 0.5],
        labelLevels: [0]  // 20, 30
    ),
    
    // COMMENTED OUT
    // // 30-50
    // ScaleSubsection(
    //     startValue: 30.0,
    //     tickIntervals: [10.0, 5.0, 1.0],
    //     labelLevels: [0]
    // ),
    
    // 50-100
    ScaleSubsection(
        startValue: 50.0,
        tickIntervals: [50.0, 10.0, 2.0],
        labelLevels: [0]  // 50, 100
    ),
    
    // 100-200: Hundreds
    ScaleSubsection(
        startValue: 100.0,
        tickIntervals: [100.0, 50.0, 10.0, 5.0],
        labelLevels: [0]  // 100, 200
    ),
    
    // COMMENTED OUT
    // // 200-500
    // ScaleSubsection(
    //     startValue: 200.0,
    //     tickIntervals: [200.0, 100.0, 50.0, 10.0],
    //     labelLevels: [0]
    // ),
    
    // 500-1000
    ScaleSubsection(
        startValue: 500.0,
        tickIntervals: [500.0, 100.0, 50.0],
        labelLevels: [0]  // 500, 1000
    ),
    
    // 1000-2000: Thousands
    ScaleSubsection(
        startValue: 1000.0,
        tickIntervals: [1000.0, 500.0, 100.0],
        labelLevels: [0]  // 1000, 2000
    ),
    
    // COMMENTED OUT
    // // 2000-4000
    // ScaleSubsection(
    //     startValue: 2000.0,
    //     tickIntervals: [2000.0, 1000.0, 200.0],
    //     labelLevels: [0]
    // ),
    
    // COMMENTED OUT
    // // 4000-5000
    // ScaleSubsection(
    //     startValue: 4000.0,
    //     tickIntervals: [5000.0, 1000.0, 200.0],
    //     labelLevels: [0]
    // ),
    
    // COMMENTED OUT
    // // 5000-10000
    // ScaleSubsection(
    //     startValue: 5000.0,
    //     tickIntervals: [5000.0, 1000.0, 500.0],
    //     labelLevels: [0]
    // ),
    
    // 10000-21000: Upper limit
    ScaleSubsection(
        startValue: 10000.0,
        tickIntervals: [10000.0, 5000.0, 1000.0],
        labelLevels: [0]  // 10000, 20000
    )
])
```

**Label Count Estimate**: ~18 labels across massive exponential range

**Verification**:
- Labels should show: 3, 4, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 10000, 20000
- No scientific notation unless value > 10,000
- Adequate spacing between labels

---

### Phase 4: Adaptive Label Reduction ✅ TODO

**Goal**: Automatically reduce label density when scale length is small

#### Step 4.1: Add Adaptive Configuration

Add to `ScaleDefinition.swift`:

```swift
/// Configuration for adaptive label reduction based on scale physical length
public struct AdaptiveLabelConfig: Sendable {
    /// Minimum physical spacing between labels (in points)
    public let minimumLabelSpacing: Distance
    
    /// Scale length threshold below which to apply adaptive reduction
    public let scaleLengthThreshold: Distance
    
    /// Reduction strategy
    public enum Strategy: Sendable {
        case keepPrimary        // Keep only level 0 labels
        case skipAlternate      // Show every 2nd label
        case skipModulo(Int)    // Show every Nth label
        case intelligentSpacing // Calculate based on spacing
    }
    
    public let strategy: Strategy
    
    public static let phone = AdaptiveLabelConfig(
        minimumLabelSpacing: 12.0,
        scaleLengthThreshold: 400.0,
        strategy: .intelligentSpacing
    )
    
    public static let tablet = AdaptiveLabelConfig(
        minimumLabelSpacing: 10.0,
        scaleLengthThreshold: 800.0,
        strategy: .keepPrimary
    )
    
    public init(
        minimumLabelSpacing: Distance,
        scaleLengthThreshold: Distance,
        strategy: Strategy
    ) {
        self.minimumLabelSpacing = minimumLabelSpacing
        self.scaleLengthThreshold = scaleLengthThreshold
        self.strategy = strategy
    }
}
```

**Verification**:
- Compiles without errors
- Configuration available for use in calculator

---

#### Step 4.2: Implement Adaptive Logic in ScaleCalculator

Modify `ScaleCalculator.swift` to apply adaptive reduction:

```swift
/// Apply adaptive label reduction based on scale length
private static func applyAdaptiveLabelReduction(
    ticks: [TickMark],
    definition: ScaleDefinition,
    config: AdaptiveLabelConfig
) -> [TickMark] {
    // Only apply if scale is below threshold
    guard definition.scaleLengthInPoints < config.scaleLengthThreshold else {
        return ticks
    }
    
    // Calculate actual label density
    let labeledTicks = ticks.filter { $0.label != nil }
    guard labeledTicks.count > 1 else { return ticks }
    
    let avgSpacing = definition.scaleLengthInPoints / Double(labeledTicks.count)
    
    // If spacing is already adequate, no reduction needed
    guard avgSpacing < config.minimumLabelSpacing else {
        return ticks
    }
    
    // Apply strategy
    switch config.strategy {
    case .keepPrimary:
        // Remove all labels except those at major tick marks (style.relativeLength >= 0.9)
        return ticks.map { tick in
            if tick.style.relativeLength >= 0.9 {
                return tick  // Keep label on major ticks
            } else {
                // Remove label but keep tick mark
                return TickMark(
                    value: tick.value,
                    normalizedPosition: tick.normalizedPosition,
                    angularPosition: tick.angularPosition,
                    style: tick.style,
                    label: nil  // Remove label
                )
            }
        }
        
    case .skipAlternate:
        // Show every other label
        var result: [TickMark] = []
        var showNext = true
        for tick in ticks {
            if tick.label != nil {
                if showNext {
                    result.append(tick)
                } else {
                    result.append(TickMark(
                        value: tick.value,
                        normalizedPosition: tick.normalizedPosition,
                        angularPosition: tick.angularPosition,
                        style: tick.style,
                        label: nil
                    ))
                }
                showNext.toggle()
            } else {
                result.append(tick)
            }
        }
        return result
        
    case .skipModulo(let n):
        // Show every Nth label
        var result: [TickMark] = []
        var count = 0
        for tick in ticks {
            if tick.label != nil {
                if count % n == 0 {
                    result.append(tick)
                } else {
                    result.append(TickMark(
                        value: tick.value,
                        normalizedPosition: tick.normalizedPosition,
                        angularPosition: tick.angularPosition,
                        style: tick.style,
                        label: nil
                    ))
                }
                count += 1
            } else {
                result.append(tick)
            }
        }
        return result
        
    case .intelligentSpacing:
        // Calculate target spacing and keep labels that satisfy it
        var result: [TickMark] = []
        var lastLabelPosition: Double? = nil
        
        for tick in ticks {
            if let label = tick.label {
                if let lastPos = lastLabelPosition {
                    let distance = abs(tick.normalizedPosition - lastPos) * definition.scaleLengthInPoints
                    if distance >= config.minimumLabelSpacing || tick.style.relativeLength >= 0.9 {
                        // Keep this label (adequate spacing or major tick)
                        result.append(tick)
                        lastLabelPosition = tick.normalizedPosition
                    } else {
                        // Remove label
                        result.append(TickMark(
                            value: tick.value,
                            normalizedPosition: tick.normalizedPosition,
                            angularPosition: tick.angularPosition,
                            style: tick.style,
                            label: nil
                        ))
                    }
                } else {
                    // First label, keep it
                    result.append(tick)
                    lastLabelPosition = tick.normalizedPosition
                }
            } else {
                result.append(tick)
            }
        }
        return result
    }
}
```

**Verification**:
- Test with 250pt scale: should have fewer labels than 500pt scale
- Test with 750pt scale: should have more labels
- Major ticks always retain labels

---

#### Step 4.3: Integrate Adaptive Logic into generateTickMarks

Modify the main generation functions:

```swift
public static func generateTickMarks(
    for definition: ScaleDefinition,
    algorithm: TickGenerationAlgorithm? = nil,
    adaptiveConfig: AdaptiveLabelConfig? = nil
) -> [TickMark] {
    let algo = algorithm ?? defaultAlgorithm
    
    var ticks: [TickMark]
    
    switch algo {
    case .legacy:
        ticks = generateTickMarksLegacy(for: definition)
    case .modulo(let config):
        ticks = generateTickMarksModulo(for: definition, config: config)
    }
    
    // Apply adaptive reduction if configured
    if let config = adaptiveConfig {
        ticks = applyAdaptiveLabelReduction(
            ticks: ticks,
            definition: definition,
            config: config
        )
    }
    
    return ticks
}
```

**Verification**:
- Pass `adaptiveConfig: .phone` for small scales
- Pass `adaptiveConfig: .tablet` for medium scales
- Pass `nil` for no adaptation (original behavior)

---

### Phase 5: Density Tests ✅ TODO

**Goal**: Prevent regressions by testing label density constraints

#### Step 5.1: Create LabelDensityTests.swift

Create new test file:

```swift
import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests to ensure label density remains within acceptable limits for legibility
/// 
/// RATIONALE: On mobile devices (phones and tablets), labels that are too close together
/// become illegible and create visual clutter. These tests enforce minimum spacing
/// requirements based on Apple HIG typography guidelines and practical usability.
///
/// REFERENCES:
/// - Apple HIG Typography: Minimum 10-11pt font size for legibility
/// - Touch target guidelines: ~44pt for interactive elements
/// - Label spacing: Minimum 10-12pt between non-interactive labels
///
/// TAGS: ux, legibility, mobile, density
@Suite("Label Density Constraints", .tags(.ux, .legibility, .mobile))
struct LabelDensityTests {
    
    /// Phone dimensions: ~5 inch slide rule, 360pt physical length
    private let phoneScaleLength: Distance = 360.0
    
    /// Tablet dimensions: ~10 inch slide rule, 720pt physical length  
    private let tabletScaleLength: Distance = 720.0
    
    /// Minimum spacing between labels on phones (Apple HIG guidance)
    private let phoneMinSpacing: Distance = 12.0
    
    /// Minimum spacing between labels on tablets
    private let tabletMinSpacing: Distance = 10.0
    
    @Suite("K Scale Density", .tags(.kscale))
    struct KScaleDensity {
        
        @Test("K scale on phone has adequate label spacing for legibility")
        func kScalePhoneDensity() {
            // GIVEN: A K scale at phone dimensions (5 inch / 360pt)
            let kScale = StandardScales.kScale(length: 360.0)
            
            // WHEN: We generate tick marks with phone adaptive config
            let ticks = ScaleCalculator.generateTickMarks(
                for: kScale,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .phone
            )
            
            // THEN: Labels should be spaced at least 12pt apart
            let labeledTicks = ticks.filter { $0.label != nil }
            
            // Calculate minimum spacing between consecutive labels
            var minSpacing = Double.infinity
            for i in 1..<labeledTicks.count {
                let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 360.0
                minSpacing = min(minSpacing, distance)
            }
            
            #expect(minSpacing >= 12.0, "K scale labels on phone must be ≥12pt apart (found: \(String(format: "%.1f", minSpacing))pt)")
            
            // AND: Total label count should be reasonable for 360pt
            // Max labels = 360pt / 12pt = 30 labels
            #expect(labeledTicks.count <= 30, "K scale on phone should have ≤30 labels (found: \(labeledTicks.count))")
            
            print("✅ K scale phone: \(labeledTicks.count) labels, min spacing: \(String(format: "%.1f", minSpacing))pt")
        }
        
        @Test("K scale on tablet allows more labels with adequate spacing")
        func kScaleTabletDensity() {
            // GIVEN: A K scale at tablet dimensions (10 inch / 720pt)
            let kScale = StandardScales.kScale(length: 720.0)
            
            // WHEN: We generate tick marks with tablet adaptive config
            let ticks = ScaleCalculator.generateTickMarks(
                for: kScale,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .tablet
            )
            
            // THEN: Labels should be spaced at least 10pt apart
            let labeledTicks = ticks.filter { $0.label != nil }
            
            var minSpacing = Double.infinity
            for i in 1..<labeledTicks.count {
                let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 720.0
                minSpacing = min(minSpacing, distance)
            }
            
            #expect(minSpacing >= 10.0, "K scale labels on tablet must be ≥10pt apart (found: \(String(format: "%.1f", minSpacing))pt)")
            
            // AND: Should have more labels than phone (more space available)
            // Max labels = 720pt / 10pt = 72 labels
            #expect(labeledTicks.count <= 72, "K scale on tablet should have ≤72 labels (found: \(labeledTicks.count))")
            
            print("✅ K scale tablet: \(labeledTicks.count) labels, min spacing: \(String(format: "%.1f", minSpacing))pt")
        }
    }
    
    @Suite("S Scale Density", .tags(.sscale))
    struct SScaleDensity {
        
        @Test("S scale on phone maintains minimum 12pt label spacing")
        func sScalePhoneDensity() {
            let sScale = StandardScales.sScale(length: 360.0)
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: sScale,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .phone
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            var minSpacing = Double.infinity
            for i in 1..<labeledTicks.count {
                let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 360.0
                minSpacing = min(minSpacing, distance)
            }
            
            #expect(minSpacing >= 12.0, "S scale labels on phone must be ≥12pt apart (found: \(String(format: "%.1f", minSpacing))pt)")
            #expect(labeledTicks.count <= 30, "S scale on phone should have ≤30 labels (found: \(labeledTicks.count))")
            
            print("✅ S scale phone: \(labeledTicks.count) labels, min spacing: \(String(format: "%.1f", minSpacing))pt")
        }
        
        @Test("S scale on tablet allows denser labeling with 10pt minimum")
        func sScaleTabletDensity() {
            let sScale = StandardScales.sScale(length: 720.0)
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: sScale,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .tablet
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            var minSpacing = Double.infinity
            for i in 1..<labeledTicks.count {
                let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 720.0
                minSpacing = min(minSpacing, distance)
            }
            
            #expect(minSpacing >= 10.0, "S scale labels on tablet must be ≥10pt apart (found: \(String(format: "%.1f", minSpacing))pt)")
            #expect(labeledTicks.count <= 72, "S scale on tablet should have ≤72 labels (found: \(labeledTicks.count))")
            
            print("✅ S scale tablet: \(labeledTicks.count) labels, min spacing: \(String(format: "%.1f", minSpacing))pt")
        }
    }
    
    @Suite("LL3 Scale Density", .tags(.ll3scale))
    struct LL3ScaleDensity {
        
        @Test("LL3 scale on phone limits labels despite exponential range")
        func ll3ScalePhoneDensity() {
            // LL3 is particularly challenging: 2.74 to 21,000 is a huge range
            // We need to ensure labels don't crowd despite the magnitude spread
            let ll3Scale = StandardScales.ll3Scale(length: 360.0)
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: ll3Scale,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .phone
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            var minSpacing = Double.infinity
            for i in 1..<labeledTicks.count {
                let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 360.0
                minSpacing = min(minSpacing, distance)
            }
            
            #expect(minSpacing >= 12.0, "LL3 scale labels on phone must be ≥12pt apart (found: \(String(format: "%.1f", minSpacing))pt)")
            #expect(labeledTicks.count <= 30, "LL3 scale on phone should have ≤30 labels (found: \(labeledTicks.count))")
            
            print("✅ LL3 scale phone: \(labeledTicks.count) labels, min spacing: \(String(format: "%.1f", minSpacing))pt")
        }
        
        @Test("LL3 scale on tablet can show more detail with proper spacing")
        func ll3ScaleTabletDensity() {
            let ll3Scale = StandardScales.ll3Scale(length: 720.0)
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: ll3Scale,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .tablet
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            var minSpacing = Double.infinity
            for i in 1..<labeledTicks.count {
                let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 720.0
                minSpacing = min(minSpacing, distance)
            }
            
            #expect(minSpacing >= 10.0, "LL3 scale labels on tablet must be ≥10pt apart (found: \(String(format: "%.1f", minSpacing))pt)")
            #expect(labeledTicks.count <= 72, "LL3 scale on tablet should have ≤72 labels (found: \(labeledTicks.count))")
            
            print("✅ LL3 scale tablet: \(labeledTicks.count) labels, min spacing: \(String(format: "%.1f", minSpacing))pt")
        }
    }
    
    @Suite("General Density Invariants", .tags(.invariant))
    struct GeneralDensityInvariants {
        
        @Test("No two labels can be closer than minimum spacing regardless of scale")
        func minimumSpacingInvariant() {
            // Test a variety of scales at phone dimensions
            let testScales: [(name: String, scale: ScaleDefinition)] = [
                ("C", StandardScales.cScale(length: 360.0)),
                ("D", StandardScales.dScale(length: 360.0)),
                ("A", StandardScales.aScale(length: 360.0)),
                ("K", StandardScales.kScale(length: 360.0)),
                ("S", StandardScales.sScale(length: 360.0)),
                ("T", StandardScales.tScale(length: 360.0)),
                ("LL1", StandardScales.ll1Scale(length: 360.0)),
                ("LL2", StandardScales.ll2Scale(length: 360.0)),
                ("LL3", StandardScales.ll3Scale(length: 360.0))
            ]
            
            for (name, scale) in testScales {
                let ticks = ScaleCalculator.generateTickMarks(
                    for: scale,
                    algorithm: .modulo(config: .default),
                    adaptiveConfig: .phone
                )
                
                let labeledTicks = ticks.filter { $0.label != nil }
                guard labeledTicks.count > 1 else { continue }
                
                var minSpacing = Double.infinity
                for i in 1..<labeledTicks.count {
                    let distance = abs(labeledTicks[i].normalizedPosition - labeledTicks[i-1].normalizedPosition) * 360.0
                    minSpacing = min(minSpacing, distance)
                }
                
                #expect(minSpacing >= 12.0, "\(name) scale violates minimum spacing: \(String(format: "%.1f", minSpacing))pt < 12pt")
            }
        }
        
        @Test("Larger scales should never have worse density than smaller scales")
        func densityScalesWithLength() {
            let kScale250 = StandardScales.kScale(length: 250.0)
            let kScale500 = StandardScales.kScale(length: 500.0)
            
            let ticks250 = ScaleCalculator.generateTickMarks(
                for: kScale250,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .phone
            )
            
            let ticks500 = ScaleCalculator.generateTickMarks(
                for: kScale500,
                algorithm: .modulo(config: .default),
                adaptiveConfig: .tablet
            )
            
            let density250 = Double(ticks250.filter { $0.label != nil }.count) / 250.0
            let density500 = Double(ticks500.filter { $0.label != nil }.count) / 500.0
            
            // Larger scales should have similar or better (higher) label density
            // Tolerance: Allow 20% variance due to quantization effects
            #expect(density500 >= density250 * 0.8, "Larger scale should not have worse label density")
        }
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var ux: Self
    @Tag static var legibility: Self
    @Tag static var mobile: Self
    @Tag static var kscale: Self
    @Tag static var sscale: Self
    @Tag static var ll3scale: Self
    @Tag static var invariant: Self
}
```

**Verification**:
- Run tests: `swift test --filter LabelDensityTests`
- All tests should pass with current implementation
- Tests should fail if label density is increased beyond threshold

---

## Implementation Checklist

### Phase 1: K Scale ✅ COMPLETE
- [x] 1.1: Add complete K scale subsections with PostScript fidelity
- [x] 1.2: Implement unified K scale formatter with Range-based intervals
- [x] Switch ScaleCalculator.defaultAlgorithm to .modulo
- [x] Create comprehensive test suite (KScaleFormatterTests.swift)
- [x] Visual verification on macOS

### UI Typography ✅ COMPLETE
- [x] Fix scale name label alignment (right-align with minWidth)
- [x] Visual verification of label positioning

### Phase 2: S Scale ⏳ PENDING  
- [ ] 2.1: Add complete S scale subsections with PostScript comments
- [ ] Visual verification on iPhone simulator
- [ ] Visual verification on iPad simulator

### Phase 3: LL3 Scale ⏳ PENDING
- [ ] 3.1: Add complete LL3 scale subsections with PostScript comments
- [ ] Visual verification on iPhone simulator
- [ ] Visual verification on iPad simulator

### Phase 4: Adaptive Reduction ⏳ PENDING
- [ ] 4.1: Add AdaptiveLabelConfig to ScaleDefinition.swift
- [ ] 4.2: Implement applyAdaptiveLabelReduction in ScaleCalculator.swift
- [ ] 4.3: Integrate adaptive logic into generateTickMarks
- [ ] Test with various scale lengths (250pt, 360pt, 500pt, 720pt)

### Phase 5: Density Tests ⏳ PENDING
- [ ] 5.1: Create LabelDensityTests.swift with all test suites
- [ ] Run test suite and verify all pass
- [ ] Add tags to test configuration
- [ ] Document test rationale in code comments

## Success Criteria

### Functional
- ✅ K scale has all 10 PostScript subsections implemented
- ✅ K scale uses unified formatter with Range-based boundary detection
- ✅ Tick generation uses modulo algorithm (no duplicates)
- ✅ Comprehensive test coverage for K scale formatter
- ⏳ S, LL3 scales have all PostScript subsections (pending)
- ⏳ Labels reduce automatically on small scales (<400pt) (pending)
- ⏳ Minimum label spacing maintained (12pt phone, 10pt tablet) (pending)
- ⏳ All density tests pass (pending)

### Visual
- ✅ K scale labels don't overlap on macOS display
- ✅ K scale power-of-10 boundaries show actual values (10, 100, 1000)
- ✅ K scale intermediate values show compact form (2, 3, 4, etc.)
- ✅ Scale name labels right-align properly (minWidth: 28)
- ⏳ Labels legible at 11pt font size on mobile (pending iPhone verification)
- ⏳ Visual hierarchy clear (major vs minor marks) (needs design review)
- ⏳ Breathing room between labels feels natural (pending mobile verification)

### Code Quality
- ✅ Range-based interval logic instead of epsilon comparison
- ✅ Single unified formatter (not separate tens/hundreds formatters)
- ✅ Test suite validates all boundary conditions
- ✅ Idiomatic Swift patterns (`ClosedRange`, `contains()`)

### Historical
- ✅ All 10 PostScript K scale subsections documented in code
- ✅ Intervals match PostScript exactly
- ✅ Formula definitions match PostScript exactly

## Future Enhancements

### Short Term
- Add dual labeling for S scale (sine ascending, cosine descending)
- Implement magnitude-aware formatters (K scale: "1K", "1M" instead of "1000", "1000000")
- Add user preference for label density (minimal, standard, detailed)

### Medium Term
- Dynamic Type support (scale labels with system text size)
- Accessibility: VoiceOver labels for tick marks
- Localization: Decimal separator handling (1,5 vs 1.5)

### Long Term
- Machine learning-based label placement optimization
- User-customizable scale configurations
- Export scales to PDF with optimal label density

## References

- **PostScript Engine**: `reference/postscript-engine-for-sliderules.ps`
- **Mathematical Foundations**: `reference/manthematical-foundations-of-the-slide-rule.md`
- **PostScript Explainer**: `reference/postscript-rule-engine-explainer.md`
- **Apple HIG Typography**: https://developer.apple.com/design/human-interface-guidelines/typography
- **Swift Testing Guide**: `swift-docs/swift-testing-playbook.md`
- **Performance Guide**: `swift-docs/swift-sliderule-rendering-improvements.md`

## Change Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2025-10-25 | Document Created | ✅ Complete | Initial plan and TODO list |
| 2025-10-25 | Phase 1.1 | ✅ Complete | Added all 10 K scale subsections to StandardScales.swift |
| 2025-10-25 | Phase 1.2 | ✅ Complete | Implemented unified kScale formatter with Range-based intervals |
| 2025-10-25 | Algorithm Fix | ✅ Complete | Changed defaultAlgorithm to .modulo in ScaleCalculator.swift |
| 2025-10-25 | Test Coverage | ✅ Complete | Created KScaleFormatterTests.swift with comprehensive tests |
| 2025-10-26 | UI Typography | ✅ Complete | Fixed scale name label alignment (minWidth with trailing) |
| TBD | Phase 2 | ⏳ Pending | S scale improvements |
| TBD | Phase 3 | ⏳ Pending | LL3 scale improvements |
| TBD | Phase 4 | ⏳ Pending | Adaptive reduction |
| TBD | Phase 5 | ⏳ Pending | Density tests |

---

**Next Steps**: Begin Phase 1.1 - Add complete K scale subsections. Stop after each phase for visual inspection and adjustment before proceeding.
