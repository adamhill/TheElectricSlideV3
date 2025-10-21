import Foundation

// MARK: - PostScript Formula Concordance for Root Scales
//
// UNDERSTANDING POSTSCRIPT ROOT FORMULAS:
// Root scales use logarithmic expansion by multiplying the logarithm by 2 (square roots)
// or 3 (cube roots). This stretches the scale, requiring multiple segments to cover the full range.
//
// Square Root Scale Examples:
//   {log 2 mul}                     - Square root scale: log₁₀(x) × 2 (expands D scale to 2× length)
//   {log 1 sub 2 mul}               - Offset square root: (log₁₀(x) - 1) × 2 for second segment
//
// Cube Root Scale Examples:
//   {log 3 mul}                     - Cube root scale: log₁₀(x) × 3 (expands D scale to 3× length)
//   {log 1 sub 3 mul}               - First offset: (log₁₀(x) - 1) × 3 for second segment
//   {log 2 sub 3 mul}               - Second offset: (log₁₀(x) - 2) × 3 for third segment
//
// How Multiplication Expansion Works:
//   R1 scale: log₁₀(x) × 2 maps [1,10] onto [0,2] expanded space (needs 2 segments)
//     - x=1:    log₁₀(1)×2 = 0×2 = 0         (left edge, first segment)
//     - x=3.16: log₁₀(3.16)×2 ≈ 0.5×2 = 1    (√10, end of first segment)
//
//   R2 scale: (log₁₀(x) - 1) × 2 maps [3.16,10] onto [0,1] normalized space
//     - x=3.16: (log₁₀(3.16)-1)×2 = (0.5-1)×2 = -1×2 = 0  (start of second segment)
//     - x=10:   (log₁₀(10)-1)×2 = (1-1)×2 = 0×2 = 1       (√100, end of second segment)
//
//   Q1 scale: log₁₀(x) × 3 maps [1,10] onto [0,3] expanded space (needs 3 segments)
//     - x=1:    log₁₀(1)×3 = 0×3 = 0         (left edge, first segment)
//     - x=2.15: log₁₀(2.15)×3 ≈ 0.33×3 = 1   (∛10, end of first segment)
//
// Segment Selection for Root Extraction:
//   Square roots (R1/R2): Count digits in number under radical
//     - Odd digits (1,3,5,...): Use R1 scale (√1 to √10)
//     - Even digits (2,4,6,...): Use R2 scale (√10 to √100)
//
//   Cube roots (Q1/Q2/Q3): Count digits in number under radical
//     - 1 digit: Use Q1 scale (∛1 to ∛10)
//     - 2 digits: Use Q2 scale (∛10 to ∛100)
//     - 3 digits: Use Q3 scale (∛100 to ∛1000)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Square Root Scales:
//   - R1 (Sq1):   Line 1016 - {log 2 mul} (range 1 to 3.2)
//   - R2 (Sq2):   Line 1021 - {log 2 mul} with offset {1 sub}
//
// Cube Root Scales:
//   - Q1:         Line 1027 - {log 3 mul} (range 1 to 2.16)
//   - Q2:         Line 1032 - {log 3 mul} with offset {1 sub}
//   - Q3:         Line 1040 - {log 3 mul} with offset {2 sub}

// MARK: - Root Scales
//
// These scales implement square root and cube root functions:
//   - R1/Sq1: First square root scale (1 to √10 ≈ 3.16)
//   - R2/Sq2: Second square root scale (√10 to 10)
//   - Q1: First cube root scale (1 to ∛10 ≈ 2.15)
//   - Q2: Second cube root scale (∛10 to ∛100 ≈ 4.64)
//   - Q3: Third cube root scale (∛100 to 10)

public enum TheRootsScales {
    
    // MARK: - Square Root Scales (R1, R2)
    
