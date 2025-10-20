# Range-Based Subsection Boundary Handling Design

## Executive Summary

This document proposes replacing error-prone manual boundary checks (`<` vs `<=`) with Swift's built-in `Range` and `ClosedRange` types to handle subsection boundaries more safely and idiomatically.

**Current Problem:**
```swift
// Line 430-435 in ScaleCalculator.swift
let isLastSubsection = subsectionIndex == definition.subsections.count - 1
let endCheck = isLastSubsection ? value <= boundaries.end : value < boundaries.end
guard value >= boundaries.start && endCheck else { continue }
```

**Proposed Solution:**
```swift
let range: any RangeExpression<Double>
if isLastSubsection {
    range = boundaries.start...boundaries.end  // ClosedRange: include end
} else {
    range = boundaries.start..<boundaries.end  // Range: exclude end
}
guard range.contains(value) else { continue }
```

---

## 1. Swift Range Types Research

### 1.1 Range<Bound> - Half-Open Interval

**Declaration:**
```swift
@frozen struct Range<Bound> where Bound : Comparable
```

**Semantics:**
- Created with half-open range operator: `a..<b`
- Includes lower bound, **excludes** upper bound
- Represents interval [a, b)
- Can represent empty ranges (e.g., `0..<0`)

**Example:**
```swift
let range = 0.0..<5.0
range.contains(3.14)  // true
range.contains(5.0)   // false ✓ Excludes upper bound
range.contains(6.28)  // false
```

**Key Properties:**
- `lowerBound`: The starting value
- `upperBound`: The ending value (not included)
- `isEmpty`: Returns true if range is empty

### 1.2 ClosedRange<Bound> - Closed Interval

**Declaration:**
```swift
@frozen struct ClosedRange<Bound> where Bound : Comparable
```

**Semantics:**
- Created with closed range operator: `a...b`
- Includes **both** lower and upper bounds
- Represents interval [a, b]
- **Cannot** represent empty ranges

**Example:**
```swift
let throughFive = 0.0...5.0
throughFive.contains(3.0)  // true
throughFive.contains(5.0)  // true ✓ Includes upper bound
throughFive.contains(10.0) // false
```

**Key Properties:**
- `lowerBound`: The starting value (included)
- `upperBound`: The ending value (included)
- `isEmpty`: Always false (closed ranges cannot be empty)

### 1.3 RangeExpression Protocol

Both `Range` and `ClosedRange` conform to `RangeExpression`:

```swift
protocol RangeExpression<Bound> {
    associatedtype Bound: Comparable
    func contains(_ element: Bound) -> Bool
}
```

This allows polymorphic usage via existential types:
```swift
let range: any RangeExpression<Double> = someCondition ? 
    start..<end :    // Range
    start...end      // ClosedRange
```

### 1.4 contains(_:) Method

**Purpose:** Check if a value is within the range

**For Range<Bound>:**
```swift
func contains(_ element: Bound) -> Bool
// Returns true if lowerBound <= element < upperBound
```

**For ClosedRange<Bound>:**
```swift
func contains(_ element: Bound) -> Bool
// Returns true if lowerBound <= element <= upperBound
```

**Critical Insight:** `contains()` handles floating-point comparisons using standard `<` and `<=` operators, which is identical to our manual checks but encapsulated in a well-tested, semantic API.

---

## 2. stride() Functions for Iteration

### 2.1 stride(from:to:by:) - Half-Open

**Declaration:**
```swift
func stride<T>(from start: T, to end: T, by stride: T.Stride) -> StrideTo<T> 
    where T : Strideable
```

**Semantics:**
- Excludes `end` value
- Matches `Range<T>` semantics
- Returns `StrideTo<T>` sequence

**Example:**
```swift
for radians in stride(from: 0.0, to: .pi * 2, by: .pi / 2) {
    print(radians)
}
// Prints: 0.0, 1.57..., 3.14..., 4.71...
// Does NOT print 6.28... (2π) - excluded!
```

