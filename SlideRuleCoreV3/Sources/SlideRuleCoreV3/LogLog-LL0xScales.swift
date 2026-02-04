import Foundation

// MARK: - LL03 Scale Label Formatters

/// Specialized label formatters for LL03 scale subsections
/// Based on Faber-Castell 62/83N reference implementation
public enum LL03LabelFormatters {
    
    /// LL03 upper range formatter (0.4 to 0.1 range)
    /// - Primary labels (0.4, 0.3, 0.2, 0.1): One decimal place (e.g., ".4")
    /// - Secondary labels (0.35, 0.25, 0.15): Two decimal places (e.g., ".35")
    ///
    /// Historical: Faber-Castell 62/83N shows 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1
    /// The tenths (0.4, 0.3, 0.2, 0.1) are displayed with one decimal point
    /// The half-tenths (0.35, 0.25, 0.15) are displayed with two decimal points
    public static let ll03UpperRange: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        
        // Round to 2 decimal places to avoid floating point issues
        let rounded = (value * 100).rounded() / 100
        
        // Check if value is a multiple of 0.1 (i.e., 0.4, 0.3, 0.2, 0.1)
        // Using modulo with tolerance for floating point comparison
        let tenthsMultiple = (rounded * 10).rounded()
        let isTenthsMultiple = abs(rounded - tenthsMultiple / 10) < 0.001
        
        if isTenthsMultiple {
            // Primary labels: one decimal place (0.4, 0.3, 0.2, 0.1)
            return String(format: "%.1f", rounded)
        } else {
            // Secondary labels: two decimal places (0.35, 0.25, 0.15)
            return String(format: "%.2f", rounded)
        }
    }
    
    /// LL03 middle range UPPER formatter (0.1 to 0.02 subsection)
    /// - Labels: Values with EVEN last digit (0.08, 0.06, 0.04, 0.02)
    /// - Skips: 0.01 (handled by next subsection as 10⁻²)
    ///
    /// Historical: Faber-Castell 62/83N labels only even-digit hundredths in this range
    public static let ll03MiddleRangeUpper: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        
        // Round to 4 decimal places to avoid floating point issues
        let rounded = (value * 10000).rounded() / 10000
        let formatted = String(format: "%.2f", rounded)
        
        // Skip anything that formats as 0.01 (handled by next subsection as 10⁻²)
        if formatted == "0.01" {
            return ""
        }
        
        // Get the hundredths digit (last significant digit for 0.0X values)
        let hundredths = Int((rounded * 100).rounded()) % 10
        
        // Only label if the hundredths digit is EVEN (2, 4, 6, 8)
        if hundredths % 2 == 0 && hundredths != 0 {
            return String(format: "%.2f", rounded)
        }
        
        // Skip odd digits (1, 3, 5, 7, 9) and 0.10 (handled by previous subsection)
        return ""
    }
    
    /// LL03 middle range LOWER formatter (0.02 to 0.01 subsection)
    /// - Labels: 0.01 as "10⁻²" ONLY
    /// - Skips: 0.02 (already labeled by previous subsection)
    ///
    /// Historical: Faber-Castell 62/83N shows 0.01 as 10⁻²
    public static let ll03MiddleRangeLower: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        
        let rounded = (value * 10000).rounded() / 10000
        
        // 0.01 displays as "10⁻²" - use tight numeric check (within 0.0005)
        // This prevents 0.015 or other nearby values from matching
        if rounded >= 0.0095 && rounded <= 0.0105 {
            return "10⁻²"
        }
        
        // Skip everything else (0.02 is already labeled by previous subsection)
        return ""
    }
    
    /// LL03 lower range formatter (0.01 to 0.001 range)
    /// - Skips 0.01 since it's already labeled as "10⁻²" by the previous subsection
    /// - Uses default formatting for other values
    public static let ll03LowerRange: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite else { return "—" }
        
        // Round to 5 decimal places to avoid floating point issues
        let rounded = (value * 100000).rounded() / 100000
        let formatted = String(format: "%.2f", rounded)
        
        // Skip anything that formats as 0.01 - already labeled as "10⁻²"
        if formatted == "0.01" {
            return ""
        }
        
        // Default formatting for other values (0.009, 0.008, etc.)
        return String(format: "%.3f", rounded)
    }
    
    // MARK: - Decade Region Formatters (0.01 to 0.00001)
    
    /// Helper to convert integer exponent to superscript string
    private static func superscript(_ n: Int) -> String {
        let superscriptDigits: [Character: Character] = [
            "-": "⁻", "0": "⁰", "1": "¹", "2": "²", "3": "³",
            "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
        ]
        return String("\(n)".map { superscriptDigits[$0] ?? $0 })
    }
    
    /// LL03 decade region formatter (0.01 to 0.00001 region)
    /// - Decade boundaries (0.01, 0.001, 0.0001, 0.00001): "10⁻²", "10⁻³", "10⁻⁴", "10⁻⁵"
    /// - Mantissa 5 values (0.005, 0.0005, 0.00005): "5"
    /// - Mantissa 2 values (0.002, 0.0002, 0.00002): "2"
    /// - Other values: "" (no label)
    ///
    /// Historical: Faber-Castell 62/83N shows decade boundaries with exponential notation,
    /// intermediate 5 and 2 positions with mantissa-only labels for visual clarity.
    public static let ll03DecadeRegion: @Sendable (ScaleValue) -> String = { value in
        guard value.isFinite && value > 0 else { return "" }
        
        let log = log10(value)
        let exponent = Int(floor(log))
        let mantissa = value / pow(10.0, Double(exponent))
        
        // Check for decade boundary (mantissa ≈ 1.0)
        // Use tight tolerance for exact power-of-10 detection
        if abs(mantissa - 1.0) < 0.05 {
            return "10" + superscript(exponent)  // e.g., "10⁻²", "10⁻³"
        }
        
        // Check for mantissa ≈ 5
        if abs(mantissa - 5.0) < 0.3 {
            return "5"
        }
        
        // Check for mantissa ≈ 2
        // Use tight tolerance (0.05) to avoid labeling values like 1.9 or 2.2 as "2"
        if abs(mantissa - 2.0) < 0.05 {
            return "2"
        }
        
        // No label for other values
        return ""
    }
}

