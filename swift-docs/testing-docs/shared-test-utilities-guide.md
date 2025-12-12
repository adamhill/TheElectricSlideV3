# SharedTestUtilities Guide

## Overview

The [`SharedTestUtilities.swift`](../../SlideRuleCoreV3/Tests/SlideRuleCoreV3Tests/SharedTestUtilities.swift:1) file provides a comprehensive set of reusable test utilities for the SlideRuleCoreV3 test suite. These utilities consolidate common testing patterns, eliminate code duplication, and provide a consistent testing interface across all test files.

**Location:** `SlideRuleCoreV3/Tests/SlideRuleCoreV3Tests/SharedTestUtilities.swift`

**Module:** Internal to test target, automatically available to all test files

### Why Use Shared Test Utilities?

- **Eliminate Duplication:** Reduces ~570+ lines of duplicated test code across 44+ test files
- **Consistency:** Ensures all tests use standardized tolerance values and patterns
- **Maintainability:** Changes to test patterns made in one place
- **Readability:** Test intent is clearer with descriptive utility names
- **Type Safety:** Helper functions provide compile-time validation

## Quick Reference

| Utility | Purpose | Common Usage |
|---------|---------|--------------|
| [`TestTolerance`](#1-testtolerance) | Standard tolerance constants | `TestTolerance.standard` (1%) |
| [`TestValues`](#2-testvalues) | Pre-defined test value arrays | `TestValues.logarithmic` |
| [`TestScaleFactory`](#3-testscalefactory) | Type-safe scale retrieval | `TestScaleFactory.getScaleOrFail(named: "C")` |
| [`RoundTripTester`](#4-roundtriptester) | Round-trip accuracy testing | `RoundTripTester.testRoundTrips(values:on:)` |
| [`ScaleComparator`](#5-scalecomparator) | Scale parity testing | `ScaleComparator.expectIdenticalPositions(_:_:at:)` |
| [`BoundaryTester`](#6-boundarytester) | Boundary condition testing | `BoundaryTester.expectCorrectBoundaries(_:)` |
| [`CommonScales`](#7-commonscales) | Quick scale instantiation | `CommonScales.c()` |

---

## The Seven Utilities

### 1. TestTolerance

**Purpose:** Provides standardized tolerance constants for different precision requirements, replacing scattered magic numbers across test files.

#### Available Constants

```swift
enum TestTolerance {
    static let standard = 0.01      // 1% - Most scale calculations
    static let strict = 0.001       // 0.1% - High-precision requirements
    static let relaxed = 0.05       // 5% - Complex calculations
    static let eeScale = 0.05       // 5% - Electrical engineering scales
    static let veryRelaxed = 0.1    // 10% - Sampling/approximate values
}
```

#### When to Use Each Tolerance

| Tolerance | Percentage | Use Cases |
|-----------|------------|-----------|
| `strict` | 0.1% | High-precision scales (LL scales, special functions) |
| `standard` | 1% | Most logarithmic scales (C, D, CI, DI) |
| `relaxed` | 5% | Complex calculations, trigonometric scales |
| `eeScale` | 5% | Electrical engineering scales (XL, Ω, τ) |
| `veryRelaxed` | 10% | Sampling, boundary approximations |

#### Usage Examples

**Before:**
```swift
let relativeError = abs(recovered - value) / value
#expect(relativeError < 0.01, "Error too large")
```

**After:**
```swift
let relativeError = abs(recovered - value) / value
#expect(relativeError < TestTolerance.standard, "Error too large")
```

**Complex Example:**
```swift
@Test("K scale precision")
func kScalePrecision() {
    let scale = CommonScales.k()
    
    // Use stricter tolerance for low values
    RoundTripTester.testRoundTrips(
        values: [1.0, 1.5, 2.0],
        on: scale,
        tolerance: TestTolerance.strict
    )
    
    // Use standard tolerance for mid-range values
    RoundTripTester.testRoundTrips(
        values: [5.0, 25.0, 50.0],
        on: scale,
        tolerance: TestTolerance.standard
    )
}
```

---

### 2. TestValues

**Purpose:** Pre-defined arrays of test values for different scale types, eliminating repeated inline arrays.

#### Available Collections

```swift
enum TestValues {
    /// Standard logarithmic scale test values (1-10 range)
    static let logarithmic = [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0]
    
    /// Extended logarithmic test values (1-100 range)
    static let logarithmicExtended = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    
    /// Square scale test values
    static let squared = [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0]
    
    /// Folded scale test values  
    static let folded = [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159]
    
    /// Standard inverted scale test values
    static let inverted = [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
    
    /// Standard test positions across normalized range [0, 1]
    static let positions = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
}
```

#### Usage Examples

**Before:**
```swift
@Test("C scale values")
func cScaleValues() {
    let scale = StandardScales.cScale(length: 250.0)
    let testValues = [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0] // Repeated in many tests
    
    for value in testValues {
        // test logic...
    }
}
```

**After:**
```swift
@Test("C scale values")
func cScaleValues() {
    let scale = CommonScales.c()
    
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmic,
        on: scale
    )
}
```

**Choosing the Right Collection:**

```swift
// For C, D, CI, DI scales
RoundTripTester.testRoundTrips(values: TestValues.logarithmic, on: cScale)

// For A, B (squared) scales  
RoundTripTester.testRoundTrips(values: TestValues.squared, on: aScale)

// For CF, DF (folded) scales
RoundTripTester.testRoundTrips(values: TestValues.folded, on: cfScale)

// For extended range scales (XL, etc.)
RoundTripTester.testRoundTrips(values: TestValues.logarithmicExtended, on: xlScale)

// For position-based tests
RoundTripTester.testPositionRoundTrips(positions: TestValues.positions, on: scale)
```

---

### 3. TestScaleFactory

**Purpose:** Centralized scale retrieval with error handling, replacing local `getScale` helper functions.

#### API

```swift
struct TestScaleFactory {
    /// Get a scale by name (returns nil if not found)
    static func getScale(named: String, length: Double = 250.0) -> ScaleDefinition?
    
    /// Get a scale by name with automatic test failure recording
    static func getScaleOrFail(
        named: String, 
        length: Double = 250.0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> ScaleDefinition?
}
```

#### Usage Examples

**Before:**
```swift
func getScale(named name: String) -> ScaleDefinition? {
    guard let scale = StandardScales.scale(named: name, length: 250.0) else {
        Issue.record("Could not find scale named '\(name)'")
        return nil
    }
    return scale
}

@Test("Test XL scale")
func testXLScale() {
    guard let scale = getScale(named: "XL") else { return }
    // test logic...
}
```

**After:**
```swift
@Test("Test XL scale")
func testXLScale() {
    guard let scale = TestScaleFactory.getScaleOrFail(named: "XL") else { return }
    // test logic...
}
```

**Parameterized Testing:**
```swift
@Test("Multiple scales", arguments: ["C", "D", "CI", "DI"])
func testMultipleScales(scaleName: String) {
    guard let scale = TestScaleFactory.getScaleOrFail(named: scaleName) else { return }
    
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmic,
        on: scale,
        tolerance: TestTolerance.standard
    )
}
```

**Custom Length:**
```swift
// Default length (250.0)
let scale1 = TestScaleFactory.getScaleOrFail(named: "C")

// Custom length
let scale2 = TestScaleFactory.getScaleOrFail(named: "C", length: 500.0)
```

---

### 4. RoundTripTester

**Purpose:** Utilities for testing position↔value round-trip accuracy, eliminating repetitive round-trip test loops.

#### API

```swift
enum RoundTripTester {
    /// Test round-trip accuracy for a single value
    static func testRoundTrip(
        value: Double,
        on scale: ScaleDefinition,
        tolerance: Double = TestTolerance.standard,
        sourceLocation: SourceLocation = #_sourceLocation
    )
    
    /// Test round-trip accuracy for multiple values
    static func testRoundTrips(
        values: [Double],
        on scale: ScaleDefinition,
        tolerance: Double = TestTolerance.standard,
        sourceLocation: SourceLocation = #_sourceLocation
    )
    
    /// Test position→value→position round-trip accuracy
    static func testPositionRoundTrips(
        positions: [Double],
        on scale: ScaleDefinition,
        tolerance: Double = 0.0001,
        sourceLocation: SourceLocation = #_sourceLocation
    )
}
```

#### Usage Examples

**Before (14 lines):**
```swift
@Test("XL scale round-trip accuracy")
func xlScaleRoundTrip() {
    let scale = StandardScales.xlScale(length: 250.0)
    let testValues = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    
    for value in testValues {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / value
        
        #expect(relativeError < 0.05,
               "XL scale: Value \(value) round-trip error \(relativeError) exceeds tolerance")
    }
}
```

**After (6 lines - 57% reduction):**
```swift
@Test("XL scale round-trip accuracy")
func xlScaleRoundTrip() {
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmicExtended,
        on: StandardScales.xlScale(length: 250.0),
        tolerance: TestTolerance.eeScale
    )
}
```

**Testing Single Values:**
```swift
@Test("Test specific value")
func testSpecificValue() {
    let scale = CommonScales.c()
    
    // Test π specifically
    RoundTripTester.testRoundTrip(
        value: 3.14159,
        on: scale,
        tolerance: TestTolerance.strict
    )
}
```

**Testing Position Round-Trips:**
```swift
@Test("Position accuracy")
func positionAccuracy() {
    let scale = CommonScales.d()
    
    // Test that positions map correctly
    RoundTripTester.testPositionRoundTrips(
        positions: TestValues.positions,
        on: scale,
        tolerance: 0.0001
    )
}
```

**Complex Multi-Range Testing:**
```swift
@Test("K scale comprehensive round-trip")
func kScaleComprehensive() {
    let scale = CommonScales.k()
    
    // Low range - strict tolerance
    RoundTripTester.testRoundTrips(
        values: [1.0, 1.2, 1.5, 2.0],
        on: scale,
        tolerance: TestTolerance.strict
    )
    
    // Mid range - standard tolerance
    RoundTripTester.testRoundTrips(
        values: [10.0, 20.0, 50.0],
        on: scale,
        tolerance: TestTolerance.standard
    )
    
    // High range - relaxed tolerance
    RoundTripTester.testRoundTrips(
        values: [500.0, 800.0, 1000.0],
        on: scale,
        tolerance: TestTolerance.relaxed
    )
}
```

---

### 5. ScaleComparator

**Purpose:** Utilities for comparing related scales (parity testing), streamlining scale-to-scale comparison tests.

#### API

```swift
enum ScaleComparator {
    /// Verify two scales produce identical positions for the same values
    static func expectIdenticalPositions(
        _ scale1: ScaleDefinition,
        _ scale2: ScaleDefinition,
        at values: [Double],
        tolerance: Double = 0.0001,
        sourceLocation: SourceLocation = #_sourceLocation
    )
    
    /// Verify two scales have matching precision at corresponding positions
    static func expectMatchingPrecision(
        _ scale1: ScaleDefinition,
        _ scale2: ScaleDefinition,
        at values: [Double],
        sourceLocation: SourceLocation = #_sourceLocation
    )
    
    /// Verify scale tick counts match
    static func expectSimilarTickCounts(
        _ scale1: ScaleDefinition,
        _ scale2: ScaleDefinition,
        allowedDifference: Int = 5,
        sourceLocation: SourceLocation = #_sourceLocation
    )
}
```

#### Usage Examples

**C/D Scale Parity:**
```swift
@Test("C and D scales should be identical")
func cScaleAndDScaleParity() {
    let cScale = CommonScales.c()
    let dScale = CommonScales.d()
    
    ScaleComparator.expectIdenticalPositions(
        cScale, dScale,
        at: TestValues.logarithmic
    )
    
    ScaleComparator.expectMatchingPrecision(
        cScale, dScale,
        at: TestValues.logarithmic
    )
    
    ScaleComparator.expectSimilarTickCounts(cScale, dScale)
}
```

**CF/DF Scale Parity:**
```swift
@Test("CF and DF folded scales parity")
func foldedScalesParity() {
    let cfScale = CommonScales.cf()
    let dfScale = CommonScales.df()
    
    ScaleComparator.expectIdenticalPositions(
        cfScale, dfScale,
        at: TestValues.folded,
        tolerance: 0.0001
    )
}
```

**Custom Tolerance:**
```swift
@Test("Related scales with relaxed tolerance")
func relatedScalesRelaxed() {
    let scale1 = TestScaleFactory.getScaleOrFail(named: "Ω")
    let scale2 = TestScaleFactory.getScaleOrFail(named: "τ")
    
    guard let s1 = scale1, let s2 = scale2 else { return }
    
    // EE scales may need more tolerance
    ScaleComparator.expectIdenticalPositions(
        s1, s2,
        at: [1.0, 10.0, 100.0],
        tolerance: 0.001  // Slightly relaxed
    )
}
```

---

### 6. BoundaryTester

**Purpose:** Utilities for testing scale boundary conditions, consolidating repeated boundary checking logic.

#### API

```swift
enum BoundaryTester {
    /// Test that scale begin/end values map to positions 0 and 1
    static func expectCorrectBoundaries(
        _ scale: ScaleDefinition,
        tolerance: Double = 0.01,
        sourceLocation: SourceLocation = #_sourceLocation
    )
    
    /// Test that position 0 yields beginValue and position 1 yields endValue
    static func expectCorrectBoundaryValues(
        _ scale: ScaleDefinition,
        tolerance: Double = 0.01,
        sourceLocation: SourceLocation = #_sourceLocation
    )
}
```

#### Usage Examples

**Basic Boundary Testing:**
```swift
@Test("C scale boundaries")
func cScaleBoundaries() {
    let scale = CommonScales.c()
    
    // Test that beginValue (1.0) → position 0.0
    // and endValue (10.0) → position 1.0
    BoundaryTester.expectCorrectBoundaries(scale)
    
    // Test that position 0.0 → beginValue (1.0)
    // and position 1.0 → endValue (10.0)
    BoundaryTester.expectCorrectBoundaryValues(scale)
}
```

**Custom Tolerance:**
```swift
@Test("High-precision scale boundaries")
func highPrecisionBoundaries() {
    let scale = CommonScales.d()
    
    // Stricter boundary requirements
    BoundaryTester.expectCorrectBoundaries(
        scale,
        tolerance: 0.001
    )
}
```

**Before/After Comparison:**

**Before (20 lines):**
```swift
@Test("K scale boundaries")
func kScaleBoundaries() {
    let scale = StandardScales.kScale(length: 250.0)
    
    // Test beginValue maps to 0
    let posBegin = ScaleCalculator.normalizedPosition(for: scale.beginValue, on: scale)
    #expect(abs(posBegin) < 0.01, "beginValue should map to position 0")
    
    // Test endValue maps to 1
    let posEnd = ScaleCalculator.normalizedPosition(for: scale.endValue, on: scale)
    #expect(abs(posEnd - 1.0) < 0.01, "endValue should map to position 1")
    
    // Test position 0 yields beginValue
    let valueAtStart = ScaleCalculator.value(at: 0.0, on: scale)
    let errorStart = abs(valueAtStart - scale.beginValue)
    #expect(errorStart < 0.01, "Position 0 should yield beginValue")
    
    // Test position 1 yields endValue
    let valueAtEnd = ScaleCalculator.value(at: 1.0, on: scale)
    let errorEnd = abs(valueAtEnd - scale.endValue)
    #expect(errorEnd < 0.01, "Position 1 should yield endValue")
}
```

**After (5 lines - 75% reduction):**
```swift
@Test("K scale boundaries")
func kScaleBoundaries() {
    let scale = CommonScales.k()
    BoundaryTester.expectCorrectBoundaries(scale)
    BoundaryTester.expectCorrectBoundaryValues(scale)
}
```

---

### 7. CommonScales

**Purpose:** Quick factory methods for frequently-tested scales, reducing verbosity from `StandardScales.cScale(length: 250.0)` to `CommonScales.c()`.

#### Available Scales

```swift
enum CommonScales {
    // Basic Scales
    static func c(length: Double = 250.0) -> ScaleDefinition
    static func d(length: Double = 250.0) -> ScaleDefinition
    static func ci(length: Double = 250.0) -> ScaleDefinition
    static func di(length: Double = 250.0) -> ScaleDefinition
    
    // Power Scales
    static func a(length: Double = 250.0) -> ScaleDefinition
    static func b(length: Double = 250.0) -> ScaleDefinition
    static func k(length: Double = 250.0) -> ScaleDefinition
    
    // Folded Scales
    static func cf(length: Double = 250.0) -> ScaleDefinition
    static func df(length: Double = 250.0) -> ScaleDefinition
    static func cif(length: Double = 250.0) -> ScaleDefinition
    static func dif(length: Double = 250.0) -> ScaleDefinition
    
    // Trigonometric Scales
    static func s(length: Double = 250.0) -> ScaleDefinition
    static func t(length: Double = 250.0) -> ScaleDefinition
    static func st(length: Double = 250.0) -> ScaleDefinition
    
    // Linear Scale
    static func l(length: Double = 250.0) -> ScaleDefinition
}
```

#### Usage Examples

**Before:**
```swift
@Test("Test calculation")
func testCalculation() {
    let cScale = StandardScales.cScale(length: 250.0)
    let dScale = StandardScales.dScale(length: 250.0)
    let ciScale = StandardScales.ciScale(length: 250.0)
    
    // test logic...
}
```

**After:**
```swift
@Test("Test calculation")
func testCalculation() {
    let cScale = CommonScales.c()
    let dScale = CommonScales.d()
    let ciScale = CommonScales.ci()
    
    // test logic...
}
```

**Custom Length:**
```swift
// Default 250.0
let scale1 = CommonScales.c()

// Custom length
let scale2 = CommonScales.c(length: 500.0)
```

**Chaining with Other Utilities:**
```swift
@Test("Quick comprehensive test")
func quickTest() {
    // Test C scale with one line
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmic,
        on: CommonScales.c(),
        tolerance: TestTolerance.standard
    )
}
```

---

## Migration Guide

### Step 1: Identify Duplication Patterns

Look for these patterns in your test files:

1. **Tolerance constants:**
   ```swift
   let tolerance = 0.01
   let eeScaleTolerance = 0.05
   ```

2. **Test value arrays:**
   ```swift
   let testValues = [1.0, 2.0, 5.0, 10.0]
   ```

3. **Local helper functions:**
   ```swift
   func getScale(named name: String) -> ScaleDefinition? { ... }
   ```

4. **Round-trip test loops:**
   ```swift
   for value in testValues {
       let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
       let recovered = ScaleCalculator.value(at: position, on: scale)
       // assertion...
   }
   ```

5. **Scale retrieval:**
   ```swift
   let scale = StandardScales.cScale(length: 250.0)
   ```

### Step 2: Replace with Shared Utilities

#### Example 1: Round-Trip Tests

**Before:**
```swift
@Test("T scale round-trip accuracy")
func tScaleRoundTrip() {
    let scale = StandardScales.tScale(length: 250.0)
    let testValues = [5.7, 10.0, 20.0, 45.0]
    
    for value in testValues {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / value
        
        #expect(
            relativeError < 0.05,
            "T scale: Value \(value) round-trip error \(relativeError) exceeds tolerance"
        )
    }
}
```

**After:**
```swift
@Test("T scale round-trip accuracy")
func tScaleRoundTrip() {
    RoundTripTester.testRoundTrips(
        values: [5.7, 10.0, 20.0, 45.0],
        on: CommonScales.t(),
        tolerance: TestTolerance.relaxed
    )
}
```

#### Example 2: Scale Parity Tests

**Before:**
```swift
@Test("A and B scale parity")
func aAndBScaleParity() {
    let aScale = StandardScales.aScale(length: 250.0)
    let bScale = StandardScales.bScale(length: 250.0)
    let testValues = [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0]
    
    for value in testValues {
        let posA = ScaleCalculator.normalizedPosition(for: value, on: aScale)
        let posB = ScaleCalculator.normalizedPosition(for: value, on: bScale)
        let difference = abs(posA - posB)
        
        #expect(
            difference < 0.0001,
            "A and B scales differ at value \(value)"
        )
    }
}
```

**After:**
```swift
@Test("A and B scale parity")
func aAndBScaleParity() {
    ScaleComparator.expectIdenticalPositions(
        CommonScales.a(),
        CommonScales.b(),
        at: TestValues.squared
    )
}
```

#### Example 3: Boundary Tests

**Before:**
```swift
@Test("CF scale boundaries")
func cfScaleBoundaries() {
    let scale = StandardScales.cfScale(length: 250.0)
    
    let posBegin = ScaleCalculator.normalizedPosition(for: scale.beginValue, on: scale)
    #expect(abs(posBegin) < 0.01, "beginValue should map to 0")
    
    let posEnd = ScaleCalculator.normalizedPosition(for: scale.endValue, on: scale)
    #expect(abs(posEnd - 1.0) < 0.01, "endValue should map to 1")
    
    let valueAtStart = ScaleCalculator.value(at: 0.0, on: scale)
    let errorStart = abs(valueAtStart - scale.beginValue)
    #expect(errorStart < 0.01, "Position 0 should yield beginValue")
    
    let valueAtEnd = ScaleCalculator.value(at: 1.0, on: scale)
    let errorEnd = abs(valueAtEnd - scale.endValue)
    #expect(errorEnd < 0.01, "Position 1 should yield endValue")
}
```

**After:**
```swift
@Test("CF scale boundaries")
func cfScaleBoundaries() {
    let scale = CommonScales.cf()
    BoundaryTester.expectCorrectBoundaries(scale)
    BoundaryTester.expectCorrectBoundaryValues(scale)
}
```

### Step 3: Test Your Changes

After migration:

1. Run your test suite: `swift test`
2. Verify all tests still pass
3. Check that error messages are still informative
4. Ensure source locations are correct in failures

---

## Best Practices

### 1. Choose the Right Tolerance

Always use named tolerances instead of magic numbers:

```swift
// ❌ Avoid
#expect(error < 0.01)

// ✅ Prefer
#expect(error < TestTolerance.standard)
```

**Tolerance Decision Tree:**
- High-precision scales (LL scales) → `TestTolerance.strict`
- Standard logarithmic scales → `TestTolerance.standard`
- Trigonometric scales → `TestTolerance.relaxed`
- EE scales (Ω, τ, XL) → `TestTolerance.eeScale`
- Approximate/sampling → `TestTolerance.veryRelaxed`

### 2. Use Appropriate Test Values

Match test values to the scale type:

```swift
// ✅ Good - appropriate values for scale type
RoundTripTester.testRoundTrips(
    values: TestValues.logarithmic,    // For C/D scales
    on: CommonScales.c()
)

RoundTripTester.testRoundTrips(
    values: TestValues.squared,         // For A/B scales
    on: CommonScales.a()
)

RoundTripTester.testRoundTrips(
    values: TestValues.folded,          // For CF/DF scales
    on: CommonScales.cf()
)
```

### 3. Combine Utilities for Comprehensive Tests

```swift
@Test("Comprehensive C scale validation")
func comprehensiveCScale() {
    let scale = CommonScales.c()
    
    // Test boundaries
    BoundaryTester.expectCorrectBoundaries(scale)
    BoundaryTester.expectCorrectBoundaryValues(scale)
    
    // Test round-trip accuracy
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmic,
        on: scale,
        tolerance: TestTolerance.standard
    )
    
    // Test position accuracy
    RoundTripTester.testPositionRoundTrips(
        positions: TestValues.positions,
        on: scale
    )
}
```

### 4. Use CommonScales for Frequently-Used Scales

```swift
// ❌ Verbose
let scale = StandardScales.cScale(length: 250.0)

// ✅ Concise
let scale = CommonScales.c()

// ✅ Custom length when needed
let scale = CommonScales.c(length: 500.0)
```

### 5. TestScaleFactory for Dynamic Scale Names

```swift
// When scale name is determined at runtime
@Test("Dynamic scale tests", arguments: ["C", "D", "CI", "DI"])
func dynamicScaleTest(scaleName: String) {
    guard let scale = TestScaleFactory.getScaleOrFail(named: scaleName) else {
        return
    }
    
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmic,
        on: scale
    )
}
```

### 6. Document Custom Test Values

When using custom values (not from TestValues), explain why:

```swift
@Test("T scale specific angles")
func tScaleSpecificAngles() {
    // Custom values selected for T scale's specific range (5.7° to 45°)
    let criticalAngles = [5.7, 10.0, 20.0, 30.0, 45.0]
    
    RoundTripTester.testRoundTrips(
        values: criticalAngles,
        on: CommonScales.t(),
        tolerance: TestTolerance.relaxed
    )
}
```

### 7. Keep Tests Readable

Balance conciseness with clarity:

```swift
// ❌ Too compressed - unclear intent
RoundTripTester.testRoundTrips(values: TestValues.logarithmic, on: CommonScales.c())

// ✅ Clear and readable
RoundTripTester.testRoundTrips(
    values: TestValues.logarithmic,
    on: CommonScales.c(),
    tolerance: TestTolerance.standard
)
```

---

## Complete Before/After Examples

### Example 1: Basic Round-Trip Test

**Before (18 lines):**
```swift
@Test("Ω scale round-trip accuracy")
func omegaScaleRoundTrip() {
    let scale = StandardScales.omegaScale(length: 250.0)
    let testValues = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    let tolerance = 0.05
    
    for value in testValues {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / value
        
        #expect(
            relativeError < tolerance,
            "Ω scale: Value \(value) round-trip error \(relativeError) exceeds tolerance \(tolerance)"
        )
    }
}
```

**After (7 lines - 61% reduction):**
```swift
@Test("Ω scale round-trip accuracy")
func omegaScaleRoundTrip() {
    RoundTripTester.testRoundTrips(
        values: TestValues.logarithmicExtended,
        on: StandardScales.omegaScale(length: 250.0),
        tolerance: TestTolerance.eeScale
    )
}
```

### Example 2: Scale Comparison Test

**Before (25 lines):**
```swift
@Test("CI and DI scale parity")
func ciAndDIScaleParity() {
    let ciScale = StandardScales.ciScale(length: 250.0)
    let diScale = StandardScales.diScale(length: 250.0)
    let testValues = [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
    let positionTolerance = 0.0001
    
    for value in testValues {
        let posCi = ScaleCalculator.normalizedPosition(for: value, on: ciScale)
        let posDi = ScaleCalculator.normalizedPosition(for: value, on: diScale)
        let difference = abs(posCi - posDi)
        
        #expect(
            difference < positionTolerance,
            "CI and DI scales differ at value \(value): \(posCi) vs \(posDi)"
        )
        
        let decimalsCi = ciScale.cursorDecimalPlaces(at: posCi)
        let decimalsDi = diScale.cursorDecimalPlaces(at: posDi)
        
        #expect(
            decimalsCi == decimalsDi,
            "CI and DI precision should match at value \(value)"
        )
    }
}
```

**After (9 lines - 64% reduction):**
```swift
@Test("CI and DI scale parity")
func ciAndDIScaleParity() {
    ScaleComparator.expectIdenticalPositions(
        CommonScales.ci(),
        CommonScales.di(),
        at: TestValues.inverted
    )
    
    ScaleComparator.expectMatchingPrecision(
        CommonScales.ci(),
        CommonScales.di(),
        at: TestValues.inverted
    )
}
```

### Example 3: Comprehensive Scale Test Suite

**Before (45+ lines):**
```swift
@Test("K scale comprehensive tests")
func kScaleComprehensive() {
    let scale = StandardScales.kScale(length: 250.0)
    
    // Boundary tests
    let posBegin = ScaleCalculator.normalizedPosition(for: scale.beginValue, on: scale)
    #expect(abs(posBegin) < 0.01, "beginValue should map to 0")
    
    let posEnd = ScaleCalculator.normalizedPosition(for: scale.endValue, on: scale)
    #expect(abs(posEnd - 1.0) < 0.01, "endValue should map to 1")
    
    // Round-trip tests - low range
    let lowValues = [1.0, 1.2, 1.5, 2.0]
    for value in lowValues {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / value
        #expect(relativeError < 0.001)
    }
    
    // Round-trip tests - mid range
    let midValues = [10.0, 20.0, 50.0]
    for value in midValues {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / value
        #expect(relativeError < 0.01)
    }
    
    // Round-trip tests - high range
    let highValues = [500.0, 800.0, 1000.0]
    for value in highValues {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / value
        #expect(relativeError < 0.05)
    }
    
    // Position round-trips
    let positions = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
    for position in positions {
        let value = ScaleCalculator.value(at: position, on: scale)
        let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let error = abs(computedPosition - position)
        #expect(error < 0.0001)
    }
}
```

**After (23 lines - 49% reduction):**
```swift
@Test("K scale comprehensive tests")
func kScaleComprehensive() {
    let scale = CommonScales.k()
    
    // Boundary tests
    BoundaryTester.expectCorrectBoundaries(scale)
    
    // Round-trip tests - low range with strict tolerance
    RoundTripTester.testRoundTrips(
        values: [1.0, 1.2, 1.5, 2.0],
        on: scale,
        tolerance: TestTolerance.strict
    )
    
    // Round-trip tests - mid range with standard tolerance
    RoundTripTester.testRoundTrips(
        values: [10.0, 20.0, 50.0],
        on: scale,
        tolerance: TestTolerance.standard
    )
    
    // Round-trip tests - high range with relaxed tolerance
    RoundTripTester.testRoundTrips(
        values: [500.0, 800.0, 1000.0],
        on: scale,
        tolerance: TestTolerance.relaxed
    )
    
    // Position round-trips
    RoundTripTester.testPositionRoundTrips(
        positions: TestValues.positions,
        on: scale
    )
}
```

---

## Extensibility

The shared utilities framework is designed to grow with your needs.

### Adding New Tolerance Levels

If you identify a new common tolerance pattern:

```swift
// In SharedTestUtilities.swift
enum TestTolerance {
    static let standard = 0.01
    static let strict = 0.001
    static let relaxed = 0.05
    static let eeScale = 0.05
    static let veryRelaxed = 0.1
    
    // Add new tolerance
    static let ultraPrecise = 0.0001  // For extremely sensitive scales
}
```

### Adding New Test Value Sets

If you discover commonly-repeated value arrays:

```swift
// In SharedTestUtilities.swift
enum TestValues {
    static let logarithmic = [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0]
    static let logarithmicExtended = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    static let squared = [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0]
    static let folded = [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159]
    static let inverted = [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
    static let positions = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
    
    // Add new test value set
    static let trigonometric = [5.7, 10.0, 15.0, 30.0, 45.0, 60.0, 84.3]
}
```

### Adding New Utility Functions

If you identify new repeated patterns:

```swift
// In SharedTestUtilities.swift

// MARK: - Label Testing Utilities
enum LabelTester {
    /// Verify labels are properly generated for a scale
    static func expectValidLabels(
        _ scale: ScaleDefinition,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let generated = GeneratedScale(definition: scale)
        
        #expect(
            !generated.labels.isEmpty,
            "\(scale.name) should have labels",
            sourceLocation: sourceLocation
        )
        
        for label in generated.labels {
            #expect(
                label.position >= 0.0 && label.position <= 1.0,
                "\(scale.name) label position out of range: \(label.position)",
                sourceLocation: sourceLocation
            )
        }
    }
}
```

### Adding Common Scales

When new scales are frequently tested:

```swift
// In SharedTestUtilities.swift
enum CommonScales {
    // ... existing scales ...
    
    // Add new commonly-used scale
    static func ll0(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll0Scale(length: length)
    }
}
```

---

## Impact & Benefits

### Immediate Benefits

1. **Reduced Code Duplication:** 47 lines eliminated in first adoption, ~570+ lines addressable
2. **Improved Consistency:** All tests use same tolerance values and patterns
3. **Better Maintainability:** Changes to test patterns made in one place
4. **Enhanced Readability:** Test intent clearer with descriptive utility names
5. **Type Safety:** Compile-time validation of test patterns

### Long-Term Benefits

1. **Easier Onboarding:** New developers learn one set of utilities
2. **Faster Test Writing:** Less boilerplate for common patterns
3. **Consistent Error Messages:** Standardized failure reporting
4. **Better Test Coverage:** Easier to apply comprehensive tests
5. **Reduced Maintenance Burden:** Single source of truth for test patterns

### Measured Impact

From [`CONSOLIDATION_SUMMARY.md`](../../SlideRuleCoreV3/Tests/CONSOLIDATION_SUMMARY.md:1):

- **ElectricalEngineeringScalesTests.swift:** 47 lines eliminated (26% reduction)
- **Potential across test suite:** ~570+ lines of duplication addressable
- **Files affected:** 44 test files benefit from these utilities
- **Test results:** ✅ All tests pass, no regressions

---

## Related Documentation

- **Source File:** [`SharedTestUtilities.swift`](../../SlideRuleCoreV3/Tests/SlideRuleCoreV3Tests/SharedTestUtilities.swift:1) (362 lines)
- **Consolidation Summary:** [`CONSOLIDATION_SUMMARY.md`](../../SlideRuleCoreV3/Tests/CONSOLIDATION_SUMMARY.md:1)
- **Swift Testing API:** [`swift-testing_api.md`](swift-testing_api.md)
- **Testing Playbook:** [`swift-testing-playbook.md`](swift-testing-playbook.md)
- **Test Coverage Plan:** [`test-coverage-plan.md`](test-coverage-plan.md)

---

## Summary

The SharedTestUtilities framework provides seven powerful utilities that consolidate common testing patterns across the SlideRuleCoreV3 test suite:

1. **TestTolerance** - Standard tolerance constants
2. **TestValues** - Pre-defined test value collections
3. **TestScaleFactory** - Type-safe scale retrieval
4. **RoundTripTester** - Round-trip accuracy testing
5. **ScaleComparator** - Scale parity testing
6. **BoundaryTester** - Boundary condition testing
7. **CommonScales** - Quick scale instantiation

By adopting these utilities, you'll write clearer, more maintainable tests with less boilerplate while ensuring consistency across the entire test suite. The framework has already eliminated 47 lines of duplication in its first adoption, with potential to eliminate 570+ lines across the full test suite.

**Remember:** When writing new tests, always check if existing utilities can help. When you notice repeated patterns, consider extending the shared utilities to benefit all tests.