### 2.2 stride(from:through:by:) - Closed/Inclusive

**Declaration:**
```swift
func stride<T>(from start: T, through end: T, by stride: T.Stride) -> StrideThrough<T> 
    where T : Strideable
```

**Semantics:**
- **Includes** `end` value (if reachable by stride)
- Matches `ClosedRange<T>` semantics
- Returns `StrideThrough<T>` sequence

**Example:**
```swift
for radians in stride(from: 0.0, through: .pi * 2, by: .pi / 2) {
    print(radians)
}
// Prints: 0.0, 1.57..., 3.14..., 4.71..., 6.28...
// DOES print 2π - included!
```

**Critical Insight:** `stride(from:through:by:)` **naturally matches PostScript's inclusive `for` operator**, which includes the end value. This is exactly what we need!

---

## 3. Current Implementation Analysis

### 3.1 Problem Location

File: [`SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift`](SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift)

Lines 379-456: `generateSubsectionTicksModulo()`

**Current Boundary Calculation (lines 458-487):**
```swift
private static func calculateSubsectionBoundaries(
    subsection: ScaleSubsection,
    subsectionIndex: Int,
    definition: ScaleDefinition,
    finestInterval: Double
) -> (start: Double, end: Double) {
    let clampedStart = max(subsection.startValue, definition.beginValue)
    
    let subsectionEnd: Double
    if subsectionIndex < definition.subsections.count - 1 {
        // Not last subsection: use next subsection's start
        let nextSubsection = definition.subsections[subsectionIndex + 1]
        subsectionEnd = nextSubsection.startValue
    } else {
        // Last subsection: end = scale's end value
        subsectionEnd = definition.endValue
    }
    
    let clampedEnd = min(subsectionEnd, definition.endValue)
    return (start: clampedStart, end: clampedEnd)
}
```

**Current Range Check (lines 430-435):**
```swift
// 7. Validate range (use < for end boundary except last subsection)
let isLastSubsection = subsectionIndex == definition.subsections.count - 1
let endCheck = isLastSubsection ? value <= boundaries.end : value < boundaries.end
guard value >= boundaries.start && endCheck else {
    continue
}
```

### 3.2 Issues with Current Approach

1. **Cognitive Overhead:** Developer must remember inclusive/exclusive semantics
2. **Error-Prone:** Easy to swap `<` and `<=` accidentally
3. **Duplication:** Logic repeated in multiple places
4. **Unclear Intent:** `endCheck` variable name doesn't convey inclusive/exclusive
5. **Manual Tracking:** Need `isLastSubsection` flag

### 3.3 PostScript Reference

From [`reference/postscript-rule-engine-explainer.md`](reference/postscript-rule-engine-explainer.md:726-744):

PostScript uses inclusive `for` loops:
```postscript
% PostScript: beginsub increment endsub { ... } for
% Semantics: for i = beginsub to endsub step increment (INCLUSIVE)

1 .01 2 {  % Loop from 1.00 to 2.00 inclusive, step 0.01
    % Process tick at value i
} for
```

The last value (2.00) **is included** in the iteration, matching `ClosedRange` semantics.

---

## 4. Proposed Solution: Range-Based Boundaries

### 4.1 Core Design Principle

**Replace manual `<`/`<=` checks with Swift Range types that encapsulate boundary semantics.**

### 4.2 Subsection Boundary Representation

**New Return Type:**
```swift
private static func calculateSubsectionBoundaries(
    subsection: ScaleSubsection,
    subsectionIndex: Int,
    definition: ScaleDefinition,
    finestInterval: Double
) -> any RangeExpression<Double> {
    let clampedStart = max(subsection.startValue, definition.beginValue)
    
    let isLastSubsection = subsectionIndex == definition.subsections.count - 1
    
    if isLastSubsection {
        // Last subsection: INCLUDE end value (matches PostScript)
        let clampedEnd = min(definition.endValue, definition.endValue)
        return clampedStart...clampedEnd  // ClosedRange
    } else {
        // Non-last subsection: EXCLUDE next subsection's start
        let nextSubsection = definition.subsections[subsectionIndex + 1]
        let subsectionEnd = min(nextSubsection.startValue, definition.endValue)
        return clampedStart..<subsectionEnd  // Range (half-open)
    }
}
```

