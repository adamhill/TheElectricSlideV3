import Foundation

/// Label formatter that can optionally suppress labels by returning nil
public typealias LabelFormatter = @Sendable (ScaleValue) -> String?

// MARK: - PostScript-Accurate Log-Log Scale Implementations
//
// This file implements Log-Log scales with EXACT subsection patterns from the PostScript
// slide rule engine (postscript-engine-for-sliderules.ps). These implementations match
// the original tick patterns precisely, including all subsection boundaries and intervals.
//
// DIFFERENCES FROM SIMPLIFIED VERSIONS:
// The TheLogsScales.swift file contains simplified subsection patterns for ease of use.
// This file provides PostScript-accurate versions for applications requiring exact
// historical slide rule reproduction or for comparison/validation purposes.
//
// POSTSCRIPT FORMULA CONCORDANCE:
// All formulas are direct Swift translations of PostScript RPN (Reverse Polish Notation):
//   PostScript: {ln 100 mul log}  →  Swift: log10(log(x) * 100)
//   PostScript: {ln 10 mul log}   →  Swift: log10(log(x) * 10)
//   PostScript: {ln log}          →  Swift: log10(log(x))
//
// WHY MULTIPLE SUBSECTIONS?
// Slide rules use different tick intervals across their range to maintain readability.
// Dense regions (where function changes slowly) get fine ticks; sparse regions get
// coarser ticks. Each subsection defines its own tick pattern for optimal precision.
//
// POSTSCRIPT LINE REFERENCES:
//   LL1scale:  Lines 915-922  (postscript-engine-for-sliderules.ps)
//   LL2scale:  Lines 925-933  (postscript-engine-for-sliderules.ps)
//   LL2Bscale: Lines 936-959  (postscript-engine-for-sliderules.ps)
//   LL3scale:  Lines 962-983  (postscript-engine-for-sliderules.ps)

extension StandardScales {
    
    // MARK: - LL1 Scale (PostScript-Accurate)
    
