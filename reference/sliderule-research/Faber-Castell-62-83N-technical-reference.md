# Faber-Castell 62/83 N NOVO DUPLEX: Complete Technical Reference

The Faber-Castell 62/83 N represents the pocket-sized pinnacle of German slide rule engineering—a **30-scale duplex instrument** manufactured from 1962 to 1976, featuring the company's signature self-documenting scales and innovative Pythagorean and split tangent functions. This comprehensive analysis covers scale layout, mathematical formulas, construction details, and gauge marks based on the official Faber-Castell instruction manual and collector documentation.

## Scale layout with tick mark directions

The 62/83 N employs a consistent color-coding system where **all red-colored scales run right to left** (decreasing), while black scales run left to right (increasing). The official manual explicitly states: *"All scales marked in red run in the opposite direction (reciprocally) from right to left."*

**Front face scale arrangement:**

| Position | Scale | Formula | Direction | Notes |
|----------|-------|---------|-----------|-------|
| Top Stator | T1 | tan 0.1x (cot) | Black figures L→R, red figures for cotangent | 5.7°–45° range |
| Top Stator | T2 | tan x (cot) | Black figures L→R, red figures for cotangent | 45°–84° range |
| Top Stator | K | x³ | L→R (black) | Cube scale |
| Top Stator | A | x² | L→R (black) | Pale blue highlight |
| Top Stator | DF | πx | L→R (black) | Fixed π-folded |
| Slide | CF | πx | L→R (black) | Green stripe accent |
| Slide | B | x² | L→R (black) | Pale blue highlight |
| Slide | CIF | 1÷πx | **R→L (red)** | Reciprocal π-folded |
| Slide | CI | 1÷x | **R→L (red)** | Reciprocal basic |
| Slide | C | x | L→R (black) | Green stripe accent |
| Bottom Stator | D | x | L→R (black) | Green stripe |
| Bottom Stator | DI | 1÷x | **R→L (red)** | Fixed reciprocal |
| Bottom Stator | S | sin 0.1x (cos) | Black figures for sine, red for cosine | 5.7°–90° |
| Bottom Stator | ST | arc 0.01x | L→R | Small angles 0.55°–6° |
| Bottom Stator | P | √(1-(0.1x)²) | **R→L (red)** | Pythagorean |

**Back face scale arrangement:**

| Position | Scale | Formula | Direction |
|----------|-------|---------|-----------|
| Top Stator | LL03 | e^(-x) | **R→L (red)** |
| Top Stator | LL02 | e^(-0.1x) | **R→L (red)** |
| Top Stator | LL01 | e^(-0.01x) | **R→L (red)** |
| Top Stator | LL00 | e^(-0.001x) | **R→L (red)** |
| Top Stator | W2 | (√10)x | L→R (black) |
| Slide | W2' | √(10x) | L→R (black) |
| Slide | CI | 1÷x | **R→L (red)** |
| Slide | L | log x | L→R (black) |
| Slide | C | x | L→R (black) |
| Slide | W1' | √x | L→R (black) |
| Bottom Stator | W1 | √x | L→R (black) |
| Bottom Stator | D & LL0 | x, e^(0.001x) | L→R, combined |
| Bottom Stator | LL1 | e^(0.01x) | L→R (black) |
| Bottom Stator | LL2 | e^(0.1x) | L→R (black) |
| Bottom Stator | LL3 | e^x | L→R (black) |

## T1 and T2 split tangent scales explained

The split tangent design solves a fundamental problem: tangent values span from near-zero to infinity across 0°–90°, making a single scale impractical. Faber-Castell's solution divides coverage into two complementary scales that together provide complete trigonometric capability.

**T1 scale specifications:**
- **Formula:** tan(θ) where the D scale reads 0.1 to 1.0
- **Angular range:** Approximately **5.7° to 45°**
- **Output range:** Tangent values from **0.1 to 1.0** on the D scale
- **Black figures:** Read tangent directly against D scale
- **Red figures:** Read cotangent against D scale (or tangent against CI)

**T2 scale specifications:**
- **Formula:** tan(θ) where the D scale reads 1.0 to 10
- **Angular range:** Approximately **45° to 84.3°** (some sources note 41°–85° overlap region)
- **Output range:** Tangent values from **1.0 to ~10** on the D scale
- **Same dual-color reading system** as T1

The manual clarifies the reading methodology: *"The two T scales, when the black figures are read, provide, in conjunction with the D scale (black), a table of tangents; the same applies when the red figures are read, in conjunction with CI (red). The two T scales, when the red figures are read, provide, in conjunction with the D Scale (black), a table of cotangents."*

This design eliminates the need to compute cotangent separately—users simply switch between black and red figures and between D and CI scales for complete tangent/cotangent coverage.

## The P scale: Faber-Castell's Pythagorean innovation

**Confirmed formula:** P = √(1 - (0.1x)²)

This is indeed the standard Faber-Castell Pythagorean scale. When x on the D scale represents a value between 0.1 and 1.0, the P scale directly yields √(1 - x²). The scale runs **right to left with red graduations**, indicating its inverse relationship.

**Range characteristics:**
- When D = 1 (representing 0.1): P ≈ **0.995** (since √(1 - 0.01) ≈ 0.995)
- When D = 10 (representing 1.0): P = **0** (since √(1 - 1) = 0)
- Practical range: **0 to approximately 0.995**

