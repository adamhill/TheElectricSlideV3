import Foundation

// MARK: - Positive Log-Log Scales (LL0, LL1, LL2, LL3)
//
// This file implements the standard positive Log-Log scales representing e^x.
// These scales are used for exponential growth, compound interest, and power calculations.
//
// SCALE HIERARCHY:
//   LL0:  e^(x/1000)  Range: 1.001 to 1.0101  (ultra-precision, micro-adjustments)
//   LL1:  e^(x/100)   Range: 1.0101 to 1.105  (small powers, precision calculations)
//   LL2:  e^(x/10)    Range: 1.105 to 2.72    (moderate powers, compound interest)
//   LL3:  e^x         Range: 2.74 to 21,000   (large exponentials, arbitrary powers)
//
// POSTSCRIPT FORMULA CONCORDANCE:
// All formulas are direct Swift translations of PostScript RPN (Reverse Polish Notation):
//   PostScript: {ln 1000 mul log}  →  Swift: log10(log(x) * 1000)  (LL0)
//   PostScript: {ln 100 mul log}   →  Swift: log10(log(x) * 100)   (LL1)
//   PostScript: {ln 10 mul log}    →  Swift: log10(log(x) * 10)    (LL2)
//   PostScript: {ln log}           →  Swift: log10(log(x))         (LL3)
//
// POSTSCRIPT LINE REFERENCES:
//   LL0scale:  Lines 905-914  (postscript-engine-for-sliderules.ps)
//   LL1scale:  Lines 915-922  (postscript-engine-for-sliderules.ps)
//   LL2scale:  Lines 925-933  (postscript-engine-for-sliderules.ps)
//   LL3scale:  Lines 962-983  (postscript-engine-for-sliderules.ps)

extension StandardScales {
    
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
            .withConstants([
                // e = 2.71828... falls within LL2 range (1.105-2.72)
                // Historical: Euler's number marked on all log-log scales where it appears
                ScaleConstant(
                    value: 2.71828,
                    label: "e"
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.twoDecimals)
            .build()
    }
    
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
}