**Key Advantages:**
1. Type system enforces correct semantics
2. Self-documenting: `...` vs `..<` clearly shows intent
3. Eliminates manual boundary logic
4. Returns semantic Range type instead of raw tuple

### 4.3 Updated Range Check

**Before:**
```swift
let isLastSubsection = subsectionIndex == definition.subsections.count - 1
let endCheck = isLastSubsection ? value <= boundaries.end : value < boundaries.end
guard value >= boundaries.start && endCheck else {
    continue
}
```

**After:**
```swift
let range = calculateSubsectionBoundaries(
    subsection: subsection,
    subsectionIndex: subsectionIndex,
    definition: definition,
    finestInterval: finestInterval
)

guard range.contains(value) else {
    continue
}
```

**Benefits:**
- 3 lines → 1 line check
- No manual comparisons
- No tracking of `isLastSubsection` at call site
- Clear semantic intent: "Is value in range?"

---

## 5. Range<Double> vs Range<Int> Analysis

### 5.1 The Question

Should we use `Range<Double>` in real space or `Range<Int>` in integer space (after xfactor conversion)?

### 5.2 Current Integer Space Usage

Lines 401-415:
```swift
// Convert to integer space using xfactor
let xfactor = config.precisionMultiplier
let startInt = toIntegerSpace(boundaries.start, xfactor: xfactor)
let endInt = toIntegerSpace(boundaries.end, xfactor: xfactor)
let incrementInt = toIntegerSpace(finestInterval, xfactor: xfactor)

// Single pass through all positions at finest granularity
var currentInt = startInt

while currentInt <= endInt {
    defer { currentInt += incrementInt }
    
    // Convert back to real value
    let value = toRealSpace(currentInt, xfactor: xfactor)
    
    // Validate range
    guard value >= boundaries.start && endCheck else { continue }
    // ...
}
```

### 5.3 Evaluation: Range<Double> (Recommended)

**Pros:**
- Simpler: No conversion back and forth
- More semantic: Boundaries are naturally in real space
- Matches PostScript: PostScript works in real space
- Cleaner API: Range boundaries match actual scale values

**Cons:**
- Potential floating-point comparison issues (minimal in practice)

**Example:**
```swift
let range: any RangeExpression<Double> = isLastSubsection ?
    1.0...2.0 :      // Include 2.0
    1.0..<2.0        // Exclude 2.0

// Loop in integer space for precision
for tickInt in stride(from: startInt, through: endInt, by: incrementInt) {
    let value = toRealSpace(tickInt, xfactor: xfactor)
    guard range.contains(value) else { continue }
    // Process tick...
}
```

### 5.4 Alternative: Range<Int> (Not Recommended)

**Pros:**
- Exact integer arithmetic
- No floating-point precision concerns

**Cons:**
- Less intuitive: Boundaries in integer space (e.g., 100, 199) vs real space (1.0, 1.99)
- More conversions: Must convert boundaries to integer space
- API confusion: Function signatures work with Doubles but return Int ranges

**Example:**
```swift
let startInt = toIntegerSpace(clampedStart, xfactor: xfactor)
let endInt = toIntegerSpace(clampedEnd, xfactor: xfactor)

let range: any RangeExpression<Int> = isLastSubsection ?
    startInt...endInt :
    startInt..<endInt

for tickInt in stride(from: startInt, through: endInt, by: incrementInt) {
    guard range.contains(tickInt) else { continue }
    let value = toRealSpace(tickInt, xfactor: xfactor)
    // Process tick...
}
```

### 5.5 Recommendation

**Use `Range<Double>` for boundary representation.**