**Primary applications:**
1. **Sine-cosine conversion:** If D is set to sin(θ), P gives cos(θ) directly, and vice versa
2. **Right triangle calculations:** c = b × √(1 - (a/b)²)
3. **Unit vector calculations:** Given x-coordinate, find y-coordinate in one operation
4. **Complex number calculations:** Converting between rectangular and polar forms

The Oughtred Society publication "Watch your Ps and Qs – The Pythagorean Scales – Are They Worth the Effort?" (Vol. 15, No. 2, 2006) provides detailed analysis of this scale's utility.

## Separator lines within the slide

Based on examination of documentation and collector photographs, the 62/83 N does **not feature explicit horizontal divider lines** between scale groups on the slide portion. Visual separation is achieved through:

- **Color accent stripes:** Green (mint) stripe on C and CF scales; pale blue highlighting on A and B scales
- **Red coloring:** All reciprocal/inverse scales (CI, CIF, DI, P) marked in red
- **Physical construction:** The slide sits in channels within the body, creating natural visual boundaries between stator and slide scales
- **Scale labeling:** Each scale is clearly labeled at the left end with its designation

The self-documenting feature—where each scale shows its mathematical formula at the right-hand end—also aids visual organization. Unlike some other manufacturers who used ruled lines to separate scale groups, Faber-Castell relied on color coding and physical design for scale differentiation.

## Gauge marks and special constants

**Scale-embedded gauge marks:**

| Symbol | Value | Location | Purpose |
|--------|-------|----------|---------|
| **π** | 3.14159 | C, D, CI, CF, DF, CIF, W1, W1', W2, W2' | Circle calculations; easily located and set |
| **ρ** (rho) | 0.01745 (π/180) | C, D, W1, W1' | Radian conversion; small angle calculations where sin α ≈ tan α ≈ arc α |
| **e** | 2.71828 | LL2 and LL3 scales | Natural logarithm base |

**Cursor hairline gauge marks (11 cursor lines total):**

| Mark | Function |
|------|----------|
| **Main central hairline** | Primary calculation line, front and back faces |
| **360** | Factor 3.6 calculations—degrees to seconds, km/h to m/sec, interest calculations |
| **d** (diameter) | Circle area calculation—set over diameter on D or C |
| **q** (or A for Area) | Two short lines in upper left corner for reading circle area on A/B |
| **KW** | Kilowatt conversion |
| **PS** (HP) | Horsepower (Pferdestärke)—paired with KW for power conversions |
| **Red side marks** | Right and left edges for reading extended red supplementary graduations |

**ST scale correction marks:** The small-angle scale includes special correction marks in the **4°–6° range** that provide exact sine and tangent values, accounting for the deviation from the arc approximation at larger small angles.

## Physical dimensions

**62/83 N (pocket version):**
- **Overall length:** 21 cm / 8⅓ inches
- **Scale length:** 12.5 cm / 5 inches (graduation length)
- **Body width:** Approximately 44 mm (scaled from the 57mm of the 2/83N)
- **Overall dimensions:** Approximately 21 × 4.5 × 1 cm

**2/83 N (full-size sibling for comparison):**
- **Overall length:** 37 cm / 14–15 inches
- **Scale length:** 25 cm / 10 inches
- **Body width:** 57 mm / 2¼ inches

**Materials and construction:**
- **Body:** Geroplast (Faber-Castell's proprietary plastic)
- **End braces:** Adjustable gold-anodized aluminum with rubber insert bumpers
- **Cursor:** All-plastic duplex cursor with 5/4-line configuration (5 lines front, 4 back)
- **Open-frame design** with stamped sheet-metal straps

Specific stator and slide heights in millimeters are not explicitly documented in available sources, but the overall body width of 57mm for the 2/83N suggests individual component heights of approximately **15–18mm for the slide** and **18–20mm per stator section**.

## Front versus back scale arrangement

The duplex design provides complementary functionality between faces:

**Front face (15 scales):** Optimized for general computation and trigonometry
- Basic arithmetic: C, D, CI, DI
- Squares/cubes: A, B, K
- π-folded scales: CF, DF, CIF
- Trigonometry: T1, T2, S, ST
- Pythagorean: P

**Back face (15–16 scales):** Optimized for exponentials, logarithms, and precision work
- Exponential (positive): LL0, LL1, LL2, LL3
- Exponential (negative): LL00, LL01, LL02, LL03
- Double-length root scales: W1, W1', W2, W2'
- Mantissa: L
- Basic: C, CI, D

The **W scales provide doubled accuracy**—effectively giving 10-inch precision on a 5-inch rule by splitting the range across two adjacent scales (W1 covers √x from 1–3.3, W2 covers √(10x) from 3–10).

## Conclusion

The Faber-Castell 62/83 N exemplifies the apex of mechanical calculation technology, combining **30 self-documenting scales** with innovative features like the Pythagorean P scale, split tangent coverage, and double-length W scales for enhanced precision. Its systematic color coding—red for reciprocal/inverse scales running right-to-left, black for standard scales running left-to-right—creates an intuitive interface despite the complexity. The absence of separator lines between scale groups reflects Faber-Castell's reliance on color accents and physical design for visual organization. Manufactured during the final era of slide rule production (1962–1976), the 62/83 N represents German precision engineering at its finest, earning its reputation as one of the most sophisticated pocket calculating instruments ever produced.