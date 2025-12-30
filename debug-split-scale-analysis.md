# Split Scale Position Calculation Analysis
**Date**: 2025-12-30
**Issue**: Split scales not filling their allocated physical regions

## Manual Calculation Trace

### Test Case 1: C Scale 50/50 Split (log₁₀ function)

**Configuration:**
- Total scale length: 800pt
- Left segment: range 1.0 → 3.162 (√10), physical 0.0...0.5, formulaOffset=0.0
- Right segment: range 3.162 → 10.0, physical 0.5...1.0, formulaOffset=-1.0

---

### LEFT SEGMENT Calculations

**Algorithm (from ScaleCalculator.normalizedPosition, lines 113-138):**
```swift
fL = log₁₀(1.0) = 0.0
fR = log₁₀(3.162) ≈ 0.5
denominator = 0.5 - 0.0 = 0.5

For each value:
  fx = log₁₀(value)
  baseNormalizedPosition = (fx - fL) / denominator
  adjustedPosition = baseNormalizedPosition + formulaOffset
  physicalPosition = physicalRange.lowerBound + (adjustedPosition × rangeWidth)
```

**value=1.0:**
- fx = log₁₀(1.0) = 0.0
- baseNormalizedPosition = (0.0 - 0.0) / 0.5 = **0.0**
- adjustedPosition = 0.0 + 0.0 = **0.0**
- physicalPosition = 0.0 + (0.0 × 0.5) = **0.0** ✅
- absolutePosition = 0.0 × 800 = **0.0pt** ✅

**value=3.162 (√10):**
- fx = log₁₀(3.162) ≈ 0.5
- baseNormalizedPosition = (0.5 - 0.0) / 0.5 = **1.0**
- adjustedPosition = 1.0 + 0.0 = **1.0**
- physicalPosition = 0.0 + (1.0 × 0.5) = **0.5** ✅
- absolutePosition = 0.5 × 800 = **400pt** ✅

**Left segment: CORRECT!** Values span from 0.0 to 0.5 normalized (0pt to 400pt).

---

### RIGHT SEGMENT Calculations

**Algorithm (same):**
```swift
fL = log₁₀(3.162) ≈ 0.5
fR = log₁₀(10.0) = 1.0
denominator = 1.0 - 0.5 = 0.5
physicalRange = 0.5...1.0
rangeWidth = 0.5
formulaOffset = -1.0
```

**value=3.162 (√10):**
- fx = log₁₀(3.162) ≈ 0.5
- baseNormalizedPosition = (0.5 - 0.5) / 0.5 = **0.0**
- adjustedPosition = 0.0 + (-1.0) = **-1.0** ❌
- physicalPosition = 0.5 + ((-1.0) × 0.5) = 0.5 - 0.5 = **0.0** ❌
- absolutePosition = 0.0 × 800 = **0.0pt** ❌
- **EXPECTED**: physicalPosition=0.5, absolutePosition=400pt

**value=10.0:**
- fx = log₁₀(10.0) = 1.0
- baseNormalizedPosition = (1.0 - 0.5) / 0.5 = **1.0**
- adjustedPosition = 1.0 + (-1.0) = **0.0** ❌
- physicalPosition = 0.5 + (0.0 × 0.5) = **0.5** ❌
- absolutePosition = 0.5 × 800 = **400pt** ❌
- **EXPECTED**: physicalPosition=1.0, absolutePosition=800pt

**value=6.0 (mid in log space ≈ 0.778):**
- fx = log₁₀(6.0) ≈ 0.778
- baseNormalizedPosition = (0.778 - 0.5) / 0.5 = **0.556**
- adjustedPosition = 0.556 + (-1.0) = **-0.444** ❌
- physicalPosition = 0.5 + ((-0.444) × 0.5) = 0.5 - 0.222 = **0.278** ❌
- absolutePosition = 0.278 × 800 = **222pt** ❌
- **EXPECTED**: physicalPosition ≈ 0.778, absolutePosition ≈ 622pt

**Right segment: INCORRECT!** The formula offset of -1.0 shifts ALL positions into the wrong region.

---

## Root Cause Identified

**The Problem**: `SplitSegment.formulaOffset` is being applied to the per-segment normalized position (0...1), causing it to shift negatively.