    /// LL1 scale: First log-log scale with exact PostScript subsections
    ///
    /// **PostScript Reference:** Lines 915-922 in postscript-engine-for-sliderules.ps
    /// ```postscript
    /// /LL1scale 32 dict dup 3 1 roll def begin
    ///     /plabel 0 {} NumFont1 MedF /Ntop load scaleLvars def
    ///     (LL1) 1 1.010 1.105  10000 {ln 100 mul log} gradsizes scalevars
    ///     /subsections [
    ///     1.010 [.005 .001 .0005 .0001] [plabel] scaleSvars
    ///     1.020 [.010 .005 .0010 .0002] [plabel] scaleSvars
    ///     1.050 [.010 .005 .0010 .0005] [plabel] scaleSvars
    ///     1.060 [.010 .005 .0010 .0005] [plabel] scaleSvars
    ///     ] def
    /// end
    /// ```
    ///
    /// **Formula:** log₁₀(ln(x) × 100)
    /// **Range:** 1.010 (e^0.01) to 1.105 (e^0.1)
    /// **Physical Range:** Represents e^(x/100) where x is shown on D scale
    /// **Used for:** very-small-exponentials, micro-growth, ultra-fine-compound-interest
    ///
    /// **Physical Applications:**
    /// - Finance: Daily compound interest at very small rates (< 0.1%)
    /// - Chemical kinetics: Initial reaction rates at trace concentrations
    /// - Semiconductor physics: Ultra-low-temperature thermal effects
    /// - Radioactive decay: Very long half-life isotopes (geological timescales)
    /// - Precision optics: Small angle approximations near paraxial limit
    /// - Atmospheric science: Trace gas concentration changes
    ///
    /// **Example 1:** Calculate 1.05^7 (weekly compound growth)
    /// 1. Locate 1.05 on LL1 scale
    /// 2. Set C:1 to cursor position on D scale
    /// 3. Move cursor to C:7
    /// 4. Read result ≈ 1.41 on LL2 scale (crosses to next scale)
    /// 5. Demonstrates: (1.05)^7 = 1.407
    ///
    /// **Example 2:** Find e^0.025 for 2.5% continuous growth
    /// 1. Cursor to 2.5 on D scale
    /// 2. Read value on LL1 scale ≈ 1.0253
    /// 3. Result: e^0.025 = 1.0253
    /// 4. Used in actuarial and annuity calculations
    ///
    /// **Example 3:** Calculate half-life decay over 100 years
    /// 1. For element with 10,000-year half-life
    /// 2. Fraction remaining = e^(-100 × ln(2)/10000)
    /// 3. Use LL1/LL01 reciprocal relationship
    /// 4. Find 0.993 on LL01 (negative scale)
    ///
    /// **Tick Pattern Explanation:**
    /// - **1.010-1.020:** Very dense (0.001 minor) for precision near scale start
    /// - **1.020-1.050:** Moderate density as function spreads
    /// - **1.050-1.105:** Coarser ticks (0.005 fine) as function spacing increases
    ///
    /// **POSTSCRIPT CONCORDANCE:**
    /// | PostScript Subsection | Swift Implementation |
    /// |----------------------|---------------------|
    /// | 1.010 [.005 .001 .0005 .0001] | tickIntervals: [0.005, 0.001, 0.0005, 0.0001] |
    /// | 1.020 [.010 .005 .0010 .0002] | tickIntervals: [0.010, 0.005, 0.001, 0.0002] |
    /// | 1.050 [.010 .005 .0010 .0005] | tickIntervals: [0.010, 0.005, 0.001, 0.0005] |
    /// | 1.060 [.010 .005 .0010 .0005] | tickIntervals: [0.010, 0.005, 0.001, 0.0005] |
    public static func ll1Scale_PostScriptAccurate(length: Distance = 250.0) -> ScaleDefinition {
        // PostScript formula: {ln 100 mul log}
        // Meaning: log₁₀(ln(x) × 100)
        let ll1Function = CustomFunction(
            name: "LL1-PostScript",
            transform: { value in
                log10(log(value) * 100.0)
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed) / 100.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL1")
            .withFunction(ll1Function)
            .withRange(begin: 1.010, end: 1.105)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // PostScript: 1.010 [.005 .001 .0005 .0001] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.010,
                    tickIntervals: [0.005, 0.001, 0.0005, 0.0001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // PostScript: 1.020 [.010 .005 .0010 .0002] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.020,
                    tickIntervals: [0.010, 0.005, 0.001, 0.0002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // PostScript: 1.050 [.010 .005 .0010 .0005] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.050,
                    tickIntervals: [0.010, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // PostScript: 1.060 [.010 .005 .0010 .0005] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.060,
                    tickIntervals: [0.010, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                )
            ])
            .build()
    }
    
    // MARK: - LL2 Scale (PostScript-Accurate)
    
    /// LL2 scale: Second log-log scale with exact PostScript subsections
    ///
    /// **PostScript Reference:** Lines 925-933 in postscript-engine-for-sliderules.ps
    /// ```postscript
    /// /LL2scale 32 dict dup 3 1 roll def begin
    ///     /plabel1 1 {} NumFont1 MedF /Ntop load scaleLvars def
    ///     /plabel 0 {} NumFont1 MedF /Ntop load scaleLvars def
    ///     (LL2) 1 1.105 2.7 1000 {ln 10 mul log} gradsizes scalevars
    ///     /subsections [
    ///     1.105 [null null .001 null] [plabel1] scaleSvars
    ///     1.106 [.05 .01 .005 .001] [plabel1] scaleSvars
    ///     1.120 [.05 .01 .005 .001] [plabel] scaleSvars
    ///     1.200 [.05 null .010 .002] [plabel] scaleSvars
    ///     1.400 [.10 .05 .010 .005] [plabel] scaleSvars
    ///     1.800 [.10 null .050 .010] [plabel] scaleSvars
    ///     2.000 [.50 .1 .050 .010] [plabel] scaleSvars
    ///     2.500 [.50 null .100 .020] [plabel] scaleSvars
    ///     ] def
    ///     /constants [
    ///     {1} NumFont1 SmallF (e) ticklength 0 get /Ntop scaleCvars
    ///     ] def
    /// end
    /// ```
    ///
    /// **Formula:** log₁₀(ln(x) × 10)
    /// **Range:** 1.105 (e^0.1) to 2.7 (e^1)
    /// **Physical Range:** Represents e^(x/10) where x is shown on D scale
    /// **Used for:** small-exponentials, moderate-growth, standard-compound-interest
    ///
    /// **Physical Applications:**
    /// - Biology: Bacterial growth in lag phase (0.1-1 doubling times)
    /// - Finance: Monthly compound interest (typical credit card rates)
    /// - Nuclear medicine: Short half-life radionuclides (hours to days)
    /// - Thermodynamics: Moderate temperature decay (cooling curves)
    /// - RC circuits: Capacitor charge/discharge over 0.1-1 time constants
    /// - Population dynamics: Small population fluctuations
    ///
    /// **Example 1:** Calculate 1.5^3 using LL2 scale
    /// 1. Locate 1.5 on LL2 scale
    /// 2. Set left C index to cursor
    /// 3. Move cursor to 3 on C scale
    /// 4. Read result ≈ 3.375 on LL2 scale (crosses to LL3 if needed)
    /// 5. Exact: (1.5)^3 = 3.375
    ///
    /// **Example 2:** Find e^0.5 (square root of e)
    /// 1. Cursor to 5 on D scale (representing 0.5 when scale is ×10)
    /// 2. Read ≈ 1.649 on LL2 scale
    /// 3. Result: e^0.5 = √e = 1.6487
    /// 4. Used in statistical confidence intervals
    ///
    /// **Example 3:** Population doubling time
    /// 1. Growth rate r = 0.07 per year (7%)
    /// 2. Time to double: t = ln(2)/r ≈ 10 years
    /// 3. Use LL2 to verify: e^(0.07×10) = e^0.7 ≈ 2.01
    /// 4. Cross-check with C/D: 1.07^10 ≈ 1.97 (discrete compounding)
    ///
    /// **Example 4:** RC time constant
    /// 1. Voltage after 1τ: V = V₀ × e^(-1) ≈ 0.368 × V₀
    /// 2. Find e^(-1) on LL02 (reciprocal scale)
    /// 3. Or calculate V remaining: 36.8%
    ///
    /// **Tick Pattern Explanation:**
    /// - **1.105-1.106:** Transition zone from LL1, very fine (0.001)
    /// - **1.106-1.200:** Dense region near e^0.1, small intervals
    /// - **1.200-1.800:** Moderate density as function spreads
    /// - **1.800-2.700:** Coarsest ticks approaching e (largest intervals)
    /// - **Special:** e = 2.71828 marked as constant
    ///
    /// **POSTSCRIPT CONCORDANCE:**
    /// | PostScript Subsection | Swift Implementation | Notes |
    /// |----------------------|---------------------|-------|
    /// | 1.105 [null null .001 null] | tickIntervals: [0.001] (only fine) | Transition from LL1 |
    /// | 1.106 [.05 .01 .005 .001] | tickIntervals: [0.05, 0.01, 0.005, 0.001] | Full density |
    /// | 1.120 [.05 .01 .005 .001] | tickIntervals: [0.05, 0.01, 0.005, 0.001] | Continues density |
    /// | 1.200 [.05 null .010 .002] | tickIntervals: [0.05, 0.01, 0.002] (skip medium) | Slight reduction |
    /// | 1.400 [.10 .05 .010 .005] | tickIntervals: [0.10, 0.05, 0.01, 0.005] | More spread |
    /// | 1.800 [.10 null .050 .010] | tickIntervals: [0.10, 0.05, 0.01] (skip medium) | Near e |
    /// | 2.000 [.50 .1 .050 .010] | tickIntervals: [0.50, 0.1, 0.05, 0.01] | Approaching e |
    /// | 2.500 [.50 null .100 .020] | tickIntervals: [0.50, 0.10, 0.02] (skip medium) | Past e |
    public static func ll2Scale_PostScriptAccurate(length: Distance = 250.0) -> ScaleDefinition {
        // PostScript formula: {ln 10 mul log}
        // Meaning: log₁₀(ln(x) × 10)
        let ll2Function = CustomFunction(
            name: "LL2-PostScript",
            transform: { value in
                log10(log(value) * 10.0)
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed) / 10.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL2")
            .withFunction(ll2Function)
            .withRange(begin: 1.105, end: 2.7)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // PostScript: 1.105 [null null .001 null] [plabel1] scaleSvars
                // Note: Only fine ticks at transition point
                ScaleSubsection(
                    startValue: 1.105,
                    tickIntervals: [0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // PostScript: 1.106 [.05 .01 .005 .001] [plabel1] scaleSvars
                ScaleSubsection(
                    startValue: 1.106,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // PostScript: 1.120 [.05 .01 .005 .001] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.120,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // PostScript: 1.200 [.05 null .010 .002] [plabel] scaleSvars
                // Note: Skips medium tick (null in second position)
                ScaleSubsection(
                    startValue: 1.200,
                    tickIntervals: [0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 1.400 [.10 .05 .010 .005] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.400,
                    tickIntervals: [0.10, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 1.800 [.10 null .050 .010] [plabel] scaleSvars
                // Note: Skips medium tick
                ScaleSubsection(
                    startValue: 1.800,
                    tickIntervals: [0.10, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 2.000 [.50 .1 .050 .010] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 2.000,
                    tickIntervals: [0.50, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 2.500 [.50 null .100 .020] [plabel] scaleSvars
                // Note: Skips medium tick
                ScaleSubsection(
                    startValue: 2.500,
                    tickIntervals: [0.50, 0.10, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .addConstant(value: .e, label: "e", style: .major)
            .build()
    }
    
    // MARK: - LL2B Scale (Extended Range)
    
    /// LL2B scale: Extended log-log scale referenced to A/B scales
    ///
    /// **PostScript Reference:** Lines 936-959 in postscript-engine-for-sliderules.ps
    /// ```postscript
    /// /LL2Bscale 32 dict dup 3 1 roll def begin
    ///     /plabel0 0 {dup dup cvi sub abs .001 lt {.5 add cvi}if} NumFont1 SmallF /Ntop load scaleLvars def
    ///     (LL2) 1 1.106 20000 1000 {ln 10 mul log 2 div} gradsizes scalevars
    ///     /subsections [
    ///     1.106 [ .1 .05 .01 .002] [] scaleSvars
    ///     1.11 [ .01 null null .002] [plabel0] scaleSvars
    ///     1.12 [ .05 null .01 .002] [plabel0] scaleSvars
    ///     1.2 [ .1 .05 .01 .005] [plabel0] scaleSvars
    ///     1.4 [.1 null .05 .010] [plabel0] scaleSvars
    ///     1.800 [.10 null null .020] [plabel0] scaleSvars
    ///     1.900 [.10 null .050 .020] [] scaleSvars
    ///     2.000 [.5 null .10 .020] [plabel0] scaleSvars
    ///     2.500 [.50 null .100 .050] [plabel0] scaleSvars
    ///     3 [1 null .100 .050] [plabel0] scaleSvars
    ///     4 [1 null .5 .1] [plabel0] scaleSvars
    ///     6 [1 null null .2] [plabel0] scaleSvars
    ///     7 [5 null null .2] [plabel0] scaleSvars
    ///     10 [10 5 1 .5] [plabel0] scaleSvars
    ///     20 [10 null null 2] [plabel0] scaleSvars
    ///     30 [null null 10 2] [] scaleSvars
    ///     50 [50 null 10 5] [plabel0] scaleSvars
    ///     100 [100 null null 20] [plabel0] scaleSvars
    ///     300 [500 null null 20] [plabel0] scaleSvars
    ///     500 [500 null null 100] [plabel0] scaleSvars
    ///     1000 [1000 null null 200] [plabel0] scaleSvars
    ///     2000 [null null 1000 200] [] scaleSvars
    ///     3000 [null null 1000 500] [] scaleSvars
    ///     5000 [5000 null null 1000] [] scaleSvars
    ///     10000 [10000 null null 2000] [plabel0] scaleSvars
    ///     20000 [10000 null null 2000] [] scaleSvars
    ///     ] def
    /// end
    /// ```
    ///
    /// **Formula:** log₁₀(ln(x) × 10) / 2
    /// **Range:** 1.106 (e^0.1) to 20,000 (e^9.9)
    /// **Physical Range:** Referenced to A/B scales (square scales) for combined operations
    /// **Used for:** extended-power-range, combined-square-operations, bridge-calculations
    ///
    /// **Physical Applications:**
    /// - Material science: Wide-range stress-strain curves with power-law behavior
    /// - Astrophysics: Luminosity-distance relationships spanning orders of magnitude
    /// - Seismology: Earthquake magnitude scales (Richter, moment magnitude)
    /// - Chemistry: Reaction rates spanning pico- to millisecond timescales
    /// - Electronics: Wide dynamic range amplifier gain calculations (dB to linear)
    /// - Optics: Neutral density filter stacking (multiple orders of magnitude)
    ///
    /// **Why "2 div" (Division by 2)?**
    /// The "/2" factor references this scale to the A/B scales, which represent x²:
    /// - A/B scales use: log₁₀(x²) = 2 × log₁₀(x)
    /// - LL2B compensates: log₁₀(ln(x) × 10) / 2
    /// - Allows direct power operations combining squares and exponentials
    ///
    /// **Example 1:** Calculate x² × e^y combined operation
    /// 1. Use A scale for x² result
    /// 2. Use LL2B scale aligned with A/B for e^y
    /// 3. Combined result on D scale
    /// 4. Saves multiple alignment steps
    ///
    /// **Example 2:** Bridge from LL2 to LL3 range
    /// 1. LL2B extends from e^0.1 to e^9.9 (continuous coverage)
    /// 2. Overlaps both LL2 (up to e^1) and LL3 (e^1 to e^10)
    /// 3. Provides seamless interpolation across decades
    ///
    /// **Example 3:** Earthquake magnitude calculation
    /// 1. Energy E proportional to 10^(1.5M) where M is magnitude
    /// 2. For M6 to M9 range: factor of 10^4.5 ≈ 31,623
    /// 3. LL2B accommodates this wide range on single scale
    /// 4. Used with A scale for amplitude-energy conversion
    ///
    /// **Example 4:** Chemical kinetics across timescales
    /// 1. Reaction rates from 10^-12 s (femtochemistry) to 1 s
    /// 2. Range factor: 10^12 = e^27.6
    /// 3. LL2B provides logarithmic spacing for decades-spanning processes
    ///
    /// **Tick Pattern Explanation:**
    /// - **1.106-3:** Fine subdivision similar to LL2 (small exponent range)
    /// - **3-10:** Moderate intervals as values increase
    /// - **10-100:** Coarser ticks (major at 10, 20, 50, 100)
    /// - **100-1000:** Decades marked with intermediate points
    /// - **1000-20000:** Sparse labeling, major decades only
    ///
    /// **Special Features:**
    /// - **26 subsections:** Most detailed subdivision of any log-log scale
    /// - **Continuous coverage:** Bridges LL2 and LL3 ranges completely
    /// - **A/B compatibility:** Direct alignment with square scales
    /// - **Wide dynamic range:** Nearly 10 orders of magnitude (e^0.1 to e^10)
    ///
    /// **POSTSCRIPT CONCORDANCE (Selected Subsections):**
    /// | PostScript Subsection | Swift Implementation | Coverage |
    /// |----------------------|---------------------|----------|
    /// | 1.106 [.1 .05 .01 .002] | tickIntervals: [0.1, 0.05, 0.01, 0.002] | e^0.1 start |
    /// | 1.2 [.1 .05 .01 .005] | tickIntervals: [0.1, 0.05, 0.01, 0.005] | Low range |
    /// | 3 [1 null .100 .050] | tickIntervals: [1.0, 0.1, 0.05] | Mid range |
    /// | 10 [10 5 1 .5] | tickIntervals: [10.0, 5.0, 1.0, 0.5] | e^2.3 |
    /// | 100 [100 null null 20] | tickIntervals: [100.0, 20.0] | e^4.6 |
    /// | 1000 [1000 null null 200] | tickIntervals: [1000.0, 200.0] | e^6.9 |
    /// | 10000 [10000 null null 2000] | tickIntervals: [10000.0, 2000.0] | e^9.2 |
    public static func ll2BScale_PostScriptAccurate(length: Distance = 250.0) -> ScaleDefinition {
        // PostScript formula: {ln 10 mul log 2 div}
        // Meaning: log₁₀(ln(x) × 10) / 2
        // The division by 2 references this to A/B scales
        let ll2BFunction = CustomFunction(
            name: "LL2B-PostScript",
            transform: { value in
                log10(log(value) * 10.0) / 2.0
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed * 2.0) / 10.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL2B")
            .withFunction(ll2BFunction)
            .withRange(begin: 1.106, end: 20000.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Note: This is a VERY detailed scale with 26 subsections!
                // PostScript: 1.106 [ .1 .05 .01 .002] [] scaleSvars
                ScaleSubsection(
                    startValue: 1.106,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: []
                ),
                // PostScript: 1.11 [ .01 null null .002] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.11,
                    tickIntervals: [0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // PostScript: 1.12 [ .05 null .01 .002] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.12,
                    tickIntervals: [0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // PostScript: 1.2 [ .1 .05 .01 .005] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.2,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 1.4 [.1 null .05 .010] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.4,
                    tickIntervals: [0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 1.800 [.10 null null .020] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.800,
                    tickIntervals: [0.10, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 1.900 [.10 null .050 .020] [] scaleSvars
                ScaleSubsection(
                    startValue: 1.900,
                    tickIntervals: [0.10, 0.05, 0.02],
                    labelLevels: []
                ),
                // PostScript: 2.000 [.5 null .10 .020] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 2.000,
                    tickIntervals: [0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 2.500 [.50 null .100 .050] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 2.500,
                    tickIntervals: [0.50, 0.10, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // PostScript: 3 [1 null .100 .050] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 3.0,
                    tickIntervals: [1.0, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 4 [1 null .5 .1] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 6 [1 null null .2] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 7 [5 null null .2] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 7.0,
                    tickIntervals: [5.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 10 [10 5 1 .5] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 20 [10 null null 2] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 30 [null null 10 2] [] scaleSvars
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 2.0],
                    labelLevels: []
                ),
                // PostScript: 50 [50 null 10 5] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [50.0, 10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 100 [100 null null 20] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 20.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 300 [500 null null 20] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 300.0,
                    tickIntervals: [500.0, 20.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 500 [500 null null 100] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 500.0,
                    tickIntervals: [500.0, 100.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 1000 [1000 null null 200] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 200.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 2000 [null null 1000 200] [] scaleSvars
                ScaleSubsection(
                    startValue: 2000.0,
                    tickIntervals: [1000.0, 200.0],
                    labelLevels: []
                ),
                // PostScript: 3000 [null null 1000 500] [] scaleSvars
                ScaleSubsection(
                    startValue: 3000.0,
                    tickIntervals: [1000.0, 500.0],
                    labelLevels: []
                ),
                // PostScript: 5000 [5000 null null 1000] [] scaleSvars
                ScaleSubsection(
                    startValue: 5000.0,
                    tickIntervals: [5000.0, 1000.0],
                    labelLevels: []
                ),
                // PostScript: 10000 [10000 null null 2000] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 10000.0,
                    tickIntervals: [10000.0, 2000.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 20000 [10000 null null 2000] [] scaleSvars
                ScaleSubsection(
                    startValue: 20000.0,
                    tickIntervals: [10000.0, 2000.0],
                    labelLevels: []
                )
            ])
            .build()
    }
    
    // MARK: - LL3 Scale (PostScript-Accurate)
    
    /// LL3 scale: Base log-log scale with exact PostScript subsections
    ///
    /// **PostScript Reference:** Lines 962-983 in postscript-engine-for-sliderules.ps
    /// ```postscript
    /// /LL3scale 32 dict dup 3 1 roll def begin
    ///     /plabel 0 {.5 add cvi} NumFont1 MedF /Ntop load scaleLvars def
    ///     (LL3) 1 2.74 21000 100 {ln log} gradsizes scalevars
    ///     /subsections [
    ///     2.6 [1 .5 .1 .02] [plabel] scaleSvars
    ///     4 [1 .5 .1 .05] [plabel] scaleSvars
    ///     6 [1 null .5 .1] [plabel] scaleSvars
    ///     10 [5 null 1 .2] [plabel] scaleSvars
    ///     15 [5 null 1 .5] [plabel] scaleSvars
    ///     20 [10 5 1 .5] [plabel] scaleSvars
    ///     30 [10 null 5 1] [plabel] scaleSvars
    ///     50 [50 null 10 2] [plabel] scaleSvars
    ///     100 [100 50 10 5] [plabel] scaleSvars
    ///     200 [200 100 50 10] [plabel] scaleSvars
    ///     500 [500 null 100 50] [plabel] scaleSvars
    ///     1000 [1000 null 500 100] [plabel] scaleSvars
    ///     2000 [2000 null 1000 200] [plabel] scaleSvars
    ///     4000 [5000 null 1000 200] [plabel] scaleSvars
    ///     5000 [5000 null 1000 500] [plabel] scaleSvars
    ///     10000 [10000 null 5000 1000] [plabel] scaleSvars
    ///     ] def
    ///     /constants [
    ///     {0} NumFont1 SmallF (e) ticklength 0 get /Ntop scaleCvars
    ///     {1} NumFont1 SmallF () ticklength 2 get /Ncent scaleCvars
    ///     ] def
    /// end
    /// ```
    ///
    /// **Formula:** log₁₀(ln(x))
    /// **Range:** 2.74 (e¹) to 21,000 (e^10)
    /// **Physical Range:** Represents e^x where x is shown on D scale
    /// **Used for:** large-exponentials, arbitrary-powers, wide-range-decay, extreme-growth
    ///
    /// **Physical Applications:**
    /// - Nuclear physics: Decay chains and accumulation over many half-lives
    /// - Astronomy: Stellar luminosity L ∝ M^3.5 for main-sequence stars
    /// - Finance: Long-term compound growth (decades to centuries)
    /// - Epidemiology: Disease spread during exponential phase (R₀ > 1)
    /// - Chemistry: High-temperature reaction rates (Arrhenius equation)
    /// - Astrophysics: Cosmic ray energy spectrum (power-law distributions)
    ///
    /// **Example 1:** Calculate 2^10 = 1024
    /// 1. Locate 2 on LL3 scale (actually on LL2, since 2 = e^0.693)
    /// 2. For 2 on LL2: set left C index to cursor
    /// 3. Move cursor to 10 on C scale
    /// 4. Read result on LL3 ≈ 1024
    /// 5. Demonstrates decade-spanning power calculation
    ///
    /// **Example 2:** Calculate e^5 for 5 time constants
    /// 1. Cursor to 5 on D scale
    /// 2. Read directly on LL3 scale ≈ 148.4
    /// 3. Result: e^5 = 148.413
    /// 4. Used in RC discharge: V = V₀ × e^(-5) ≈ 0.67% remains
    ///
    /// **Example 3:** Stellar mass-luminosity relation
    /// 1. For star with 10 solar masses
    /// 2. L ∝ M^3.5, so L/L☉ = 10^3.5 ≈ 3162
    /// 3. Using LL3 with fractional powers: 10^3.5 = e^(3.5 × ln(10))
    /// 4. Calculate ln(10) ≈ 2.303, then 3.5 × 2.303 ≈ 8.06
    /// 5. Find e^8.06 ≈ 3160 on LL3 scale
    ///
    /// **Example 4:** Radioactive decay over 10 half-lives
    /// 1. After 10 half-lives: N/N₀ = (1/2)^10 = 1/1024
    /// 2. Reciprocal on LL03 scale: find 1024 position
    /// 3. Remaining fraction: 0.000977 or 0.0977%
    ///
    /// **Example 5:** Compound interest over 50 years at 5%
    /// 1. A = P × (1.05)^50
    /// 2. Using LL scales: 1.05 is on LL1
    /// 3. Raise to 50th power crosses to LL3
    /// 4. Result: 1.05^50 ≈ 11.47
    /// 5. $1000 grows to $11,470
    ///
    /// **Tick Pattern Explanation:**
    /// - **2.6-6:** Fine subdivision near e (ticks every 0.1)
    /// - **6-20:** Moderate intervals (ticks every 1)
    /// - **20-100:** Decade marks with intermediate 5's
    /// - **100-1000:** Coarse intervals (every 100)
    /// - **1000-21000:** Sparse marking (every 1000-5000)
    /// - **Special:** e = 2.71828 marked at position 0
    ///
    /// **Constants:**
    /// - **e (2.71828):** Marked at natural position (offset 0 from scale start)
    /// - **e² (7.389):** Not explicitly marked but at position 1.0 on scale
    /// - **e³ (20.09):** Near decade mark at 20
    ///
    /// **POSTSCRIPT CONCORDANCE:**
    /// | PostScript Subsection | Swift Implementation | Decade |
    /// |----------------------|---------------------|--------|
    /// | 2.6 [1 .5 .1 .02] | tickIntervals: [1.0, 0.5, 0.1, 0.02] | e¹ |
    /// | 4 [1 .5 .1 .05] | tickIntervals: [1.0, 0.5, 0.1, 0.05] | e^1.4 |
    /// | 6 [1 null .5 .1] | tickIntervals: [1.0, 0.5, 0.1] | e^1.8 |
    /// | 10 [5 null 1 .2] | tickIntervals: [5.0, 1.0, 0.2] | e^2.3 |
    /// | 20 [10 5 1 .5] | tickIntervals: [10.0, 5.0, 1.0, 0.5] | e^3.0 |
    /// | 50 [50 null 10 2] | tickIntervals: [50.0, 10.0, 2.0] | e^3.9 |
    /// | 100 [100 50 10 5] | tickIntervals: [100.0, 50.0, 10.0, 5.0] | e^4.6 |
    /// | 500 [500 null 100 50] | tickIntervals: [500.0, 100.0, 50.0] | e^6.2 |
    /// | 1000 [1000 null 500 100] | tickIntervals: [1000.0, 500.0, 100.0] | e^6.9 |
    /// | 5000 [5000 null 1000 500] | tickIntervals: [5000.0, 1000.0, 500.0] | e^8.5 |
    /// | 10000 [10000 null 5000 1000] | tickIntervals: [10000.0, 5000.0, 1000.0] | e^9.2 |
    public static func ll3Scale_PostScriptAccurate(length: Distance = 250.0) -> ScaleDefinition {
        // PostScript formula: {ln log}
        // Meaning: log₁₀(ln(x))
        let ll3Function = CustomFunction(
            name: "LL3-PostScript",
            transform: { value in
                log10(log(value))
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed))
            }
        )
        
        return ScaleBuilder()
            .withName("LL3")
            .withFunction(ll3Function)
            .withRange(begin: 2.74, end: 21000.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // PostScript: 2.6 [1 .5 .1 .02] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 2.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 4 [1 .5 .1 .05] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 6 [1 null .5 .1] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 10 [5 null 1 .2] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 15 [5 null 1 .5] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 15.0,
                    tickIntervals: [5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 20 [10 5 1 .5] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 30 [10 null 5 1] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 5.0, 1.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 50 [50 null 10 2] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [50.0, 10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 100 [100 50 10 5] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 200 [200 100 50 10] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 200.0,
                    tickIntervals: [200.0, 100.0, 50.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 500 [500 null 100 50] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 500.0,
                    tickIntervals: [500.0, 100.0, 50.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 1000 [1000 null 500 100] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 500.0, 100.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 2000 [2000 null 1000 200] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 2000.0,
                    tickIntervals: [2000.0, 1000.0, 200.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 4000 [5000 null 1000 200] [plabel] scaleSvars
                // Note: Major tick is 5000 even though subsection starts at 4000
                ScaleSubsection(
                    startValue: 4000.0,
                    tickIntervals: [5000.0, 1000.0, 200.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 5000 [5000 null 1000 500] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 5000.0,
                    tickIntervals: [5000.0, 1000.0, 500.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // PostScript: 10000 [10000 null 5000 1000] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 10000.0,
                    tickIntervals: [10000.0, 5000.0, 1000.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .addConstant(value: .e, label: "e", style: .major)
            .build()
    }
    
    // From the LogLog-LogLadyScales
    
    // MARK: - LL3 Scale (Base Scale)
    
    /// LL3 scale: Base log-log scale with exact PostScript subsections
    ///
    /// **PostScript Reference:** Lines 1419-1442 in postscript-engine-for-sliderules.ps
    /// **Formula:** {ln log} → log₁₀(ln(x)) where x = e^y
    /// **Range:** 2.74 (≈e^1.0) to 21,000 (≈e^10)
    /// **Physical Applications:** Power calculations, exponential growth, compound interest
    ///
    /// **COMPLETE SUBSECTION STRATEGY:**
    /// This implementation includes ALL 17 PostScript subsections for perfect fidelity.
    /// Some subsections provide only tick marks (no labels) for visual guidance.
    ///
    /// **POSTSCRIPT LINE REFERENCES:**
    /// - Scale definition: Line 1419
    /// - Subsections 1-17: Lines 1426-1442
    public static func ll3Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(ln(x))
        // This maps e^x to position on the scale
        let ll3Function = CustomFunction(
            name: "LL3-scale",
            transform: { value in
                log10(log(value))  // log₁₀(ln(x))
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed))  // e^(10^t)
            }
        )
        
        return ScaleBuilder()
            .withName("LL3")
            .withFunction(ll3Function)
            .withRange(begin: 2.74, end: 21000.0)  // e¹ to e¹⁰
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // PostScript subsection 1: 2.6-4 (line 1426)
                // Very fine divisions for e^1 region where LL3 begins
                // Intervals: [1, .5, .1, .02]
                // CRITICAL: Most precise region, essential for small exponentials
                ScaleSubsection(
                    startValue: 2.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                
                // PostScript subsection 2: 4-6 (line 1427)
                // Slightly coarser as we move away from e
                // Intervals: [1, .5, .1, .05]
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 3: 6-10 (line 1428)
                // Transition to decades
                // Intervals: [1, null, .5, .1]
                // LABEL STRATEGY: Show 6, 7, 8, 9, 10
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 4: 10-15 (line 1429)
                // Lower decades with 5-unit primary intervals
                // Intervals: [5, null, 1, .2]
                // LABEL STRATEGY: Show 10, 15
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 5: 15-20 (line 1430)
                // Mid-decade refinement
                // Intervals: [5, null, 1, .5]
                // LABEL STRATEGY: Show 15, 20
                ScaleSubsection(
                    startValue: 15.0,
                    tickIntervals: [5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 6: 20-30 (line 1431)
                // Decades with half-decade markers
                // Intervals: [10, 5, 1, .5]
                // LABEL STRATEGY: Show 20, 30 (and possibly 25 from secondary)
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 7: 30-50 (line 1432)
                // Wider spacing as function becomes linear
                // Intervals: [10, null, 5, 1]
                // LABEL STRATEGY: Show 30, 40, 50
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 5.0, 1.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 8: 50-100 (line 1433)
                // Transition to hundreds
                // Intervals: [50, null, 10, 2]
                // LABEL STRATEGY: Show 50, 100
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [50.0, 10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 9: 100-200 (line 1434)
                // Hundreds with rich subdivisions
                // Intervals: [100, 50, 10, 5]
                // LABEL STRATEGY: Show 100, 200
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 10: 200-500 (line 1435)
                // Mid-hundreds
                // Intervals: [200, 100, 50, 10]
                // LABEL STRATEGY: Show 200, 400 (from primary), possibly 300 (from secondary)
                ScaleSubsection(
                    startValue: 200.0,
                    tickIntervals: [200.0, 100.0, 50.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 11: 500-1000 (line 1436)
                // Upper hundreds
                // Intervals: [500, 100, 50]
                // LABEL STRATEGY: Show 500, 1000
                ScaleSubsection(
                    startValue: 500.0,
                    tickIntervals: [500.0, 100.0, 50.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 12: 1000-2000 (line 1437)
                // Thousands
                // Intervals: [1000, 500, 100]
                // LABEL STRATEGY: Show 1000, 2000
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 500.0, 100.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 13: 2000-3000 (line 1438)
                // Mid-thousands without primary labels
                // Intervals: [null, null, 1000, 200]
                // PURPOSE: Provides tick marks only, no labels at 2000 level
                // NOTE: Labels at 2000 come from subsection 12, at 3000 from subsection 14
                ScaleSubsection(
                    startValue: 2000.0,
                    tickIntervals: [1000.0, 200.0],
                    labelLevels: [],  // No labels - boundary markers from adjacent subsections
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 14: 3000-5000 (line 1439)
                // Upper thousands
                // Intervals: [null, null, 1000, 500]
                // PURPOSE: Similar to subsection 13 - tick marks with boundary labels from neighbors
                ScaleSubsection(
                    startValue: 3000.0,
                    tickIntervals: [1000.0, 500.0],
                    labelLevels: [],  // No labels
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 15: 5000-10000 (line 1440)
                // Five-thousand interval
                // Intervals: [5000, null, null, 1000]
                // LABEL STRATEGY: No labels in PostScript ([]) - boundary labels from neighbors
                ScaleSubsection(
                    startValue: 5000.0,
                    tickIntervals: [5000.0, 1000.0],
                    labelLevels: [],  // No labels per PostScript
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 16: 10000-20000 (line 1441)
                // Ten-thousand interval
                // Intervals: [10000, null, null, 2000]
                // LABEL STRATEGY: Show 10000, 20000 (plabel applies)
                ScaleSubsection(
                    startValue: 10000.0,
                    tickIntervals: [10000.0, 2000.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // PostScript subsection 17: 20000+ (line 1442)
                // Endpoint region
                // Intervals: [10000, null, null, 2000]
                // PURPOSE: Provides tick marks approaching 21000 endpoint
                // NOTE: No labels in PostScript ([])
                ScaleSubsection(
                    startValue: 20000.0,
                    tickIntervals: [10000.0, 2000.0],
                    labelLevels: [],  // No labels
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .withConstants([
                ScaleConstant(
                    value: 2.71828,
                    label: "e",
                )
            ])
            .build()
    }
    
    // MARK: - LL2 Scale
    
    /// LL2 scale: Medium-range log-log scale for e^(x/10)
    ///
    /// **Description:** Medium-range log-log scale representing e^(x/10)
    /// **Formula:** log₁₀(ln(x) × 10) = log₁₀(ln(x)) + 1
    /// **Range:** 1.105 (e^0.1) to 2.72 (e¹)
    /// **Used for:** moderate-powers, fractional-exponents, population-models
    ///
    /// **Physical Applications:**
    /// - Biology: Population doubling time calculations
    /// - Pharmacology: Drug concentration decay over hours
    /// - Acoustics: Sound pressure level conversions
    /// - Finance: Daily/monthly compound interest
    /// - Engineering: Gradual decay processes
    ///
    /// **Example 1:** Calculate 1.9^2.5
    /// 1. Rewrite as (1.9^0.25)^10
    /// 2. Locate 1.9 on LL2
    /// 3. Set right C index to cursor
    /// 4. Move cursor to 2.5 on C
    /// 5. Read on LL2, then look up to LL3 for ×10 power
    /// 6. Result ≈ 4.97
    ///
    /// **Example 2:** Bacterial growth: Double every 20 minutes
    /// 1. After 2 hours (6 doublings): 2^6 = 64
    /// 2. Use LL2/LL3 relationship with D scale
    /// 3. Demonstrates biological exponential growth
    ///
    /// **POSTSCRIPT REFERENCES:** Line 925 in postscript-engine-for-sliderules.ps
    public static func ll2Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(ln(x) × 10)
        // The ×10 makes this scale represent e^(x/10)
        let ll2Function = CustomFunction(
            name: "LL2-scale",
            transform: { value in
                log10(log(value) * 10.0)
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed) / 10.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL2")
            .withFunction(ll2Function)
            .withRange(begin: 1.105, end: 2.72)  // e^0.1 to e^1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.105, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 1.5, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.twoDecimals)
            .build()
    }
    
    // MARK: - LL1 Scale
    
    /// LL1 scale: Small-range log-log scale for e^(x/100)
    ///
    /// **Description:** Small-range log-log scale for values very close to 1
    /// **Formula:** log₁₀(ln(x) × 100) = log₁₀(ln(x)) + 2
    /// **Range:** 1.0101 (e^0.01) to 1.105 (e^0.1)
    /// **Used for:** small-powers, precision-calculations, near-unity-exponents
    ///
    /// **Physical Applications:**
    /// - Metrology: Small measurement corrections
    /// - Optics: Thin lens approximations
    /// - Economics: Small percentage changes
    /// - Quality control: Tolerance calculations
    /// - Surveying: Small angle corrections
    ///
    /// **Example:** Calculate 1.04^100
    /// 1. Locate 1.04 on LL1 scale
    /// 2. To raise to power 100, look "two scales up"
    /// 3. Read 50.5 on LL3 scale
    /// 4. Demonstrates power-of-10 scale jumping
    ///
    /// **POSTSCRIPT REFERENCES:** Line 915 in postscript-engine-for-sliderules.ps
    public static func ll1Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(ln(x) × 100)
        let ll1Function = CustomFunction(
            name: "LL1-scale",
            transform: { value in
                log10(log(value) * 100.0)
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed) / 100.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL1")
            .withFunction(ll1Function)
            .withRange(begin: 1.0101, end: 1.105)  // e^0.01 to e^0.1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.01, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 1.05, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .build()
    }
    
    // MARK: - LL0 Scale
    
    /// LL0 scale: Ultra-precision log-log scale for e^(x/1000)
    ///
    /// **Description:** Ultra-precision scale for values extremely close to 1
    /// **Formula:** log₁₀(ln(x) × 1000) = log₁₀(ln(x)) + 3
    /// **Range:** 1.001 (e^0.001) to 1.010 (e^0.01)
    /// **Used for:** high-precision-calculations, small-corrections, micro-adjustments
    ///
    /// **Physical Applications:**
    /// - Precision engineering: Thermal expansion coefficients
    /// - Calibration: Instrument correction factors
    /// - Materials science: Elastic modulus variations
    /// - Astronomy: Parallax corrections
    /// - Geodesy: Earth curvature corrections
    ///
    /// **Example:** Calculate 1.002^1000
    /// 1. Locate 1.002 on LL0 scale
    /// 2. To raise to power 1000, look "three scales up"
    /// 3. Read 7.4 on LL3 scale
    /// 4. Demonstrates the power of scale hierarchy
    ///
    /// **POSTSCRIPT REFERENCES:** Line 905 in postscript-engine-for-sliderules.ps
    public static func ll0Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(ln(x) × 1000)
        let ll0Function = CustomFunction(
            name: "LL0-scale",
            transform: { value in
                log10(log(value) * 1000.0)
            },
            inverseTransform: { transformed in
                exp(pow(10, transformed) / 1000.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL0")
            .withFunction(ll0Function)
            .withRange(begin: 1.001, end: 1.0101)  // e^0.001 to e^0.01
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.001, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 1.005, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .build()
    }
    
    // MARK: - Negative Log-Log Scales (Reciprocal)
    
    /// LL03 scale: Base reciprocal log-log scale for e^(-x)
    ///
    /// **Description:** Reciprocal of LL3, represents e^(-x) for negative powers
    /// **Formula:** log₁₀(-ln(x)) = log₁₀(ln(1/x))
    /// **Range:** 0.368 (e^-1) to 0.00005 (e^-10)
    /// **Used for:** reciprocal-powers, decay-processes, inverse-relationships
    ///
    /// **Physical Applications:**
    /// - Radioactive decay: Activity remaining after n half-lives
    /// - Electrical: Capacitor discharge V = V₀e^(-t/RC)
    /// - Pharmacology: Drug elimination from bloodstream
    /// - Heat transfer: Cooling curves (Newton's law)
    /// - Optics: Light absorption (Beer's law)
    ///
    /// **Example 1:** Calculate 0.75^10
    /// 1. Locate 0.75 on LL02 scale (e^-0.3 range)
    /// 2. Set left C index to cursor
    /// 3. Move cursor to 1 (for power 10, look up scale)
    /// 4. Read 0.056 on LL03
    /// 5. Demonstrates decay/damping calculations
    ///
    /// **Example 2:** RC circuit: Find voltage after 5τ
    /// 1. V(t) = V₀e^(-t/τ), after 5τ: V = V₀e^-5
    /// 2. Locate e^-5 ≈ 0.0067 on LL03
    /// 3. About 0.67% of initial voltage remains
    /// 4. Critical for electronics timing
    ///
    /// **POSTSCRIPT REFERENCES:** Line 785 in postscript-engine-for-sliderules.ps
    public static func ll03Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(-ln(x)) = log₁₀(ln(1/x))
        // For x < 1, this gives positive values
        let ll03Function = CustomFunction(
            name: "LL03-scale",
            transform: { value in
                log10(-log(value))  // log₁₀(-ln(x))
            },
            inverseTransform: { transformed in
                exp(-pow(10, transformed))  // e^(-10^t)
            }
        )
        
        return ScaleBuilder()
            .withName("LL03")
            .withFunction(ll03Function)
            .withRange(begin: 0.00005, end: 0.368)  // e^-10 to e^-1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.00005, tickIntervals: [0.0001, 0.00005, 0.00001, 0.000005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.0001, tickIntervals: [0.0001, 0.00005, 0.00001, 0.000005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.001, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.01, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withConstants([
                ScaleConstant(
                    value: 0.36788,  // 1/e
                    label: "1/e",
                )
            ])
            .build()
    }
    
    // MARK: - LL02 Scale
    
    /// LL02 scale: Medium reciprocal log-log scale for e^(-x/10)
    ///
    /// **Description:** Reciprocal of LL2, medium-range negative powers
    /// **Formula:** log₁₀(-ln(x) × 10)
    /// **Range:** 0.368 (e^-1) to 0.905 (e^-0.1)
    /// **Used for:** moderate-decay, damping-calculations, attenuation
    ///
    /// **Physical Applications:**
    /// - Acoustics: Sound attenuation through materials
    /// - Optics: Filter transmission coefficients
    /// - Mechanical: Damped oscillations
    /// - Economics: Depreciation curves
    /// - Communications: Signal loss in transmission lines
    ///
    /// **Example:** Calculate 0.78^3.4
    /// 1. Locate 0.78 on LL02 scale
    /// 2. Set left C index to cursor
    /// 3. Move cursor to 3.4 on C
    /// 4. Read 0.43 on LL02
    /// 5. Demonstrates fractional negative powers
    ///
    /// **POSTSCRIPT REFERENCES:** Line 772 in postscript-engine-for-sliderules.ps
    public static func ll02Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(-ln(x) × 10)
        let ll02Function = CustomFunction(
            name: "LL02-scale",
            transform: { value in
                log10(-log(value) * 10.0)
            },
            inverseTransform: { transformed in
                exp(-pow(10, transformed) / 10.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL02")
            .withFunction(ll02Function)
            .withRange(begin: 0.368, end: 0.905)  // e^-1 to e^-0.1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.37, tickIntervals: [0.05, 0.02, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.50, tickIntervals: [0.05, 0.02, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.80, tickIntervals: [0.02, 0.01, 0.005, 0.001], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withConstants([
                ScaleConstant(
                    value: 0.36788,  // 1/e at left edge
                    label: "1/e",
                )
            ])
            .build()
    }
    
    // MARK: - LL01 Scale
    
    /// LL01 scale: Small reciprocal log-log scale for e^(-x/100)
    ///
    /// **Description:** Reciprocal of LL1, small negative powers
    /// **Formula:** log₁₀(-ln(x) × 100)
    /// **Range:** 0.905 (e^-0.1) to 0.990 (e^-0.01)
    /// **Used for:** small-decay, precision-attenuation, quality-factors
    ///
    /// **Physical Applications:**
    /// - Materials: Low-loss dielectrics
    /// - Optics: High-transmission filters
    /// - RF engineering: Cable loss calculations
    /// - Precision: Small correction factors
    ///
    /// **Example:** Calculate 0.99^560
    /// 1. Rewrite as (0.99^5.6)^100
    /// 2. Locate 0.99 on LL01
    /// 3. Use C scale for power 5.6
    /// 4. Look "two scales down" to LL03
    /// 5. Read 0.0036
    ///
    /// **POSTSCRIPT REFERENCES:** Line 740 in postscript-engine-for-sliderules.ps
    public static func ll01Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(-ln(x) × 100)
        let ll01Function = CustomFunction(
            name: "LL01-scale",
            transform: { value in
                log10(-log(value) * 100.0)
            },
            inverseTransform: { transformed in
                exp(-pow(10, transformed) / 100.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL01")
            .withFunction(ll01Function)
            .withRange(begin: 0.905, end: 0.990)  // e^-0.1 to e^-0.01
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.90, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.95, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.98, tickIntervals: [0.005, 0.001, 0.0005, 0.0001], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .build()
    }
    
    // MARK: - LL00 Scale
    
    /// LL00 scale: Ultra-precision reciprocal log-log scale for e^(-x/1000)
    ///
    /// **Description:** Reciprocal of LL0, ultra-precision negative powers
    /// **Formula:** log₁₀(-ln(x) × 1000)
    /// **Range:** 0.990 (e^-0.01) to 0.999 (e^-0.001)
    /// **Used for:** ultra-precision-decay, micro-corrections, quality-factors
    ///
    /// **Physical Applications:**
    /// - High-Q resonators: Quality factor calculations
    /// - Precision optics: Anti-reflection coating optimization
    /// - Materials science: Ultra-low-loss materials
    /// - Metrology: High-precision calibrations
    ///
    /// **POSTSCRIPT REFERENCES:** Line 730 in postscript-engine-for-sliderules.ps
    public static func ll00Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(-ln(x) × 1000)
        let ll00Function = CustomFunction(
            name: "LL00-scale",
            transform: { value in
                log10(-log(value) * 1000.0)
            },
            inverseTransform: { transformed in
                exp(-pow(10, transformed) / 1000.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL00")
            .withFunction(ll00Function)
            .withRange(begin: 0.990, end: 0.999)  // e^-0.01 to e^-0.001
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.990, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.995, tickIntervals: [0.001, 0.0005, 0.0001, 0.00002], labelLevels: [0]),
                ScaleSubsection(startValue: 0.998, tickIntervals: [0.0005, 0.0001, 0.00005, 0.00001], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .build()
    }
    
    // MARK: - Special Variant Scales
    
    /// LL02B scale: Combined LL02/LL03 scale referenced to A/B scales
    ///
    /// **Description:** Extended negative scale referenced to A/B (square) scales
    /// **Formula:** log₁₀(-ln(x) × 10) / 2 (half-length compression)
    /// **Range:** 0.00005 (e^-10) to 0.904 (e^-0.1)
    /// **Used for:** square-root-relationships, combined-calculations, space-saving
    ///
    /// **Physical Applications:**
    /// - Combines functionality of LL02 and LL03 in one scale
    /// - Space-efficient slide rule designs (Hemmi 266)
    /// - Allows direct reading with A/B scales
    /// - Used in compact professional rules
    ///
    /// **Note:** This scale compresses two decades into the space of one by
    /// referencing to A/B scales (which are themselves compressed by factor of 2)
    ///
    /// **POSTSCRIPT REFERENCES:** Line 758 in postscript-engine-for-sliderules.ps
    public static func ll02BScale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(-ln(x) × 10) / 2
        // The "/ 2" references this to A/B scales
        let ll02BFunction = CustomFunction(
            name: "LL02B-scale",
            transform: { value in
                log10(-log(value) * 10.0) / 2.0
            },
            inverseTransform: { transformed in
                exp(-pow(10, transformed * 2.0) / 10.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL02B")
            .withFunction(ll02BFunction)
            .withRange(begin: 0.00005, end: 0.904)  // Extended range
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.00005, tickIntervals: [0.0001, 0.00005, 0.00001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.0001, tickIntervals: [0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.0010, tickIntervals: [0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.01, tickIntervals: [0.01, 0.005, 0.001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.10, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.80, tickIntervals: [0.05, 0.01, 0.002], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .build()
    }
    
    /// LL00B scale (Hemmi 266): Variant of LL00 referenced to A/B scales
    ///
    /// **Description:** Ultra-precision reciprocal scale with A/B reference
    /// **Formula:** log₁₀(-ln(x) × 100) / 2 + 0.5
    /// **Range:** 0.900 (e^-0.105) to 0.999 (e^-0.001)
    /// **Used for:** compact-designs, combined-operations, Hemmi-266-compatibility
    ///
    /// **Note:** The "+0.5" offset aligns this with the A/B scale positioning.
    /// This is a specialized variant found on the Hemmi 266 series.
    ///
    /// **POSTSCRIPT REFERENCES:** Line 717 in postscript-engine-for-sliderules.ps
    public static func ll00BScale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(-ln(x) × 100) / 2 + 0.5
        let ll00BFunction = CustomFunction(
            name: "LL00B-scale",
            transform: { value in
                log10(-log(value) * 100.0) / 2.0 + 0.5
            },
            inverseTransform: { transformed in
                exp(-pow(10, (transformed - 0.5) * 2.0) / 100.0)
            }
        )
        
        return ScaleBuilder()
            .withName("LL00B")
            .withFunction(ll00BFunction)
            .withRange(begin: 0.900, end: 0.999)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.900, tickIntervals: [0.05, 0.01, 0.005, 0.001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.950, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.980, tickIntervals: [0.01, 0.005, 0.001, 0.0002], labelLevels: [0]),
                ScaleSubsection(startValue: 0.990, tickIntervals: [0.005, 0.001, 0.0005, 0.0001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.995, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.998, tickIntervals: [0.0005, 0.0001, 0.00002], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .build()
    }
    
    /// H266LL01 scale: Hemmi 266 variant of LL01 (subset of LL00B)
    ///
    /// **Description:** Subset of LL00B scale used in Hemmi 266 design
    /// **Formula:** Same as LL00B: log₁₀(-ln(x) × 100) / 2 + 0.5
    /// **Range:** 0.90 to 0.99 (truncated from LL00B)
    /// **Used for:** Hemmi-266-specific-layouts, space-optimization
    ///
    /// **Note:** This is essentially LL00B with a truncated range, used
    /// in the Hemmi 266 to create a more compact scale arrangement.
    ///
    /// **POSTSCRIPT REFERENCES:** Line 725 in postscript-engine-for-sliderules.ps
    public static func h266LL01Scale(length: Distance = 250.0) -> ScaleDefinition {
        // This uses the same function as LL00B but with different range
        let ll00BScale = ll00BScale(length: length)
        
        return ScaleDefinition(
            name: "H266LL01",
            function: ll00BScale.function,
            beginValue: 0.90,  // Truncated range
            endValue: 0.99,
            scaleLengthInPoints: length,
            layout: ll00BScale.layout,
            tickDirection: ll00BScale.tickDirection,
            subsections: [
                ScaleSubsection(startValue: 0.900, tickIntervals: [0.05, 0.01, 0.005, 0.001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.950, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.980, tickIntervals: [0.01, 0.005, 0.001, 0.0002], labelLevels: [0])
            ],
            defaultTickStyles: ll00BScale.defaultTickStyles,
            labelFormatter: ll00BScale.labelFormatter,
            labelColor: (red: 1.0, green: 0.0, blue: 0.0),  // Red labels
            constants: []
        )
    }
    
    /// H266LL03 scale: Specialized ultra-small negative power scale
    ///
    /// **Description:** Specialized scale for extremely small values (10^-9 × x range)
    /// **Formula:** log₁₀(ln(x × 10^-9) × -0.1) / 2
    /// **Range:** 1 to 50,000 (representing 10^-9 to 5×10^-5)
    /// **Used for:** nano-scale-calculations, quantum-effects, ultra-precision-work
    ///
    /// **Physical Applications:**
    /// - Nanotechnology: Molecular-scale measurements
    /// - Quantum physics: Probability amplitudes
    /// - Semiconductor: Gate oxide thickness calculations
    /// - Precision metrology: Atomic-scale measurements
    /// - Materials science: Thin film properties
    ///
    /// **Formula Breakdown:**
    /// For input value n (1 to 50,000):
    ///   x = n × 10^-9 (actual represented value)
    ///   transform = log₁₀(ln(x) × -0.1) / 2
    ///
    /// This creates a scale where:
    ///   - 1 represents 10^-9
    ///   - 10 represents 10^-8
    ///   - 100 represents 10^-7
    ///   - 50,000 represents 5×10^-5
    ///
    /// **Label Format:** Labels show as "10^-X" notation
    /// Example: value 1 → "10^-9", value 100 → "10^-7"
    ///
    /// **Example:** Ultra-thin film calculation
    /// 1. Film thickness = 10 nm = 10^-8 m
    /// 2. Locate 10 on H266LL03 scale
    /// 3. Use with other scales for area/volume calculations
    /// 4. Critical for semiconductor manufacturing
    ///
    /// **POSTSCRIPT REFERENCES:** Line 750 in postscript-engine-for-sliderules.ps
    /// PostScript formula: {10 -9 exp mul ln -.1 mul log 2 div}
    public static func h266LL03Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Formula: log₁₀(ln(x × 10^-9) × -0.1) / 2
        // This handles ultra-small values in the 10^-9 range
        let h266LL03Function = CustomFunction(
            name: "H266LL03-scale",
            transform: { value in
                // value represents the scale reading (1 to 50,000)
                // actual physical value is value × 10^-9
                let actualValue = value * 1e-9
                return log10(log(actualValue) * -0.1) / 2.0
            },
            inverseTransform: { transformed in
                // Reverse: from position to scale reading
                let lnValue = pow(10, transformed * 2.0) / -0.1
                let actualValue = exp(lnValue)
                return actualValue / 1e-9  // Convert back to scale units
            }
        )
        
        // Special label formatter for 10^-X notation
        let h266Formatter: LabelFormatter = { value in
            // Calculate the exponent: log₁₀(value × 10^-9)
            let exponent = log10(value * 1e-9)
            let roundedExp = Int(round(exponent))
            
            // Format as "10^-X" but suppress some labels for clarity
            if value < 2 || (value >= 10 && value.truncatingRemainder(dividingBy: 10) == 0) {
                return String(format: "10⁻%d", abs(roundedExp))
            }
            return nil  // Suppress intermediate labels
        }
        
        return ScaleBuilder()
            .withName("H266LL03")
            .withFunction(h266LL03Function)
            .withRange(begin: 1.0, end: 50000.0)  // Scale units, not physical values
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [10.0, 5.0], labelLevels: [0]),
                ScaleSubsection(startValue: 20.0, tickIntervals: [100.0, 50.0, 10.0], labelLevels: [0]),
                ScaleSubsection(startValue: 100.0, tickIntervals: [100.0, 500.0, 100.0], labelLevels: [0]),
                ScaleSubsection(startValue: 200.0, tickIntervals: [1000.0, 500.0, 100.0], labelLevels: [0]),
                ScaleSubsection(startValue: 1000.0, tickIntervals: [1000.0, 5000.0, 1000.0], labelLevels: [0]),
                ScaleSubsection(startValue: 2000.0, tickIntervals: [10000.0, 5000.0, 1000.0], labelLevels: [0]),
                ScaleSubsection(startValue: 10000.0, tickIntervals: [10000.0, 50000.0, 10000.0], labelLevels: [0]),
                ScaleSubsection(startValue: 20000.0, tickIntervals: [100000.0, 50000.0, 10000.0], labelLevels: [0])
            ])
            .withLabelFormatter({ value in h266Formatter(value) ?? "" })
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .build()
    }
    
    
    
}