// MARK: - Negative Log-Log Scales (LL00, LL01, LL02, LL03)
//
// This file implements the reciprocal (negative) Log-Log scales representing e^(-x).
// These scales are used for decay processes, attenuation, and inverse relationships.
//
// SCALE HIERARCHY:
//   LL00: e^(-x/1000)  Range: 0.990 to 0.999   (ultra-precision reciprocal)
//   LL01: e^(-x/100)   Range: 0.905 to 0.990   (small negative powers)
//   LL02: e^(-x/10)    Range: 0.368 to 0.905   (moderate decay)
//   LL03: e^(-x)       Range: 0.00005 to 0.368 (large negative powers)
//
// POSTSCRIPT FORMULA CONCORDANCE:
//   PostScript: {ln neg 1000 mul log}  →  Swift: log10(-log(x) * 1000)  (LL00)
//   PostScript: {ln neg 100 mul log}   →  Swift: log10(-log(x) * 100)   (LL01)
//   PostScript: {ln neg 10 mul log}    →  Swift: log10(-log(x) * 10)    (LL02)
//   PostScript: {ln neg log}           →  Swift: log10(-log(x))         (LL03)
//
// POSTSCRIPT LINE REFERENCES:
//   LL00scale: Lines 730-739  (postscript-engine-for-sliderules.ps)
//   LL01scale: Lines 740-757  (postscript-engine-for-sliderules.ps)
//   LL02scale: Lines 772-784  (postscript-engine-for-sliderules.ps)
//   LL03scale: Lines 785-815  (postscript-engine-for-sliderules.ps)