Rationale:
1. Simpler mental model: Work in real space for boundaries
2. Integer space is an implementation detail for precision
3. `contains()` check on Double is O(1) comparison, not expensive
4. Floating-point comparison is already used throughout (line 433)
5. Matches semantic level of API (ScaleValue is Double)

---

## 6. stride() Integration

### 6.1 Current Loop Structure

Lines 414-453:
```swift
var currentInt = startInt

while currentInt <= endInt {
    defer { currentInt += incrementInt }
    
    // Determine hierarchy level using modulo
    guard let level = determineTickLevel(...) else { continue }
    
    // Convert back to real value
    let value = toRealSpace(currentInt, xfactor: xfactor)
    
    // Validate range
    guard value >= boundaries.start && endCheck else { continue }
    
    // Handle circular scale edge case
    if definition.isCircular && config.skipCircularOverlap { ... }
    
    // Create tick at determined level
    let tick = createTickAtLevel(...)
    ticks.append(tick)
}
```

### 6.2 Proposed: stride(from:through:by:)

**Key Insight:** PostScript's `for` operator is inclusive, matching `stride(from:through:by:)` semantics!

**Updated Loop:**
```swift
let range = calculateSubsectionBoundaries(...)

// Use stride(from:through:by:) to match PostScript's inclusive loop
for tickInt in stride(from: startInt, through: endInt, by: incrementInt) {
    // Determine hierarchy level using modulo
    guard let level = determineTickLevel(
        position: tickInt,
        intervals: subsection.tickIntervals,
        xfactor: xfactor
    ) else {
        continue
    }
    
    // Convert back to real value
    let value = toRealSpace(tickInt, xfactor: xfactor)
    
    // Validate range (Range automatically handles boundaries!)
    guard range.contains(value) else {
        continue
    }
    
    // Handle circular scale edge case
    if definition.isCircular && config.skipCircularOverlap {
        if shouldSkipCircularTick(value, definition, tolerance: 0.01 * finestInterval) {
            continue
        }
    }
    
    // Create tick at determined level
    let tick = createTickAtLevel(
        value: value,
        level: level,
        subsection: subsection,
        definition: definition
    )
    
    ticks.append(tick)
}
```

### 6.3 Benefits of stride(from:through:by:)

1. **Matches PostScript:** Both are inclusive of end value
2. **More Swifty:** Idiomatic iteration over sequences
3. **Eliminates Manual Increment:** No `defer { currentInt += incrementInt }`
4. **Clearer Intent:** "Stride through values" vs "while loop with manual tracking"
5. **Works with Range:** stride + Range.contains() = clean boundary handling

### 6.4 Why through Instead of to?

**stride(from:to:by:)** - Excludes end:
```swift
for i in stride(from: 100, to: 200, by: 1) {
    // Iterates 100, 101, ..., 199 (NOT 200)
}
```

**stride(from:through:by:)** - Includes end:
```swift
for i in stride(from: 100, through: 200, by: 1) {
    // Iterates 100, 101, ..., 199, 200 (includes 200!)
}
```

PostScript `for` operator includes the end value, so we must use `through`.

---

## 7. Complete Solution Design

### 7.1 Updated calculateSubsectionBoundaries

```swift
/// Calculate subsection boundary range with proper inclusive/exclusive semantics
/// - Returns: Range for non-last subsections (exclusive end), ClosedRange for last subsection (inclusive end)
private static func calculateSubsectionBoundaries(
    subsection: ScaleSubsection,
    subsectionIndex: Int,
    definition: ScaleDefinition
) -> any RangeExpression<Double> {
    // Clamp start to scale's begin value
    let clampedStart = max(subsection.startValue, definition.beginValue)
    
    // Determine if this is the last subsection
    let isLastSubsection = subsectionIndex == definition.subsections.count - 1
    
    if isLastSubsection {
        // Last subsection: INCLUDE end value (matches PostScript inclusive 'for')
        // Use ClosedRange: [start...end]
        let clampedEnd = min(definition.endValue, definition.endValue)
        return clampedStart...clampedEnd
    } else {
        // Non-last subsection: EXCLUDE next subsection's start to avoid overlap
        // Use Range: [start..<nextStart)
        let nextSubsection = definition.subsections[subsectionIndex + 1]
        let subsectionEnd = min(nextSubsection.startValue, definition.endValue)
        return clampedStart..<subsectionEnd
    }
}
```

