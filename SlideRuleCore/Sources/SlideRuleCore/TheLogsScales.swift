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
// - LL1 scale:  Lines 1357-1366 - {ln 10 mul log}
// - LL2 scale:  Lines 1368-1385 - {ln 10 mul log}
// - LL3 scale:  Lines 1420-1446 - {ln log}
// - L scale:    Line 1136 - {} (linear/identity)
// - Ln scale:   Line 1173 - {ln 10 ln mul div}

// MARK: - Logarithmic Scales

public enum TheLogsScales {
    
    // MARK: - Log-Log Scales
    
    /// LL1 scale: First log-log scale for small exponentials
    ///
    /// **PostScript Reference:** LL1scale (lines 1357-1366)
    /// Formula: log₁₀(ln(x)) × 10 (e^0.01x to e^0.1x range)
    /// Range: 1.01 to 1.105 (e^0.01 to e^0.1)
    /// Used for: small-exponential-growth, compound-interest, power-calculations
    ///
    /// **Physical Applications:**
    /// - Finance: Compound interest calculations for small rates
    /// - Population dynamics: Growth models with small rates
    /// - Radioactive decay: Short half-life isotopes
    /// - Chemical kinetics: Reaction rates at low concentrations
    /// - Electrical engineering: RC time constants
    ///
    /// **Example 1:** Calculate 1.05^7 (compound interest)
    /// 1. Locate 1.05 on LL1 scale
    /// 2. Set C:1 over D:1.05 position
    /// 3. Move cursor to C:7
    /// 4. Read result on LL2 scale ≈ 1.407
    /// 5. Demonstrates progression across LL scales
    ///
    /// **Example 2:** Find e^0.05 for exponential growth
    /// 1. Input 0.05 corresponds to position on LL1
    /// 2. Locate appropriate value on LL1 scale
    /// 3. Read e^0.05 ≈ 1.0513 directly
    /// 4. Used in continuous compounding formulas
    public static func ll1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("LL1")
            .withFunction(CustomFunction(
                name: "log-ln",
                transform: { log10(log($0)) * 10.0 },
                inverseTransform: { exp(pow(10, $0 / 10.0)) }
            ))
            .withRange(begin: 1.01, end: 1.105)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.01,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                )
            ])
            .build()
    }
    
    /// LL2 scale: Second log-log scale for medium exponentials
    ///
    /// **PostScript Reference:** LL2scale (lines 1368-1385)
    /// Formula: log₁₀(ln(x)) × 10 (e^0.1x to e^1x range)
    /// Range: 1.105 to 2.72 (e^0.1 to e ≈ 2.718)
    /// Used for: exponential-calculations, continued-compound-interest, growth-models
    ///
    /// **Physical Applications:**
    /// - Exponential growth: Population doubling calculations
    /// - Radioactive decay: Medium half-life calculations
    /// - Thermodynamics: Temperature decay over time
    /// - Economics: Inflation and investment growth
    /// - Biology: Bacterial growth curves
    ///
    /// **Example 1:** Calculate e^0.5 for half-unit exponential
    /// 1. Locate value corresponding to 0.5 exponent
    /// 2. Read approximately 1.649 on LL2 scale
    /// 3. Verification: e^0.5 = √e ≈ 1.649
    ///
    /// **Example 2:** Power calculation: 1.2^4 using LL1→LL2
    /// 1. Locate 1.2 on LL1 or LL2
    /// 2. Set C:1 over cursor position
    /// 3. Move cursor to C:4
    /// 4. Read result ≈ 2.07 on LL2 scale
    /// 5. Shows multi-scale exponential operations
    public static func ll2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("LL2")
            .withFunction(CustomFunction(
                name: "log-ln",
                transform: { log10(log($0)) * 10.0 },
                inverseTransform: { exp(pow(10, $0 / 10.0)) }
            ))
            .withRange(begin: 1.105, end: 2.72)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.1,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .addConstant(value: .e, label: "e", style: .major)
            .build()
    }
    
    /// LL3 scale: Third log-log scale for large exponentials
    ///
    /// **PostScript Reference:** LL3scale (lines 1420-1446)
    /// Formula: log₁₀(ln(x)) (e^1x to e^10x range)
    /// Range: 2.74 to 21000 (e^1 to e^10)
    /// Used for: large-exponential-growth, power-laws, extreme-compound-interest
    ///
    /// **Physical Applications:**
    /// - Large-scale exponential growth: Economic projections
    /// - Nuclear physics: High-energy decay calculations
    /// - Astrophysics: Stellar luminosity relationships
    /// - Information theory: Entropy calculations
    /// - Extreme compounding: Long-term investments
    ///
    /// **Example 1:** Calculate e^5 for large exponential
    /// 1. Locate position for exponent 5 on LL3
    /// 2. Read e^5 ≈ 148.4 directly
    /// 3. Used in probability and statistics
    ///
    /// **Example 2:** Power calculation: 2^10 = 1024 using LL scales
    /// 1. Locate 2 on LL2 scale (e^0.693)
    /// 2. Set C:1 over D:2 position
    /// 3. Move cursor to C:10
    /// 4. Read result ≈ 1024 on LL3 scale
    /// 5. Demonstrates arbitrary base powers
    ///
    /// **Example 3:** Multi-scale with trig: Calculate e^(sin(30°))
    /// 1. Find sin(30°) = 0.5 using S scale on C/D
    /// 2. Locate 0.5 exponent on LL scales
    /// 3. Read e^0.5 ≈ 1.649 on LL2
    /// 4. Shows integration with transcendental scales
    public static func ll3Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("LL3")
            .withFunction(CustomFunction(
                name: "log-ln",
                transform: { log10(log($0)) },
                inverseTransform: { exp(pow(10, $0)) }
            ))
            .withRange(begin: 2.74, end: 21000)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 2.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.2],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 500.0, 100.0, 50.0],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
    
    // MARK: - Linear Logarithm Scales
    
    /// L scale: Linear logarithm scale (mantissa)
    ///
    /// **PostScript Reference:** Lscale (line 1136)
    /// Formula: Identity function (linear 0 to 1)
    /// Range: 0 to 1 (represents log mantissa)
    /// Used for: logarithm-mantissa, powers-of-10, log-interpolation
    ///
    /// **Physical Applications:**
    /// - Logarithmic calculations: Finding log₁₀ of any number
    /// - Decibel calculations: Sound and signal power
    /// - pH calculations: Acid/base chemistry
    /// - Richter scale: Earthquake magnitude
    /// - Astronomical magnitudes: Star brightness
    ///
    /// **Example 1:** Find log₁₀(5)
    /// 1. Locate 5 on D scale
    /// 2. Read corresponding value on L scale ≈ 0.699
    /// 3. Therefore log₁₀(5) = 0.699
    ///
    /// **Example 2:** Calculate 10^0.5 (antilog)
    /// 1. Locate 0.5 on L scale
    /// 2. Read corresponding D scale value ≈ 3.162
    /// 3. Result: 10^0.5 = √10 ≈ 3.162
    ///
    /// **Example 3:** Combined with LL scales: Find x where e^x = 10
    /// 1. Locate 10 on LL3 scale
    /// 2. Use L scale with C/D for log operations
    /// 3. Result: x = ln(10) ≈ 2.303
    /// 4. Demonstrates L/LL integration
    public static func lScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("L")
            .withFunction(LinearFunction())
            .withRange(begin: 0, end: 1)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    /// Ln scale: Natural logarithm scale
    ///
    /// **PostScript Reference:** Lnscale (line 1173)
    /// Formula: ln(x) / (10×ln(10)) (normalized natural log)
    /// Range: 0 to 10×ln(10) ≈ 23.03
    /// Used for: natural-logarithms, hyperbolic-functions, exponential-decay
    ///
    /// **Physical Applications:**
    /// - Thermodynamics: Entropy and energy calculations
    /// - Hyperbolic functions: sinh, cosh calculations via sinh x = (e^x - e^-x)/2
    /// - Electrical engineering: RC and RL circuit time constants
    /// - Pharmacology: Drug half-life and clearance
    /// - Nuclear physics: Decay rate calculations
    ///
    /// **Example 1:** Find ln(7) for natural logarithm
    /// 1. Locate 7 on D scale
    /// 2. Read corresponding Ln scale value ≈ 1.946
    /// 3. Result: ln(7) ≈ 1.946
    ///
    /// **Example 2:** Calculate sinh(2) using Ln and LL scales
    /// 1. Calculate e^2 using LL scales ≈ 7.389
    /// 2. Calculate e^-2 ≈ 0.135 using reciprocal LL scales
    /// 3. Subtract: 7.389 - 0.135 = 7.254
    /// 4. Divide by 2: sinh(2) = 3.627
    /// 5. Demonstrates Ln/LL/hyperbolic integration
    ///
    /// **Example 3:** RC time constant: τ = RC, find time to 63% charge
    /// 1. Use Ln scale for e-based calculations
    /// 2. At t = τ, voltage = V(1 - e^-1) = 0.632V
    /// 3. Ln scale provides natural timing relationship
    /// 4. Electrical engineering application
    public static func lnScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Ln")
            .withFunction(CustomFunction(
                name: "ln-normalized",
                transform: { log($0) / (10 * log(10)) },
                inverseTransform: { exp($0 * 10 * log(10)) }
            ))
            .withRange(begin: 0, end: 10 * log(10))
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
}