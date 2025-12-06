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
                // Cursor Precision: 5 decimals (from 0.0001 quaternary interval)
                // Mathematical: Extreme compression near e^0.01, finest marks for micro-exponential precision
                // Historical: LL1 start required finest precision on K&E rules for daily compound interest calculations
                // PostScript: 1.010 [.005 .001 .0005 .0001] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.010,
                    tickIntervals: [0.005, 0.001, 0.0005, 0.0001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.0002 quaternary interval)
                // Mathematical: Slightly coarser as e^x spacing increases, maintains 4 sig figs at LL1 mid-range
                // Historical: K&E LL1 readable to 0.0005 by experts, matches precision requirements
                // PostScript: 1.020 [.010 .005 .0010 .0002] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.020,
                    tickIntervals: [0.010, 0.005, 0.001, 0.0002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Transitioning toward LL2, 0.0005 intervals maintain precision for fractional powers
                // Historical: Upper LL1 range (1.05-1.06) critical for weekly/monthly compound interest
                // PostScript: 1.050 [.010 .005 .0010 .0005] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.050,
                    tickIntervals: [0.010, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Final LL1 subsection before transition to LL2, maintains consistency
                // Historical: 1.06-1.105 range completes LL1 coverage with uniform precision
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
                // Cursor Precision: 4 decimals (from 0.001 fine interval only)
                // Mathematical: Transition zone from LL1, single fine interval ensures smooth handoff
                // Historical: 1.105 is exact boundary between LL1/LL2, K&E used minimal ticks here
                // PostScript: 1.105 [null null .001 null] [plabel1] scaleSvars
                // Note: Only fine ticks at transition point
                ScaleSubsection(
                    startValue: 1.105,
                    tickIntervals: [0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Full density at LL2 start, 0.001 marks for e^0.1 precision
                // Historical: LL2 beginning required finest marks for fractional exponential accuracy
                // PostScript: 1.106 [.05 .01 .005 .001] [plabel1] scaleSvars
                ScaleSubsection(
                    startValue: 1.106,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Maintains precision as logarithmic compression increases
                // Historical: 1.12-1.20 range critical for small power calculations on K&E LL scales
                // PostScript: 1.120 [.05 .01 .005 .001] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.120,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Slight precision reduction as function spacing increases toward e^0.3
                // Historical: K&E LL2 mid-range (1.2-1.4) readable to 3-4 sig figs
                // PostScript: 1.200 [.05 null .010 .002] [plabel] scaleSvars
                // Note: Skips medium tick (null in second position)
                ScaleSubsection(
                    startValue: 1.200,
                    tickIntervals: [0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Coarser marks as function spreads, approaching e^0.5 region
                // Historical: 1.4-1.8 range transitions toward e, maintains 3 sig fig accuracy
                // PostScript: 1.400 [.10 .05 .010 .005] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1.400,
                    tickIntervals: [0.10, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Near e (2.718), logarithmic spacing widens, 0.01 marks adequate
                // Historical: LL2 near e shows coarsest marks but still 2-3 sig figs per K&E standards
                // PostScript: 1.800 [.10 null .050 .010] [plabel] scaleSvars
                // Note: Skips medium tick
                ScaleSubsection(
                    startValue: 1.800,
                    tickIntervals: [0.10, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Approaching and passing e (2.718), maintains readable precision
                // Historical: 2.0-2.5 includes e constant marker, K&E showed 0.01 readability
                // PostScript: 2.000 [.50 .1 .050 .010] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 2.000,
                    tickIntervals: [0.50, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Past e toward e^1 endpoint, coarsest LL2 marks at 0.02
                // Historical: LL2 upper end (2.5-2.7) transitions to LL3, adequate for power operations
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
            .withFormula("e⁰·¹ˣ/²")
            .withFunction(ll2BFunction)
            .withRange(begin: 1.106, end: 20000.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Note: This is a VERY detailed scale with 26 subsections!
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: LL2B start at e^0.1, divided by 2 for A/B reference, finest precision
                // Historical: LL2B combines LL2+LL3 range, enables square-exponential operations on K&E rules
                // PostScript: 1.106 [ .1 .05 .01 .002] [] scaleSvars
                ScaleSubsection(
                    startValue: 1.106,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: []
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Early LL2B requires fine marks for small exponential precision
                // Historical: 1.11 region critical for fractional powers with A/B scale alignment
                // PostScript: 1.11 [ .01 null null .002] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.11,
                    tickIntervals: [0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Maintains finest precision through low LL2B range
                // Historical: 1.12-1.2 transition maintains 4 sig figs for compound operations
                // PostScript: 1.12 [ .05 null .01 .002] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.12,
                    tickIntervals: [0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Slight coarsening as logarithmic spacing increases
                // Historical: 1.2-1.4 range provides 3-4 sig figs for A/B scale power operations
                // PostScript: 1.2 [ .1 .05 .01 .005] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.2,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Approaching e region, marks coarser but adequate for LL2B range
                // Historical: 1.4-1.8 covers e^0.4-0.7 range with standard K&E precision
                // PostScript: 1.4 [.1 null .05 .010] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.4,
                    tickIntervals: [0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Near e (2.718), logarithmic compression widens spacing
                // Historical: 1.8-1.9 subsection provides adequate marks near e constant
                // PostScript: 1.800 [.10 null null .020] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1.800,
                    tickIntervals: [0.10, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Transition subsection near e, no labels but provides tick guidance
                // Historical: 1.9-2.0 fills gap, maintains visual continuity on K&E LL2B scales
                // PostScript: 1.900 [.10 null .050 .020] [] scaleSvars
                ScaleSubsection(
                    startValue: 1.900,
                    tickIntervals: [0.10, 0.05, 0.02],
                    labelLevels: []
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Past e, entering LL3 territory but compressed by factor of 2
                // Historical: 2.0-2.5 (e^0.7-1.0) overlaps LL2/LL3 boundary on extended K&E rules
                // PostScript: 2.000 [.5 null .10 .020] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 2.000,
                    tickIntervals: [0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Approaching e^1, marks coarsen to 0.05 as spacing increases
                // Historical: 2.5-3.0 range transitions from LL2-like to LL3-like density
                // PostScript: 2.500 [.50 null .100 .050] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 2.500,
                    tickIntervals: [0.50, 0.10, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Into LL3 range (e^1+), integer labels with 0.05 fine marks
                // Historical: 3-4 covers e^1.1-1.4, K&E LL2B shows decades with fine subdivisions
                // PostScript: 3 [1 null .100 .050] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 3.0,
                    tickIntervals: [1.0, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.1 quaternary interval)
                // Mathematical: LL3 low range, 0.1 marks provide 2-3 sig figs
                // Historical: 4-6 (e^1.4-1.8) maintains readability through compressed scale
                // PostScript: 4 [1 null .5 .1] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.2 quaternary interval)
                // Mathematical: Mid LL3 range, coarser 0.2 marks adequate for this region
                // Historical: 6-7 subsection provides uniform spacing per K&E LL2B design
                // PostScript: 6 [1 null null .2] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.2 quaternary interval)
                // Mathematical: Approaching 10 (e^2.3), larger primary intervals
                // Historical: 7-10 transition shows 5-unit primary marks on K&E extended scales
                // PostScript: 7 [5 null null .2] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 7.0,
                    tickIntervals: [5.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.5 quaternary interval)
                // Mathematical: First decade boundary (10 = e^2.3), richest subdivisions at major mark
                // Historical: 10-20 region shows full tick hierarchy on K&E LL2B: 10s, 5s, 1s, 0.5s
                // PostScript: 10 [10 5 1 .5] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 2.0 quaternary interval)
                // Mathematical: Second decade (20-30), simplified to 10-unit and 2-unit marks
                // Historical: 20-30 subsection reduces density as scale compresses per K&E practice
                // PostScript: 20 [10 null null 2] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 2.0 quaternary interval)
                // Mathematical: Mid-decade transition, tick marks only (no labels)
                // Historical: 30-50 fills visual gap, K&E LL2B maintained tick continuity here
                // PostScript: 30 [null null 10 2] [] scaleSvars
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 2.0],
                    labelLevels: []
                ),
                // Cursor Precision: 2 decimals (from 5.0 quaternary interval)
                // Mathematical: Half-century mark, 50-unit primary with 5-unit quaternary
                // Historical: 50-100 (e^4.0-4.6) shows decade-scale marks on K&E LL2B
                // PostScript: 50 [50 null 10 5] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [50.0, 10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 20.0 quaternary interval)
                // Mathematical: Century mark (100 = e^4.6), coarse 20-unit marks
                // Historical: 100-300 spans one LL3 decade, K&E showed major marks only
                // PostScript: 100 [100 null null 20] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 20.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 20.0 quaternary interval)
                // Mathematical: 300-500 region, 500-unit primary (note asymmetric interval)
                // Historical: K&E LL2B used non-uniform intervals here to balance density
                // PostScript: 300 [500 null null 20] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 300.0,
                    tickIntervals: [500.0, 20.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 100.0 quaternary interval)
                // Mathematical: Half-millennium, coarsest marks at 100-unit quaternary
                // Historical: 500-1000 (e^6.2-6.9) approaches upper LL3 range per K&E limits
                // PostScript: 500 [500 null null 100] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 500.0,
                    tickIntervals: [500.0, 100.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 200.0 quaternary interval)
                // Mathematical: Millennium mark (1000 = e^6.9), very coarse 200-unit marks
                // Historical: 1000-2000 shows minimal subdivision on K&E LL2B extended range
                // PostScript: 1000 [1000 null null 200] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 200.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 200.0 quaternary interval)
                // Mathematical: 2000-3000 transition, tick marks only for visual continuity
                // Historical: No labels here per K&E LL2B, boundaries labeled by adjacent subsections
                // PostScript: 2000 [null null 1000 200] [] scaleSvars
                ScaleSubsection(
                    startValue: 2000.0,
                    tickIntervals: [1000.0, 200.0],
                    labelLevels: []
                ),
                // Cursor Precision: 1 decimal (from 500.0 quaternary interval)
                // Mathematical: 3000-5000 range, larger quaternary spacing (500 units)
                // Historical: Upper LL2B becomes sparse, K&E provided minimal marks above e^8
                // PostScript: 3000 [null null 1000 500] [] scaleSvars
                ScaleSubsection(
                    startValue: 3000.0,
                    tickIntervals: [1000.0, 500.0],
                    labelLevels: []
                ),
                // Cursor Precision: 1 decimal (from 1000.0 quaternary interval)
                // Mathematical: Five-thousand mark, coarsest quaternary at 1000 units
                // Historical: 5000-10000 (e^8.5-9.2) approaches LL2B limit per K&E design
                // PostScript: 5000 [5000 null null 1000] [] scaleSvars
                ScaleSubsection(
                    startValue: 5000.0,
                    tickIntervals: [5000.0, 1000.0],
                    labelLevels: []
                ),
                // Cursor Precision: 1 decimal (from 2000.0 quaternary interval)
                // Mathematical: Ten-thousand mark (10^4 = e^9.2), labeled decade boundary
                // Historical: 10000-20000 final LL2B range, K&E showed major marks only
                // PostScript: 10000 [10000 null null 2000] [plabel0] scaleSvars
                ScaleSubsection(
                    startValue: 10000.0,
                    tickIntervals: [10000.0, 2000.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 2000.0 quaternary interval)
                // Mathematical: Endpoint region (20000 = e^9.9), tick marks for visual completion
                // Historical: Final LL2B subsection, no labels, approaches theoretical e^10 limit
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
            .withFormula("eˣ")
            .withFunction(ll3Function)
            .withRange(begin: 2.74, end: 21000.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: LL3 starts at e (2.718), 0.02 marks near e provide 2-3 sig figs
                // Historical: LL3 low end (2.6-4) most precise region, K&E readable to 0.05 for small powers
                // PostScript: 2.6 [1 .5 .1 .02] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 2.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Low LL3 range (e^1.4), 0.05 marks → readable to ~0.02
                // Historical: 4-6 region (e^1.4-1.8) standard K&E LL3 precision for decade powers
                // PostScript: 4 [1 .5 .1 .05] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.1 quaternary interval)
                // Mathematical: Approaching 10 (e^2.3), marks coarsen to 0.1 as spacing increases
                // Historical: 6-10 transition shows reduced density per K&E LL3 design
                // PostScript: 6 [1 null .5 .1] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.2 quaternary interval)
                // Mathematical: First decade boundary (10 = e^2.3), 0.2 marks for interpolation
                // Historical: 10-15 region shows 5-unit primary marks on K&E LL3 scales
                // PostScript: 10 [5 null 1 .2] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.2],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.5 quaternary interval)
                // Mathematical: Mid-teens region, 0.5 quaternary provides adequate precision
                // Historical: 15-20 subsection maintains visual continuity on K&E LL3
                // PostScript: 15 [5 null 1 .5] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 15.0,
                    tickIntervals: [5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 0.5 quaternary interval)
                // Mathematical: 20 = e^3.0, richest tick hierarchy at this decade point
                // Historical: 20-30 region shows full 4-level subdivision on K&E LL3 rules
                // PostScript: 20 [10 5 1 .5] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 1.0 quaternary interval)
                // Mathematical: 30-50 range (e^3.4-3.9), coarser 1-unit quaternary marks
                // Historical: K&E LL3 mid-range reduces density while maintaining decade readability
                // PostScript: 30 [10 null 5 1] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 5.0, 1.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 2.0 quaternary interval)
                // Mathematical: Half-century mark, 2-unit quaternary for 50-100 range
                // Historical: 50-100 (e^3.9-4.6) shows decade transition on K&E LL3
                // PostScript: 50 [50 null 10 2] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [50.0, 10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 5.0 quaternary interval)
                // Mathematical: Century mark (100 = e^4.6), richest subdivision at major boundary
                // Historical: 100-200 shows full tick hierarchy on K&E LL3: 100s, 50s, 10s, 5s
                // PostScript: 100 [100 50 10 5] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 10.0 quaternary interval)
                // Mathematical: 200-500 mid-hundreds, 10-unit quaternary adequate for this range
                // Historical: K&E LL3 maintains readability through second century
                // PostScript: 200 [200 100 50 10] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 200.0,
                    tickIntervals: [200.0, 100.0, 50.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 2 decimals (from 50.0 quaternary interval)
                // Mathematical: Half-millennium (500 = e^6.2), coarsening toward thousands
                // Historical: 500-1000 transition shows reduced density per K&E LL3 design
                // PostScript: 500 [500 null 100 50] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 500.0,
                    tickIntervals: [500.0, 100.0, 50.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 100.0 quaternary interval)
                // Mathematical: Millennium (1000 = e^6.9), 100-unit quaternary marks
                // Historical: 1000-2000 (e^6.9-7.6) shows major marks on K&E LL3 upper range
                // PostScript: 1000 [1000 null 500 100] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 500.0, 100.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 200.0 quaternary interval)
                // Mathematical: Two thousand (2000 = e^7.6), 200-unit quaternary spacing
                // Historical: 2000-4000 range approaching LL3 upper limit per K&E standards
                // PostScript: 2000 [2000 null 1000 200] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 2000.0,
                    tickIntervals: [2000.0, 1000.0, 200.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 200.0 quaternary interval)
                // Mathematical: 4000-5000 transition, note 5000-unit primary (asymmetric)
                // Historical: K&E LL3 used non-uniform intervals here to balance visual density
                // PostScript: 4000 [5000 null 1000 200] [plabel] scaleSvars
                // Note: Major tick is 5000 even though subsection starts at 4000
                ScaleSubsection(
                    startValue: 4000.0,
                    tickIntervals: [5000.0, 1000.0, 200.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 500.0 quaternary interval)
                // Mathematical: Five thousand (5000 = e^8.5), coarse 500-unit marks
                // Historical: 5000-10000 final LL3 range, K&E showed minimal subdivision
                // PostScript: 5000 [5000 null 1000 500] [plabel] scaleSvars
                ScaleSubsection(
                    startValue: 5000.0,
                    tickIntervals: [5000.0, 1000.0, 500.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // Cursor Precision: 1 decimal (from 1000.0 quaternary interval)
                // Mathematical: Ten thousand (10000 = e^9.2), coarsest LL3 marks at 1000 units
                // Historical: 10000-21000 endpoint region, K&E LL3 limit near e^10
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
            .withFormula("log₁₀(ln(x))")
            .withFunction(ll3Function)
            .withRange(begin: 2.74, end: 21000.0)  // e¹ to e¹⁰
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: LL3 starts near e, 0.02 marks provide finest precision in this implementation
                // Historical: Simplified LL3 maintains K&E precision standards at scale start
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
                
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Low LL3 range, 0.05 marks adequate for e^1.4 region
                // Historical: 4-6 subsection maintains readability as logarithmic compression increases
                // PostScript subsection 2: 4-6 (line 1427)
                // Slightly coarser as we move away from e
                // Intervals: [1, .5, .1, .05]
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                
                // Cursor Precision: 2 decimals (from 0.1 quaternary interval)
                // Mathematical: Approaching first decade (10 = e^2.3), coarser 0.1 marks
                // Historical: K&E LL3 reduced tick density in 6-10 transition per design standards
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
                
                // Cursor Precision: 2 decimals (from 0.2 quaternary interval)
                // Mathematical: First decade boundary, 0.2 quaternary for 10-15 interpolation
                // Historical: 10-15 region shows 5-unit primary on K&E LL3 scales
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
                
                // Cursor Precision: 2 decimals (from 0.5 quaternary interval)
                // Mathematical: Mid-decade, 0.5 marks adequate for 15-20 range
                // Historical: K&E maintained uniform 5-unit primaries through lower decades
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
                
                // Cursor Precision: 2 decimals (from 0.5 quaternary interval)
                // Mathematical: 20 = e^3.0, richest tick hierarchy at major decade
                // Historical: 20-30 shows full 4-level subdivision on K&E LL3 for this critical range
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
                
                // Cursor Precision: 1 decimal (from 1.0 quaternary interval)
                // Mathematical: 30-50 mid-range, 1-unit marks adequate for this spacing
                // Historical: K&E LL3 shows coarser marks past 30 as scale compresses
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
                
                // Cursor Precision: 2 decimals (from 2.0 quaternary interval)
                // Mathematical: Half-century to century transition, 2-unit marks
                // Historical: 50-100 (e^3.9-4.6) decade boundary on K&E LL3
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
                
                // Cursor Precision: 2 decimals (from 5.0 quaternary interval)
                // Mathematical: Century mark, richest hundred-scale subdivision
                // Historical: 100-200 shows full tick hierarchy (100, 50, 10, 5) on K&E LL3
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
                
                // Cursor Precision: 2 decimals (from 10.0 quaternary interval)
                // Mathematical: Mid-hundreds with 10-unit quaternary
                // Historical: 200-500 maintains adequate readability on K&E LL3 upper range
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
                
                // Cursor Precision: 2 decimals (from 50.0 quaternary interval)
                // Mathematical: Half-millennium, 50-unit quaternary marks
                // Historical: 500-1000 shows reduced density approaching thousands on K&E LL3
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
                
                // Cursor Precision: 1 decimal (from 100.0 quaternary interval)
                // Mathematical: Millennium (1000 = e^6.9), coarse 100-unit marks
                // Historical: 1000-2000 shows sparse subdivision on K&E LL3 upper range
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
                
                // Cursor Precision: 1 decimal (from 200.0 quaternary interval)
                // Mathematical: 2000-3000 transition, tick marks only (no labels per PostScript)
                // Historical: K&E LL3 omitted labels here, boundaries labeled by adjacent subsections
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
                
                // Cursor Precision: 1 decimal (from 500.0 quaternary interval)
                // Mathematical: 3000-5000 region, coarse 500-unit quaternary
                // Historical: Upper LL3 thousands become very sparse per K&E design
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
                
                // Cursor Precision: 1 decimal (from 1000.0 quaternary interval)
                // Mathematical: 5000-10000 final approach, coarsest marks at 1000 units
                // Historical: K&E LL3 showed minimal subdivision in this endpoint region
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
                
                // Cursor Precision: 1 decimal (from 2000.0 quaternary interval)
                // Mathematical: Ten thousand (10^4 = e^9.2), major labeled boundary
                // Historical: 10000-20000 final labeled region on K&E LL3, approaching e^10 limit
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
                
                // Cursor Precision: 1 decimal (from 2000.0 quaternary interval)
                // Mathematical: Endpoint region (20000-21000), tick marks for visual completion
                // Historical: Final LL3 subsection, no labels, approaches theoretical e^10 = 22026 limit
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
            .withFormula("e⁰·¹ˣ")
            .withFunction(ll2Function)
            .withRange(begin: 1.105, end: 2.72)  // e^0.1 to e^1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Simplified LL2 start, 0.005 marks provide 3-4 sig figs
                // Historical: Simplified version maintains essential precision for e^0.1-0.5 range
                ScaleSubsection(startValue: 1.105, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Mid-range LL2, uniform 0.005 marks throughout for consistency
                // Historical: Simplified subsections trade PostScript accuracy for ease of use
                ScaleSubsection(startValue: 1.5, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Upper LL2 approaching e, maintains consistent quaternary spacing
                // Historical: Uniform intervals simplify implementation while preserving readable precision
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
            .withFormula("e⁰·⁰¹ˣ")
            .withFunction(ll1Function)
            .withRange(begin: 1.0101, end: 1.105)  // e^0.01 to e^0.1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Simplified LL1 start, 0.0005 marks for e^0.01-0.05 micro-exponential precision
                // Historical: Maintains K&E LL1 precision requirements with simplified 2-subsection pattern
                ScaleSubsection(startValue: 1.01, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Upper LL1, uniform 0.0005 intervals through e^0.05-0.1 range
                // Historical: Simplified version preserves fine precision critical for LL1 operations
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
            .withFormula("e⁰·⁰⁰¹ˣ")
            .withFunction(ll0Function)
            .withRange(begin: 1.001, end: 1.0101)  // e^0.001 to e^0.01
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 5 decimals (from 0.00005 quaternary interval)
                // Mathematical: Ultra-precision LL0 start, 0.00005 marks for e^0.001-0.005 finest resolution
                // Historical: Simplified LL0 preserves K&E ultra-precision requirements, capped at 5 decimals
                ScaleSubsection(startValue: 1.001, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00005 quaternary interval)
                // Mathematical: Upper LL0, uniform finest marks through e^0.005-0.01 range
                // Historical: Maintains extreme precision needed for LL0 micro-correction calculations
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
            .withFormula("e⁻ˣ")
            .withFunction(ll03Function)
            .withRange(begin: 0.00005, end: 0.368)  // e^-10 to e^-1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 5 decimals (from 0.000005 quaternary interval, capped at 5)
                // Mathematical: Reciprocal of LL3 at e^-10, extreme precision for ultra-small decay values
                // Historical: LL03 start (0.00005 = e^-10) required finest marks on K&E reciprocal scales
                ScaleSubsection(startValue: 0.00005, tickIntervals: [0.0001, 0.00005, 0.00001, 0.000005], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.000005 quaternary interval, capped at 5)
                // Mathematical: Ultra-fine marks for e^-9 to e^-7 range, mirrors LL3 upper precision
                // Historical: K&E LL03 low end readable to 0.00001 by experts for decay calculations
                ScaleSubsection(startValue: 0.0001, tickIntervals: [0.0001, 0.00005, 0.00001, 0.000005], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00005 quaternary interval)
                // Mathematical: e^-7 to e^-5 range, 0.00005 marks for precise decay/attenuation work
                // Historical: Mid-LL03 maintains 4-5 sig figs per K&E reciprocal scale standards
                ScaleSubsection(startValue: 0.001, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: e^-5 to e^-2 range, coarsening as values approach 1/e
                // Historical: Upper LL03 shows reduced density like LL3, maintains 3-4 sig figs
                ScaleSubsection(startValue: 0.01, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Approaching 1/e (0.368), coarsest LL03 marks at 0.005
                // Historical: LL03 end (0.1-0.368 = e^-2.3 to e^-1) transitions to LL02, K&E standard precision
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withColorApplication((scaleName: true, scaleLabels: true, scaleTicks: true))
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
            .withFormula("e⁻⁰·¹ˣ")
            .withFunction(ll02Function)
            .withRange(begin: 0.368, end: 0.905)  // e^-1 to e^-0.1
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: LL02 start at 1/e, 0.005 marks for e^-1 to e^-0.7 precision
                // Historical: Reciprocal of LL2, maintains K&E precision for moderate negative powers
                ScaleSubsection(startValue: 0.37, tickIntervals: [0.05, 0.02, 0.01, 0.005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Mid-LL02 (0.5 = e^-0.69), uniform marks for decay calculations
                // Historical: 0.5-0.8 range critical for RC circuits, K&E LL02 showed 3-4 sig figs
                ScaleSubsection(startValue: 0.50, tickIntervals: [0.05, 0.02, 0.01, 0.005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Approaching e^-0.1, finest LL02 marks at 0.001 near scale end
                // Historical: Upper LL02 (0.8-0.905) transitions to LL01, K&E increased density here
                ScaleSubsection(startValue: 0.80, tickIntervals: [0.02, 0.01, 0.005, 0.001], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withColorApplication(ScaleColorPresets.labelsOnly)  // Apply red color only to labels, not scale
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
            .withFormula("e⁻⁰·⁰¹ˣ")
            .withFunction(ll01Function)
            .withRange(begin: 0.905, end: 0.990)  // e^-0.1 to e^-0.01
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: LL01 start at e^-0.1, reciprocal of LL1, fine marks for small negative powers
                // Historical: 0.90-0.95 range matches LL1 precision, K&E LL01 readable to 0.001
                ScaleSubsection(startValue: 0.90, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Mid-LL01 (0.95 = e^-0.05), uniform fine marks for precision attenuation
                // Historical: 0.95-0.98 critical for quality factor calculations, K&E maintained 4 sig figs
                ScaleSubsection(startValue: 0.95, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.0001 quaternary interval)
                // Mathematical: Approaching e^-0.01, finest LL01 marks at 0.0001 near unity
                // Historical: Upper LL01 (0.98-0.990) transitions to LL00, K&E showed maximum density here
                ScaleSubsection(startValue: 0.98, tickIntervals: [0.005, 0.001, 0.0005, 0.0001], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withColorApplication((scaleName: true, scaleLabels: true, scaleTicks: true))
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
            .withFormula("e⁻⁰·⁰⁰¹ˣ")
            .withFunction(ll00Function)
            .withRange(begin: 0.990, end: 0.999)  // e^-0.01 to e^-0.001
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 5 decimals (from 0.00005 quaternary interval)
                // Mathematical: LL00 start at e^-0.01, ultra-precision reciprocal, finest marks on slide rule
                // Historical: 0.990-0.995 range required extreme precision on K&E LL00, readable to 0.0001
                ScaleSubsection(startValue: 0.990, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00002 quaternary interval, capped at 5)
                // Mathematical: Mid-LL00 (0.995 = e^-0.005), finest interval on any slide rule scale
                // Historical: THE MOST PRECISE SUBSECTION: K&E LL00 experts could read to 0.00001 (6 decimals theoretically)
                ScaleSubsection(startValue: 0.995, tickIntervals: [0.001, 0.0005, 0.0001, 0.00002], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00001 quaternary interval, capped at 5)
                // Mathematical: Approaching unity (0.999 = e^-0.001), extreme compression requires finest marks
                // Historical: Upper LL00 (0.998-0.999) the ultimate precision challenge on K&E rules
                ScaleSubsection(startValue: 0.998, tickIntervals: [0.0005, 0.0001, 0.00005, 0.00001], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withColorApplication(ScaleColorPresets.labelsOnly)  // Apply red color only to labels, not scale
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
            .withFormula("e⁻⁰·¹ˣ/²")
            .withFunction(ll02BFunction)
            .withRange(begin: 0.00005, end: 0.904)  // Extended range
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 5 decimals (from 0.00001 quaternary interval, capped at 5)
                // Mathematical: LL02B combines LL02+LL03 ranges, divided by 2 for A/B reference
                // Historical: Extended negative scale on K&E, matches LL03 extreme precision at start
                ScaleSubsection(startValue: 0.00005, tickIntervals: [0.0001, 0.00005, 0.00001], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00005 quaternary interval)
                // Mathematical: Ultra-low decay range (e^-9 to e^-7), finest marks for nano-scale work
                // Historical: LL02B low end preserves precision for combined square-decay operations
                ScaleSubsection(startValue: 0.0001, tickIntervals: [0.0001, 0.00005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Transitioning through e^-7 to e^-5 range, reduced quaternary density
                // Historical: K&E LL02B mid-range shows 4 sig figs for extended decay calculations
                ScaleSubsection(startValue: 0.0010, tickIntervals: [0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: e^-5 to e^-2 range, coarsening as values approach 1/e
                // Historical: LL02B upper-mid maintains precision for A/B scale compatibility
                ScaleSubsection(startValue: 0.01, tickIntervals: [0.01, 0.005, 0.001], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: 0.1-0.8 range (e^-2.3 to e^-0.2), standard LL02-like precision
                // Historical: LL02B overlaps LL02 range here, K&E showed 3-4 sig figs
                ScaleSubsection(startValue: 0.10, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Approaching e^-0.1, finest LL02B upper marks at 0.002
                // Historical: LL02B end (0.8-0.904) matches LL02, enables seamless A/B operations
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
            .withFormula("e⁻⁰·⁰¹ˣ/²")
            .withFunction(ll00BFunction)
            .withRange(begin: 0.900, end: 0.999)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: LL00B start (0.900 = e^-0.105), combines LL00+LL01, A/B referenced
                // Historical: Hemmi 266 variant, coarser than pure LL01 but adequate for combined ops
                ScaleSubsection(startValue: 0.900, tickIntervals: [0.05, 0.01, 0.005, 0.001], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Mid-LL00B (0.950 = e^-0.05), increasing density for precision
                // Historical: 0.95-0.98 transition zone, Hemmi 266 showed 4 sig figs here
                ScaleSubsection(startValue: 0.950, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0002 quaternary interval)
                // Mathematical: Approaching LL00 range, 0.0002 marks for high precision
                // Historical: 0.98-0.99 Hemmi 266 increased density approaching unity
                ScaleSubsection(startValue: 0.980, tickIntervals: [0.01, 0.005, 0.001, 0.0002], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.0001 quaternary interval)
                // Mathematical: LL00B enters LL00 territory (e^-0.01), finest marks begin
                // Historical: 0.990-0.995 Hemmi 266 matched LL00 precision for quality factors
                ScaleSubsection(startValue: 0.990, tickIntervals: [0.005, 0.001, 0.0005, 0.0001], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00005 quaternary interval)
                // Mathematical: Ultra-precision LL00B region (0.995 = e^-0.005), extreme compression
                // Historical: Hemmi 266 LL00B peak precision, readable to 0.0001 by experts
                ScaleSubsection(startValue: 0.995, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                // Cursor Precision: 5 decimals (from 0.00002 quaternary interval, capped at 5)
                // Mathematical: LL00B end approaching unity, finest marks (0.00002) on Hemmi variant
                // Historical: 0.998-0.999 ultimate Hemmi 266 precision, matches LL00 theoretical limit
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
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: H266LL01 truncated LL00B range, maintains precision for 0.9-0.95
                // Historical: Hemmi 266 space-saving variant, adequate for compact rule design
                ScaleSubsection(startValue: 0.900, tickIntervals: [0.05, 0.01, 0.005, 0.001], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Mid-H266LL01, increasing density toward 0.98
                // Historical: Hemmi 266 maintained LL00B precision in truncated range
                ScaleSubsection(startValue: 0.950, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                // Cursor Precision: 4 decimals (from 0.0002 quaternary interval)
                // Mathematical: H266LL01 upper end, finest marks at 0.0002 before truncation
                // Historical: Truncated at 0.99, preserves essential LL00B functionality on Hemmi 266
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
            .withFormula("e⁻⁰·¹ˣ×¹⁰⁻⁹")
            .withFunction(h266LL03Function)
            .withRange(begin: 1.0, end: 50000.0)  // Scale units, not physical values
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 1 decimal (from 1.0 single interval)
                // Mathematical: H266LL03 represents 10^-9 scale units, 1-unit marks at nano-scale start
                // Historical: Specialized Hemmi 266 scale for ultra-small values, coarse scale-unit marks
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 1.0 quaternary interval)
                // Mathematical: 2-10 range (10^-9 to 10^-8 physical), 1-unit quaternary marks
                // Historical: Hemmi 266 H266LL03 low range shows decade subdivisions
                ScaleSubsection(startValue: 2.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0]),
                // Cursor Precision: 2 decimals (from 5.0 quaternary interval)
                // Mathematical: First decade (10 = 10^-8), simplified to 5-unit marks
                // Historical: 10-20 region Hemmi 266 reduced tick density for nano-scale calculations
                ScaleSubsection(startValue: 10.0, tickIntervals: [10.0, 5.0], labelLevels: [0]),
                // Cursor Precision: 2 decimals (from 10.0 quaternary interval)
                // Mathematical: 20-100 range (10^-8 to 10^-7), coarse 10-unit quaternary
                // Historical: Hemmi 266 mid-range shows decade transitions with limited subdivision
                ScaleSubsection(startValue: 20.0, tickIntervals: [100.0, 50.0, 10.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 100.0 quaternary interval)
                // Mathematical: Century mark in scale units (100 = 10^-7), very coarse marks
                // Historical: 100-200 Hemmi 266 shows minimal subdivision in middle decades
                ScaleSubsection(startValue: 100.0, tickIntervals: [100.0, 500.0, 100.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 100.0 quaternary interval)
                // Mathematical: 200-1000 transition, 100-unit quaternary spacing
                // Historical: Hemmi 266 maintained sparse marks through upper scale-unit decades
                ScaleSubsection(startValue: 200.0, tickIntervals: [1000.0, 500.0, 100.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 1000.0 quaternary interval)
                // Mathematical: Millennium in scale units (1000 = 10^-6), coarsest marks
                // Historical: 1000-2000 Hemmi 266 shows major marks only for micro-scale range
                ScaleSubsection(startValue: 1000.0, tickIntervals: [1000.0, 5000.0, 1000.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 1000.0 quaternary interval)
                // Mathematical: Upper thousands (2000-10000 = 10^-6 to 10^-5), very sparse
                // Historical: Hemmi 266 H266LL03 approaching upper limit, minimal subdivision
                ScaleSubsection(startValue: 2000.0, tickIntervals: [10000.0, 5000.0, 1000.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 10000.0 quaternary interval)
                // Mathematical: Ten thousand in scale units (10000 = 10^-5), decade boundary
                // Historical: 10000-20000 Hemmi 266 shows final decade with coarse marks
                ScaleSubsection(startValue: 10000.0, tickIntervals: [10000.0, 50000.0, 10000.0], labelLevels: [0]),
                // Cursor Precision: 1 decimal (from 10000.0 quaternary interval)
                // Mathematical: Endpoint region (20000-50000 = 2×10^-5 to 5×10^-5), sparse marks
                // Historical: Final H266LL03 subsection, Hemmi 266 limit at 5×10^-5 physical value
                ScaleSubsection(startValue: 20000.0, tickIntervals: [100000.0, 50000.0, 10000.0], labelLevels: [0])
            ])
            .withLabelFormatter({ value in h266Formatter(value) ?? "" })
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .build()
    }
    
    
    
}