### 7.2 Updated generateSubsectionTicksModulo

```swift
/// Generate ticks for a single subsection using modulo algorithm
private static func generateSubsectionTicksModulo(
    subsection: ScaleSubsection,
    subsectionIndex: Int,
    definition: ScaleDefinition,
    config: ModuloTickConfig
) -> [TickMark] {
    var ticks: [TickMark] = []
    
    // 1. Find finest (smallest non-null) interval
    guard let finestInterval = subsection.tickIntervals.filter({ $0 > 0 }).min() else {
        return []
    }
    
    // 2. Calculate proper subsection boundary range
    let range = calculateSubsectionBoundaries(
        subsection: subsection,
        subsectionIndex: subsectionIndex,
        definition: definition
    )
    
    // 3. Convert to integer space for precision
    let xfactor = config.precisionMultiplier
    
    // Extract bounds from range for integer conversion
    let (boundsStart, boundsEnd): (Double, Double) = {
        if let closedRange = range as? ClosedRange<Double> {
            return (closedRange.lowerBound, closedRange.upperBound)
        } else if let openRange = range as? Range<Double> {
            return (openRange.lowerBound, openRange.upperBound)
        } else {
            fatalError("Unexpected range type")
        }
    }()
    
    let startInt = toIntegerSpace(boundsStart, xfactor: xfactor)
    let endInt = toIntegerSpace(boundsEnd, xfactor: xfactor)
    let incrementInt = toIntegerSpace(finestInterval, xfactor: xfactor)
    
    guard incrementInt > 0 else {
        return []
    }
    
    // 4. Single pass using stride(from:through:by:) to match PostScript
    for tickInt in stride(from: startInt, through: endInt, by: incrementInt) {
        // 5. Determine hierarchy level using modulo
        guard let level = determineTickLevel(
            position: tickInt,
            intervals: subsection.tickIntervals,
            xfactor: xfactor
        ) else {
            continue
        }
        
        // 6. Convert back to real value
        let value = toRealSpace(tickInt, xfactor: xfactor)
        
        // 7. Validate using Range.contains() - handles inclusive/exclusive automatically!
        guard range.contains(value) else {
            continue
        }
        
        // 8. Handle circular scale edge case
        if definition.isCircular && config.skipCircularOverlap {
            if shouldSkipCircularTick(value, definition, tolerance: 0.01 * finestInterval) {
                continue
            }
        }
        
        // 9. Create tick at determined level
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
```

### 7.3 Key Changes Summary

1. **calculateSubsectionBoundaries** now returns `any RangeExpression<Double>` instead of tuple
2. Use **ClosedRange** (`...`) for last subsection, **Range** (`..<`) for others
3. Replace **while loop** with **`stride(from:through:by:)`** for idiomatic iteration
4. Replace **manual boundary checks** with **`range.contains(value)`**
5. **Type system** enforces correct inclusive/exclusive semantics

---

## 8. Benefits Analysis

### 8.1 Correctness

| Aspect | Before | After |
|--------|--------|-------|
| Boundary Logic | Manual `<` vs `<=` | `Range.contains()` (tested API) |
| Last Subsection | Tracked via flag | Encoded in `ClosedRange` type |
| Loop Semantics | While with manual increment | `stride(through:)` - matches PostScript |
| Intent Clarity | Implicit in comparisons | Explicit in Range type choice |

### 8.2 Code Quality

**Lines of Code:**
- Before: ~7 lines for boundary check logic
- After: ~2 lines (`calculateSubsectionBoundaries` + `range.contains()`)

**Cognitive Load:**
- Before: Must remember inclusive/exclusive rules
- After: Type system enforces rules

