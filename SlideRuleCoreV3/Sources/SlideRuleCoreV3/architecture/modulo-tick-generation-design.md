# Modulo-Based Tick Generation Algorithm - Swift Architecture

## Executive Summary

This document defines the architecture for reimplementing the slide rule tick generation algorithm in Swift using the PostScript engine's elegant modulo-based approach. The new design eliminates multi-pass generation and duplicate removal, replacing them with a single-pass algorithm that determines tick hierarchy using modulo arithmetic.

**Key Benefits:**
- ✅ Single-pass generation (no duplicates)
- ✅ O(n) complexity instead of O(n × m) where m = interval levels
- ✅ Deterministic tick hierarchy
- ✅ Matches PostScript's proven algorithm
- ✅ Better floating-point precision handling

---

## Table of Contents

1. [Current vs. PostScript Approach Analysis](#1-current-vs-postscript-approach-analysis)
2. [Core Algorithm Design](#2-core-algorithm-design)
3. [Floating-Point Precision Strategy](#3-floating-point-precision-strategy)
4. [Null Interval Handling](#4-null-interval-handling)
5. [Circular Scale Edge Cases](#5-circular-scale-edge-cases)
6. [Integration Strategy](#6-integration-strategy)
7. [Backward Compatibility](#7-backward-compatibility)
8. [Detailed Pseudocode](#8-detailed-pseudocode)
9. [Testing Strategy](#9-testing-strategy)

---

## 1. Current vs. PostScript Approach Analysis

### Current Swift Implementation

**File:** [`ScaleCalculator.swift:159-234`](SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:159)

```swift
// Multi-pass approach
for (level, interval) in subsection.tickIntervals.enumerated() {
    guard interval > 0 else { continue }
    
    var currentValue = subsection.startValue
    while currentValue <= endValue {
        // Generate tick at this level
        ticks.append(tick)
        currentValue += interval
    }
}

// Remove duplicates (lines 275-316)
allTicks = removeDuplicates(from: allTicks, isCircular: definition.isCircular)
```

**Problems:**
1. **Multiple passes**: Iterates 4 times per subsection (once per interval level)
2. **Duplicate generation**: Same position generated multiple times
3. **Duplicate removal overhead**: Requires sorting and comparison
4. **Ambiguous hierarchy**: Must decide which tick "wins" during duplicate removal
5. **Complexity**: O(n × m) where n = ticks, m = interval levels

### PostScript Engine Approach

**File:** [`postscript-engine-for-sliderules.ps:1914-1944`](reference/postscript-engine-for-sliderules.ps:1914)

```postscript
beginsub xfactor mul increment xfactor mul endsub xfactor mul {
    /curtick exch def
    /curinterval 0 def
    {
        intervals curinterval get
        xfactor mul cvi
        curtick exch mod 0 eq { exit }  % If divisible, we found the level
        /curinterval ++
    } loop
    % Draw ONE tick at determined level
} for
```

**Advantages:**
1. **Single pass**: Iterate once through positions at finest granularity
2. **No duplicates**: Each position generates exactly one tick
3. **Deterministic hierarchy**: Modulo test determines tick level
4. **Elegant**: Tests intervals in order until finding a match
5. **Complexity**: O(n) where n = ticks at finest granularity

---

## 2. Core Algorithm Design

### Algorithm Overview

The PostScript engine's key insight: **Iterate at the finest increment, then use modulo arithmetic to determine which hierarchy level each position belongs to.**

```
For position p from start to end (at finest increment):
    For each interval level i from 0 to n:
        If p is divisible by interval[i]:
            Draw tick at level i
            Break (don't test smaller intervals)
```

### Swift Type Design

```swift
/// Configuration for modulo-based tick generation
public struct ModuloTickConfig: Sendable {
    /// Precision multiplier (xfactor in PostScript)
    /// Converts floating-point values to integers for exact modulo arithmetic
    /// Example: xfactor=100 means 0.01 precision
    let precisionMultiplier: Int
    
    /// Minimum position separation to detect duplicates (normalized units)
    let minSeparation: Double
    
    /// Whether to skip last tick on circular scales (360° = 0°)
    let skipCircularOverlap: Bool
    
    public init(
        precisionMultiplier: Int = 100,
        minSeparation: Double = 0.001,
        skipCircularOverlap: Bool = true
    ) {
        self.precisionMultiplier = precisionMultiplier
        self.minSeparation = minSeparation
        self.skipCircularOverlap = skipCircularOverlap
    }
}
```

### Core Algorithm Structure

```swift
/// Generate tick marks using modulo-based single-pass algorithm
private static func generateTickMarksModulo(
    for subsection: ScaleSubsection,
    on definition: ScaleDefinition,
    config: ModuloTickConfig = .default
) -> [TickMark] {
    var ticks: [TickMark] = []
    
    // 1. Find finest (smallest non-null) interval
    let finestInterval = subsection.tickIntervals
        .filter { $0 > 0 }
        .min() ?? return []
    
    // 2. Convert to integer space using xfactor
    let xfactor = config.precisionMultiplier
    let startInt = Int((subsection.startValue * Double(xfactor)).rounded())
    let endInt = Int((definition.endValue * Double(xfactor)).rounded())
    let incrementInt = Int((finestInterval * Double(xfactor)).rounded())
    
    // 3. Single pass through all positions
    var currentInt = startInt
    while currentInt <= endInt {
        // 4. Determine hierarchy level using modulo
        let level = determineTickLevel(
            position: currentInt,
            intervals: subsection.tickIntervals,
            xfactor: xfactor
        )
        
        // 5. Skip if level not found (shouldn't happen)
        guard let tickLevel = level else {
            currentInt += incrementInt
            continue
        }
        
        // 6. Convert back to real value
        let value = Double(currentInt) / Double(xfactor)
        
        // 7. Check if in valid range
        guard value >= definition.beginValue && value <= definition.endValue else {
            currentInt += incrementInt
            continue
        }
        
        // 8. Handle circular scale edge case
        if definition.isCircular && config.skipCircularOverlap {
            if shouldSkipCircularTick(value, definition) {
                currentInt += incrementInt
                continue
            }
        }
        
        // 9. Generate tick at determined level
        let tick = createTick(
            value: value,
            level: tickLevel,
            subsection: subsection,
            definition: definition
        )
        ticks.append(tick)
        
        currentInt += incrementInt
    }
    
    return ticks
}
```

### Tick Level Determination (The Core)

This is the heart of the algorithm - the modulo-based hierarchy test:

```swift
/// Determine which tick level a position belongs to using modulo arithmetic
/// Tests intervals from largest (level 0) to smallest, matching PostScript order
private static func determineTickLevel(
    position: Int,
    intervals: [Double],
    xfactor: Int
) -> Int? {
    // Test each interval level in order (0=major, 1=medium, 2=minor, 3=tiny)
    for (level, interval) in intervals.enumerated() {
        // Skip null intervals
        guard interval > 0 else { continue }
        
        // Convert interval to integer space
        let intervalInt = Int((interval * Double(xfactor)).rounded())
        
        // Test if position is divisible by this interval
        if position % intervalInt == 0 {
            return level
        }
    }
    
    // Should never reach here if finest interval is in the array
    return nil
}
```

**PostScript Equivalent:**
```postscript
/curinterval 0 def
{
    intervals curinterval get
    dup null ne {
        xfactor mul cvi
        curtick exch mod 0 eq { exit }
    } {
        pop
    } ifelse
    /curinterval ++
} loop
```

---

## 3. Floating-Point Precision Strategy

### The Problem

Floating-point arithmetic cannot represent decimal fractions exactly:
```swift
0.1 + 0.2 == 0.3  // false in Swift!
0.30000000000000004 // actual result
```

For tick generation, this causes:
- Missed tick marks due to rounding errors
- Incorrect hierarchy determination
- Inconsistent spacing

### The xfactor Solution (PostScript's Approach)

**Concept:** Convert all floating-point values to integers using a precision multiplier.

```swift
// Example: interval = 0.01, value = 2.37
let xfactor = 100

// Floating-point (imprecise):
let currentFloat = 2.37
let intervalFloat = 0.01
let result = currentFloat / intervalFloat  // 236.99999999... ???

// Integer (exact):
let currentInt = 237  // 2.37 × 100
let intervalInt = 1   // 0.01 × 100
let result = currentInt % intervalInt  // 0 (exact!)
```

### Precision Multiplier Selection

```swift
/// Determine appropriate xfactor based on finest interval
public static func recommendedPrecisionMultiplier(
    for subsection: ScaleSubsection
) -> Int {
    // Find finest interval
    guard let finestInterval = subsection.tickIntervals.filter({ $0 > 0 }).min() else {
        return 100
    }
    
    // Determine decimal places needed
    let decimalPlaces = maxDecimalPlaces(finestInterval)
    
    // xfactor = 10^(decimalPlaces + 1) for safety margin
    return Int(pow(10.0, Double(decimalPlaces + 1)))
}

private static func maxDecimalPlaces(_ value: Double) -> Int {
    let string = String(format: "%.10f", value)
    let components = string.components(separatedBy: ".")
    guard components.count > 1 else { return 0 }
    
    let fractional = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "0"))
    return fractional.count
}
```

**Examples:**
| Finest Interval | Decimal Places | Recommended xfactor |
|----------------|----------------|---------------------|
| 1.0            | 0              | 10                  |
| 0.1            | 1              | 100                 |
| 0.01           | 2              | 1000                |
| 0.001          | 3              | 10000               |

### Conversion Utilities

```swift
/// Convert value to integer space
private static func toIntegerSpace(
    _ value: Double,
    xfactor: Int
) -> Int {
    Int((value * Double(xfactor)).rounded())
}

/// Convert integer back to real space
private static func toRealSpace(
    _ intValue: Int,
    xfactor: Int
) -> Double {
    Double(intValue) / Double(xfactor)
}

/// Test if two values are equal within precision
private static func areEqual(
    _ a: Double,
    _ b: Double,
    xfactor: Int
) -> Bool {
    let aInt = toIntegerSpace(a, xfactor: xfactor)
    let bInt = toIntegerSpace(b, xfactor: xfactor)
    return aInt == bInt
}
```

---

## 4. Null Interval Handling

### The Problem

PostScript allows `null` in interval arrays to skip certain tick levels:

```postscript
/intervals [ 1 null .1 .02 ] def
```

This means: major ticks at 1, skip medium level, minor at 0.1, tiny at 0.02.

### Swift Implementation

Since Swift doesn't have nullable primitives in arrays elegantly, we use:

**Option 1: Optional Array** (Preferred)
```swift
public struct ScaleSubsection: Sendable {
    /// Tick intervals where nil means "skip this level"
    public let tickIntervals: [Double?]
}

// Usage:
let subsection = ScaleSubsection(
    startValue: 1.0,
    tickIntervals: [1.0, nil, 0.1, 0.02]  // Skip medium level
)
```

**Option 2: Use 0.0 as Sentinel**
```swift
// Current approach - 0.0 means null
let tickIntervals: [Double] = [1.0, 0.0, 0.1, 0.02]

// Filter nulls:
let validIntervals = tickIntervals.enumerated()
    .filter { $0.element > 0 }
    .map { ($0.offset, $0.element) }
```

### Null Handling in Algorithm

```swift
private static func determineTickLevel(
    position: Int,
    intervals: [Double?],  // or [Double] with 0.0 sentinel
    xfactor: Int
) -> Int? {
    for (level, interval) in intervals.enumerated() {
        // Skip null intervals
        guard let interval = interval, interval > 0 else {
            continue
        }
        
        let intervalInt = toIntegerSpace(interval, xfactor: xfactor)
        if position % intervalInt == 0 {
            return level
        }
    }
    return nil
}
```

**Important:** Must test intervals in order, skipping nulls, to maintain hierarchy.

---

## 5. Circular Scale Edge Cases

### The Problem

Circular scales wrap at 360°, creating edge cases:

1. **Overlapping tick at 0°/360°:** The scale's end coincides with its beginning
2. **Subsection wrap-around:** A subsection might span across 0°
3. **Full circle detection:** Need to know if scale covers full 360°

### PostScript Handling

```postscript
% Skip last tick mark for circular rules
/circular where {
    pop
    endscale endsub eq {
        beginscale formula exec endscale formula exec 1 sub eq {
            1 index sub  % Subtract increment to skip last tick
        } if
    } if
} if
```

Logic:
1. Check if at end of subsection (`endsub == endscale`)
2. Check if covers full circle (`f(begin) - f(end) >= 0.999`)
3. If both true, skip the last tick

### Swift Implementation

```swift
/// Check if a tick should be skipped on circular scales
private static func shouldSkipCircularTick(
    _ value: Double,
    _ definition: ScaleDefinition
) -> Bool {
    guard definition.isCircular else {
        return false
    }
    
    // Check if this is the last value
    let tolerance = 0.01 * abs(definition.endValue - definition.beginValue)
    let isLastValue = abs(value - definition.endValue) < tolerance
    
    guard isLastValue else {
        return false
    }
    
    // Check if scale covers full circle
    let beginPos = definition.function.transform(definition.beginValue)
    let endPos = definition.function.transform(definition.endValue)
    let coverage = abs(beginPos - endPos)
    let coversFullCircle = coverage >= 0.999
    
    // Skip if both conditions met
    return coversFullCircle
}
```

### Circular Scale Test Cases

```swift
// Test 1: Full circle (0° to 360°) - should skip last tick
let fullCircle = ScaleDefinition(
    beginValue: 0,
    endValue: 360,
    layout: .circular(diameter: 400, radiusInPoints: 100)
)
// Expected: Ticks at 0°, 10°, 20°, ..., 350° (NOT 360°)

// Test 2: Partial circle (45° to 315°) - keep all ticks
let partialCircle = ScaleDefinition(
    beginValue: 45,
    endValue: 315,
    layout: .circular(diameter: 400, radiusInPoints: 100)
)
// Expected: Ticks at 45°, 55°, ..., 315° (keep 315°)

// Test 3: Logarithmic circular (1 to 10) - full circle
let logCircle = ScaleDefinition(
    beginValue: 1,
    endValue: 10,
    function: LogarithmicFunction(),
    layout: .circular(diameter: 400, radiusInPoints: 100)
)
// log(1)=0, log(10)=1, coverage = 1.0 ≥ 0.999
// Should skip tick at value 10
```

---

## 6. Integration Strategy

### Backward Compatibility Approach

**Strategy:** Introduce new implementation alongside existing code, with feature flag.

```swift
public struct ScaleCalculator: Sendable {
    
    /// Configuration for tick generation algorithm
    public enum TickGenerationAlgorithm: Sendable {
        /// Legacy multi-pass approach (default for compatibility)
        case legacy
        
        /// New modulo-based single-pass approach
        case modulo(config: ModuloTickConfig)
    }
    
    /// Global algorithm preference (can be overridden per scale)
    public static var defaultAlgorithm: TickGenerationAlgorithm = .legacy
    
    /// Generate all tick marks for a scale definition
    public static func generateTickMarks(
        for definition: ScaleDefinition,
        algorithm: TickGenerationAlgorithm? = nil
    ) -> [TickMark] {
        let algo = algorithm ?? defaultAlgorithm
        
        switch algo {
        case .legacy:
            return generateTickMarksLegacy(for: definition)
        case .modulo(let config):
            return generateTickMarksModulo(for: definition, config: config)
        }
    }
    
    // Existing implementation renamed
    private static func generateTickMarksLegacy(
        for definition: ScaleDefinition
    ) -> [TickMark] {
        // Current implementation (lines 122-156)
        // ...
    }
    
    // New implementation
    private static func generateTickMarksModulo(
        for definition: ScaleDefinition,
        config: ModuloTickConfig
    ) -> [TickMark] {
        // New modulo-based implementation
        // ...
    }
}
```

### Migration Path

**Phase 1: Introduce Side-by-Side**
```swift
// Enable new algorithm globally
ScaleCalculator.defaultAlgorithm = .modulo(config: .default)

// Or per-scale
let ticks = ScaleCalculator.generateTickMarks(
    for: cScale,
    algorithm: .modulo(config: .default)
)
```

**Phase 2: Testing & Validation**
- Run both algorithms on all standard scales
- Compare outputs for equivalence
- Performance benchmarks
- Edge case testing

**Phase 3: Make Default**
```swift
public static var defaultAlgorithm: TickGenerationAlgorithm = .modulo(config: .default)
```

**Phase 4: Deprecate Legacy**
```swift
@available(*, deprecated, message: "Use modulo algorithm instead")
private static func generateTickMarksLegacy(...) { ... }
```

### API Additions

```swift
extension ScaleDefinition {
    /// Recommended precision multiplier for this scale
    public var recommendedXFactor: Int {
        ModuloTickConfig.recommendedPrecisionMultiplier(for: self)
    }
}

extension ScaleSubsection {
    /// Check if this subsection uses null intervals
    public var hasNullIntervals: Bool {
        tickIntervals.contains { $0 <= 0 }
    }
    
    /// Get non-null intervals with their level indices
    public var activeIntervals: [(level: Int, interval: Double)] {
        tickIntervals.enumerated()
            .filter { $0.element > 0 }
            .map { ($0.offset, $0.element) }
    }
}
```

---

## 7. Backward Compatibility

### Ensuring Identical Output

The modulo approach should produce **identical results** to the current implementation (after duplicate removal).

**Test Strategy:**

```swift
func testModuloEquivalence() throws {
    let scales = StandardScales.allCases
    
    for scale in scales {
        let definition = scale.definition
        
        // Generate with both algorithms
        let legacyTicks = ScaleCalculator.generateTickMarks(
            for: definition,
            algorithm: .legacy
        )
        
        let moduloTicks = ScaleCalculator.generateTickMarks(
            for: definition,
            algorithm: .modulo(config: .default)
        )
        
        // Should have same count
        XCTAssertEqual(legacyTicks.count, moduloTicks.count,
                       "Tick count mismatch for scale \(scale)")
        
        // Should have same values (within tolerance)
        for (legacy, modulo) in zip(legacyTicks, moduloTicks) {
            XCTAssertEqual(legacy.value, modulo.value, accuracy: 0.0001,
                          "Value mismatch for scale \(scale)")
            XCTAssertEqual(legacy.normalizedPosition, modulo.normalizedPosition,
                          accuracy: 0.0001,
                          "Position mismatch for scale \(scale)")
            XCTAssertEqual(legacy.style.relativeLength, modulo.style.relativeLength,
                          "Style mismatch for scale \(scale)")
        }
    }
}
```

### Known Differences

The modulo approach may differ in edge cases:

1. **Duplicate Resolution:** When two intervals produce the same position, legacy keeps the one with larger tick. Modulo never creates duplicates, so this doesn't apply.

2. **Floating-Point Rounding:** Modulo uses integer arithmetic, so may produce slightly different positions for values with many decimal places.

**Mitigation:** Use appropriate xfactor to ensure sufficient precision.

---

## 8. Detailed Pseudocode

### Complete Implementation

```swift
// MARK: - Modulo-Based Tick Generation

public struct ModuloTickConfig: Sendable {
    let precisionMultiplier: Int
    let minSeparation: Double
    let skipCircularOverlap: Bool
    
    public static let `default` = ModuloTickConfig(
        precisionMultiplier: 100,
        minSeparation: 0.001,
        skipCircularOverlap: true
    )
    
    public static func recommendedPrecisionMultiplier(
        for subsection: ScaleSubsection
    ) -> Int {
        guard let finest = subsection.tickIntervals.filter({ $0 > 0 }).min() else {
            return 100
        }
        
        // Count decimal places
        let string = String(format: "%.10f", finest)
        let parts = string.components(separatedBy: ".")
        guard parts.count > 1 else { return 10 }
        
        let decimals = parts[1].trimmingCharacters(in: .init(charactersIn: "0")).count
        return Int(pow(10.0, Double(decimals + 1)))
    }
    
    public static func recommendedPrecisionMultiplier(
        for definition: ScaleDefinition
    ) -> Int {
        // Find finest interval across all subsections
        let finestIntervals = definition.subsections.compactMap { subsection in
            subsection.tickIntervals.filter { $0 > 0 }.min()
        }
        
        guard let globalFinest = finestIntervals.min() else {
            return 100
        }
        
        let string = String(format: "%.10f", globalFinest)
        let parts = string.components(separatedBy: ".")
        guard parts.count > 1 else { return 10 }
        
        let decimals = parts[1].trimmingCharacters(in: .init(charactersIn: "0")).count
        return Int(pow(10.0, Double(decimals + 1)))
    }
}

extension ScaleCalculator {
    
    /// Generate tick marks using modulo-based algorithm
    private static func generateTickMarksModulo(
        for definition: ScaleDefinition,
        config: ModuloTickConfig
    ) -> [TickMark] {
        var allTicks: [TickMark] = []
        
        // Generate ticks for each subsection
        for subsection in definition.subsections {
            let ticks = generateSubsectionTicksModulo(
                subsection: subsection,
                definition: definition,
                config: config
            )
            allTicks.append(contentsOf: ticks)
        }
        
        // Add constants (these are independent of modulo algorithm)
        for constant in definition.constants {
            let position = normalizedPosition(for: constant.value, on: definition)
            let angularPos = definition.isCircular ? position * 360.0 : nil
            
            let tick = TickMark(
                value: constant.value,
                normalizedPosition: position,
                angularPosition: angularPos,
                style: constant.style,
                label: constant.label
            )
            allTicks.append(tick)
        }
        
        // Sort by position (should already be sorted, but ensure it)
        allTicks.sort { $0.normalizedPosition < $1.normalizedPosition }
        
        return allTicks
    }
    
    /// Generate ticks for a single subsection using modulo algorithm
    private static func generateSubsectionTicksModulo(
        subsection: ScaleSubsection,
        definition: ScaleDefinition,
        config: ModuloTickConfig
    ) -> [TickMark] {
        var ticks: [TickMark] = []
        
        // 1. Find finest interval
        guard let finestInterval = subsection.tickIntervals.filter({ $0 > 0 }).min() else {
            return []
        }
        
        // 2. Convert to integer space
        let xfactor = config.precisionMultiplier
        let startInt = toIntegerSpace(subsection.startValue, xfactor: xfactor)
        let endInt = toIntegerSpace(definition.endValue, xfactor: xfactor)
        let incrementInt = toIntegerSpace(finestInterval, xfactor: xfactor)
        
        guard incrementInt > 0 else {
            return []
        }
        
        // 3. Single pass through positions
        var currentInt = startInt
        
        while currentInt <= endInt {
            defer { currentInt += incrementInt }
            
            // 4. Determine hierarchy level
            guard let level = determineTickLevel(
                position: currentInt,
                intervals: subsection.tickIntervals,
                xfactor: xfactor
            ) else {
                continue
            }
            
            // 5. Convert back to real value
            let value = toRealSpace(currentInt, xfactor: xfactor)
            
            // 6. Validate range
            guard value >= definition.beginValue && value <= definition.endValue else {
                continue
            }
            
            // 7. Handle circular scale edge case
            if definition.isCircular && config.skipCircularOverlap {
                if shouldSkipCircularTick(value, definition, tolerance: 0.01 * finestInterval) {
                    continue
                }
            }
            
            // 8. Create tick
            let tick = createTickAtLevel(
                value: value,
                level: level,
                subsection: subsection,
                definition: definition
            )
            
            ticks.append(tick)
        }
        
        return ticks
    }
    
    /// Determine which tick level a position belongs to
    private static func determineTickLevel(
        position: Int,
        intervals: [Double],
        xfactor: Int
    ) -> Int? {
        // Test intervals from largest to smallest (PostScript order)
        for (level, interval) in intervals.enumerated() {
            // Skip null intervals (0.0 or negative)
            guard interval > 0 else { continue }
            
            // Convert interval to integer space
            let intervalInt = toIntegerSpace(interval, xfactor: xfactor)
            
            // Test divisibility
            if position % intervalInt == 0 {
                return level
            }
        }
        
        return nil
    }
    
    /// Create a tick mark at the specified level
    private static func createTickAtLevel(
        value: ScaleValue,
        level: Int,
        subsection: ScaleSubsection,
        definition: ScaleDefinition
    ) -> TickMark {
        // Calculate position
        let position = normalizedPosition(for: value, on: definition)
        let angularPos = definition.isCircular ? position * 360.0 : nil
        
        // Determine style
        let styleIndex = min(level, definition.defaultTickStyles.count - 1)
        let style = definition.defaultTickStyles[styleIndex]
        
        // Determine if should have label
        let shouldLabel = subsection.labelLevels.contains(level) || style.shouldLabel
        
        let label: String? = if shouldLabel {
            formatLabel(
                value: value,
                subsectionFormatter: subsection.labelFormatter,
                scaleFormatter: definition.labelFormatter
            )
        } else {
            nil
        }
        
        return TickMark(
            value: value,
            normalizedPosition: position,
            angularPosition: angularPos,
            style: style,
            label: label
        )
    }
    
    /// Check if tick should be skipped on circular scales
    private static func shouldSkipCircularTick(
        _ value: Double,
        _ definition: ScaleDefinition,
        tolerance: Double
    ) -> Bool {
        guard definition.isCircular else {
            return false
        }
        
        // Check if this is near the end value
        let isLastTick = abs(value - definition.endValue) < tolerance
        guard isLastTick else {
            return false
        }
        
        // Check if scale covers full circle
        let beginTransformed = definition.function.transform(definition.beginValue)
        let endTransformed = definition.function.transform(definition.endValue)
        let coverage = abs(endTransformed - beginTransformed)
        let coversFullCircle = coverage >= 0.999
        
        return coversFullCircle
    }
    
    // MARK: - Precision Utilities
    
    private static func toIntegerSpace(_ value: Double, xfactor: Int) -> Int {
        Int((value * Double(xfactor)).rounded())
    }
    
    private static func toRealSpace(_ intValue: Int, xfactor: Int) -> Double {
        Double(intValue) / Double(xfactor)
    }
}
```

### Usage Examples

```swift
// Example 1: C scale from 1 to 10
let cScale = ScaleDefinition(
    name: "C",
    function: LogarithmicFunction(),
    beginValue: 1.0,
    endValue: 10.0,
    scaleLengthInPoints: 250.0,
    layout: .linear,
    subsections: [
        ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [1.0, 0.1, 0.05, 0.01],
            labelLevels: [0, 1]
        ),
        ScaleSubsection(
            startValue: 2.0,
            tickIntervals: [1.0, 0.5, 0.1, 0.02],
            labelLevels: [0]
        )
    ]
)

// Generate with modulo algorithm
let config = ModuloTickConfig(
    precisionMultiplier: 100,  // 0.01 precision
    minSeparation: 0.001,
    skipCircularOverlap: false
)

let ticks = ScaleCalculator.generateTickMarks(
    for: cScale,
    algorithm: .modulo(config: config)
)

// For subsection 1 (1.0-2.0) at position 1.37:
// - Position int: 137 (1.37 × 100)
// - Test level 0: 137 % 100 = 37 (not divisible)
// - Test level 1: 137 % 10 = 7 (not divisible)
// - Test level 2: 137 % 5 = 2 (not divisible)
// - Test level 3: 137 % 1 = 0 (divisible!) → tiny tick at 1.37
```

---

## 9. Testing Strategy

### Unit Tests

```swift
// MARK: - Modulo Algorithm Tests

class ModuloTickGenerationTests: XCTestCase {
    
    // Test 1: No duplicates generated
    func testNoDuplicates() {
        let cScale = StandardScales.c.definition
        let ticks = ScaleCalculator.generateTickMarks(
            for: cScale,
            algorithm: .modulo(config: .default)
        )
        
        let positions = ticks.map { $0.normalizedPosition }
        let uniquePositions = Set(positions)
        
        XCTAssertEqual(positions.count, uniquePositions.count,
                       "Modulo algorithm should not generate duplicates")
    }
    
    // Test 2: Correct hierarchy determination
    func testHierarchyDetermination() {
        // At position 2.0: should be major (divisible by 1.0)
        // At position 2.5: should be medium (divisible by 0.5)
        // At position 2.1: should be medium (divisible by 0.1)
        // At position 2.02: should be tiny (divisible by 0.02)
        
        let subsection = ScaleSubsection(
            startValue: 2.0,
            tickIntervals: [1.0, 0.5, 0.1, 0.02]
        )
        
        let testCases: [(value: Double, expectedLevel: Int)] = [
            (2.0, 0),   // Major
            (2.5, 1),   // Medium
            (2.1, 2),   // Minor
            (2.02, 3)   // Tiny
        ]
        
        for (value, expectedLevel) in testCases {
            let intPos = Int(value * 100)
            let level = ScaleCalculator.determineTickLevel(
                position: intPos,
                intervals: subsection.tickIntervals,
                xfactor: 100
            )
            
            XCTAssertEqual(level, expectedLevel,
                          "Value \(value) should be at level \(expectedLevel)")
        }
    }
    
    // Test 3: Null interval handling
    func testNullIntervals() {
        let subsection = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [1.0, 0.0, 0.1, 0.01]  // Skip medium level
        )
        
        // Position 1.5 would be medium, but should fall through to minor
        let intPos = 150  // 1.5 × 100
        let level = ScaleCalculator.determineTickLevel(
            position: intPos,
            intervals: subsection.tickIntervals,
            xfactor: 100
        )
        
        // Should skip level 1 (null) and match level 2 (0.1)
        // 150 % 10 = 0
        XCTAssertEqual(level, 2, "Should skip null interval and match minor")
    }
    
    // Test 4: Circular scale overlap
    func testCircularScaleOverlap() {
        let circScale = ScaleDefinition(
            name: "C",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .circular(diameter: 400, radiusInPoints: 100),
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.01]
                )
            ]
        )
        
        let ticks = ScaleCalculator.generateTickMarks(
            for: circScale,
            algorithm: .modulo(config: .default)
        )
        
        // Should not have tick at value 10 (overlaps with 1)
        let hasTickAt10 = ticks.contains { abs($0.value - 10.0) < 0.01 }
        XCTAssertFalse(hasTickAt10, "Should skip overlapping tick at 360°")
    }
    
    // Test 5: Floating-point precision
    func testFloatingPointPrecision() {
        // Test that 0.1 + 0.2 == 0.3 in integer space
        let xfactor = 100
        let val1 = 0.1
        let val2 = 0.2
        let expected = 0.3
        
        let int1 = Int((val1 * Double(xfactor)).rounded())
        let int2 = Int((val2 * Double(xfactor)).rounded())
        let sum = int1 + int2
        let expectedInt = Int((expected * Double(xfactor)).rounded())
        
        XCTAssertEqual(sum, expectedInt, "Integer arithmetic should be exact")
    }
    
    // Test 6: Equivalence with legacy algorithm
    func testEquivalenceWithLegacy() throws {
        let scales = [
            StandardScales.c,
            StandardScales.d,
            StandardScales.a,
            StandardScales.k
        ]
        
        for scale in scales {
            let definition = scale.definition
            
            let legacyTicks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .legacy
            )
            
            let moduloTicks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: .default)
            )
            
            // Should have same count
            XCTAssertEqual(legacyTicks.count, moduloTicks.count,
                          "Tick count mismatch for \(scale)")
            
            // Should have same values
            for (legacy, modulo) in zip(legacyTicks, moduloTicks) {
                XCTAssertEqual(legacy.value, modulo.value, accuracy: 0.0001)
                XCTAssertEqual(legacy.normalizedPosition, modulo.normalizedPosition,
                              accuracy: 0.0001)
            }
        }
    }
}
```

### Performance Tests

```swift
class ModuloPerformanceTests: XCTestCase {
    
    func testModuloPerformance() {
        let cScale = StandardScales.c.definition
        
        measure {
            _ = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .modulo(config: .default)
            )
        }
    }
    
    func testLegacyPerformance() {
        let cScale = StandardScales.c.definition
        
        measure {
            _ = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .legacy
            )
        }
    }
    
    func testPerformanceComparison() {
        let scales = [
            StandardScales.c,
            StandardScales.d,
            StandardScales.ll3  // Log-log scale with many ticks
        ]
        
        for scale in scales {
            let definition = scale.definition
            
            let legacyTime = measureTime {
                _ = ScaleCalculator.generateTickMarks(
                    for: definition,
                    algorithm: .legacy
                )
            }
            
            let moduloTime = measureTime {
                _ = ScaleCalculator.generateTickMarks(
                    for: definition,
                    algorithm: .modulo(config: .default)
                )
            }
            
            print("\(scale): Legacy=\(legacyTime)s, Modulo=\(moduloTime)s")
            print("Speedup: \(legacyTime / moduloTime)x")
        }
    }
    
    private func measureTime(_ block: () -> Void) -> TimeInterval {
        let start = Date()
        block()
        return Date().timeIntervalSince(start)
    }
}
```

### Edge Case Tests

```swift
class ModuloEdgeCaseTests: XCTestCase {
    
    // Test very small intervals
    func testVerySmallIntervals() {
        let subsection = ScaleSubsection(
            startValue: 0.001,
            tickIntervals: [0.001, 0.0001, 0.00001, 0.000001]
        )
        
        let config = ModuloTickConfig(
            precisionMultiplier: 1000000,  // Need high precision
            minSeparation: 0.000001,
            skipCircularOverlap: false
        )
        
        // Should handle without overflow
        XCTAssertNoThrow {
            // Generate ticks
        }
    }
    
    // Test very large values
    func testVeryLargeValues() {
        let subsection = ScaleSubsection(
            startValue: 1000000,
            tickIntervals: [1000, 100, 10, 1]
        )
        
        // Should handle without overflow
        XCTAssertNoThrow {
            // Generate ticks
        }
    }
    
    // Test single interval
    func testSingleInterval() {
        let subsection = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [0.1]  // Only one level
        )
        
        // Should generate ticks at 0.1 intervals
        // All should be same level
    }
    
    // Test all null intervals
    func testAllNullIntervals() {
        let subsection = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [0.0, 0.0, 0.0, 0.0]
        )
        
        // Should generate no ticks
    }
}
```

---

## Summary

This architecture provides:

1. ✅ **Single-pass generation** - O(n) complexity
2. ✅ **No duplicates** - Each position generates one tick
3. ✅ **Deterministic hierarchy** - Modulo test determines level
4. ✅ **Floating-point precision** - Integer arithmetic via xfactor
5. ✅ **Null interval support** - Skip levels gracefully
6. ✅ **Circular scale handling** - Prevent 0°/360° overlap
7. ✅ **Backward compatible** - Side-by-side with legacy
8. ✅ **Well-tested** - Comprehensive test strategy

The implementation follows PostScript's proven algorithm while leveraging Swift's type safety and modern features.

---

## Next Steps

1. Implement `ModuloTickConfig` struct
2. Implement `determineTickLevel` function
3. Implement `generateSubsectionTicksModulo` function
4. Add precision utilities
5. Add circular scale checks
6. Write unit tests
7. Performance benchmarks
8. Integration with existing code
9. Documentation
10. Migration guide
