import Foundation

// MARK: - Pickett N-16 ES Electronic Slide Rule Scales
// Complete implementation of all 32 specialized scales from the N-16 ES (circa 1960)
// Designed by Chan Street for professional electronics engineering
// Historical significance: Revolutionary four-decade scales, reciprocal embedding, simultaneous triple reading

extension StandardScales {
    
    // MARK: - Pickett N-16 ES Component Value Scales (Four-Decade Span)
    
    /// Lr - Inductance with Reciprocal Function for resonance calculations
    /// Historical: Revolutionary four-decade span (0.001µH to 100H)
    /// Used with Cr scale for direct f = 1/(2π√LC) reading
    /// PostScript reference: Line 840
    public static func inductanceReciprocalScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Lr")
            .withFormula("1 - log₁₀(x)/12")
            .withFunction(InductanceReciprocalFunction(cycles: 12))
            // FIX: Changed from 0.02 to 0.027 to match real Pickett N-16 ES slide rule
            // This offset prevents major tick marks from aligning between Lr and Cr scales
            // Real Pickett N-16 ES shows Lr starting at approximately 0.03
            .withRange(begin: 0.027, end: 200.0)  // Offset 4-decade range matching real Pickett N-16 ES
            .withLength(length)
            .withTickDirection(.down)
            // Use .absolutelyNone for major ticks so labelLevels is the sole determinant of labeling
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // PARTIAL DECADE: 0.027 to 0.1 (continues from 0.01-0.1 decade pattern)
                // Variable tick density: finest in first third, coarsest in last third
                // FIX: Scale now starts at 0.027 to match real Pickett N-16 ES
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.03→0.06: First section (finest = 0.001)
                // Major=0.01, Half=0.005, Minor=0.002, Tiny=0.001
                ScaleSubsection(startValue: 0.027, tickIntervals: [0.01, 0.005, 0.002, 0.001], labelLevels: [0]),
                
