import Foundation

/// Label formatter that can optionally suppress labels by returning nil
public typealias LabelFormatter = @Sendable (ScaleValue) -> String?

// MARK: - Special Log-Log Scale Variants
//
// This file contains specialized variants and PostScript-accurate implementations
// of Log-Log scales. These include:
//
// 1. **PostScript-Accurate Scales** - Exact subsection patterns from the PostScript
//    slide rule engine for historical accuracy and validation
//
// 2. **Extended/Combined Scales** - Scales that combine or extend standard LL ranges
//    (LL2B, LL02B, LL00B) for space efficiency or A/B scale compatibility
//
// 3. **Hemmi 266 Variants** - Specialized scales found on the Hemmi 266 series
//
// POSTSCRIPT LINE REFERENCES:
//   LL1scale (PS-accurate):  Lines 915-922  (postscript-engine-for-sliderules.ps)
//   LL2scale (PS-accurate):  Lines 925-933  (postscript-engine-for-sliderules.ps)
//   LL2Bscale:               Lines 936-959  (postscript-engine-for-sliderules.ps)
//   LL3scale (PS-accurate):  Lines 962-983  (postscript-engine-for-sliderules.ps)
//   LL00Bscale:              Lines 717-724  (postscript-engine-for-sliderules.ps)
//   H266LL01:                Lines 725-729  (postscript-engine-for-sliderules.ps)
//   H266LL03:                Lines 750-757  (postscript-engine-for-sliderules.ps)
//   LL02Bscale:              Lines 758-771  (postscript-engine-for-sliderules.ps)

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
    /// **Formula:** log₁₀(ln(x) × 10)
    /// **Range:** 1.105 (e^0.1) to 2.7 (e^1)
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
    /// **Formula:** log₁₀(ln(x) × 10) / 2
    /// **Range:** 1.106 (e^0.1) to 20,000 (e^9.9)
    /// **Physical Range:** Referenced to A/B scales (square scales) for combined operations
    /// **Used for:** extended-power-range, combined-square-operations, bridge-calculations
    ///
    /// **Why "2 div" (Division by 2)?**
    /// The "/2" factor references this scale to the A/B scales, which represent x²:
    /// - A/B scales use: log₁₀(x²) = 2 × log₁₀(x)
    /// - LL2B compensates: log₁₀(ln(x) × 10) / 2
    /// - Allows direct power operations combining squares and exponentials
    ///
    /// **Special Features:**
    /// - **26 subsections:** Most detailed subdivision of any log-log scale
    /// - **Continuous coverage:** Bridges LL2 and LL3 ranges completely
    /// - **A/B compatibility:** Direct alignment with square scales
    /// - **Wide dynamic range:** Nearly 10 orders of magnitude (e^0.1 to e^10)
    public static func ll2BScale_PostScriptAccurate(length: Distance = 250.0) -> ScaleDefinition {
        // PostScript formula: {ln 10 mul log 2 div}
        // Meaning: log₁₀(ln(x) × 10) / 2
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
                // PostScript: 1.106 [ .1 .05 .01 .002] [] scaleSvars
                ScaleSubsection(startValue: 1.106, tickIntervals: [0.1, 0.05, 0.01, 0.002], labelLevels: []),
                // PostScript: 1.11 [ .01 null null .002] [plabel0] scaleSvars
                ScaleSubsection(startValue: 1.11, tickIntervals: [0.01, 0.002], labelLevels: [0], labelFormatter: StandardLabelFormatter.twoDecimals),
                // PostScript: 1.12 [ .05 null .01 .002] [plabel0] scaleSvars
                ScaleSubsection(startValue: 1.12, tickIntervals: [0.05, 0.01, 0.002], labelLevels: [0], labelFormatter: StandardLabelFormatter.twoDecimals),
                // PostScript: 1.2 [ .1 .05 .01 .005] [plabel0] scaleSvars
                ScaleSubsection(startValue: 1.2, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0], labelFormatter: StandardLabelFormatter.oneDecimal),
                // PostScript: 1.4 [.1 null .05 .010] [plabel0] scaleSvars
                ScaleSubsection(startValue: 1.4, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0], labelFormatter: StandardLabelFormatter.oneDecimal),
                // PostScript: 1.800 [.10 null null .020] [plabel0] scaleSvars
                ScaleSubsection(startValue: 1.800, tickIntervals: [0.10, 0.02], labelLevels: [0], labelFormatter: StandardLabelFormatter.oneDecimal),
                // PostScript: 1.900 [.10 null .050 .020] [] scaleSvars
                ScaleSubsection(startValue: 1.900, tickIntervals: [0.10, 0.05, 0.02], labelLevels: []),
                // PostScript: 2.000 [.5 null .10 .020] [plabel0] scaleSvars
                ScaleSubsection(startValue: 2.000, tickIntervals: [0.5, 0.1, 0.02], labelLevels: [0], labelFormatter: StandardLabelFormatter.oneDecimal),
                // PostScript: 2.500 [.50 null .100 .050] [plabel0] scaleSvars
                ScaleSubsection(startValue: 2.500, tickIntervals: [0.50, 0.10, 0.05], labelLevels: [0], labelFormatter: StandardLabelFormatter.oneDecimal),
                // PostScript: 3 [1 null .100 .050] [plabel0] scaleSvars
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.1, 0.05], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 4 [1 null .5 .1] [plabel0] scaleSvars
                ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 6 [1 null null .2] [plabel0] scaleSvars
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.2], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 7 [5 null null .2] [plabel0] scaleSvars
                ScaleSubsection(startValue: 7.0, tickIntervals: [5.0, 0.2], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 10 [10 5 1 .5] [plabel0] scaleSvars
                ScaleSubsection(startValue: 10.0, tickIntervals: [10.0, 5.0, 1.0, 0.5], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 20 [10 null null 2] [plabel0] scaleSvars
                ScaleSubsection(startValue: 20.0, tickIntervals: [10.0, 2.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 30 [null null 10 2] [] scaleSvars
                ScaleSubsection(startValue: 30.0, tickIntervals: [10.0, 2.0], labelLevels: []),
                // PostScript: 50 [50 null 10 5] [plabel0] scaleSvars
                ScaleSubsection(startValue: 50.0, tickIntervals: [50.0, 10.0, 5.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 100 [100 null null 20] [plabel0] scaleSvars
                ScaleSubsection(startValue: 100.0, tickIntervals: [100.0, 20.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 300 [500 null null 20] [plabel0] scaleSvars
                ScaleSubsection(startValue: 300.0, tickIntervals: [500.0, 20.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 500 [500 null null 100] [plabel0] scaleSvars
                ScaleSubsection(startValue: 500.0, tickIntervals: [500.0, 100.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 1000 [1000 null null 200] [plabel0] scaleSvars
                ScaleSubsection(startValue: 1000.0, tickIntervals: [1000.0, 200.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 2000 [null null 1000 200] [] scaleSvars
                ScaleSubsection(startValue: 2000.0, tickIntervals: [1000.0, 200.0], labelLevels: []),
                // PostScript: 3000 [null null 1000 500] [] scaleSvars
                ScaleSubsection(startValue: 3000.0, tickIntervals: [1000.0, 500.0], labelLevels: []),
                // PostScript: 5000 [5000 null null 1000] [] scaleSvars
                ScaleSubsection(startValue: 5000.0, tickIntervals: [5000.0, 1000.0], labelLevels: []),
                // PostScript: 10000 [10000 null null 2000] [plabel0] scaleSvars
                ScaleSubsection(startValue: 10000.0, tickIntervals: [10000.0, 2000.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 20000 [10000 null null 2000] [] scaleSvars
                ScaleSubsection(startValue: 20000.0, tickIntervals: [10000.0, 2000.0], labelLevels: [])
            ])
            .build()
    }
    
    // MARK: - LL3 Scale (PostScript-Accurate)
    
    /// LL3 scale: Base log-log scale with exact PostScript subsections
    ///
    /// **PostScript Reference:** Lines 962-983 in postscript-engine-for-sliderules.ps
    /// **Formula:** log₁₀(ln(x))
    /// **Range:** 2.74 (e¹) to 21,000 (e^10)
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
                // PostScript: 2.6 [1 .5 .1 .02] [plabel] scaleSvars
                ScaleSubsection(startValue: 2.6, tickIntervals: [1.0, 0.5, 0.1, 0.02], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 4 [1 .5 .1 .05] [plabel] scaleSvars
                ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 6 [1 null .5 .1] [plabel] scaleSvars
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 10 [5 null 1 .2] [plabel] scaleSvars
                ScaleSubsection(startValue: 10.0, tickIntervals: [5.0, 1.0, 0.2], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 15 [5 null 1 .5] [plabel] scaleSvars
                ScaleSubsection(startValue: 15.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 20 [10 5 1 .5] [plabel] scaleSvars
                ScaleSubsection(startValue: 20.0, tickIntervals: [10.0, 5.0, 1.0, 0.5], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 30 [10 null 5 1] [plabel] scaleSvars
                ScaleSubsection(startValue: 30.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 50 [50 null 10 2] [plabel] scaleSvars
                ScaleSubsection(startValue: 50.0, tickIntervals: [50.0, 10.0, 2.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 100 [100 50 10 5] [plabel] scaleSvars
                ScaleSubsection(startValue: 100.0, tickIntervals: [100.0, 50.0, 10.0, 5.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 200 [200 100 50 10] [plabel] scaleSvars
                ScaleSubsection(startValue: 200.0, tickIntervals: [200.0, 100.0, 50.0, 10.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 500 [500 null 100 50] [plabel] scaleSvars
                ScaleSubsection(startValue: 500.0, tickIntervals: [500.0, 100.0, 50.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 1000 [1000 null 500 100] [plabel] scaleSvars
                ScaleSubsection(startValue: 1000.0, tickIntervals: [1000.0, 500.0, 100.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 2000 [2000 null 1000 200] [plabel] scaleSvars
                ScaleSubsection(startValue: 2000.0, tickIntervals: [2000.0, 1000.0, 200.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 4000 [5000 null 1000 200] [plabel] scaleSvars
                ScaleSubsection(startValue: 4000.0, tickIntervals: [5000.0, 1000.0, 200.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 5000 [5000 null 1000 500] [plabel] scaleSvars
                ScaleSubsection(startValue: 5000.0, tickIntervals: [5000.0, 1000.0, 500.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer),
                // PostScript: 10000 [10000 null 5000 1000] [plabel] scaleSvars
                ScaleSubsection(startValue: 10000.0, tickIntervals: [10000.0, 5000.0, 1000.0], labelLevels: [0], labelFormatter: StandardLabelFormatter.integer)
            ])
            .addConstant(value: .e, label: "e", style: .major)
            .build()
    }
    
    // MARK: - LL02B Scale
    
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
                ScaleSubsection(startValue: 0.00005, tickIntervals: [0.0001, 0.00005, 0.00001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.0001, tickIntervals: [0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.0010, tickIntervals: [0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.01, tickIntervals: [0.01, 0.005, 0.001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.10, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.80, tickIntervals: [0.05, 0.01, 0.002], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(.red)  // Red labels
            .build()
    }
    
    // MARK: - LL00B Scale (Hemmi 266)
    
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
                ScaleSubsection(startValue: 0.900, tickIntervals: [0.05, 0.01, 0.005, 0.001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.950, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.980, tickIntervals: [0.01, 0.005, 0.001, 0.0002], labelLevels: [0]),
                ScaleSubsection(startValue: 0.990, tickIntervals: [0.005, 0.001, 0.0005, 0.0001], labelLevels: [0]),
                ScaleSubsection(startValue: 0.995, tickIntervals: [0.001, 0.0005, 0.0001, 0.00005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.998, tickIntervals: [0.0005, 0.0001, 0.00002], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.threeDecimals)
            .withLabelColor(.red)  // Red labels
            .build()
    }
    
    // MARK: - H266LL01 Scale (Hemmi 266)
    
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
            labelColor: .red,  // Red labels
            constants: []
        )
    }
    
    // MARK: - H266LL03 Scale (Hemmi 266)
    
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
    /// **Label Format:** Labels show as "10^-X" notation
    /// Example: value 1 → "10^-9", value 100 → "10^-7"
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
            .withLabelColor(.red)  // Red labels
            .build()
    }
    
    // MARK: - H266L Scale (Hemmi 266 L scale with dB symbol)
    
    /// H266L scale: Hemmi 266 L scale with special display name
    ///
    /// **Description:** Standard L (mantissa) scale with Hemmi 266-specific display name using dB symbol
    /// **Formula:** log₁₀ x (linear scale, 0 to 1)
    /// **Range:** 0 to 1
    /// **Display Name:** ㏈ L (using Unicode dB symbol)
    ///
    /// This is functionally identical to the standard L scale but with:
    /// - Token name "H266L" for parser recognition
    /// - Display name "㏈ L" for Hemmi 266 visual style
    ///
    /// **POSTSCRIPT REFERENCES:** Based on standard L scale definition
    public static func h266LScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("H266L")
            .withDisplayName("㏈ L")  // Hemmi 266 uses dB symbol prefix
            .withFormula("log₁₀ x")
            .withFunction(LinearFunction())
            .withRange(begin: 0, end: 1)
            .withLength(length)
            .withTickDirection(.up)
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
}
