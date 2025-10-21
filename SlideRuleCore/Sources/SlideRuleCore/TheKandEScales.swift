import Foundation

// MARK: - Keuffel & Esser Trigonometric Scales
//
// **MANUFACTURER-SPECIFIC DESIGN HISTORY:**
//
// Keuffel & Esser (K&E) was one of America's premier slide rule manufacturers. After transitioning
// from importing European rules to independent manufacturing around 1900-1901 (receiving a patent
// for "Mannheim Adjustable Slide Rule Frame" in June 1900), K&E developed proprietary scale
// variations for:
//   - Product differentiation in competitive market (vs Post, Dietzgen, other manufacturers)
//   - Patent protection of unique designs
//   - Optimization for specific professional applications
//   - Manufacturing standardization
//
// **K&E SCALE VARIATIONS:**
//
// The K&E trig scales differ slightly from standard versions:
//   - KE-S: Starts at 5.5° vs standard 5.7° (0.2° earlier)
//   - KE-T: Starts at 5.5° vs standard 5.7° (0.2° earlier)
//   - KE-ST/SRT: Extended to 0.55°-6.0° vs standard 0.57°-5.7° (wider range)
//
// These variations provided finer precision in the transition regions and extended coverage for
// small-angle calculations valued in surveying and navigation applications.
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
//   - KE-S:       Line 661  - S scale starting at 5.5°
//   - KE-T:       Line 657  - T scale starting at 5.5°
//   - KE-ST/SRT:  Line 665  - ST scale range 0.55° to 6°

public enum TheKandEScales {
    
    // MARK: - KE Trigonometric Scales
    
    /// KE-S scale: Keuffel & Esser sine scale with extended low-end range
    ///
    /// **Description:** Keuffel & Esser sine scale with extended low-end range
    /// **Formula:** log₁₀(10×sin(x)) for angles in degrees
    /// **Range:** 5.5° to 90° (vs standard 5.7° to 90°)
    /// **Used for:** sine-calculations, K&E-specific-calculations, extended-precision-surveying
    ///
    /// **Physical Applications:**
    /// - Surveying: Extended range for small vertical angles
    /// - Navigation: Celestial navigation with low-altitude stars
    /// - Structural engineering: Force components at shallow angles
    /// - Civil engineering: Grade calculations near 5-6° transition
    /// - Precision work: Applications requiring 5.5°-5.7° coverage
    ///
    /// **Example 1:** Find sin(5.6°) using K&E extended range
    /// 1. Standard S scale starts at 5.7°, cannot read 5.6°
    /// 2. KE-S scale extends to 5.5°, covers this value
    /// 3. Locate 5.6° on KE-S scale
    /// 4. Read sin(5.6°) ≈ 0.0976 on C/D scale
    /// 5. Demonstrates K&E advantage for transition angles
    ///
    /// **Example 2:** Compare K&E vs standard at 5.7° boundary
    /// 1. Locate 5.7° on both KE-S and standard S scales
    /// 2. Both should read same value on C/D
    /// 3. KE-S provides smoother transition from ST scale
    /// 4. Shows manufacturer design philosophy
    ///
    /// **Example 3:** Surveying: Calculate vertical rise for 5.55° slope over 100m
    /// 1. Angle 5.55° falls between ST (ends 5.7°) and S scales
    /// 2. Use KE-S scale at 5.55°
    /// 3. Read sin(5.55°) ≈ 0.0967 on C/D
    /// 4. Rise = 100 × 0.0967 = 9.67m
    /// 5. K&E scale eliminates gap in coverage
    ///
    /// **POSTSCRIPT REFERENCES:** Line 661 in postscript-engine-for-sliderules.ps
    public static func keSScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("KE-S")
            .withFunction(SineFunction(multiplier: 10.0))
            .withRange(begin: 5.5, end: 90)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 5.5,
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
    
