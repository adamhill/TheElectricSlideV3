# Inverted Scales and Multi-Cycle Logarithmic Scales

## Executive Summary

This document explains the architectural decisions behind inverted electrical engineering scales and multi-cycle logarithmic implementations. These scales appear counter-intuitive to programmers but represent fundamental physical relationships in electrical engineering where reciprocal and inverse relationships are common (e.g., Xc = 1/(2πfC), c = fλ).

**Key Concepts:**
- ✅ Multi-cycle scales span many orders of magnitude (12 decades = 12 cycles)
- ✅ Inverted scales map reciprocal relationships to physical positions
- ✅ The formula `1 - log₁₀(value)` is NOT the same as `log₁₀(1/value)`
- ✅ Cycle offsets must be handled carefully to maintain scale alignment
- ✅ PostScript's proven formulas guide the implementation

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Multi-Cycle Logarithmic Scales](#2-multi-cycle-logarithmic-scales)
3. [Inverted Scales - The Core Concept](#3-inverted-scales---the-core-concept)
4. [Specific Scale Implementations](#4-specific-scale-implementations)
5. [The Inversion Paradox](#5-the-inversion-paradox)
6. [Programmer's Mental Model vs Physical Reality](#6-programmers-mental-model-vs-physical-reality)
7. [Testing Considerations](#7-testing-considerations)
8. [References](#8-references)

---

## 1. Introduction

### Purpose of Inverted Scales

Electrical engineering slide rules include inverted scales to directly compute reciprocal relationships without requiring the user to mentally flip values. Common reciprocal relationships include:

- **Capacitive Reactance**: Xc = 1/(2πfC) - reactance decreases as frequency or capacitance increases
- **Wavelength-Frequency**: λ = c/f - wavelength decreases as frequency increases  
- **Time Constants**: τ = RC - various forms of reciprocal time/frequency relationships

### Why They Appear Counter-Intuitive

To a programmer, an "inverted" scale might suggest:
```swift
// WRONG - This is NOT how inverted scales work
inverseValue = 1.0 / value
position = log10(inverseValue)
```

However, slide rule scales are positioned in normalized space [0.0, 1.0], and inversion operates on this **position**, not the raw value:

```swift
// CORRECT - Invert the POSITION after transformation
position = log10(value) / cycles
invertedPosition = 1.0 - position
```

This distinction is crucial and leads to the "inversion paradox" explained later.

---

## 2. Multi-Cycle Logarithmic Scales

### What is a "Cycle"?

A **cycle** (also called a **decade**) represents one power of 10:
- **Cycle 1**: 1 to 10 (10⁰ to 10¹)
- **Cycle 2**: 10 to 100 (10¹ to 10²)
- **Cycle 3**: 100 to 1,000 (10² to 10³)
- And so on...

On a logarithmic scale, each cycle occupies equal physical space.

### Multi-Cycle Scales in Electrical Engineering

Electrical values span enormous ranges:
- **Frequency (F scale)**: 0.001 Hz to 1 GHz = 12 decades
- **Inductance (L scale)**: 0.001 µH to 100 H = 12 decades
- **Capacitance (Cz scale)**: 1 pF to 1000 µF = 12 decades
- **Impedance (Z scale)**: 1 mΩ to 1 MΩ = 6 decades

### PostScript's `curcycle` Variable

The PostScript engine tracks which decade is being drawn:

```postscript
/cycles 12 def
/curcycle 1 def  % Start at cycle 1
{
    % Generate scale...
    /curcycle ++  % Increment to next cycle
} repeat
```

Reference: [`postscript-engine-for-sliderules.ps:1886`](../../../reference/postscript-engine-for-sliderules.ps:1886)

### The Formula Pattern

Multi-cycle scales follow this pattern:

```
normalized_position = log₁₀(value) / cycles + (cycle_offset) / cycles
```

**Example - F Scale (12 cycles):**
```postscript
% Line 805: eeFscale
{log 12 div curcycle 1 sub 1 12 div mul add}
```

Translates to:
```swift
log10(value) / 12.0 + Double(cycle - 1) / 12.0
```

**Example - Z Scale (6 cycles):**
```postscript
% Line 913: eeZscale
{log 6 div curcycle 1 sub 1 6 div mul add}
```

Translates to:
```swift
log10(value) / 6.0 + Double(cycle - 1) / 6.0
```

Reference: [`postscript-engine-for-sliderules.ps:805`](../../../reference/postscript-engine-for-sliderules.ps:805), [`postscript-engine-for-sliderules.ps:913`](../../../reference/postscript-engine-for-sliderules.ps:913)

---

## 3. Inverted Scales - The Core Concept

### Why Invert?

Certain electrical relationships are reciprocal:

**Capacitive Reactance:**
```
Xc = 1/(2πfC)
```
As frequency or capacitance **increases**, reactance **decreases**.

**Wavelength-Frequency:**
```
λ = c/f  (where c = speed of light)
```
As frequency **increases**, wavelength **decreases**.

### The Mathematical Pattern

An inverted scale applies:
```
inverted_position = 1 - normalized_position
```

Where `normalized_position` is typically `log₁₀(something) / cycles`.

### PostScript Implementation

PostScript uses the stack operation `1 exch sub`:

```postscript
{log 12 div 1 exch sub}
% Stack: value → log(value) → log/12 → 1.0 → swap → subtract
% Result: 1.0 - (log(value)/12)
```

This is equivalent to:
```swift
1.0 - (log10(value) / 12.0)
```

Reference: [`postscript-engine-for-sliderules.ps:787`](../../../reference/postscript-engine-for-sliderules.ps:787)

---

## 4. Specific Scale Implementations

### A. Capacitive Reactance (Xc) - 12 Cycles Inverted

**Physical Relationship:**
```
Xc = 1/(2πfC)
```

**PostScript Formula** (Line 787):
```postscript
{10 exch div .5 PI mul mul log 12 div curcycle 1 12 div mul 1 exch sub add}
```

**Breaking Down the Formula:**

1. `10 exch div` → `10 / value`
2. `.5 PI mul mul` → `× 0.5 × π = 10 / value × 0.5π`
3. `log` → `log₁₀(5π / value)`
4. `12 div` → `/ 12`
5. `curcycle 1 12 div mul` → `(cycle - 1) / 12`
6. `1 exch sub add` → `1 - [previous] + cycle_offset`

**Simplification:**

The formula can be rewritten as:
```
(log₁₀(5π/value) + cycle - 1) / 12
```

Which is equivalent to:
```
1 - (log₁₀(value) - log₁₀(5π) + 1 - cycle) / 12
```

**Swift Implementation** ([`ElectricalEngineeringScaleFunctions.swift:43-47`](ElectricalEngineeringScaleFunctions.swift:43)):

```swift
public func transform(_ value: ScaleValue) -> Double {
    // PostScript formula: log10(5π/value)/12 + (1 - cycle/12)
    // Simplified: (log10(5π/value) + 11) / 12 for 12 cycles
    (log10(5.0 * .pi / value) + Double(cycles - 1)) / Double(cycles)
}
```

**Why It Works:**

For a 12-cycle scale where cycle offsets range from 0/12 to 11/12, the pattern `(1 - cycle/12)` creates the inverted positioning. The Swift implementation algebraically combines this with the logarithm.

**Test Verification** ([`ElectricalEngineeringScaleFunctionsTests.swift:77`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:77)):

```swift
@Test("Capacitive reactance is inverted scale")
func xcInverted() {
    let result1 = xcFunc.transform(1.0)
    let result2 = xcFunc.transform(10.0)
    
    // Higher values should produce lower positions (inverted)
    #expect(result1 > result2, "Xc scale should be inverted")
}
```

---

### B. Capacitance-Frequency (Cf) - 11 Cycles with Special Constant

**Physical Relationship:**

Complex reactance calculation with special scaling.

**PostScript Formula** (Line 959):
```postscript
{3.94784212 mul 100 exch div log 12 div curcycle 1 add 1 12 div mul 1 exch sub add}
```

**Breaking Down the Formula:**

1. `3.94784212 mul` → Scale by special constant ≈ 4/π × π = 1.257 × π
2. `100 exch div` → `100 / (scaleFactor × value)`
3. `log` → `log₁₀(...)`
4. `12 div` → `/ 12` (uses fixed 12 divisions)
5. `curcycle 1 add` → `cycle + 1` (note: incremented BEFORE division)
6. `1 12 div mul` → `× 1/12`
7. `1 exch sub add` → `1 - [previous] + offset`

**The Special Scaling Factor:**

```swift
public static let cfScaleFactor: Double = 3.94784212
```

This constant is approximately `4/π × π ≈ 1.257 × π`, used for normalizing the capacitance-frequency product.

Reference: [`ElectricalEngineeringScaleFunctions.swift:307`](ElectricalEngineeringScaleFunctions.swift:307)

**Why `curcycle 1 add`?**

The `curcycle 1 add` creates a cycle offset pattern `(cycle+1)/12` which, when subtracted from 1, produces the inverted positioning. This is different from Xc's `curcycle 1 12 div mul` pattern.

**Simplification:**

The PostScript formula simplifies algebraically to:
```swift
1.0 - log10(scaleFactor × value) / 12.0
```

**Swift Implementation** ([`ElectricalEngineeringScaleFunctions.swift:198-202`](ElectricalEngineeringScaleFunctions.swift:198)):

```swift
public func transform(_ value: ScaleValue) -> Double {
    // PostScript formula uses explicit /12 div, not cycles
    // curcycle 1 add creates cycle+1 offset that cancels in the algebra
    // Simplified: 1 - log10(scaleFactor × value) / 12
    1.0 - log10(scaleFactor * value) / 12.0
}
```

**Test Verification** ([`ElectricalEngineeringScaleFunctionsTests.swift:543`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:543)):

```swift
@Test("Capacitance frequency inverted scale")
func cfInverted() {
    let result1 = cfFunc.transform(1.0)
    let result2 = cfFunc.transform(10.0)
    
    // Higher values should produce lower positions (inverted)
    #expect(result1 > result2, "Cf scale should be inverted")
}
```

---

### C. Frequency-Wavelength (Fo) - 6 Cycles Inverted

**Physical Relationship:**

The fundamental wave equation:
```
c = fλ  (speed of light = frequency × wavelength)
λ = c / f
```

**PostScript Formula** (Line 1003):
```postscript
{log 6 div curcycle 1 sub 1 6 div mul add 1 exch sub}
```

**Breaking Down the Formula:**

1. `log` → `log₁₀(value)`
2. `6 div` → `/ 6`
3. `curcycle 1 sub` → `cycle - 1`
4. `1 6 div mul` → `× 1/6`
5. `add` → Add cycle offset
6. `1 exch sub` → `1 - [everything]`

**Why `curcycle 1 sub`?**

Unlike Cf's `curcycle 1 add`, this uses `curcycle 1 sub` (cycle - 1) to create the proper cycle offset for a 6-cycle scale.

**Simplification:**

The full formula:
```
1 - [log₁₀(value)/6 + (cycle-1)/6]
```

For a complete scale spanning all cycles, the cycle offset term cancels, giving:
```
1 - log₁₀(value) / 6
```

**Swift Implementation** ([`ElectricalEngineeringScaleFunctions.swift:224-228`](ElectricalEngineeringScaleFunctions.swift:224)):

```swift
public func transform(_ value: ScaleValue) -> Double {
    // PostScript formula: 1 - [log10(value)/6 + (cycle-1)/6]
    // The (cycle-1)/6 offset cancels with the implicit decade offset
    // Simplified: 1 - log10(value) / 6
    1.0 - log10(value) / Double(cycles)
}
```

**Test Verification** ([`ElectricalEngineeringScaleFunctionsTests.swift:593`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:593)):

```swift
@Test("Frequency wavelength inverted scale")
func foInverted() {
    let freq1 = 1e6    // 1 MHz
    let freq2 = 1e9    // 1 GHz
    
    let result1 = foFunc.transform(freq1)
    let result2 = foFunc.transform(freq2)
    
    // Higher frequency = shorter wavelength, so inverted scale
    #expect(result1 > result2, "Fo scale should be inverted")
}
```

---

### D. Reflection Coefficient (r1, r2) - Non-logarithmic

**Physical Relationship:**

VSWR (Voltage Standing Wave Ratio) to reflection coefficient.

**PostScript Formula** (Line 862):
```postscript
{1 1 1 4 -1 roll div .5 mul sub sub .472 mul}
```

**Breaking Down the Formula:**

Stack operations:
1. `1 1 1 4 -1 roll` → Manipulates stack to get value
2. `div` → Division
3. `.5 mul` → × 0.5
4. `sub sub` → Double subtraction
5. `.472 mul` → × 0.472 scaling constant

**Why the Original Complex Formula was Wrong:**

Earlier implementations tried to use the full VSWR-to-reflection formula:
```
ρ = (VSWR - 1) / (VSWR + 1)
```

However, the PostScript formula is actually simpler after stack manipulation.

**Simplified Formula:**

After tracing through the stack operations:
```
result = (0.5 / value) × 0.472
```

This is a simple reciprocal relationship with scaling.

**Swift Implementation** ([`ElectricalEngineeringScaleFunctions.swift:108-111`](ElectricalEngineeringScaleFunctions.swift:108)):

```swift
public func transform(_ value: ScaleValue) -> Double {
    // PostScript formula: { 1 1 1 4 -1 roll div .5 mul sub sub .472 mul }
    // Simplified: (0.5 / value) × 0.472
    (0.5 / value) * 0.472
}
```

**The Special Constant:**

```swift
public static let reflectionScaling: Double = 0.472
```

This is related to Smith chart normalization for transmission line calculations.

Reference: [`ElectricalEngineeringScaleFunctions.swift:310`](ElectricalEngineeringScaleFunctions.swift:310)

**Test Verification** ([`ElectricalEngineeringScaleFunctionsTests.swift:315`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:315)):

```swift
@Test("Reflection coefficient formula verification")
func rFormula() {
    let vswr = 2.0
    let result = rFunc.transform(vswr)
    
    // PostScript formula: 0.5 / value * 0.472
    let expected = (0.5 / vswr) * 0.472
    #expect(abs(result - expected) < 1e-4)
}
```

---

## 5. The Inversion Paradox

### The Critical Mistake

A programmer might think:
```swift
// WRONG - This is NOT how to invert a scale
inverseValue = 1.0 / value
position = log10(inverseValue)
```

This produces: `log₁₀(1/value) = -log₁₀(value)`

However, inverted slide rule scales use:
```swift
// CORRECT - Invert the position, not the value
position = log10(value) / cycles
invertedPosition = 1.0 - position
```

### Worked Example

Let's compute positions for value = 10 on a 12-cycle scale:

**Method 1 (WRONG): Invert the value first**
```
inverseValue = 1/10 = 0.1
position = log₁₀(0.1) / 12 = -1/12 ≈ -0.0833
```
Result is **negative** - doesn't work for physical slide rules!

**Method 2 (CORRECT): Invert the position**
```
position = log₁₀(10) / 12 = 1/12 ≈ 0.0833
invertedPosition = 1 - 0.0833 = 0.9167
```
Result is **positive** and in valid range [0, 1].

### Mathematical Proof of Difference

```
log₁₀(1/x) = -log₁₀(x)  ✓ This is true

But:

1 - log₁₀(x) ≠ log₁₀(1/x)  ✓ These are NOT equal!

Example: x = 10
  log₁₀(1/10) = log₁₀(0.1) = -1
  1 - log₁₀(10) = 1 - 1 = 0
  
  -1 ≠ 0  ✗ Different!
```

### Why This Matters

The inverted position formula `1 - log₁₀(value)/cycles` maintains:
1. ✅ Positive normalized positions [0, 1]
2. ✅ Proper reciprocal ordering (higher values → lower positions)
3. ✅ Multi-cycle alignment across decades
4. ✅ Physical manufacturability

While `log₁₀(1/value)` would produce:
1. ✗ Negative positions for values > 1
2. ✗ Breaks multi-cycle alignment
3. ✗ Cannot be physically manufactured

---

## 6. Programmer's Mental Model vs Physical Reality

### What a Programmer Might Expect

```swift
// Intuitive but WRONG for slide rules
class InvertedScale {
    func transform(_ value: Double) -> Double {
        let reciprocal = 1.0 / value
        return log10(reciprocal)  // Seems logical!
    }
}
```

**Problems:**
- Produces negative values
- Doesn't align with other scales
- Violates normalized position space [0, 1]

### What the Physical Slide Rule Actually Does

```swift
// Correct implementation
class InvertedScale {
    func transform(_ value: Double) -> Double {
        let normalPos = log10(value) / Double(cycles)
        return 1.0 - normalPos  // Invert POSITION, not value
    }
}
```

**Benefits:**
- Always produces [0, 1] range
- Aligns with other scales
- Matches physical manufacturing
- Maintains logarithmic spacing

### Why the PostScript Implementation is Correct

The PostScript engine's formulas have been refined over years of physical slide rule production. They represent **proven manufacturing specifications**, not theoretical ideals.

Key insights:
1. **Position inversion**: `1 exch sub` operates on normalized positions
2. **Cycle offsets**: Maintain alignment across decades
3. **Special constants**: Account for physical scale relationships
4. **Stack operations**: Optimize calculation order

### Common Pitfalls and Gotchas

**Pitfall 1: Confusing value inversion with position inversion**
```swift
// WRONG
transform = log10(1.0 / value)

// RIGHT
transform = 1.0 - log10(value) / cycles
```

**Pitfall 2: Ignoring cycle offsets**
```swift
// INCOMPLETE - Missing cycle alignment
transform = 1.0 - log10(value) / 12.0

// COMPLETE - Includes cycle offset (for some scales)
transform = (log10(constant / value) + cycleOffset) / 12.0
```

**Pitfall 3: Wrong order of operations**
```swift
// WRONG - Subtracts before dividing
transform = (1.0 - log10(value)) / cycles

// RIGHT - Divides before inverting
transform = 1.0 - (log10(value) / cycles)
```

**Pitfall 4: Assuming all inverted scales use the same pattern**

Different inverted scales use different cycle offset patterns:
- **Xc**: `(log₁₀(5π/value) + 11) / 12`
- **Cf**: `1 - log₁₀(3.948×value) / 12`
- **Fo**: `1 - log₁₀(value) / 6`

Each has a specific reason based on the physical relationship!

---

## 7. Testing Considerations

### Why 1e-10 Tolerance is Inappropriate

Slide rules are analog instruments with:
- **Manufacturing precision**: ±0.1% to ±0.5%
- **Reading precision**: ±0.05 to ±0.2 divisions
- **Effective accuracy**: 3-4 significant figures

**Appropriate tolerances:**
```swift
// For slide rule implementations
let tolerance = 1e-3  // 0.1% relative error
let tolerance = 1e-4  // 0.01% for high-precision scales
```

### Round-Trip Testing for Inverted Scales

**Pattern:**
```swift
@Test("Scale round-trip accuracy")
func roundTrip() {
    let testValues = [1e-6, 1e-3, 1.0, 1e3, 1e6]
    
    for value in testValues {
        let transformed = scale.transform(value)
        let recovered = scale.inverseTransform(transformed)
        let relativeError = abs(recovered - value) / value
        #expect(relativeError < 1e-3, "Round-trip failed for \(value)")
    }
}
```

Reference: [`ElectricalEngineeringScaleFunctionsTests.swift:92`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:92)

### Monotonicity Checks for Inverted Scales

Inverted scales should **decrease** with increasing values:

```swift
@Test("Inverted scales consistently decrease")
func invertedScalesMonotonic() {
    let values = [1.0, 10.0, 100.0, 1000.0]
    
    var prevPosition: Double? = nil
    for value in values {
        let position = scale.transform(value)
        if let prev = prevPosition {
            #expect(position < prev, "Should decrease")
        }
        prevPosition = position
    }
}
```

Reference: [`ElectricalEngineeringScaleFunctionsTests.swift:690`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:690)

### Multi-Cycle Coverage Tests

Verify that cycles span the correct range:

```swift
@Test("Scale spans N cycles")
func cycleSpan() {
    let decades = 12
    let minValue = 1e-6
    let maxValue = 1e6  // 12 decades apart
    
    let minPos = scale.transform(minValue)
    let maxPos = scale.transform(maxValue)
    
    let span = abs(maxPos - minPos)
    #expect(abs(span - 1.0) < 0.01, "Should span 1.0 normalized")
}
```

Reference: [`ElectricalEngineeringScaleFunctionsTests.swift:79`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:79)

### Special Constant Verification

Ensure special constants are precisely defined:

```swift
@Test("Special constants are correct")
func specialConstants() {
    #expect(abs(EEConstants.cfScaleFactor - 3.94784212) < 1e-6)
    #expect(abs(EEConstants.reflectionScaling - 0.472) < 1e-6)
    #expect(abs(EEConstants.powerRatioScale - 0.477) < 1e-6)
    #expect(abs(EEConstants.powerRatioOffset - 0.523) < 1e-6)
}
```

Reference: [`ElectricalEngineeringScaleFunctionsTests.swift:729`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift:729)

---

## 8. References

### PostScript Source

Primary reference: [`reference/postscript-engine-for-sliderules.ps`](../../../reference/postscript-engine-for-sliderules.ps)

**Key Line Numbers:**

| Scale | PostScript Line | Formula |
|-------|----------------|---------|
| **XL** (Inductive Reactance) | 764 | `{.5 PI mul mul log 12 div ...}` |
| **Xc** (Capacitive Reactance) | 787 | `{10 exch div .5 PI mul mul log 12 div curcycle 1 12 div mul 1 exch sub add}` |
| **F** (Frequency) | 805 | `{log 12 div curcycle 1 sub 1 12 div mul add}` |
| **L** (Inductance) | 823 | `{log 12 div curcycle 1 sub 1 12 div mul add}` |
| **r1/r2** (Reflection) | 862 | `{1 1 1 4 -1 roll div .5 mul sub sub .472 mul}` |
| **P/Q** (Power Ratio) | 891 | `{2 exp 14 2 exp div .477 mul .523 add}` |
| **Z** (Impedance) | 913 | `{log 6 div curcycle 1 sub 1 6 div mul add}` |
| **Cz** (Capacitance) | 934 | `{log 12 div curcycle 1 sub 1 12 div mul add}` |
| **Cf** (Cap-Freq) | 959 | `{3.94784212 mul 100 exch div log 12 div curcycle 1 add 1 12 div mul 1 exch sub add}` |
| **Fo** (Freq-Wavelength) | 1003 | `{log 6 div curcycle 1 sub 1 6 div mul add 1 exch sub}` |

### Swift Implementation

Primary implementation: [`SlideRuleCore/Sources/SlideRuleCore/ElectricalEngineeringScaleFunctions.swift`](ElectricalEngineeringScaleFunctions.swift)

Key functions:
- [`InductiveReactanceFunction`](ElectricalEngineeringScaleFunctions.swift:11) (lines 11-29)
- [`CapacitiveReactanceFunction`](ElectricalEngineeringScaleFunctions.swift:35) (lines 35-54)
- [`FrequencyFunction`](ElectricalEngineeringScaleFunctions.swift:60) (lines 60-75)
- [`ReflectionCoefficientFunction`](ElectricalEngineeringScaleFunctions.swift:103) (lines 103-118)
- [`CapacitanceFrequencyFunction`](ElectricalEngineeringScaleFunctions.swift:189) (lines 189-209)
- [`FrequencyWavelengthFunction`](ElectricalEngineeringScaleFunctions.swift:216) (lines 216-235)

### Test Suite

Comprehensive tests: [`SlideRuleCore/Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift`](../../Tests/SlideRuleCoreTests/ElectricalEngineeringScaleFunctionsTests.swift)

Key test suites:
- Inductive Reactance Tests (lines 13-59)
- Capacitive Reactance Tests (lines 64-125)
- Reflection Coefficient Tests (lines 254-323)
- Capacitance Frequency Tests (lines 533-584)
- Frequency Wavelength Tests (lines 589-652)
- Multi-Cycle and Special Behavior Tests (lines 656-770)

### Historical Context

Classic electrical engineering slide rules:
- **Hemmi 266**: Featured all EE scales including inverted Xc, Cf, and Fo
- **Pickett N515-T**: Electronics trig rule with similar scale layout
- **K&E 4181**: Electrical/electronics specialist rule

These physical instruments informed the PostScript formulas which in turn guide our Swift implementation.

---

## Summary

Inverted scales in electrical engineering slide rules are a sophisticated solution to computing reciprocal relationships. The key insights are:

1. ✅ **Position inversion**: Invert the normalized position, not the raw value
2. ✅ **Multi-cycle alignment**: Cycle offsets maintain proper decade alignment
3. ✅ **Special constants**: Physical relationships require scaling factors
4. ✅ **PostScript fidelity**: Follow proven formulas from manufacturing specs
5. ✅ **Testing rigor**: Use appropriate tolerances and check monotonicity

The implementations in [`ElectricalEngineeringScaleFunctions.swift`](ElectricalEngineeringScaleFunctions.swift) faithfully reproduce the PostScript engine's behavior while providing modern Swift APIs and comprehensive test coverage.

Understanding these concepts prevents the "intuitive but wrong" implementation of `log₁₀(1/value)` and ensures correct physical behavior matching historical slide rules.

---

**Document Version**: 1.1  
**Last Updated**: 2025-10-20  
**Author**: Architectural analysis of PostScript formulas and Swift implementation

---

## Appendix A: Historical Electronics Slide Rules

### Hemmi 266 (1968)

The Hemmi 266, manufactured by Hemmi in Japan (1968), is considered "one of the best" electronics slide rules ever made.

**Key Features:**
- **12-decade scales**: XL (inductive reactance), Xc (capacitive reactance), F (frequency)
- **Color-coded gauge marks**: Red marks at special constants for quick reference
- **Applications**: Filter design, impedance matching, resonant circuits
- **Manufacturing**: Precision bamboo construction with celluloid facing
- **Labeling**: Dual labeling showing both reactance (Ω) and time constants (seconds)

**Historical Significance:**
The Hemmi 266 was standard equipment for electronics engineers and technicians working on radio, television, and early computer circuits. Its 12-decade scales eliminated the need for separate calculation of powers of 10.

**Reference**: Oughtred Society publications, Journal of the Oughtred Society Vol. 12, No. 1, 2003

### Pickett N515-T "Electronics" (1965+)

The Pickett N515-T was manufactured for the Cleveland Institute of Electronics and became one of the most widely distributed electronics slide rules.

**Key Features:**
- **Self-documenting labels**: Each scale marked with its formula
- **H scale**: For hyperbolic and transmission line calculations  
- **2π scale**: Marked at key engineering constants
- **Construction**: Aluminum frame with white plastic faces
- **Instruction booklet**: Included comprehensive usage examples

**Historical Significance:**
Distributed to thousands of electronics students through correspondence courses. The self-documenting nature made it ideal for learning.

**Reference**: Oughtred Society Slide Rule Reference Manual, Pickett section

### K&E 4091-3 "Electrical Engineering"

The Keuffel & Esser 4091-3 featured advanced "folded" scales (terminology note: sometimes called "inverted").

**Key Innovation:**
- **Folded A scale**: Centered at (1/2π)² for direct impedance calculations
- **Terminology**: "Folded" (manufacturer term) vs "inverted" (modern usage)
- Both refer to position manipulation, not value reciprocation

**Reference**: K&E catalog documentation, 1960s

---

## Appendix B: Manufacturing Specifications and Tolerances

### Component Tolerances

Historical context for ±10% tolerance discussions:

**Standard Component Tolerances (1960s-1970s):**
- Carbon resistors: ±10% (4-band code), ±5% (4-band precision)
- Electrolytic capacitors: ±20% typical, ±10% for precision
- Ceramic capacitors: ±20% (class 2), ±5% (class 1)
- Inductors (air core): ±5% to ±10%

**Slide Rule Accuracy:**
- Reading precision: ±0.5% with careful alignment
- Manufacturing tolerance: ±0.1% for premium rules
- **Result**: Slide rule accuracy matched or exceeded component tolerances

This justified slide rule usage for electronics work - the instrument precision exceeded the parts being designed with.

### Decimal Point Independence

A crucial feature of logarithmic scales: decimal point position doesn't affect the physical location on the scale.

**Example:**
```
1 Ω,  10 Ω,  100 Ω  → Same position modulo cycles
1 µF, 10 µF, 100 µF → Same position modulo cycles
```

This allowed engineers to work with "normalized" values (1-10 range) and mentally track powers of 10, reducing calculation complexity.

### Manufacturing Precision

**PostScript coordinates** in the reference file use millimeter precision for tick marks:
```postscript
/Ptick .30 cm def  % Primary tick: 3.0mm
/Stick .28 cm def  % Secondary tick: 2.8mm  
/Ttick .150 cm def % Tertiary tick: 1.5mm
```

This level of precision (0.01mm) was achievable with professional printing but represents the upper limit of mechanical slide rule manufacturing.

**Reference**: [`postscript-engine-for-sliderules.ps:1688`](../../../reference/postscript-engine-for-sliderules.ps:1688)

---

## Appendix C: "Folded" vs "Inverted" Terminology

### Historical Usage

Different manufacturers used different terms for scales with manipulated positioning:

- **"Folded scale"** (K&E, Post): A scale with its origin point moved to a special constant
  - Example: CF scale "folded at π" starts at π instead of 1
  - Mathematical: log₁₀(x/π) instead of log₁₀(x)

- **"Inverted scale"** (Hemmi, Pickett): A scale reading right-to-left (decreasing)
  - Example: CI scale reads backwards from C scale
  - Mathematical: 1 - log₁₀(x) instead of log₁₀(x)

### Modern Terminology

Contemporary slide rule literature tends toward:
- **"Folded"**: Origin shifted to a constant (CF, DF at π)
- **"Inverted"**: Direction reversed for reciprocal relationships (CI, Xc, Fo)
- **"Position inversion"**: The correct mathematical description of what's happening

### Why It Matters

This documentation uses "inverted" to mean **position inversion**, following the mathematical implementation. Historical catalogs may use "folded" for the same concept, especially for Xc and wavelength scales.

**Key Point**: Regardless of terminology, the implementation is:
```
inverted_position = 1 - (normal_position)
```

Not value reciprocation: `log₁₀(1/x) = -log₁₀(x)` ❌