**Maintainability:**
- Before: Easy to introduce bugs by swapping `<` and `<=`
- After: Compiler prevents incorrect usage

### 8.3 Swift Idiomaticity

| Pattern | Rating | Notes |
|---------|--------|-------|
| Manual `while` loops | ❌ | Un-Swifty |
| `stride(from:through:by:)` | ✅ | Idiomatic Swift |
| Raw tuple returns | ❌ | Lose type information |
| `RangeExpression<T>` | ✅ | Protocol-oriented design |
| Manual `<`/`<=` checks | ❌ | Error-prone |
| `Range.contains()` | ✅ | Self-documenting, tested |

### 8.4 Performance

**No Performance Impact:**
- `Range.contains()` compiles to same comparisons
- `stride()` is a zero-cost abstraction (inlined by optimizer)
- Integer space conversion unchanged

---

## 9. Testing Strategy

### 9.1 Test Cases for Range Boundaries

```swift
func testSubsectionBoundaries() {
    // Test non-last subsection (exclusive end)
    let nonLastRange = calculateSubsectionBoundaries(
        subsection: subsection1,
        subsectionIndex: 0,
        definition: cScale
    )
    
    XCTAssertTrue(nonLastRange.contains(1.0))   // Include start
    XCTAssertTrue(nonLastRange.contains(1.5))   // Middle
    XCTAssertTrue(nonLastRange.contains(1.999)) // Near end
    XCTAssertFalse(nonLastRange.contains(2.0))  // Exclude end ✓
    
    // Test last subsection (inclusive end)
    let lastRange = calculateSubsectionBoundaries(
        subsection: subsection2,
        subsectionIndex: 1, // Last
        definition: cScale
    )
    
    XCTAssertTrue(lastRange.contains(2.0))      // Include start
    XCTAssertTrue(lastRange.contains(5.0))      // Middle
    XCTAssertTrue(lastRange.contains(9.999))    // Near end
    XCTAssertTrue(lastRange.contains(10.0))     // Include end ✓
}
```

### 9.2 Test stride() vs while Loop Equivalence

```swift
func testStrideVsWhileEquivalence() {
    let startInt = 100
    let endInt = 200
    let incrementInt = 1
    
    // Old way: while loop
    var whileResults: [Int] = []
    var current = startInt
    while current <= endInt {
        whileResults.append(current)
        current += incrementInt
    }
    
    // New way: stride(from:through:by:)
    let strideResults = Array(stride(from: startInt, through: endInt, by: incrementInt))
    
    XCTAssertEqual(whileResults, strideResults)
    XCTAssertEqual(whileResults.count, 101) // 100...200 inclusive
    XCTAssertEqual(whileResults.last, 200)  // Includes end ✓
}
```

### 9.3 Integration Test: Tick Generation

```swift
func testTickGenerationWithRanges() {
    let cScale = ScaleDefinition(/* ... */)
    let config = ModuloTickConfig.default
    
    // Generate ticks using new Range-based approach
    let ticks = ScaleCalculator.generateTickMarksModulo(
        for: cScale,
        config: config
    )
    
    // Verify no duplicate ticks at subsection boundaries
    let tickValues = ticks.map { $0.value }
    let uniqueValues = Set(tickValues)
    XCTAssertEqual(tickValues.count, uniqueValues.count, "No duplicate ticks")
    
    // Verify last tick is included
    XCTAssertTrue(tickValues.contains(cScale.endValue), "Last tick included")
    
    // Verify subsection boundary is NOT duplicated
    let subsection1End = cScale.subsections[0].startValue + 1.0
    let boundaryTicks = tickValues.filter { abs($0 - subsection1End) < 0.001 }
    XCTAssertEqual(boundaryTicks.count, 1, "Boundary not duplicated")
}
```

---

## 10. Migration Plan

### 10.1 Phase 1: Update calculateSubsectionBoundaries

**File:** [`SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift`](SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift)

**Changes:**
1. Change return type from `(start: Double, end: Double)` to `any RangeExpression<Double>`
2. Return `ClosedRange` for last subsection, `Range` for others
3. Remove `finestInterval` parameter (not needed)