    /// R1 (Sq1) scale: First square root scale, extended precision for √1 to √10
    ///
    /// **Description:** First square root scale, extended precision for √1 to √10
    /// **Formula:** log₁₀(x) × 2 (D scale stretched to 2× length)
    /// **Range:** 1 to 3.16 (√1 to √10)
    /// **Used for:** square-roots, high-precision-area-calculations, pythagorean-theorem
    ///
    /// **Physical Applications:**
    /// - Geometry: Circle calculations r = √(A/π)
    /// - Pythagorean theorem: c = √(a² + b²) with better accuracy than A/B
    /// - Electrical: RMS calculations, impedance Z = √(R² + X²)
    /// - Statistics: Standard deviation calculations
    /// - Engineering: Stress analysis requiring high precision
    ///
    /// **Example 1:** Square root: Find √5
    /// 1. Determine 5 has 1 digit → use R1 scale (odd digits)
    /// 2. Locate 5 on D scale
    /// 3. Read 2.24 on R1 scale above
    /// 4. Better precision than using A/B scales
    ///
    /// **Example 2:** Circle radius from area: r = √(A/π) where A = 25
    /// 1. Calculate 25/π ≈ 7.96 using C/D/CF scales
    /// 2. Read √7.96 ≈ 2.82 on R1 scale
    /// 3. Result: radius ≈ 2.82 units
    ///
    /// **Example 3:** Pythagorean: Find hypotenuse where a=3, b=4
    /// 1. Calculate a²+b² = 9+16 = 25 using A scale
    /// 2. Locate 25 on D (even digits)
    /// 3. Read 5.0 on R2 scale
    /// 4. Demonstrates multi-scale geometry calculation
    ///
    /// **POSTSCRIPT REFERENCES:** Line 1016 in postscript-engine-for-sliderules.ps
    public static func r1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sq1")
            .withFunction(CustomFunction(
                name: "square-root",
                transform: { log10($0) * 2.0 },
                inverseTransform: { pow(10, $0 / 2.0) }
            ))
            .withRange(begin: 1.0, end: 3.2)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0-2.0: Dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                ),
                // 2.0-3.2: Medium subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                )
            ])
            .build()
    }
    
    /// R2 (Sq2) scale: Second square root scale for √10 to √100
    ///
    /// **Description:** Second square root scale for √10 to √100
    /// **Formula:** (log₁₀(x) - 1) × 2 with offset
    /// **Range:** 3.1 to 10 (√10 to √100)
    /// **Used for:** square-roots-even-digits, extended-range-precision
    ///
    /// **Physical Applications:** (same as R1)
    ///
    /// **Example 1:** Square root: Find √50
    /// 1. Determine 50 has 2 digits → use R2 scale (even digits)
    /// 2. Locate 50 on D scale
    /// 3. Read 7.07 on R2 scale above
    /// 4. Covers higher range than R1
    ///
    /// **Example 2:** Electrical impedance: Z = √(R² + X²) where R=60Ω, X=80Ω
    /// 1. Calculate 60²+80² = 10000 using A scale
    /// 2. Locate 10000 (4 digits, even) on appropriate range
    /// 3. Read √10000 = 100Ω on R2 scale
    /// 4. Real electrical engineering calculation
    ///
    /// **POSTSCRIPT REFERENCES:** Line 1021 in postscript-engine-for-sliderules.ps
    public static func r2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sq2")
            .withFunction(CustomFunction(
                name: "square-root-offset",
                transform: { (log10($0) - 1.0) * 2.0 },
                inverseTransform: { pow(10, $0 / 2.0 + 1.0) }
            ))
            .withRange(begin: 3.1, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 3.1-5.0: Dense subdivisions
                ScaleSubsection(
                    startValue: 3.1,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // 5.0-10.0: Medium subdivisions
                ScaleSubsection(
                    startValue: 5.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    // MARK: - Cube Root Scales (Q1, Q2, Q3)
    
    /// Q1 scale: First cube root scale for ∛1 to ∛10
    ///
    /// **Description:** First cube root scale for ∛1 to ∛10
    /// **Formula:** log₁₀(x) × 3 (D scale stretched to 3× length)
    /// **Range:** 1 to 2.16 (∛1 to ∛10)
    /// **Used for:** cube-roots, volume-to-dimension, precision-cubic-calculations
    ///
    /// **Physical Applications:**
    /// - Volume to dimension: Find sphere radius from volume
    /// - Cube roots with high precision
    /// - Flow rate calculations (velocity ∝ ∛pressure)
    /// - Material sizing: Find cube dimensions from volume
    /// - Chemical engineering: Reactor sizing
    ///
    /// **Example 1:** Cube root: Find ∛8
    /// 1. Determine 8 has 1 digit → use Q1 scale
    /// 2. Locate 8 on D scale
    /// 3. Read 2.0 on Q1 scale
    /// 4. Verification: 2³ = 8 ✓
    ///
    /// **Example 2:** Sphere radius from volume: r = ∛(3V/4π) where V = 10
    /// 1. Calculate 3V/4π ≈ 2.39 using C/D/CF scales
    /// 2. Locate 2.39 on D scale
    /// 3. Read ∛2.39 ≈ 1.34 on Q1 scale
    /// 4. Result: radius ≈ 1.34 units
    ///
    /// **POSTSCRIPT REFERENCES:** Line 1027 in postscript-engine-for-sliderules.ps
    public static func q1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q1")
            .withFunction(CustomFunction(
                name: "cube-root",
                transform: { log10($0) * 3.0 },
                inverseTransform: { pow(10, $0 / 3.0) }
            ))
            .withRange(begin: 1.0, end: 2.16)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0-2.0: Dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                ),
                // 2.0-2.16: Very fine subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    /// Q2 scale: Second cube root scale for ∛10 to ∛100
    ///
    /// **Description:** Second cube root scale for ∛10 to ∛100
    /// **Formula:** (log₁₀(x) - 1) × 3 with offset
    /// **Range:** 2.15 to 4.7 (∛10 to ∛100)
    /// **Used for:** cube-roots-mid-range, extended-precision
    ///
    /// **Physical Applications:** (same as Q1)
    ///
    /// **Example:** Cube root: Find ∛50
    /// 1. Determine 50 has 2 digits → use Q2 scale
    /// 2. Locate 50 on D scale
    /// 3. Read 3.68 on Q2 scale
    /// 4. Covers middle range of cube roots
    ///
    /// **POSTSCRIPT REFERENCES:** Line 1032 in postscript-engine-for-sliderules.ps
    public static func q2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q2")
            .withFunction(CustomFunction(
                name: "cube-root-offset1",
                transform: { (log10($0) - 1.0) * 3.0 },
                inverseTransform: { pow(10, $0 / 3.0 + 1.0) }
            ))
            .withRange(begin: 2.15, end: 4.7)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 2.15-2.0: Very fine subdivisions (overlap transition)
                ScaleSubsection(
                    startValue: 2.15,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                ),
                // 3.0-4.7: Medium subdivisions
                ScaleSubsection(
                    startValue: 3.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    /// Q3 scale: Third cube root scale for ∛100 to ∛1000
    ///
    /// **Description:** Third cube root scale for ∛100 to ∛1000
    /// **Formula:** (log₁₀(x) - 2) × 3 with offset
    /// **Range:** 4.6 to 10 (∛100 to ∛1000)
    /// **Used for:** cube-roots-large-numbers, completing-cubic-calculations
    ///
    /// **Physical Applications:** (same as Q1)
    ///
    /// **Example 1:** Cube root: Find ∛500
    /// 1. Determine 500 has 3 digits → use Q3 scale
    /// 2. Locate 500 on D scale
    /// 3. Read 7.94 on Q3 scale
    /// 4. Covers largest range of cube roots
    ///
    /// **Example 2:** Complex calculation: ³√(19π × 0.127) / (√716 × 0.0231 × 24.1)
    /// 1. Calculate numerator using DF for π, then Q scales for cube root
    /// 2. Calculate denominator using R scales for square root + C/D multiplication
    /// 3. Final division using CI/DI scales
    /// 4. Demonstrates competition-level multi-scale problem
    ///
    /// **POSTSCRIPT REFERENCES:** Line 1040 in postscript-engine-for-sliderules.ps
    public static func q3Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q3")
            .withFunction(CustomFunction(
                name: "cube-root-offset2",
                transform: { (log10($0) - 2.0) * 3.0 },
                inverseTransform: { pow(10, $0 / 3.0 + 2.0) }
            ))
            .withRange(begin: 4.6, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 4.6-10.0: Medium subdivisions
                ScaleSubsection(
                    startValue: 4.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
}