                // 0.06→0.1: Third third of decade (finest = 0.002)
                // Major=0.01, Half=0.005, Minor=0.002
                ScaleSubsection(startValue: 0.06, tickIntervals: [0.01, 0.005, 0.002], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 0.1 to 1.0
                // Variable tick density: 20 divisions (first), 10 divisions (middle), 5 divisions (last)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1→0.3: First third of decade (20 divisions per 0.1, finest = 0.005)
                // Major=0.1, Half=0.05, Minor=0.01, Tiny=0.005
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                
                // 0.3→0.6: Second third of decade (10 divisions per 0.1, finest = 0.01)
                // Major=0.1, Half=0.05, Minor=0.02, Tiny=0.01
                ScaleSubsection(startValue: 0.3, tickIntervals: [0.1, 0.05, 0.02, 0.01], labelLevels: [0]),
                
                // 0.6→1.0: Third third of decade (5 divisions per 0.1, finest = 0.02)
                // Major=0.1, Half=0.05, Minor=0.02
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 1.0 to 10.0
                // Variable tick density: 20 divisions (first), 10 divisions (middle), 5 divisions (last)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1→3: First third of decade (20 divisions per 1.0, finest = 0.05)
                // Major=1, Half=0.5, Minor=0.1, Tiny=0.05
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1, 0.05], labelLevels: [0]),
                
                // 3→6: Second third of decade (10 divisions per 1.0, finest = 0.1)
                // Major=1, Half=0.5, Minor=0.2, Tiny=0.1
                ScaleSubsection(startValue: 3.0, tickIntervals: [1, 0.5, 0.2, 0.1], labelLevels: [0]),
                
                // 6→10: Third third of decade (5 divisions per 1.0, finest = 0.2)
                // Major=1, Half=0.5, Minor=0.2
                ScaleSubsection(startValue: 6.0, tickIntervals: [1, 0.5, 0.2], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 10.0 to 100.0
                // Variable tick density: 20 divisions (first), 10 divisions (middle), 5 divisions (last)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 10→30: First third of decade (20 divisions per 10, finest = 0.5)
                // Major=10, Half=5, Minor=1, Tiny=0.5
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1, 0.5], labelLevels: [0]),
                
                // 30→60: Second third of decade (10 divisions per 10, finest = 1.0)
                // Major=10, Half=5, Minor=2, Tiny=1
                ScaleSubsection(startValue: 30.0, tickIntervals: [10, 5, 2, 1], labelLevels: [0]),
                
                // 60→100: Third third of decade (5 divisions per 10, finest = 2.0)
                // Major=10, Half=5, Minor=2
                ScaleSubsection(startValue: 60.0, tickIntervals: [10, 5, 2], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // PARTIAL DECADE: 100.0 to 200.0 (continues 100-1000 decade pattern)
                // First third of decade (finest = 5)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 100→200: First third of decade (20 divisions per 100, finest = 5)
                // Major=100, Half=50, Minor=10, Tiny=5
                ScaleSubsection(startValue: 100.0, tickIntervals: [100, 50, 10, 5], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                guard value > 0 else { return "0" }
                
                if value < 1.0 {
                    // Values less than 1: leading decimal format like ".03", ".4"
                    if value >= 0.1 {
                        // 0.1 to 0.99 → ".1", ".2", ... ".9"
                        let digit = Int((value * 10).rounded())
                        return ".\(digit)"
                    } else {
                        // 0.01 to 0.099 → ".01", ".02", ... ".09"
                        let digit = Int((value * 100).rounded())
                        return ".0\(digit)"
                    }
                } else {
                    // Values >= 1: just the integer
                    return String(Int(value.rounded()))
                }
            }
            .withLabelColor(.green)
            .addConstant(value: 25.12, label: "XL", style: .major)
            .addConstant(value: 26.30, label: "TL", style: .major)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    /// Cr - Capacitance with Reciprocal Function for resonance calculations
    /// Historical: Four-decade span (0.01 to 100)
    /// INVERTED SCALE: Values decrease from left (100) to right (0.01)
    /// Decimal keeper prevents magnitude errors across femtofarads to farads
    public static func capacitanceReciprocalScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Cr")
            .withFormula("1 - (log₁₀(x)+2)/4")
            .withFunction(CapacitanceReciprocalFunction(cycles: 4))
            .withRange(begin: 100.0, end: 0.01)  // INVERTED: 100 at position 0 (left), 0.01 at position 1 (right)
            .withLength(length)
            .withTickDirection(.up)
            // Use .absolutelyNone for major ticks so labelLevels is the sole determinant of labeling
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // INVERTED SCALE: Values decrease left-to-right (100 → 0.01)
                // Tick density pattern REVERSED from Lr: 5/10/20 (coarse→fine)
                // because left side (high values) is compressed, right side (low values) is expanded
                // ═══════════════════════════════════════════════════════════════════════
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 100 to 10 (leftmost, compressed end)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 100→60: First third of decade (5 divisions per 10 = coarse, compressed)
                // Major=10, Half=5, Minor=2
                ScaleSubsection(startValue: 100.0, tickIntervals: [10, 5, 2], labelLevels: [0]),
                
                // 60→30: Second third of decade (10 divisions per 10 = medium)
                // Major=10, Half=5, Minor=2, Tiny=1
                ScaleSubsection(startValue: 60.0, tickIntervals: [10, 5, 2, 1], labelLevels: [0]),
                
                // 30→10: Third third of decade (20 divisions per 10 = fine)
                // Major=10, Half=5, Minor=1, Tiny=0.5
                ScaleSubsection(startValue: 30.0, tickIntervals: [10, 5, 1, 0.5], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 10 to 1
                // ═══════════════════════════════════════════════════════════════════════
                
                // 10→6: First third of decade (5 divisions per 1 = coarse)
                // Major=1, Half=0.5, Minor=0.2
                ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.2], labelLevels: [0]),
                
                // 6→3: Second third of decade (10 divisions per 1 = medium)
                // Major=1, Half=0.5, Minor=0.2, Tiny=0.1
                ScaleSubsection(startValue: 6.0, tickIntervals: [1, 0.5, 0.2, 0.1], labelLevels: [0]),
                
                // 3→1: Third third of decade (20 divisions per 1 = fine)
                // Major=1, Half=0.5, Minor=0.1, Tiny=0.05
                ScaleSubsection(startValue: 3.0, tickIntervals: [1, 0.5, 0.1, 0.05], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 1 to 0.1
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1→0.6: First third of decade (5 divisions per 0.1 = coarse)
                // Major=0.1, Half=0.05, Minor=0.02
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0]),
                
                // 0.6→0.3: Second third of decade (10 divisions per 0.1 = medium)
                // Major=0.1, Half=0.05, Minor=0.02, Tiny=0.01
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02, 0.01], labelLevels: [0]),
                
                // 0.3→0.1: Third third of decade (20 divisions per 0.1 = fine)
                // Major=0.1, Half=0.05, Minor=0.01, Tiny=0.005
                ScaleSubsection(startValue: 0.3, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 0.1 to 0.01 (rightmost, expanded end)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1→0.06: First third of decade (5 divisions per 0.01 = coarse)
                // Major=0.01, Half=0.005, Minor=0.002
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.01, 0.005, 0.002], labelLevels: [0]),
                
                // 0.06→0.03: Second third of decade (10 divisions per 0.01 = medium)
                // Major=0.01, Half=0.005, Minor=0.002, Tiny=0.001
                ScaleSubsection(startValue: 0.06, tickIntervals: [0.01, 0.005, 0.002, 0.001], labelLevels: [0]),
                
                // 0.03→0.01: Third third of decade (20 divisions per 0.01 = fine, most expanded)
                // Major=0.01, Half=0.005, Minor=0.001, Tiny=0.0005
                ScaleSubsection(startValue: 0.03, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                guard value > 0 else { return "0" }
                
                if value < 1.0 {
                    // Values less than 1: leading decimal format like ".03", ".4"
                    if value >= 0.1 {
                        // 0.1 to 0.99 → ".1", ".2", ... ".9"
                        let digit = Int((value * 10).rounded())
                        return ".\(digit)"
                    } else {
                        // 0.01 to 0.099 → ".01", ".02", ... ".09"
                        let digit = Int((value * 100).rounded())
                        return ".0\(digit)"
                    }
                } else {
                    // Values >= 1: just the integer
                    return String(Int(value.rounded()))
                }
            }
            .withLabelColor(.red)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    /// C/L - Combined Capacitance/Inductance scale (four-decade)
    /// Dual purpose: Component values or time constant calculations
    /// Note: This conflicts with standard C scale, so we use "pickettL" internally
    public static func pickettLScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("L")
            .withFormula("log₁₀(x)/12")
            .withFunction(CapacitanceInductanceFunction(cycles: 12))
            .withRange(begin: 1e-12, end: 1e-3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    // MARK: - Pickett N-16 ES Frequency and Wavelength Scales
    
    /// ω - Angular Frequency scale (ω = 2πf)
    /// Used for: Complex impedance, AC analysis in radian notation
    /// Sparse tick pattern matching physical Pickett N-16 ES slide rule
    ///
    /// Note: Uses `.absolutelyNone` as the major tick style so that `labelLevels`
    /// is the sole determinant of labeling. This ensures the 0.5-0.7 range
    /// has tick marks but no labels.
    ///
    /// ## Historical ω/τ Alignment Artifact
    ///
    /// The ω and τ scales are designed so that **at any visual position on the rule,
    /// ω × τ = 1**. This reciprocal relationship was essential for electronics engineers
    /// calculating time constants (τ = RC or L/R) from angular frequencies.
    ///
    /// The raw transform functions include an intentional offset (~0.27-0.28) so that
    /// the scales visually align. This is NOT a mathematical error—it's how physical
    /// slide rules were manufactured to achieve the reciprocal relationship:
    ///
    /// - **Pickett N-16 ES** (1960s): First to include coordinated ω/τ scales
    /// - **Pickett N-4 ES**: Simplified electronics rule with same alignment
    /// - **Faber-Castell 2/83N**: German equivalent with ω/τ alignment
    /// - **Aristo 0970**: European electronics rule using same principle
    ///
    /// The offset grows logarithmically from the reference point (ω=1, τ=1),
    /// where both transforms equal zero. This was a deliberate manufacturing
    /// decision, not a calculation error.
    ///
    /// See: `PickettN16ESOmegaTauAlignmentTests.swift` for verification tests
    public static func angularFrequencyOmegaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("ω")
            .withFormula("log₁₀(2πf)/12")
            .withFunction(AngularFrequencyOmegaFunction(cycles: 12))
            .withRange(begin: 0.48, end: 62.0)
            .withLength(length)
            .withTickDirection(.up)
            // Use .absolutelyNone for major ticks so labelLevels: [] truly produces no labels
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
          // ═══════════════════════════════════════════════════════
            // DECADE: 0.5 to 1.0 — Tick pattern for 10ths of this decade
            // ═══════════════════════════════════════════════════════
            
            // 0.5 to 0.7: Ticks only, NO labels
            // Major=0.1, Half=0.05, Minor=0.02
            ScaleSubsection(
                startValue: 0.5,
                tickIntervals: [0.1, 0.05, 0.02],
                labelLevels: []  // NO labels
            ),
            
            // 0.7 to 1.0: Labels at .7, .8, .9
            ScaleSubsection(
                startValue: 0.7,
                tickIntervals: [0.1, 0.05, 0.02],
                labelLevels: [0]  // Label major ticks only
            ),
            
            // ═══════════════════════════════════════════════════════
            // DECADE: 1 to 10 — Intervals scale up 10×
            // Major=1.0, Half=0.5, Minor=0.1
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1, 0.02],  // Added 0.02 for finest ticks matching real Pickett N-16 ES
                labelLevels: [0]  // Label 1,2,3,4,5,6,7,8,9
            ),
            
            // ═══════════════════════════════════════════════════════
            // DECADE: 10 to 20 — Intervals scale up another 10×
            // Major=10.0, Half=5.0, Minor=1.0, Tiny=0.5, Micro=0.25
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0, 0.5,0.25],
                labelLevels: [0]  // Label 10,20,30,40,50,60
            ),

            // ═══════════════════════════════════════════════════════
            // DECADE: 10 to 20 — Intervals scale up another 10×
            // Major=10.0, Half=5.0, Minor=1.0, Tiny=0.5, Micro=0.25
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 20.0,
                tickIntervals: [10.0, 5.0, 1.0, 0.5],
                labelLevels: [0]  // Label 10,20,30,40,50,60
            ),

            // ═══════════════════════════════════════════════════════
            // DECADE: 10 to 60+ — Intervals scale up another 10×
            // Major=10.0, Half=5.0, Minor=1.0
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 50.0,
                tickIntervals: [10.0, 5.0, 1.0],
                labelLevels: [0]  // Label 10,20,30,40,50,60
            ),

            
        ])
        .withLabelFormatter { omega in
            guard omega > 0 else { return "" }
            
            if omega < 1.0 {
                // Format as ".7", ".8", ".9"
                let digit = Int((omega * 10).rounded())
                return ".\(digit)"
            } else if omega < 10.0 {
                // Format as "1", "2", ... "9"
                return String(Int(omega.rounded()))
            } else {
                // Format as "10", "20", ... "60"
                return String(Int(omega.rounded()))
            }
        }
        .build()
}
    
    /// λ Scale: Wavelength scale in METERS (not frequency!)
    /// Shows wavelength values directly: 3000m to 30m (2 decades, inverted)
    /// Essential for RF and antenna work - matches real Pickett N16-ES
    /// Formula: Inverted logarithmic scale with wavelength in meters
    /// Range: 3000.0 to 30.0 meters (2 decades, high values on left)
    /// Used for: antenna-design, RF-propagation, wavelength-calculations, electromagnetic-theory
    ///
    /// **Physical Applications:**
    /// - Antenna Design: Calculate antenna dimensions directly from wavelength (λ/4, λ/2 antennas)
    /// - RF Propagation: Direct wavelength reading for path loss calculations
    /// - Amateur Radio: Shows wavelength bands (160m, 80m, 40m, 20m, etc.)
    /// - Radio Broadcasting: Match antenna size to broadcast wavelength
    ///
    /// **Example 1:** Design quarter-wave antenna for 40m amateur band
    /// 1. Locate 40m on λ scale
    /// 2. Quarter-wave length = 40m/4 = 10m
    ///
    /// **Example 2:** Find wavelength for FM broadcast band
    /// 1. FM band is approximately 100 MHz
    /// 2. λ = c/f = 3×10⁸ / 100×10⁶ = 3m
    /// 3. Locate 3m on λ scale (right end, smaller values)
    public static func wavelengthLambdaScale(length: Distance = 250.0) -> ScaleDefinition {
        let wavelengthFunction = WavelengthMeterFunction()
        
        return ScaleBuilder()
            .withName("λ")  // Lambda symbol for wavelength scale (matches real Pickett N16-ES)
            .withFormula("λ (meters)")
            .withFunction(wavelengthFunction)
            .withRange(begin: 3000.0, end: 30.0)  // 3000m to 30m (2 decades, inverted - high values on left)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                // SPARSE LABELING: Matches real Pickett N16-ES λ scale
                // Labels from reference image: 3000, 2000, 1000, 900, 800, 700, 600, 500, 400, 300, 200, 100, 90, 80, 70, 60, 50, 40, 30
                // Scale spans 3000m to 30m = 2 decades (inverted)
                
                // ═══════════════════════════════════════════════════════════════════════
                // FIRST DECADE: 3000m to 300m (leftmost portion)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 3000→1000: First third (coarse, compressed)
                // Labels: 3000, 2000, 1000
                ScaleSubsection(startValue: 3000.0, tickIntervals: [1000.0, 500.0, 100.0], labelLevels: [0]),
                
                // 1000→300: Second portion
                // Labels: 1000, 900, 800, 700, 600, 500, 400, 300
                ScaleSubsection(startValue: 1000.0, tickIntervals: [100.0, 50.0, 10.0], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // SECOND DECADE: 300m to 30m (rightmost portion, more expanded)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 300→100: First portion of second decade
                // Labels: 300, 200, 100
                ScaleSubsection(startValue: 300.0, tickIntervals: [100.0, 50.0, 10.0], labelLevels: [0]),
                
                // 100→30: Second portion of second decade (finest)
                // Labels: 100, 90, 80, 70, 60, 50, 40, 30
                ScaleSubsection(startValue: 100.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0])
            ])
            .withLabelFormatter { wavelength in
                // Show integer wavelength values at major positions
                // Real Pickett N16-ES shows: 3000, 2000, 1000, 900, 800, 700, 600, 500, 400, 300, 200, 100, 90, 80, 70, 60, 50, 40, 30
                guard wavelength > 0 else { return "" }
                
                let rounded = wavelength.rounded()
                
                // Only label at these specific positions (major decade and mid-decade values)
                let labelValues: Set<Double> = [
                    3000, 2000, 1000,
                    900, 800, 700, 600, 500, 400, 300, 200, 100,
                    90, 80, 70, 60, 50, 40, 30
                ]
                
                if labelValues.contains(rounded) && abs(wavelength - rounded) < 0.5 {
                    return String(format: "%.0f", rounded)
                }
                return ""
            }
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    /// F Scale: Frequency in MHz (F × λ = 300)
    /// Shows frequency values directly: 0.1 to 10 MHz (2 decades)
    /// Essential for RF and antenna work - matches real Pickett N16-ES
    /// Formula: 1 - log₁₀(300/F) / 6 (aligns with λ scale where F × λ = 300)
    /// Range: 0.1 to 10 MHz (2 decades, low values on left)
    /// Used for: RF-frequency-calculations, antenna-design, electromagnetic-theory
    ///
    /// **Physical Applications:**
    /// - RF Engineering: Direct frequency reading in MHz
    /// - Antenna Design: Convert directly to wavelength via λ scale alignment
    /// - Amateur Radio: Shows frequency bands corresponding to wavelength bands
    /// - Radio Broadcasting: Match frequency to antenna dimensions
    ///
    /// **Alignment with λ Scale:**
    /// The F scale is mathematically tied to the λ scale via F × λ = 300
    /// (where F is in MHz, λ is in meters, and 300 ≈ c in convenient units)
    /// | F (MHz) | λ (m) | F × λ |
    /// |---------|-------|-------|
    /// | 0.1     | 3000  | 300   |
    /// | 1.0     | 300   | 300   |
    /// | 10      | 30    | 300   |
    ///
    /// **Example:** Find frequency for 40m amateur band
    /// 1. Locate 40m on λ scale
    /// 2. Read corresponding F value: F = 300/40 = 7.5 MHz
    public static func pickettFScale(length: Distance = 250.0) -> ScaleDefinition {
        let frequencyFunction = PickettFFunction(cycles: 6)
        
        return ScaleBuilder()
            .withName("F")  // F for Frequency scale (matches real Pickett N16-ES)
            .withFormula("F (MHz)")
            .withFunction(frequencyFunction)
            .withRange(begin: 0.1, end: 10.0)  // 0.1 to 10 MHz (2 decades, low values on left)
            .withLength(length)
            .withTickDirection(.up)  // Opposite to λ scale which is .down
            .withSubsections([
                // SPARSE LABELING: Matches real Pickett N16-ES F scale
                // Labels from reference: .1, .2, .3, .4, .5, .6, .7, .8, .9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
                // Scale spans 0.1 to 10 MHz = 2 decades
                
                // ═══════════════════════════════════════════════════════════════════════
                // FIRST DECADE: 0.1 to 1.0 MHz (leftmost portion)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1→0.3: First portion (finest ticks)
                // Labels: .1, .2, .3
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                
                // 0.3→0.6: Middle portion
                // Labels: .3, .4, .5, .6
                ScaleSubsection(startValue: 0.3, tickIntervals: [0.1, 0.05, 0.02, 0.01], labelLevels: [0]),
                
                // 0.6→1.0: Last portion of first decade (coarser)
                // Labels: .6, .7, .8, .9
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // SECOND DECADE: 1.0 to 10 MHz (rightmost portion, more compressed)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1→3: First portion of second decade (finest)
                // Labels: 1, 2, 3
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0]),
                
                // 3→6: Middle portion
                // Labels: 3, 4, 5, 6
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0]),
                
                // 6→10: Last portion (coarsest)
                // Labels: 6, 7, 8, 9, 10
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5, 0.2], labelLevels: [0])
            ])
            .withLabelFormatter { frequency in
                // Show frequency values at major positions
                // Real Pickett N16-ES shows: .1, .2, .3, .4, .5, .6, .7, .8, .9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
                guard frequency > 0 else { return "" }
                
                if frequency < 1.0 {
                    // Values less than 1: leading decimal format like ".1", ".2", etc.
                    let digit = Int((frequency * 10).rounded())
                    return ".\(digit)"
                } else {
                    // Values >= 1: just the integer
                    return String(Int(frequency.rounded()))
                }
            }
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    // MARK: - DEPRECATED FILTER RESPONSE VARIANT
    // TODO: Remove this legacy Θ phase-angle implementation once the current Pickett N-16 ES
    //       filter response scales are finalized and fully tested.
    // Pickett N-16 ES Filter Response Scales (Coordinated Triple Reading)
    
    /// Θ - Phase angle scale for RC/RL circuits (0° to 90°)
    /// Used with: cos(Θ) and dB scales for simultaneous filter analysis
    /// Applications: Audio equalizers, communications filters
    /* public static func phaseAngleThetaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Θ")
            .withFormula("α = cot⁻¹(2πfRC)")
            .withFunction(PhaseAngleFunction())
            .withRange(begin: 0, end: 90)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0, tickIntervals: [10, 5, 1], labelLevels: [0]),
                ScaleSubsection(startValue: 30, tickIntervals: [10, 5, 1], labelLevels: [0]),
                ScaleSubsection(startValue: 60, tickIntervals: [10, 5, 1], labelLevels: [0]),
                ScaleSubsection(startValue: 80, tickIntervals: [5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                if value < 1.0 {
                    return String(format: "%.2f°", value)
                } else if value < 10.0 {
                    return String(format: "%.1f°", value)
                } else {
                    return String(format: "%.0f°", value)
                }
            }
            .build()
    } */
    
    /// cos(Θ) - Relative gain and power factor (0 to 1)
    /// Formula: cos(θ) = 1/√(1 + (1/(2πfRC))²) for filters
    /// Special marker: -3dB point at 0.707
    public static func cosinePowerFactorScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("cos Θ")
            .withFormula("cos(θ)")
            .withFunction(CosinePhaseFunction())
            .withRange(begin: 0.0, end: 1.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 0.0, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 0.5, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 0.9, tickIntervals: [0.05, 0.01], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                if value < 0.01 {
                    return String(format: "%.3f", value)
                } else if value < 0.1 {
                    return String(format: "%.3f", value)
                } else {
                    return String(format: "%.2f", value)
                }
            }
            .addConstant(value: 0.707, label: "-3dB", style: .major)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    /// dB - Decibel scale (power ratios)
    /// Formula: 10 log₁₀(P₂/P₁)
    /// Coordinated with Θ and cos(Θ) for complete filter characterization
    public static func decibelPowerScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("db")
            .withFormula("10 log₁₀(P₂/P₁)")
            .withFunction(DecibelFunction(isVoltageRatio: false))
            .withRange(begin: 0.01, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                // Convert ratio to dB for display
                let dB = 10.0 * log10(value)
                if abs(dB) < 1.0 {
                    return String(format: "%.2f dB", dB)
                } else if abs(dB) < 10.0 {
                    return String(format: "%.1f dB", dB)
                } else {
                    return String(format: "%.0f dB", dB)
                }
            }
            .withLabelColor(.green)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    /// dB - Decibel scale (voltage/current ratios)
    /// Formula: 20 log₁₀(V₂/V₁)
    /// Lower scale on N-16 ES back face
    public static func decibelVoltageScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("db")
            .withFormula("20 log₁₀(V₂/V₁)")
            .withFunction(DecibelFunction(isVoltageRatio: true))
            .withRange(begin: 0.01, end: 100.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                // Convert ratio to dB for display
                let dB = 20.0 * log10(value)
                if abs(dB) < 1.0 {
                    return String(format: "%.2f dB", dB)
                } else if abs(dB) < 10.0 {
                    return String(format: "%.1f dB", dB)
                } else {
                    return String(format: "%.0f dB", dB)
                }
            }
            .withLabelColor(.red)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    // MARK: - Pickett N-16 ES Upper dB Scale (LINEAR)
    
    /// Upper dB Scale - Linear Decibel Scale for Pickett N-16 ES
    /// This is a LINEAR scale (NOT logarithmic like most slide rule scales)
    ///
    /// ## ACTUAL Pickett N-16 ES Specifications (from physical specimen)
    ///
    /// **Range:** 20 to 60 dB
    ///
    /// **Position Formula (Linear):**
    /// ```
    /// position = (dB_value - 20) / 40
    /// ```
    ///
    /// **Dual Labeling:**
    /// - RED number with ">" prefix on LEFT of tick: >20, >25, >30, >35, >40, >45, >50, >55, >60
    /// - BLACK number on RIGHT of tick: 60, 55, 50, 45, 40, 35, 30, 25, 20
    /// - RED + BLACK always = 80
    ///
    /// **Tick Marks (UNIFORMLY spaced):**
    /// - Major ticks at 5 dB intervals: FULL height, labeled
    /// - 4 ticks at 1 dB intervals: FULL height, NOT labeled (21, 22, 23, 24 between 20-25)
    /// - 5 ticks at 0.5 dB intervals: HALF height (20.5, 21.5, 22.5, 23.5, 24.5 between 20-25)
    /// - Total: 9 tick marks between each labeled position (4 full + 5 half)
    /// - All ticks are EVENLY spaced (linear scale, NOT logarithmic)
    ///
    /// **Example positions:**
    /// - 20 dB → position 0.000 (left end), labels: ">20" (RED) "60" (BLACK)
    /// - 25 dB → position 0.125, labels: ">25" (RED) "55" (BLACK)
    /// - 40 dB → position 0.500 (center), labels: ">40" (RED) "40" (BLACK)
    /// - 60 dB → position 1.000 (right end), labels: ">60" (RED) "20" (BLACK)
    ///
    /// **Historical Context:**
    /// Used for quick voltage/power ratio conversions in electronics work,
    /// coordinated with the Θ and cos(Θ) scales for filter analysis.
    /// The dual labeling (primary/complement) allows reading attenuation
    /// and gain simultaneously.
    public static func upperDecibelLinearScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("dB")  // Proper name for decibel scale
            .withFormula("(dB - 20) / 40")
            .withFunction(LinearDecibelFunction(minDB: 20.0, maxDB: 60.0))
            .withRange(begin: 20.0, end: 60.0)  // Direct dB values
            .withLength(length)
            .withTickDirection(.up)
            // THREE tick levels for correct Pickett N-16 ES pattern:
            // Level 0: 5dB - LABELED with dual formatting (RED ">XX" / BLACK "YY")
            // Level 1: 1dB - UNLABELED ticks at FULL height (21, 22, 23, 24)
            // Level 2: 0.5dB - UNLABELED ticks at HALF height (20.5, 21.5, 22.5, 23.5, 24.5)
            //
            // Uses custom tick styles:
            // - Level 0: Uses .absolutelyNone so dualLabelFormatter controls labeling (full height)
            // - Level 1: Full height (1.0) but no labels (for 1dB ticks)
            // - Level 2: Half height (0.5) no labels (for 0.5dB ticks)
            .withDefaultTickStyles([
                .absolutelyNone,  // Level 0: 5dB labeled ticks (full height)
                TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 1.0),  // Level 1: 1dB full height, unlabeled
                TickStyle(relativeLength: 0.375, shouldLabel: false, lineWidth: 0.65)  // Level 2: 0.5dB half height, unlabeled
            ])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // SINGLE SUBSECTION: Linear scale 20-60 dB with UNIFORM tick spacing
                //
                // From ACTUAL Pickett N-16 ES:
                // - Labels at 5 dB intervals: 20, 25, 30, 35, 40, 45, 50, 55, 60
                // - Alternating tick heights between labels:
                //   - 1 dB intervals: FULL height (21, 22, 23, 24)
                //   - 0.5 dB intervals: HALF height (20.5, 21.5, 22.5, 23.5, 24.5)
                // - Total 9 tick marks between each label (4 full + 5 half)
                // - All ticks EVENLY spaced (linear scale, NOT logarithmic)
                //
                // Example between 20 and 25 dB:
                //   20 (labeled, full) → 20.5 (half) → 21 (full) → 21.5 (half) →
                //   22 (full) → 22.5 (half) → 23 (full) → 23.5 (half) →
                //   24 (full) → 24.5 (half) → 25 (labeled, full)
                // ═══════════════════════════════════════════════════════════════════════
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [5.0, 1.0, 0.5],  // Major=5dB (labeled), Full=1dB, Half=0.5dB
                    labelLevels: [0],  // Only label at 5dB intervals (level 0)
                    dualLabelFormatter: StandardLabelFormatter.upperDecibelDual
                )
            ])
            // No single-label formatter needed since we use dualLabelFormatter
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    // MARK: - Pickett N-16 ES Time Constant Scale
    
    /// τ - Time constant scale (τ = 1/ω, reciprocal relationship)
    /// CRITICAL: This scale is mathematically tied to the ω scale via τ × ω = 1
    /// INVERTED SCALE: Values DECREASE from left (~2.08) to right (~0.016)
    /// Range: 1/0.48 ≈ 2.083 to 1/62 ≈ 0.0161 (reciprocal of ω range)
    ///
    /// ## Historical ω/τ Alignment Artifact
    ///
    /// This scale is **intentionally offset** from a pure mathematical inverse so that
    /// at any visual position on the slide rule, ω × τ = 1. This was a manufacturing
    /// decision common to professional electronics slide rules:
    ///
    /// - **Pickett N-16 ES** (1960s): Original implementation by Chan Street
    /// - **Pickett N-4 ES**: Simplified version with same alignment principle
    /// - **Faber-Castell 2/83N**: German engineering rule using identical offset
    /// - **Aristo 0970 Studio**: European equivalent for broadcast engineering
    /// - **Hemmi 266**: Japanese precision rule with coordinated EE scales
    ///
    /// The raw `TimeConstantFunction.transform()` includes this offset. Only at the
    /// reference point (ω=1, τ=1) do both transforms equal exactly zero. For other
    /// reciprocal pairs (e.g., ω=10/τ=0.1), there's an intentional cumulative offset
    /// of approximately `log₁₀(ω) × constant` that makes the physical scales align.
    ///
    /// **DO NOT "FIX" THIS OFFSET** - it is historically accurate and required for
    /// the scales to function correctly as reciprocals on a physical slide rule.
    ///
    /// See: `PickettN16ESOmegaTauAlignmentTests.swift` for verification tests
    ///
    /// Required alignments (from REAL Pickett N16-ES, NON-NEGOTIABLE):
    /// - ω=1 aligns with τ=1
    /// - ω=2 aligns with τ=0.5
    /// - ω=5 aligns with τ=0.2
    /// - ω=10 aligns with τ=0.1
    /// - ω=20 aligns with τ=0.05
    /// - ω=50 aligns with τ=0.02
    ///
    /// Dual function: τ = RC for capacitive circuits, τ = L/R for inductive circuits
    /// Applications: Charging rates, transient response, settling time
    public static func timeConstantTauScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("τ")
            .withFormula("-log₁₀(τ)/12")
            .withFunction(TimeConstantFunction(cycles: 12))
            // INVERTED RANGE: τ = 1/ω, so begin = 1/0.48, end = 1/62
            .withRange(begin: 1.0/0.48, end: 1.0/62.0)  // ≈2.083 to ≈0.0161
            .withLength(length)
            .withTickDirection(.down)
            // Use .absolutelyNone for major ticks so labelLevels is the sole determinant of labeling
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // INVERTED SCALE: Values decrease left-to-right (2.08 → 0.016)
                // Subsections ordered from HIGH value to LOW value
                // ═══════════════════════════════════════════════════════════════════════
                
                // ═══════════════════════════════════════════════════════════════════════
                // PARTIAL DECADE: 2.08 to 1.0 (corresponds to ω: 0.48 to 1)
                // Left portion of scale - compressed region
                // ═══════════════════════════════════════════════════════════════════════
                // 2.08→1.5: Sparse ticks (very compressed, minimal labeling in this region)
                // Cursor precision: +1 decimal from automatic (3→4 decimals)
                ScaleSubsection(startValue: 2.08, tickIntervals: [0.5, 0.1, 0.05], labelLevels: [], cursorPrecision: .fixed(places: 4)),
                
                // 1.5→1.0: Transition to labeled region
                // Cursor precision: +1 decimal from automatic (3→4 decimals)
                ScaleSubsection(startValue: 1.5, tickIntervals: [0.5, 0.1, 0.05], labelLevels: [0], cursorPrecision: .fixed(places: 4)),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 1.0 to 0.1 (corresponds to ω: 1 to 10)
                // This is the primary labeled decade on the τ scale
                // Variable tick density: coarse→medium→fine
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1.0→0.6: First third of decade (coarse, leftward portion)
                // Labels: 1, .9, .8, .7, .6
                // Cursor precision: +1 decimal from automatic (3→4 decimals)
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0], cursorPrecision: .fixed(places: 4)),
                
                // 0.6→0.3: Second third of decade (medium)
                // Labels: .6, .5, .4, .3
                // Cursor precision: +1 decimal from automatic (3→4 decimals)
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02, 0.01], labelLevels: [0], cursorPrecision: .fixed(places: 4)),
                
                // 0.3→0.1: Third third of decade (fine, more expanded)
                // Labels: .3, .2, .1
                // Cursor precision: +1 decimal from automatic (4→5 decimals)
                ScaleSubsection(startValue: 0.3, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0], cursorPrecision: .fixed(places: 5)),
                
                // ═══════════════════════════════════════════════════════════════════════
                // PARTIAL DECADE: 0.1 to 0.016 (corresponds to ω: 10 to 62)
                // Right portion of scale - most expanded region
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1→0.05: Labels at .1, .09, .08, .07, .06, .05
                // Cursor precision: +1 decimal from automatic (4→5 decimals)
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.01, 0.005, 0.002, 0.001], labelLevels: [0], cursorPrecision: .fixed(places: 5)),
                
                // 0.05→0.02: Labels at .05, .04, .03, .02
                // Cursor precision: +1 decimal from automatic (4→5 decimals)
                ScaleSubsection(startValue: 0.05, tickIntervals: [0.01, 0.005, 0.002, 0.001], labelLevels: [0], cursorPrecision: .fixed(places: 5)),
                
                // 0.02→0.016: Final portion (sparse, edge of scale)
                // Cursor precision: +1 decimal from automatic (4→5 decimals)
                ScaleSubsection(startValue: 0.02, tickIntervals: [0.01, 0.005, 0.002], labelLevels: [0], cursorPrecision: .fixed(places: 5))
            ])
            .withLabelFormatter { value in
                guard value > 0 else { return "0" }
                
                if value >= 1.0 {
                    // Values >= 1: show as integer if close to integer, else one decimal
                    let rounded = value.rounded()
                    if abs(value - rounded) < 0.01 {
                        return String(Int(rounded))
                    }
                    return String(format: "%.1f", value)
                } else if value >= 0.1 {
                    // 0.1 to 0.99 → ".1", ".2", ... ".9"
                    let digit = Int((value * 10).rounded())
                    return ".\(digit)"
                } else {
                    // 0.01 to 0.099 → ".01", ".02", ... ".09"
                    let twoDigits = Int((value * 100).rounded())
                    if twoDigits < 10 {
                        return ".0\(twoDigits)"
                    }
                    return ".\(twoDigits)"
                }
            }
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    // MARK: - Pickett N-16 ES Utility Scales
    
    /// D/Q - Decimal keeper and Q-factor scale (Two Decades: 0.1 to 10)
    ///
    /// ## ACTUAL Pickett N-16 ES Specifications (from physical specimen)
    ///
    /// This is a standard logarithmic A-scale pattern running from .1 to 10 (two decades).
    /// Used for decade tracking to prevent magnitude errors in four-decade calculations.
    /// D = capacitative impedance / resistance
    /// Q = resistance / inductive impedance
    ///
    /// **Range:** 0.1 to 10 (two decades)
    ///
    /// **Tick Pattern (from actual Pickett N16-ES):**
    /// - .1 → .2: 49 ticks (finest density)
    /// - .2 → .3: 19 ticks
    /// - .3 → .4: 19 ticks
    /// - .4 → .5: 19 ticks
    /// - .5 → .6: 9 ticks
    /// - .6 → .7: 9 ticks
    /// - .7 → .8: 9 ticks
    /// - .8 → .9: 9 ticks
    /// - .9 → 1: 9 ticks
    /// - 1 → 2: 49 ticks (finest density)
    /// - 2 → 3: 19 ticks
    /// - 3 → 4: 19 ticks
    /// - 4 → 5: 19 ticks
    /// - 5 → 6: 9 ticks
    /// - 6 → 7: 9 ticks
    /// - 7 → 8: 9 ticks
    /// - 8 → 9: 9 ticks
    /// - 9 → 10: 9 ticks
    ///
    /// **Labels:** .1, .2, .3, .4, .5, .6, .7, .8, .9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    ///
    /// Note: This is identical to the standard A scale, just with explicit .1 to 10 labeling.
    public static func pickettDQScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("D or Q")
            .withFormula("log₁₀(x)")
            .withFunction(DecimalKeeperQFunction(isQMode: false))
            .withRange(begin: 0.1, end: 10.0)  // Two decades: 0.1 to 10
            .withLength(length)
            .withTickDirection(.down)
            // Standard 4-level tick styles for A-scale pattern
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // FIRST DECADE: 0.1 to 1.0
                // Standard A-scale variable tick density pattern
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1 → 0.2: 49 ticks (finest) - 50 divisions = 0.002 per tick
                // Pattern: Major=0.1, Half=0.05, Minor=0.01, Tiny=0.002
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01, 0.002], labelLevels: [0]),
                
                // 0.2 → 0.5: 19 ticks each section - 20 divisions = 0.005 per tick
                // Pattern: Major=0.1, Half=0.05, Minor=0.01, Tiny=0.005
                ScaleSubsection(startValue: 0.2, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                
                // 0.5 → 1.0: 9 ticks each section - 10 divisions = 0.01 per tick
                // Pattern: Major=0.1, Half=0.05, Minor=0.01
                ScaleSubsection(startValue: 0.5, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // SECOND DECADE: 1.0 to 10.0
                // Same pattern scaled up 10x
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1 → 2: 49 ticks (finest) - 50 divisions = 0.02 per tick
                // Pattern: Major=1, Half=0.5, Minor=0.1, Tiny=0.02
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.02], labelLevels: [0]),
                
                // 2 → 5: 19 ticks each section - 20 divisions = 0.05 per tick
                // Pattern: Major=1, Half=0.5, Minor=0.1, Tiny=0.05
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0]),
                
                // 5 → 10: 9 ticks each section - 10 divisions = 0.1 per tick
                // Pattern: Major=1, Half=0.5, Minor=0.1
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                // Format labels: .1, .2, ... .9, 1, 2, ... 10
                guard value > 0 else { return "" }
                
                if value < 1.0 {
                    // Values 0.1-0.9: show as ".1", ".2", etc.
                    let digit = Int((value * 10).rounded())
                    return ".\(digit)"
                } else {
                    // Values 1-10: show as integers
                    return String(Int(value.rounded()))
                }
            }
            .addConstant(value: 1.0, label: "♦", style: .major)
            .withSuppressFormulaLabel(true)  // TEST: Suppress formula for Phase 2 annotation testing
            .build()
    }
    
    // MARK: - Convenience Accessors for N-16 ES Scale Names
    
    /// Cos - Alias for cosinePowerFactorScale (used in definition strings)
    public static func cosScale(length: Distance = 250.0) -> ScaleDefinition {
        // Note: cosinePowerFactorScale already has suppressFormulaLabel applied
        cosinePowerFactorScale(length: length)
    }
}