    /// KE-T scale: Keuffel & Esser tangent scale with extended low-end range
    ///
    /// **Description:** Keuffel & Esser tangent scale with extended low-end range
    /// **Formula:** log₁₀(10×tan(x)) for angles in degrees
    /// **Range:** 5.5° to 45° (vs standard 5.7° to 45°)
    /// **Used for:** tangent-calculations, slope-angles, K&E-extended-precision
    ///
    /// **Physical Applications:**
    /// - Civil engineering: Road grades in 5.5°-5.7° range
    /// - Structural engineering: Roof pitches and ramp slopes
    /// - Surveying: Vertical angle measurements with extended coverage
    /// - Navigation: Course angles and bearing calculations
    /// - Precision trigonometry: Gap-free coverage with ST scale
    ///
    /// **Example 1:** Find tan(5.6°) for road grade calculation
    /// 1. Standard T scale starts at 5.7°, misses 5.6°
    /// 2. KE-T extends to 5.5°, covers this angle
    /// 3. Locate 5.6° on KE-T scale
    /// 4. Read tan(5.6°) ≈ 0.098 on C/D = 9.8% grade
    /// 5. Critical for civil engineering specifications
    ///
    /// **Example 2:** Transition from SRT to KE-T scales
    /// 1. SRT scale ends at 6.0° on K&E rules
    /// 2. KE-T starts at 5.5°, creating overlap 5.5°-6.0°
    /// 3. Overlap allows verification between scales
    /// 4. Demonstrates K&E design for continuous coverage
    ///
    /// **Example 3:** Calculate building setback: distance = height/tan(angle) for angle=5.55°
    /// 1. Height = 20m, angle = 5.55°
    /// 2. Find tan(5.55°) ≈ 0.097 on KE-T scale (C/D reading)
    /// 3. Calculate 20/0.097 ≈ 206m using CI/DI scales
    /// 4. Zoning regulation application
    ///
    /// **POSTSCRIPT REFERENCES:** Line 657 in postscript-engine-for-sliderules.ps
    public static func keTScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("KE-T")
            .withFunction(TangentFunction(multiplier: 10.0))
            .withRange(begin: 5.5, end: 45)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 5.5,
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
    
    /// KE-ST/SRT scale: Keuffel & Esser small angle tangent with extended range
    ///
    /// **Description:** Keuffel & Esser small angle tangent with extended range
    /// **Formula:** log₁₀(100×radians) = log₁₀(100×π×degrees/180)
    /// **Range:** 0.55° to 6.0° (vs standard 0.57° to 5.7°)
    /// **Title:** "SRT" on actual K&E slide rules
    /// **Used for:** small-angle-approximations, extended-precision-surveying, radian-conversion
    ///
    /// **Physical Applications:**
    /// - Precision surveying: Very small vertical angles below 0.57°
    /// - Artillery calculations: Minute elevation adjustments
    /// - Optical engineering: Small-angle lens systems
    /// - Astronomy: Extended precision for celestial measurements
    /// - Geodesy: High-precision horizontal angle work
    ///
    /// **Example 1:** Small angle below standard ST range: 0.56°
    /// 1. Standard ST starts at 0.57°, cannot read 0.56°
    /// 2. K&E SRT extends to 0.55°, covers this value
    /// 3. Locate 0.56° on SRT scale
    /// 4. Read value on C/D ≈ 0.00977 (radians ×100)
    /// 5. K&E provides 0.02° additional low-end coverage
    ///
    /// **Example 2:** Extended upper range: Compare SRT at 5.8° vs standard ST
    /// 1. Standard ST ends at 5.7°
    /// 2. K&E SRT extends to 6.0°
    /// 3. At 5.8°, SRT allows direct reading
    /// 4. Provides 0.3° extended upper coverage
    /// 5. Total extension: 0.02° lower + 0.3° upper = better coverage
    ///
    /// **Example 3:** Artillery: Elevation adjustment of 0.56° for 1000m range
    /// 1. Convert 0.56° to milliradians using SRT
    /// 2. Calculate adjustment distance
    /// 3. K&E precision critical for military applications
    /// 4. Demonstrates specialized professional use
    ///
    /// **POSTSCRIPT REFERENCES:** Line 665 in postscript-engine-for-sliderules.ps
    public static func keSTScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("SRT")
            .withFunction(CustomFunction(
                name: "small-tan",
                transform: { log10($0 * .pi / 180.0 * 100.0) },
                inverseTransform: { pow(10, $0) * 180.0 / .pi / 100.0 }
            ))
            .withRange(begin: 0.55, end: 6.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.55,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
}