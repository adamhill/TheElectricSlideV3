# Implemented Scales Reference

Complete reference for all slide rule scales implemented in SlideRuleCoreV3.

## Table of Contents

- [Standard Scales](#standard-scales)
- [Power Scales](#power-scales)
- [Folded Scales](#folded-scales)
- [Inverted Scales](#inverted-scales)
- [Extended Range Scales](#extended-range-scales)
- [Trigonometric Scales](#trigonometric-scales)
- [Log-Log Scales (Positive)](#log-log-scales-positive)
- [Log-Log Scales (Negative/Reciprocal)](#log-log-scales-negativereciprocal)
- [Specialized Log-Log Variants](#specialized-log-log-variants)
- [Square Root Scales](#square-root-scales)
- [Cube Root Scales](#cube-root-scales)
- [Hyperbolic Scales](#hyperbolic-scales)
- [Pythagorean Scales](#pythagorean-scales)
- [Electrical Engineering Scales](#electrical-engineering-scales)
- [Pickett N-16 ES Electronic Scales](#pickett-n-16-es-electronic-scales)
- [Special Purpose Scales](#special-purpose-scales)

---

## Standard Scales

### C Scale
**Aliases:** `C`
**Range:** 1 to 10
**Formula:** `x`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Three subsections with varying tick densities (0.01, 0.05, 0.02 quaternary intervals)
**Use Case:** Standard logarithmic multiplication/division scale, fundamental to all slide rule operations.
**File:** [`StandardScales.swift:79`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:79)

### D Scale
**Aliases:** `D`
**Range:** 1 to 10
**Formula:** `x`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Identical to C scale (0.01, 0.05, 0.02 quaternary intervals)
**Use Case:** Companion to C scale with opposite tick direction, used for multiplication/division operations.
**File:** [`StandardScales.swift:122`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:122)

---

## Power Scales

### A Scale
**Aliases:** `A`
**Range:** 1 to 100
**Formula:** `x²`
**Transform Function:** [`HalfLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:61) - `log₁₀(x)/2`
**Subsections:** Two subsections covering 1-10 and 10-100 (0.05, 0.5 quaternary intervals)
**Use Case:** Square scale - read x² on D when x is on A. Compresses two decades into one C/D length.
**File:** [`StandardScales.swift:459`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:459)

### B Scale
**Aliases:** `B`
**Range:** 1 to 100
**Formula:** `x²`
**Transform Function:** [`HalfLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:61) - `log₁₀(x)/2`
**Subsections:** Identical to A scale with inverted tick direction
**Use Case:** Duplicate of A scale with opposite tick direction for square calculations.
**File:** [`StandardScales.swift:955`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:955)

### K Scale
**Aliases:** `K`
**Range:** 1 to 1000
**Formula:** `x³`
**Transform Function:** [`ThirdLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:79) - `log₁₀(x)/3`
**Subsections:** Ten subsections with progressive coarsening (0.05 to 50 quaternary intervals)
**Use Case:** Cube scale - read x³ on D when x is on K. Compresses three decades into one C/D length.
**File:** [`StandardScales.swift:497`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:497)

---

## Folded Scales

### CF Scale
**Aliases:** `CF`
**Range:** π to 10π (3.14159... to 31.4159...)
**Formula:** `πx`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Five subsections from π to 20 (0.01 to 0.1 quaternary intervals)
**Use Case:** C scale folded at π to prevent running off the scale edge during calculations.
**File:** [`StandardScales.swift:237`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:237)

### DF Scale
**Aliases:** `DF`
**Range:** π to 10π
**Formula:** `πx`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Identical to CF scale
**Use Case:** D scale folded at π, companion to CF with opposite tick direction.
**File:** [`StandardScales.swift:288`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:288)

### DFm Scale
**Aliases:** `DFM`, `DF/M`, `DFm`
**Range:** log₁₀(e) to 10×log₁₀(e) (~0.434 to 4.34)
**Formula:** `Mx` (where M = log₁₀(e))
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Four subsections (0.005 to 0.1 quaternary intervals)
**Use Case:** Converts natural logarithms to base-10 logarithms. When cursor is on LL scale, D shows ln(x) and DFm shows log₁₀(x).
**File:** [`StandardScales.swift:335`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:335)

### DFMPSS Scale (PostScript Variant)
**Aliases:** `DFMPSS`
**Range:** 10M to 100M (~4.34 to 43.4)
**Formula:** `log₁₀x`
**Transform Function:** [`DFmPostScriptFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/DFmScalesExtension.swift:136) - `log₁₀(x) - log₁₀(10M)`
**Subsections:** Five subsections matching PostScript engine definition
**Use Case:** PostScript engine compatible variant of DFm scale with extended range.
**File:** [`DFmScalesExtension.swift:175`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/DFmScalesExtension.swift:175)

---

## Inverted Scales

### CI Scale
**Aliases:** `CI`
**Range:** 10 to 1 (reversed)
**Formula:** `1/x`
**Transform Function:** [`ReciprocalLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:41) - `-log₁₀(x)`
**Subsections:** Three subsections mirroring C scale in reverse (0.02, 0.05, 0.01 quaternary intervals)
**Use Case:** Inverted C scale for reciprocal operations and division without moving the slide.
**File:** [`StandardScales.swift:165`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:165)

### DI Scale
**Aliases:** `DI`
**Range:** 10 to 1 (reversed)
**Formula:** `1/x`
**Transform Function:** [`ReciprocalLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:41) - `-log₁₀(x)`
**Subsections:** Identical to CI scale with opposite tick direction
**Use Case:** Inverted D scale, companion to CI for reciprocal calculations.
**File:** [`StandardScales.swift:212`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:212)

### CIF Scale
**Aliases:** `CIF`
**Range:** 10π to π (reversed)
**Formula:** `1/πx`
**Transform Function:** [`ReciprocalLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:41) - `-log₁₀(x)`
**Subsections:** Six subsections in reverse order from CF scale
**Use Case:** Inverted CF scale for folded reciprocal operations.
**File:** [`StandardScales.swift:383`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:383)

### DIF Scale
**Aliases:** `DIF`
**Range:** 10π to π (reversed)
**Formula:** `1/πx`
**Transform Function:** [`ReciprocalLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:41) - `-log₁₀(x)`
**Subsections:** Identical to CIF scale with opposite tick direction
**Use Case:** Inverted DF scale, companion to CIF for folded reciprocal division.
**File:** [`StandardScales.swift:436`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:436)

### AI Scale
**Aliases:** `AI`
**Range:** 100 to 1 (reversed)
**Formula:** `100/x²`
**Transform Function:** [`AIScaleFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:157) - `log₁₀(100/x)/2`
**Subsections:** Same as A scale, red labels
**Use Case:** Inverse of A scale for reciprocal square operations.
**File:** [`StandardScales.swift:980`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:980)

### BI Scale
**Aliases:** `BI`
**Range:** 100 to 1 (reversed)
**Formula:** `100/x²`
**Transform Function:** [`AIScaleFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:157) - `log₁₀(100/x)/2`
**Subsections:** Same as AI with opposite tick direction, red labels
**Use Case:** Inverse of B scale, companion to AI with downward ticks.
**File:** [`StandardScales.swift:1008`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1008)

---

## Extended Range Scales

### C10-100 Scale
**Aliases:** `C10-100`, `C10.100`
**Range:** 1 to 10 (displayed as 10 to 100)
**Formula:** `10x`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Three subsections matching C scale pattern
**Use Case:** C scale with ×10 labels for extended range engineering calculations.
**File:** [`StandardScales.swift:1149`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1149)

### C100-1000 Scale
**Aliases:** `C100-1000`, `C100.1000`
**Range:** 1 to 10 (displayed as 100 to 1000)
**Formula:** `100x`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Three subsections matching C scale pattern
**Use Case:** C scale with ×100 labels for extended range work.
**File:** [`StandardScales.swift:1190`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1190)

### D10-100 Scale
**Aliases:** `D10-100`, `D10.100`
**Range:** 1 to 10 (displayed as 10 to 100)
**Formula:** `10x`
**Transform Function:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(x)`
**Subsections:** Three subsections matching D scale pattern
**Use Case:** D scale companion to C10-100 with opposite tick direction.
**File:** [`StandardScales.swift:1407`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1407)

---

## Trigonometric Scales

### S Scale
**Aliases:** `S`
**Range:** 5.7° to 90°
**Formula:** `∡sin`
**Transform Function:** [`SineFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(sin(x)×10)`
**Subsections:** Seven subsections with dual labeling (0.05° to 5° intervals)
**Use Case:** Sine scale for angular calculations in navigation, surveying, and trigonometry.
**File:** [`StandardScales.swift:690`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:690)

### T Scale
**Aliases:** `T`
**Range:** 5.7° to 45°
**Formula:** `∡tan`
**Transform Function:** [`TangentFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(tan(x)×10)`
**Subsections:** Two subsections (0.05° to 0.1° intervals)
**Use Case:** Tangent scale for angle calculations used with C/D scales.
**File:** [`StandardScales.swift:765`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:765)

### T1 Scale
**Aliases:** `T1`
**Range:** 5.7° to 45°
**Formula:** `∡tan`
**Transform Function:** [`TangentFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(tan(x)×10)`
**Subsections:** Two subsections for double-precision tangent
**Use Case:** First half of split tangent scale providing extended precision for small to medium angles (Pickett N3 variant).
**File:** [`StandardScales.swift:798`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:798)

### T2 Scale
**Aliases:** `T2`
**Range:** 45° to 84.3°
**Formula:** `∡tan`
**Transform Function:** [`TangentFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(tan(x)×10)`
**Subsections:** Three subsections covering steep tangent range
**Use Case:** Second half of split tangent scale extending range to larger angles (Pickett N3 variant).
**File:** [`StandardScales.swift:831`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:831)

### ST Scale
**Aliases:** `ST`
**Range:** 0.57° to 5.7°
**Formula:** `∡tan ≈ ∡`
**Transform Function:** [`SmallTanFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:141) - `log₁₀(x×π/180×100)`
**Subsections:** Two subsections for small angle approximation (0.005° to 0.01° intervals)
**Use Case:** Small angle tangent where tan(x) ≈ x in radians, essential for artillery and navigation.
**File:** [`StandardScales.swift:870`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:870)

### KE-S Scale
**Aliases:** `KE-S`, `KES`
**Range:** 5.5° to 90°
**Formula:** `sin x`
**Transform Function:** [`SineFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(sin(x)×10)`
**Subsections:** Three subsections (0.05° to 0.5° intervals)
**Use Case:** Keuffel & Esser sine variant with earlier starting point for extended coverage.
**File:** [`StandardScales.swift:1033`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1033)

### KE-T Scale
**Aliases:** `KE-T`, `KET`
**Range:** 5.5° to 45°
**Formula:** `tan x`
**Transform Function:** [`TangentFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(tan(x)×10)`
**Subsections:** Two subsections (0.05° to 0.1° intervals)
**Use Case:** K&E tangent variant with earlier starting point, complements KE-S.
**File:** [`StandardScales.swift:1073`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1073)

### SRT Scale (KE-ST)
**Aliases:** `SRT`, `KE-ST`, `KEST`
**Range:** 0.55° to 6°
**Formula:** `tan x ≈ x`
**Transform Function:** [`SmallTanFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:141) - `log₁₀(x×π/180×100)`
**Subsections:** Three subsections (0.005° to 0.05° intervals)
**Use Case:** K&E small radian/tangent scale with extended range for artillery and ballistics.
**File:** [`StandardScales.swift:1106`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1106)

### S/C Scale (CR3S)
**Aliases:** `CR3S`, `S/C`, `SC`
**Range:** 6° to 90°
**Formula:** `sin x / cos x`
**Transform Function:** [`SineFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `log₁₀(sin(x)×10)`
**Subsections:** Five subsections with both sine and cosine labeling
**Use Case:** Combined sine/cosine scale - shows both sin(x) ascending and cos(90-x) descending.
**File:** [`StandardScales.swift:1343`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1343)

---

## Log-Log Scales (Positive)

### LL0 Scale
**Aliases:** `LL0`  
**Range:** 1.001 to 1.0101 (e^0.001 to e^0.01)  
**Formula:** `e^(0.001x)`  
**Transform Function:** Custom - `log₁₀(ln(x)×1000)`  
**Subsections:** Two subsections with ultra-fine intervals (0.00005 quaternary)  
**Use Case:** Ultra-precision scale for values extremely close to 1, used for micro-corrections and high-precision calculations.  
**File:** [`LogLogScalesExtension.swift:1463`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1463)

### LL1 Scale
**Aliases:** `LL1`
**Range:** 1.0101 to 1.105 (e^0.01 to e^0.1)
**Formula:** `e^(0.01x)`
**Transform Function:** Custom - `log₁₀(ln(x)×100)`
**Subsections:** Two subsections (0.0005 quaternary interval)
**Use Case:** Small-range log-log for values close to 1, essential for daily compound interest and small powers.
**File:** [`LogLogScalesExtension.swift:1407`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1407)

### LL2 Scale
**Aliases:** `LL2`
**Range:** 1.105 to 2.72 (e^0.1 to e^1)
**Formula:** `e^(0.1x)`
**Transform Function:** Custom - `log₁₀(ln(x)×10)`
**Subsections:** Three subsections (0.005 quaternary interval)
**Use Case:** Medium-range log-log for moderate powers and fractional exponents, population models.
**File:** [`LogLogScalesExtension.swift:1346`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1346)

### LL3 Scale
**Aliases:** `LL3`
**Range:** 2.74 to 21,000 (e^1 to e^10)
**Formula:** `e^x`
**Transform Function:** Custom - `log₁₀(ln(x))`
**Subsections:** 17 subsections covering full range (0.02 to 2000 quaternary intervals)
**Use Case:** Base log-log scale for large exponentials, arbitrary powers, wide-range decay, extreme growth calculations.
**File:** [`LogLogScalesExtension.swift:1047`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1047)

---

## Log-Log Scales (Negative/Reciprocal)

### LL00 Scale
**Aliases:** `LL00`  
**Range:** 0.990 to 0.999 (e^-0.01 to e^-0.001)  
**Formula:** `e^(-0.001x)`  
**Transform Function:** Custom - `log₁₀(-ln(x)×1000)`  
**Subsections:** Three subsections with ultra-fine intervals (0.00002 to 0.00005), red labels  
**Use Case:** Ultra-precision reciprocal for negative powers, high-Q resonators, precision optics.  
**File:** [`LogLogScalesExtension.swift:1727`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1727)

### LL01 Scale
**Aliases:** `LL01`  
**Range:** 0.905 to 0.990 (e^-0.1 to e^-0.01)  
**Formula:** `e^(-0.01x)`  
**Transform Function:** Custom - `log₁₀(-ln(x)×100)`  
**Subsections:** Three subsections (0.0001 to 0.0005 quaternary), red labels  
**Use Case:** Small reciprocal log-log for small decay and attenuation, quality factors.  
**File:** [`LogLogScalesExtension.swift:1672`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1672)

### LL02 Scale
**Aliases:** `LL02`  
**Range:** 0.368 to 0.905 (e^-1 to e^-0.1)  
**Formula:** `e^(-0.1x)`  
**Transform Function:** Custom - `log₁₀(-ln(x)×10)`  
**Subsections:** Three subsections (0.001 to 0.005 quaternary), red labels  
**Use Case:** Medium reciprocal log-log for moderate decay, damping, attenuation calculations.  
**File:** [`LogLogScalesExtension.swift:1604`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1604)

### LL03 Scale
**Aliases:** `LL03`  
**Range:** 0.00005 to 0.368 (e^-10 to e^-1)  
**Formula:** `e^(-x)`  
**Transform Function:** Custom - `log₁₀(-ln(x))`  
**Subsections:** Five subsections (0.000005 to 0.005 quaternary), red labels  
**Use Case:** Base reciprocal log-log for negative powers, decay processes, inverse relationships.  
**File:** [`LogLogScalesExtension.swift:1526`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1526)

---

## Specialized Log-Log Variants

### LL2B Scale
**Aliases:** `LL2B`  
**Range:** 1.106 to 20,000 (e^0.1 to e^9.9)  
**Formula:** `e^(0.1x/2)`  
**Transform Function:** Custom - `log₁₀(ln(x)×10)/2`  
**Subsections:** 26 subsections (!), most detailed LL scale (0.002 to 2000 quaternary)  
**Use Case:** Extended LL2/LL3 range referenced to A/B scales for combined square-exponential operations.  
**File:** [`LogLogScalesExtension.swift:456`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:456)

### LL02B Scale
**Aliases:** `LL02B`  
**Range:** 0.00005 to 0.904 (e^-10 to e^-0.1)  
**Formula:** `e^(-0.1x/2)`  
**Transform Function:** Custom - `log₁₀(-ln(x)×10)/2`  
**Subsections:** Six subsections (0.00001 to 0.002 quaternary), red labels  
**Use Case:** Extended negative LL02/LL03 referenced to A/B scales for combined operations.  
**File:** [`LogLogScalesExtension.swift:1785`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1785)

### LL00B Scale (Hemmi 266)
**Aliases:** `LL00B`  
**Range:** 0.900 to 0.999 (e^-0.105 to e^-0.001)  
**Formula:** `e^(-0.01x/2)`  
**Transform Function:** Custom - `log₁₀(-ln(x)×100)/2 + 0.5`  
**Subsections:** Six subsections with A/B offset (0.00002 to 0.001 quaternary), red labels  
**Use Case:** Hemmi 266 variant with A/B scale reference for compact designs.  
**File:** [`LogLogScalesExtension.swift:1847`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1847)

### H266LL01 Scale
**Aliases:** `H266LL01`  
**Range:** 0.90 to 0.99 (truncated from LL00B)  
**Formula:** `e^(-0.01x/2)`  
**Transform Function:** Same as LL00B - `log₁₀(-ln(x)×100)/2 + 0.5`  
**Subsections:** Three subsections (0.0002 to 0.001 quaternary), red labels  
**Use Case:** Hemmi 266 space-saving variant, truncated LL00B range.  
**File:** [`LogLogScalesExtension.swift:1908`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1908)

### H266LL03 Scale
**Aliases:** `H266LL03`  
**Range:** 1 to 50,000 (represents 10^-9 to 5×10^-5)  
**Formula:** `e^(-0.1x×10^-9)`  
**Transform Function:** Custom - `log₁₀(ln(x×10^-9)×-0.1)/2`  
**Subsections:** Nine subsections for nano-scale values  
**Use Case:** Specialized ultra-small negative power scale for nanotechnology and quantum effects.  
**File:** [`LogLogScalesExtension.swift:1977`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/LogLogScalesExtension.swift:1977)

---

## Square Root Scales

### R1 Scale (Sq1)
**Aliases:** `R1`, `SQ1`  
**Range:** 1.0 to 3.2 (√1 to √10)  
**Formula:** `√x`  
**Transform Function:** [`SquareRootFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:222) - `log₁₀(x)×2`
**Subsections:** Two subsections (0.005 to 0.01 quinary/quaternary intervals)
**Use Case:** First square root scale covering √1 to √10 with 2× log expansion for precision.
**File:** [`StandardScales.swift:1450`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1450)

### R2 Scale (Sq2)
**Aliases:** `R2`, `SQ2`
**Range:** 3.1 to 10.0 (√10 to √100)
**Formula:** `√(10x)`
**Transform Function:** [`SquareRootOffsetFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:241) - `(log₁₀(x)-1)×2`
**Subsections:** Two subsections (0.02 quaternary interval)
**Use Case:** Second square root scale continuing from R1, covers √10 to √100.
**File:** [`StandardScales.swift:1485`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1485)

---

## Cube Root Scales

### Q1 Scale
**Aliases:** `Q1`  
**Range:** 1.0 to 2.16 (∛1 to ∛10)  
**Formula:** `∛x`  
**Transform Function:** [`CubeRootFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:262) - `log₁₀(x)×3`
**Subsections:** Two subsections (0.005 to 0.01 quinary/quaternary intervals)
**Use Case:** First cube root scale covering ∛1 to ∛10 with 3× log expansion.
**File:** [`StandardScales.swift:1520`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1520)

### Q2 Scale
**Aliases:** `Q2`
**Range:** 2.15 to 4.7 (∛10 to ∛100)
**Formula:** `∛(10x)`
**Transform Function:** [`CubeRootOffset1Function()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:276) - `(log₁₀(x)-1)×3`
**Subsections:** Two subsections (0.01 to 0.02 quaternary intervals)
**Use Case:** Second cube root scale continuing from Q1, covers ∛10 to ∛100.
**File:** [`StandardScales.swift:1555`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1555)

### Q3 Scale
**Aliases:** `Q3`
**Range:** 4.6 to 10.0 (∛100 to ∛1000)
**Formula:** `∛(100x)`
**Transform Function:** [`CubeRootOffset2Function()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:300) - `(log₁₀(x)-2)×3`
**Subsections:** One subsection (0.02 quaternary interval)
**Use Case:** Third cube root scale completing the range, covers ∛100 to ∛1000.
**File:** [`StandardScales.swift:1589`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1589)

---

## Hyperbolic Scales

### Ch Scale
**Aliases:** `CH`  
**Range:** 0 to 3  
**Formula:** `cosh x`  
**Transform Function:** [`HyperbolicCosineFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:35) - `log₁₀(cosh(x))`
**Subsections:** Six subsections (0.01 to 0.1 intervals)
**Use Case:** Hyperbolic cosine for catenary curves, transmission lines, hanging cable calculations.
**File:** [`HyperbolicScalesExtension.swift:60`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:60)

### Sh Scale
**Aliases:** `SH`
**Range:** 0.1 to 3
**Formula:** `sinh x`
**Transform Function:** [`HyperbolicSineFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:75) - `log₁₀(sinh(x)×10)`
**Subsections:** Four subsections (0.001 to 0.005 quaternary intervals)
**Use Case:** Hyperbolic sine for catenary calculations, special relativity, suspension bridges.
**File:** [`HyperbolicScalesExtension.swift:252`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:252)

### Sh1 Scale
**Aliases:** `SH1`
**Range:** 0.1 to 0.90
**Formula:** `sinh x`
**Transform Function:** [`HyperbolicSineFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:75) - `log₁₀(sinh(x)×10)`
**Subsections:** Five subsections for extended precision (0.001 to 0.005 quaternary)
**Use Case:** First part of split hyperbolic sine scale for small-argument high-precision calculations.
**File:** [`HyperbolicScalesExtension.swift:316`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:316)

### Sh2 Scale
**Aliases:** `SH2`
**Range:** 0.88 to 3.0
**Formula:** `sinh(x-1)`
**Transform Function:** [`HyperbolicSineFunction(multiplier: 10.0, offset: 1.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:75) - `log₁₀(|sinh(x-1)|×10)`
**Subsections:** Four subsections with offset (0.005 to 0.5 quaternary)
**Use Case:** Second part of split sinh scale with offset, extends range to larger arguments.
**File:** [`HyperbolicScalesExtension.swift:379`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:379)

### Th Scale
**Aliases:** `TH`
**Range:** 0.1 to 3
**Formula:** ` tanh x`
**Transform Function:** [`HyperbolicTangentFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:53) - `log₁₀(tanh(x)×10)`
**Subsections:** Seven subsections (0.001 to 0.5 quaternary intervals)
**Use Case:** Hyperbolic tangent for relativity velocity addition, signal processing, neural networks.
**File:** [`HyperbolicScalesExtension.swift:151`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:151)

---

## Pythagorean Scales

### H1 Scale
**Aliases:** `H1`  
**Range:** 1.005 to 1.415  
**Formula:** `√(x²-1)`  
**Transform Function:** [`PythagoreanHFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:103) - `log₁₀(√(x²-1)×10)`
**Subsections:** Six subsections (0.0001 to 0.005 quaternary intervals)
**Use Case:** Pythagorean scale for small values, precision surveying, near-unity calculations.
**File:** [`HyperbolicScalesExtension.swift:458`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:458)

### H2 Scale
**Aliases:** `H2`
**Range:** 1.42 to 10
**Formula:** `√(x²-1)`
**Transform Function:** [`PythagoreanHFunction(multiplier: 1.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:103) - `log₁₀(√(x²-1))`
**Subsections:** Three subsections (0.01 to 0.05 quaternary intervals)
**Use Case:** Pythagorean scale for larger values, general geometry, right triangle calculations.
**File:** [`HyperbolicScalesExtension.swift:554`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:554)

### P Scale
**Aliases:** `P`
**Range:** 0 to 0.995
**Formula:** `√(1-x²)`
**Transform Function:** [`PythagoreanPFunction(multiplier: 10.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:126) - `log₁₀(√(1-x²)×10)`
**Subsections:** Nine subsections (0.0001 to 0.1 intervals), red labels
**Use Case:** Pythagorean complement for unit circle calculations, trigonometric complements, probability.
**File:** [`HyperbolicScalesExtension.swift:625`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:625)

### PA Scale
**Aliases:** `PA`
**Range:** 9 to 91
**Formula:** `10-x-7.6log₁₀(x)/log₁₀(1.72)+log₁₀(7.6)`
**Transform Function:** [`PercentageAngularFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:152) - Complex logarithmic percentage transformation
**Subsections:** One subsection (0.5 quaternary interval)
**Use Case:** Percentage/angular calculations for statistics, quality control, confidence intervals.
**File:** [`HyperbolicScalesExtension.swift:905`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:905)

---

## Electrical Engineering Scales

### XL Scale (Inductive Reactance)
**Aliases:** `EEXL`, `XL`  
**Range:** 1 to 100 (12 logarithmic cycles: 1mΩ to 1MΩ)  
**Formula:** `ωL`  
**Transform Function:** [`InductiveReactanceFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:11) - `log₁₀(0.5π×value)/12`
**Subsections:** Six subsections (0.1 to 0.5 quaternary intervals), green labels
**Use Case:** Inductive reactance calculations for AC circuits, filter design, impedance matching.
**File:** [`ElectricalEngineeringScalesExtension.swift:52`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:52)

### Xc Scale (Capacitive Reactance)
**Aliases:** `EEXC`, `XC`
**Range:** 100 to 1 (inverted, 12 cycles: 100MΩ to 1mΩ)
**Formula:** `1/(ωC)`
**Transform Function:** [`CapacitiveReactanceFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:35) - `(log₁₀(5π/value)+11)/12`
**Subsections:** Six subsections (0.1 to 0.5 quaternary intervals), red labels
**Use Case:** Capacitive reactance for filter design, coupling networks, AC circuit analysis.
**File:** [`ElectricalEngineeringScalesExtension.swift:109`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:109)

### F Scale (Frequency)
**Aliases:** `EEF`, `F` (Note: conflicts with Pickett F)
**Range:** 1 to 100 (12 cycles: 0.001Hz to 1GHz)
**Formula:** `log₁₀ f`
**Transform Function:** [`FrequencyFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:60) - `log₁₀(value)/12`
**Subsections:** Six subsections (0.1 to 0.5 quaternary intervals)
**Use Case:** Frequency selection for filter design, resonance calculations, RF design.
**File:** [`ElectricalEngineeringScalesExtension.swift:168`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:168)

### Fo Scale (Frequency/Wavelength)
**Aliases:** `EEFO`, `FO`
**Range:** 100 to 1 (inverted, 6 cycles)
**Formula:** `c/f`
**Transform Function:** [`FrequencyWavelengthFunction(cycles: 6)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:216) - `1 - log₁₀(value)/6`
**Subsections:** Four subsections (0.05 to 0.2 quaternary intervals)
**Use Case:** Shows wavelength corresponding to frequency for antenna design and RF propagation.
**File:** [`ElectricalEngineeringScalesExtension.swift:231`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:231)

### L Scale (Inductance)
**Aliases:** `EEL`
**Range:** 1 to 100 (12 cycles: 0.001µH to 100H)
**Formula:** `log₁₀ L`
**Transform Function:** [`InductanceFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:81) - `log₁₀(value)/12`
**Subsections:** Six subsections (0.1 to 0.5 quaternary intervals)
**Use Case:** Inductor selection for filter design, resonance calculations, transformer design.
**File:** [`ElectricalEngineeringScalesExtension.swift:288`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:288)

### Li Scale (Inverted Inductance)
**Aliases:** `EELI`, `LI`
**Range:** 100 to 1 (inverted, 12 cycles)
**Formula:** `log₁₀(1/L)`
**Transform Function:** [`InductanceFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:81) - `log₁₀(value)/12`
**Subsections:** Six subsections with TL/XL constants (0.1 to 0.5 quaternary intervals)
**Use Case:** Reciprocal inductance for Q-factor calculations and time constant analysis.
**File:** [`ElectricalEngineeringScalesExtension.swift:346`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:346)

### Cz Scale (Capacitance for Impedance)
**Aliases:** `EECZ`, `CZ`
**Range:** 1 to 100 (12 cycles: 1pF to 1000µF)
**Formula:** `log₁₀ C`
**Transform Function:** [`CapacitanceImpedanceFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:168) - `log₁₀(value)/12`
**Subsections:** Six subsections with TC/fm constant (0.1 to 0.5 quaternary intervals)
**Use Case:** Capacitor selection for impedance matching, filter design, energy storage.
**File:** [`ElectricalEngineeringScalesExtension.swift:407`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:407)

### Cf Scale (Capacitance/Frequency Product)
**Aliases:** `EECF`
**Range:** 100 to 1 (inverted, 11 cycles)
**Formula:** `log₁₀(C·f)`
**Transform Function:** [`CapacitanceFrequencyFunction(cycles: 11)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:189) - `1 - log₁₀(3.948×value)/12`
**Subsections:** Six subsections with XC constant (0.1 to 0.5 quaternary intervals)
**Use Case:** RC time constants, phase shift networks, oscillator design, signal delay.
**File:** [`ElectricalEngineeringScalesExtension.swift:467`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:467)

### Z Scale (Impedance)
**Aliases:** `EEZ`, `Z`
**Range:** 1 to 100 (6 cycles: 1mΩ to 100MΩ)
**Formula:** `log₁₀ Z`
**Transform Function:** [`ImpedanceFunction(cycles: 6)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:147) - `log₁₀(value)/6`
**Subsections:** Four subsections (0.05 to 0.2 quaternary intervals)
**Use Case:** Impedance matching for transmission lines, antenna systems, audio systems.
**File:** [`ElectricalEngineeringScalesExtension.swift:526`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:526)

### r1 Scale (Reflection Coefficient/VSWR)
**Aliases:** `EER1`, `R1EE`
**Range:** 0.5 to 50 (VSWR)
**Formula:** `VSWR`
**Transform Function:** [`ReflectionCoefficientFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:103) - `(0.5/value)×0.472`
**Subsections:** Ten subsections with ∞ constant (0.005 to 50 quaternary), red labels
**Use Case:** VSWR and reflection coefficient for transmission line analysis, antenna matching.
**File:** [`ElectricalEngineeringScalesExtension.swift:580`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:580)

### r2 Scale (Inverted Reflection Coefficient)
**Aliases:** `EER2`, `R2EE`
**Range:** 0.5 to 50 (VSWR, inverted)
**Formula:** `1/VSWR`
**Transform Function:** [`ReflectionCoefficientFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:103) - `(0.5/value)×0.472`
**Subsections:** Ten subsections with ∞ constant (0.005 to 50 quaternary)
**Use Case:** Inverted r1 for bidirectional VSWR measurements and network analysis.
**File:** [`ElectricalEngineeringScalesExtension.swift:649`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:649)

### P Scale (Power Ratio)
**Aliases:** `EEP`
**Range:** 0 to 14 (power ratios)
**Formula:** `10log₁₀(P₂/P₁)`
**Transform Function:** [`PowerRatioFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:125) - `(value²/196)×0.477 + 0.523`
**Subsections:** Five subsections (0.05 to 0.5 quaternary intervals), green labels
**Use Case:** Decibel calculations for amplifier gain, signal attenuation, link budget analysis.
**File:** [`ElectricalEngineeringScalesExtension.swift:721`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:721)

### Q Scale (Inverted Power Ratio)
**Aliases:** `EEQ`
**Range:** 0 to 14 (power ratios, inverted)
**Formula:** `10log₁₀(P₁/P₂)`
**Transform Function:** [`PowerRatioFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:125) - `(value²/196)×0.477 + 0.523`
**Subsections:** Five subsections (0.05 to 0.5 quaternary intervals)
**Use Case:** Reciprocal power ratios for loss measurements, filter insertion loss.
**File:** [`ElectricalEngineeringScalesExtension.swift:778`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScalesExtension.swift:778)

---

## Pickett N-16 ES Electronic Scales

### Lr Scale (Inductance Reciprocal)
**Aliases:** `LR`  
**Range:** 0.001 to 100.0 (0.001µH to 100H)  
**Formula:** `1 - log₁₀(x)/12`  
**Transform Function:** [`InductanceReciprocalFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:16) - `1 - log₁₀(value)/12`
**Subsections:** Six subsections with XL/TL constants (0.1 to 0.5 quaternary), green labels
**Use Case:** Four-decade inductance scale with reciprocal function for resonance calculations with Cr scale.
**File:** [`PickettN16ESScalesExtension.swift:16`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:16)

### Cr Scale (Capacitance Reciprocal)
**Aliases:** `CR`
**Range:** 1e-12 to 1e-3 (1pF to 1000µF)
**Formula:** `1 - log₁₀(x)/12`
**Transform Function:** [`CapacitanceReciprocalFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:44) - `1 - log₁₀(value)/12`
**Subsections:** Six subsections (0.1 to 0.5 quaternary), red labels
**Use Case:** Four-decade capacitance scale with reciprocal function, used with Lr for f = 1/(2π√LC).
**File:** [`PickettN16ESScalesExtension.swift:42`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:42)

### L Scale (Pickett C/L Combined)
**Aliases:** `PICKETTL`, `C/L`
**Range:** 1e-12 to 1e-3
**Formula:** `log₁₀(x)/12`
**Transform Function:** [`CapacitanceInductanceFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:70) - `log₁₀(value)/12`
**Subsections:** Four subsections (0.1 to 0.5 quaternary intervals)
**Use Case:** Dual purpose scale for component values or time constant calculations.
**File:** [`PickettN16ESScalesExtension.swift:66`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:66)

### ω Scale (Angular Frequency)
**Aliases:** `OMEGA`, `Ω`, `ω`
**Range:** 0.001 to 1e9 (Hz, converted to rad/s)
**Formula:** `log₁₀(2πf)/12`
**Transform Function:** [`AngularFrequencyFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:93) - `log₁₀(2π×value)/12`
**Subsections:** Twelve subsections covering full frequency range
**Use Case:** Angular frequency (ω = 2πf) for AC analysis in complex notation, impedance calculations.
**File:** [`PickettN16ESScalesExtension.swift:88`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:88)

### λ Scale (Wavelength)
**Aliases:** `LAMBDA`, `Λ`, `λ`
**Range:** 1e5 to 1e11 (Hz, displays as 3000m to 3mm wavelength)
**Formula:** `1 - log₁₀(f)/6`
**Transform Function:** [`WavelengthFunction(cycles: 6)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:143) - `1 - log₁₀(value)/6`
**Subsections:** Six subsections across wavelength range, red labels
**Use Case:** Wavelength from frequency (λ = c/f) for antenna design and transmission line calculations.
**File:** [`PickettN16ESScalesExtension.swift:129`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:129)

### Θ Scale (Phase Angle)
**Aliases:** `THETA`, `Θ`, `θ`
**Range:** 0° to 90°
**Formula:** `α = cot⁻¹(2πfRC)`
**Transform Function:** [`PhaseAngleFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:182) - `log₁₀(tan(radians))`
**Subsections:** Four subsections (1° to 5° intervals)
**Use Case:** Phase angle for RC/RL filter response, coordinated with cos(Θ) and dB scales.
**File:** [`PickettN16ESScalesExtension.swift:163`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:163)

### cos Θ Scale (Power Factor)
**Aliases:** `COS`, `COSTHETA`, `COSΘ`, `COSθ`
**Range:** 0.0 to 1.0
**Formula:** `cos(θ)`
**Transform Function:** [`CosinePhaseFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:210) - `1 - acos(value)/(π/2)`
**Subsections:** Three subsections with -3dB constant (0.01 to 0.05 quaternary intervals)
**Use Case:** Relative gain and power factor for filter response, -3dB point at 0.707.
**File:** [`PickettN16ESScalesExtension.swift:192`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:192)

### dB Scale (Power)
**Aliases:** `DB`, `DECIBEL`
**Range:** 0.01 to 100.0 (power ratios)
**Formula:** `10 log₁₀(P₂/P₁)`
**Transform Function:** [`DecibelFunction(isVoltageRatio: false)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:243) - `(dB+40)/80`
**Subsections:** Three subsections (0.01 to 1 quaternary), green labels
**Use Case:** Decibel scale for power ratios, coordinated with phase and gain scales.
**File:** [`PickettN16ESScalesExtension.swift:221`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:221)

### dbV Scale (Voltage)
**Aliases:** `DBV`, `DECIBELV`
**Range:** 0.01 to 100.0 (voltage ratios)
**Formula:** `20 log₁₀(V₂/V₁)`
**Transform Function:** [`DecibelFunction(isVoltageRatio: true)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:243) - `(dB+40)/80`
**Subsections:** Three subsections (0.01 to 1 quaternary), red labels
**Use Case:** Decibel scale for voltage/current ratios, lower scale on N-16 ES.
**File:** [`PickettN16ESScalesExtension.swift:252`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:252)

### τ Scale (Time Constant)
**Aliases:** `TAU`, `Τ`, `τ`
**Range:** 1e-9 to 1e3 (ns to seconds)
**Formula:** `log₁₀(τ)/12`
**Transform Function:** [`TimeConstantFunction(cycles: 12)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:119) - `log₁₀(value)/12`
**Subsections:** Three subsections (0.1 to 0.5 quaternary intervals)
**Use Case:** Time constant (τ = RC or L/R) for charging rates, transient response, settling time.
**File:** [`PickettN16ESScalesExtension.swift:285`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:285)

### D/Q Scale (Decimal Keeper)
**Aliases:** `PICKETTD`, `D/Q`
**Range:** 1.0 to 10.0
**Formula:** `log₁₀(x)`
**Transform Function:** [`DecimalKeeperQFunction(isQMode: false)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:289) - `log₁₀(mantissa)`
**Subsections:** Three subsections matching C/D pattern
**Use Case:** Decimal keeper for tracking magnitude in four-decade calculations, prevents order-of-magnitude errors.
**File:** [`PickettN16ESScalesExtension.swift:321`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:321)

### Q Scale (Quality Factor)
**Aliases:** `PICKETTQ`, `Q`
**Range:** 1.0 to 100.0
**Formula:** `log₁₀(Q)`
**Transform Function:** [`DecimalKeeperQFunction(isQMode: true)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:289) - `log₁₀(value)`
**Subsections:** Two subsections (0.1 to 1 quaternary intervals)
**Use Case:** Quality factor for resonant circuits (Q = ωL/R = 1/(ωRC)).
**File:** [`PickettN16ESScalesExtension.swift:340`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScalesExtension.swift:340)

---

## Special Purpose Scales

### L Scale (Linear Logarithm)
**Aliases:** `L`  
**Range:** 0 to 1 (mantissa)  
**Formula:** `log₁₀ x`  
**Transform Function:** [`LinearFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) - `x` (direct linear)
**Subsections:** One subsection (0.002 quaternary interval)
**Use Case:** Linear logarithm scale for mantissa/logarithm table calculations, highest linear precision.
**File:** [`StandardScales.swift:904`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:904)

### Ln Scale (Natural Logarithm)
**Aliases:** `LN`
**Range:** 0 to 10×ln(10) (~23.026)
**Formula:** `ln x`
**Transform Function:** [`LnNormalizedFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:121) - `ln(x)/(10×ln(10))`
**Subsections:** One subsection (0.005 quaternary interval)
**Use Case:** Natural logarithm scale for direct ln(x) reading and conversion.
**File:** [`StandardScales.swift:927`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:927)

### CAS Scale (Calibrated Airspeed)
**Aliases:** `CAS`
**Range:** 80 to 1000
**Formula:** `(22.74x+698.7)/1000`
**Transform Function:** [`CalibratedAirspeedFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:181) - `log₁₀((value×22.74+698.7)/1000)`
**Subsections:** Two subsections (2.0 to 10.0 quaternary intervals)
**Use Case:** Aviation scale for converting between indicated and calibrated airspeed.
**File:** [`StandardScales.swift:1234`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1234)

### TIME Scale
**Aliases:** `TIME`
**Range:** 60 to 600 (1 to 10 hours in minutes)
**Formula:** `x min`
**Transform Function:** [`TimeConversionFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:201) - `log₁₀(value/60) + log₁₀(6)`
**Subsections:** Two subsections (10 minute intervals), displays as hours:minutes
**Use Case:** Time conversion for time-distance calculations, shows hours:minutes format.
**File:** [`StandardScales.swift:1268`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1268)

### TIME2 Scale
**Aliases:** `TIME2`
**Range:** 600 to 6000 (10 to 100 hours in minutes)
**Formula:** `x hr`
**Transform Function:** [`TimeConversionFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:201) - `log₁₀(value/60) + log₁₀(6)`
**Subsections:** Three subsections (30 to 60 minute intervals), displays hours or days
**Use Case:** Extended time conversion for longer durations, companion to TIME scale.
**File:** [`StandardScales.swift:1300`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1300)

### L360 Scale
**Aliases:** (none listed in factory method)
**Range:** 0° to 360°
**Formula:** `θ° (0-360)`
**Transform Function:** [`LinearDegreeFunction(maxDegrees: 360.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:179) - `x/360`
**Subsections:** One subsection (1° quaternary interval)
**Use Case:** Linear 360-degree scale for compass bearings, navigation, circular calculations.
**File:** [`HyperbolicScalesExtension.swift:773`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:773)

### L180 Scale
**Aliases:** (none listed in factory method)
**Range:** 0° to 360° (labeled 0-180 and 360-180)
**Formula:** `θ° (0-180°)`
**Transform Function:** [`LinearDegreeFunction(maxDegrees: 360.0)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:179) - `x/360`
**Subsections:** Two subsections with dual labeling (1° quaternary interval)
**Use Case:** Linear 180-degree scale with complementary labeling for protractor and supplementary angles.
**File:** [`HyperbolicScalesExtension.swift:824`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScalesExtension.swift:824)

---

## Scale Name Cross-Reference

Quick lookup for finding scales by any of their aliases:

| Primary Name | All Aliases | Category |
|--------------|-------------|----------|
| C | `C` | Standard |
| D | `D` | Standard |
| CI | `CI` | Inverted |
| DI | `DI` | Inverted |
| CF | `CF` | Folded |
| DF | `DF` | Folded |
| DFm | `DFM`, `DF/M`, `DFm` | Folded |
| DFm-PS | `DFMPSS` | Folded (PostScript) |
| CIF | `CIF` | Inverted Folded |
| DIF | `DIF` | Inverted Folded |
| A | `A` | Power |
| B | `B` | Power |
| K | `K` | Power |
| AI | `AI` | Inverted Power |
| BI | `BI` | Inverted Power |
| S | `S` | Trigonometric |
| T | `T` | Trigonometric |
| T1 | `T1` | Trigonometric |
| T2 | `T2` | Trigonometric |
| ST | `ST` | Trigonometric |
| KE-S | `KE-S`, `KES` | Trigonometric (K&E) |
| KE-T | `KE-T`, `KET` | Trigonometric (K&E) |
| SRT | `SRT`, `KE-ST`, `KEST` | Trigonometric (K&E) |
| S/C | `CR3S`, `S/C`, `SC` | Trigonometric Combined |
| LL0 | `LL0` | Log-Log |
| LL1 | `LL1` | Log-Log |
| LL2 | `LL2` | Log-Log |
| LL3 | `LL3` | Log-Log |
| LL00 | `LL00` | Log-Log Reciprocal |
| LL01 | `LL01` | Log-Log Reciprocal |
| LL02 | `LL02` | Log-Log Reciprocal |
| LL03 | `LL03` | Log-Log Reciprocal |
| LL2B | `LL2B` | Log-Log Variant |
| LL02B | `LL02B` | Log-Log Variant |
| LL00B | (none) | Log-Log Variant (Hemmi) |
| H266LL01 | `H266LL01` | Log-Log Variant (Hemmi) |
| H266LL03 | `H266LL03` | Log-Log Variant (Hemmi) |
| C10-100 | `C10-100`, `C10.100` | Extended Range |
| C100-1000 | `C100-1000`, `C100.1000` | Extended Range |
| D10-100 | `D10-100`, `D10.100` | Extended Range |
| Sq1 (R1) | `R1`, `SQ1` | Square Root |
| Sq2 (R2) | `R2`, `SQ2` | Square Root |
| Q1 | `Q1` | Cube Root |
| Q2 | `Q2` | Cube Root |
| Q3 | `Q3` | Cube Root |
| Ch | `CH` | Hyperbolic |
| Sh | `SH` | Hyperbolic |
| Sh1 | `SH1` | Hyperbolic Split |
| Sh2 | `SH2` | Hyperbolic Split |
| Th | `TH` | Hyperbolic |
| H1 | `H1` | Pythagorean |
| H2 | `H2` | Pythagorean |
| P | `P` | Pythagorean Complement |
| PA | `PA` | Percentage Angular |
| XL | `EEXL`, `XL` | EE Reactance |
| Xc | `EEXC`, `XC` | EE Reactance |
| F (EE) | `EEF` | EE Frequency |
| Fo | `EEFO`, `FO` | EE Wavelength |
| L (EE) | `EEL` | EE Inductance |
| Li | `EELI`, `LI` | EE Inductance Inverted |
| Cz | `EECZ`, `CZ` | EE Capacitance |
| Cf | `EECF` | EE Cap/Freq Product |
| Z | `EEZ`, `Z` | EE Impedance |
| r1 | `EER1`, `R1EE` | EE Reflection |
| r2 | `EER2`, `R2EE` | EE Reflection |
| P (EE) | `EEP` | EE Power Ratio |
| Q (EE) | `EEQ` | EE Power Ratio Inverted |
| Lr | `LR` | Pickett N-16 ES |
| Cr | `CR` | Pickett N-16 ES |
| L (Pickett) | `PICKETTL`, `C/L` | Pickett N-16 ES |
| ω | `OMEGA`, `Ω`, `ω` | Pickett N-16 ES |
| λ | `LAMBDA`, `Λ`, `λ` | Pickett N-16 ES |
| Θ | `THETA`, `Θ`, `θ` | Pickett N-16 ES |
| cos Θ | `COS`, `COSTHETA`, `COSΘ`, `COSθ` | Pickett N-16 ES |
| dB (power) | `DB`, `DECIBEL` | Pickett N-16 ES |
| dB (voltage) | `DBV`, `DECIBELV` | Pickett N-16 ES |
| τ | `TAU`, `Τ`, `τ` | Pickett N-16 ES |
| D (Pickett) | `PICKETTD`, `D/Q` | Pickett N-16 ES |
| Q (Pickett) | `PICKETTQ`, `Q` | Pickett N-16 ES |
| L | `L` | Special |
| Ln | `LN` | Special |
| CAS | `CAS` | Aviation |
| TIME | `TIME` | Time Conversion |
| TIME2 | `TIME2` | Time Conversion |

---

## Usage Notes

### Scale Function Reference

All scales use one of the following transform functions:

- **Standard:** [`LogarithmicFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift), [`LinearFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift), [`SineFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift), [`TangentFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift)
- **Power:** [`HalfLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:61), [`ThirdLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:79)
- **Reciprocal:** [`ReciprocalLogFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:41), [`AIScaleFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:157)
- **Root:** [`SquareRootFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:222), [`SquareRootOffsetFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:241), [`CubeRootFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScalesFunctions.swift:262), etc.
- **Hyperbolic:** [`HyperbolicCosineFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:35), [`HyperbolicSineFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:75), [`HyperbolicTangentFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/HyperbolicScaleFunctions.swift:53)
- **EE:** [`InductiveReactanceFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:11), [`CapacitiveReactanceFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/ElectricalEngineeringScaleFunctions.swift:35), etc.
- **Pickett:** [`InductanceReciprocalFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:16), [`CapacitanceReciprocalFunction()`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/PickettN16ESScaleFunctions.swift:44), etc.
- **Custom:** Log-log scales use anonymous [`CustomFunction`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleModels.swift) structs with specific transform/inverse pairs

### Subsection Patterns

Most scales use progressive tick coarsening:
- **Fine intervals** (0.001-0.01) at scale start where function changes rapidly
- **Medium intervals** (0.05-0.1) in mid-range
- **Coarse intervals** (0.5-50) at scale end where function flattens

Special cases:
- **LL2B:** 26 subsections (most detailed)
- **LL3:** 17 subsections (complete PostScript fidelity)
- **K Scale:** 10 subsections (three decades compressed)

### Creating New Scales

To add a new scale:

1. Define the scale function in appropriate `*ScaleFunctions.swift` file
2. Add scale builder method in corresponding `*ScalesExtension.swift` file
3. Add case(s) to factory method in [`StandardScales.swift:1636`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1636)
4. Update this reference document

### Factory Method

All scales are accessible through [`StandardScales.scale(named:length:)`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/scales/StandardScales.swift:1636). The factory method performs case-insensitive lookup and returns `ScaleDefinition?`.

---

## Related Documentation

- [Creating New Scale from Photos Guide](new-sliderule-side-from-photos.md)
- [Scale Definition Models](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift)
- [Scale Calculator](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleCalculator.swift)
- [PostScript Engine Reference](../reference/postscript-engine-for-sliderule<br>.ps)
- [Mathematical Foundations](../reference/mathematical-foundations-of-the-slide-rule.pdf)

## Total Scale Count

**89 unique scale names** accessible through the factory method, representing approximately **60+ distinct scale implementations** (many shares functions with different parameters).

### Breakdown by Category:
- Standard scales: 2 (C, D)
- Power scales: 3 (A, B, K)
- Folded scales: 6 (CF, DF, DFm variants, CIF, DIF)
- Inverted scales: 4 (CI, DI, AI, BI)
- Extended range: 3 (C10-100, C100-1000, D10-100)
- Trigonometric: 8 (S, T, T1, T2, ST, KE variants, S/C)
- Log-log positive: 4 (LL0-LL3)
- Log-log negative: 4 (LL00-LL03)
- Log-log variants: 5 (LL2B, LL02B, LL00B, H266 variants)
- Root scales: 5 (R1, R2, Q1, Q2, Q3)
- Hyperbolic: 5 (Ch, Sh, Sh1, Sh2, Th)
- Pythagorean: 3 (H1, H2, P)
- Electrical Engineering: 11 (XL, Xc, F, Fo, L, Li, Cz, Cf, Z, r1, r2, P, Q)
- Pickett N-16 ES: 11 (Lr, Cr, L, ω, λ, Θ, cos Θ, dB×2, τ, D, Q)
- Special purpose: 6 (L, Ln, CAS, TIME×2, L360, L180, PA)

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-06  
**Maintainer:** SlideRuleCoreV3 Development Team