extension StandardScales {
    
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
            .withLabelColor(.red)  // Red labels
            .withColorApplication(ScaleColorPresets.labelsOnly)  // Apply red color only to labels, not scale
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
            .withLabelColor(.red)  // Red labels
            .withColorApplication((scaleName: true, scaleLabels: true, scaleTicks: true))
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
            .withLabelColor(.red)  // Red color for inverted/reciprocal scale
            .withColorApplication(ScaleColorPresets.all)  // Apply red to all elements (name, labels, ticks)
            .withConstants([
                ScaleConstant(
                    value: 0.36788,  // 1/e at left edge
                    label: "1/e",
                )
            ])
            .build()
    }
    
    // MARK: - LL03 Scale
    
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
            .withRange(begin: 0.4, end: 0.00001)  // Large on left (0.4 ≈ e^-0.92), small on right (10⁻⁵)
            .withLength(length)
            .withTickDirection(.up)
            // Faber-Castell 62/83N: Level 0 and Level 1 ticks same height/font (0.4-0.1 region)
            // Level 0: Primary labels (0.4, 0.3, 0.2, 0.1) - full height
            // Level 1: Secondary labels (0.35, 0.25, 0.15) - SAME full height as primary
            // Level 2: Minor ticks (0.01 interval) - shorter, unlabeled
            // Level 3: Tiny ticks (0.002 interval) - shortest, unlabeled
            .withDefaultTickStyles([
                TickStyle(relativeLength: 0.85, shouldLabel: true, lineWidth: 1.0),   // Level 0: Full height, labeled
                TickStyle(relativeLength: 0.85, shouldLabel: true, lineWidth: 1.0),   // Level 1: Full height, labeled (same as Level 0)
                TickStyle(relativeLength: 0.65, shouldLabel: false, lineWidth: 0.65), // Level 2: Half height, unlabeled
                TickStyle(relativeLength: 0.4, shouldLabel: false, lineWidth: 0.65)  // Level 3: Quarter height, unlabeled
            ])
            .withSubsections([
                // REVERSED ORDER: Largest values (leftmost) to smallest values (rightmost)
                // Based on Faber-Castell 62/83N reference: labels read 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1... down to 10⁻⁵
                
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Near 1/e (0.368), leftmost region of reversed scale
                // Historical: LL03 LEFT side (0.1-0.4 = e^-2.3 to e^-0.92)
                // Labels: Primary (0.4, 0.3, 0.2, 0.1) with 1 decimal, Secondary (0.35, 0.25, 0.15) with 2 decimals
                // Tick marks: 24 ticks between each labeled value (0.05 interval ÷ 25 = 0.002 finest tick)
                //   - 4 ticks at 0.01 intervals + 20 ticks at 0.002 intervals = 24 ticks per label pair
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0, 1],  // Include both primary (0.1) and secondary (0.05) intervals
                    labelFormatter: LL03LabelFormatters.ll03UpperRange
                ),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Mid-upper LL03, transitioning toward smaller values
                // Historical: Faber-Castell 62/83N shows 0.1, 0.08, 0.06, 0.04 with 19 ticks between each
                // Labels: 0.1, 0.08, 0.06, 0.04 at 0.02 intervals
                // Tick marks: 19 ticks between each label (0.02 interval ÷ 20 = 0.001 finest tick)
                //   - Level 0 (0.02): labeled
                //   - Level 1 (0.01): 1 tick mid-way
                //   - Level 2 (0.005): 2 more ticks
                //   - Level 3 (0.001): 16 finest ticks = 19 total
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.02, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: LL03LabelFormatters.ll03MiddleRangeUpper
                ),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Transition zone from 0.02 to 0.01
                // Historical: Faber-Castell 62/83N shows 0.02 and 0.01 (as 10⁻²) with 9 ticks between
                // Labels: 0.02, 0.01 (displayed as "10⁻²")
                // Tick marks: 9 ticks between 0.02 and 0.01 (0.01 interval ÷ 10 = 0.001 finest tick)
                //   - Level 0 (0.01): labeled
                //   - Level 1 (0.005): 1 tick mid-way
                //   - Level 2 (0.001): 8 finest ticks = 9 total
                ScaleSubsection(
                    startValue: 0.02,
                    tickIntervals: [0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: LL03LabelFormatters.ll03MiddleRangeLower
                ),
                // MARK: Decade Region (0.01 to 0.00001) - Faber-Castell 62/83N Pattern
                // Pattern: 10⁻² ... 5 ... 2 ... 10⁻³ ... 5 ... 2 ... 10⁻⁴ ... 5 ... 2 ... 10⁻⁵
                // "5" labels come from subsection primary ticks (level 0) with custom formatter
                // "2" labels come from ScaleConstants (gauge marks)
                //
                // Tick counts from actual Faber-Castell 62/83N measurement:
                // 10⁻² to 10⁻³ decade:
                //   - 10⁻² → 5: 24 ticks over 0.005 range
                //   - 5 → 2:    14 ticks over 0.003 range
                //   - 2 → 10⁻³: 4 ticks over 0.001 range
                // 10⁻³ to 10⁻⁴ decade:
                //   - 10⁻³ → 5: 9 ticks over 0.0005 range
                //   - 5 → 2:    14 ticks over 0.0003 range
                //   - 2 → 10⁻⁴: 4 ticks over 0.0001 range
                // 10⁻² to 5 segment (0.01 to 0.005)
                // INTERMEDIATE TICKS: Use TWO dummy level 0 and 1 intervals (10.0, 10.0) that never generate ticks
                // This shifts actual intervals (0.001, 0.0002) to levels 2 and 3, making them shorter (0.65 and 0.4 relative height)
                ScaleSubsection(
                    startValue: 0.01,
                    tickIntervals: [10.0, 10.0, 0.001, 0.0002],  // 10.0 at levels 0,1 never fire; 0.001 at level 2, 0.0002 at level 3
                    labelLevels: [],  // No labels in this segment - 10⁻² handled by previous subsection
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
                ),
                // 5 position - enable label for "5"
                // This subsection starts exactly at 0.005 so the first tick (level 0) is "5"
                // Level 0 is used ONLY for the starting "5" label, intermediates are levels 1-2
                ScaleSubsection(
                    startValue: 0.005,
                    tickIntervals: [0.003, 0.001, 0.0002],  // Level 0 for "5" label at start, levels 1-2 for intermediates
                    labelLevels: [0],  // Label level 0 to show "5"
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion  // Handles "5", "2", and decade boundaries
                ),
                // 2 position at 0.002 - enable label for "2"
                // Level 0 interval (0.002) is larger than subsection range, so only startValue gets level 0
                // This prevents generating a tick at 0.001 which would steal the decade boundary label
                ScaleSubsection(
                    startValue: 0.002,
                    tickIntervals: [0.002, 0.0001],  // Level 0 only at 0.002; level 1 for intermediates
                    labelLevels: [0],  // Label level 0 to show "2"
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion  // Handles "5", "2", and decade boundaries
                ),
                // 10⁻³ DECADE BOUNDARY AND 10⁻³ to 5 segment (0.001 to 0.0005)
                // Level 0 at 0.0005 generates tick at start value 0.001 for "10⁻³" label
                ScaleSubsection(
                    startValue: 0.001,
                    tickIntervals: [0.0005, 0.0001, 0.00005],  // 0.0005 generates level 0 tick at 0.001
                    labelLevels: [0],  // Enable label at decade boundary
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
                ),
                // 5 position at 0.0005 - enable label for "5"
                // Level 0 is used ONLY for the starting "5" label, intermediates are levels 1-2
                ScaleSubsection(
                    startValue: 0.0005,
                    tickIntervals: [0.0003, 0.0001, 0.00002],  // Level 0 for "5" label at start, levels 1-2 for intermediates
                    labelLevels: [0],  // Label level 0 to show "5"
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion  // Handles "5", "2", and decade boundaries
                ),
                // 2 position at 0.0002 - enable label for "2"
                // Level 0 interval (0.0002) is larger than subsection range, so only startValue gets level 0
                // This prevents generating a tick at 0.0001 which would steal the decade boundary label
                ScaleSubsection(
                    startValue: 0.0002,
                    tickIntervals: [0.0002, 0.00001],  // Level 0 only at 0.0002; level 1 for intermediates
                    labelLevels: [0],  // Label level 0 to show "2"
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion  // Handles "5", "2", and decade boundaries
                ),
                
                // 10⁻⁴ DECADE BOUNDARY AND 10⁻⁴ to 5 segment (0.0001 to 0.00005)
                // Level 0 at 0.00005 generates tick at start value 0.0001 for "10⁻⁴" label
                ScaleSubsection(
                    startValue: 0.0001,
                    tickIntervals: [0.00005, 0.00001, 0.000005],  // 0.00005 generates level 0 tick at 0.0001
                    labelLevels: [0],  // Enable label at decade boundary
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
                ),
                // 5 position at 0.00005 - enable label for "5"
                // Level 0 is used ONLY for the starting "5" label, intermediates are levels 1-2
                ScaleSubsection(
                    startValue: 0.00005,
                    tickIntervals: [0.00003, 0.00001, 0.000002],  // Level 0 for "5" label at start, levels 1-2 for intermediates
                    labelLevels: [0],  // Label level 0 to show "5"
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion  // Handles "5", "2", and decade boundaries
                ),
                // 2 position at 0.00002 - enable label for "2"
                // Level 0 interval (0.00002) is larger than subsection range, so only startValue gets level 0
                // This prevents generating a tick at 0.00001 which would steal the decade boundary label
                ScaleSubsection(
                    startValue: 0.00002,
                    tickIntervals: [0.00002, 0.000001],  // Level 0 only at 0.00002; level 1 for intermediates
                    labelLevels: [0],  // Label level 0 to show "2"
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion  // Handles "5", "2", and decade boundaries
                ),
                // 10⁻⁵ DECADE BOUNDARY (0.00001 = 10⁻⁵) - MUST show "10⁻⁵" label
                // This is the final decade boundary at the end of the scale
                ScaleSubsection(
                    startValue: 0.00001,
                    tickIntervals: [0.000005, 0.000001],  // Level 0 for "10⁻⁵" label at boundary
                    labelLevels: [0],  // Enable label at decade boundary
                    labelFormatter: LL03LabelFormatters.ll03DecadeRegion
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.fourDecimals)
            .withLabelColor(.red)  // Red labels
            .withColorApplication((scaleName: true, scaleLabels: true, scaleTicks: true))
            .withConstants([
                ScaleConstant(
                    value: 0.36788,  // 1/e
                    label: "1/e"
                )
                // NOTE: "2" labels (0.002, 0.0002, 0.00002) are now generated via subsection
                // labeling with labelLevels: [0], not ScaleConstants. This ensures they appear
                // with source: .subsection and allows proper tick level styling.
            ])
            .build()
    }
}
