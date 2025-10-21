import Foundation

// MARK: - Scale Reading Guide
//
// POSTSCRIPT SCALE IMPLEMENTATION NOTES:
// These scales implement the PostScript formulas documented in postscript-engine-for-sliderules.ps.
// Each scale definition specifies:
//   - Formula: The mathematical transformation applied
//   - Range: The input value range for the scale
//   - Physical Applications: Real-world uses
//   - Usage Examples: Step-by-step calculation procedures
//
// SCALE ALIGNMENT:
// Slide rule scales work by aligning values to perform multiplication, division,
// and function evaluation. Common operations:
//   - Multiplication: C×D scales (align hairline)
//   - Function evaluation: Read from function scale, interpret on C/D
//   - Inverse operations: Use inverted scales (CI, DI)
//
// POSTSCRIPT REFERENCES:
// - S scale:   Line 586 - {sin 10 mul log}
// - T scale:   Line 623 - {tan 10 mul log}
// - ST scale:  Line 638 - {radians 100 mul log}

// MARK: - Transcendental Scales

public enum TheTranscendentalScales {
    
    // MARK: - Trigonometric Scales
    
    /// S scale: Sine/cosine scale with dual labeling
    ///
    /// **PostScript Reference:** Sscale (line 586)
    /// Formula: log₁₀(10×sin(x)) for angles in degrees
    /// Range: 5.7° to 90° (sin values 0.1 to 1.0 on C/D)
    /// Used for: sine-calculations, cosine-calculations, triangle-solutions, navigation
    ///
    /// **Physical Applications:**
    /// - Surveying: Right triangle calculations, slope angles
    /// - Navigation: Course and bearing calculations, celestial navigation
    /// - Structural engineering: Force components in angled members
    /// - RF engineering: Antenna radiation patterns
    /// - Physics: Wave mechanics, oscillations, projectile motion
    ///
    /// **Example 1:** Find sin(30°)
    /// 1. Locate 30° on S scale (black numbers)
    /// 2. Read value on C/D scale below
    /// 3. Result: sin(30°) = 0.5
    /// 4. Fundamental trig calculation
    ///
    /// **Example 2:** Find cos(60°) using complementary angle
    /// 1. Cosine uses red numbers (read right to left)
    /// 2. Locate 60° on S scale red labeling
    /// 3. Or locate 30° on black (since cos(60°)=sin(30°))
    /// 4. Read C/D value = 0.5
    ///
    /// **Example 3:** Calculate 25.7 × sin(13.6°) for force component
    /// 1. Locate 13.6° on S scale
    /// 2. Read sin(13.6°) ≈ 0.235 on C/D scale
    /// 3. Set C:1 over D:0.235
    /// 4. Move cursor to C:25.7
    /// 5. Read D:6.04 (force component)
    /// 6. Structural engineering application
    ///
    /// **Example 4:** Law of Sines: a/sin(A) = b/sin(B)
    /// 1. Find sin(angle A) using S scale → C/D
    /// 2. Divide side a by sin(A) using C/D/CI
    /// 3. Find sin(angle B) using S scale
    /// 4. Multiply by sin(B) to get side b
    /// 5. Multi-scale triangle solution
    public static func sScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("S")
            .withFunction(SineFunction(multiplier: 10.0))
            .withRange(begin: 5.7, end: 90)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.angle
                ),
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                )
            ])
            .build()
    }
    
    /// T scale: Tangent/cotangent scale with dual sections
    ///
    /// **PostScript Reference:** Tscale (line 623)
    /// Formula: log₁₀(10×tan(x)) for angles in degrees
    /// Range: 5.7° to 45° (tan values 0.1 to 1.0 on C/D); 45° to 84.5° uses CI scale
    /// Used for: tangent-calculations, slope-calculations, grade-percentages, surveying
    ///
    /// **Physical Applications:**
    /// - Civil engineering: Road grades, ramp slopes (rise/run)
    /// - Surveying: Vertical angle calculations, elevation changes
    /// - Navigation: Course corrections, drift angles
    /// - Structural engineering: Roof pitches, truss angles
    /// - Physics: Inclined plane problems, friction angles
    ///
    /// **Example 1:** Find tan(20°) for slope calculation
    /// 1. Locate 20° on T scale
    /// 2. Read value on C/D scale below
    /// 3. Result: tan(20°) ≈ 0.364
    /// 4. Represents 36.4% grade
    ///
    /// **Example 2:** Find slope angle from 15% grade
    /// 1. Grade 15% = rise/run = 0.15 = tan(θ)
    /// 2. Locate 0.15 on C/D scale
    /// 3. Read angle on T scale above
    /// 4. Result: θ ≈ 8.5°
    ///
    /// **Example 3:** Calculate height of building: h = d × tan(θ) where d=50m, θ=60°
    /// 1. Angle 60° > 45° → use CI scale section
    /// 2. Locate 60° on T scale
    /// 3. Read tan(60°) ≈ 1.732 on CI scale
    /// 4. Multiply: 50 × 1.732 = 86.6m
    /// 5. Demonstrates T scale with CI integration
    ///
    /// **Example 4:** Navigation: Drift angle with cross-wind
    /// 1. Wind speed and aircraft speed known
    /// 2. Calculate drift angle using T scale
    /// 3. Correct course using complementary angle
    /// 4. Real navigation application
    public static func tScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("T")
            .withFunction(TangentFunction(multiplier: 10.0))
            .withRange(begin: 5.7, end: 45)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                )
            ])
            .build()
    }
    
    /// ST scale: Small angle scale where sin≈tan≈radians
    ///
    /// **PostScript Reference:** STscale (line 638)
    /// Formula: log₁₀(100×radians) = log₁₀(100×π×degrees/180)
    /// Range: 0.57° to 5.7° (small angles where approximations valid)
    /// Used for: small-angle-approximations, radian-conversion, precision-angles
    ///
    /// **Physical Applications:**
    /// - Precision surveying: Very small angular deviations
    /// - Optical engineering: Small-angle lens calculations
    /// - Astronomy: Angular diameter of celestial objects (arcminutes/arcseconds)
    /// - Ballistics: Small trajectory corrections
    /// - Navigation: Minute course corrections
    ///
    /// **Example 1:** Convert 3° to radians
    /// 1. Locate 3° on ST scale
    /// 2. Read corresponding value on C/D scale
    /// 3. Value represents radians × 100
    /// 4. Result: 3° ≈ 0.0524 radians
    /// 5. Uses "R" gauge mark at 57.29° (180/π) for conversions
    ///
    /// **Example 2:** Small angle approximation: sin(2°) ≈ tan(2°) ≈ 2°(in radians)
    /// 1. Locate 2° on ST scale
    /// 2. Read value on C/D ≈ 0.0349
    /// 3. This equals sin(2°) ≈ tan(2°) ≈ 2π/180
    /// 4. Demonstrates small angle equivalence
    ///
    /// **Example 3:** Angular diameter of Moon: Calculate apparent size
    /// 1. Moon diameter d = 3474 km, distance D = 384,400 km
    /// 2. Small angle: θ ≈ d/D in radians
    /// 3. θ ≈ 0.00904 radians ≈ 0.518°
    /// 4. Use ST scale to verify/calculate
    /// 5. Astronomy application
    ///
    /// **Example 4:** Combined with S scale: Transition region 5-6°
    /// 1. For angles near 5.7°, can use either S or ST scale
    /// 2. Compare results for consistency
    /// 3. ST gives higher precision at low end
    /// 4. S scale takes over for larger angles
    /// 5. Demonstrates scale overlap region
    public static func stScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("ST")
            .withFunction(CustomFunction(
                name: "small-tan",
                transform: { log10($0 * .pi / 180.0 * 100.0) },
                inverseTransform: { pow(10, $0) * 180.0 / .pi / 100.0 }
            ))
            .withRange(begin: 0.57, end: 5.7)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.6,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
}