### 10.2 Phase 2: Update generateSubsectionTicksModulo

**Changes:**
1. Update call to `calculateSubsectionBoundaries` (no finestInterval)
2. Extract bounds from range for integer conversion
3. Replace `while` loop with `stride(from:through:by:)`
4. Replace manual boundary check with `range.contains(value)`

### 10.3 Phase 3: Testing

1. Run existing test suite - should pass unchanged
2. Add new tests for Range boundary behavior
3. Verify no duplicate ticks at boundaries
4. Performance benchmarks (expect no change)

### 10.4 Phase 4: Documentation

1. Update inline comments to reference Range types
2. Add doc comments explaining Range choice
3. Update architecture documents

---

## 11. Alternative Approaches Considered

### 11.1 Custom BoundaryRange Struct

**Idea:** Create custom type wrapping Range/ClosedRange

```swift
struct BoundaryRange {
    let start: Double
    let end: Double
    let includeEnd: Bool
    
    func contains(_ value: Double) -> Bool {
        value >= start && (includeEnd ? value <= end : value < end)
    }
}
```

**Pros:**
- Custom semantics
- More explicit includeEnd flag

**Cons:**
- Reinventing the wheel
- Lose Swift standard library integration
- More code to maintain

**Decision:** ❌ Rejected - Use standard Range types instead

### 11.2 Always Use ClosedRange

**Idea:** Always use `ClosedRange`, adjust end value

```swift
let adjustedEnd = isLastSubsection ? 
    boundaries.end : 
    boundaries.end - epsilon // Subtract tiny amount
return start...adjustedEnd
```

**Pros:**
- Single range type

**Cons:**
- Magic epsilon value
- Floating-point arithmetic issues
- Hides intent (exclusive end)

**Decision:** ❌ Rejected - Use appropriate Range type for semantics

### 11.3 Keep Manual Checks, Add Helper Function

**Idea:** Wrap current logic in helper function

```swift
func isInBoundary(_ value: Double, start: Double, end: Double, includeEnd: Bool) -> Bool {
    value >= start && (includeEnd ? value <= end : value < end)
}
```

**Pros:**
- Minimal change
- Encapsulates logic

**Cons:**
- Still manual comparison logic
- Doesn't leverage type system
- Less idiomatic

**Decision:** ❌ Rejected - Range types are more idiomatic

---

## 12. Conclusion

### 12.1 Recommendation Summary

**Adopt Range-based boundary handling:**

1. ✅ Use `Range<Double>` (..<) for non-last subsections (exclusive end)
2. ✅ Use `ClosedRange<Double>` (...) for last subsection (inclusive end)
3. ✅ Return `any RangeExpression<Double>` from `calculateSubsectionBoundaries`
4. ✅ Replace manual `<`/`<=` checks with `range.contains(value)`
5. ✅ Use `stride(from:through:by:)` to match PostScript's inclusive loop
6. ✅ Work in real space (Double) for ranges, integer space for iteration

### 12.2 Key Advantages

| Benefit | Impact |
|---------|--------|
| Type Safety | Compiler enforces correct boundary semantics |
| Clarity | `...` vs `..<` shows intent explicitly |
| Maintainability | Less code, fewer bugs |
| Idiomaticity | Follows Swift best practices |
| PostScript Match | `stride(through:)` matches inclusive `for` |
| Testability | Range types are well-tested standard library |

### 12.3 Risk Assessment

**Low Risk:**
- Standard library types (well-tested)
- No performance impact
- Backward compatible behavior
- Easy to test

**Mitigation:**
- Comprehensive test suite
- Side-by-side comparison with old behavior
- Gradual rollout possible

### 12.4 Next Steps

1. **Review:** Get approval from team
2. **Implement:** Apply changes to `ScaleCalculator.swift`
3. **Test:** Run full test suite + new Range tests
4. **Document:** Update inline comments and architecture docs
5. **Deploy:** Merge to main branch