**For the right segment:**
- The formula offset `-1.0` was intended to shift the **formula output** before normalization (PostScript `{1 sub}`)
- But it's being applied **after** normalization, shifting the 0...1 range to -1...0
- Then multiplied by `rangeWidth=0.5` gives -0.5...0.0
- Then added to `range.lowerBound=0.5` gives 0.0...0.5 (WRONG - overwrites left segment!)

---

## PostScript vs Current Implementation

### PostScript Model (from `postscript-engine-for-sliderules.ps`)
```postscript
/Sh1scale: {sinh 10 mul log}         % Outputs 0.0 to ~0.95
/Sh2scale: {sinh 10 mul log 1 sub}   % Outputs -0.06 to 0.55 (offset applied to formula output)
```

The `{1 sub}` subtracts 1 from the **raw formula output**, not the normalized position!

### Current Implementation (incorrect for simple splits)
```swift
//  ScaleCalculator.swift lines 113-134
let baseNormalizedPosition = (fx - fL) / denominator  // Normalizes 0...1 within segment
let adjustedPosition = baseNormalizedPosition + segment.formulaOffset  // Applied after normalization!
```

This is wrong for simple 50/50 splits where each segment covers exactly half the domain.

---

## Two Types of Split Scales

### Type A: Simple Domain Split (like C scale 1→√10 | √10→10)
- Each segment has its own value range
- Segments are **consecutive** (left ends where right begins)
- **No formula offset needed!** Just physical range mapping.
- Each segment independently normalizes its range to 0...1
- Physical range mapping does the rest

**Correct configuration:**
```swift
Left:  .withSplitSegment(.left(formulaOffset: 0.0))
Right: .withSplitSegment(.right(formulaOffset: 0.0))  // NOT -1.0!
```

### Type B: Overlapping Formula Split (like Sh1/Sh2)
- Formula itself has an offset (e.g., `sinh(x-1)` for Sh2)
- Segments have **overlapping** value ranges (Sh1: 0.1→0.9, Sh2: 0.88→3.0)
- Formula offset is already in the ScaleFunction, not in Split Segment!
- `SplitSegment.formulaOffset` should still be 0.0

**Correct configuration:**
```swift
Sh1: .withFunction(HyperbolicSineFunction(offset: 0.0))  // Function offset
     .withSplitSegment(.left(formulaOffset: 0.0))        // Split offset = 0
     
Sh2: .withFunction(HyperbolicSineFunction(offset: 1.0))  // Function offset (formula shift)
     .withSplitSegment(.right(formulaOffset: 0.0))       // Split offset = 0
```

---

## The Fix

**For ALL split segments in SplitScalesPreview.swift**: 
Use `formulaOffset: 0.0` for BOTH left and right segments.

The physical range mapping (0.0...0.5 for left, 0.5...1.0 for right) handles the positioning correctly when formulaOffset is 0.0.

**Changed lines:**
- Line 73: `.withSplitSegment(.right(formulaOffset: -1.0))` → `formulaOffset: 0.0`
- Line 178: `.withSplitSegment(.right(formulaOffset: -1.0))` → `formulaOffset: 0.0`

Any formula-level offsetting should be done in the ScaleFunction itself (like Sh2's `offset: 1.0`).

---

## Expected Results After Fix

### Test Case 1 (C Scale 50/50):
**Left segment:**
- value=1.000 → norm=0.0000, abs=0pt (left edge) ✅
- value=3.162 → norm=0.5000, abs=400pt (midpoint) ✅

**Right segment:**
- value=3.162 → norm=0.5000, abs=400pt (midpoint) ✅
- value=10.000 → norm=1.0000, abs=800pt (right edge) ✅

### Test Case 3 (Sh1/Sh2):
Both segments should fill their full 50% regions with proper overlap at 0.88-0.90.

---

## Design Intent of SplitSegment.formulaOffset

After this analysis, it appears `SplitSegment.formulaOffset` may have been designed for a **different use case** that doesn't match our current split scale patterns. The correct approach for split scales is:

1. **Formula offset**: Use the `offset` parameter in the ScaleFunction itself (e.g., `HyperbolicSineFunction(offset: 1.0)`)
2. **Physical split**: Use `SplitSegment` with `formulaOffset: 0.0` to define which half to render in

The `SplitSegment.formulaOffset` parameter may need to be **deprecated** or its usage clarified/renamed to avoid this confusion.