---

## Appendix A: Code Comparison

### Before (Current)
```swift
// Calculate boundaries as tuple
private static func calculateSubsectionBoundaries(
    subsection: ScaleSubsection,
    subsectionIndex: Int,
    definition: ScaleDefinition,
    finestInterval: Double
) -> (start: Double, end: Double) {
    let clampedStart = max(subsection.startValue, definition.beginValue)
    let subsectionEnd: Double
    if subsectionIndex < definition.subsections.count - 1 {
        let nextSubsection = definition.subsections[subsectionIndex + 1]
        subsectionEnd = nextSubsection.startValue
    } else {
        subsectionEnd = definition.endValue
    }
    let clampedEnd = min(subsectionEnd, definition.endValue)
    return (start: clampedStart, end: clampedEnd)
}

// Usage in generateSubsectionTicksModulo
let boundaries = calculateSubsectionBoundaries(...)
let startInt = toIntegerSpace(boundaries.start, xfactor: xfactor)
let endInt = toIntegerSpace(boundaries.end, xfactor: xfactor)

var currentInt = startInt
while currentInt <= endInt {
    defer { currentInt += incrementInt }
    
    guard let level = determineTickLevel(...) else { continue }
    let value = toRealSpace(currentInt, xfactor: xfactor)
    
    // Manual boundary check
    let isLastSubsection = subsectionIndex == definition.subsections.count - 1
    let endCheck = isLastSubsection ? value <= boundaries.end : value < boundaries.end
    guard value >= boundaries.start && endCheck else { continue }
    
    // ... rest of processing
}
```

### After (Proposed)
```swift
// Calculate boundaries as Range type
private static func calculateSubsectionBoundaries(
    subsection: ScaleSubsection,
    subsectionIndex: Int,
    definition: ScaleDefinition
) -> any RangeExpression<Double> {
    let clampedStart = max(subsection.startValue, definition.beginValue)
    let isLastSubsection = subsectionIndex == definition.subsections.count - 1
    
    if isLastSubsection {
        let clampedEnd = min(definition.endValue, definition.endValue)
        return clampedStart...clampedEnd  // ClosedRange
    } else {
        let nextSubsection = definition.subsections[subsectionIndex + 1]
        let subsectionEnd = min(nextSubsection.startValue, definition.endValue)
        return clampedStart..<subsectionEnd  // Range
    }
}

// Usage in generateSubsectionTicksModulo
let range = calculateSubsectionBoundaries(...)

// Extract bounds for integer conversion
let (boundsStart, boundsEnd) = /* extract from range */
let startInt = toIntegerSpace(boundsStart, xfactor: xfactor)
let endInt = toIntegerSpace(boundsEnd, xfactor: xfactor)

// Use stride instead of while loop
for tickInt in stride(from: startInt, through: endInt, by: incrementInt) {
    guard let level = determineTickLevel(...) else { continue }
    let value = toRealSpace(tickInt, xfactor: xfactor)
    
    // Range.contains() handles inclusive/exclusive automatically!
    guard range.contains(value) else { continue }
    
    // ... rest of processing
}
```

**Line Count Reduction:** ~15 lines → ~8 lines
**Cognitive Complexity:** High → Low
**Error Potential:** High → Minimal

---

## Appendix B: References

- [Swift Range Documentation](https://developer.apple.com/documentation/swift/range)
- [Swift ClosedRange Documentation](https://developer.apple.com/documentation/swift/closedrange)
- [Swift stride(from:to:by:) Documentation](https://developer.apple.com/documentation/swift/stride(from:to:by:)/)
- [Swift stride(from:through:by:) Documentation](https://developer.apple.com/documentation/swift/stride(from:through:by:)/)
- [RangeExpression Protocol](https://developer.apple.com/documentation/swift/rangeexpression)
- [PostScript Rule Engine Explainer](reference/postscript-rule-engine-explainer.md)
- [Modulo Tick Generation Design](architecture/modulo-tick-generation-design.md)